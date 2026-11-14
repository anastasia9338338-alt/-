"""Cross-check the bundled codecs against Pillow, without EditableImage access."""
from pathlib import Path
import io,subprocess,json
from PIL import Image

def binary(data):return '"'+''.join('\\%03d'%v for v in data)+'"'
def codec_prefix(modules):
    names=['PNGTypes','PNGCRC','PNGInflate','PNGDecode','PNGEncode','JPEGDecode','FrameImageFiles','FrameArtwork']
    # Use the exact Bootstrap loader: it requires every module to return a table.
    boot=modules['Bootstrap'];loader=boot[boot.index('local cache = {}'):boot.index('local Identity=requireModule(')]
    s='local sources={}\n'
    for name in names:s+='sources["'+name+'"]='+binary(modules[name].encode())+'\n'
    return s+loader+'\n'

def run_codec_checks(modules,runner,folder):
    prefix=codec_prefix(modules)
    fixtures=[]
    image=Image.new('RGBA',(48,40));image.putdata([(x*5,y*6,(x*3+y*2)%256,(x*7+y*5)%256)for y in range(40)for x in range(48)])
    for kind in ['RGBA','RGB','L','LA','P']:
        converted=image.convert(kind);raw=io.BytesIO();converted.save(raw,format='PNG');fixtures.append((kind,raw.getvalue(),converted.convert('RGBA').tobytes(),0))
    rgb=image.convert('RGB')
    for progressive in (False,True):
        for sampling in (0,1,2):
            raw=io.BytesIO();rgb.save(raw,format='JPEG',quality=94,subsampling=sampling,progressive=progressive)
            actual=raw.getvalue();expected=Image.open(io.BytesIO(actual)).convert('RGBA').tobytes()
            fixtures.append(('JPEG '+str(progressive)+'/'+str(sampling),actual,expected,4))
    for progressive in (False,True):
        raw=io.BytesIO();rgb.convert('L').save(raw,format='JPEG',quality=90,progressive=progressive)
        actual=raw.getvalue();fixtures.append(('JPEG grayscale '+str(progressive),actual,Image.open(io.BytesIO(actual)).convert('RGBA').tobytes(),1))
    raw=io.BytesIO();rgb.save(raw,format='JPEG',quality=94,subsampling=2,restart_marker_blocks=1)
    actual=raw.getvalue();assert any(bytes((255,marker))in actual for marker in range(208,216)),'Pillow 10.2+ is required for restart-marker coverage'
    fixtures.append(('JPEG restart markers',actual,Image.open(io.BytesIO(actual)).convert('RGBA').tobytes(),4))
    s=prefix+'''local storage={};local F=requireModule('FrameImageFiles')
local context={ReadAsset=function()return storage.Source end,Write=function(path,bytes)storage[path]=bytes end,Register=function(path)return 'rbxasset://'..path end,Remove=function(path)storage[path]=nil end,Name=function(n)return 'frame_'..n..'.png'end,NativeDecode=function()error('EditableImage denied')end,NativeTexture=function()error('EditableImage denied')end}
local files=F.Install(context)
local function hex(bytes)local t={};for i=1,#bytes do t[i]=string.format('%02x',bytes:byte(i))end;return table.concat(t)end
'''
    for i,(name,data,expected,tolerance)in enumerate(fixtures):
        s+='storage.Source='+binary(data)+'\ndo local image=files:Decode("input");assert(image.Width==48 and image.Height==40);local resource,asset=files:Texture(image.Pixels,image.Width,image.Height);assert(type(asset)=="string");print("CASE'+str(i)+' "..hex(storage[resource.Filename]));resource:Destroy();assert(storage[resource.Filename]==nil)end\n'
    s+="""local Art=requireModule('FrameArtwork');local dense=buffer.create(160*128*4)
for y=0,127 do for x=0,159 do
 local v=(x<28 or x>=132 or y<28 or y>=100)and 242 or((math.floor(x/8)+math.floor(y/8))%2==0 and 82 or 106)
 local i=(y*160+x)*4;buffer.writeu8(dense,i,v);buffer.writeu8(dense,i+1,v);buffer.writeu8(dense,i+2,v);buffer.writeu8(dense,i+3,255)
end end
local cleaned=Art.Clean(dense,160,128,true)
assert(cleaned.Removed>7000 and buffer.readu8(cleaned.Pixels,3)==255,'Dense white ornament hides the checker tones or gets erased')
print('DENSE CHECKER PASS')
"""
    s+='local leaked=files:Texture(buffer.create(4),1,1);files:Dispose();assert(leaked.Destroyed);print("LIFETIME PASS")\n'
    path=Path(folder)/'portable_frame_codecs.luau';path.write_text(s)
    result=subprocess.run([str(runner),str(path)],capture_output=True,text=True,timeout=40)
    assert result.returncode==0,(result.stdout[-2000:],result.stderr)
    outputs={line.split(' ',1)[0]:line.split(' ',1)[1]for line in result.stdout.splitlines()if line.startswith('CASE')}
    for i,(name,data,expected,tolerance)in enumerate(fixtures):
        decoded=Image.open(io.BytesIO(bytes.fromhex(outputs['CASE'+str(i)])));assert decoded.size==(48,40)
        actual=decoded.convert('RGBA').tobytes();error=[abs(a-b)for a,b in zip(actual,expected)]
        assert max(error)<=max(1,tolerance*3)and sum(error)/len(error)<=max(.01,tolerance),(name,max(error),sum(error)/len(error))
    assert 'LIFETIME PASS'in result.stdout
    print('PASS: 14 PNG/JPEG baseline/progressive/grayscale/restart decode and PNG output cross-checks against Pillow, with EditableImage denied')
