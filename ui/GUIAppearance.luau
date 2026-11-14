-- Optional artwork with client-side checker removal and a rounded external frame.
-- A separate surface keeps decoration out of the native content layout.
local Appearance = {}; Appearance.__index = Appearance
local white = Color3.new(1, 1, 1)
local function trim(value) return tostring(value or ''):match('^%s*(.-)%s*$') end
local function clamp(value, fallback, lo, hi)
    value = tonumber(value)
    if not value or value ~= value or math.abs(value) == math.huge then return fallback end
    return math.clamp(value, lo, hi)
end
function Appearance.Normalize(value)
    local source = trim(value)
    if source == '' then return '' end
    local lower = source:lower()
    local id = source:match('^%d+$') or lower:match('^rbxassetid://(%d+)$')
    local host = lower:match('^https?://([^/%?#]+)')
    if host == 'roblox.com' or host and host:match('%.roblox%.com$') then
        id = lower:match('[?&]id=(%d+)') or lower:match('/asset/(%d+)')
            or lower:match('/library/(%d+)') or lower:match('/catalog/(%d+)')
    end
    if id then return 'rbxassetid://' .. id end
    if lower:match('^rbxthumb://') or lower:match('^rbxasset://') then return source end
    if host and not source:find('%s') then return source end
    return nil, 'Нужна прямая ссылка на картинку или Roblox ID.'
end
local function new(class, props)
    local object = Instance.new(class)
    for key, value in pairs(props) do object[key] = value end
    return object
end
function Appearance:BindTexture(node,value)
    if type(value)=='string'then node.Image=value else node.ImageContent=value end
end
function Appearance:Track(connection)
    self.Connections[#self.Connections+1] = connection
    return connection
end
function Appearance.Install(ctx)
    local self = setmetatable({Context=ctx,Library=ctx.Library,Window=ctx.Window,Connections={},Registered={},Surfaces={},FrameGeneration=0,
        Assets={Background={Asset='',Token=0},Frame={Asset='',Token=0}},Building=true},Appearance)
    self.Background = new('ImageLabel',{Name='AstralGUIBackground',BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,1),Image='',Active=false,Selectable=false,
        ZIndex=0,Visible=false,ScaleType=Enum.ScaleType.Crop,Parent=ctx.Window.MainFrame})
    self.BackgroundCorner = new('UICorner',{Parent=self.Background})
    self.Layer = new('Frame',{Name='AstralGUIFrame',BackgroundTransparency=1,BorderSizePixel=0,
        Active=false,Selectable=false,ZIndex=ctx.Window.MainFrame.ZIndex-1,Visible=false,Parent=ctx.Window.MainFrame.Parent})
    self.FramePicture=new('ImageLabel',{Name='FrameArtwork',BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.fromScale(1,1),Active=false,Selectable=false,Image='',Parent=self.Layer})
    self.FrameGradient=new('UIGradient',{Rotation=90,Enabled=false,Parent=self.FramePicture})
    ctx.Library:AddToRegistry(self.FrameGradient,{Color=function()return self:Gradient()end})
    self.Registered[#self.Registered+1]=self.FrameGradient
    self.Fallback=new('Frame',{Name='FrameFallback',BackgroundTransparency=1,BorderSizePixel=0,Active=false,Visible=false,Parent=self.Layer})
    self.FallbackCorner=new('UICorner',{Parent=self.Fallback})
    self.FallbackStroke=new('UIStroke',{Thickness=1,Color=white,Parent=self.Fallback})
    local mainCorner = ctx.Window.MainFrame:FindFirstChildOfClass('UICorner')
    local function updateCorner()
        if not self.Closed then
            self.BackgroundCorner.CornerRadius = mainCorner and mainCorner.CornerRadius or UDim.new(0,12)
            self:Apply()
        end
    end
    if mainCorner then self:Track(mainCorner:GetPropertyChangedSignal('CornerRadius'):Connect(updateCorner)) end
    updateCorner()
    self.MainCorner=mainCorner
    self:Track(ctx.Window.MainFrame:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()self:Apply()end))
    self:Track(ctx.Window.MainFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()self:Apply()end))
    self:Track(ctx.Window.MainFrame:GetPropertyChangedSignal('Visible'):Connect(function()self:Apply();self:Animate()end))
    self:Track(ctx.Tab.Container:GetPropertyChangedSignal('Visible'):Connect(function()self:Animate()end))
    self.Tab=ctx.Tab
    self:BuildUI(ctx.Tab)
    self.Building=false
    self:Sync()
    self.Library.AppearanceController=self
    for frame in pairs(self.Library.ArtworkSurfaces or{})do self:AddSurface(frame)end
    return self
end
function Appearance:Gradient(cell)
    local scheme = self.Library.Scheme
    local top, bottom = scheme.BodyTopColor, scheme.BodyBottomColor
    local a, b = 0, 1; local start, finish = 0, 1
    if cell and cell.Geometry then
        local g=cell.Geometry;a,b=g.V,g.V+g.VH;start,finish=g.Start,g.Finish
    end
    local first, last = top:Lerp(bottom,start), top:Lerp(bottom,finish)
    local points = {ColorSequenceKeypoint.new(0,first)}
    if a>0 then points[#points+1]=ColorSequenceKeypoint.new(a,first)end
    if b<1 then points[#points+1]=ColorSequenceKeypoint.new(b,last)end
    points[#points+1]=ColorSequenceKeypoint.new(1,last)
    return ColorSequence.new(points)
end
function Appearance:SetStatus(kind, message)
    local label=self.Status and self.Status[kind]
    if label and not self.Closed then label:SetText(message)end
end
function Appearance:SetSource(kind, value)
    local entry = self.Assets[kind]
    local source, why = Appearance.Normalize(value)
    local request = trim(value)
    local key=request..(kind=='Frame'and tostring(self.Config.RemoveGrid)or'')
    if key==entry.RequestKey then return end
    entry.RequestKey=key
    entry.Request=request;entry.Token+=1;entry.Pending=false
    if kind=='Frame'then self.FrameGeneration+=1 end
    local token=entry.Token
    if self.Context.Cancel then self.Context.Cancel(kind)end
    if not source then self:SetStatus(kind,why);return end
    if source==''then
        entry.Asset='';entry.Data=nil;if kind=='Frame'then
            self.FrameKey=nil;self.FrameUnavailable=nil
            if self.FrameTexture then self.FrameTexture:Destroy();self.FrameTexture=nil end
            if self.PreviewTexture then self.PreviewTexture:Destroy();self.PreviewTexture=nil end
        end;self.Previews[kind]:SetImage('image');self:SetStatus(kind,'Вставь ссылку под превью.');self:Apply();return
    end
    entry.Pending=true;self:SetStatus(kind,'Загрузка изображения…')
    local function valid()return not self.Closed and entry.Token==token end
    local function accept(asset)
        if not valid()then return end
        if type(asset)~='string'or asset==''then self:SetStatus(kind,'Не удалось загрузить изображение.');return end
        local function display(data,why)
            if not valid()then return end
            entry.Asset=asset;entry.Pending=false
            if kind=='Frame'then
                entry.Data=data;self.FrameKey=nil
                if self.PreviewTexture then self.PreviewTexture:Destroy();self.PreviewTexture=nil end
                if data and self.Context.MakeTexture then
                    local ok,image,content=pcall(self.Context.MakeTexture,data.Pixels,data.Width,data.Height)
                    if not valid()then if ok and image then image:Destroy()end;return end
                    if ok then self.PreviewTexture=image;self:BindTexture(self.PreviewImages.Frame,content) end
                end
                if not data then self:SetStatus(kind,why or'Обработка рамки недоступна: показан округлый контур.')
                else self:SetStatus(kind,data.Removed>0 and'Сетка удалена. Рамка подготовлена.'or'Рамка подготовлена.')end
            else
                local preview=self.PreviewImages[kind]
                local glyph=preview:FindFirstChild('AstralFunctionGlyph');if glyph then glyph:Destroy()end
                preview.Image=asset;preview.ImageRectOffset=Vector2.zero;preview.ImageRectSize=Vector2.zero
                self.Previews[kind].Image=asset
                self:SetStatus(kind,'Изображение загружено.')
            end
            self:Apply()
        end
        if kind=='Frame'and self.Context.PrepareFrame then self.Context.PrepareFrame(asset,self.Config.RemoveGrid,valid,display)
        elseif kind=='Frame'then display(nil,'Обработка картинки недоступна.')
        else display()end
    end
    if source:match('^rbxthumb://')or source:match('^rbxasset://')then accept(source)
    else
        local ok, message=pcall(self.Context.Resolve,source,kind,accept)
        if not ok and valid()then self:SetStatus(kind,'Ошибка загрузки: '..tostring(message))end
    end
    if self.Context.Delay then self.Context.Delay(15,function()
        if valid()and (entry.Pending or entry.Asset==''or kind=='Background'and not self.PreviewImages[kind].IsLoaded)then
            self:SetStatus(kind,'Не загрузилось. Проверь прямую ссылку на PNG/JPG.')
        end
    end)end
end
function Appearance:Apply()
    if self.Closed or not self.Config then return end
    local c=self.Config
    self.Background.Image=self.Assets.Background.Asset
    self.Background.ImageColor3=c.BackgroundColor;self.Background.ImageTransparency=c.BackgroundTransparency
    self.Background.ScaleType=c.BackgroundMode=='Fit'and Enum.ScaleType.Fit or c.BackgroundMode=='Stretch'and Enum.ScaleType.Stretch or Enum.ScaleType.Crop
    self.Background.Visible=c.BackgroundEnabled and self.Assets.Background.Asset~=''
    self.Layer.Visible=c.FrameEnabled and self.Assets.Frame.Asset~=''and self.Window.MainFrame.Visible
    local owner=self.Window.MainFrame;local size=owner.AbsoluteSize;local dpi=math.max(.1,self.Library.DPIScale or 1)
    local t=c.FrameWidth*dpi;local parentPos=self.Layer.Parent.AbsolutePosition or Vector2.zero
    self.Layer.Position=UDim2.fromOffset(owner.AbsolutePosition.X-parentPos.X-t,owner.AbsolutePosition.Y-parentPos.Y-t)
    self.Layer.Size=UDim2.fromOffset(size.X+t*2,size.Y+t*2)
    local radius=self.MainCorner and self.MainCorner.CornerRadius.Offset*dpi or 22*dpi
    self.Fallback.Position=UDim2.fromOffset(t*.5,t*.5);self.Fallback.Size=UDim2.new(1,-t,1,-t)
    self.FallbackCorner.CornerRadius=UDim.new(0,radius+t*.5)
    self.FallbackStroke.Thickness=t;self.FallbackStroke.Color=c.MatchTheme and self.Library.Scheme.BodyTopColor or c.FrameColor
    self.FallbackStroke.Transparency=c.FrameTransparency
    self.Fallback.Visible=not self.Assets.Frame.Data or self.FrameUnavailable==true
    self.FramePicture.Visible=self.Assets.Frame.Data~=nil and not self.FrameUnavailable
    self.FramePicture.ImageColor3=c.MatchTheme and white or c.FrameColor;self.FramePicture.ImageTransparency=c.FrameTransparency
    self.FrameGradient.Enabled=c.MatchTheme;self.FrameGradient.Color=self:Gradient()
    local key=table.concat({size.X,size.Y,t,radius,c.FrameEdge,tostring(self.Assets.Frame.Data)},':')
    if self.Assets.Frame.Data and key~=self.FrameKey then
        self.FrameKey=key;self.FrameGeneration+=1;local generation=self.FrameGeneration
        local function raster()
            if self.Closed or generation~=self.FrameGeneration then return end
            local ok,image,content=pcall(self.Context.RasterFrame,self.Assets.Frame.Data,size.X,size.Y,t,radius,c.FrameEdge)
            if self.Closed or generation~=self.FrameGeneration then if ok and image then image:Destroy()end;return end
            if ok and image then
                local previous=self.FrameTexture;self.FrameTexture=image;self:BindTexture(self.FramePicture,content)
                self.FrameUnavailable=false;self.Fallback.Visible=false;self.FramePicture.Visible=true
                if previous then previous:Destroy()end
            else self.FrameUnavailable=true;self.Fallback.Visible=true;self.FramePicture.Visible=false;self:SetStatus('Frame','Рендер рамки недоступен: '..tostring(image))end
        end
        if self.Context.Delay then self.Context.Delay(.12,raster)else raster()end
    end
    self:ApplySurfaces()
    if self.Previews then
        self.Previews.Background:SetColor(c.BackgroundColor);self.Previews.Background:SetTransparency(c.BackgroundTransparency)
        self.Previews.Frame:SetColor(c.MatchTheme and white or c.FrameColor);self.Previews.Frame:SetTransparency(c.FrameTransparency)
        self.PreviewGradient.Enabled=c.MatchTheme;self.PreviewGradient.Color=self:Gradient()
    end
end
function Appearance:Sync()
    if self.Closed then return end
    local options,toggles=self.Library.Options,self.Library.Toggles
    local function value(id,default)local o=options[id]or toggles[id];if o and o.Value~=nil then return o.Value end;return default end
    self.Config={BackgroundEnabled=value('AstralGUIBackgroundEnabled',true),FrameEnabled=value('AstralGUIFrameEnabled',true),
        BackgroundColor=value('AstralGUIBackgroundColor',white),FrameColor=value('AstralGUIFrameColor',white),
        BackgroundTransparency=clamp(value('AstralGUIBackgroundTransparency',.65),.65,0,1),
        FrameTransparency=clamp(value('AstralGUIFrameTransparency',0),0,0,1),FrameWidth=clamp(value('AstralGUIFrameWidth',14),14,2,80),
        FrameEdge=clamp(value('AstralGUIFrameEdge',22),22,5,45)/100,MatchTheme=value('AstralGUIFrameMatchTheme',false),
        BackgroundMode=value('AstralGUIBackgroundMode','Crop'),Floating=value('AstralGUIFloatingBackground',false),
        Motion=value('AstralGUIPreviewMotion',true),RemoveGrid=value('AstralGUIFrameRemoveGrid',true)}
    self:Apply()
    self:SetSource('Background',value('AstralGUIBackgroundURL',''))
    self:SetSource('Frame',value('AstralGUIFrameURL',''))
    self:Animate()
end
function Appearance:BuildUI(tab)
    local background=tab:AddLeftGroupbox('Фон GUI','image')
    local frame=tab:AddRightGroupbox('Рамка GUI','scan')
    self.Groups={Background=background,Frame=frame};self.Previews={};self.PreviewImages={};self.Status={}
    local function changed()if not self.Building then self:Sync()end end
    for _,kind in ipairs({'Background','Frame'})do
        local box=self.Groups[kind]
        local preview=box:AddImage('AstralGUI'..kind..'Preview',{Image='image',Height=150,ScaleType=Enum.ScaleType.Stretch,BackgroundTransparency=1})
        self.Previews[kind]=preview
        local image=preview.Holder:FindFirstChildWhichIsA('ImageLabel',true);self.PreviewImages[kind]=image
        image.Parent.ClipsDescendants=true
        if kind=='Background'then image.AnchorPoint=Vector2.new(.5,.5);image.Position=UDim2.fromScale(.5,.5);image.Size=UDim2.fromScale(1.12,1.12)end
        self:Track(image:GetPropertyChangedSignal('IsLoaded'):Connect(function()
            if not self.Closed and not self.Assets[kind].Pending and image.IsLoaded and self.Assets[kind].Asset~=''and image.Image==self.Assets[kind].Asset then self:SetStatus(kind,'Изображение загружено.')end
        end))
        box:AddInput('AstralGUI'..kind..'URL',{Text='Ссылка на картинку',Default='',Placeholder='PNG / JPG / WebP / Roblox ID',Finished=true,ClearTextOnFocus=false,Callback=changed})
        box:AddToggle('AstralGUI'..kind..'Enabled',{Text=kind=='Background'and'Показать фон' or'Показать рамку',Default=true,Callback=changed})
        box:AddLabel('Цвет'):AddColorPicker('AstralGUI'..kind..'Color',{Default=white,Title=kind=='Background'and'Цвет фона' or'Цвет рамки',Callback=changed})
        box:AddSlider('AstralGUI'..kind..'Transparency',{Text='Прозрачность',Default=kind=='Background'and .65 or 0,Min=0,Max=1,Rounding=2,Compact=true,Callback=changed})
        if kind=='Background'then
            box:AddToggle('AstralGUIFloatingBackground',{Text='Фон вынесенных окон',Default=false,Callback=changed})
            box:AddToggle('AstralGUIPreviewMotion',{Text='Покачивание превью',Default=true,Callback=changed})
            box:AddDropdown('AstralGUIBackgroundMode',{Text='Размещение фото',Values={'Crop','Fit','Stretch'},Default='Crop',AllowNull=false,Callback=changed})
        else
            box:AddToggle('AstralGUIFrameRemoveGrid',{Text='Автоматически убирать сетку',Default=true,Callback=changed})
            box:AddToggle('AstralGUIFrameMatchTheme',{Text='Точно под цвет GUI',Default=false,Callback=changed})
            box:AddSlider('AstralGUIFrameWidth',{Text='Ширина рамки',Default=14,Min=2,Max=80,Rounding=0,Suffix=' px',Compact=true,Callback=changed})
            box:AddSlider('AstralGUIFrameEdge',{Text='Область краёв фото',Default=22,Min=5,Max=45,Rounding=0,Suffix=' %',Compact=true,Callback=changed})
            box:AddLabel('Рамка выводится из PNG-файла без доступа к EditableImage. Середина остаётся прозрачной; контур повторяет закругления GUI.',true)
        end
        box:AddButton({Text='Убрать картинку',Func=function()self.Library.Options['AstralGUI'..kind..'URL']:SetValue('')end})
        self.Status[kind]=box:AddLabel('Вставь ссылку под превью.',true)
    end
    self.PreviewGradient=new('UIGradient',{Rotation=90,Enabled=false,Parent=self.PreviewImages.Frame})
    self.Library:AddToRegistry(self.PreviewGradient,{Color=function()return self:Gradient()end})
    self.Registered[#self.Registered+1]=self.PreviewGradient
end
function Appearance:Animate()
    local enabled=not self.Closed and self.Config and self.Config.Motion and self.Window.MainFrame.Visible and self.Tab.Container.Visible
    if not enabled then
        if self.MotionConnection then self.MotionConnection:Disconnect();self.MotionConnection=nil end
        for _,image in pairs(self.PreviewImages or{})do image.Rotation=0 end
        return
    end
    if self.MotionConnection or not self.Context.RunService then return end
    self.MotionConnection=self.Context.RunService.Heartbeat:Connect(function(dt)
        self.Phase=(self.Phase or 0)+math.min(dt,.1)
        for _,image in pairs(self.PreviewImages)do image.Rotation=math.sin(self.Phase*.8)*2 end
    end)
end
function Appearance:AddSurface(frame)
    if self.Closed or not frame or self.Surfaces[frame]then return end
    local image=new('ImageLabel',{Name='AstralFloatingBackground',Image='',BackgroundTransparency=1,BorderSizePixel=0,Active=false,
        Visible=false,ZIndex=frame.ZIndex-1,ScaleType=Enum.ScaleType.Crop,Parent=frame.Parent})
    local corner=new('UICorner',{CornerRadius=UDim.new(0,12),Parent=image})
    local record={Frame=frame,Image=image,Corner=corner,Transparency=frame.BackgroundTransparency,Connections={}}
    self.Surfaces[frame]=record
    for _,key in ipairs({'AbsolutePosition','AbsoluteSize','Visible','Parent','ZIndex'})do
        record.Connections[#record.Connections+1]=frame:GetPropertyChangedSignal(key):Connect(function()self:ApplySurfaces()end)
    end
    record.Connections[#record.Connections+1]=frame.Destroying:Connect(function()self:RemoveSurface(frame)end)
    self:ApplySurfaces()
end
function Appearance:RemoveSurface(frame)
    local record=self.Surfaces[frame];if not record then return end;self.Surfaces[frame]=nil
    for _,c in ipairs(record.Connections)do c:Disconnect()end
    if frame.Parent and frame.BackgroundTransparency==1 and record.Applied then frame.BackgroundTransparency=record.Transparency end
    record.Image:Destroy()
end
function Appearance:ApplySurfaces()
    if not self.Config then return end
    for frame,record in pairs(self.Surfaces)do
        local c=self.Config;local visible=c.Floating and c.BackgroundEnabled and self.Assets.Background.Asset~=''and frame.Visible and frame.Parent~=nil
        record.Image.Visible=visible
        if visible then
            record.Image.Parent=frame.Parent
            local origin=frame.Parent.AbsolutePosition or Vector2.zero
            record.Image.Position=UDim2.fromOffset(frame.AbsolutePosition.X-origin.X,frame.AbsolutePosition.Y-origin.Y)
            record.Image.Size=UDim2.fromOffset(frame.AbsoluteSize.X,frame.AbsoluteSize.Y);record.Image.ZIndex=frame.ZIndex-1
            record.Image.Image=self.Assets.Background.Asset;record.Image.ImageColor3=c.BackgroundColor;record.Image.ImageTransparency=c.BackgroundTransparency
            local corner=frame:FindFirstChildOfClass('UICorner')
            if corner then
                local scale=frame:FindFirstChildOfClass('UIScale');local r=corner.CornerRadius
                record.Corner.CornerRadius=UDim.new(r.Scale,r.Offset*(scale and scale.Scale or 1))
            end
            frame.BackgroundTransparency=1;record.Applied=true
        elseif record.Applied then
            if frame.BackgroundTransparency==1 then frame.BackgroundTransparency=record.Transparency end;record.Applied=false
        end
    end
end
function Appearance:Dispose()
    if self.Closed then return end
    self.Closed=true;self.FrameGeneration+=1
    if self.MotionConnection then self.MotionConnection:Disconnect()end
    local frames={};for frame in pairs(self.Surfaces)do frames[#frames+1]=frame end;for _,frame in ipairs(frames)do self:RemoveSurface(frame)end
    if self.Library.AppearanceController==self then self.Library.AppearanceController=nil end
    if self.FrameTexture then self.FrameTexture:Destroy()end;if self.PreviewTexture then self.PreviewTexture:Destroy()end
    for kind,entry in pairs(self.Assets)do entry.Token+=1;if self.Context.Cancel then self.Context.Cancel(kind)end end
    for _,c in ipairs(self.Connections)do c:Disconnect()end;table.clear(self.Connections)
    for _,node in ipairs(self.Registered)do self.Library:RemoveFromRegistry(node)end
    self.Background:Destroy();self.Layer:Destroy();self.PreviewGradient:Destroy()
end
return Appearance
