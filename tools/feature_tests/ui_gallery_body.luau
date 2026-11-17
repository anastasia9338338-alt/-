-- Same native renderer and style controller; no browser/native Roblox claims.
local oldCalls=calls
local pending,requests={},0
local appearance=Appearance.Install({Library=Library,Window=window,Tab=tabs.GUI,DefaultSource="12345",
    Resolve=function(source,kind,callback)requests+=1;pending[source]=callback end})
Library:OnUnload(function()appearance:Dispose()end)
check(calls==oldCalls and #appearance.Cards==10,"Building the gallery ran gameplay actions or lost a wallpaper")
check(Catalog.Items[1].Source=="https://i.pinimg.com/736x/1f/e5/29/1fe529587285dae0fd004497ac8d2cc1.jpg" and Catalog.Items[2].Source=="https://i.pinimg.com/736x/90/6f/58/906f58d7915dc3d12b1c27fed66a0177.jpg","User-specified photos were replaced or their URLs stayed concatenated")
check(not Library.Options.AstralGUIFrameWidth and not Library.Options.AstralGUIFrameURL and not Library.Toggles.AstralGUIFrameEnabled,"Frame editor was not removed")
check(appearance.Asset=="rbxassetid://12345" and requests==0,"Default Roblox background caused a network download")
local mainRecord=appearance.Surfaces[window.MainFrame]
check(mainRecord and mainRecord.Image.Image==appearance.Asset and mainRecord.Image.ZIndex<window.MainFrame.ZIndex,"Wallpaper was not placed under the window content")
check(window.MainFrame.BackgroundTransparency==1 and mainRecord.Image.BackgroundTransparency==.3,"Wallpaper did not preserve the user's window opacity")
check(group.Holder.BackgroundTransparency>=.78,"Tab group backplates completely cover the wallpaper")
local hud=Library:AddDraggableLabel("astral | 80 ms",UIStyle.BrandIcon)
Library:RegisterArtworkSurface(hud.Label)
local hudRecord=appearance.Surfaces[hud.Label]
check(hudRecord and hudRecord.Image.Image==appearance.Asset,"HUD did not inherit the shared wallpaper")
hud.Label.Position=UDim2.fromOffset(240,150);appearance:ApplySurfaces()
check(hudRecord.Image.Position==UDim2.fromOffset(hud.Label.AbsolutePosition.X,hud.Label.AbsolutePosition.Y),"HUD background did not follow drag position")
local position=hud.Label.Position
appearance:Choose(Catalog.Items[1]);local first=pending[Catalog.Items[1].Source]
appearance:Choose(Catalog.Items[2]);local second=pending[Catalog.Items[2].Source]
second("asset://second.jpg");first("asset://first.jpg")
check(appearance.Asset=="asset://second.jpg" and hudRecord.Image.Image==appearance.Asset and mainRecord.Image.Image==appearance.Asset,"An obsolete image load overwrote a newer selection or left mismatched surfaces")
check(hud.Label.Position==position,"Wallpaper updates reset the user's HUD position")
owner.SettingsGear.Activated:Fire()
local settingsRecord=appearance.Surfaces[owner.SettingsPanel.Frame]
check(settingsRecord and settingsRecord.Image.Image==appearance.Asset,"Function settings did not share the selected background")
owner.SettingsPanel.Frame.Visible=false
local custom="https://example.com/own.jpg"
Library.Options.AstralGUIBackgroundURL:SetValue(custom);pending[custom]("asset://own.jpg")
check(appearance.Asset=="asset://own.jpg","Custom URL no longer resolves to an image")
Library.Toggles.AstralGUIBackgroundEnabled:SetValue(false)
check(not mainRecord.Image.Visible and window.MainFrame.BackgroundTransparency==.3,"Disabling wallpapers failed to restore the plain theme")
Library.Toggles.AstralGUIBackgroundEnabled:SetValue(true)
check(mainRecord.Image.Visible and mainRecord.Image.Image=="asset://own.jpg","Re-enabling lost the chosen background")
Library.Scheme.AccentColor=Color3.fromRGB(45,180,210);Library:UpdateColorsUsingRegistry()
for _,record in ipairs(Library.TabButtons)do if record.Icon then check(record.Icon.ImageColor3==Library.Scheme.AccentColor,"Sidebar icon did not follow theme accent")end end
check(window.MainFrame:FindFirstChild("AstralBrandIcon",true).ImageColor3==Library.Scheme.AccentColor,"Astral header logo did not follow the GUI accent")
check(hud.Label:FindFirstChildOfClass("ImageLabel").ImageColor3==Library.Scheme.AccentColor,"Watermark logo did not follow the GUI accent")
check(window.MainFrame:FindFirstChild("Container").BackgroundTransparency==1,"Native tab container still blocks wallpapers")
local railOwner=group:AddToggle("ReferenceRailTest",{Text="Long option name",Default=false})
railOwner:AddKeyPicker("ReferenceRailBind",{Default="None",Mode="Toggle",SyncToggleState=true})
local railSettings=group:AddDependencyBox();railSettings:SetupDependencies({{railOwner,true}})
railSettings:AddSlider("ReferenceRailValue",{Text="Value",Default=1,Min=0,Max=5})
Library:AttachDependencySettings()
local reserved=railOwner.TextLabel.Size
Library.Options.AstralGUITextScale:SetValue(1.2)
check(railOwner.Holder.Size.Y.Offset>=26 and railOwner.Control.Position.X.Offset==-30 and railOwner.SettingsGear.Position.X.Offset==-3,"Activation and gear controls no longer share the same fixed rail")
check(railOwner.AddonHost.Position.X.Offset==-72 and railOwner.TextLabel.Size.X.Offset==reserved.X.Offset,"Font/style refresh rolled back reserved bind/settings space")
tabs.GUI:Show()
check(appearance.GalleryActive<=2,"Gallery created an unbounded image loading burst")
appearance:Dispose()
for _,record in pairs(appearance.Surfaces)do check(false,"Disposed wallpaper surface survived")end
check(not appearance.Library.AppearanceController,"Unloaded gallery remained attached to the library")
check(calls==oldCalls,"Wallpaper/layout edits triggered a gameplay feature")
