-- Opt-in window artwork. Eight clipped edge pieces leave the center empty;
-- normalized image coordinates work without privileged image-size APIs.
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
function Appearance.Layout(width, height, thickness, edge)
    width = math.max(1, width); height = math.max(1, height)
    local t = math.min(thickness, width / 3, height / 3)
    local x = {0, t, width-t, width}; local y = {0, t, height-t, height}
    local uv = {0, edge, 1-edge, 1}; local result = {}
    for row = 1, 3 do for col = 1, 3 do
        if row ~= 2 or col ~= 2 then
            result[#result+1] = {X=x[col],Y=y[row],Width=x[col+1]-x[col],Height=y[row+1]-y[row],
                U=uv[col],V=uv[row],UW=uv[col+1]-uv[col],VH=uv[row+1]-uv[row],
                Start=y[row]/height,Finish=y[row+1]/height}
        end
    end end
    return result
end
local function new(class, props)
    local object = Instance.new(class)
    for key, value in pairs(props) do object[key] = value end
    return object
end
function Appearance:Track(connection)
    self.Connections[#self.Connections+1] = connection
    return connection
end
function Appearance.Install(ctx)
    local self = setmetatable({Context=ctx,Library=ctx.Library,Window=ctx.Window,Connections={},Registered={},
        Assets={Background={Asset='',Token=0},Frame={Asset='',Token=0}},Cells={},Building=true},Appearance)
    self.Background = new('ImageLabel',{Name='AstralGUIBackground',BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,1),Image='',Active=false,Selectable=false,
        ZIndex=0,Visible=false,ScaleType=Enum.ScaleType.Crop,Parent=ctx.Window.MainFrame})
    self.BackgroundCorner = new('UICorner',{Parent=self.Background})
    self.Layer = new('Frame',{Name='AstralGUIFrame',BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,1),Active=false,Selectable=false,
        ZIndex=4,Visible=false,Parent=ctx.Window.MainFrame})
    for index=1,8 do
        local cell = {}
        cell.Clip = new('Frame',{Name='Edge'..index,BackgroundTransparency=1,BorderSizePixel=0,
            ClipsDescendants=true,Active=false,Selectable=false,Parent=self.Layer})
        cell.Image = new('ImageLabel',{Name='Artwork',BackgroundTransparency=1,BorderSizePixel=0,
            Image='',ScaleType=Enum.ScaleType.Stretch,Active=false,Selectable=false,Parent=cell.Clip})
        cell.Gradient = new('UIGradient',{Rotation=90,Enabled=false,Parent=cell.Image})
        self.Cells[index] = cell
        ctx.Library:AddToRegistry(cell.Gradient,{Color=function()return self:Gradient(cell)end})
        self.Registered[#self.Registered+1] = cell.Gradient
    end
    local mainCorner = ctx.Window.MainFrame:FindFirstChildOfClass('UICorner')
    local function updateCorner()
        if not self.Closed then self.BackgroundCorner.CornerRadius = mainCorner and mainCorner.CornerRadius or UDim.new(0,12) end
    end
    if mainCorner then self:Track(mainCorner:GetPropertyChangedSignal('CornerRadius'):Connect(updateCorner)) end
    updateCorner()
    self:Track(ctx.Window.MainFrame:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()self:Apply()end))
    self:BuildUI(ctx.Tab)
    self.Building=false
    self:Sync()
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
    if request==entry.Request then return end
    entry.Request=request;entry.Token+=1;entry.Pending=false
    local token=entry.Token
    if self.Context.Cancel then self.Context.Cancel(kind)end
    if not source then self:SetStatus(kind,why);return end
    if source==''then
        entry.Asset='';self.Previews[kind]:SetImage('image');self:SetStatus(kind,'Вставь ссылку под превью.');self:Apply();return
    end
    entry.Pending=true;self:SetStatus(kind,'Загрузка изображения…')
    local function valid()return not self.Closed and entry.Token==token end
    local function accept(asset)
        if not valid()then return end
        if type(asset)~='string'or asset==''then self:SetStatus(kind,'Не удалось загрузить изображение.');return end
        entry.Asset=asset;entry.Pending=false
        -- The resolver already returned a registered image URI. Some executors
        -- use URI shapes outside the icon atlas parser; do not reject those.
        local preview=self.PreviewImages[kind]
        local glyph=preview:FindFirstChild('AstralFunctionGlyph');if glyph then glyph:Destroy()end
        preview.Image=asset;preview.ImageRectOffset=Vector2.zero;preview.ImageRectSize=Vector2.zero
        self.Previews[kind].Image=asset;self.Previews[kind].RectOffset=Vector2.zero;self.Previews[kind].RectSize=Vector2.zero
        self:Apply()
        if self.PreviewImages[kind].IsLoaded then self:SetStatus(kind,'Изображение загружено.')end
    end
    if source:match('^rbxthumb://')or source:match('^rbxasset://')then accept(source)
    else
        local ok, message=pcall(self.Context.Resolve,source,kind,accept)
        if not ok and valid()then self:SetStatus(kind,'Ошибка загрузки: '..tostring(message))end
    end
    if self.Context.Delay then self.Context.Delay(15,function()
        if valid()and (entry.Pending or entry.Asset==''or not self.PreviewImages[kind].IsLoaded)then
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
    self.Layer.Visible=c.FrameEnabled and self.Assets.Frame.Asset~=''
    local size=self.Layer.AbsoluteSize;local dpi=math.max(.1,self.Library.DPIScale or 1)
    local layout=Appearance.Layout(size.X/dpi,size.Y/dpi,c.FrameWidth,c.FrameEdge)
    for index,cell in ipairs(self.Cells)do
        local g=layout[index];cell.Geometry=g
        cell.Clip.Position=UDim2.fromOffset(g.X,g.Y);cell.Clip.Size=UDim2.fromOffset(g.Width,g.Height)
        cell.Image.Position=UDim2.fromScale(-g.U/g.UW,-g.V/g.VH)
        cell.Image.Size=UDim2.fromScale(1/g.UW,1/g.VH)
        cell.Image.Image=self.Assets.Frame.Asset;cell.Image.ImageTransparency=c.FrameTransparency
        cell.Image.ImageColor3=c.MatchTheme and white or c.FrameColor
        cell.Gradient.Enabled=c.MatchTheme;cell.Gradient.Color=self:Gradient(cell)
    end
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
        BackgroundMode=value('AstralGUIBackgroundMode','Crop')}
    self:Apply()
    self:SetSource('Background',value('AstralGUIBackgroundURL',''))
    self:SetSource('Frame',value('AstralGUIFrameURL',''))
end
function Appearance:BuildUI(tab)
    local background=tab:AddLeftGroupbox('Фон GUI','image')
    local frame=tab:AddRightGroupbox('Рамка GUI','scan')
    self.Groups={Background=background,Frame=frame};self.Previews={};self.PreviewImages={};self.Status={}
    local function changed()if not self.Building then self:Sync()end end
    for _,kind in ipairs({'Background','Frame'})do
        local box=self.Groups[kind]
        local preview=box:AddImage('AstralGUI'..kind..'Preview',{Image='image',Height=150,ScaleType=Enum.ScaleType.Fit,BackgroundTransparency=1})
        self.Previews[kind]=preview
        local image=preview.Holder:FindFirstChildWhichIsA('ImageLabel',true);self.PreviewImages[kind]=image
        self:Track(image:GetPropertyChangedSignal('IsLoaded'):Connect(function()
            if not self.Closed and not self.Assets[kind].Pending and image.IsLoaded and self.Assets[kind].Asset~=''and image.Image==self.Assets[kind].Asset then self:SetStatus(kind,'Изображение загружено.')end
        end))
        box:AddInput('AstralGUI'..kind..'URL',{Text='Ссылка на картинку',Default='',Placeholder='PNG / JPG / WebP / Roblox ID',Finished=true,ClearTextOnFocus=false,Callback=changed})
        box:AddToggle('AstralGUI'..kind..'Enabled',{Text=kind=='Background'and'Показать фон' or'Показать рамку',Default=true,Callback=changed})
        box:AddLabel('Цвет'):AddColorPicker('AstralGUI'..kind..'Color',{Default=white,Title=kind=='Background'and'Цвет фона' or'Цвет рамки',Callback=changed})
        box:AddSlider('AstralGUI'..kind..'Transparency',{Text='Прозрачность',Default=kind=='Background'and .65 or 0,Min=0,Max=1,Rounding=2,Compact=true,Callback=changed})
        if kind=='Background'then
            box:AddDropdown('AstralGUIBackgroundMode',{Text='Размещение фото',Values={'Crop','Fit','Stretch'},Default='Crop',AllowNull=false,Callback=changed})
        else
            box:AddToggle('AstralGUIFrameMatchTheme',{Text='Точно под цвет GUI',Default=false,Callback=changed})
            box:AddSlider('AstralGUIFrameWidth',{Text='Ширина рамки',Default=14,Min=2,Max=80,Rounding=0,Suffix=' px',Compact=true,Callback=changed})
            box:AddSlider('AstralGUIFrameEdge',{Text='Область краёв фото',Default=22,Min=5,Max=45,Rounding=0,Suffix=' %',Compact=true,Callback=changed})
            box:AddLabel('Рамка растягивается по контуру. Середина остаётся пустой. Для точного цвета подходит белая PNG-рамка с прозрачными полями.',true)
        end
        box:AddButton({Text='Убрать картинку',Func=function()self.Library.Options['AstralGUI'..kind..'URL']:SetValue('')end})
        self.Status[kind]=box:AddLabel('Вставь ссылку под превью.',true)
    end
    self.PreviewGradient=new('UIGradient',{Rotation=90,Enabled=false,Parent=self.PreviewImages.Frame})
    self.Library:AddToRegistry(self.PreviewGradient,{Color=function()return self:Gradient()end})
    self.Registered[#self.Registered+1]=self.PreviewGradient
end
function Appearance:Dispose()
    if self.Closed then return end
    self.Closed=true
    for kind,entry in pairs(self.Assets)do entry.Token+=1;if self.Context.Cancel then self.Context.Cancel(kind)end end
    for _,c in ipairs(self.Connections)do c:Disconnect()end;table.clear(self.Connections)
    for _,node in ipairs(self.Registered)do self.Library:RemoveFromRegistry(node)end
    self.Background:Destroy();self.Layer:Destroy();self.PreviewGradient:Destroy()
end
return Appearance
