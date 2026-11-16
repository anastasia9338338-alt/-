-- The real game controls keep their paths and native callbacks. Decorations are
-- siblings of Menu, never extra children of the game's Contents item collection.
local requireModule=...
local Layout=requireModule('ShopLayout')
local Quick=requireModule('ShopQuickSpawn')
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
local function descendants(v,skip,quick)
 if not v then return {}end
 local result,stack={},{}
 local first=v:GetChildren();for i=#first,1,-1 do stack[#stack+1]=first[i]end
 while #stack>0 do
  local node=table.remove(stack)
  if node==skip or node==quick then continue end
  result[#result+1]=node
  -- Toy preview meshes are rendered by Roblox. Skinning their GUI never
  -- needs to walk thousands of parts/attachments inside each WorldModel.
  if not node:IsA('WorldModel')and not node:IsA('Model')and not node:IsA('BasePart')and not node:IsA('Camera')then
   local nested=node:GetChildren();for i=#nested,1,-1 do stack[#stack+1]=nested[i]end
  end
 end
 return result
end
local function find(v,names)
 for _,name in ipairs(names)do local x=v:FindFirstChild(name);if x then return x end end
 return nil
end
local function live(v)return v and v.Parent end
local function favoriteName(v)
 local name=fold(v.Name)
 return name:find('favorit',1,true)or name:find('favourit',1,true)or name:find('избран',1,true)or name=='star'or name=='starbutton'or name=='stars'
end
local function button(v)return v:IsA('ImageButton')or v:IsA('TextButton')end
local function order(nodes,direction)
 local index={};for i,v in ipairs(nodes)do index[v]=i end
 table.sort(nodes,function(a,b)
  if a.LayoutOrder~=b.LayoutOrder then return a.LayoutOrder<b.LayoutOrder end
  local pa,pb=a.AbsolutePosition,b.AbsolutePosition
  local av,bv=direction=='column'and pa.Y or pa.X,direction=='column'and pb.Y or pb.X
  return av==bv and index[a]<index[b]or av<bv
 end)
end
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
-- Cache native tree snapshots until an external structural mutation. One menu
-- event previously scanned every page several times and restyled all cells.
function Shop:Descendants(node)
 if not node then return {}end
 self.DescCache=self.DescCache or setmetatable({},{__mode='k'})
 local cache=self.DescCache[node];local version=self.TreeVersion or 0
 if cache and cache.Version==version then return cache.Nodes end
 local nodes=descendants(node,self.Layer,self.Quick and self.Quick.Host);self.TreeScans=(self.TreeScans or 0)+1
 self.DescCache[node]={Version=version,Nodes=nodes};return nodes
end
function Shop:Invalidate(node)
 if self.Applying or(self.Quick and self.Quick:Owns(node))then return end
 if node:IsA('WorldModel')or node:IsA('Model')or node:IsA('BasePart')or node:IsA('Camera')or node:IsA('Attachment')or node:IsA('JointInstance')then return end
 self.TreeVersion=(self.TreeVersion or 0)+1;self.StructureDirty=true
 local owner
 for _,record in ipairs(self.Pages)do if under(node,record.Node)then owner=record;break end end
 if owner then
  owner.Styled=nil;owner.Controls=nil
  local holder=owner.Grid and owner.Grid.Parent
  local cell=node
  while cell and cell.Parent~=holder and cell~=owner.Node do cell=cell.Parent end
  if cell and self.CellStyles then self.CellStyles[cell]=nil end
 end
 if not owner or owner==self.Current then self.Dirty=true end
 self:Queue()
end
function Shop.Install(ctx)
 local self=setmetatable({Context=ctx,Records={},Connections={},Bound={},Watches={},Pages={},Created={},Enabled=false},Shop)
 local box=ctx.Tab:AddRightGroupbox('Игровой магазин','shopping-bag')
 box:AddToggle('AstralGUIShopStyle',{Text='Магазин по референсу',Default=true,Callback=function(v)self:SetEnabled(v)end})
 self.Status=box:AddLabel('Открой Your Toys в игровом меню.',true)
 if ctx.Input and ctx.SpawnQuick then self.Quick=Quick.Install(self,ctx)end
 self.Connections[#self.Connections+1]=ctx.PlayerGui.DescendantAdded:Connect(function(v)
  if self.Enabled and(v.Name=='MenuGui'or v.Name=='Menu'or v.Name=='TabContents')then self:Queue()end
 end)
 if ctx.Library.ScreenGui then self.Connections[#self.Connections+1]=ctx.Library.ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()self:Queue()end)end
 return self
end
function Shop:Queue()
 if self.Closed or self.Applying or not self.Enabled or self.Queued then return end;self.Queued=true
 self.Context.Defer(function()self.Queued=false;if not self.Closed and self.Enabled then self:Find()end end)
end
-- Native hover/filter/viewport code can rewrite geometry after the first
-- styled frame. Repair only the affected recorded properties; routing every
-- overwrite through Find used to walk/repaint the entire shop on interaction.
function Shop:QueueRepair(node,key,record)
 if self.Closed or not self.Enabled then return end
 self.PendingRepairs=self.PendingRepairs or{}
 local entry=self.PendingRepairs[node]
 if not entry or entry.Record~=record then entry={Record=record,Keys={}};self.PendingRepairs[node]=entry end
 entry.Keys[key]=true
 if self.RepairQueued then return end
 self.RepairQueued=true
 self.Context.Defer(function()
  self.RepairQueued=false
  local pending=self.PendingRepairs;self.PendingRepairs={}
  if self.Closed or not self.Enabled then return end
  local applying=self.Applying;self.Applying=true
  for object,work in pairs(pending)do
   local owner=self.CellOwners and self.CellOwners[object]
   if object.Parent and self.Records[object]==work.Record and(not owner or under(owner,self.Menu))then
    for property in pairs(work.Keys)do
     local saved=work.Record.Properties[property]
     if saved and object[property]~=saved.Forced then
      local ok,why=pcall(function()object[property]=saved.Forced end)
      if ok then self.GeometryRepairs=(self.GeometryRepairs or 0)+1 else self.LastRepairError=tostring(why)end
     end
    end
   end
  end
  self.Applying=applying
 end)
end
function Shop:WatchCell(node,key,cell)
 if not cell then return end
 self.CellOwners=self.CellOwners or setmetatable({},{__mode='k'})
 self.CellMaintained=self.CellMaintained or setmetatable({},{__mode='k'})
 self.CellWatches=self.CellWatches or{}
 self.CellOwners[node]=cell
 local maintained=self.CellMaintained[node]or{};self.CellMaintained[node]=maintained;maintained[key]=true
 if self.CellWatches[node]then return end
 -- One observer for a GUI/constraint instance, rather than one per styled
 -- property. Native content changes (Text/Image) do not request a repaint.
 self.CellWatches[node]=node.Changed:Connect(function(property)
  if self.Closed or self.Applying or not self.Enabled or not maintained[property]then return end
  local owner=self.CellOwners[node]
  local record=self.Records[node];local saved=record and record.Properties[property]
  if owner and under(owner,self.Menu)and saved and node[property]~=saved.Forced then self:QueueRepair(node,property,record)end
 end)
end
function Shop:Watch(node,property)
 local map=self.Watches[node];if not map then map={};self.Watches[node]=map end
 if map[property]then return end
 map[property]=node:GetPropertyChangedSignal(property):Connect(function()
  if self.Closed or self.Applying or not self.Enabled then return end
  -- Our gradient/icon layer is maintained by Draw and the theme registry.
  -- Its own color/rounding writes must not schedule another native page pass.
  if self.Layer and under(node,self.Layer)then return end
  local record=self.Records[node];local saved=record and record.Properties[property]
  if saved and node[property]~=saved.Forced then self:QueueRepair(node,property,record);return end
  if self.FooterNodes and self.FooterNodes[node]then self.FooterDirty=true else
   self.Dirty=true
   for _,record in ipairs(self.Pages)do if under(node,record.Node)and property~='Visible'then record.Styled=nil end end
   if property=='Visible'then
    for _,record in ipairs(self.Pages)do if node~=record.Node and under(node,record.Node)then record.Styled=nil end end
   end
  end;self:Queue()
 end)
end
function Shop:Write(node,key,value,scope,maintain)
 local r=self.Records[node]
 if not r then r={Scope=scope or'page',Properties={}};self.Records[node]=r end
 local p=r.Properties[key];if not p then p={Original=node[key]};r.Properties[key]=p end
 if node[key]~=value then node[key]=value end;p.Forced=value
 if maintain then
  if self.ItemStyling then self:WatchCell(node,key,self.StylingCell)else self:Watch(node,key)end
 end
end
function Shop:Restore(scope)
 for node,r in pairs(self.Records)do if not scope or r.Scope==scope then
  if node.Parent then for key,p in pairs(r.Properties)do if node[key]==p.Forced then node[key]=p.Original end end end
  self.Records[node]=nil
 end end
 for node,ownedScope in pairs(self.Created)do if not scope or ownedScope==scope then if node.Parent then node:Destroy()end;self.Created[node]=nil end end
end
function Shop:Rect(node,r,scope)
 if not gui(node)then return end
 self:Write(node,'AnchorPoint',Vector2.zero,scope,true)
 self:Write(node,'AutomaticSize',Enum.AutomaticSize.None,scope,true)
 self:Write(node,'SizeConstraint',Enum.SizeConstraint.RelativeXY,scope,true)
 local parent=parentGui(node);local automatic=parent and(parent:FindFirstChildOfClass('UIListLayout')or parent:FindFirstChildOfClass('UIGridLayout'))
 self:Write(node,'Position',UDim2.fromOffset(r.X,r.Y),scope,not automatic)
 self:Write(node,'Size',UDim2.fromOffset(r.W,r.H),scope,true)
 local aspect=node:FindFirstChildOfClass('UIAspectRatioConstraint')
 if aspect then
  self:Write(aspect,'AspectType',Enum.AspectType.FitWithinMaxSize,scope,true)
  self:Write(aspect,'DominantAxis',Enum.DominantAxis.Width,scope,true)
  self:Write(aspect,'AspectRatio',r.W/math.max(r.H,.001),scope,true)
 end
 for _,limit in ipairs(children(node))do if limit:IsA('UISizeConstraint')then self:Write(limit,'MinSize',Vector2.zero,scope,true);self:Write(limit,'MaxSize',Vector2.new(1e6,1e6),scope,true)end end
end
function Shop:Round(node,radius,scope)
 local corner=node:FindFirstChildOfClass('UICorner')
 if not corner then corner=Instance.new('UICorner');corner.Name='AstralShopCorner';corner.Parent=node;self.Created[corner]=scope or'page' end
 self:Write(corner,'CornerRadius',UDim.new(0,radius),scope,true)
end
function Shop:Text(node,size,scope)
 self:Write(node,'TextScaled',false,scope,true);self:Write(node,'TextWrapped',false,scope,true)
 self:Write(node,'FontFace',Font.fromEnum(Enum.Font.GothamBold),scope)
 self:Write(node,'TextSize',size,scope,true);self:Write(node,'TextColor3',self:ThemeColor('FontColor',C(231,234,238)),scope)
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
  if p~=self.Menu then for _,scale in ipairs(children(p))do if scale:IsA('UIScale')then self:Write(scale,'Scale',1,scope,true)end end end
  if p==self.Menu then break end;p=p.Parent
 end
end
function Shop:ThemeColor(key,fallback)
 local scheme=self.Context.Library.Scheme or{}
 return scheme[key]or fallback
end
function Shop:RegisterTheme(node,properties)
 if self.Context.Library.AddToRegistry then self.Context.Library:AddToRegistry(node,properties)end
end
function Shop:DestroyArtwork(node)
 if not node then return end
 if self.Context.Library.RemoveFromRegistry then
  for _,child in ipairs(self:Descendants(node))do self.Context.Library:RemoveFromRegistry(child)end
  self.Context.Library:RemoveFromRegistry(node)
 end
 node:Destroy()
end
function Shop:PanelTheme(panel)
 local scheme=self.Context.Library.Scheme or{}
 panel.BackgroundColor3=self:ThemeColor('WhiteColor',C(255,255,255))
 panel.BackgroundTransparency=tonumber(scheme.GlassTransparency)or .55
 local gradient=panel:FindFirstChild('AstralShopGradient')
 if not gradient then gradient=Instance.new('UIGradient');gradient.Name='AstralShopGradient';gradient.Rotation=90;gradient.Parent=panel end
 local function colors()
  return ColorSequence.new(self:ThemeColor('BodyTopColor',C(24,26,29)),self:ThemeColor('BodyBottomColor',C(21,23,26)))
 end
 gradient.Color=colors()
 self:RegisterTheme(panel,{BackgroundColor3='WhiteColor',BackgroundTransparency='GlassTransparency'})
 self:RegisterTheme(gradient,{Color=colors});self:Watch(gradient,'Color')
end
function Shop:Surface()
 if live(self.Layer)then return end
 local parent=self.Menu.Parent
 while parent and not parent:IsA('ScreenGui')do parent=parent.Parent end
 parent=parent or self.Menu.Parent
 local layer=Instance.new('Frame');layer.Name='AstralGameShopSkin';layer.BackgroundTransparency=1;layer.BorderSizePixel=0;layer.Active=false;layer.Visible=false;layer.Parent=parent
 self.Layer=layer;self.LayerScale=Instance.new('UIScale');self.LayerScale.Parent=layer;self.Panels={};self.IconCopies={};self.IconMeta={};self.TextCopies={}
 for _,name in ipairs({'Sidebar','Title','Categories','Favorite','Body','Limit'})do
  local panel=Instance.new('Frame');panel.Name=name;panel.BorderSizePixel=0;panel.Active=false;panel.Parent=layer;self:PanelTheme(panel)
  local corner=Instance.new('UICorner');corner.Parent=panel;self.Panels[name]={Node=panel,Corner=corner}
 end
end
function Shop:Draw()
 self:Surface()
 local ok,origin=pcall(function()return self.Layer.Parent.AbsolutePosition end)
 if not ok or not origin then origin=Vector2.zero end
 local position=self.Menu.AbsolutePosition
 self.Layer.Position=UDim2.fromOffset(position.X-origin.X,position.Y-origin.Y)
 self.LayerScale.Scale=self.MenuScale or 1;self.Layer.Size=UDim2.fromOffset(self.Plan.Width,self.Plan.Height);self.Layer.ZIndex=self.Menu.ZIndex-1;self.Layer.Visible=true
 for name,panel in pairs(self.Panels)do
  self:PanelTheme(panel.Node)
  local r=self.Plan[name];panel.Node.Position=UDim2.fromOffset(r.X,r.Y);panel.Node.Size=UDim2.fromOffset(r.W,r.H)
  panel.Corner.CornerRadius=UDim.new(0,r.Radius);panel.Node.ZIndex=self.Menu.ZIndex-1
  panel.Node.Visible=(name~='Favorite'or self.HasFavorite)and(name~='Categories'or self.HasCategories)and(name~='Limit'or self.ShowLimit)
 end
end
function Shop:Bind(menu,contents)
 self:Detach();self.Menu=menu;self.Contents=contents;self.StructureDirty=true;self.TreeVersion=(self.TreeVersion or 0)+1
 self.Bound[#self.Bound+1]=menu.DescendantAdded:Connect(function(v)self:Invalidate(v)end)
 self.Bound[#self.Bound+1]=menu.DescendantRemoving:Connect(function(v)self:Invalidate(v)end)
 self.Bound[#self.Bound+1]=menu:GetPropertyChangedSignal('Visible'):Connect(function()self:Queue()end)
 self.Bound[#self.Bound+1]=menu:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()if self.Active and self.Plan and live(self.Layer)then self:Draw()end end)
 self.Bound[#self.Bound+1]=menu.Destroying:Connect(function()
  self.Active=false;if self.Layer then self:DestroyArtwork(self.Layer);self.Layer=nil end;self:Queue()
 end)
 self:Watch(menu,'Size')
end
local function rootScale(node,stop)
 local scale=1
 while node and node~=stop do
  for _,v in ipairs(children(node))do if v:IsA('UIScale')and v.Scale>0 then scale*=v.Scale end end
  node=node.Parent
 end
 return scale
end
function Shop:CollectionGrid(root)
 local best,score=nil,-1
 for _,node in ipairs(self:Descendants(root))do if node:IsA('UIGridLayout')then
  local count,known,interactive=0,0,0
  for _,child in ipairs(children(node.Parent))do if gui(child)then
   count+=1
   if button(child)or child:FindFirstChildWhichIsA('ImageButton',true)or child:FindFirstChildWhichIsA('TextButton',true)then interactive+=1 end
   local name=self.Context.ResolveItem and self.Context.ResolveItem(child)or child.Name
   if self.Context.Catalog and self.Context.Catalog[name]then known+=1 end
  end end
  local value=count+known*1000+interactive*100
  if value>score then best=node;score=value end
 end end
 return best
end
function Shop:Discover()
 self.DiscoveryPasses=(self.DiscoveryPasses or 0)+1
 local seen={};for _,r in ipairs(self.Pages)do seen[r.Node]=true end
 for _,page in ipairs(children(self.Contents))do
  local name=fold(page.Name)
  local decoration=name:find('footer',1,true)or name:find('limit',1,true)or name:find('background',1,true)or name=='header'
  if gui(page)and not decoration and not seen[page]then
   local items=page:FindFirstChild('Contents',true)
   local grid=self:CollectionGrid(items or page)
   local view=items and(items:IsA('ScrollingFrame')and items or items:FindFirstChildWhichIsA('ScrollingFrame',true)or(gui(items)and items))
   if name=='settings'or name=='options'or name=='configuration'or name:find('color',1,true)then grid=nil end
   local record={Node=page,List=view or page,Items=items or page,Grid=grid,Kind=grid and'grid'or'panel'}
   self.Pages[#self.Pages+1]=record
   self:Watch(page,'Visible')
  end
 end
 -- Contents and its layout can stream after the page root was discovered.
 for _,record in ipairs(self.Pages)do
  local items=record.Node:FindFirstChild('Contents',true)
  local grid=self:CollectionGrid(items or record.Node)
  local name=fold(record.Node.Name)
  if name=='settings'or name=='options'or name=='configuration'or name:find('color',1,true)then grid=nil end
  record.Items=items or record.Node;record.Grid=grid;record.Kind=grid and'grid'or'panel'
  record.List=items and(items:IsA('ScrollingFrame')and items or items:FindFirstChildWhichIsA('ScrollingFrame',true)or(gui(items)and items))or record.Node
  if grid then
   local ancestor=grid.Parent
   while ancestor and ancestor~=record.Node do
    if ancestor:IsA('ScrollingFrame')then record.List=ancestor;break end
    ancestor=ancestor.Parent
   end
  end
 end
end
local function textValue(v)
 local result=tostring(v.Text or'')
 for _,key in ipairs({'ContentText','LocalizedText'})do local ok,value=pcall(function()return v[key]end);if ok and type(value)=='string'and value~=''then result..=' '..value end end
 return fold(result)
end
local headerWords={thetoyshop=true,toyshop=true,yourtoys=true,puttoysaway=true,toycleanup=true,settings=true,
 ["вашиигрушки"]=true,["магазинигрушек"]=true,["магазин"]=true,["настройки"]=true}
local function nativeHeading(node)
 for _,property in ipairs({'Text','ContentText','LocalizedText'})do
  local ok,value=pcall(function()return node[property]end)
  if ok and type(value)=='string'then
   value=fold(value):gsub('<[^>]*>',''):gsub('%s+',''):gsub('[%p]','')
   if headerWords[value]then return true end
  end
 end
 return false
end
local function footer(v,stop)
 local n=v
 while n and n~=stop do
  local name=fold(n.Name):gsub('[%s_%-]','')
  if name:find('toylimit',1,true)or name:find('toyslimit',1,true)or name:find('toycount',1,true)then return n end
  n=n.Parent
 end
 return nil
end
function Shop:HideText(node,scope)
 self:Write(node,'TextTransparency',1,scope,true);self:Write(node,'TextStrokeTransparency',1,scope,true)
end
function Shop:ResetArtwork()
 for _,map in ipairs({self.IconCopies or{},self.TextCopies or{},self.CardCopies or{}})do for _,v in pairs(map)do if v.Parent then self:DestroyArtwork(v)end end end
 self.IconCopies={};self.IconMeta={};self.TextCopies={};self.CardCopies={}
end
function Shop:Controls(record)
 if record.Controls and record.ControlsVersion==(self.TreeVersion or 0)then return record.Controls end
 local title,categories,favorite,limit,sidebar
 local buttons={}
 for _,node in ipairs(self:Descendants(self.Menu))do
  if gui(node)and not(record.Grid and under(node,record.Items))then
   local inPage=under(node,record.Node)
   local shared=not under(node,self.Contents)
   local name=node.Name:lower()
   if inPage or shared then
    if node:IsA('TextLabel')or node:IsA('TextButton')then
     local text=fold(node.Text)
     if text:find('your toys',1,true)or text:find('ваши игруш',1,true)or text=='shop'or text:find('магазин',1,true)or name=='title'or name=='heading'or name=='header'or name:find('pagetitle',1,true)then title=title or node
     elseif text:find('лимит игруш',1,true)or text:find('toy limit',1,true)or name:find('toylimit',1,true)then limit=limit or node end
    end
    if(node:IsA('Frame')or node:IsA('ScrollingFrame')or node:IsA('Folder'))and(name:find('categor',1,true)or name=='filters')then categories=categories or node end
    if node:IsA('ImageButton')or node:IsA('TextButton')then
     if favoriteName(node)then favorite=favorite or node else
      for _,child in ipairs(self:Descendants(node))do if favoriteName(child)then favorite=favorite or node;break end end
     end
    end
   end
  end
 end
 -- Locate category buttons from a named group, or from the horizontal strip.
 if categories then for _,v in ipairs(self:Descendants(categories))do if v:IsA('ImageButton')or v:IsA('TextButton')then buttons[#buttons+1]=v end end end
 if #buttons==0 then
  local groups={}
  for _,v in ipairs(self:Descendants(record.Node))do if not under(v,record.Items)and(v:IsA('ImageButton')or v:IsA('TextButton'))and v~=favorite then
   local p=v.Parent;groups[p]=groups[p]or{};groups[p][#groups[p]+1]=v
  end end
  for p,group in pairs(groups)do if #group>=4 and #group<=12 then categories=p;buttons=group;break end end
 end
 -- Sidebar may be a Folder, a Frame, or a set of direct native buttons.
 local nav=find(self.Menu,{'Tabs','TabButtons','Navigation','Sidebar'})
 if nav then for _,v in ipairs(self:Descendants(nav))do if v:IsA('ImageButton')or v:IsA('TextButton')then sidebar=sidebar or{};sidebar[#sidebar+1]=v end end end
 if not sidebar then
  local groups={}
  for _,v in ipairs(self:Descendants(self.Menu))do if not under(v,self.Contents)and(v:IsA('ImageButton')or v:IsA('TextButton'))then
   local p=v.Parent;groups[p]=groups[p]or{};groups[p][#groups[p]+1]=v
  end end
  for _,group in pairs(groups)do if #group>=4 and #group<=8 then sidebar=group;break end end
 end
 order(buttons,'row');order(sidebar or{},'column')
 -- Some native versions keep Chat/Settings beside Tabs rather than inside it.
 -- Keep those real controls in the strip instead of inventing substitute tabs.
 local included={};for _,v in ipairs(sidebar or{})do included[v]=true end
 for _,v in ipairs(self:Descendants(self.Menu))do if button(v)and not under(v,self.Contents)and not included[v]then
  local name=v.Name:lower()
  if name=='chat'or name=='chatbutton'or name=='settingsbutton'then sidebar=sidebar or{};sidebar[#sidebar+1]=v;included[v]=true end
 end end
 record.Controls={Title=title,Categories=categories,CategoryButtons=buttons,Favorite=favorite,Limit=limit,Sidebar=sidebar or{},Nav=nav}
 record.ControlsVersion=self.TreeVersion or 0;return record.Controls
end
function Shop:Icon(node,r,scope)
 local visual=node
 if not node:IsA('ImageButton')or node.Image==nil or node.Image==''then visual=node:FindFirstChildWhichIsA('ImageLabel',true)or node end
 if not(visual:IsA('ImageButton')or visual:IsA('ImageLabel'))or not visual.Image or visual.Image==''then return end
 self:Surface()
 local image=self.IconCopies[visual]
 if not image then image=Instance.new('ImageLabel');image.Name='NativeShopIcon';image.BackgroundTransparency=1;image.BorderSizePixel=0;image.Active=false;image.Parent=self.Layer;self.IconCopies[visual]=image end
 self:Round(image,math.min(r.W,r.H)*.3,scope)
 image.Position=UDim2.fromOffset(r.X,r.Y);image.Size=UDim2.fromOffset(r.W,r.H);image.Image=visual.Image
 image.ImageRectOffset=visual.ImageRectOffset;image.ImageRectSize=visual.ImageRectSize;image.ScaleType=Enum.ScaleType.Fit
 pcall(function()image.ResampleMode=Enum.ResamplerMode.Default end)
 image.ImageColor3=self:ThemeColor('FontColor',C(231,234,238));self:RegisterTheme(image,{ImageColor3='FontColor'});image.ImageTransparency=0;image.ZIndex=self.Menu.ZIndex-1;image.Visible=true
 self.IconMeta[visual]={Button=node,Desired=r}
 self:Write(visual,'ImageTransparency',1,scope,true);self:Watch(visual,'Image');self:Watch(visual,'ImageRectOffset');self:Watch(visual,'ImageRectSize')
end
function Shop:RefreshIcons()
 if not self.Active or not live(self.Layer)or not live(self.Menu)then return end
 local origin=self.Menu.AbsolutePosition
 for visual,image in pairs(self.IconCopies)do
  local meta=self.IconMeta[visual]
  image.Visible=meta~=nil and not meta.Hidden and live(visual)~=nil and visible(visual,self.Menu)
  if image.Visible then
   local button=meta.Button;local scale=self.MenuScale or 1;local pos=(button.AbsolutePosition-origin)/scale;local size=button.AbsoluteSize/scale;local desired=meta.Desired
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
 label.FontFace=Font.fromEnum(Enum.Font.GothamBold);label.TextColor3=self:ThemeColor('FontColor',C(231,234,238));self:RegisterTheme(label,{TextColor3='FontColor'})
 label.TextXAlignment=right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left;label.ZIndex=self.Menu.ZIndex-1;label.Visible=true
end
function Shop:Button(node,r,scope)
 self:Rect(node,r,scope);self:Write(node,'BackgroundTransparency',1,scope,true);self:Write(node,'BorderSizePixel',0,scope)
 self:Round(node,math.min(r.W,r.H)*.32,scope)
 if node:IsA('ImageButton')then self:Write(node,'ScaleType',Enum.ScaleType.Fit,scope)end
end
function Shop:Group(nodes,container,rect,direction,scope,page)
 if #nodes==0 then return end
 local root=gui(container)and container or parentGui(nodes[1])
 local dedicated=root and root~=self.Menu and root~=page and not under(self.Contents,root)
 if dedicated then
  self:Normalize(root,scope);self:Rect(root,rect,scope);self:Write(root,'BackgroundTransparency',1,scope,true);self:Write(root,'ClipsDescendants',false,scope)
  self:Round(root,rect.Radius or 8*self.Plan.Scale,scope)
  if root:IsA('ImageLabel')or root:IsA('ImageButton')then self:Write(root,'ImageTransparency',1,scope,true)end
  if root:IsA('ScrollingFrame')then self:Write(root,'ScrollBarThickness',0,scope);self:Write(root,'CanvasSize',UDim2.fromOffset(rect.W,rect.H),scope,true);self:Write(root,'AutomaticCanvasSize',Enum.AutomaticSize.None,scope,true)end
  local layout=root:FindFirstChildOfClass('UIListLayout')
  if layout then self:Write(layout,'FillDirection',direction=='row'and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,scope,true);self:Write(layout,'Padding',UDim.new(0,0),scope,true);self:Write(layout,'SortOrder',Enum.SortOrder.LayoutOrder,scope,true);self:Write(layout,'HorizontalAlignment',Enum.HorizontalAlignment.Left,scope,true);self:Write(layout,'VerticalAlignment',Enum.VerticalAlignment.Top,scope,true)end
  local padding=root:FindFirstChildOfClass('UIPadding')
  if padding then for _,key in ipairs({'PaddingTop','PaddingBottom','PaddingLeft','PaddingRight'})do self:Write(padding,key,UDim.new(0,0),scope,true)end end
 end
 for i,node in ipairs(nodes)do
  self:Write(node,'LayoutOrder',i,scope,true);self:Write(node,'Visible',true,scope,true)
  local w=direction=='row'and rect.W/#nodes or rect.W;local h=direction=='row'and rect.H or rect.H/#nodes
  local x=direction=='row'and(i-1)*w or 0;local y=direction=='row'and 0 or(i-1)*h
  local global={X=rect.X+x,Y=rect.Y+y,W=w,H=h}
  if dedicated and under(node,root)then
   local slot=node
   while slot.Parent and slot.Parent~=root do slot=slot.Parent end
   if gui(slot)then self:Rect(slot,{X=x,Y=y,W=w,H=h},scope);self:Write(slot,'BackgroundTransparency',1,scope,true)end
   if slot~=node then self:Button(node,{X=0,Y=0,W=w,H=h},scope)else self:Button(node,{X=x,Y=y,W=w,H=h},scope)end
  else self:Normalize(node,scope);self:Button(node,global,scope)end
  self:Icon(node,global,scope)
 end
end
function Shop:Grid(record)
 self.GridPasses=(self.GridPasses or 0)+1
 self.CellStyles=self.CellStyles or setmetatable({},{__mode="k"})
 local plan=self.Plan;local list=record.List
 -- Contents is not necessarily the actual collection: the native inventory
 -- also places its grid under a ScrollingFrame and an inner canvas Frame.
 local grid=self:CollectionGrid(record.Items)
 if grid then
  local ancestor=grid.Parent
  while ancestor and ancestor~=record.Node do if ancestor:IsA('ScrollingFrame')then list=ancestor;break end;ancestor=ancestor.Parent end
  record.Grid=grid;record.List=list
 end
 local holder=grid and grid.Parent or list
 if not gui(holder)then return end
 local cells={};for _,node in ipairs(children(holder))do if gui(node)then cells[#cells+1]=node end end
 local count=0;for _,cell in ipairs(cells)do if cell.Visible then count+=1 end end
 local paid=record.Node.Name:lower()~='toys'
 local rowHeight=plan.Cell+(paid and 14*plan.Scale or 0)
 local height=math.max(plan.Grid.H,math.ceil(count/plan.Columns)*(rowHeight+plan.Gap)-plan.Gap)
 -- Every coordinate space between viewport and grid must have the same usable
 -- width. Changing CellSize alone left the old narrow inner canvas in place.
 local node=holder
 while node and under(node,list)do
  if gui(node)then
   if node==list then self:Rect(node,plan.Grid)
   else self:Rect(node,{X=0,Y=0,W=plan.Grid.W,H=height})end
   self:Write(node,'BackgroundTransparency',1,nil,true);self:Write(node,'BorderSizePixel',0)
   local padding=node:FindFirstChildOfClass('UIPadding')
   if padding then for _,key in ipairs({'PaddingTop','PaddingBottom','PaddingLeft','PaddingRight'})do self:Write(padding,key,UDim.new(0,0),nil,true)end end
   for _,child in ipairs(children(node))do if child:IsA('UIScale')then self:Write(child,'Scale',1,nil,true)end end
  end
  if node==list then break end;node=node.Parent
 end
 if list:IsA('ScrollingFrame')then
  self:Write(list,'CanvasSize',UDim2.fromOffset(0,height),nil,true)
 end
 if grid then
  self:Write(grid,'CellSize',UDim2.fromOffset(plan.Cell,rowHeight),nil,true)
  self:Write(grid,'CellPadding',UDim2.fromOffset(plan.Gap,plan.Gap),nil,true)
  self:Write(grid,'FillDirection',Enum.FillDirection.Horizontal,nil,true)
  self:Write(grid,'FillDirectionMaxCells',plan.Columns,nil,true)
  self:Write(grid,'HorizontalAlignment',Enum.HorizontalAlignment.Left,nil,true)
  self:Write(grid,'VerticalAlignment',Enum.VerticalAlignment.Top,nil,true)
  self:Write(grid,'StartCorner',Enum.StartCorner.TopLeft,nil,true)
 end
 local function favorite(v)
  return favoriteName(v)
 end
 self.ItemStyling=true
 for _,cell in ipairs(cells)do
  local saved=self.CellStyles[cell]
  if saved and saved.Width==plan.Cell and saved.Height==rowHeight then continue end
  self.CellStyles[cell]={Width=plan.Cell,Height=rowHeight}
  self.CellPasses=(self.CellPasses or 0)+1
  self.StylingCell=cell
  self:Rect(cell,{X=0,Y=0,W=plan.Cell,H=rowHeight})
  self:Write(cell,'ClipsDescendants',true,nil,true);self:Watch(cell,'Visible')
  local texts={}
  for _,v in ipairs(self:Descendants(cell))do if(v:IsA('TextLabel')or v:IsA('TextButton'))and not favoriteName(v)and v.Text~=''then texts[#texts+1]=v end end
  if cell:IsA('TextButton')and cell.Text~=''then self:Text(cell,7*plan.Scale);self:Write(cell,'TextYAlignment',Enum.TextYAlignment.Bottom,nil,true)end
  for i,v in ipairs(texts)do
   self:Text(v,math.max(7,7*plan.Scale));self:Write(v,'ClipsDescendants',true,nil,true)
   self:Rect(v,{X=0,Y=paid and plan.Cell+(i-1)*7*plan.Scale or math.max(0,plan.Cell-8*plan.Scale),W=plan.Cell,H=7*plan.Scale})
   self:Write(v,'TextXAlignment',Enum.TextXAlignment.Center,nil,true);self:Write(v,'TextStrokeTransparency',1,nil,true)
   self:Write(v,'ZIndex',math.max(cell.ZIndex or 1,3)+2,nil,true)
  end
  -- A fixed-size image/ViewportFrame inside a correctly sized grid cell still
  -- renders the old 100-pixel toy. Fit the visual subtree, not just CellSize.
  for _,v in ipairs(self:Descendants(cell))do
   if v:IsA('UIScale')then self:Write(v,'Scale',1,nil,true)
   elseif gui(v)then
    if favorite(v)and(button(v)or v:IsA('ImageLabel')or v:IsA('TextLabel'))then
     self:Write(v,'Visible',false,nil,false)
    elseif v:IsA('ImageLabel')or v:IsA('ImageButton')or v:IsA('ViewportFrame')or v:IsA('Frame')then
     local currency=false;local ancestor=v
     while ancestor and ancestor~=cell do
      local name=fold(ancestor.Name)
      if name:find('coin',1,true)or name:find('price',1,true)or name:find('cost',1,true)or name:find('currency',1,true)or name:find('robux',1,true)then currency=true;break end
      ancestor=ancestor.Parent
     end
     if paid and currency and(v:IsA('ImageLabel')or v:IsA('ImageButton'))then
      self:Rect(v,{X=plan.Cell-8*plan.Scale,Y=plan.Cell+2*plan.Scale,W=7*plan.Scale,H=7*plan.Scale})
     else self:Rect(v,{X=0,Y=0,W=plan.Cell,H=v:IsA('Frame')and rowHeight or plan.Cell})end
    end
   end
  end
 end
 self.StylingCell=nil;self.ItemStyling=false
end
function Shop:PanelContent(record)
 local plan=self.Plan;local page=record.Node;local size=record.NativeSize
 self:Normalize(page,'page')
 local bounds=record.ContentBounds or{X=0,Y=0,W=size.X,H=size.Y}
 local fit=math.min(plan.Body.W/math.max(bounds.W,1),plan.Body.H/math.max(bounds.H,1))
 self:Rect(page,{X=plan.Body.X+(plan.Body.W-bounds.W*fit)*.5-bounds.X*fit,Y=plan.Body.Y+(plan.Body.H-bounds.H*fit)*.5-bounds.Y*fit,W=size.X,H=size.Y},'page')
 self:Write(page,'ClipsDescendants',false,'page',true);self:Write(page,'BackgroundTransparency',1,'page',true)
 local scale=page:FindFirstChildOfClass('UIScale')
 if not scale then scale=Instance.new('UIScale');scale.Name='AstralPanelScale';scale.Parent=page;self.Created[scale]='page' end
 self:Write(scale,'Scale',fit,'page',true)
 for _,v in ipairs(self:Descendants(page))do
  if gui(v)then
   if v:IsA('Frame')or v:IsA('ScrollingFrame')then self:Write(v,'BackgroundTransparency',1,'page',true)
   elseif v:IsA('TextBox')or button(v)then
    if v:IsA('TextBox')then self:Write(v,'BackgroundColor3',self:ThemeColor('MainColor',C(37,39,42)),'page')end;self:Write(v,'BackgroundTransparency',(self.Context.Library.Scheme or{}).RowTransparency or .92,'page')
    self:Round(v,5,'page')
   end
   if v:IsA('TextLabel')or v:IsA('TextButton')or v:IsA('TextBox')then
    local t=tostring(v.Text or'')
    if not t:match('^[RGBHSV]$')then self:Write(v,'TextColor3',self:ThemeColor('FontColor',C(231,234,238)),'page')end
   end
  end
 end
end
function Shop:Footer(record)
 local count='';local root=self.GuiRoot or self.Menu.Parent
 local nodes=self:Descendants(root);local groups={}
 local function nativeText(v)
  return v.Parent~=nil and under(v,root)and not under(v,self.Layer)and not(self.Quick and self.Quick:Owns(v))and(v:IsA('TextLabel')or v:IsA('TextButton'))
 end
 local function caption(v)
  local value=textValue(v)
  return value:find('лимит игруш',1,true)or value:find('toy limit',1,true)or value:find('toys limit',1,true)
 end
 for _,v in ipairs(nodes)do if nativeText(v)and caption(v)then
  local parent=v.Parent
  if gui(parent)and parent~=self.Menu and parent~=record.Node and not under(record.Items,parent)then groups[parent]=true end
 end end
 for _,v in ipairs(nodes)do if nativeText(v)then
  local footerRoot=footer(v,root)
  local fraction=tostring(v.Text or''):match('^%s*%d+%s*/%s*%d+%s*$')~=nil
  local associated=false
  for group in pairs(groups)do if under(v,group)then associated=true;footerRoot=footerRoot or group;break end end
  local outsideItems=not under(v,record.Items)
  local visibleCounter=fraction and outsideItems and visible(v,root)and(record.Quick or record.Node.Name:lower()=='toys')
  local isFooter=footerRoot or caption(v)or associated or visibleCounter
  if isFooter then
   self.FooterNodes=self.FooterNodes or{};self.FooterNodes[v]=true
   if fraction then count=v.Text end
   self:HideText(v,'shared');self:Watch(v,'Text');self:Watch(v,'AutoLocalize');self:Watch(v,'ContentText')
   if footerRoot then for _,piece in ipairs(self:Descendants(footerRoot))do
    if piece:IsA('UIStroke')then self:Write(piece,'Transparency',1,'shared',true)end
    if gui(piece)then self:Write(piece,'BackgroundTransparency',1,'shared',true);if piece:IsA('ImageLabel')then self:Write(piece,'ImageTransparency',1,'shared',true)end end
   end end
   local p=v.Parent
   if gui(p)and p~=self.Menu and p~=record.Node then self:Write(p,'BackgroundTransparency',1,'shared',true);if p:IsA('ImageLabel')then self:Write(p,'ImageTransparency',1,'shared',true)end end
  end
 end end
 if count~=''then self.LastCount=count else count=self.LastCount or''end
 if self.ShowLimit then
  self:Label('ToyLimitLabel','Toy Limit',self.Plan.LimitText,math.max(7,6*self.Plan.Scale))
  self:Label('ToyLimitCount',count,{X=self.Plan.Limit.X+self.Plan.Limit.W-38*self.Plan.Scale,Y=self.Plan.Limit.Y+3*self.Plan.Scale,W=31*self.Plan.Scale,H=10*self.Plan.Scale},math.max(7,6*self.Plan.Scale),true)
  local panel=self.Panels.Limit.Node;panel.ClipsDescendants=true
  local label=self.TextCopies.ToyLimitLabel;label.Parent=panel;label.Position=UDim2.fromOffset(7*self.Plan.Scale,0);label.Size=UDim2.new(.6,0,1,0)
  local value=self.TextCopies.ToyLimitCount;value.Parent=panel;value.AnchorPoint=Vector2.new(1,.5);value.Position=UDim2.new(1,-7*self.Plan.Scale,.5,0);value.Size=UDim2.new(.38,-7*self.Plan.Scale,1,0)
 end
end
function Shop:Page(record)
 self.LayoutPasses=(self.LayoutPasses or 0)+1
 local plan=self.Plan;local list=record.List;self:Surface()
 for _,v in ipairs(self:Descendants(self.Menu))do if gui(v)and not under(v,self.Contents)then
  self:Write(v,'BackgroundTransparency',1,'shared',true);self:Write(v,'BorderSizePixel',0,'shared')
  if v:IsA('ImageLabel')then
   local p=v.Parent;local glyph=false;while p and p~=self.Menu do if button(p)then glyph=true;break end;p=p.Parent end
   if not glyph or fold(v.Name):find('background',1,true)then self:Write(v,'ImageTransparency',1,'shared',true)end
  end
 end end
 for _,image in pairs(self.IconCopies)do image.Visible=false end
 for _,label in pairs(self.TextCopies)do label.Visible=false end
 local styled=record.Styled and record.Styled.Width==plan.Width and record.Styled.Height==plan.Height
 if record.Grid and not styled then
 self:Normalize(list,'page');self:Rect(list,plan.Body)
 self:Write(list,'BackgroundTransparency',1,nil,true);self:Write(list,'BorderSizePixel',0);self:Write(list,'ClipsDescendants',true)
 if list:IsA('ScrollingFrame')then self:Write(list,'ScrollBarThickness',0);self:Write(list,'ScrollingDirection',Enum.ScrollingDirection.Y);self:Write(list,'AutomaticCanvasSize',Enum.AutomaticSize.Y)end
 -- Remove native panel fills throughout this page. Their old sibling header
 -- and footer backgrounds otherwise cover the smaller rounded skin.
 for _,v in ipairs(self:Descendants(self.Menu))do if gui(v)and(under(v,record.Node)or not under(v,self.Contents))then
  local scope=under(v,record.Node)and'page'or'shared'
  self:Write(v,'BackgroundTransparency',1,scope,true);self:Write(v,'BorderSizePixel',0,scope)
  local stroke=v:FindFirstChildOfClass('UIStroke');if stroke then self:Write(stroke,'Transparency',1,scope,true)end
  if under(v,record.Items)and(v:IsA('ImageLabel')or v:IsA('ImageButton'))then
   -- Keep the original image, atlas rectangle and render asset. Default
   -- filtering avoids carrying a native Pixelated mode into small thumbnails.
   self:Write(v,'ScaleType',Enum.ScaleType.Fit)
   pcall(function()self:Write(v,'ResampleMode',Enum.ResamplerMode.Default)end)
  elseif v:IsA('ImageLabel')then
   local ancestor=v.Parent;local glyph=false
   while ancestor and ancestor~=self.Menu do if button(ancestor)then glyph=true;break end;ancestor=ancestor.Parent end
   local name=v.Name:lower()
   if not glyph or name:find('background',1,true)or name:find('panel',1,true)then self:Write(v,'ImageTransparency',1,scope,true)end
  end
 end end
 self:Grid(record)
 elseif not record.Grid and not record.Quick and not styled then self:PanelContent(record)end
 record.Styled={Width=plan.Width,Height=plan.Height}
 local discoveredControls=self:Controls(record)
 local controls=table.clone(discoveredControls)
 -- Hide every original page title, including localized shadow copies.
 local nativeRoot=self.GuiRoot or self.Menu
 for _,node in ipairs(self:Descendants(nativeRoot))do
  if(node:IsA('TextLabel')or node:IsA('TextButton'))and not under(node,self.Layer)and not(self.Quick and self.Quick:Owns(node))then
   local name=fold(node.Name)
   local scoped=under(node,record.Node)or not under(node,self.Contents)
   if scoped and(nativeHeading(node)or(not(record.Grid and under(node,record.Items))and(name=='title'or name=='heading'or name=='header')))then self:HideText(node,'shared')end
  end
 end
 if controls.Title then
  self:HideText(controls.Title,'page');self:Write(controls.Title,'BackgroundTransparency',1,'shared',true)
 end
 local titles={toys='Your Toys',toyshop='Toy Shop',shop='Shop',settings='Settings',toydestroy='Toy Cleanup',astralquickspawnpage='Быстрый спавн'}
 self:Label('YourToysTitle',titles[record.Node.Name:lower()]or record.Node.Name,plan.TitleText,plan.TitleSize)
 self.HasCategories=record.Grid~=nil and #controls.CategoryButtons>0
 if not record.Grid then
  if controls.Categories and gui(controls.Categories)and not under(controls.Categories,record.Node)then self:Write(controls.Categories,'Visible',false,'shared',true)end
  for _,node in ipairs(controls.CategoryButtons)do if not under(node,record.Node)then self:Write(node,'Visible',false,'shared',true)end end
  if controls.Favorite and not under(controls.Favorite,record.Node)then self:Write(controls.Favorite,'Visible',false,'shared',true)end
  controls.CategoryButtons={};controls.Favorite=nil
 end

 local removedFavorite=controls.Favorite
 self.HasFavorite=false
 if removedFavorite then self:Write(removedFavorite,'Visible',false,'shared',true)end
 local categoryButtons={}
 for _,v in ipairs(controls.CategoryButtons)do
  if v~=removedFavorite and not favoriteName(v)then categoryButtons[#categoryButtons+1]=v end
 end
 controls.Favorite=nil
 local categoryScope=under(controls.Categories,record.Node)and'page'or'shared'
 self:Group(categoryButtons,controls.Categories,plan.Categories,'row',categoryScope,record.Node)
 if self.Quick then self.Quick:Mount(self.Menu,self.Contents);self.Quick:ConnectTabs(controls.Sidebar)end
 local side=plan.Sidebar
 if self.Quick then side={X=side.X,Y=side.Y,W=side.W,H=side.H*#controls.Sidebar/(#controls.Sidebar+1),Radius=side.Radius}end
 self:Group(controls.Sidebar,controls.Nav,side,'column','shared',record.Node)
 if self.Quick then self.Quick:LayoutClock(plan,#controls.Sidebar+1)end
 self.ShowLimit=record.Quick or(record.Grid~=nil and record.Node.Name:lower()=='toys')
 self:Footer(record)

 local top=self.Menu.AbsolutePosition;local width=self.Menu.AbsoluteSize.X
 for _,node in ipairs(self:Descendants(self.GuiRoot or self.Menu))do
  if gui(node)and not under(node,self.Layer)and not(self.Quick and self.Quick:Owns(node))then
   local name=fold(node.Name);local label=(node:IsA('TextButton')or node:IsA('TextLabel'))and fold(node.Text or'')or''
   local atTop=node.AbsolutePosition.Y<top.Y+plan.Body.Y*(self.MenuScale or 1)and node.AbsolutePosition.X>top.X+width*.7
   if name=='close'or name=='closebutton'or name=='exit'or(atTop and(name=='x'or label=='x'or label=='×'))then self:Write(node,'Visible',false,'shared',true)end
  end
 end

 if self.Quick then self.Quick:RefreshOwned(self.Pages);if record.Quick then self.Quick:Render(plan)end end
 self:Draw();self:RefreshIcons();self:StartIcons()
end
function Shop:Find()
 if self.Closed or not self.Enabled or self.Applying then return end
 self.Applying=true
 local ok,why=pcall(function()
  local guiRoot=self.Context.PlayerGui:FindFirstChild('MenuGui');local menu=guiRoot and guiRoot:FindFirstChild('Menu',true)
  local contents=menu and menu:FindFirstChild('TabContents')
  if not gui(menu)or not contents then if self.Menu then self:Detach()end;self.Status:SetText('Ожидание игрового меню.');return end
  if self.Menu~=menu or self.Contents~=contents then self:Bind(menu,contents)end
  self.GuiRoot=guiRoot
  if not menu.Visible then
   if self.Quick then self.Quick:CloseForMenu()end
   self.Active=false
   if self.IconConnection then self.IconConnection:Disconnect();self.IconConnection=nil end
   if self.Layer then self.Layer.Visible=false end
   self.Status:SetText('Открой игровое меню.');return
  end
  if self.StructureDirty or #self.Pages==0 then self:Discover();self.StructureDirty=false end
  local active
  if self.Quick and self.Quick.Open and menu.Visible then active=self.Quick.Record end
  if not active then for _,record in ipairs(self.Pages)do if live(record.Node)and visible(record.Node,self.Menu)then active=record;break end end end
  if active and active~=self.Current then
   self:Restore('shared');self:ResetArtwork();self.Current=active;self.Dirty=true
  end
  if not active then
   if self.Quick then self.Quick:CloseForMenu()end
   self.Active=false;if self.IconConnection then self.IconConnection:Disconnect();self.IconConnection=nil end
   if self.Layer then self.Layer.Visible=false end
   -- A closed game menu is not a style-disable request. Keep the native
   -- page cache and restore its original properties only on detach/unload.
   self.Status:SetText('Открой игровое меню.');return
  end
  self.Active=true
  self.MenuScale=1
  local bounds=menu.AbsoluteSize
  if not active.NativeSize then
   local scale=rootScale(active.Node,guiRoot)
   local size=active.Node.AbsoluteSize/scale
   active.NativeSize=Vector2.new(math.max(size.X,1),math.max(size.Y,1))
  end
  if active.Node.Name:lower()=='settings'and not active.ContentBounds then
   local lo=Vector2.new(math.huge,math.huge);local hi=Vector2.new(-math.huge,-math.huge)
   local origin=active.Node.AbsolutePosition;local scale=rootScale(active.Node,guiRoot)
   for _,node in ipairs(self:Descendants(active.Node))do
    local candidate=button(node)or node:IsA('TextBox')
    if node:IsA('UIGradient')and gui(node.Parent)then node=node.Parent;candidate=true end
    if candidate and visible(node,active.Node)and not nativeHeading(node)then
     local pos=(node.AbsolutePosition-origin)/scale;local box=node.AbsoluteSize/scale
     if box.X>0 and box.Y>0 then lo=Vector2.new(math.min(lo.X,pos.X),math.min(lo.Y,pos.Y));hi=Vector2.new(math.max(hi.X,pos.X+box.X),math.max(hi.Y,pos.Y+box.Y))end
    end
   end
   if lo.X<hi.X and lo.Y<hi.Y then active.ContentBounds={X=lo.X-8,Y=lo.Y-8,W=hi.X-lo.X+16,H=hi.Y-lo.Y+16}end
  end
  local camera=self.Context.Workspace and self.Context.Workspace.CurrentCamera
  local viewport=camera and camera.ViewportSize or Vector2.new(900,585)
  local plan=Layout.Build(viewport.X,viewport.Y)
  if not self.Dirty and self.Plan and self.Plan.Width==plan.Width and self.Plan.Height==plan.Height and self.LastMenuScale==rootScale(menu,guiRoot)then
   self.MenuScale=self.LastMenuScale
   self:Footer(active);self:Draw();self:StartIcons();return
  end
  self.Plan=plan
  for _,scale in ipairs(children(menu))do if scale:IsA('UIScale')then self:Write(scale,'Scale',1,'shared',true)end end
  self.MenuScale=rootScale(menu,guiRoot)
  self:Write(menu,'Size',UDim2.fromOffset(plan.Width,plan.Height),'shared',true)
  self:Write(menu,'Position',UDim2.fromScale(.5,.5),'shared',true);self:Write(menu,'AnchorPoint',Vector2.new(.5,.5),'shared',true)
  -- Preserve the game's exact window bounds, anchors, position and UIScale.
  self:Write(menu,'BackgroundTransparency',1,'shared',true);self:Write(menu,'BorderSizePixel',0,'shared')
  local stroke=menu:FindFirstChildOfClass('UIStroke');if stroke then self:Write(stroke,'Transparency',1,'shared')end
  self:Page(active);self.LastMenuScale=self.MenuScale;self.Dirty=false;self.Status:SetText(active.Node.Name..': единое оформление включено.')
 end)
 self.StylingCell=nil;self.ItemStyling=false;self.Applying=false
 if not ok then self.LastError=tostring(why);self.Status:SetText('Магазин: '..self.LastError)end
end
function Shop:Detach()
 if self.Quick then self.Quick:Detach()end
 local applying=self.Applying;self.Applying=true
 if self.IconConnection then self.IconConnection:Disconnect();self.IconConnection=nil end
 for _,c in ipairs(self.Bound)do c:Disconnect()end;self.Bound={}
 for _,map in pairs(self.Watches)do for _,c in pairs(map)do c:Disconnect()end end;self.Watches={}
 for _,connection in pairs(self.CellWatches or{})do connection:Disconnect()end
 self.CellWatches={};self.CellOwners=nil;self.CellMaintained=nil;self.PendingRepairs={}
 self:Restore();for v in pairs(self.Created)do if v.Parent then v:Destroy()end end;self.Created={};if self.Layer then self:DestroyArtwork(self.Layer);self.Layer=nil end
 self.DescCache=nil;self.CellStyles=nil;self.Pages={};self.Current=nil;self.GuiRoot=nil;self.Menu=nil;self.Contents=nil;self.Active=false;self.Applying=applying
end
function Shop:SetEnabled(value)
 if self.Closed then return end;self.Enabled=value==true
 if self.Enabled then if self.Status then self:Find()end else self:Detach();if self.Status then self.Status:SetText('Оригинальный магазин.')end end
end
function Shop:Sync()local t=self.Context.Library.Toggles.AstralGUIShopStyle;self:SetEnabled(t and t.Value)end
function Shop:Dispose()
 if self.Closed then return end;self.Closed=true;self.Enabled=false;self:Detach();if self.Quick then self.Quick:Dispose()end;for _,c in ipairs(self.Connections)do c:Disconnect()end
end
return Shop
