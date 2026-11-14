if GUIAppearance then
 ValidateGUIAssetLifetime()
 local requests={};local function resolve(source,key,kind,done,empty,numeric,keep)requests[#requests+1]={Source=source,Done=done,Keep=keep}end
 local guiTab=window:AddTab('GUI','image');Library:BeginStartup()
 local a,assets,styler=BuildGUIAppearance(window,guiTab,resolve);Library:FinishStartup();a:Sync();styler:Sync()
 local opt,tog=Library.Options,Library.Toggles
 local originalSize=window.MainFrame.Size
 check(not a.Background.Visible and not a.Layer.Visible,'Default GUI changed with empty image links')
 opt.AstralGUIBackgroundURL:SetValue('https://images.example/cat.png');local old=requests[#requests]
 opt.AstralGUIBackgroundURL:SetValue('https://images.example/landscape.png');old.Done('rbxasset://old.png')
 check(a.Background.Image=='','Stale URL overwrote the chosen image');requests[#requests].Done('rbxasset://landscape.png')
 check(a.Background.Visible and a.PreviewImages.Background.ScaleType==Enum.ScaleType.Stretch,'Landscape preview not stretched horizontally')
 guiTab.Container.Visible=true;a:Animate();advance(.25)
 check(math.abs(a.PreviewImages.Background.Rotation)>0 and math.abs(a.PreviewImages.Background.Rotation)<=2,'Preview has no gentle motion')
 tog.AstralGUIPreviewMotion:SetValue(false);check(a.PreviewImages.Background.Rotation==0 and not a.MotionConnection,'Disabled preview motion continues')
 local pop=Instance.new('Frame',Library.Floats);pop.Size=UDim2.fromOffset(240,200);pop.Position=UDim2.fromOffset(40,60)
 Library:StyleFloatingPanel(pop);tog.AstralGUIFloatingBackground:SetValue(true)
 local surface=a.Surfaces[pop]
 check(surface and surface.Image.Visible and surface.Image.Image==a.Background.Image and surface.Image.Parent==pop.Parent,'Detached panel does not receive artwork')
 check(surface.Image.Parent~=pop and surface.Image.Active==false,'Floating image enters its panel layout or steals input')
 local teleports=TeleportMenu.Install({Library=Library,Workspace=workspace,Locations=function()return{}end,Player={CharacterAdded=signal()},RunService=RunService})
 teleports:SetVisible(true)
 check(a.Surfaces[teleports.Frame].Image.Visible and teleports.Frame.BackgroundTransparency==1,'Teleport menu ignores the selected floating wallpaper')
 teleports:SetVisible(false);teleports:SetVisible(true)
 check(teleports.Frame.BackgroundTransparency==1,'Opening teleport menu removes the floating wallpaper')
 tog.AstralGUIFloatingBackground:SetValue(false);check(not surface.Image.Visible and pop.BackgroundTransparency==Library.Scheme.GlassTransparency,'Floating wallpaper does not restore panel background')
 check(teleports.Frame.BackgroundTransparency==Library.Scheme.GlassTransparency,'Teleport menu lost glass alpha after background disable')
 teleports:Dispose()
 opt.AstralGUIFrameURL:SetValue('https://images.example/frost.png');requests[#requests].Done('rbxasset://frost.png');advance(.2)
 check(a.Assets.Frame.Data and a.Assets.Frame.Data.Removed>0,'Baked checkerboard was not removed')
 check(a.Layer.Parent==window.MainFrame.Parent and a.Layer.Position.X.Offset<window.MainFrame.AbsolutePosition.X,'Frame still overlays content instead of surrounding window')
 check(window.MainFrame.Size==originalSize,'Frame changes window/content dimensions')
 check(a.FrameTexture and not a.FrameTexture.Destroyed,'Rounded frame texture missing')
 local tex=a.FrameTexture;local mid=(math.floor(tex.Size.Y/2)*tex.Size.X+math.floor(tex.Size.X/2))*4
 check(buffer.readu8(tex.Pixels,mid+3)==0 and buffer.readu8(tex.Pixels,3)==0,'Frame has an opaque center or square outer corners')
 local current=a.FrameTexture;window.MainFrame.Size=UDim2.fromOffset(760,610);window.MainFrame:GetPropertyChangedSignal('AbsoluteSize'):Fire();advance(.2)
 check(current.Destroyed and a.FrameTexture~=current,'Resize leaks old frame texture')
 opt.AstralGUIFrameWidth:SetValue(60);advance(.2);check(window.MainFrame.Size.X.Offset==760,'Wide frame squeezes window')
 tog.AstralGUIFrameMatchTheme:SetValue(true)
 check(a.FrameGradient.Enabled,'Frame does not use theme gradient')
 opt.AstralGUIFrameURL:SetValue('');advance(.2);check(not a.Layer.Visible,'Cleared frame remains visible')
 -- Style editing uses real native control objects and does not alter callbacks.
 tog.AstralGUIFunctionIcons:SetValue(true);tog.AstralGUISeparators:SetValue(true)
 local iconCount,dividerCount=0,0
 for _,v in ipairs(Library.ScreenGui:GetDescendants())do
  if v.Name=='AstralStyleIcon'and v.Visible then iconCount+=1 end
  if v.Name=='AstralFunctionDivider'and v.Visible then dividerCount+=1 end
 end
 check(iconCount>0 and dividerCount>0,'Function icon/divider customization missing')
 opt.AstralGUIFont:SetValue('Gotham');opt.AstralGUITextScale:SetValue(1.1)
 check(Library.Toggles.FlyT.TextLabel.FontFace.Family=='Gotham','Selected GUI font not applied')
 local fill=Color3.fromRGB(160,180,200);opt.AstralGUISliderFill:SetValueRGB(fill)
 local found=false;for _,v in ipairs(Library.ScreenGui:GetDescendants())do if v.Name=='SliderFill'and v.BackgroundColor3:ToHex()==fill:ToHex()then found=true end end
 check(found,'Slider customization missing')
 local functionName=Library.Toggles.FlyT.TextLabel.Text:gsub('<[^>]*>','')
 opt.AstralGUIIconTarget:SetValue(functionName);opt.AstralGUIIconOverride:SetValue('star')
 check(styler.Overrides[functionName]=='star','Per-function icon override was not stored')
 local configLibrary={Options={},Toggles={},Tabs={}}
 for id,control in pairs(opt)do if id:match('^AstralGUI')then configLibrary.Options[id]=control end end
 for id,control in pairs(tog)do if id:match('^AstralGUI')then configLibrary.Toggles[id]=control end end
 SaveManager:SetLibrary(configLibrary)
 local saved,ok=SaveManager:SaveJSON('GUI style');check(ok,'GUI style failed to save')
 opt.AstralGUITextScale:SetValue(.8);opt.AstralGUIFont:SetValue('Arial');tog.AstralGUISeparators:SetValue(false)
 opt.AstralGUIIconMap:SetValue('{}');opt.AstralGUISliderFill:SetValueRGB(Color3.new())
 Library:BeginStartup();check(SaveManager:LoadJSON(saved),'GUI style failed to load');advance(.02);Library:FinishStartup();a:Sync();styler:Sync()
 check(styler.Config.Font=='Gotham'and styler.Config.Scale==1.1 and styler.Config.Separators,'Saved font/size/dividers did not restore')
 check(styler.Overrides[functionName]=='star'and styler.Config.Fill:ToHex()==fill:ToHex(),'Saved icon map/slider color did not restore')
 opt.AstralGUIFont:SetValue('Original');opt.AstralGUITextScale:SetValue(1)
 tog.AstralGUIFunctionIcons:SetValue(false);tog.AstralGUISeparators:SetValue(false)
 opt.AstralGUIBackgroundURL:SetValue('https://images.example/pending.png');local pending=requests[#requests]
 local connections=table.clone(a.Connections);a:Dispose();pending.Done('rbxasset://late.png')
 check(not a.Background.Parent and not a.Layer.Parent,'Artwork survives unload')
 for _,c in ipairs(connections)do check(not c.Connected,'Artwork listener survives unload')end
 check(not surface.Image.Parent,'Floating artwork survives unload')
 styler:Dispose();pop:Destroy();UIStyle.ApplyBase(Library)
 print('PASS: landscape/moving previews, cleaned rounded external frame, detached wallpaper and native style controls')
end
