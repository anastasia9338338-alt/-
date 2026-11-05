#!/usr/bin/env python3
"""Verify the production Lua PNG decoder and no-file-API fallback."""
from pathlib import Path
import argparse,base64,re,subprocess,tempfile,zlib

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--luau',type=Path,default=Path('/workspace/scratch/astral-speed/tools/luau'))
    args=parser.parse_args();root=Path(__file__).resolve().parents[1]
    source=(root/'src/Main.luau').read_text();a=source.index('local function texture()');b=source.index('local function buildUI()',a)
    png=base64.b64decode(re.search(r'return "(.*?)"',(root/'src/Texture.luau').read_text())[1])
    setup='''local captured
local writefile=function(_,bytes)captured=bytes end
local getcustomasset=function(path)return 'asset://'..path end
local function requireModule(name)assert(name=='Texture');return(function()
'''+(root/'src/Texture.luau').read_text()+'''\nend)()end
'''
    body=source[a:b]+f'''
assert(texture()=='asset://AstralWinter_snowflake_v1.png','Custom texture asset not returned')
assert(#captured=={len(png)},'Wrong PNG byte count')
local a,b=1,0
for i=1,#captured do a=(a+string.byte(captured,i))%65521;b=(b+a)%65521 end
assert(b*65536+a=={zlib.adler32(png)},'Decoded PNG integrity differs')
writefile=nil;assert(texture()==nil,'Missing file API did not fall back')
writefile=function()end;getcustomasset=function()return false end
assert(texture()==nil,'Invalid asset response did not fall back')
print('PASS: embedded snow-crystal PNG integrity and asset fallback')
'''
    with tempfile.TemporaryDirectory(prefix='winter-texture-')as temp:
        p=Path(temp)/'texture.luau';p.write_text(setup+body)
        r=subprocess.run([str(args.luau),str(p)],capture_output=True,text=True)
        print(r.stdout,end='')
        if r.returncode:print(r.stderr,end='')
        raise SystemExit(r.returncode)

if __name__=='__main__':main()
