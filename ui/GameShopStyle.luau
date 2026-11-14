-- Layout the game's existing inventory. Do not style Settings, its HSV controls,
-- purchase dialogs, HUD or unrelated pages. Every native button keeps its path.
local Shop={};Shop.__index=Shop
local C=Color3.fromRGB
local function isGui(v)return v and v:IsA('GuiObject')end
local function descendants(v)return v and v:GetDescendants()or{}end
local function named(v,names)
 for _,name in ipairs(names)do local found=v:FindFirstChild(name);if found then return found end end
 return nil
end
local function corner(node)return node:FindFirstChildOfClass('UICorner')end
function Shop.Install(ctx)
 local self=setmetatable({Context=ctx,Records={},Created={},Connections={},MenuConnections={},Pages={},Enabled=false},Shop)
 local box=ctx.Tab:AddRightGroupbox('Игровой магазин','shopping-bag')
 box:AddToggle('AstralGUIShopStyle',{Text='Компактный магазин',Default=true,Callback=function(v)self:SetEnabled(v)end})
 box:AddLabel('Сетка игрушек, верхние категории и боковые иконки — как на образце.',true)
 self.Status=box:AddLabel('Открой игровой магазин.',true)
 self.Connections[#self.Connections+1]=ctx.PlayerGui.DescendantAdded:Connect(function(v)
  if self.Enabled and(v.Name=='MenuGui'or v.Name=='Menu'or v.Name=='TabContents')then self:Queue()end
 end)
 if ctx.Library.ScreenGui then
  self.Connections[#self.Connections+1]=ctx.Library.ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()self:Queue()end)
 end
 return self
end
function Shop:Queue()
 if self.Closed or self.Queued then return end;self.Queued=true
 self.Context.Defer(function()self.Queued=false;if not self.Closed and self.Enabled then self:Find()end end)
end
function Shop:Write(node,key,value,scope)
 local r=self.Records[node]
 if not r then r={Properties={},Scope=scope or'page'};self.Records[node]=r end
 local property=r.Properties[key]
 if not property then property={Original=node[key]};r.Properties[key]=property end
 node[key]=value;property.Forced=value
end
function Shop:Round(node,radius,scope)
 local c=corner(node)
 if c then self:Write(c,'CornerRadius',UDim.new(0,radius),scope)
 else
  c=Instance.new('UICorner');c.Name='AstralShopCorner';c.CornerRadius=UDim.new(0,radius);c.Parent=node
  self.Created[#self.Created+1]={Node=c,Scope=scope or'page'}
 end
end
function Shop:Restore(scope)
 for node,r in pairs(self.Records)do if not scope or r.Scope==scope then
  if node.Parent then for key,value in pairs(r.Properties)do if node[key]==value.Forced then node[key]=value.Original end end end
  self.Records[node]=nil
 end end
 for i=#self.Created,1,-1 do local r=self.Created[i];if not scope or r.Scope==scope then r.Node:Destroy();table.remove(self.Created,i)end end
end
function Shop:Detach()
 for _,c in ipairs(self.MenuConnections)do c:Disconnect()end;self.MenuConnections={}
 for _,page in ipairs(self.Pages)do if page.Connection then page.Connection:Disconnect()end end
 self:Restore();self.Pages={};self.Menu=nil;self.Contents=nil;self.Sidebar=nil
end
function Shop:Bind(menu,contents)
 self:Detach();self.Menu=menu;self.Contents=contents
 self.Sidebar=named(menu,{'Tabs','TabButtons','Navigation','Sidebar'})
 if not isGui(self.Sidebar)then
  for _,child in ipairs(menu:GetChildren())do if child~=contents and(child:IsA('Frame')or child:IsA('ScrollingFrame'))then
   local count=0;for _,v in ipairs(child:GetDescendants())do if v:IsA('ImageButton')then count+=1 end end
   if count>=4 and count<=12 then self.Sidebar=child;break end
  end end
 end
 self.MenuConnections[#self.MenuConnections+1]=menu.DescendantAdded:Connect(function(v)
  if v.Name~='AstralShopCorner'then self:Queue()end
 end)
 self.MenuConnections[#self.MenuConnections+1]=menu:GetPropertyChangedSignal('Visible'):Connect(function()self:Queue()end)
 self.MenuConnections[#self.MenuConnections+1]=contents:GetPropertyChangedSignal('Visible'):Connect(function()self:Queue()end)
end
function Shop:Discover()
 local seen={};for _,record in ipairs(self.Pages)do seen[record.Node]=true end
 for _,page in ipairs(self.Contents:GetChildren())do
  -- Actual game path: MenuGui.Menu.TabContents.Toys.Contents.
  local name=page.Name:lower()
  if isGui(page)and(name=='toys'or name=='toyshop'or name=='shop'or name=='toystore')and not seen[page]then
   local list=page:FindFirstChild('Contents',true)
   if list and(list:IsA('ScrollingFrame')or list:IsA('Frame'))then
    local record={Node=page,List=list};self.Pages[#self.Pages+1]=record
    record.Connection=page:GetPropertyChangedSignal('Visible'):Connect(function()self:Queue()end)
   end
  end
 end
end
function Shop:Window()
 local camera=self.Context.Workspace and self.Context.Workspace.CurrentCamera
 local viewport=camera and camera.ViewportSize or self.Context.Library.ScreenGui and self.Context.Library.ScreenGui.AbsoluteSize or Vector2.new(1024,768)
 local width=math.max(160,math.min(720,viewport.X-32,(viewport.Y-54)*720/530))
 local height=width*530/720
 local scale=self.Menu:FindFirstChildOfClass('UIScale');local dpi=math.max(.1,scale and scale.Scale or 1)
 self.Width=width/dpi;self.Height=height/dpi
 self:Write(self.Menu,'Size',UDim2.fromOffset(self.Width,self.Height),'shared')
 self:Write(self.Menu,'AnchorPoint',Vector2.new(.5,.5),'shared')
 self:Write(self.Menu,'Position',UDim2.fromScale(.5,.5),'shared')
 self:Write(self.Menu,'BackgroundTransparency',1,'shared')
 self:Write(self.Menu,'BorderSizePixel',0,'shared')
 local aspect=self.Menu:FindFirstChildOfClass('UIAspectRatioConstraint')
 if aspect then self:Write(aspect,'AspectRatio',720/530,'shared')end
 self:Write(self.Contents,'AnchorPoint',Vector2.zero,'shared');self:Write(self.Contents,'Position',UDim2.fromOffset(76,0),'shared')
 self:Write(self.Contents,'Size',UDim2.new(1,-76,1,0),'shared')
 self:Write(self.Contents,'BackgroundTransparency',1,'shared')
 if isGui(self.Sidebar)then
  local top=self.Height>=360 and 80 or 38
  self:Write(self.Sidebar,'AnchorPoint',Vector2.zero,'shared');self:Write(self.Sidebar,'Position',UDim2.fromOffset(0,top),'shared')
  self:Write(self.Sidebar,'Size',UDim2.new(0,64,1,-top),'shared')
  self:Write(self.Sidebar,'BackgroundColor3',C(54,56,59),'shared')
  self:Write(self.Sidebar,'BackgroundTransparency',.3,'shared')
  self:Write(self.Sidebar,'BorderSizePixel',0,'shared');self:Round(self.Sidebar,18,'shared')
  if self.Sidebar:IsA('ScrollingFrame')then self:Write(self.Sidebar,'ScrollBarThickness',0,'shared')end
  local buttons={};for _,v in ipairs(self.Sidebar:GetChildren())do if v:IsA('ImageButton')or v:IsA('TextButton')then buttons[#buttons+1]=v end end
  local layout=self.Sidebar:FindFirstChildOfClass('UIListLayout')
  local rowHeight=math.min(58,(self.Height-top)/math.max(#buttons,1))
  for index,v in ipairs(buttons)do
   self:Write(v,'BackgroundTransparency',1,'shared');self:Write(v,'BorderSizePixel',0,'shared')
   self:Write(v,'Size',UDim2.new(1,0,0,height))
   if v:IsA('ImageButton')then self:Write(v,'ScaleType',Enum.ScaleType.Fit,'shared')end
   if not layout then self:Write(v,'AnchorPoint',Vector2.zero,'shared');self:Write(v,'Position',UDim2.fromOffset(0,(index-1)*rowHeight),'shared')end
  end
 end
 local close=named(self.Menu,{'Close','CloseButton','Exit','X'})
 if isGui(close)then
  self:Write(close,'AnchorPoint',Vector2.new(1,0),'shared');self:Write(close,'Position',UDim2.new(1,-2,0,-28),'shared')
  self:Write(close,'Size',UDim2.fromOffset(24,24),'shared')
 end
end
function Shop:Header(record)
 local page,list=record.Node,record.List;local categories,title,search
 for _,v in ipairs(descendants(page))do if not v:IsDescendantOf(list)and v~=list then
  local name=v.Name:lower()
  if(v:IsA('Frame')or v:IsA('ScrollingFrame'))and(name:find('categor',1,true)or name=='filters')then categories=categories or v end
  if v:IsA('TextBox')then search=search or v end
  if v:IsA('TextLabel')and(name:find('title',1,true)or name=='heading'or v.Text:lower():find('toys',1,true)or v.Text:lower():find('игруш',1,true))then title=title or v end
 end end
 local function normalizeParents(node)
  local parent=node and node.Parent
  while parent and parent~=page do
   if isGui(parent)then
    self:Write(parent,'AnchorPoint',Vector2.zero);self:Write(parent,'Position',UDim2.fromOffset(0,0));self:Write(parent,'Size',UDim2.new(1,0,0,34))
    self:Write(parent,'BackgroundTransparency',1);self:Write(parent,'ClipsDescendants',false)
   end
   parent=parent.Parent
  end
 end
 normalizeParents(title);normalizeParents(search);normalizeParents(categories)
 if title then
  self:Write(title,'TextColor3',C(245,245,245));self:Write(title,'FontFace',Font.fromEnum(Enum.Font.BuilderSansBold))
  self:Write(title,'TextSize',18);self:Write(title,'TextXAlignment',Enum.TextXAlignment.Left)
  if title.Parent then
   self:Write(title,'AnchorPoint',Vector2.zero);self:Write(title,'Position',UDim2.fromOffset(10,0));self:Write(title,'Size',UDim2.new(search and .26 or .53,-14,0,34))
  end
 end
 if search and search.Parent then
  self:Write(search,'AnchorPoint',Vector2.zero);self:Write(search,'Position',UDim2.new(.28,0,0,4));self:Write(search,'Size',UDim2.new(.26,-4,0,26))
  self:Write(search,'BackgroundTransparency',1);self:Write(search,'TextSize',12);self:Write(search,'TextColor3',C(230,230,230))
 end
 if categories and categories.Parent then
  self:Write(categories,'AnchorPoint',Vector2.zero);self:Write(categories,'Position',UDim2.new(.56,3,0,0));self:Write(categories,'Size',UDim2.new(.44,-3,0,34))
  self:Write(categories,'BackgroundColor3',C(54,56,59));self:Write(categories,'BackgroundTransparency',.18)
  self:Write(categories,'BorderSizePixel',0);self:Round(categories,15)
  if categories:IsA('ScrollingFrame')then self:Write(categories,'ScrollBarThickness',0)end
  local buttons={};for _,v in ipairs(categories:GetChildren())do if v:IsA('ImageButton')or v:IsA('TextButton')then buttons[#buttons+1]=v end end
  local layout=categories:FindFirstChildOfClass('UIListLayout')
  if layout then self:Write(layout,'FillDirection',Enum.FillDirection.Horizontal);self:Write(layout,'Padding',UDim.new(0,1))end
  for index,v in ipairs(buttons)do
   self:Write(v,'BackgroundTransparency',1);self:Write(v,'BorderSizePixel',0)
   if v:IsA('ImageButton')then self:Write(v,'ScaleType',Enum.ScaleType.Fit)end
   self:Write(v,'Size',UDim2.new(1/math.max(#buttons,1),-1,1,0))
   if not layout then self:Write(v,'AnchorPoint',Vector2.zero);self:Write(v,'Position',UDim2.fromScale((index-1)/math.max(#buttons,1),0))end
  end
 end
end
function Shop:Page(record)
 local page,list=record.Node,record.List
 self:Write(page,'AnchorPoint',Vector2.zero);self:Write(page,'Position',UDim2.fromOffset(0,0));self:Write(page,'Size',UDim2.fromScale(1,1))
 self:Write(page,'BackgroundColor3',C(48,50,53));self:Write(page,'BackgroundTransparency',.28)
 self:Write(page,'BorderSizePixel',0);self:Write(page,'ClipsDescendants',true);self:Round(page,18)
 self:Write(list,'AnchorPoint',Vector2.zero);self:Write(list,'Position',UDim2.fromOffset(7,38));self:Write(list,'Size',UDim2.new(1,-14,1,-44))
 self:Write(list,'BackgroundTransparency',1);self:Write(list,'BorderSizePixel',0);self:Write(list,'ClipsDescendants',true)
 local available=math.max(20,self.Width-90);local columns=math.clamp(math.floor((available+4)/34),4,10)
 local cell=math.max(12,math.floor((available-(columns-1)*4)/columns))
 local grid=list:FindFirstChildOfClass('UIGridLayout')
 if grid then
  self:Write(grid,'CellSize',UDim2.fromOffset(cell,cell));self:Write(grid,'CellPadding',UDim2.fromOffset(4,4))
  self:Write(grid,'FillDirection',Enum.FillDirection.Horizontal);self:Write(grid,'FillDirectionMaxCells',columns)
 end
 if list:IsA('ScrollingFrame')then
  self:Write(list,'ScrollBarThickness',0);self:Write(list,'ScrollingDirection',Enum.ScrollingDirection.Y)
  self:Write(list,'AutomaticCanvasSize',Enum.AutomaticSize.Y)
 end
 for _,v in ipairs(descendants(list))do
  if isGui(v)then
   self:Write(v,'BackgroundTransparency',1);self:Write(v,'BorderSizePixel',0)
   if v:IsA('ImageLabel')or v:IsA('ImageButton')then self:Write(v,'ScaleType',Enum.ScaleType.Fit)end
   if v:IsA('TextLabel')then self:Write(v,'TextColor3',C(245,245,245));self:Write(v,'FontFace',Font.fromEnum(Enum.Font.BuilderSansBold))end
  end
 end
 self:Header(record)
end
function Shop:Find()
 if not self.Enabled or self.Closed or self.Updating then return end;self.Updating=true
 local gui=self.Context.PlayerGui:FindFirstChild('MenuGui');local menu=gui and gui:FindFirstChild('Menu')
 local contents=menu and menu:FindFirstChild('TabContents')
 if not isGui(menu)or not isGui(contents)then
  if self.Menu then self:Detach()end;self.Status:SetText('Открой игровой магазин.');self.Updating=false;return
 end
 if self.Menu~=menu or self.Contents~=contents then self:Bind(menu,contents)end
 self:Discover()
 local active=false
 for _,r in ipairs(self.Pages)do if r.Node.Parent and r.Node.Visible then active=true;break end end
 if active and contents.Visible and menu.Visible then
  self:Window();for _,r in ipairs(self.Pages)do if r.Node.Parent and r.Node.Visible then self:Page(r)end end
  self.Status:SetText('Игровой магазин: компактная сетка включена.')
 else self:Restore('shared');self.Status:SetText('Оформление включится на вкладке игрушек.')end
 self.Updating=false
end
function Shop:SetEnabled(value)
 if self.Closed then return end;self.Enabled=value==true
 if self.Enabled then if self.Status then self:Find()end
 else self:Detach();if self.Status then self.Status:SetText('Оригинальное оформление магазина.')end end
end
function Shop:Sync()local t=self.Context.Library.Toggles.AstralGUIShopStyle;self:SetEnabled(t and t.Value)end
function Shop:Dispose()
 if self.Closed then return end;self.Closed=true;self.Enabled=false;self:Detach()
 for _,c in ipairs(self.Connections)do c:Disconnect()end
end
return Shop
