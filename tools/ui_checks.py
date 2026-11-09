"""Execute real TheWorstUIV2 and Astral GUI adapter in a GUI-shaped test engine."""
from pathlib import Path
import argparse,re,subprocess,tempfile

ROOT=Path(__file__).resolve().parents[1]
def program(modules):
    support=ROOT/'tools/feature_tests'
    s=(support/'ui_engine_mock.luau').read_text()
    s+='\nlocal FakeIcons={GetAsset=function(name)return{Url="rbxassetid://1",ImageRectOffset=Vector2.zero,ImageRectSize=Vector2.zero}end}\n'
    s+='local Native=(function(...)\n'+modules['TheWorstUIV2']+'\nend)(function(name)assert(name=="Icons");return FakeIcons end)\n'
    s+='local Library=(function(...)\n'+modules['Library']+'\nend)(function(name)if name=="TheWorstUIV2"then return Native elseif name=="Icons"then return FakeIcons elseif name=="FunctionGlyphs"then return{}end;error(name)end)\n'
    s+='local runtime={}\nlocal Identity={ConfigFolder="Astral/Configs",ThemeFolder="Astral/Themes",Runtime=function()return runtime end}\n'
    for name in ['SaveManager','ThemeManager']:
        body=modules.get(name)
        if body is None:
            pattern=re.compile(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',re.M|re.S)
            body=dict(pattern.findall((ROOT/'astral.lua').read_text()))[name]
        s+='local '+name+'=(function(...)\n'+body+'\nend)(function(name)assert(name=="AppIdentity");return Identity end)\n'
    return s+(support/'ui_adapter_body.luau').read_text()

if __name__=='__main__':
    args=argparse.ArgumentParser();args.add_argument('--luau',type=Path,required=True);args.add_argument('--bundle',type=Path);a=args.parse_args()
    if a.bundle:
        pattern=re.compile(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',re.M|re.S)
        modules=dict(pattern.findall(a.bundle.read_text()))
    else:modules={n:(ROOT/'ui'/p).read_text()for n,p in [('Library','Library.luau'),('TheWorstUIV2','TheWorstUIV2.luau')]}
    with tempfile.TemporaryDirectory(prefix='astral-ui-')as d:
        p=Path(d)/'ui.luau';p.write_text(program(modules));r=subprocess.run([str(a.luau),str(p)],capture_output=True,text=True)
        print(r.stdout,end='');print(r.stderr,end='');raise SystemExit(r.returncode)
