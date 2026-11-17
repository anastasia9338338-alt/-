-- One wallpaper selection for the window, sidebar, HUD and floating panels.
-- Image layers are below text, follow their owner through property signals,
-- and never participate in a content layout or the gameplay network channel.
local requireModule = ...
local Catalog = requireModule("BackgroundCatalog")
local Appearance = {}
Appearance.__index = Appearance
local WHITE = Color3.new(1, 1, 1)
local function new(class, parent, props)
	local node = Instance.new(class)
	for key, value in pairs(props) do node[key] = value end
	node.Parent = parent
	return node
end
local function trim(value) return tostring(value or ""):match("^%s*(.-)%s*$") end
function Appearance.Normalize(value)
	local source = trim(value)
	if source == "" then return "" end
	local lower = source:lower()
	local id = source:match("^%d+$") or lower:match("^rbxassetid://(%d+)$")
	local host = lower:match("^https?://([^/%?#]+)")
	if host == "roblox.com" or host and host:match("%.roblox%.com$") then
		id = lower:match("[?&]id=(%d+)") or lower:match("/asset/(%d+)")
			or lower:match("/library/(%d+)") or lower:match("/catalog/(%d+)")
	end
	if id then return "rbxassetid://" .. id end
	if lower:match("^rbxthumb://") or lower:match("^rbxasset://") then return source end
	if host and not source:find("%s") then return source end
	return nil, "Нужна прямая ссылка на PNG/JPG или Roblox ID."
end
function Appearance.Install(ctx)
	local self = setmetatable({Context=ctx, Library=ctx.Library, Window=ctx.Window, Tab=ctx.Tab,
		Connections={}, Surfaces={}, Cache={}, Cards={}, Timers={}, Building=true, GalleryActive=0, GalleryNext=1,
		DefaultSource=tostring(ctx.DefaultSource or "108109283852139"), Generation=0}, Appearance)
	self:BuildUI()
	self.Building = false
	ctx.Library.AppearanceController = self
	self.PreviousColors = ctx.Library.UpdateColorsUsingRegistry
	self.ColorHook = function(library, ...)
		self.PreviousColors(library, ...)
		if not self.Closed then self:Apply() end
	end
	ctx.Library.UpdateColorsUsingRegistry = self.ColorHook
	for surface in pairs(ctx.Library.ArtworkSurfaces or {}) do self:AddSurface(surface) end
	self.Connections[#self.Connections+1] = ctx.Tab.Container:GetPropertyChangedSignal("Visible"):Connect(function() self:LoadGallery() end)
	self.Connections[#self.Connections+1] = ctx.Window.MainFrame:GetPropertyChangedSignal("Visible"):Connect(function() self:LoadGallery() end)
	self:Sync()
	return self
end
function Appearance:Status(message)
	if not self.Closed then self.StatusLabel:SetText(message) end
end
function Appearance:Fetch(source, key, callback)
	local cached = self.Cache[source]
	if cached then
		if cached.Asset then callback(cached.Asset) else cached.Callbacks[#cached.Callbacks+1]=callback end
		return
	end
	self.FetchSerial=(self.FetchSerial or 0)+1
	key=key..self.FetchSerial
	local entry = {Callbacks={callback}, Pending=true, Key=key}
	self.Cache[source] = entry
	local function finish(asset, message)
		if self.Closed or not entry.Pending then return end
		entry.Pending=false; entry.Asset=asset
		if not asset then self.Cache[source]=nil end
		local callbacks=entry.Callbacks; entry.Callbacks={}
		for _,done in ipairs(callbacks) do done(asset, message) end
	end
	if source:match("^rbxasset") or source:match("^rbxthumb://") then finish(source); return end
	local ok, message = pcall(self.Context.Resolve, source, key, function(asset)
		if type(asset)=="string" and asset~="" then finish(asset) else finish(nil, "Не удалось загрузить изображение.") end
	end)
	if not ok then finish(nil, tostring(message)); return end
	if entry.Pending and self.Context.Delay then
		self.Timers[#self.Timers+1]=self.Context.Delay(15, function()
			if entry.Pending then finish(nil, "Не загрузилось. Нужна прямая ссылка на PNG/JPG.") end
		end)
	end
end
function Appearance:SetSource(value)
	local source, message = Appearance.Normalize(value)
	if not source then self:Status(message); return end
	if source==self.Source then return end
	self.Source=source; self.Generation+=1
	local generation=self.Generation
	if source=="" then self.Asset=nil; self:Apply(); return end
	self:Status("Загрузка фона…")
	self:Fetch(source, "Background", function(asset, why)
		if self.Closed or self.Generation~=generation then return end
		if not asset then self.Source=nil; self:Status(why or "Не удалось загрузить фон."); return end
		self.Asset=asset
		self.Preview:SetImage(asset)
		self:Status("Фон применяется ко всем вкладкам, ватермарку и окнам.")
		self:Apply()
	end)
end
function Appearance:Choose(item)
	if self.Closed then return end
	self.Library.Options.AstralGUIBackgroundURL:SetValue(item.Source)
	self.Library.Toggles.AstralGUIBackgroundEnabled:SetValue(true)
end
function Appearance:BuildUI()
	local lib, tab = self.Library, self.Tab
	local gallery=tab:AddLeftGroupbox("Библиотека фонов", "images")
	gallery:AddLabel("Зима · 10 фонов", true)
	local grid=new("Frame", gallery.Container, {Name="BackgroundGallery", BackgroundTransparency=1,
		Size=UDim2.new(1,0,0,5*96-8)})
	new("UIGridLayout", grid, {CellSize=UDim2.new(.5,-4,0,88), CellPadding=UDim2.fromOffset(8,8), SortOrder=Enum.SortOrder.LayoutOrder})
	for index, item in ipairs(Catalog.Items) do
		local card=new("TextButton", grid, {Name="BackgroundCard"..index, Text="", AutoButtonColor=false,
			BackgroundColor3=lib.Scheme.MainColor, BorderSizePixel=0, LayoutOrder=index, Size=UDim2.new(.5,-4,0,88)})
		new("UICorner", card, {CornerRadius=UDim.new(0,8)})
		local stroke=new("UIStroke", card, {Color=lib.Scheme.OutlineColor, Thickness=1})
		local picture=new("ImageLabel", card, {Name="Thumbnail", BackgroundTransparency=1, Image="",
			ScaleType=Enum.ScaleType.Crop, Position=UDim2.fromOffset(3,3), Size=UDim2.new(1,-6,1,-23)})
		new("UICorner", picture, {CornerRadius=UDim.new(0,6)})
		local title=new("TextLabel", card, {BackgroundTransparency=1, Text=item.Name, TextColor3=lib.Scheme.FontColor,
			TextSize=11, FontFace=lib.Scheme.Font, TextTruncate=Enum.TextTruncate.AtEnd,
			Position=UDim2.new(0,4,1,-20), Size=UDim2.new(1,-8,0,18)})
		lib:AddToRegistry(card, {BackgroundColor3="MainColor"})
		lib:AddToRegistry(title, {TextColor3="FontColor", FontFace="Font"})
		self.Cards[index]={Item=item, Button=card, Image=picture, Stroke=stroke, Title=title}
		self.Connections[#self.Connections+1]=card.Activated:Connect(function() self:Choose(item) end)
	end
	gallery:Resize()
	local selected=tab:AddRightGroupbox("Фон GUI", "image")
	self.Preview=selected:AddImage("AstralGUIBackgroundPreview", {Image="image", Height=150, ScaleType=Enum.ScaleType.Crop, BackgroundTransparency=1})
	self.SelectedLabel=selected:AddLabel("Текущий фон", true)
	local function changed() if not self.Building then self:Sync() end end
	selected:AddInput("AstralGUIBackgroundURL", {Text="Свой фон по URL", Default=self.DefaultSource,
		Placeholder="https://…/picture.jpg или Roblox ID", Finished=true, ClearTextOnFocus=false, Callback=changed})
	selected:AddButton({Text="Применить ссылку", Func=function()self.Source=nil;self:Sync()end})
	selected:AddToggle("AstralGUIBackgroundEnabled", {Text="Показывать обои во всём GUI", Default=true, Callback=changed})
	selected:AddLabel("Оттенок обоев"):AddColorPicker("AstralGUIBackgroundColor", {Default=WHITE, Title="Оттенок обоев", Callback=changed})
	selected:AddSlider("AstralGUIBackgroundTransparency", {Text="Прозрачность обоев", Default=.65, Min=0, Max=1, Rounding=2, Compact=true, Callback=changed})
	selected:AddDropdown("AstralGUIBackgroundMode", {Text="Размещение", Values={"Crop","Fit","Stretch"}, Default="Crop", AllowNull=false, Callback=changed})
	selected:AddButton({Text="Вернуть исходный фон", Func=function()
		lib.Options.AstralGUIBackgroundURL:SetValue(self.DefaultSource)
		lib.Toggles.AstralGUIBackgroundEnabled:SetValue(true)
	end})
	selected:AddButton({Text="Убрать обои", Func=function() lib.Toggles.AstralGUIBackgroundEnabled:SetValue(false) end})
	self.StatusLabel=selected:AddLabel("Фон для всех вкладок и окон.", true)
end
function Appearance:Sync()
	if self.Closed then return end
	local function value(id, fallback)
		local control=self.Library.Options[id] or self.Library.Toggles[id]
		if control and control.Value~=nil then return control.Value end
		return fallback
	end
	self.Config={Enabled=value("AstralGUIBackgroundEnabled",true), Color=value("AstralGUIBackgroundColor",WHITE),
		Transparency=math.clamp(value("AstralGUIBackgroundTransparency",.65),0,1), Mode=value("AstralGUIBackgroundMode","Crop")}
	local source=value("AstralGUIBackgroundURL",self.DefaultSource)
	self:SetSource(trim(source)=="" and self.DefaultSource or source)
	self:Apply(); self:LoadGallery()
end
function Appearance:PanelAlpha()
	return self.Config and self.Config.Enabled and self.Asset and math.max(.78,self.Library.Scheme.GlassTransparency) or self.Library.Scheme.GlassTransparency
end
function Appearance:LoadGallery()
	if self.Closed or not self.Tab.Container.Visible or not self.Window.MainFrame.Visible then return end
	while self.GalleryActive<2 and self.GalleryNext<=#self.Cards do
		local index=self.GalleryNext; self.GalleryNext+=1; self.GalleryActive+=1
		local card=self.Cards[index]
		self:Fetch(card.Item.Source,"Gallery"..index,function(asset)
			if self.Closed then return end
			if asset then card.Image.Image=asset end
			self.GalleryActive-=1; self:LoadGallery()
		end)
	end
end
function Appearance:AddSurface(frame)
	if self.Closed or not frame then return end
	local previous=self.Surfaces[frame]
	if previous then
		if frame.BackgroundTransparency~=1 then previous.Alpha=frame.BackgroundTransparency end
		self:ApplySurfaces()
		return
	end
	local image=new("ImageLabel", frame.Parent, {Name="AstralSharedWallpaper", Active=false, Selectable=false,
		BackgroundColor3=frame.BackgroundColor3, BackgroundTransparency=1, BorderSizePixel=0,
		Image="", Visible=false, ScaleType=Enum.ScaleType.Crop, ZIndex=math.max(0,frame.ZIndex-1)})
	local corner=new("UICorner", image, {CornerRadius=UDim.new(0,12)})
	local record={Image=image, Corner=corner, Alpha=frame.BackgroundTransparency, Connections={}}
	self.Surfaces[frame]=record
	for _,key in ipairs({"AbsolutePosition","AbsoluteSize","Visible","Parent","ZIndex"}) do
		record.Connections[#record.Connections+1]=frame:GetPropertyChangedSignal(key):Connect(function() self:ApplySurfaces() end)
	end
	record.Connections[#record.Connections+1]=frame.Destroying:Connect(function() self:RemoveSurface(frame) end)
	self:ApplySurfaces()
end
function Appearance:BaseAlpha(frame, record)
	local registry=self.Library.Registry[frame]
	local role=registry and registry.BackgroundTransparency
	if type(role)=="string" then return self.Library.Scheme[role] or record.Alpha end
	if type(role)=="function" then return role() end
	return record.Alpha
end
function Appearance:ApplySurfaces()
	if self.Closed or not self.Config or self.ApplyingSurfaces then return end
	self.ApplyingSurfaces=true
	for frame, record in pairs(self.Surfaces) do
		local active=self.Config.Enabled and self.Asset~=nil and frame.Visible and frame.Parent~=nil
		record.Image.Visible=active
		if active then
			local origin=frame.Parent.AbsolutePosition or Vector2.zero
			record.Image.Parent=frame.Parent
			record.Image.Position=UDim2.fromOffset(frame.AbsolutePosition.X-origin.X,frame.AbsolutePosition.Y-origin.Y)
			record.Image.Size=UDim2.fromOffset(frame.AbsoluteSize.X,frame.AbsoluteSize.Y)
			record.Image.ZIndex=math.max(0,frame.ZIndex-1)
			record.Image.Image=self.Asset; record.Image.ImageColor3=self.Config.Color
			record.Image.ImageTransparency=self.Config.Transparency
			record.Image.ScaleType=self.Config.Mode=="Fit" and Enum.ScaleType.Fit or self.Config.Mode=="Stretch" and Enum.ScaleType.Stretch or Enum.ScaleType.Crop
			record.Image.BackgroundColor3=frame:FindFirstChild("AstralPopupGradient") and self.Library.Scheme.BodyTopColor or frame.BackgroundColor3
			record.Image.BackgroundTransparency=self:BaseAlpha(frame,record)
			local corner=frame:FindFirstChildOfClass("UICorner")
			if corner then
				local scale=frame:FindFirstChildOfClass("UIScale")
				record.Corner.CornerRadius=UDim.new(corner.CornerRadius.Scale,corner.CornerRadius.Offset*(scale and scale.Scale or 1))
			end
			frame.BackgroundTransparency=1; record.Applied=true
		elseif record.Applied then frame.BackgroundTransparency=self:BaseAlpha(frame,record); record.Applied=false end
	end
	self.ApplyingSurfaces=false
end
function Appearance:Apply()
	if self.Closed or not self.Config then return end
	local chosen="Текущий фон"
	for _,card in ipairs(self.Cards) do
		local selected=card.Item.Source==self.Source
		card.Stroke.Color=selected and self.Library.Scheme.AccentColor or self.Library.Scheme.OutlineColor
		card.Stroke.Thickness=selected and 2 or 1
		if selected then chosen=card.Item.Name end
	end
	self.SelectedLabel:SetText(chosen)
	self.Preview:SetColor(self.Config.Color)
	self.Preview:SetTransparency(self.Config.Transparency)
	for node in pairs(self.Library.Registry) do
		if node.Parent and node:GetAttribute("AstralWallpaperPanel")==true then node.BackgroundTransparency=self:PanelAlpha() end
	end
	self:ApplySurfaces()
end
function Appearance:RemoveSurface(frame)
	local record=self.Surfaces[frame]; if not record then return end
	self.Surfaces[frame]=nil
	for _,connection in ipairs(record.Connections) do connection:Disconnect() end
	if frame.Parent and record.Applied then frame.BackgroundTransparency=self:BaseAlpha(frame,record) end
	record.Image:Destroy()
end
function Appearance:Dispose()
	if self.Closed then return end
	self.Closed=true; self.Generation+=1
	if self.Library.AppearanceController==self then self.Library.AppearanceController=nil end
	if self.Library.UpdateColorsUsingRegistry==self.ColorHook then self.Library.UpdateColorsUsingRegistry=self.PreviousColors end
	local frames={}; for frame in pairs(self.Surfaces) do frames[#frames+1]=frame end
	for _,frame in ipairs(frames) do self:RemoveSurface(frame) end
	for _,connection in ipairs(self.Connections) do connection:Disconnect() end
	for _,timer in ipairs(self.Timers) do if self.Context.CancelTask then pcall(self.Context.CancelTask,timer) end end
	for _,entry in pairs(self.Cache) do if entry.Pending and self.Context.Cancel then self.Context.Cancel(entry.Key) end end
	for _,card in ipairs(self.Cards) do
		for _,node in ipairs({card.Button,card.Title}) do self.Library:RemoveFromRegistry(node) end
	end
	table.clear(self.Cache)
end
return Appearance
