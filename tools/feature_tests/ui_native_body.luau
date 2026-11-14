-- Runs the full shipped native Library; mocks supply engine services only.
check(Library.ScreenGui and Library.ScreenGui.Parent==CoreGui,"Native library did not attach its root")
local calls=0
check(type(Library.BeginStartup)=="function"and type(Library.FinishStartup)=="function","Native UI has no initialization guard")
Library:BeginStartup()
Library.ForceCheckbox=true
local window=Library:CreateWindow({Title="astral",Footer="",Size=UDim2.fromOffset(680,540),ShowCustomCursor=false,ShowMobileButtons=false,AutoShow=true,Animations={ToggleWindow=true},CornerRadius=18,Icon="sparkles",Compact=true,IconSidebar=true,SidebarCompactWidth=52,MinContainerWidth=440})
check(window.MainFrame.Visible and Library.Toggled and window.MainFrame.BackgroundTransparency==Library.Scheme.GlassTransparency,"AutoShow did not display the real window before any render tick")
Library.Animations.ToggleWindow=false
local tab=window:AddTab("Defense","shield")
local group=tab:AddLeftGroupbox("Protection")
local toggle=group:AddToggle("SpinT",{Text="Character Spin",Default=false,Callback=function(value)if value then calls+=1 end end})
toggle:AddKeyPicker("CSKey",{Text="Spin",Default="None",Mode="Toggle",SyncToggleState=true})
local resets=0
local resetButton=group:AddButton("Respawn",function()resets+=1 end)
resetButton:AddKeyPicker("ResetCharKey",{Text="Respawn",Default="None",Mode="Press"})
local mouseLock=group:AddLabel("Mouse Lock"):AddKeyPicker("MouseLockKey",{Default="LeftAlt",Mode="Toggle"})
resetButton.Base.MouseButton1Click:Fire()
check(resets==0,"Startup click-through invoked Respawn")
local slider=group:AddSlider("WalkSpeed",{Text="Walk Speed",Default=16,Min=0,Max=100,Rounding=0})
local dropdown=group:AddDropdown("AntiKickType",{Text="Anti Kick Item",Values={"Pallet","Food"},Default=1})
dropdown:SetValueImages({Pallet="rbxassetid://123",Food="rbxassetid://456"})
local watched=0;toggle:OnChanged(function()watched+=1 end)
check(watched==0,"Registering a native toggle observer invoked a gameplay action")
toggle:SetValue(true);toggle:SetValue(false)
check(calls==0 and watched==0,"Native startup replayed configured gameplay callbacks")
-- Run the actual Main startup order: create controls, replace the default
-- theme, then refresh registry callbacks. This used to erase the gradient colors.
ThemeManager:SetLibrary(Library)
ThemeManager:SetDefaultTheme(UIStyle.Theme())
for _,name in {"HeaderColor","BodyTopColor","BodyBottomColor","CheckColor"}do
    check(typeof(Library.Scheme[name])=="Color3","Default theme erased "..name)
end
Library:FinishStartup()
check(calls==0 and not toggle.Value,"Native control construction enabled a disabled gameplay toggle")
key("LeftAlt");key("LeftAlt",true)
check(calls==0 and not toggle.Value and resets==0,"Alt invoked an unbound spin or Respawn action")
check(Library.Options.ResetCharKey.Value=="None" and Library.Options.CSKey.Value=="None","Gameplay bindings acquired a default action key")
toggle:SetValue(true);check(calls==1 and toggle.Value and watched==1,"Native toggle no longer invokes an explicit action")
toggle:SetValue(true);check(calls==1 and watched==1,"Unchanged values replayed gameplay callbacks")
toggle:SetValue(false)
check(window.MainFrame.AbsoluteSize.X<=workspace.CurrentCamera.ViewportSize.X-64,"Window is wider than its viewport")
check(Library.Tabs.Defense==tab and #Library.TabButtons==1,"Native sidebar tabs were not registered")
local rail=Library.TabButtons[1].Label.Parent.Parent.Parent
local surface=window.MainFrame:FindFirstChild("BodySurface")
check(not Library.TabButtons[1].Label.Visible and Library.TabButtons[1].Icon.Visible,"Compact sidebar shows text or hides the original icon")
check(rail.Size.X.Offset==52 and surface and surface.Position.X.Offset==0,"Icon rail is not separated by the requested unified body")
window.MainFrame.Size=UDim2.fromOffset(500,420);window:SetSidebarWidth(180)
check(window:GetSidebarWidth()==52 and not Library.TabButtons[1].Label.Visible,"An old layout restored a full-width text sidebar")
check(surface.Size.X.Offset==0 and Library.WindowContainer.Size.X.Offset==-53,"Sidebar and body resize independently and overlap")
resetButton.Base.MouseButton1Click:Fire();check(resets==1,"Explicit Respawn button click no longer works")
check(slider.Value==16 and dropdown.Value=="Pallet","Native controls lost declared defaults")
local itemImages={}
for _,node in ipairs(Library.ScreenGui:GetDescendants())do
    if node:IsA("ImageLabel")and node.Visible then itemImages[node.Image]=true end
end
check(itemImages["rbxassetid://123"]and itemImages["rbxassetid://456"],"Native dropdown did not render provided item images")
local widget=Library:AddDraggableLabel({Text="astral",Icon="sparkles"})
check(widget.Label and table.find(Library.DraggableElements,widget.Label),"Native watermark was not registered for dragging")
check(widget.Label:FindFirstChildOfClass("UIPadding").PaddingLeft.Offset>=28,"Watermark icon has no reserved space")

-- Reference skin checks run on the actual native instances, not a separate HTML UI.
check(toggle.Holder.Size.Y.Offset==40 and toggle.TextLabel.FontFace.Family=="BuilderSansBold","Reference row height or bold caption changed")
check(toggle.TextLabel.TextTransparency==0,"Inactive captions are dimmed compared with the reference")
check(toggle.Parent.Holder.BackgroundTransparency==1 and not toggle.Parent.Holder:FindFirstChildOfClass("UIStroke"),"The old outer section cards returned")
local search=window.MainFrame:FindFirstChild("SearchField",true)
check(search and search.PlaceholderText=="Search"and search.TextXAlignment==Enum.TextXAlignment.Left,"Header search is blank or misaligned")
check(window.MainFrame.ClassName=="Frame"and not surface:FindFirstChildOfClass("UICorner"),"The header/body are still separate rounded windows")
local header=window.MainFrame:FindFirstChild("HeaderSurface")
check(header and header.Size.Y.Offset==44 and surface.Position.Y.Offset==44,"Header and body do not use the reference geometry")
check(header.BackgroundColor3:ToHex()=="17191c" and window.MainFrame:FindFirstChildOfClass("UIGradient"),"Reference palette or vertical body shading changed")
check(window.MainFrame:FindFirstChild("MinimizeMenu",true)and window.MainFrame:FindFirstChild("CloseMenu",true),"Reference header controls are missing")
local previousCalls,previousWatched=calls,watched
local originalParent=dropdown.Holder.Parent
local panel=Library:AttachSettings(toggle,{dropdown})
check(dropdown.Holder.Parent==panel.Body and Library.Options.AntiKickType==dropdown,"Gear panel replaced a settings object or lost its ID")
check(toggle.Holder:FindFirstChild("Checkbox").Position.X.Offset==-42,"The checkbox did not leave room for its gear on the right")
panel.Gear.Activated:Fire()
check(panel.Frame.Visible and calls==previousCalls and watched==previousWatched,"Opening settings toggled a gameplay feature")
dropdown:SetValue("Food");check(dropdown.Value=="Food","A relocated native combo no longer changes settings")
Library:Toggle(false);check(not panel.Frame.Visible,"Settings panel remained over the game after hiding the menu")
Library:Toggle(true)
local dependency=group:AddDependencyBox();dependency:SetupDependencies({{toggle,true}})
dependency:AddSlider("DependentValue",{Text="Existing dependent setting",Default=3,Min=0,Max=10})
Library:AttachDependencySettings()
check(dependency.DependencyPanelOwner==toggle and dependency.Holder.Parent==panel.Body,"Native dependent settings were not attached to their owner's gear")
check(not toggle.Value and dependency.Visible,"Configuration cannot be opened while its action is off")
local button=group:AddButton("Bound action",function()end)
local buttonHolder=button.Base.Parent
button:AddKeyPicker("BoundAction",{Default="None",Mode="Press"})
check(button.Base.Parent==buttonHolder and buttonHolder.Size.Y.Offset==40,"Adding a bind wrapped the button in a second short row")
local label=group:AddLabel("Label action");label:AddKeyPicker("LabelAction",{Default="Z",Mode="Press"})
check(label.Holder.Name=="LabelRow"and label.Holder.Size.Y.Offset==40,"A labeled bind created a stray line or icon")
local panelSignals=table.clone(panel.Connections)
panel.Gear.Activated:Fire();toggle:Destroy()
check(panel.Disposed and not panel.Frame.Parent and dropdown.Holder.Parent==originalParent,"Destroying an owner leaked its panel or destroyed shared settings")
for _,connection in panelSignals do check(not connection.Connected,"Gear listener survived owner disposal")end
-- The real theme settings build and default selection also refresh registry
-- callbacks. Reuse their actual source rather than a fake theme manager.
local paletteToggle=group:AddToggle("ThemePaletteToggle",{Text="Palette check",Default=false})
local sectionPadding=group.Container:FindFirstChildOfClass("UIPadding")
check(sectionPadding.PaddingLeft.Offset>=2 and sectionPadding.PaddingRight.Offset>=2 and sectionPadding.PaddingTop.Offset>=2 and sectionPadding.PaddingBottom.Offset>=2,"Section scrolling clips its row outline")
local popupPadding
-- Owner-disposal above destroys its panel, so verify popup insets on a new owner.
local insetOwner=group:AddToggle("OutlineInsetOwner",{Text="Settings outline",Default=false})
local insetPanel=Library:AttachSettings(insetOwner,{})
popupPadding=insetPanel.Body:FindFirstChildOfClass("UIPadding")
check(popupPadding.PaddingLeft.Offset>=2 and popupPadding.PaddingRight.Offset>=2,"Gear settings clip their row outline")
check(Library.Scheme.MainColor:ToHex()=="25272a" and Library.Scheme.FontColor.R>.85 and Library.Scheme.GlassTransparency>=.5 and group.Container.BackgroundTransparency==1,"GUI does not preserve the reference charcoal tint and visible game background")
check(paletteToggle.Holder.BackgroundTransparency==Library.Scheme.RowTransparency and Library.Scheme.RowTransparency>=.9,"Opaque rows obscure the game through the glass menu")
local settingsTab=window:AddTab("Settings","settings")
ThemeManager:ApplyToTab(settingsTab)
local themed,themeError=UIStyle.ApplyStartupTheme(ThemeManager,Library)
check(themed~=false,"Default theme selection failed: "..tostring(themeError))
for _,name in {"HeaderColor","BodyTopColor","BodyBottomColor","CheckColor"}do
    check(typeof(Library.Scheme[name])=="Color3","Theme application erased "..name)
end
paletteToggle:SetValue(true);paletteToggle:SetValue(false)
check(not paletteToggle.Value and paletteToggle.Holder:FindFirstChild("Checkbox").BackgroundColor3==Library.Scheme.CheckColor,"Checkbox palette broke after applying the theme")
check(window.MainFrame.Visible and window.MainFrame.BackgroundTransparency==Library.Scheme.GlassTransparency,"Applying a theme hid the menu")
if BuildPCLDRow then
    local espSection=tab:AddRightGroupbox("ESP")
    local server={FillColor=Color3.fromRGB(170,20,220),OutlineColor=Color3.new(),NameColor=Color3.new(1,1,1),NameOutlineColor=Color3.new()}
    local espConfig={Server=server};local updates=0
    local api={SetRuntimeToggle=function()end,WakeRuntimeGate=function()end,SetSmoothPCLDConnection=function()end,UpdateESP=function()end,RefreshESP=function()end,SnapPCLDESP=function()end,PCLDAvatars={Refresh=function()end,SetMode=function()end}}
    BuildPCLDRow(espSection,Library.Toggles,espConfig,api,function(kind,key,value)espConfig[kind][key]=value;updates+=1 end)
    local pcld=Library.Toggles.PCLDESPT;local pickers=0
    for _,addon in pcld.Addons do if addon.Type=="ColorPicker"then pickers+=1 end end
    check(pickers==2 and Library.Options.PCLDFill and Library.Options.PCLDOutline,"PCLD is missing independent fill/outline colors")
    local chosen=Color3.fromRGB(40,120,220);local beforeColor=updates
    Library.Options.PCLDFill:SetValueRGB(chosen)
    check(server.FillColor:ToHex()==chosen:ToHex() and server.OutlineColor:ToHex()=="000000" and updates==beforeColor+1,"PCLD fill overwrites its independent outline")
    Library.Options.PCLDOutline:SetValueRGB(Color3.fromRGB(240,40,60))
    check(server.OutlineColor:ToHex()=="f0283c" and server.FillColor:ToHex()==chosen:ToHex(),"PCLD outline overwrites fill")
    local hidden=tab:AddRightGroupbox("ESP Settings");hidden:SetVisible(false)
    local object=setmetatable({Items={"Train"},Images={Train="rbxassetid://123"},Config={},Updates=0},{__index=ObjectESP})
    for _,kind in {"Blobman","Gucci","Item"}do object.Config[kind]={FillColor=chosen,OutlineColor=chosen,NameColor=chosen,NameOutlineColor=chosen,FillTransparency=.5,OutlineTransparency=0}end
    function object:Update()self.Updates+=1 end
    object:BuildUI(espSection,hidden,nil)
    Library:AttachDependencySettings()
    for _,kind in {"Blobman","Gucci","Item"}do
        local row=Library.Toggles["Astral"..kind.."ESP"]
        check(row.SettingsPanel and row.SettingsGear,"Flat ESP has no settings gear for "..kind)
        local before=object.Updates;row.SettingsGear.Activated:Fire()
        check(object.Updates==before and not row.Value,"Opening ESP settings enabled its action")
    end
    check(not hidden.Visible and not hidden.BoxHolder.Visible,"The old standalone ESP Config panel is still visible")
end
if BuildExtraPCLDRow then
    local section=tab:AddLeftGroupbox("Additional ESP")
    BuildExtraPCLDRow(section)
    local row=Library.Toggles.NewESP_PCLDESP;local pickers=0
    for _,addon in row.Addons do if addon.Type=="ColorPicker"then pickers+=1 end end
    check(pickers==1,"The embedded PCLD row still shows extra palettes")
    local updates=0
    BindExtraPCLDColor(Library.Options,function(fill,outline)
        updates+=1
        check(fill:ToHex()=="2878dc" and outline:ToHex()==fill:ToHex(),"The embedded PCLD fill and outline do not share one chosen color")
    end)
    Library.Options.NewESP_PCLD_ChamsColor:SetValueRGB(Color3.fromRGB(40,120,220))
    check(updates==1,"The embedded PCLD color did not update its renderer")
end
-- Regression for the reported blue opaque window and disappearing icons.
check(window.MainFrame.ClassName=="Frame"and window.MainFrame.BackgroundTransparency==.55,"The restored glass window regressed to an opaque/composited surface")
check(Library.Scheme.FontColor:ToHex()=="e7eaee"and toggle.Destroyed,"The light reference palette was not retained after theme application")
for name,icon in pairs(UIStyle.Icons)do
    local original=window:AddTab("Original icon "..name,icon)
    local entry=Library.TabButtons[#Library.TabButtons]
    check(original and entry.Icon and entry.Icon.Visible and entry.Icon.Image~="","Original sidebar icon missing: "..name)
    local tint=entry.Icon.ImageColor3
    check(math.min(tint.R,tint.G,tint.B)>.5 and entry.Icon.ImageTransparency<=.5,"Original sidebar icon became too dark: "..name)
end
Library.Animations.ToggleWindow=true
Library:Toggle(false)
for _=1,60 do RunService.RenderStepped:Fire(1/60)end
Library:Toggle(true)
for _=1,60 do RunService.RenderStepped:Fire(1/60)end
check(window.MainFrame.Visible and window.MainFrame.BackgroundTransparency==.55,"Opening restored the wrong window transparency")
for _,entry in ipairs(Library.TabButtons)do
    check(entry.Icon and entry.Icon.ImageTransparency<=.5,"Menu animation left a sidebar icon faded out")
end
-- Additional regression cases executed inside the shipped native GUI harness.
local resize=window.MainFrame:FindFirstChild("Resize")
local glyph=resize and resize:FindFirstChild("ResizeGlyph")
check(resize and resize.Size.X.Offset>=26 and glyph and glyph.Image~="","Resize affordance is absent or has no real icon")
check(glyph.ImageColor3==Library.Scheme.FontColor and glyph.ImageTransparency==0 and glyph.ZIndex>resize.ZIndex,"Resize icon is dim or occluded")
check(glyph.Position.X.Offset>=0 and glyph.Position.X.Offset+glyph.Size.X.Offset<=resize.Size.X.Offset,"Resize icon is clipped by its hit area")

local action=group:AddToggle("ReadabilityOwner",{Text="Gucci settings",Default=false})
local choices=group:AddDropdown("ReadabilityChoices",{Text="Gucci Type",Values={"Blobman","Tractor","Train"},Default="Blobman"})
local previousParent=choices.Holder.Parent
local config=Library:AttachSettings(action,{choices})
config.Gear.Activated:Fire()
check(config.Frame.Visible and config.Frame.Active and config.Frame.BackgroundTransparency==0,"Settings still blend with the window or click through")
check(config.Frame.BackgroundColor3==Library.Scheme.WhiteColor and config.Frame:FindFirstChild("AstralPopupGradient")~=nil,"Popup introduced another palette")
check(window.MainFrame.BackgroundTransparency==.55,"Popup styling changed the main glass window")
check(Library.Scheme.HeaderTransparency==.45 and Library.Scheme.RowTransparency==.92,"Popup styling changed the watermark or normal rows")
choices.Menu:Open()
check(choices.Menu.Active and choices.Menu.Menu.Active and choices.Menu.Menu.BackgroundTransparency==0,"Dropdown menu still blends with settings")
local marks=0;local names={}
for _,row in ipairs(choices.Menu.Menu:GetChildren())do
 if row.Name=="DropdownOption"and row.Visible then
  local caption=row:FindFirstChildOfClass("TextButton")
  local mark=row:FindFirstChild("SelectionMark")
  check(caption and caption.TextTransparency<=.08,"Enabled choice is too dim")
  names[caption.Text]=true
  if mark and mark.Visible then marks+=1 end
 end
end
check(names.Blobman and names.Tractor and names.Train and marks==1,"Choices or selected marker are missing")
choices.Holder:GetPropertyChangedSignal("AbsolutePosition"):Fire()
check(choices.Menu.Active,"Moving a setting inside its gear closes the combo unexpectedly")
choices:SetValue("Train")
marks=0
for _,row in ipairs(choices.Menu.Menu:GetChildren())do
 local mark=row:FindFirstChild("SelectionMark")
 if row.Visible and mark and mark.Visible then
  marks+=1;check(row:FindFirstChildOfClass("TextButton").Text=="Train","Selection marker did not follow choice")
 end
end
check(marks==1,"Dropdown selection markers are ambiguous")
config.Frame.Visible=false
check(not choices.Menu.Active and not choices.Menu.Menu.Visible,"Closing gear leaves an orphan menu over the game")
config.Gear.Activated:Fire();choices.Menu:Open();action:Destroy()
check(config.Disposed and not choices.Menu.Active and choices.Holder.Parent==previousParent,"Destroying an owner loses settings or retains its popup")

local tweaks=tab:AddLeftTabbox("Game Tweaks test")
local line=tweaks:AddTab(nil,"spline");local hole=tweaks:AddTab(nil,"orbit")
check(tweaks.Holder.BackgroundTransparency==1,"Game Tweaks has an extra gray surface unlike other groups")
check(line.ButtonHolder.BackgroundTransparency==1 and hole.ButtonHolder.BackgroundTransparency==1,"Internal tab buttons create a different solid color")
hole:Show();line:Show()
check(line.ButtonHolder.BackgroundTransparency==1 and hole.ButtonHolder.BackgroundTransparency==1,"Changing internal tabs restores the solid bar")

local floating=Instance.new("Frame",Library.Floats)
Library:StyleFloatingPanel(floating)
check(floating.BackgroundTransparency==Library.Scheme.GlassTransparency and floating.BackgroundColor3==Library.Scheme.WhiteColor and floating:FindFirstChild("AstralPopupGradient")~=nil,"Floating panel does not match the main glass surface")
floating:Destroy()
print('PASS: settings, dropdown selection/lifecycle, Game Tweaks consistency and resize visibility')

if BuildHomeProfile then
 local home=window:AddTab("Main layout test","house")
 Library:BeginStartup()
 local profile=BuildHomeProfile({Home=home},{DisplayName="TestPlayer",UserId=123},{GetUserThumbnailAsync=function()return "rbxassetid://123456"end})
 Library:FinishStartup()
 local image=Library.Options.AstralHomeAvatar
 check(image and image.Type=="Image" and image.Height==150 and image.Holder.Parent==profile.Container,"Main avatar missing or outside profile")
 check(profile.BoxHolder.LayoutOrder==-20,"Profile is not first in Main")
 local character=window:AddTab("Character layout test","user")
 Library:BeginStartup();BuildCharacterLayout({Player=character});Library:FinishStartup()
 local movement=character.Groupboxes.Movement;local utility=character.Groupboxes.Character
 check(movement and utility and utility.BoxHolder.LayoutOrder==-20,"Character sections not balanced")
 check(not character.Groupboxes.Values.Visible and not character.Groupboxes.Values.BoxHolder.Visible,"Old standalone values section still occupies space")
 for toggle,id in pairs({FlyT="FlightSpeedS",WalkspeedT="WalkspeedS",JumpPowerT="JumpPowerS",SpinT="SpinS",AstralWallClimb="AstralClimbSpeed",AstralSlideTP="AstralSlideTPDuration"})do
  local owner=Library.Toggles[toggle];local setting=Library.Options[id]
  check(owner.SettingsPanel and setting.Holder.Parent==owner.SettingsPanel.Body,"Movement setting is not attached to its feature: "..toggle)
 end
 check(Library.Toggles.AstralAntiAFK.Holder.Parent==utility.Container and Library.Toggles.FlyT.Holder.Parent==movement.Container,"Movement and utility rows mixed together")
 local popup=Library.Toggles.FlyT.SettingsPanel
 popup.Gear.Activated:Fire()
 local grad=popup.Frame:FindFirstChild("AstralPopupGradient")
 check(popup.Frame.BackgroundTransparency==0 and popup.Frame.BackgroundColor3==Library.Scheme.WhiteColor,"Settings do not cover controls behind them")
 check(grad and grad.Color.Keypoints[1].Value:ToHex()==Library.Scheme.BodyTopColor:ToHex()and grad.Color.Keypoints[2].Value:ToHex()==Library.Scheme.BodyBottomColor:ToHex(),"Settings use a different palette from main GUI")
 popup.Frame.Visible=false
end
if BuildMergedCharacterGroups then
 local tab=window:AddTab("Merged Character layout","user")
 local left=tab:AddLeftGroupbox("Left reference").BoxHolder.Parent;local right=tab:AddRightGroupbox("Right reference").BoxHolder.Parent
 local groups=BuildMergedCharacterGroups(tab)
 check(#groups==6,"Merged Character layout lost sections")
 check(tab.Groupboxes["Movement Settings"].BoxHolder.Parent==left and tab.Groupboxes["Character Extras"].BoxHolder.Parent==left and tab.Groupboxes["Animation Presets"].BoxHolder.Parent==left,"Merged movement/appearance sections mixed into right column")
 check(tab.Groupboxes.Teleport.BoxHolder.Parent==right and tab.Groupboxes["Players Extras"].BoxHolder.Parent==right and tab.Groupboxes["Coin Farm"].BoxHolder.Parent==right,"Merged player/action sections mixed into left column")
 check(tab.Groupboxes["Movement Settings"].BoxHolder.LayoutOrder<tab.Groupboxes["Animation Presets"].BoxHolder.LayoutOrder,"Merged section order is unstable")
end
local signalsBefore=table.clone(Library.Signals)
local actionListeners=table.clone(UIS.InputBegan.Connections)
local releaseListeners=table.clone(UIS.InputEnded.Connections)
Library:Unload()
for _,connection in ipairs(signalsBefore)do check(not connection.Connected,"Native UI service listener survived unload")end
for _,connection in actionListeners do check(not connection.Connected,"Control input listener survived unloading named tabs")end
for _,connection in releaseListeners do check(not connection.Connected,"Control release listener survived unloading named tabs")end
check(Library.Unloaded and Library.ScreenGui==nil and runtime.Library==nil,"Native UI did not finish unload")
print('PASS: '..checks..' native sidebar control defaults, explicit toggle input, Alt safety, dropdown imagery, draggable HUD and unload checks (mocked)')
