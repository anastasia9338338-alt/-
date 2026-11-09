"""Execute real TheWorstUIV2 and Astral GUI adapter in a GUI-shaped test engine."""
from pathlib import Path
import argparse,re,subprocess,tempfile

ROOT=Path(__file__).resolve().parents[1]
def program(modules):
    support=ROOT/'tools/feature_tests'
    s=(support/'ui_engine_mock.luau').read_text()
    s+='\nlocal FakeIcons={GetAsset=function(name)return{Url="rbxassetid://1",ImageRectOffset=Vector2.zero,ImageRectSize=Vector2.zero}end}\n'
    s+='local Native=(function(...)\n'+modules['TheWorstUIV2']+'\nend)(function(name)assert(name=="Icons");return FakeIcons end)\n'
    if 'Presentation'in modules:s+='local Presentation=(function()\n'+modules['Presentation']+'\nend)()\n'
    else:s+='local Presentation=nil\n'
    s+='local Library=(function(...)\n'+modules['Library']+'\nend)(function(name)if name=="TheWorstUIV2"then return Native elseif name=="Icons"then return FakeIcons elseif name=="Presentation"then return Presentation elseif name=="FunctionGlyphs"then return{}end;error(name)end)\n'
    s+='local runtime={}\nlocal Identity={ConfigFolder="Astral/Configs",ThemeFolder="Astral/Themes",Runtime=function()return runtime end}\n'
    for name in ['SaveManager','ThemeManager']:
        body=modules.get(name)
        if body is None:
            pattern=re.compile(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',re.M|re.S)
            body=dict(pattern.findall((ROOT/'astral.lua').read_text()))[name]
        s+='local '+name+'=(function(...)\n'+body+'\nend)(function(name)assert(name=="AppIdentity");return Identity end)\n'
    if 'Watermark'in modules:s+='local HUD=(function()\n'+modules['Watermark']+'\nend)()\n'
    if 'TeleportMenu'in modules:
        s+='local TeleportMenu=(function(...)\n'+modules['TeleportMenu']+'\nend)(function(name)if name=="AssetCatalog"then return{Locations={Beach="rbxassetid://123"}}elseif name=="ProvidedPhotos"then return{Get=function()end}end;error(name)end)\n'
    main=modules.get('Main')
    if main:
        defaults=main[main.index('tbl8 = {'):main.index('\n\n',main.index('tbl8 = {'))]
        a=main.index('gameCorrectionsNotify.OnClientEvent:Connect(function(arg)')+len('gameCorrectionsNotify.OnClientEvent:Connect(')
        z=main.index('\n\t\t\t\tend)',a)+len('\n\t\t\t\tend')
        s+='do\nlocal tbl8\n'+defaults+'\n'
        s+='''local flag11=false;local tbl9={KickFlags=0};local n36=0;local reset,kicked=0,0
local humanoid={ChangeState=function(_,state)if state==Enum.HumanoidStateType.Dead then reset+=1 end end}
local tbl12={Char=function()return nil,nil,humanoid end};local fn18=function()end
local localPlayer={Kick=function()kicked+=1 end}
'''
        s+='local correction='+main[a:z]+'\n'
        s+='''check(not tbl8.AutoReset and not tbl8.AutoLeave and not tbl8.AutoAntiLag and not tbl8.Flight,"Active gameplay defaults survived the startup fix")
for _=1,6 do correction("Flying")end
check(reset==0 and kicked==0,"Real Main correction handler killed or kicked the idle local character")
tbl8.AutoReset=true;correction("Flying")
check(reset==1 and kicked==0,"Manual Auto Reset no longer invokes its original handler")
end
'''
    return s+(support/'ui_adapter_body.luau').read_text()

if __name__=='__main__':
    args=argparse.ArgumentParser();args.add_argument('--luau',type=Path,required=True);args.add_argument('--bundle',type=Path);a=args.parse_args()
    if a.bundle:
        pattern=re.compile(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',re.M|re.S)
        modules=dict(pattern.findall(a.bundle.read_text()))
    else:modules={n:(ROOT/'ui'/p).read_text()for n,p in [('Library','Library.luau'),('TheWorstUIV2','TheWorstUIV2.luau'),('Presentation','Presentation.luau'),('Watermark','Watermark.luau')]}
    with tempfile.TemporaryDirectory(prefix='astral-ui-')as d:
        p=Path(d)/'ui.luau';p.write_text(program(modules));r=subprocess.run([str(a.luau),str(p)],capture_output=True,text=True)
        print(r.stdout,end='');print(r.stderr,end='');raise SystemExit(r.returncode)
