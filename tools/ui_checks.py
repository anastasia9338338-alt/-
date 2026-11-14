"""Execute the exact bundled Astral UI in a GUI-shaped test engine."""
from pathlib import Path
import argparse,re,subprocess,tempfile

ROOT=Path(__file__).resolve().parents[1]
def adapter_program(modules):
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

def startup_program(main):
    if not main:return ''
    defaults=main[main.index('tbl8 = {'):main.index('\n\n',main.index('tbl8 = {'))]
    a=main.index('gameCorrectionsNotify.OnClientEvent:Connect(function(arg)')+len('gameCorrectionsNotify.OnClientEvent:Connect(')
    z=main.index('\n\t\t\t\tend)',a)+len('\n\t\t\t\tend')
    return '''do
local tbl8
'''+defaults+'''
local flag11=false;local tbl9={KickFlags=0};local n36=0;local reset,kicked=0,0
local humanoid={ChangeState=function(_,state)if state==Enum.HumanoidStateType.Dead then reset+=1 end end}
local tbl12={Char=function()return nil,nil,humanoid end};local fn18=function()end
local localPlayer={Kick=function()kicked+=1 end}
local correction='''+main[a:z]+'''
check(not tbl8.AutoReset and not tbl8.AutoLeave and not tbl8.AutoAntiLag and not tbl8.Flight,"Active gameplay defaults survived the startup fix")
for _=1,6 do correction("Flying")end
check(reset==0 and kicked==0,"Real Main correction handler killed or kicked the idle local character")
tbl8.AutoReset=true;correction("Flying")
check(reset==1 and kicked==0,"Manual Auto Reset no longer invokes its original handler")
end
'''

def program(modules):
    if 'TheWorstUIV2'in modules:return adapter_program(modules)
    support=ROOT/'tools/feature_tests'
    s=(support/'ui_engine_mock.luau').read_text()+'\n'+(support/'ui_native_mock.luau').read_text()
    s+='local UIMotion=(function()\n'+modules['UIMotion']+'\nend)()\n'
    s+='''
local runtime={}
local Identity={Root="Astral",ConfigFolder="Astral/Configs",ThemeFolder="Astral/Themes",Runtime=function()return runtime end}
local Brand={Clean=function(text)return text end}
local FakeIcons={GetAsset=function(name)return{Url="rbxassetid://1",ImageRectOffset=Vector2.zero,ImageRectSize=Vector2.zero}end}
local MenuDecor={ItemImage=function()end,ValueIcon=function()return "box"end,BlockedTab=function()return false end,Icon=function()return "box"end}
local FunctionGlyphs={Get=function()end}
local Library=(function(...)
'''+modules['Library']+'''
end)(function(name)
if name=="Branding"then return Brand elseif name=="AppIdentity"then return Identity elseif name=="MenuDecor"then return MenuDecor elseif name=="FunctionGlyphs"then return FunctionGlyphs elseif name=="Icons"then return FakeIcons elseif name=="UIMotion"then return UIMotion end
error(name)
end)
'''
    if 'UIStyle'not in modules or 'ThemeManager'not in modules:
        bundled=dict(re.findall(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',(ROOT/'astral.lua').read_text(),re.M|re.S))
        modules=dict(modules)
        for name in ('UIStyle','ThemeManager'):modules.setdefault(name,bundled[name])
    s+='local ThemeManager=(function(...)\n'+modules['ThemeManager']+'\nend)(function(name)assert(name=="AppIdentity");return Identity end)\n'
    if 'UIStyle'in modules:
        s+='local UIStyle=(function()\n'+modules['UIStyle']+'\nend)()\nUIStyle.ApplyBase(Library)\n'
    if 'ObjectESP'in modules:
        s+='local ObjectESP=(function(...)\n'+modules['ObjectESP']+'\nend)(function(name)assert(name=="AssetCatalog");return {Items={Train="rbxassetid://123"}}end)\n'
    main=modules.get('Main','')
    if 'Icons'in modules:
        fake='local FakeIcons={GetAsset=function(name)return{Url="rbxassetid://1",ImageRectOffset=Vector2.zero,ImageRectSize=Vector2.zero}end}'
        s=s.replace(fake,'local FakeIcons=(function()\n'+modules['Icons']+'\nend)()')
    if 'Toggles:AddToggle("PCLDESPT"'in main:
        a=main.index('Toggles:AddToggle("PCLDESPT"');b=main.index('Toggles:AddToggle("StickyESPT"',a)
        s+='local function BuildPCLDRow(Toggles,toggles,espConfig,tbl12,fn21)\nlocal tbl8={PCLDESP=false}\n'+main[a:b]+'\nend\n'
    extra=modules.get('ExtraFeatures','')
    if 'v89:AddCheckbox("NewESP_PCLDESP"'in extra:
        a=extra.index('v89:AddCheckbox("NewESP_PCLDESP"');b=extra.index('\nv89:AddDivider()',a)
        s+='local function BuildExtraPCLDRow(v89)\n'+extra[a:b]+'\nend\n'
        a=extra.index('options.NewESP_PCLD_ChamsColor:OnChanged(function()');b=extra.index('\nend)',a)+len('\nend)')
        s+='local function BindExtraPCLDColor(options,onColor)\nlocal color2,color3\nlocal fn74=function()onColor(color2,color3)end\n'+extra[a:b]+'\nend\n'
    if 'AstralHomeAvatar'in main:
        a=main.index('local box=tbl15.Home:AddLeftGroupbox("Welcome"');b=main.index('\n        end\n\n        do',a)
        s+='local function BuildHomeProfile(tbl15,localPlayer,Players)\nlocal flag11=false\n'+main[a:b]+'\nreturn box\nend\n'
        a=main.index('local Values = tbl15.Player:AddLeftGroupbox');b=main.index('\n        do\n            local teleports=requireModule("TeleportMenu")',a)
        s+='local function BuildCharacterLayout(tbl15)\nlocal lib,options,toggles=Library,Library.Options,Library.Toggles\nlocal tbl8,tbl9,tbl12={},{},{}\nlocal tbl7={RegisteredKeybinds={},KeybindNames={}}\nlocal flag11=false\ndo\n'+main[a:b]+'\nend\n'
    if 'Character Extras'in modules.get('ExtraFeatures',''):
        extra=modules['ExtraFeatures'];a=extra.index('function UI:_Group(');b=extra.index('\nfunction UI:AddLeftGroupbox',a)
        s+='local function BuildMergedCharacterGroups(tab)\nlocal UI={}\nlocal function plain(value)return tostring(value):gsub("<[^>]*>","")end\n'+extra[a:b]+"\nlocal bridge={Groupboxes={},Wrap=function(_,object)return object end}\nlocal wrapper=setmetatable({_object=tab,_tabName='Player',_bridge=bridge},{__index=UI})\nfor _,name in ipairs({'Values','Teleporting','Character','Players','Coin Farm','Animations'})do wrapper:_Group('Left',name,'user')end\nreturn bridge.Groupboxes\nend\n"
    s+=startup_program(modules.get('Main'))
    return s+(support/'ui_native_body.luau').read_text()

if __name__=='__main__':
    args=argparse.ArgumentParser();args.add_argument('--luau',type=Path,required=True);args.add_argument('--bundle',type=Path);a=args.parse_args()
    if a.bundle:
        pattern=re.compile(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',re.M|re.S)
        modules=dict(pattern.findall(a.bundle.read_text()))
    else:
        modules={n:(ROOT/'ui'/f'{n}.luau').read_text()for n in ('Library','UIMotion')}
        if 'requireModule("TheWorstUIV2")'in modules['Library']:
            modules.update({n:(ROOT/'ui'/p).read_text()for n,p in [('TheWorstUIV2','TheWorstUIV2.luau'),('Presentation','Presentation.luau'),('Watermark','Watermark.luau')]})
    with tempfile.TemporaryDirectory(prefix='astral-ui-')as d:
        p=Path(d)/'ui.luau';p.write_text(program(modules));r=subprocess.run([str(a.luau),str(p)],capture_output=True,text=True)
        print(r.stdout,end='');print(r.stderr,end='');raise SystemExit(r.returncode)
