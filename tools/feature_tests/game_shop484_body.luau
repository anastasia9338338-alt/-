local originalIsA=Node.IsA
function Node:IsA(class)
 if class=='GuiObject'and(self.ClassName=='UIPadding'or self.ClassName=='UISizeConstraint'or self.ClassName=='UIAspectRatioConstraint')then return false end
 if class=='GuiObject'and table.find({'Model','WorldModel','Part','MeshPart','Camera','Attachment','Motor6D','Weld'},self.ClassName)then return false end
 if class=='BasePart'and(self.ClassName=='Part'or self.ClassName=='MeshPart')then return true end
 if class=='JointInstance'and(self.ClassName=='Motor6D'or self.ClassName=='Weld')then return true end
 return originalIsA(self,class)
end
-- Native property/hierarchy signals matter for post-layout streaming. The
-- generic UI fixture omits these events; use faithful shop-local delivery.
local originalNewindex=mt.__newindex
mt.__newindex=function(node,key,value)
 local old=node[key]
 if key=='Parent'and old~=value and old then
  local removed={node};for _,descendant in ipairs(node:GetDescendants())do removed[#removed+1]=descendant end
  local ancestor=old
  while ancestor do for _,descendant in ipairs(removed)do ancestor.DescendantRemoving:Fire(descendant)end;ancestor=ancestor.Parent end
  old.ChildRemoved:Fire(node)
 end
 originalNewindex(node,key,value)
 if old~=value then
  if key=='Parent'and value then
   value.ChildAdded:Fire(node)
   local added={node};for _,descendant in ipairs(node:GetDescendants())do added[#added+1]=descendant end
   local ancestor=value
   while ancestor do for _,descendant in ipairs(added)do ancestor.DescendantAdded:Fire(descendant)end;ancestor=ancestor.Parent end
  end
  node.Changed:Fire(key)
 end
end
-- Engine constraint semantics: ScaleWithParentSize has the parent's maximum
-- bounds; FitWithinMaxSize uses the requested own bounds (Creator Hub AspectType).
local originalIndex=mt.__index
mt.__index=function(node,key)
 local value=originalIndex(node,key)
 if key=='AbsoluteSize'and node:IsA('GuiObject')then
  local aspect=node:FindFirstChildOfClass('UIAspectRatioConstraint')
  if aspect then
   local box=value
   if aspect.AspectType==Enum.AspectType.ScaleWithParentSize and node.Parent then box=node.Parent.AbsoluteSize end
   local ratio=aspect.AspectRatio or 1
   local width=math.min(box.X,box.Y*ratio);value=Vector2.new(width,width/ratio)
  end
  for _,limit in ipairs(node:GetChildren())do if limit:IsA('UISizeConstraint')and limit.MinSize then value=Vector2.new(math.max(value.X,limit.MinSize.X),math.max(value.Y,limit.MinSize.Y))end end
 end
 return value
end
local function add(parent,class,name)local n=Instance.new(class,parent);n.Name=name;return n end
local playerGui=Instance.new('Folder');playerGui.Name='PlayerGui'
local gui=add(playerGui,'ScreenGui','MenuGui')
local menu=add(gui,'Frame','Menu');menu.Size=UDim2.fromOffset(900,650);menu.Position=UDim2.fromScale(.5,.5);menu.AnchorPoint=Vector2.new(.5,.5);menu.ZIndex=3
local originalMenuSize,originalPosition,originalAnchor=menu.Size,menu.Position,menu.AnchorPoint
local nativeScale=add(menu,'UIScale','NativeScale');nativeScale.Scale=1
local pages=Instance.new('Folder',menu);pages.Name='TabContents';if pages:IsA('GuiObject')then pages.Size=UDim2.fromScale(1,1)end
local toys=add(pages,'Frame','Toys');toys.Visible=false;toys.Size=UDim2.fromScale(1,1)
local list=add(toys,'ScrollingFrame','Contents');local grid=add(list,'UIGridLayout','Grid');grid.CellSize=UDim2.fromOffset(100,100)
local toy=add(list,'ImageButton','Chair');toy.Image='rbxassetid://star';toy.ImageTransparency=1;toy.ImageRectOffset=Vector2.new(20,30)
local art=add(toy,'ImageLabel','Preview');art.Image='rbxassetid://chair'
local toyScale=add(toy,'UIScale','NativeToyScale');toyScale.Scale=1.3
local nativeAspect=add(toy,'UIAspectRatioConstraint','Aspect');nativeAspect.AspectType=Enum.AspectType.ScaleWithParentSize;nativeAspect.DominantAxis=Enum.DominantAxis.Height;nativeAspect.AspectRatio=1
local minA=add(toy,'UISizeConstraint','MinA');minA.MinSize=Vector2.new(80,80)
local minB=add(toy,'UISizeConstraint','MinB');minB.MinSize=Vector2.new(90,90)
local toyStar=add(toy,'ImageLabel','Star');toyStar.Image='rbxassetid://star';toyStar.Visible=false
local title=add(toys,'TextLabel','Title');title.Text='Ваши игрушки';title.TextScaled=true;title.TextStrokeTransparency=0
local cats=add(toys,'Frame','Categories');local category={};for i=1,6 do category[i]=add(cats,'ImageButton','Category'..i);category[i].Image='rbxassetid://'..i end
local nav=add(menu,'Frame','Tabs');local navButtons={};for i=1,6 do navButtons[i]=add(nav,'ImageButton','Tab'..i);navButtons[i].Image='rbxassetid://nav'..i end
local chat=add(menu,'ImageButton','ChatButton');chat.Image='rbxassetid://chat'
local globalStar=add(menu,'ImageButton','Favorites');globalStar.Image='rbxassetid://favorite'
local footer=add(gui,'Frame','BottomBar');local caption=add(footer,'TextLabel','Caption');caption.Text='Limit';caption.LocalizedText='Лимит игрушек';caption.TextStrokeTransparency=0;caption.AutoLocalize=true
local count=add(footer,'TextLabel','Count');count.Text='5/100';local nativeBar=add(footer,'Frame','Progress');local footerStroke=add(nativeBar,'UIStroke','Border');footerStroke.Transparency=0
local shop=add(pages,'Frame','ToyShop');shop.Visible=false;shop.Size=UDim2.fromScale(1,1)
local shopTitle=add(shop,'TextLabel','Title');shopTitle.Text='Магазин игрушек';shopTitle.TextScaled=true;shopTitle.TextStrokeTransparency=0
local shopItems=add(shop,'Frame','Contents');shopItems.Size=UDim2.fromScale(1,1)
local decoyScroll=add(shopItems,'ScrollingFrame','CoinDetails');decoyScroll.Size=UDim2.fromScale(.5,1)
add(decoyScroll,'UIGridLayout','CostGrid');local coinDummy=add(decoyScroll,'ImageLabel','Coin');coinDummy.Image='rbxassetid://coin'
local shopList=add(shopItems,'ScrollingFrame','Products');shopList.Size=UDim2.fromScale(.5,1);local shopGrid=add(shopList,'UIGridLayout','Cards');shopGrid.CellSize=UDim2.fromOffset(100,100)
local card=add(shopList,'ImageButton','Product');card.Image='rbxassetid://product';local price=add(card,'TextLabel','Price');price.Text='5000';price.TextSize=90;price.TextScaled=true
local name=add(card,'TextLabel','Name');name.Text='Toy';name.TextScaled=true;name.TextSize=70
local priceIcon=add(card,'ImageLabel','CoinCost');priceIcon.Image='rbxassetid://coin';priceIcon.Size=UDim2.fromOffset(100,100)
local originalPriceIconSize=priceIcon.Size
local englishTitle=add(shop,'TextLabel','CaptionCopy');englishTitle.Text='The Toy Shop';englishTitle.TextStrokeTransparency=0
local close=add(menu,'TextButton','Close');close.Text='X';close.Visible=true
local settings=add(pages,'Frame','Settings');settings.Visible=false;settings.Size=UDim2.fromScale(1,1)
local settingsTitle=add(settings,'TextLabel','Title');settingsTitle.Text='Настройки';settingsTitle.TextScaled=true
local picker=add(settings,'Frame','ColorPicker');picker.Size=UDim2.fromOffset(500,260);picker.Position=UDim2.fromOffset(150,90)
local hue=add(picker,'TextBox','Hue');hue.Text='160';hue.Position=UDim2.fromOffset(300,40);hue.Size=UDim2.fromOffset(80,40);hue.TextSize=32
local gradient=add(picker,'UIGradient','HueGradient');gradient.Color=ColorSequence.new(Color3.new(1,0,0),Color3.new(0,1,0))
local originalGradient=gradient.Color
local swatch=add(picker,'TextButton','ColorSwatch');swatch.BackgroundColor3=Color3.new(1,0,0);local originalSwatch=swatch.BackgroundColor3
local settingsFraction=add(picker,'TextLabel','Fraction');settingsFraction.Text='5/100';settingsFraction.TextTransparency=0
local presetGrid=add(picker,'UIGridLayout','ColorPresets');presetGrid.CellSize=UDim2.fromOffset(40,40)
local presetCellSize=presetGrid.CellSize
local destroy=add(pages,'Frame','ToyDestroy');destroy.Visible=false;destroy.Size=UDim2.fromScale(1,1)
local cleanupCaption=add(destroy,'TextLabel','CaptionCopy');cleanupCaption.Text='Put Toys Away';cleanupCaption.TextStrokeTransparency=0
local destroyButton=add(destroy,'TextButton','DestroySelected');destroyButton.Text='Delete';destroyButton.Position=UDim2.fromOffset(100,100);destroyButton.Size=UDim2.fromOffset(180,50)
local currency=add(pages,'Frame','Coins');currency.Visible=false;currency.Size=UDim2.fromScale(1,1)
local currencyFooter=add(currency,'Frame','Footer');local footerAction=add(currencyFooter,'TextButton','CurrencyAction');footerAction.Text='Purchase';footerAction.TextTransparency=0
local buy=add(currency,'TextButton','BuyCoins');buy.Text='Buy Coins';buy.Position=UDim2.fromOffset(200,200);buy.Size=UDim2.fromOffset(150,70)
local library={Toggles={},ScreenGui=Instance.new('ScreenGui'),Registry={},Scheme={WhiteColor=Color3.new(1,1,1),BodyTopColor=Color3.fromRGB(24,26,29),BodyBottomColor=Color3.fromRGB(21,23,26),MainColor=Color3.fromRGB(37,39,42),FontColor=Color3.fromRGB(231,234,238),GlassTransparency=.55,RowTransparency=.92}};local box={}
function library:AddToRegistry(node,properties)self.Registry[node]=properties end
function library:RemoveFromRegistry(node)self.Registry[node]=nil end
function library:UpdateColorsUsingRegistry()for node,properties in pairs(self.Registry)do for key,value in pairs(properties)do node[key]=type(value)=='function'and value()or self.Scheme[value]end end end
function box:AddToggle(id,info)local t={Value=info.Default};function t:SetValue(v)self.Value=v;info.Callback(v)end;library.Toggles[id]=t;return t end
function box:AddLabel(text)return{SetText=function(self,v)self.Text=v end,Text=text}end
local input={InputBegan=signal(),Held={}};function input:GetFocusedTextBox()return self.Focused end;function input:IsKeyDown(key)return self.Held[key.Name]==true end
local savedOptions={};local spawned={};local now=0
local render=signal();local world={CurrentCamera={ViewportSize=Vector2.new(1280,900)}}
local controller=Shop.Install({Library=library,Tab={AddRightGroupbox=function()return box end},PlayerGui=playerGui,Workspace=world,Defer=task.defer,RunService={RenderStepped=render},Input=input,Options=savedOptions,Catalog={Chair='rbxassetid://chair'},ResolveItem=function(cell)return cell.Name end,
 Encode=function(data)return table.concat(data,'|')end,Decode=function(data)return data==''and{}or string.split(data,'|')end,
 Clock=function()return now end,SpawnThread=function(fn)fn()end,SpawnQuick=function(name,valid)if valid()then spawned[#spawned+1]=name end end})
local checks=0;local function check(ok,message)assert(ok,message);checks+=1 end
local function nativeBounds()
 local scale=math.min(1280/900,900/585,2)
 check(math.abs(menu.Size.X.Offset-346*scale)<1e-5 and math.abs(menu.Size.Y.Offset-274*scale)<1e-5,'Current v4.86 window size was changed')
 check(nativeScale.Scale==1,'Current shop scale changed')
 check(controller.Plan.Sidebar.Y==controller.Plan.Body.Y and controller.Plan.Sidebar.H==controller.Plan.Body.H,'Sidebar and content heights differ')
 check(controller.Plan.Grid.X-controller.Plan.Body.X>=6*controller.Plan.Scale,'Toy artwork touches rounded outer contour')
end
local all={toys,shop,settings,destroy,currency}
local function switch(page)
 for _,p in ipairs(all)do p.Visible=p==page end
 controller:Find();advance(.02)
 check(not controller.LastError,controller.LastError or'Unexpected profile failure')
 check(controller.Current and controller.Current.Node==page and controller.Active and controller.Layer.Visible,'Native page missing common style')
 nativeBounds()
 check(caption.TextTransparency==1 and caption.TextStrokeTransparency==1 and nativeBar.BackgroundTransparency==1 and footerStroke.Transparency==1,'Localized outlined footer/progress leaks outside Menu')
end
local clicks=0;toy.Activated:Connect(function()clicks+=1 end);card.Activated:Connect(function()clicks+=10 end);destroyButton.Activated:Connect(function()clicks+=100 end);buy.Activated:Connect(function()clicks+=1000 end)
controller:Sync();switch(toys)
check(grid.FillDirectionMaxCells==10 and grid.CellSize.X.Offset>25,'Ten-column inventory remains tiny')
check(toy.Image=='rbxassetid://star'and toy.ImageRectOffset==Vector2.new(20,30)and toy.Parent==list,'Original image atlas/path changed')
check(not toyStar.Visible,'Per-item favorite stars were not removed')
check(title.TextTransparency==1 and title.TextStrokeTransparency==1,'Native outlined inventory heading leaks')
check(controller.TextCopies.ToyLimitCount.Text=='5/100'and controller.Panels.Limit.Node.Visible,'Owned Toy Limit/count missing')
check(not controller.HasFavorite and not globalStar.Visible and not controller.TextCopies.FavoritesStar,'Global top-right star was not removed')
check(toy.AbsoluteSize.X<=controller.Plan.Cell+.001 and minA.MinSize==Vector2.zero and minB.MinSize==Vector2.zero and nativeAspect.AspectType==Enum.AspectType.FitWithinMaxSize,'Native parent-relative aspect or duplicate minimum breaks ten-column cell fit')
check(toy.AbsoluteSize.X*10+controller.Plan.Gap*9<=controller.Plan.Grid.W+.001,'Ten rendered cell widths do not fit viewport')
local desiredCell,desiredArt,desiredGap=toy.Size,art.Size,grid.CellPadding
local beforeLayouts,beforeTrees,beforeCells=controller.LayoutPasses,controller.TreeScans,controller.CellPasses
-- Native inventory code runs after the first skin pass when selecting,
-- spawning or refreshing previews. Cached cell dimensions must stay enforced.
toy.Size=UDim2.fromOffset(130,130);art.Size=UDim2.fromOffset(160,160);toyScale.Scale=1.8
minA.MinSize=Vector2.new(110,110);nativeAspect.AspectType=Enum.AspectType.ScaleWithParentSize
grid.CellSize=UDim2.fromOffset(130,130);grid.CellPadding=UDim2.fromOffset(35,35)
list.CanvasSize=UDim2.fromOffset(1000,8000)
advance(.02)
check(toy.Size==desiredCell and art.Size==desiredArt and toyScale.Scale==1 and minA.MinSize==Vector2.zero,
 'Post-paint native geometry overwrite leaves large toy previews or constraints')
check(nativeAspect.AspectType==Enum.AspectType.FitWithinMaxSize and grid.CellSize.X.Offset==controller.Plan.Cell and grid.CellPadding==desiredGap,
 'Native layout overwrite leaves oversized cells or wide gaps')
check(controller.LayoutPasses==beforeLayouts and controller.TreeScans==beforeTrees and controller.CellPasses==beforeCells,
 'Repairing native toy geometry repaints or rescans the entire shop')
check((controller.GeometryRepairs or 0)>=8,'Native geometry overwrites were never observed')
local beforeHover=controller.LayoutPasses
for i=1,20 do toy.BackgroundTransparency=.3;navButtons[1].BackgroundTransparency=.4;advance(.001)end
check(controller.LayoutPasses==beforeHover,'Native hover/interaction styling starts full page passes')
local streamedLimit=add(toy,'UISizeConstraint','StreamedMin');streamedLimit.MinSize=Vector2.new(180,180)
advance(.02)
check(streamedLimit.MinSize==Vector2.zero and toy.AbsoluteSize.X<=controller.Plan.Cell+.001,
 'Late native constraints bypass the cached cell styling')
local streamedLayouts=controller.LayoutPasses
streamedLimit.MinSize=Vector2.new(190,190);advance(.02)
check(streamedLimit.MinSize==Vector2.zero and controller.LayoutPasses==streamedLayouts,
 'A streamed constraint is either unguarded or triggers a full page repaint')
-- The game may replace its category layout without replacing the toy buttons.
grid:Destroy();grid=add(list,'UIGridLayout','ReplacementGrid')
grid.CellSize=UDim2.fromOffset(140,140);grid.CellPadding=UDim2.fromOffset(45,45)
advance(.02)
check(controller.Current.Grid==grid and grid.CellSize.X.Offset==controller.Plan.Cell and grid.CellPadding==desiredGap,
 'A late/replaced native grid is not discovered and corrected')
check(controller.Panels.Body.Node.BackgroundColor3==library.Scheme.WhiteColor and controller.Panels.Body.Node.BackgroundTransparency==library.Scheme.GlassTransparency and controller.Panels.Body.Node.AstralShopGradient.Color.Keypoints[1].Value==library.Scheme.BodyTopColor,'Shop does not use Astral glass gradient/opacity')
check(chat.Visible and chat.Position.Y.Offset>nav.Position.Y.Offset,'Detached native Chat tab is outside strip')
local corner=nav:FindFirstChild('AstralShopCorner');check(corner~=nil,'Sidebar not rounded')
toy.Activated:Fire();local inventoryWidth=grid.CellSize.X.Offset
switch(shop)
check(not toys.Visible and nav:FindFirstChild('AstralShopCorner')~=nil,'Hidden inventory or shared sidebar rounding broke on page switch')
check(price.TextScaled==false and price.TextSize<25 and price.Size.Y.Offset<25,'Paid card giant TextScaled price overlaps entire grid')
check(name.TextScaled==false and name.Position.Y.Offset>price.Position.Y.Offset,'Paid card name/price rows overlap')
check(shopTitle.TextTransparency==1 and shopTitle.TextStrokeTransparency==1,'Native Russian Shop heading leaks')
check(shopGrid.CellSize.Y.Offset>shopGrid.CellSize.X.Offset,'Paid card has no reserved text region')
check(controller.Current.List==shopList and math.abs(shopList.Size.X.Offset-controller.Plan.Grid.W)<1e-5,'Purchases use wrong half-width scrolling viewport')
check(priceIcon.Size.X.Offset<=8*controller.Plan.Scale and priceIcon.Position.Y.Offset>=controller.Plan.Cell,'Currency icon covers toy preview')
check(englishTitle.TextTransparency==1 and englishTitle.TextStrokeTransparency==1,'The Toy Shop native caption remains above our title')
check(not close.Visible,'Native menu close cross remains visible')

check(not controller.Panels.Limit.Node.Visible,'Inventory-only footer is rendered on purchase page')
card.Activated:Fire()
local huePosition,hueSize=hue.Position,hue.Size
switch(settings)
check(not shop.Visible and price.TextScaled==false and price.TextSize<25,'Paid card cache was lost or remained visible on another page')
check(controller.TextCopies.YourToysTitle.Text=='Settings'and settingsTitle.TextTransparency==1,'Settings retains old giant title/theme')
check(settingsFraction.TextTransparency==0,'Settings fraction was mistaken for an inventory count')
check(hue.Text=='160'and hue.Position==huePosition and hue.Size==hueSize and gradient.Color==originalGradient and swatch.BackgroundColor3==originalSwatch and presetGrid.CellSize==presetCellSize,'HSV geometry/values/gradient were flattened')
check(settings:FindFirstChild('AstralPanelScale')~=nil and controller.Current.ContentBounds and settings.AstralPanelScale.Scale>math.min(controller.Plan.Body.W/controller.Current.NativeSize.X,controller.Plan.Body.H/controller.Current.NativeSize.Y),'Settings useful content remains tiny inside an almost empty native page')
local settingsScale=settings:FindFirstChild('AstralPanelScale')
switch(destroy)
check(not settings.Visible and settingsScale.Parent==settings and hue.Position==huePosition and hue.Text=='160','Hidden Settings cache damaged controls or remained visible')
check(controller.TextCopies.YourToysTitle.Text=='Toy Cleanup','ToyDestroy remains unstyled')
check(cleanupCaption.TextTransparency==1 and cleanupCaption.TextStrokeTransparency==1,'Put Toys Away native caption remains visible')
destroyButton.Activated:Fire()
switch(currency);check(footerAction.TextTransparency==0,'Arbitrary native Footer action is mistaken for Toy Limit');check(controller.TextCopies.YourToysTitle.Text=='Coins','Unknown native page not discovered/styled');buy.Activated:Fire()
check(clicks==1111 and card.Parent==shopList and hue.Parent==picker,'Original game handlers/paths lost')
switch(toys);check(grid.CellSize.X.Offset==inventoryWidth,'Inventory changes size after full page round trip')
count.Text='6/100';controller:Find();check(controller.TextCopies.ToyLimitCount.Text=='6/100','Footer count stale')
local cachedSize=menu.Size;local cachedCells=controller.CellPasses
for _,p in ipairs(all)do p.Visible=false end;controller:Find()
check(not controller.Layer.Visible and caption.TextTransparency==1 and caption.TextStrokeTransparency==1,'Closing native menu exposes a sibling localized footer')
check(not close.Visible and controller.CellPasses==cachedCells and priceIcon.Size~=originalPriceIconSize,'Closing the menu discards its cached styling')
check(menu.Size==cachedSize and nativeScale.Scale==1,'Closing changes the cached menu geometry')
local before=hue.Position;controller:SetEnabled(false);check(not controller.Layer and hue.Position==before and menu.Size==originalMenuSize and priceIcon.Size==originalPriceIconSize and close.Visible,'Disable failed to restore original native properties')
controller:SetEnabled(true);switch(toys)
nativeScale.Scale=1.5;controller:Find()
check(nativeScale.Scale==1 and controller.MenuScale==1 and controller.LayerScale.Scale==1,'Existing fixed shop scale is not retained')
local moved=category[1];moved.Position=UDim2.fromOffset(1400,0);render:Fire()
local expected=(moved.AbsolutePosition-menu.AbsolutePosition)/controller.MenuScale
check(controller.IconCopies[moved].Position.X.Offset==expected.X,'Moved icon fallback double-applies native UIScale')
nativeScale.Scale=1;controller:Find()
local holder=add(gui,'Frame','NativeHolder');holder.Size=UDim2.fromScale(1,1);local ancestorScale=add(holder,'UIScale','AncestorScale');ancestorScale.Scale=1.25
menu.Parent=holder;controller:Find()
check(controller.MenuScale==1.25 and controller.LayerScale.Scale==1.25 and ancestorScale.Scale==1.25,'Ancestor native scale is ignored or overwritten')
-- A clock page uses the same chrome and native owned inventory only.
local quick=controller.Quick
check(quick and quick.Clock and quick.Clock.Size.Y.Offset==controller.Plan.Sidebar.H/8,'Clock tab does not fit shared sidebar height')
local passes=controller.LayoutPasses;controller:Find();controller:Find()
check(controller.LayoutPasses==passes,'Unchanged menu is rebuilt on every deferred update')
check(not(controller.Watches[toy]and controller.Watches[toy].Size),'A per-item size observer causes repeated full inventory layouts')
check(controller.TextCopies.ToyLimitCount.Parent==controller.Panels.Limit.Node and controller.Panels.Limit.Node.ClipsDescendants,'5/100 is outside its clipped Toy Limit frame')
check(controller.TextCopies.ToyLimitLabel.TextTransparency==0,'Style hides its own footer during a repeated update')
library.Scheme.FontColor=Color3.fromRGB(210,170,130);library.Scheme.GlassTransparency=.61;library.Scheme.BodyTopColor=Color3.fromRGB(31,32,33);library:UpdateColorsUsingRegistry()
check(controller.Panels.Body.Node.BackgroundTransparency==.61 and controller.TextCopies.ToyLimitCount.TextColor3==library.Scheme.FontColor and controller.Panels.Body.Node.AstralShopGradient.Color.Keypoints[1].Value==library.Scheme.BodyTopColor,'Shop does not follow live Astral theme changes')
local beforeScans,beforeCells,beforeDiscovery=controller.TreeScans,controller.CellPasses,controller.DiscoveryPasses
for i=1,50 do count.Text=tostring(i)..'/100';controller:Find()end
check(controller.TreeScans==beforeScans and controller.CellPasses==beforeCells and controller.DiscoveryPasses==beforeDiscovery,
 'Counter updates rescan or restyle the toy collection')
switch(shop);switch(toys);local warmCells=controller.CellPasses
for i=1,5 do switch(shop);switch(toys)end
check(controller.CellPasses==warmCells,'Warm page switches restyle every toy again')
local warmGrids=controller.GridPasses;local warmTree=controller.TreeScans
menu.Visible=false;controller:Find();menu.Visible=true;controller:Find()
check(controller.GridPasses==warmGrids and controller.TreeScans==warmTree,'Closing/reopening rebuilds the unchanged collection')
local preview=add(toy,'ViewportFrame','ModelPreview');controller:Find()
local model=add(preview,'WorldModel','NativeToy');local treeVersion=controller.TreeVersion;local gridPasses=controller.GridPasses
for i=1,100 do local mesh=add(model,'Part','PreviewMesh'..i);add(mesh,'Attachment','Link')end
controller:Find()
check(controller.TreeVersion==treeVersion and controller.GridPasses==gridPasses,'3D preview parts trigger full GUI layout invalidation')
quick.Clock.Activated:Fire();check(quick.Open and controller.Current.Quick and quick.Host.Visible,'Clock tab did not open')
local addButton=quick.Host:FindFirstChild('AddItem');addButton.Activated:Fire()
check(quick.Host.QuickItems.Chair.Item.Image=='rbxassetid://chair'and quick.Host.QuickItems.Chair.Item.ImageRectOffset==Vector2.zero,'Quick picker copied the favorite bitmap/atlas instead of item art')
check(quick.Choosing and quick.Owned.Chair and not quick.Owned.Unowned,'Picker includes unavailable store items')
quick.Host.QuickItems.Chair.Item.Activated:Fire()
check(quick.Rows.Chair.Image.Image=='rbxassetid://chair'and quick.Rows.Chair.Image.ImageRectOffset==Vector2.zero,'Selected quick tile copied favorite artwork')
check(quick.Selected.Chair and not quick.Choosing and quick.Rows.Chair.Bind.Size.X.Offset==quick.Rows.Chair.Image.Size.X.Offset,'Selected item bind does not match icon width')
quick.Rows.Chair.Bind.Activated:Fire();check(library.IsPicking and quick.Picking=='Chair','Compact bind does not capture')
input.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.K},false)
check(quick.Keys.Chair.Value=='K'and not library.IsPicking and #spawned==0,'Binding a key immediately spawns an item')
input.Focused=true;input.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.K},false);input.Focused=nil
input.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.K},true)
check(#spawned==0,'Typing/processed input spawns a toy')
input.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.K},false)
input.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.K},false)
check(#spawned==1 and spawned[1]=='Chair','Key press repeats/fails native owned spawn')
now+=1;quick.Rows.Chair.Image.Activated:Fire();check(#spawned==2,'Icon does not spawn selected item')
check(savedOptions.AstralShopQuickItems.Value=='Chair'and savedOptions.AstralShopQuickKey_Chair.Value=='K','Selection/key is absent from GUI config options')
quick.Rows.Chair.Bind.MouseButton2Click:Fire();check(quick.Keys.Chair.Value=='None','Right-click did not clear bind')
quick.Keys.Chair:SetValue({'J','Press',{'LCtrl'}});now+=1
input.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.J},false);check(#spawned==2,'Modifierless input triggers modified bind')
input.Held.LeftControl=true;input.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.J},false);check(#spawned==3,'Modified bind does not spawn');input.Held.LeftControl=false
quick.Rows.Chair.Image.MouseButton2Click:Fire();check(not quick.Selected.Chair and not quick:Spawn('Chair')and not quick:Spawn('Unowned'),'Removed/unowned item can still spawn')
savedOptions.AstralShopQuickItems:SetValue('Chair');quick.Keys.Chair:SetValue({'K','Press', {}})
controller:SetEnabled(false);check(toys.Visible and not library.IsPicking,'Disabling clock page leaves native game tabs hidden')
controller:SetEnabled(true);controller:Find()
quick.Clock.Activated:Fire();quick.Rows.Chair.Bind.Activated:Fire();menu.Visible=false;controller:Find()
check(not library.IsPicking and not quick.Open and toys.Visible,'Closing the game menu leaves key capture or native pages stuck')
menu.Visible=true;controller:Find()
local watches={};for _,map in pairs(controller.Watches)do for _,connection in pairs(map)do watches[#watches+1]=connection end end
for _,connection in pairs(controller.CellWatches or{})do watches[#watches+1]=connection end
local layer=controller.Layer;controller:Dispose();check(not layer.Parent,'Style survives unload')
for _,connection in ipairs(watches)do check(not connection.Connected,'Observer survives unload')end
check(savedOptions.AstralShopQuickItems==nil,'Quick config options survive unload')
check(next(library.Registry)==nil,'Owned shop theme entries survive unload')
print('PASS: reference rectangles, '..checks..' current-sized all-page profiles, padded star-free cards, paid labels, HSV, clipped footer, clock owned selection/binds/config/spawn and lifecycle (mocked)')
