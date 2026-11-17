-- Real bundled Obsidian renderers plus Astral's controls and startup guards.
Library:BeginStartup()
Library.ForceCheckbox=true
local window=Library:CreateWindow(UIStyle.Window())
check(window.MainFrame.Visible and Library.Toggled,"Reference GUI did not appear synchronously")
check(window.MainFrame.Size.X.Offset==650 and window.MainFrame.Size.Y.Offset==500,"Reference window dimensions changed")
check(window.MainFrame:FindFirstChildOfClass("UICorner").CornerRadius.Offset==20,"Reference rounding cap was replaced")
local names={"Home","Player","Combat","Defense","Target","Blobman","Visual","Aim","Fun","Shop","GUI","Settings"}
local tabs={}
for _,name in names do tabs[name]=window:AddTab(name,"shield")end
local group=tabs.Defense:AddLeftGroupbox("Defense")
local calls=0
local toggle=group:AddToggle("ReferenceTestAction",{Text="Action",Default=false,Callback=function()calls+=1 end})
toggle:AddKeyPicker("ReferenceBind",{Default="None",Mode="Toggle",SyncToggleState=true,Text="Action"})
local button=group:AddButton("Action",function()calls+=1 end)
button:AddKeyPicker("ReferenceButtonBind",{Default="None",Mode="Press"})
local speed=group:AddSlider("ReferenceSpeed",{Text="Speed",Default=16,Min=0,Max=100,Rounding=0})
local players=group:AddDropdown("ReferenceTargets",{Text="Players",Values={"PlayerA","PlayerB"},Multi=true,Default={},Searchable=true})
players:SetValueImages({PlayerA="rbxassetid://123",PlayerB="rbxassetid://456"})
local input=group:AddInput("ReferenceInput",{Text="Text",Default="value"})
local watched=0;toggle:OnChanged(function()watched+=1 end)
button.Base.MouseButton1Click:Fire();toggle:SetValue(true);toggle:SetValue(false)
check(calls==0 and watched==0,"Constructing the transferred GUI executed a gameplay action")
ThemeManager:SetLibrary(Library);ThemeManager:SetDefaultTheme(UIStyle.Theme())
Library:FinishStartup()
key("LeftAlt");key("LeftAlt",true)
check(calls==0,"An unbound Alt key invoked a gameplay action")
toggle:SetValue(true);toggle:SetValue(true)
check(calls==1 and watched==1,"Explicit toggles failed or replayed an unchanged value")
toggle:SetValue(false);check(calls==2 and watched==2,"Transferred checkbox no longer turns off")
button.Base.MouseButton1Click:Fire();check(calls==3,"Transferred button lost its callback")
check(speed.Value==16 and input.Value=="value","Native controls lost their defaults")
players:SetValue({PlayerA=true});check(players.Value.PlayerA and not players.Value.PlayerB,"Player selection stopped being independent")
local originals=Library.Options.ReferenceTargets
local owner=group:AddToggle("ReferenceSettingsOwner",{Text="Settings owner",Default=false,Callback=function()calls+=100 end})
local dependent=group:AddDependencyBox();dependent:SetupDependencies({{owner,true}})
dependent:AddSlider("ReferenceSetting",{Text="Existing setting",Default=4,Min=0,Max=10})
Library:AttachDependencySettings()
check(owner.SettingsPanel and dependent.Holder.Parent==owner.SettingsPanel.Body,"Function settings were lost during the GUI transfer")
local before=calls;owner.SettingsGear.Activated:Fire()
check(owner.SettingsPanel.Frame.Visible and calls==before and not owner.Value,"Opening settings enabled the action")
Library.Options.ReferenceSetting:SetValue(6)
check(Library.Options.ReferenceSetting.Value==6 and Library.Options.ReferenceTargets==originals,"Settings migration replaced existing controls")
local dep=owner.SettingsPanel
Library.Animations.ToggleWindow=false
window:Toggle(false)
check(not window.MainFrame.Visible and not dep.Frame.Visible,"Hiding the transferred GUI left an action panel over the game")
window:Toggle(true)
local settings=tabs.Settings
ThemeManager:ApplyToTab(settings)
UIStyle.ApplyStartupTheme(ThemeManager,Library)
check(Library.Scheme.BackgroundColor:ToHex()=="0f0f0f" and Library.Scheme.AccentColor:ToHex()=="7d55ff","The supplied Obsidian palette was overwritten")
if GUIStyle then
    local appearance=GUIStyle.Install({Library=Library,Tab=tabs.GUI,Defer=task.defer,
        Decode=function(value)return services.HttpService:JSONDecode(value)end,
        Encode=function(value)return services.HttpService:JSONEncode(value)end})
    Library:OnUnload(function()appearance:Dispose()end)
    check(Library.Options.AstralGUIWindowAlpha.Value==0 and Library.Options.AstralGUISliderHeight.Value==15,"The user's GUI controls overwrote the reference defaults")
    Library.Options.AstralGUIWindowAlpha:SetValue(.3)
    check(window.MainFrame.BackgroundTransparency==.3,"Existing window transparency customization no longer reaches the transferred renderer")
    Library.Options.AstralGUISliderHeight:SetValue(20)
    local track=speed.Holder:FindFirstChild("SliderTrack",true)
    check(track and track.Size.Y.Offset==20,"Existing slider customization was lost during transfer")
    Library.Toggles.AstralGUIThumbVisible:SetValue(true)
    check(speed.Holder:FindFirstChild("SliderThumb",true).Visible,"The optional slider thumb setting stopped working")
end
local image=false
for _,node in Library.ScreenGui:GetDescendants()do
    if node:IsA("ImageLabel")and(node.Image=="rbxassetid://123"or node.Image=="rbxassetid://456")then image=true end
end
check(image,"Item/player pictures disappeared from dropdowns")
local inputListeners=table.clone(UIS.InputBegan.Connections)
local releaseListeners=table.clone(UIS.InputEnded.Connections)
Library:Unload()
for _,connection in inputListeners do check(not connection.Connected,"Control input listener survived reference GUI unload")end
for _,connection in releaseListeners do check(not connection.Connected,"Hold-key listener survived reference GUI unload")end
check(Library.Unloaded and not Library.ScreenGui,"Transferred GUI did not dispose its root")
print('PASS: '..checks..' actual Obsidian window/control, startup, image, settings and unload checks (mocked)')
