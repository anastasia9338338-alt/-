local originalIsA=Node.IsA
function Node:IsA(class)
 if class=='GuiObject'and(self.ClassName=='UIPadding'or self.ClassName=='UISizeConstraint')then return false end
 return originalIsA(self,class)
end
local function add(parent,class,name)local n=Instance.new(class,parent);n.Name=name;return n end
local playerGui=Instance.new('Folder');playerGui.Name='PlayerGui'
local gui=add(playerGui,'ScreenGui','MenuGui')
local menu=add(gui,'Frame','Menu');menu.Size=UDim2.fromOffset(900,650);menu.Position=UDim2.fromScale(.5,.5);menu.AnchorPoint=Vector2.new(.5,.5);menu.ZIndex=3
local originalMenuSize,originalPosition,originalAnchor=menu.Size,menu.Position,menu.AnchorPoint
local nativeScale=add(menu,'UIScale','NativeScale');nativeScale.Scale=1
local pages=Instance.new('Folder',menu);pages.Name='TabContents'
local toys=add(pages,'Frame','Toys');toys.Visible=false;toys.Size=UDim2.fromScale(1,1)
local list=add(toys,'ScrollingFrame','Contents');local grid=add(list,'UIGridLayout','Grid');grid.CellSize=UDim2.fromOffset(100,100)
local toy=add(list,'ImageButton','Chair');toy.Image='rbxassetid://chair';toy.ImageRectOffset=Vector2.new(20,30)
local toyStar=add(toy,'ImageLabel','Star');toyStar.Image='rbxassetid://star';toyStar.Visible=false
local title=add(toys,'TextLabel','Title');title.Text='Ваши игрушки';title.TextScaled=true;title.TextStrokeTransparency=0
local cats=add(toys,'Frame','Categories');local category={};for i=1,6 do category[i]=add(cats,'ImageButton','Category'..i);category[i].Image='rbxassetid://'..i end
local nav=add(menu,'Frame','Tabs');local navButtons={};for i=1,6 do navButtons[i]=add(nav,'ImageButton','Tab'..i);navButtons[i].Image='rbxassetid://nav'..i end
local chat=add(menu,'ImageButton','ChatButton');chat.Image='rbxassetid://chat'
local globalStar=add(menu,'ImageButton','Favorites');globalStar.Image='rbxassetid://favorite'
local footer=add(gui,'Frame','ToyCountFooter');local caption=add(footer,'TextLabel','Caption');caption.Text='Limit';caption.LocalizedText='Лимит игрушек';caption.TextStrokeTransparency=0;caption.AutoLocalize=true
local count=add(footer,'TextLabel','Count');count.Text='5/100';local nativeBar=add(footer,'Frame','Progress');local footerStroke=add(nativeBar,'UIStroke','Border');footerStroke.Transparency=0
local shop=add(pages,'Frame','ToyShop');shop.Visible=false;shop.Size=UDim2.fromScale(1,1)
local shopTitle=add(shop,'TextLabel','Title');shopTitle.Text='Магазин игрушек';shopTitle.TextScaled=true;shopTitle.TextStrokeTransparency=0
local shopList=add(shop,'ScrollingFrame','Contents');local shopGrid=add(shopList,'UIGridLayout','Cards');shopGrid.CellSize=UDim2.fromOffset(100,100)
local card=add(shopList,'ImageButton','Product');card.Image='rbxassetid://product';local price=add(card,'TextLabel','Price');price.Text='5000';price.TextSize=90;price.TextScaled=true
local name=add(card,'TextLabel','Name');name.Text='Toy';name.TextScaled=true;name.TextSize=70
local settings=add(pages,'Frame','Settings');settings.Visible=false;settings.Size=UDim2.fromScale(1,1)
local settingsTitle=add(settings,'TextLabel','Title');settingsTitle.Text='Настройки';settingsTitle.TextScaled=true
local picker=add(settings,'Frame','ColorPicker');picker.Size=UDim2.fromOffset(500,260);picker.Position=UDim2.fromOffset(150,90)
local hue=add(picker,'TextBox','Hue');hue.Text='160';hue.Position=UDim2.fromOffset(300,40);hue.Size=UDim2.fromOffset(80,40);hue.TextSize=32
local gradient=add(picker,'UIGradient','HueGradient');gradient.Color=ColorSequence.new(Color3.new(1,0,0),Color3.new(0,1,0))
local originalGradient=gradient.Color
local swatch=add(picker,'TextButton','ColorSwatch');swatch.BackgroundColor3=Color3.new(1,0,0);local originalSwatch=swatch.BackgroundColor3
local presetGrid=add(picker,'UIGridLayout','ColorPresets');presetGrid.CellSize=UDim2.fromOffset(40,40)
local presetCellSize=presetGrid.CellSize
local destroy=add(pages,'Frame','ToyDestroy');destroy.Visible=false;destroy.Size=UDim2.fromScale(1,1)
local destroyButton=add(destroy,'TextButton','DestroySelected');destroyButton.Text='Delete';destroyButton.Position=UDim2.fromOffset(100,100);destroyButton.Size=UDim2.fromOffset(180,50)
local currency=add(pages,'Frame','Coins');currency.Visible=false;currency.Size=UDim2.fromScale(1,1)
local buy=add(currency,'TextButton','BuyCoins');buy.Text='Buy Coins';buy.Position=UDim2.fromOffset(200,200);buy.Size=UDim2.fromOffset(150,70)
local library={Toggles={},ScreenGui=Instance.new('ScreenGui')};local box={}
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
check(toy.Image=='rbxassetid://chair'and toy.ImageRectOffset==Vector2.new(20,30)and toy.Parent==list,'Original image atlas/path changed')
check(not toyStar.Visible,'Per-item favorite stars were not removed')
check(title.TextTransparency==1 and title.TextStrokeTransparency==1,'Native outlined inventory heading leaks')
check(controller.TextCopies.ToyLimitCount.Text=='5/100'and controller.Panels.Limit.Node.Visible,'Owned Toy Limit/count missing')
check(controller.HasFavorite and globalStar.Visible,'Global favorite missing')
check(chat.Visible and chat.Position.Y.Offset>nav.Position.Y.Offset,'Detached native Chat tab is outside strip')
local corner=nav:FindFirstChild('AstralShopCorner');check(corner~=nil,'Sidebar not rounded')
toy.Activated:Fire();local inventoryWidth=grid.CellSize.X.Offset
switch(shop)
check(title.TextTransparency==0 and not corner.Parent,'Leaving inventory retains old source properties/corners')
check(price.TextScaled==false and price.TextSize<25 and price.Size.Y.Offset<25,'Paid card giant TextScaled price overlaps entire grid')
check(name.TextScaled==false and name.Position.Y.Offset>price.Position.Y.Offset,'Paid card name/price rows overlap')
check(shopTitle.TextTransparency==1 and shopTitle.TextStrokeTransparency==1,'Native Russian Shop heading leaks')
check(shopGrid.CellSize.Y.Offset>shopGrid.CellSize.X.Offset,'Paid card has no reserved text region')
check(not controller.Panels.Limit.Node.Visible,'Inventory-only footer is rendered on purchase page')
card.Activated:Fire()
local huePosition,hueSize=hue.Position,hue.Size
switch(settings)
check(price.TextScaled==true and price.TextSize==90,'Previous paid card modifications leaked across page transition')
check(controller.TextCopies.YourToysTitle.Text=='Settings'and settingsTitle.TextTransparency==1,'Settings retains old giant title/theme')
check(hue.Text=='160'and hue.Position==huePosition and hue.Size==hueSize and gradient.Color==originalGradient and swatch.BackgroundColor3==originalSwatch and presetGrid.CellSize==presetCellSize,'HSV geometry/values/gradient were flattened')
check(settings:FindFirstChild('AstralPanelScale')~=nil and settings.Position.X.Offset+1e-5>=controller.Plan.Body.X,'Settings content not proportionally contained')
local settingsScale=settings:FindFirstChild('AstralPanelScale')
switch(destroy)
check(not settingsScale.Parent and hue.Position==huePosition and hue.Text=='160','Settings content/scale leaks into cleanup page')
check(controller.TextCopies.YourToysTitle.Text=='Toy Cleanup','ToyDestroy remains unstyled')
destroyButton.Activated:Fire()
switch(currency);check(controller.TextCopies.YourToysTitle.Text=='Coins','Unknown native page not discovered/styled');buy.Activated:Fire()
check(clicks==1111 and card.Parent==shopList and hue.Parent==picker,'Original game handlers/paths lost')
switch(toys);check(grid.CellSize.X.Offset==inventoryWidth,'Inventory changes size after full page round trip')
count.Text='6/100';controller:Find();check(controller.TextCopies.ToyLimitCount.Text=='6/100','Footer count stale')
for _,p in ipairs(all)do p.Visible=false end;controller:Find()
check(not controller.Layer.Visible and caption.TextTransparency==0 and caption.TextStrokeTransparency==0,'Closing native menu does not restore sibling localized footer')
check(menu.Size==originalMenuSize and nativeScale.Scale==1 and title.TextTransparency==0,'Closing changes ordinary menu geometry')
local before=hue.Position;controller:SetEnabled(false);check(not controller.Layer and hue.Position==before,'Disable leaves theme/native content changes')
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
quick.Clock.Activated:Fire();check(quick.Open and controller.Current.Quick and quick.Host.Visible,'Clock tab did not open')
local addButton=quick.Host:FindFirstChild('AddItem');addButton.Activated:Fire()
check(quick.Choosing and quick.Owned.Chair and not quick.Owned.Unowned,'Picker includes unavailable store items')
quick.Host.QuickItems.Chair.Item.Activated:Fire()
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
local layer=controller.Layer;controller:Dispose();check(not layer.Parent,'Style survives unload')
for _,connection in ipairs(watches)do check(not connection.Connected,'Observer survives unload')end
check(savedOptions.AstralShopQuickItems==nil,'Quick config options survive unload')
print('PASS: reference rectangles, '..checks..' current-sized all-page profiles, padded star-free cards, paid labels, HSV, clipped footer, clock owned selection/binds/config/spawn and lifecycle (mocked)')
