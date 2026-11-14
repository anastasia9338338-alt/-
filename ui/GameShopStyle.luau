-- The real game controls keep their paths and native callbacks. Decorations are
-- siblings of Menu, never extra children of the game's Contents item collection.
local requireModule=...
local Layout=requireModule('ShopLayout')
local Shop={};Shop.__index=Shop
local C=Color3.fromRGB
local function fold(text)
 local result={}
 for _,code in utf8.codes(tostring(text):lower())do
  if code>=0x410 and code<=0x42F then code+=32 elseif code==0x401 then code=0x451 end
  result[#result+1]=utf8.char(code)
 end
 return table.concat(result)
end
local function gui(v)return v and v:IsA('GuiObject')end
local function under(v,parent)return v==parent or v and v:IsDescendantOf(parent)end
local function children(v)return v and v:GetChildren()or{}end
local function descendants(v)return v and v:GetDescendants()or{}end
local function find(v,names)
 for _,name in ipairs(names)do local x=v:FindFirstChild(name);if x then return x end end
 return nil
end
local function live(v)return v and v.Parent end
local function parentGui(v)
 local p=v and v.Parent
 while p and not gui(p)do p=p.Parent end
 return p
end
local function visible(v,stop)
 while v do
  if gui(v)and not v.Visible then return false end
  if v==stop then return true end;v=v.Parent
 end
 return false
end
function Shop.Install(ctx)
 local self=setmetatable({Context=ctx,Records={},Connections={},Bound={},Watches={},Pages={},Created={},Enabled=false},Shop)
 local box=ctx.Tab:AddRightGroupbox('Игровой магазин','shopping-bag')
 box:AddToggle('AstralGUIShopStyle',{Text='Магазин по референсу',Default=true,Callback=function(v)self:SetEnabled(v)end})
 self.Status=box:AddLabel('Открой Your Toys в игровом меню.',true)
 self.Connections[#self.Connections+1]=ctx.PlayerGui.DescendantAdded:Connect(function(v)
  if self.Enabled and(v.Name=='MenuGui'or v.Name=='Menu'or v.Name=='TabContents'or self.Menu and under(v,self.Menu))then self:Queue()end
 end)
 if ctx.Library.ScreenGui then self.Connections[#self.Connections+1]=ctx.Library.ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()self:Queue()end)end
 return self
end
function Shop:Queue()
 if self.Closed or not self.Enabled or self.Queued then return end;self.Queued=true
 self.Context.Defer(function()self.Queued=false;if not self.Closed and self.Enabled then self:Find()end end)
end
function Shop:Watch(node,property)
 local map=self.Watches[node];if not map then map={};self.Watches[node]=map end
 if map[property]then return end
 map[property]=node:GetPropertyChangedSignal(property):Connect(function()
  if self.Closed or self.Applying or not self.Enabled then return end
  self:Queue()
 end)
end
function Shop:Write(node,key,value,scope,maintain)
 local r=self.Records[node]
 if not r then r={Scope=scope or'page',Properties={}};self.Records[node]=r end
 local p=r.Properties[key];if not p then p={Original=node[key]};r.Properties[key]=p end
 if node[key]~=value then node[key]=value end;p.Forced=value
 if maintain then self:Watch(node,key)end
end
function Shop:Restore(scope)
 for node,r in pairs(self.Records)do if not scope or r.Scope==scope then
  if node.Parent then for key,p in pairs(r.Properties)do if node[key]==p.Forced then node[key]=p.Original end end end
  self.Records[node]=nil
 end end
end
function Shop:Rect(node,r,scope)
 if not gui(node)then return end
 self:Write(node,'AnchorPoint',Vector2.zero,scope,true)
 self:Write(node,'AutomaticSize',Enum.AutomaticSize.None,scope,true)
 local parent=parentGui(node);local automatic=parent and(parent:FindFirstChildOfClass('UIListLayout')or parent:FindFirstChildOfClass('UIGridLayout'))
 self:Write(node,'Position',UDim2.fromOffset(r.X,r.Y),scope,not automatic)
 self:Write(node,'Size',UDim2.fromOffset(r.W,r.H),scope,true)
 local aspect=node:FindFirstChildOfClass('UIAspectRatioConstraint')
 if aspect then self:Write(aspect,'AspectRatio',r.W/math.max(r.H,.001),scope,true)end
 local limit=node:FindFirstChildOfClass('UISizeConstraint')
 if limit then self:Write(limit,'MinSize',Vector2.zero,scope,true);self:Write(limit,'MaxSize',Vector2.new(1e6,1e6),scope,true)end
end
function Shop:Text(node,size,scope)
 self:Write(node,'TextScaled',false,scope,true);self:Write(node,'TextWrapped',false,scope,true)
 self:Write(node,'FontFace',Font.fromEnum(Enum.Font.GothamBold),scope)
 self:Write(node,'TextSize',size,scope,true);self:Write(node,'TextColor3',C(247,247,247),scope)
 self:Write(node,'TextXAlignment',Enum.TextXAlignment.Left,scope)
end
function Shop:Normalize(node,scope)
 -- Folders are valid game containers, but do not expose GuiObject properties.
 -- All GUI ancestors are made a full-window coordinate space during this page.
 local p=node and node.Parent
 while p and p~=self.Menu.Parent do
  if gui(p)and p~=self.Menu then
   self:Rect(p,{X=0,Y=0,W=self.Plan.Width,H=self.Plan.Height},scope)
   self:Write(p,'BackgroundTransparency',1,scope,true);self:Write(p,'ClipsDescendants',false,scope)
   local stroke=p:FindFirstChildOfClass('UIStroke');if stroke then self:Write(stroke,'Transparency',1,scope)end
  end
  for _,scale in ipairs(children(p))do if scale:IsA('UIScale')then self:Write(scale,'Scale',1,scope,true)end end
  if p==self.Menu then break end;p=p.Parent
 end
end
function Shop:Surface()
 if live(self.Layer)then return end
 local parent=self.Menu.Parent
 while parent and not parent:IsA('ScreenGui')do parent=parent.Parent end
 parent=parent or self.Menu.Parent
 local layer=Instance.new('Frame');layer.Name='AstralGameShopSkin';layer.BackgroundTransparency=1;layer.BorderSizePixel=0;layer.Active=false;layer.Visible=false;layer.Parent=parent
 self.Layer=layer;self.Panels={};self.IconCopies={};self.IconMeta={};self.TextCopies={}
 for _,name in ipairs({'Sidebar','Title','Categories','Favorite','Body','Limit'})do
  local panel=Instance.new('Frame');panel.Name=name;panel.BorderSizePixel=0;panel.Active=false;panel.BackgroundColor3=C(51,53,55);panel.BackgroundTransparency=name=='Body'and .4 or .24;panel.Parent=layer
  local corner=Instance.new('UICorner');corner.Parent=panel;self.Panels[name]={Node=panel,Corner=corner}
 end
end
function Shop:Draw()
 self:Surface()
 local ok,origin=pcall(function()return self.Layer.Parent.AbsolutePosition end)
 if not ok or not origin then origin=Vector2.zero end
 local position=self.Menu.AbsolutePosition
 self.Layer.Position=UDim2.fromOffset(position.X-origin.X,position.Y-origin.Y)
 self.Layer.Size=UDim2.fromOffset(self.Plan.Width,self.Plan.Height);self.Layer.ZIndex=self.Menu.ZIndex-1;self.Layer.Visible=true
 for name,panel in pairs(self.Panels)do
  local r=self.Plan[name];panel.Node.Position=UDim2.fromOffset(r.X,r.Y);panel.Node.Size=UDim2.fromOffset(r.W,r.H)
  panel.Corner.CornerRadius=UDim.new(0,r.Radius);panel.Node.ZIndex=self.Menu.ZIndex-1
  panel.Node.Visible=name~='Favorite'or self.HasFavorite
 end
end
function Shop:Bind(menu,contents)
 self:Detach();self.Menu=menu;self.Contents=contents
 self.Bound[#self.Bound+1]=menu.DescendantAdded:Connect(function()self:Queue()end)
 self.Bound[#self.Bound+1]=menu:GetPropertyChangedSignal('Visible'):Connect(function()self:Queue()end)
 self.Bound[#self.Bound+1]=menu:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()if self.Active and self.Plan and live(self.Layer)then self:Draw()end end)
 self.Bound[#self.Bound+1]=menu.Destroying:Connect(function()
  self.Active=false;if self.Layer then self.Layer:Destroy();self.Layer=nil end;self:Queue()
 end)
 self:Watch(menu,'Size')
end
function Shop:Discover()
 local seen={};for _,r in ipairs(self.Pages)do seen[r.Node]=true end
 local list=children(self.Contents);for _,v in ipairs(descendants(self.Contents))do if v.Parent~=self.Contents then list[#list+1]=v end end
 for _,page in ipairs(list)do
  local name=page.Name:lower()
  if(name=='toys'or name=='toyshop'or name=='toystore'or name=='shop')and not seen[page]then
   local items=page:FindFirstChild('Contents',true)
   if items then
    local view=gui(items)and items or items:FindFirstChildWhichIsA('ScrollingFrame',true)
    if view then
     self.Pages[#self.Pages+1]={Node=page,List=view,Items=items}
     local p=view;while p and p~=self.Menu.Parent do if gui(p)then self:Watch(p,'Visible')end;if p==self.Menu then break end;p=p.Parent end
    end
   end
  end
 end
end
function Shop:Controls(record)
 local title,categories,favorite,limit,sidebar
 local buttons={}
 for _,node in ipairs(descendants(self.Menu))do
  if gui(node)and not under(node,record.Items)then
   local inPage=under(node,record.Node)
   local shared=not under(node,self.Contents)
   local name=node.Name:lower()
   if inPage or shared then
    if node:IsA('TextLabel')then
     local text=fold(node.Text)
     if text:find('your toys',1,true)or text:find('ваши игруш',1,true)or name=='title'or name=='heading'then title=title or node
     elseif text:find('лимит игруш',1,true)or text:find('toy limit',1,true)or name:find('toylimit',1,true)then limit=limit or node end
    end
    if(node:IsA('Frame')or node:IsA('ScrollingFrame')or node:IsA('Folder'))and(name:find('categor',1,true)or name=='filters')then categories=categories or node end
    if node:IsA('ImageButton')or node:IsA('TextButton')then
     if inPage and(name:find('favorite',1,true)or name:find('favourite',1,true)or name=='star'or name=='starbutton'or name=='stars')then favorite=favorite or node end
    end
   end
  end
 end
 -- Locate category buttons from a named group, or from the horizontal strip.
 if categories then for _,v in ipairs(descendants(categories))do if v:IsA('ImageButton')or v:IsA('TextButton')then buttons[#buttons+1]=v end end end
 if #buttons==0 then
  local groups={}
  for _,v in ipairs(descendants(record.Node))do if not under(v,record.Items)and(v:IsA('ImageButton')or v:IsA('TextButton'))and v~=favorite then
   local p=v.Parent;groups[p]=groups[p]or{};groups[p][#groups[p]+1]=v
  end end
  for p,group in pairs(groups)do if #group>=4 and #group<=12 then categories=p;buttons=group;break end end
 end
 -- Sidebar may be a Folder, a Frame, or a set of direct native buttons.
 local nav=find(self.Menu,{'Tabs','TabButtons','Navigation','Sidebar'})
 if nav then for _,v in ipairs(descendants(nav))do if v:IsA('ImageButton')or v:IsA('TextButton')then sidebar=sidebar or{};sidebar[#sidebar+1]=v end end end
 if not sidebar then
  local groups={}
  for _,v in ipairs(descendants(self.Menu))do if not under(v,self.Contents)and(v:IsA('ImageButton')or v:IsA('TextButton'))then
   local p=v.Parent;groups[p]=groups[p]or{};groups[p][#groups[p]+1]=v
  end end
  for _,group in pairs(groups)do if #group>=4 and #group<=8 then sidebar=group;break end end
 end
 return{Title=title,Categories=categories,CategoryButtons=buttons,Favorite=favorite,Limit=limit,Sidebar=sidebar or{},Nav=nav}
end
function Shop:Icon(node,r,scope)
 local visual=node
 if node:IsA('ImageButton')and(node.Image==nil or node.Image=='')then visual=node:FindFirstChildWhichIsA('ImageLabel',true)or node end
 if not(visual:IsA('ImageButton')or visual:IsA('ImageLabel'))or not visual.Image or visual.Image==''then return end
 self:Surface()
 local image=self.IconCopies[visual]
 if not image then image=Instance.new('ImageLabel');image.Name='NativeShopIcon';image.BackgroundTransparency=1;image.BorderSizePixel=0;image.Active=false;image.Parent=self.Layer;self.IconCopies[visual]=image end
 image.Position=UDim2.fromOffset(r.X,r.Y);image.Size=UDim2.fromOffset(r.W,r.H);image.Image=visual.Image
 image.ImageRectOffset=visual.ImageRectOffset;image.ImageRectSize=visual.ImageRectSize;image.ScaleType=Enum.ScaleType.Fit
 image.ImageColor3=C(245,245,245);image.ImageTransparency=0;image.ZIndex=self.Menu.ZIndex-1;image.Visible=true
 self.IconMeta[visual]={Button=node,Desired=r}
 self:Write(visual,'ImageTransparency',1,scope,true);self:Watch(visual,'Image');self:Watch(visual,'ImageRectOffset');self:Watch(visual,'ImageRectSize')
end
function Shop:RefreshIcons()
 if not self.Active or not live(self.Layer)or not live(self.Menu)then return end
 local origin=self.Menu.AbsolutePosition
 for visual,image in pairs(self.IconCopies)do
  local meta=self.IconMeta[visual]
  image.Visible=meta~=nil and live(visual)~=nil and visible(visual,self.Menu)
  if image.Visible then
   local button=meta.Button;local pos=button.AbsolutePosition-origin;local size=button.AbsoluteSize;local desired=meta.Desired
   local cx,cy=desired.X+desired.W*.5,desired.Y+desired.H*.5
   -- Follow native automatic layouts when their true hit rectangle differs.
   -- The displayed icon always stays inside the original clickable control.
   if cx<pos.X or cx>pos.X+size.X or cy<pos.Y or cy>pos.Y+size.Y then
    image.Position=UDim2.fromOffset(pos.X,pos.Y);image.Size=UDim2.fromOffset(size.X,size.Y)
   else image.Position=UDim2.fromOffset(desired.X,desired.Y);image.Size=UDim2.fromOffset(desired.W,desired.H)end
  end
 end
end
function Shop:StartIcons()
 if self.IconConnection or not self.Context.RunService then return end
 self.IconConnection=self.Context.RunService.RenderStepped:Connect(function()self:RefreshIcons()end)
end
function Shop:Label(key,text,r,size,right)
 self:Surface()
 local label=self.TextCopies[key]
 if not label then label=Instance.new('TextLabel');label.Name=key;label.BackgroundTransparency=1;label.BorderSizePixel=0;label.Active=false;label.Parent=self.Layer;self.TextCopies[key]=label end
 label.Position=UDim2.fromOffset(r.X,r.Y);label.Size=UDim2.fromOffset(r.W,r.H)
 label.Text=text;label.TextSize=size;label.TextScaled=false;label.TextWrapped=false;label.AutoLocalize=false
 label.FontFace=Font.fromEnum(Enum.Font.GothamBold);label.TextColor3=C(248,248,248)
 label.TextXAlignment=right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left;label.ZIndex=self.Menu.ZIndex-1;label.Visible=true
end
function Shop:Button(node,r,scope)
 self:Rect(node,r,scope);self:Write(node,'BackgroundTransparency',1,scope,true);self:Write(node,'BorderSizePixel',0,scope)
 if node:IsA('ImageButton')then self:Write(node,'ScaleType',Enum.ScaleType.Fit,scope)end
end
function Shop:Group(nodes,container,rect,direction,scope,page)
 if #nodes==0 then return end
 local root=gui(container)and container or parentGui(nodes[1])
 local dedicated=root and root~=self.Menu and root~=page and not under(self.Contents,root)
 if dedicated then
  self:Normalize(root,scope);self:Rect(root,rect,scope);self:Write(root,'BackgroundTransparency',1,scope,true);self:Write(root,'ClipsDescendants',false,scope)
  local layout=root:FindFirstChildOfClass('UIListLayout')
  if layout then self:Write(layout,'FillDirection',direction=='row'and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,scope,true);self:Write(layout,'Padding',UDim.new(0,0),scope,true)end
  local padding=root:FindFirstChildOfClass('UIPadding')
  if padding then for _,key in ipairs({'PaddingTop','PaddingBottom','PaddingLeft','PaddingRight'})do self:Write(padding,key,UDim.new(0,0),scope,true)end end
 end
 for i,node in ipairs(nodes)do
  local w=direction=='row'and rect.W/#nodes or rect.W;local h=direction=='row'and rect.H or rect.H/#nodes
  local x=direction=='row'and(i-1)*w or 0;local y=direction=='row'and 0 or(i-1)*h
  local global={X=rect.X+x,Y=rect.Y+y,W=w,H=h}
  if dedicated then
   local slot=node
   while slot.Parent and slot.Parent~=root do slot=slot.Parent end
   if gui(slot)then self:Rect(slot,{X=x,Y=y,W=w,H=h},scope);self:Write(slot,'BackgroundTransparency',1,scope,true)end
   if slot~=node then self:Button(node,{X=0,Y=0,W=w,H=h},scope)else self:Button(node,{X=x,Y=y,W=w,H=h},scope)end
  else self:Normalize(node,scope);self:Button(node,global,scope)end
  self:Icon(node,global,scope)
 end
end
function Shop:Page(record)
 local plan=self.Plan;local list=record.List;self:Surface()
 for _,image in pairs(self.IconCopies)do image.Visible=false end
 for _,label in pairs(self.TextCopies)do label.Visible=false end
 self:Normalize(list,'shared');self:Rect(list,plan.Body)
 self:Write(list,'BackgroundTransparency',1,nil,true);self:Write(list,'BorderSizePixel',0);self:Write(list,'ClipsDescendants',true)
 if list:IsA('ScrollingFrame')then self:Write(list,'ScrollBarThickness',0);self:Write(list,'ScrollingDirection',Enum.ScrollingDirection.Y);self:Write(list,'AutomaticCanvasSize',Enum.AutomaticSize.Y)end
 local grid=list:FindFirstChildOfClass('UIGridLayout')or record.Items:FindFirstChildOfClass('UIGridLayout')
 if grid then
  self:Write(grid,'CellSize',UDim2.fromOffset(plan.Cell,plan.Cell),nil,true);self:Write(grid,'CellPadding',UDim2.fromOffset(plan.Gap,plan.Gap),nil,true)
  self:Write(grid,'FillDirection',Enum.FillDirection.Horizontal,nil,true);self:Write(grid,'FillDirectionMaxCells',10,nil,true)
 end
 local padding=list:FindFirstChildOfClass('UIPadding')
 if padding then for _,key in ipairs({'PaddingTop','PaddingBottom','PaddingLeft','PaddingRight'})do self:Write(padding,key,UDim.new(0,2*plan.Scale),nil,true)end end
 for _,v in ipairs(descendants(record.Items))do if gui(v)then
  self:Write(v,'BackgroundTransparency',1,nil,true);self:Write(v,'BorderSizePixel',0)
  if v:IsA('ImageLabel')or v:IsA('ImageButton')then self:Write(v,'ScaleType',Enum.ScaleType.Fit)end
  if v.Parent==record.Items then
   self:Write(v,'AutomaticSize',Enum.AutomaticSize.None,nil,true)
   local bound=v:FindFirstChildOfClass('UISizeConstraint');if bound then self:Write(bound,'MinSize',Vector2.zero,nil,true);self:Write(bound,'MaxSize',Vector2.new(plan.Cell,plan.Cell),nil,true)end
  end
  local name=v.Name:lower()
  if v.Parent~=record.Items and(name:find('favorite',1,true)or name:find('favourite',1,true)or name=='star'or name=='starbutton')and(v:IsA('ImageButton')or v:IsA('TextButton'))then
   self:Write(v,'Visible',true,nil,true);self:Write(v,'AnchorPoint',Vector2.new(1,1));self:Write(v,'Position',UDim2.new(1,-1,1,-1));self:Write(v,'Size',UDim2.fromOffset(11*plan.Scale,11*plan.Scale))
  end
 end end
 local controls=self:Controls(record)
 if controls.Title then
  self:Normalize(controls.Title,'shared');self:Write(controls.Title,'TextTransparency',1,'shared',true);self:Write(controls.Title,'BackgroundTransparency',1,'shared',true)
 end
 self:Label('YourToysTitle',record.Node.Name:lower()=='toys'and'Your Toys'or'Toy Shop',plan.TitleText,plan.TitleSize)

 self.HasFavorite=controls.Favorite~=nil
 local categoryButtons={};for _,v in ipairs(controls.CategoryButtons)do if v~=controls.Favorite then categoryButtons[#categoryButtons+1]=v end end
 self:Group(categoryButtons,controls.Categories,plan.Categories,'row',nil,record.Node)
 if controls.Favorite then
  local parent=parentGui(controls.Favorite)
  local categoryRoot=gui(controls.Categories)and controls.Categories or parentGui(categoryButtons[1])
  if parent==categoryRoot and parent and parent~=record.Node and parent~=self.Menu then
   local gap=plan.Favorite.X-(plan.Categories.X+plan.Categories.W)
   self:Write(parent,'Size',UDim2.fromOffset(plan.Categories.W+gap+plan.Favorite.W,plan.Categories.H),nil,true)
   self:Button(controls.Favorite,{X=plan.Favorite.X-plan.Categories.X,Y=0,W=plan.Favorite.W+gap,H=plan.Favorite.H})
  else self:Normalize(controls.Favorite);self:Button(controls.Favorite,plan.Favorite)end
  self:Icon(controls.Favorite,plan.Favorite)
 end
 self:Group(controls.Sidebar,controls.Nav,plan.Sidebar,'column','shared',record.Node)
 self:Label('ToyLimitLabel','Toy Limit',plan.LimitText,math.max(6,6*plan.Scale))
 local count=''
 if controls.Limit then
  local caption=controls.Limit;local root=caption.Parent
  while root and root~=record.Node and root~=self.Menu and not under(record.List,root)do
   local parent=root.Parent
   if not parent or parent==record.Node or parent==self.Menu or under(record.List,parent)then break end
   root=parent
  end
  local dedicated=root and gui(root)and root~=record.Node and root~=self.Menu and not under(record.List,root)
  if dedicated then
   for _,v in ipairs(descendants(root))do if v:IsA('ImageButton')or v:IsA('TextButton')or v:IsA('TextBox')then dedicated=false;break end end
  end
  if dedicated then self:Normalize(root,'shared');self:Rect(root,plan.Limit,'shared')end
  self:Write(caption,'TextTransparency',1,'shared',true);self:Write(caption,'BackgroundTransparency',1,'shared')
  for _,v in ipairs(descendants(root or record.Node))do
   if v~=caption and v:IsA('TextLabel')and v.Text:match('%d+%s*/%s*%d+')then
    count=v.Text;self:Watch(v,'Text');self:Write(v,'TextTransparency',1,'shared',true)
   end
   if dedicated and gui(v)then
    self:Write(v,'BackgroundTransparency',1,'shared')
    if v:IsA('ImageLabel')then self:Write(v,'ImageTransparency',1,'shared')end
   end
  end
  if dedicated then self:Write(root,'BackgroundTransparency',1,'shared')end
 end

 self:Label('ToyLimitCount',count,{X=plan.Limit.X+plan.Limit.W-47*plan.Scale,Y=plan.Limit.Y+2*plan.Scale,W=42*plan.Scale,H=12*plan.Scale},math.max(6,6*plan.Scale),true)

 local close=find(self.Menu,{'Close','CloseButton','Exit','X'})
 if gui(close)then self:Rect(close,{X=344*plan.Scale,Y=0,W=18*plan.Scale,H=18*plan.Scale},'shared');if close:IsA('TextButton')then self:Text(close,14*plan.Scale,'shared')end end

 self:Draw();self:RefreshIcons();self:StartIcons()
end
function Shop:Find()
 if self.Closed or not self.Enabled or self.Applying then return end
 self.Applying=true
 local ok,why=pcall(function()
  local guiRoot=self.Context.PlayerGui:FindFirstChild('MenuGui');local menu=guiRoot and guiRoot:FindFirstChild('Menu')
  local contents=menu and menu:FindFirstChild('TabContents')
  if not gui(menu)or not contents then if self.Menu then self:Detach()end;self.Status:SetText('Ожидание игрового меню.');return end
  if self.Menu~=menu or self.Contents~=contents then self:Bind(menu,contents)end
  self:Discover();local active
  for _,r in ipairs(self.Pages)do if live(r.List)and visible(r.List,self.Menu)then active=r;break end end
  if not active then self.Active=false;if self.IconConnection then self.IconConnection:Disconnect();self.IconConnection=nil end;if self.Layer then self.Layer.Visible=false end;self:Restore('shared');self.Status:SetText('Открой Your Toys в игровом меню.');return end
  self.Active=true
  local camera=self.Context.Workspace and self.Context.Workspace.CurrentCamera
  local viewport=camera and camera.ViewportSize or Vector2.new(900,585)
  self.Plan=Layout.Build(viewport.X,viewport.Y)
  for _,scale in ipairs(children(menu))do if scale:IsA('UIScale')then self:Write(scale,'Scale',1,'shared',true)end end
  self:Write(menu,'AnchorPoint',Vector2.new(.5,.5),'shared',true);self:Write(menu,'Position',UDim2.fromScale(.5,.5),'shared',true)
  self:Write(menu,'AutomaticSize',Enum.AutomaticSize.None,'shared',true);self:Write(menu,'Size',UDim2.fromOffset(self.Plan.Width,self.Plan.Height),'shared',true);self:Write(menu,'BackgroundTransparency',1,'shared',true)
  self:Write(menu,'BorderSizePixel',0,'shared')
  local stroke=menu:FindFirstChildOfClass('UIStroke');if stroke then self:Write(stroke,'Transparency',1,'shared')end
  local aspect=menu:FindFirstChildOfClass('UIAspectRatioConstraint');if aspect then self:Write(aspect,'AspectRatio',364/272,'shared',true)end
  self:Page(active);self.Status:SetText('Your Toys: оформление по референсу включено.')
 end)
 self.Applying=false
 if not ok then self.LastError=tostring(why);self.Status:SetText('Магазин: '..self.LastError)end
end
function Shop:Detach()
 local applying=self.Applying;self.Applying=true
 if self.IconConnection then self.IconConnection:Disconnect();self.IconConnection=nil end
 for _,c in ipairs(self.Bound)do c:Disconnect()end;self.Bound={}
 for _,map in pairs(self.Watches)do for _,c in pairs(map)do c:Disconnect()end end;self.Watches={}
 self:Restore();if self.Layer then self.Layer:Destroy();self.Layer=nil end
 self.Pages={};self.Menu=nil;self.Contents=nil;self.Active=false;self.Applying=applying
end
function Shop:SetEnabled(value)
 if self.Closed then return end;self.Enabled=value==true
 if self.Enabled then if self.Status then self:Find()end else self:Detach();if self.Status then self.Status:SetText('Оригинальный магазин.')end end
end
function Shop:Sync()local t=self.Context.Library.Toggles.AstralGUIShopStyle;self:SetEnabled(t and t.Value)end
function Shop:Dispose()
 if self.Closed then return end;self.Closed=true;self.Enabled=false;self:Detach();for _,c in ipairs(self.Connections)do c:Disconnect()end
end
return Shop
