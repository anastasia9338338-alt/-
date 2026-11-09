-- Actual TheWorstUIV2 widgets, not a replacement renderer, are instantiated.
Library:BeginStartup()
local window=Library:CreateWindow({Title="astral",Footer="v4.70",AutoShow=true})
local tabs={}
for _,name in ipairs({"Home","Player","Combat","Defense","Target","Blobman","Visual","Aim","Fun","Settings"})do tabs[name]=window:AddTab(name,"home")end
local group=tabs.Home:AddLeftGroupbox("Main")
local calls={toggle=0,slider=0,dropdown=0,input=0,color=0,press=0,hold=0}
local toggle=group:AddToggle("TestToggle",{Text="Toggle",Default=false,Callback=function()calls.toggle+=1 end})
local slider=group:AddSlider("TestSlider",{Text="Slider",Min=0,Max=1,Rounding=2,Default=.5,Callback=function()calls.slider+=1 end})
local dropdown=group:AddDropdown("TestDropdown",{Text="Choice",Values={"A","B","C"},Default="A",AllowNull=true,FormatListValue=function(v)return"Label "..v end,Callback=function()calls.dropdown+=1 end})
dropdown:SetValueImages({A="rbxassetid://123"})
check(dropdown.Holder.ItemHolder.Holder:FindFirstChild("ButtonFrame_Label A"):FindFirstChild("AstralOptionImage")~=nil,"Dropdown preview images were not rendered")
local multi=group:AddDropdown("TestMulti",{Text="Multiple",Values={"A","B","C"},Multi=true,Default={"A","C"}})
local input=group:AddInput("TestInput",{Text="Input",Default="old",AllowEmpty=false,EmptyReset="reset",Callback=function()calls.input+=1 end})
local color=toggle:AddColorPicker("TestColor",{Default=Color3.fromRGB(20,50,80),Transparency=.2,Callback=function()calls.color+=1 end})
local keyPicker=toggle:AddKeyPicker("TestKey",{Text="Toggle",Default="Q",Mode="Toggle",SyncToggleState=true})
local press=group:AddLabel("Press"):AddKeyPicker("TestPress",{Text="Press",Default="E",Mode="Press",Callback=function()calls.press+=1 end})
local hold=group:AddLabel("Hold"):AddKeyPicker("TestHold",{Text="Hold",Default="R",Mode="Hold",Callback=function()calls.hold+=1 end})
check(calls.toggle==0 and calls.slider==0 and calls.dropdown==0 and calls.input==0 and calls.color==0,"UI construction activated gameplay callbacks")
local accidentalRespawns=0
local reset=group:AddButton({Text="Respawn",Func=function()accidentalRespawns+=1 end})
reset:Press();key("Q");key("Q",true)
check(accidentalRespawns==0 and calls.toggle==0,"Input during GUI startup activated gameplay")
Library:FinishStartup()
check(Native.ScreenGui==Library.ScreenGui and Library.ScreenGui.Name=="AstralTheWorstUIV2","Adapter rendered a second legacy GUI")
check(window.Raw.Frame==window.MainFrame and toggle.Raw.Frame==toggle.Holder,"Controls do not reference actual native frames")
check(not window.MainFrame.TopBar.Visible and window.MainFrame.TopBar.Size.Y.Offset==0,"The old title/version bar remained visible")
check(window.MainFrame.Holder.Position.Y.Offset==38 and window.MainFrame.Holder.BackgroundTransparency==1,"Title-bar gap or dark body layer remained")
check(Library.Scheme.BackgroundColor.R>.95 and Library.Scheme.FontColor.R<.2,"Default white-glass contrast was not applied")
check(color.Holder==color.Raw.Frame and color.Holder~=nil,"Inline native color picker did not expose its frame")
for _,name in ipairs({"Home","Player","Combat","Defense","Target","Blobman","Visual","Aim","Fun","Settings"})do
 check(tabs[name].Raw.Name==name,"Tab name changed: "..name)
 local button=tabs[name].Raw.Button
 check(button.Icon:FindFirstChild("AstralSectionIcon")~=nil and button.NameText.Position.X.Offset>=34,"Section icons overlap text or depend only on external images")
end
check(multi.Value.A and multi.Value.C and not multi.Value.B,"Multi default array was not converted to Astral's flag map")
toggle.Raw:Set(true);check(toggle.Value and calls.toggle==1,"Native toggle lost/doubled its callback")
toggle:SetValue(true);toggle:SetValue(true);check(calls.toggle==1,"Unchanged toggle values replayed gameplay callbacks")
slider.Raw:Set(.77);check(math.abs(slider.Value-.77)<1e-6 and calls.slider==1,"Native slider lost/doubled its value")
slider:SetValue(100);check(slider.Value==1 and slider.Raw.Value==1,"Slider did not clamp programmatic values")
local before=slider.Value;slider:SetValue(0/0);check(slider.Value==before,"Slider accepted NaN")
slider.Raw:Set("..");check(slider.Value==before,"Malformed native numeric input changed the slider")
dropdown.Raw:Set("Label B");check(dropdown.Value=="B"and calls.dropdown==1,"Dropdown leaked formatted labels into gameplay")
multi.Raw:Set({"A","B"});check(multi.Value.A and multi.Value.B and not multi.Value.C,"Native multi array did not become a boolean map")
multi:SetValue({C=true});check(multi.Value.C and not multi.Value.A,"Saved multi map failed to restore")
multi:SetValues({"B","C","D"});check(multi.Value.C and not multi.Value.A,"Refreshing options lost a still-valid selection")
dropdown:SetValue(nil);check(dropdown.Value==nil,"Nullable dropdown converted nil into a game selection")
input.Raw:Set("");check(input.Value=="reset"and calls.input==1,"Input empty reset changed")
color.Raw:Set(Color3.fromRGB(90,80,70),.6);check(color.Value.R==90/255 and color.Transparency==.6 and calls.color==1,"Color/transparency callback mismatch")
local dependency=group:AddDependencyBox();dependency:SetupDependencies({{toggle,true}})
local nested=dependency:AddDependencyBox();nested:SetupDependencies({{multi,"C"}})
local dependent=nested:AddSlider("Dependent",{Text="Dependent",Min=0,Max=10,Default=5})
toggle:SetValue(false);check(not dependent.Holder.Visible,"Nested dependency stayed visible")
toggle:SetValue(true);check(dependent.Holder.Visible,"Nested dependency failed to restore")
multi:SetValue({B=true});check(not dependent.Holder.Visible,"Dropdown dependency used array indexes instead of flags")
local label=group:AddLabel("Status",{Text="Ready",DoesWrap=true})
check(Library.Labels.Status==label,"Named status labels disappeared")
label:SetText("Working");check(label.Raw.Frame.TextName.Text=="Working","Dynamic label was not updated")
-- One dispatcher handles action keys; native binds only assign the key.
toggle:SetValue(false);local count=calls.toggle
key("Q");key("Q",true);check(toggle.Value and calls.toggle==count+1,"Toggle key activated twice through native+adapter listeners")
key("E");key("E",true);check(calls.press==1 and not press.Toggled,"Press key was not a single action")
key("R");check(hold:GetState()and calls.hold==1,"Hold did not begin")
UIS.Focused={};key("R",true);check(not hold:GetState()and calls.hold==2,"Focused textbox stranded a held action");UIS.Focused=nil
key("E",false,true);check(calls.press==1,"Processed typing input activated gameplay")
keyPicker:SetValue({"T","Toggle",{"LeftControl"}});toggle:SetValue(false)
key("T");key("T",true);check(not toggle.Value,"Missing modifier activated a key")
key("LeftControl");key("T");key("T",true);key("LeftControl",true);check(toggle.Value,"Imported modifier binding failed")
-- Native assignment publishes the new value without executing the action.
local oldCount=calls.toggle;keyPicker.Raw:Set("Y")
check(keyPicker.Value=="Y"and calls.toggle==oldCount,"Assigning a key activated its gameplay callback")
keyPicker:SetValue({"Q","Toggle",{}})
toggle:SetDisabled(true);count=calls.toggle;toggle.Raw:Set(false)
check(toggle.Value and calls.toggle==count,"Disabled native control changed gameplay")
toggle:SetDisabled(false)
local player=Instance.new("Player");player.Name="Second";player.DisplayName="Second"
Players.List[#Players.List+1]=player
local players=group:AddDropdown("PlayerTargets",{Text="Targets",SpecialType="Player",ExcludeLocalPlayer=true,Multi=true,AllowNull=true,FormatListValue=function(v)return v.Name end})
check(#players.Values==1 and players.Values[1]==player,"Player selector lost the live player objects")
players.Raw:Set({"Second"});check(players.Value[player]==true,"Player selector returned a name instead of a Player")
Players.PlayerRemoving:Fire(player);check(#players.Values==0 and not next(players.Value),"Leaving player remained selected")
local tabbox=tabs.Player:AddLeftTabbox("Pose")
local offset=tabbox:AddTab("Offset");local rotation=tabbox:AddTab("Rotation")
offset:AddSlider("OffsetX",{Text="X",Min=-10,Max=10,Default=0});rotation:AddSlider("RotationY",{Text="Y",Min=-180,Max=180,Default=0})
check(offset.Raw.Frame==rotation.Raw.Frame and offset.Raw.Container~=rotation.Raw.Container,"Subtabs did not use a native section group")
rotation:AddToggle("SearchTarget",{Text="Native Search Target",Default=false})
local search=Library.Taskbar.StartFrame.AllParentFakeFrame.SearchFrame.SearchBox
search.Text="native search target";search.FocusLost:Fire()
local found=Library.Taskbar.StartFrame.AllParentFakeFrame:FindFirstChild("FoundElement")
check(found~=nil,"Native taskbar search did not find Astral controls")
found.MouseButton1Up:Fire()
check(window.Raw.CurrentTab=="Player","Native search opened the wrong Astral tab")
local notification=Library:Notify({Title="Progress",Description="0/10",Persist=true})
notification:ChangeDescription("3/10");advance(.2)
check(notification.Frame and notification.Frame.Parent and notification.Frame:FindFirstChild("DescriptionText",true).Text=="3/10","Persistent native notification lost its live handle")
notification:Destroy();check(not notification.Frame.Parent,"Notification cancellation did not destroy its native frame")
local dialog=window:AddDialog("Conflict",{Title="Conflict",Description="Same key",FooterButtons={{Title="Keep"},{Title="Cancel"}}})
dialog:Destroy()
window.Raw:Toggle(false);check(not Library.Toggled,"Native close did not synchronize pointer/UI state")
window.Raw:Toggle(true);check(Library.Toggled,"Taskbar reopen did not synchronize pointer/UI state")
Library.Taskbar:ToggleWindow("astral",false);check(not Library.Toggled,"Taskbar bypassed the shared window toggle")
Library.Taskbar:ToggleWindow("astral",true);check(Library.Toggled,"Taskbar reopen did not restore the shared visibility")
local cleanup=0;Library:OnUnload(function()cleanup+=1 end)
-- The existing managers must work against the new widgets and original IDs.
-- JSON storage is a deterministic mock; manager serialization code is real.
SaveManager:SetLibrary(Library);SaveManager:SetFolder("Astral/Configs")
ThemeManager:SetLibrary(Library);ThemeManager:SetFolder("Astral/Themes")
SaveManager:BuildConfigSection(tabs.Settings)
ThemeManager:SetDefaultTheme(Presentation.Theme())
ThemeManager:ApplyToTab(tabs.Settings)
local themeOk,themeError=ThemeManager:ApplyTheme("Default");check(themeOk,tostring(themeError))
keyPicker:SetValue({"Q","Toggle",{"LCtrl"}})
multi:SetValue({B=true});slider:SetValue(.42);input:SetValue("saved")
local saved,success,saveError=SaveManager:SaveJSON("Roundtrip");check(success,tostring(saveError))
slider:SetValue(.17);input:SetValue("changed");multi:SetValue({C=true});keyPicker:SetValue({"Y","Hold",{}})
local loaded,loadError=SaveManager:LoadJSON(saved);check(loaded,tostring(loadError))
advance(.1) -- the unchanged SaveManager applies individual records via defer
check(math.abs(slider.Value-.42)<1e-6 and input.Value=="saved"and multi.Value.B and not multi.Value.C,"Original config managers lost control values")
check(keyPicker.Value=="Q"and keyPicker.Mode=="Toggle"and keyPicker.Modifiers[1]=="LCtrl","Original key/config shape was not preserved")
toggle:SetValue(false);key("LeftControl");key("Q");key("Q",true);key("LeftControl",true)
check(toggle.Value,"Legacy LCtrl modifier alias no longer works")
local savedTheme,themeSuccess=ThemeManager:SaveJSON();check(themeSuccess and savedTheme~=nil,"Theme export failed on the new GUI")
-- A real on-disk startup profile must not replay active gameplay switches.
local spin=group:AddToggle("SpinT",{Text="Character Spin",Default=false,Callback=function(value)if value then accidentalRespawns+=1 end end})
local unsafe=services.HttpService:JSONEncode({objects={{type="Toggle",idx="SpinT",value=true},{type="Toggle",idx="TestToggle",value=true}}})
files["Astral/Configs/settings/Unsafe.json"]=unsafe
local setAuto,autoError=SaveManager:SaveAutoloadConfig("Unsafe");check(setAuto,tostring(autoError))
toggle:SetValue(false);local countBefore=calls.toggle
Library:BeginStartup();SaveManager:LoadAutoloadConfig();advance(.1);Library:FinishStartup()
check(not spin.Value and not toggle.Value and accidentalRespawns==0 and calls.toggle==countBefore,"Saved active functions were replayed automatically on startup")
local manualOk=SaveManager:Load("Unsafe");advance(.1)
check(manualOk and spin.Value and accidentalRespawns==1,"Explicit manual config loading was removed instead of disabling startup replay")
-- New HUD is centered and contains neither currency nor elapsed time.
local widget=Library:AddDraggableLabel("astral");Players.MaxPlayers=25
local hud=HUD.Install({Widget=widget,RunService=RunService,Players=Players,Player=localPlayer,Workspace=workspace,Stats=services.Stats})
check(widget.Centered and widget.Label.AnchorPoint.X==.5 and widget.Label.Position.X.Scale==.5,"Watermark is not centered")
check(not widget.Label.Text:find("Coins",1,true)and not widget.Label.Text:find(":",1,true),"Removed watermark currency/timer returned")
check(widget.Label:FindFirstChildOfClass("UICorner").CornerRadius.Scale==1 and widget.Label.BackgroundTransparency>.3,"Watermark does not use the rounded translucent style")
hud:Dispose()
local floating=Instance.new("Frame",Library.ScreenGui);floating.Name="ExamplePopup";Library:StyleFloatingPanel(floating)
check(floating:FindFirstChildOfClass("UICorner").CornerRadius.Offset==Presentation.Radius and floating.BackgroundColor3.R>.95,"Floating menu did not inherit the light rounded surface")
-- Long values cannot occupy the same pixels as their control labels.
local long=group:AddDropdown("LongValue",{Text="A readable label",Values={"A very long selected value that needs truncation"},Default=1})
local left=long.TextLabel.AbsolutePosition.X+long.TextLabel.AbsoluteSize.X
local right=long.Holder.SelectedItemBox.AbsolutePosition.X
check(left<=right,"Long dropdown value overlaps its label")
if TeleportMenu then
 local world=Instance.new("Folder");local beach=Instance.new("Part",world);beach.Name="Beach"
 local teleports=0
 local menu=TeleportMenu.Install({Library=Library,Locations=function()return{beach}end,Player={CharacterAdded=signal()},Workspace=workspace,
  RunService=RunService,Character=function()end,Teleport=function()teleports+=1 end})
 menu:SetVisible(true)
 check(menu.Frame.BackgroundColor3.R>.95 and menu.Frame.BackgroundTransparency>.3 and menu.Frame:FindFirstChildOfClass("UICorner").CornerRadius.Offset==Presentation.Radius,"Actual teleport menu did not inherit the new surface")
 check(teleports==0 and #menu.Rows==1,"Opening the teleport menu automatically moved the character")
 menu:Dispose()
end
advance(.3)
Library:Unload();Library:Unload();check(cleanup==1 and Library.Unloaded and Native.Unloaded,"Unload was not idempotent")
for _,connection in ipairs(Library.Connections)do check(not connection.Connected,"Adapter input survived unload")end
check(Native.ScreenGui==nil,"Native GUI survived unload")
print('PASS: '..checks..' actual TheWorstUIV2 controls, tabs, state/config shapes, callbacks, binds, dependencies, notifications and cleanup (mock GUI engine)')
