"""Reproducible integration patches to MIT-licensed TheWorstUIV2.

Upstream: m1kp0/libraries a7ddb2ea8184bb5cc97b7f02c3270396e9b6e9cb.
Keep upstream rendering; expose frames and isolate the Astral lifecycle.
"""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parent

def source():
    s=(ROOT/'vendor/TheWorstUIV2.upstream.lua').read_text()
    s=s[s.index('-- TheWorstUI V2'):]
    s=s.replace('getgenv().UI = {','local UI = {',1)
    s=s.replace('Instance.new("ScreenGui", game.CoreGui)','Instance.new("ScreenGui", (gethui and gethui()) or game:GetService("CoreGui"))',1)
    s=s.replace('UI.ScreenGui.Name = "TheWorstUIV2"','UI.ScreenGui.Name = "AstralTheWorstUIV2"\n    UI.ScreenGui.ResetOnSpawn = false\n    UI.ExternalBinds = true',1)
    a=s.index('    local LucideIcons = loadstring(');z=s.index('\n    UI.GetIcon = GetIcon',a)
    s=s[:a]+'''    local requireModule = ...
    local Icons = requireModule("Icons")
    local function GetIcon(name)
        if not name or name == "" then return {Image="",Size=Vector2.zero,Position=Vector2.zero} end
        if type(name)=="number" then name="rbxassetid://"..name end
        if tostring(name):find("://",1,true) then return {Image=name,Size=Vector2.zero,Position=Vector2.zero} end
        local icon=Icons.GetAsset(name)
        return {Image=icon and icon.Url or "",Size=icon and icon.ImageRectSize or Vector2.zero,Position=icon and icon.ImageRectOffset or Vector2.zero}
    end
''' +s[z:]
    # Export actual native widgets; the compatibility layer never renders a
    # second hidden GUI or downloads a mutable UI implementation at runtime.
    refs={'Label':'LabelFrame','Button':'ButtonFrame','Toggle':'ToggleFrame',
          'Slider':'SliderFrame','Textbox':'TextboxFrame','Dropdown':'DropdownFrame',
          'Colorpicker':'ColorpickerFrame','Bind':'BindBoxFrame'}
    for obj,frame in refs.items():
        extra=f'{obj}.Frame={frame}'
        if obj=='Bind':extra='Bind.Frame=BindBox.Parent; Bind.IsBinding=function()return IsBinding end'
        if obj=='Dropdown':extra+='; Dropdown.Config=DropdownConfig'
        s=re.sub(r'(?m)^(\s*)return '+obj+r'\s*$',lambda m:m[1]+extra+'\n'+m[1]+'return '+obj,s)
    # Inline color pickers expose their actual small color button; only the
    # standalone section picker has a ColorpickerFrame local.
    first=s.index('function Section:CreateColorpicker')
    s=s[:first].replace('Colorpicker.Frame=ColorpickerFrame','Colorpicker.Frame=ColorpickerBox')+s[first:]
    s=s.replace('return Section\n','Section.Frame=IsGroup and SectToCreate.RealFrame or SectionFrame; Section.Container=GetParent()\n                                        return Section\n')
    s=s.replace('return Tab\n','Tab.Frame=SectionsHolder; Tab.Button=TabButton; Tab.Show=function()ChangeTab(TabConfig.Name,TabButton)end\n                                return Tab\n')
    s=s.replace('return Window\n','Window.Frame=WindowFrame; Window.TaskbarIcon=TaskbarIcon\n                        return Window\n')
    s=s.replace('return Taskbar\n','Taskbar.Frame=MainFrame; Taskbar.StartFrame=StartFrame; Taskbar.NotificationsHubFrame=NotificationsHubFrame\n            return Taskbar\n')
    # A readable horizontal tab strip on small screens instead of squeezing
    # all ten Astral names into the width of one desktop window.
    s=s.replace('CreateElement("FakeFrame", {\n                                                    Name = "ButtonsListFrame",',
        'CreateElement("ScrollingFrame", {\n                                                    Name = "ButtonsListFrame",\n                                                    BackgroundTransparency=1, ScrollBarThickness=2, ScrollingDirection=Enum.ScrollingDirection.X, AutomaticCanvasSize=Enum.AutomaticSize.X, CanvasSize=UDim2.new(), BorderSizePixel=0,')
    s=s.replace('Width / ButtonsCount, 1, 0','math.max(90, Width / ButtonsCount), 1, 0')
    # Keep native binding assignment UI. One Astral dispatcher handles press,
    # hold, toggle and modifiers so a key never activates both implementations.
    s=s.replace('else\n                                                    if Input.KeyCode.Name ~= Bind.Value',
        'else\n                                                    if UI.ExternalBinds then return end\n                                                    if Input.KeyCode.Name ~= Bind.Value')
    s=s.replace('else\n                                                        if Input.KeyCode.Name ~= Bind.Value',
        'else\n                                                        if UI.ExternalBinds then return end\n                                                        if Input.KeyCode.Name ~= Bind.Value')
    # Binding Set is also called by the user's capture UI; publish assignment.
    s=s.replace('BindBox.Text = "None"\n', 'BindBox.Text = "None"\n                                                    if Bind.OnAssigned then Bind.OnAssigned("None") end\n')
    s=s.replace('BindBox.Text = BindValue.Name\n','BindBox.Text = BindValue.Name\n                                                    if Bind.OnAssigned then Bind.OnAssigned(BindValue.Name) end\n')
    s=s.replace(' or BindValue == Enum.KeyCode.None or BindValue == Enum.UserInputType.None','')
    s=s.replace('else\n                                                            if Input.KeyCode ~= Bind.Value',
        'else\n                                                            if UI.ExternalBinds then return end\n                                                            if Input.KeyCode ~= Bind.Value')
    s=s.replace('DropdownSet(ToSelect, true) end','DropdownSet(Options, false) end')
    s=s.replace('Option:Destroy(OptionsAdd)','Option:Destroy()')
    s=s.replace('local function AddOptions(OptionsAdd)','local function AddOptions(OptionsAdd, NeedSet, ToSelect)')
    s=s.replace('Number = tonumber(Number)','Number = tonumber(Number)\n        if not Number or Number~=Number or math.abs(Number)==math.huge then return 0 end')
    s=s.replace('local Sign = Number >= 0 and 1 or -1\n        local Result = math.floor(Number / Factor + 0.5 * Sign) * Factor\n\n        if Result < 0 then\n            Result = Result + Factor\n        end',
        'local Result = math.round(Number / Factor) * Factor')
    s=s.replace('function Slider:Set(Value)\n',
        '''function Slider:Set(Value)
                                                    Value=tonumber(Value)
                                                    if not Value or Value~=Value or math.abs(Value)==math.huge then Value=tonumber(Slider.Value)or SliderConfig.Min end
''')
    s=s.replace('getgenv().TheWorstUIV2Loaded = true','UI.Loaded = true')
    s=s.replace('getgenv().SavePinnedState','UI.SavePinnedState')
    s=s.replace('local function ChangeSectionTab(Name, Button)','local function ChangeSectionTab(Name, Button, Group)')
    s=s.replace('if Sect.Name == Name then','if Sect.Name == Name and(not Group or Sect.Group==Group)then')
    s=s.replace(', SectionConfig.Side)',', SectionConfig.Group)')
    s=s.replace('local CurrentOpenSection = nil','local currentSections = {}')
    s=s.replace('CurrentOpenSection = CurrentSect','currentSections[CurrentSect.Group] = CurrentSect')
    s=s.replace('CurrentOpenSection','currentSections[SectionConfig.Group]')
    # Use the native window's single toggle path for taskbar and search too;
    # avoids an upstream global WindowOpen and keeps adapter visibility in sync.
    a=s.index('                    function Taskbar:ToggleWindow(')
    z=s.index('                    function Taskbar:ToggleStart(',a)
    s=s[:a]+'''                    function Taskbar:ToggleWindow(name,open)
                        local window=UI.Windows[name]
                        if window then return window:Toggle(open)end
                    end

'''+s[z:]
    # Search results must open the actual Astral tab/section that owns a row.
    s=s.replace('Window = WindowConfig.Name,','Window = WindowConfig.Name, Tab=Tab, Section=Section,')
    s=s.replace('local SectionsHolderFrame = RealWindow.Holder.TabFrame.SectionsHolderFrame',
        'local SectionsHolderFrame = Element.Tab and Element.Tab.Frame or RealWindow.Holder.TabFrame.SectionsHolderFrame')
    s=s.replace('Taskbar:ToggleWindow(Element.Window, true)','Taskbar:ToggleWindow(Element.Window, true)\n                                    if Element.Tab then Element.Tab:Show()end\n                                    if Element.Section and Element.Section.Show then Element.Section:Show()end')
    s=s.replace('if not Element.Name:find(Text, 1, true) then continue end',
        'if not Element.Frame.Visible or not Element.Name:find(Text:lower(), 1, true) then continue end')
    s=s.replace('Section.Frame=IsGroup and SectToCreate.RealFrame or SectionFrame; Section.Container=GetParent()',
        '''Section.Frame=IsGroup and SectToCreate.RealFrame or SectionFrame; Section.Container=GetParent()
                                        function Section:Show()ChangeSectionTab(SectionConfig.Name,nil,SectionConfig.Group)end''')
    # Window activation is coordinated by the owning adapter. Upstream Toggle
    # uses the external Opened flag; mirror it inside the method for callers.
    s=s.replace('function Window:Toggle(Open: boolean)\n','function Window:Toggle(Open: boolean)\n                                Window.Opened=Open\n')
    s=s.replace('WindowFrame.Position = UDim2.new(0, TaskbarIcon.AbsolutePosition.X, 1, 0) ',
                'if not Window.Opened then WindowFrame.Position = UDim2.new(0, TaskbarIcon.AbsolutePosition.X, 1, 0) end ')
    # Native notification handles preserve live progress and cancellation.
    s=s.replace('}) task.spawn(function()\n                        if not UI.NotificationSettings.Enabled then return end',
        '''})
                        local handle={Destroyed=false}
                        function handle:Destroy()self.Destroyed=true;if self.Frame then self.Frame:Destroy()end end
                        function handle:ChangeDescription(text)
                            self.Description=tostring(text)
                            local label=self.Frame and self.Frame:FindFirstChild("DescriptionText",true)
                            if label then label.Text=self.Description end
                        end
                        task.spawn(function()
                        if handle.Destroyed or not UI.NotificationSettings.Enabled then return end''')
    s=s.replace('task.delay(NotitficationConfig.Duration, function()',
        '''handle.Frame=NotificationFrame
                        if handle.Description then handle:ChangeDescription(handle.Description)end
                        if handle.Destroyed then NotificationFrame:Destroy();return end
                        if NotitficationConfig.Persist then return end
                        task.delay(NotitficationConfig.Duration, function()
                            if handle.Destroyed or not NotificationFrame.Parent then return end''')
    s=s.replace('                    end) end\n\n                    function Taskbar:ConfigNotifications',
        '                    end)\n                        return handle\n                    end\n\n                    function Taskbar:ConfigNotifications',1)
    # Retire tracked asynchronous UI work as well as signal connections.
    s=s.replace('function UI:Unload()\n','function UI:Unload()\n            if UI.Unloaded then return end\n            UI.Unloaded=true\n            for thread in pairs(uiThreads)do if thread~=coroutine.running()then pcall(nativeTask.cancel,thread)end end\n            table.clear(uiThreads)\n')
    s=s.replace('local function PlaySound(SoundId: string, Volume: number)\n','local function PlaySound(SoundId: string, Volume: number)\n        if not SoundId or SoundId==""then return end\n')
    s=s.replace('Sound:Play()\n','Sound:Play()\n        game:GetService("Debris"):AddItem(Sound,15)\n')
    # All native asynchronous work uses this lifecycle-owned task facade.
    pre='''local nativeTask=task
local uiThreads={}
local task=setmetatable({}, {__index=nativeTask})
local function finishable(fn)
    return function(...)
        local result=table.pack(pcall(fn,...))
        uiThreads[coroutine.running()]=nil
        if not result[1]then error(result[2],0)end
        return table.unpack(result,2,result.n)
    end
end
for _,method in ipairs({"spawn","defer","delay"})do
    task[method]=function(...)
        local args=table.pack(...)
        local position=method=="delay"and 2 or 1
        if type(args[position])=="function"then args[position]=finishable(args[position])end
        local thread=nativeTask[method](table.unpack(args,1,args.n))
        if type(thread)=="thread"and coroutine.status(thread)~="dead"then uiThreads[thread]=true end
        return thread
    end
end
'''
    license=(ROOT/'vendor/LICENSE').read_text()
    assert 'loadstring' not in s and 'HttpGet' not in s
    result='--[[\n'+license+'\nAstral integration patches: ui/prepare_vendor.py\n]]\n'+pre+s
    return '\n'.join(line.rstrip()for line in result.splitlines())+'\n'

if __name__=='__main__':
    (ROOT/'TheWorstUIV2.luau').write_text(source())
