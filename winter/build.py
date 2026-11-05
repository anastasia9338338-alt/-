#!/usr/bin/env python3
"""Build a single executable winter.lua without loadstring or HTTP dependencies."""
from pathlib import Path
import argparse,base64,hashlib,re,subprocess,zipfile

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--luau-dir',type=Path,default=Path('/workspace/scratch/astral-speed/tools'))
    args=parser.parse_args()
    root=Path(__file__).resolve().parent;repo=root.parent
    names=['Texture','Weather','Snow','Decor','Main']
    sources={name:(root/'src'/(name+'.luau')).read_text()for name in names}
    assert set(p.stem for p in (root/'src').glob('*.luau'))==set(names)
    for name,body in sources.items():
        for dependency in re.findall(r'requireModule\("(\w+)"\)',body):assert dependency in sources,(name,dependency)
        assert not re.search(r':(?:FireServer|InvokeServer)\s*\(',body),'Winter must not invoke gameplay remotes'
    texture=re.fullmatch(r'.*?return "([A-Za-z0-9+/=]+)"\s*',sources['Texture'],re.S)
    assert texture and base64.b64decode(texture[1]).startswith(b'\x89PNG\r\n\x1a\n')
    parts=['-- Winter Wonderland 1.0 | standalone client-side winter scenery.\n',
        '-- Snow, soft footprints, holiday decor. Re-executing replaces this instance.\n',
        '-- Open the snowflake button for controls; close (×) restores the scenery.\n',
        'local loaders,cache,loading={},{},{}\n']
    for name,body in sources.items():parts += [f'loaders.{name}=function(...)\n',body,'\nend\n']
    parts += ['''local function requireModule(name)
    if cache[name]~=nil then return cache[name]end
    assert(not loading[name],"Circular winter module: "..tostring(name))
    local loader=assert(loaders[name],"Missing winter module: "..tostring(name))
    loading[name]=true
    local result=loader(requireModule)
    loading[name]=nil;cache[name]=result
    return result
end
return requireModule("Main")
''']
    out=repo/'winter.lua';out.write_text(''.join(parts))
    for path in [out]+[root/'src'/(name+'.luau')for name in names]:
        r=subprocess.run([str(args.luau_dir/'luau-compile'),'--null',str(path)],capture_output=True,text=True)
        assert r.returncode==0,(path.name,r.stdout,r.stderr)
    with zipfile.ZipFile(repo/'winter.zip','w',zipfile.ZIP_DEFLATED,compresslevel=6)as archive:archive.write(out,'winter.lua')
    with zipfile.ZipFile(repo/'winter.zip')as archive:
        assert archive.namelist()==['winter.lua']and archive.testzip()is None
        assert archive.read('winter.lua')==out.read_bytes()
    print('PASS: standalone winter.lua, five source modules and ZIP')
    print('Lua bytes:',out.stat().st_size,'ZIP bytes:',(repo/'winter.zip').stat().st_size)
    print('SHA256:',hashlib.sha256(out.read_bytes()).hexdigest())

if __name__=='__main__':main()
