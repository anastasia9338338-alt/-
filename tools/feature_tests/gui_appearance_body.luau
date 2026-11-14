if GUIAppearance then
    ValidateGUIAssetLifetime()
    for _,size in ipairs({{320,260},{660,624},{1280,900},{12,10}})do
        for _,thickness in ipairs({2,14,80})do for _,edge in ipairs({.05,.22,.45})do
            local w,h=size[1],size[2];local cells=GUIAppearance.Layout(w,h,thickness,edge);local area=0
            check(#cells==8,'Frame added a center image')
            for _,g in ipairs(cells)do
                check(g.Width>0 and g.Height>0 and g.X>=0 and g.Y>=0 and g.X+g.Width<=w+.001 and g.Y+g.Height<=h+.001,'Border leaves resized window')
                check(g.U>=0 and g.V>=0 and g.U+g.UW<=1.0001 and g.V+g.VH<=1.0001,'Border reads invalid source image range')
                check(not(w/2>g.X and w/2<g.X+g.Width and h/2>g.Y and h/2<g.Y+g.Height),'A frame edge covers the center')
                area+=g.Width*g.Height
            end
            local t=math.min(thickness,w/3,h/3)
            check(math.abs(area-(w*h-(w-2*t)*(h-2*t)))<.001,'Frame pieces have gaps or overlaps')
        end end
    end
    check(GUIAppearance.Normalize('  rbxassetid://4321  ')=='rbxassetid://4321','Asset URI normalization failed')
    check(GUIAppearance.Normalize('data:image/png;base64,aaa')==nil,'Non-image link scheme accepted')
    local requests={}
    local function resolve(source,key,kind,done,empty,number,keep)
        requests[#requests+1]={Source=source,Key=key,Kind=kind,Done=done,Keep=keep}
    end
    local beforeTabs=#Library.TabButtons
    local guiTab=window:AddTab('GUI','image')
    Library:BeginStartup()
    local appearance,assets=BuildGUIAppearance(window,guiTab,resolve)
    Library:FinishStartup();appearance:Sync()
    local opt,tog=Library.Options,Library.Toggles
    check(#Library.TabButtons==beforeTabs+1 and Library.Tabs.GUI==guiTab,'GUI tab missing')
    local left,right=appearance.Groups.Background,appearance.Groups.Frame
    check(left.BoxHolder.Parent~=right.BoxHolder.Parent and guiTab.Sides[1].Size.X.Scale==.5 and guiTab.Sides[2].Size.X.Scale==.5,'Artwork selectors do not split the tab equally')
    for _,kind in ipairs({'Background','Frame'})do
        check(appearance.Previews[kind].Height==150 and appearance.Previews[kind].Holder.Parent==appearance.Groups[kind].Container,'Artwork preview differs from the native avatar image control')
        check(opt['AstralGUI'..kind..'URL'].Finished and not opt['AstralGUI'..kind..'URL'].ClearTextOnFocus,'URL input fires every keystroke or erases the pasted URL')
    end
    check(not appearance.Background.Visible and not appearance.Layer.Visible and #requests==0,'Empty artwork changes the default gray GUI or starts a request')
    check(window.MainFrame.BackgroundTransparency==.55 and Library.Scheme.RowTransparency==.92,'Artwork controls changed the base glass theme')
    local function raw(kind,value)opt['AstralGUI'..kind..'URL']:SetValue(value)end
    raw('Background','123456')
    check(#requests==1 and requests[1].Source=='rbxassetid://123456'and requests[1].Keep==true,'Background does not use native resolver with retained image file')
    raw('Background','https://images.example/photo.png')
    check(#requests==2,'Direct image URL not requested')
    requests[1].Done('rbxassetid://old')
    check(appearance.Background.Image=='','An obsolete image response won the race')
    requests[2].Done('rbxasset://photo.png')
    check(appearance.Background.Visible and appearance.Background.Image=='rbxasset://photo.png','Selected background is not shown')
    check(appearance.PreviewImages.Background.Image=='rbxasset://photo.png','Photo preview did not follow the URL')
    check(appearance.Background.ZIndex<window.MainFrame:FindFirstChild('HeaderSurface').ZIndex and not appearance.Background.Active,'Background covers or intercepts GUI controls')
    local chosen=Color3.fromRGB(130,170,200)
    opt.AstralGUIBackgroundColor:SetValueRGB(chosen);opt.AstralGUIBackgroundTransparency:SetValue(.32)
    opt.AstralGUIBackgroundMode:SetValue('Fit')
    check(appearance.Background.ImageColor3:ToHex()==chosen:ToHex()and appearance.Background.ImageTransparency==.32 and appearance.Background.ScaleType==Enum.ScaleType.Fit,'Background color, opacity or placement ignored')
    tog.AstralGUIBackgroundEnabled:SetValue(false);check(not appearance.Background.Visible,'Background toggle ignored')
    tog.AstralGUIBackgroundEnabled:SetValue(true)
    raw('Frame','https://www.roblox.com/catalog/789/Frame')
    local frameRequest=requests[#requests];check(frameRequest.Source=='rbxassetid://789','Roblox catalog link not normalized')
    frameRequest.Done('rbxasset://frame.png')
    check(appearance.Layer.Visible and #appearance.Cells==8 and appearance.PreviewImages.Frame.Image=='rbxasset://frame.png','Frame or its picture preview missing')
    for _,cell in ipairs(appearance.Cells)do
        check(cell.Image.Image=='rbxasset://frame.png'and cell.Clip.ClipsDescendants and not cell.Image.Active,'Frame piece loses texture, clipping or click-through')
        local g=cell.Geometry;local w=appearance.Layer.AbsoluteSize.X;local h=appearance.Layer.AbsoluteSize.Y
        check(not(w/2>g.X and w/2<g.X+g.Width and h/2>g.Y and h/2<g.Y+g.Height),'Frame paints over the center of the GUI')
    end
    opt.AstralGUIFrameColor:SetValueRGB(chosen);opt.AstralGUIFrameTransparency:SetValue(.4)
    check(appearance.Cells[1].Image.ImageColor3:ToHex()==chosen:ToHex()and appearance.Cells[1].Image.ImageTransparency==.4,'Frame tint or transparency ignored')
    tog.AstralGUIFrameMatchTheme:SetValue(true)
    Library.Scheme.BodyTopColor=Color3.fromRGB(42,45,49);Library.Scheme.BodyBottomColor=Color3.fromRGB(19,21,24)
    Library:UpdateColorsUsingRegistry()
    check(appearance.Cells[1].Gradient.Enabled and appearance.Cells[1].Image.ImageColor3:ToHex()=='ffffff','Exact theme matching does not replace manual tint')
    check(appearance.Cells[1].Gradient.Color.Keypoints[1].Value:ToHex()==Library.Scheme.BodyTopColor:ToHex(),'Frame top does not match the current GUI gradient')
    check(appearance.Cells[8].Gradient.Color.Keypoints[#appearance.Cells[8].Gradient.Color.Keypoints].Value:ToHex()==Library.Scheme.BodyBottomColor:ToHex(),'Frame bottom does not match the current GUI gradient')
    local last=appearance.Cells[8].Geometry
    window.MainFrame.Size=UDim2.fromOffset(760,610);window.MainFrame:GetPropertyChangedSignal('AbsoluteSize'):Fire()
    local grown=appearance.Cells[8].Geometry
    check(grown.X>last.X and grown.Y>last.Y and math.abs(grown.Width-last.Width)<.001,'Resizing stretches frame corners or fails to follow the window')
    opt.AstralGUIFrameWidth:SetValue(30);check(appearance.Cells[1].Geometry.Width==30,'Frame width not configurable')
    opt.AstralGUIFrameEdge:SetValue(35);check(appearance.Cells[1].Geometry.UW==.35,'Source edge region not configurable')
    local configLibrary={Options={},Toggles={},Tabs={}}
    for id,value in pairs(Library.Options)do if id:match('^AstralGUI')then configLibrary.Options[id]=value end end
    for id,value in pairs(Library.Toggles)do if id:match('^AstralGUI')then configLibrary.Toggles[id]=value end end
    SaveManager:SetLibrary(configLibrary)
    local config,success=SaveManager:SaveJSON('Artwork test');check(success,'GUI appearance config failed to save')
    raw('Frame','');opt.AstralGUIFrameTransparency:SetValue(.9);tog.AstralGUIFrameMatchTheme:SetValue(false)
    Library:BeginStartup()
    check(SaveManager:LoadJSON(config),'GUI appearance config failed to load');advance(.02)
    Library:FinishStartup();appearance:Sync()
    local restored=requests[#requests];restored.Done('rbxasset://restored/frame.png')
    check(opt.AstralGUIFrameURL.Value=='https://www.roblox.com/catalog/789/Frame'and appearance.Layer.Visible,'Saved image URL or enable state not restored')
    check(appearance.Config.FrameTransparency==.4 and appearance.Config.FrameWidth==30 and appearance.Config.MatchTheme,'Saved frame appearance not restored after startup callback suppression')
    check(appearance.Config.BackgroundColor:ToHex()==chosen:ToHex()and appearance.Config.BackgroundTransparency==.32,'Saved background settings lost')
    local connections=table.clone(appearance.Connections)
    raw('Frame','https://images.example/pending.png');local pending=requests[#requests]
    raw('Frame','');pending.Done('rbxasset://late.png')
    check(not appearance.Layer.Visible and appearance.Assets.Frame.Asset=='','Clearing URL leaves frame or accepts a stale image')
    raw('Background','javascript:alert(1)')
    check(appearance.Status.Background.TextLabel.Text:find('Нужна',1,true)~=nil,'Invalid image input has no clear status')
    raw('Background','https://images.example/missing.png');advance(16)
    check(appearance.Status.Background.TextLabel.Text:find('Не загрузилось',1,true)~=nil,'A failed request remains loading forever')
    local response=requests[#requests]
    appearance:Dispose();response.Done('rbxasset://after-unload.png');appearance:Sync()
    check(not appearance.Background.Parent and not appearance.Layer.Parent,'Disposal leaves custom artwork')
    for _,c in ipairs(connections)do check(not c.Connected,'Artwork event observer survives disposal')end
    for _,g in ipairs(appearance.Registered)do check(Library.Registry[g]==nil,'Artwork gradient stays in theme registry after disposal')end
    -- The actual SaveManager keeps these ordinary Inputs/Sliders/ColorPickers.
    UIStyle.ApplyBase(Library)
    print('PASS: native GUI artwork previews, exact theme matching, resize, async cancellation, clear and unload')
end
