local playerGui=Instance.new('Folder');playerGui.Name='PlayerGui'
local gui=Instance.new('ScreenGui',playerGui);gui.Name='MenuGui'
local menu=Instance.new('Frame',gui);menu.Name='Menu';menu.Size=UDim2.fromScale(.96,.96);menu.Visible=true;menu.ZIndex=3
local nativeScale=Instance.new('UIScale',menu);nativeScale.Scale=1.5
-- This real-world structural variation was rejected by the old controller.
local pages=Instance.new('Folder',menu);pages.Name='TabContents'
local settings=Instance.new('Frame',pages);settings.Name='Settings';settings.Visible=true
local hue=Instance.new('TextBox',settings);hue.Text='160';hue.TextSize=40
local toys=Instance.new('Frame',pages);toys.Name='Toys';toys.Visible=false
local titleWrap=Instance.new('Frame',toys);titleWrap.Name='Heading';titleWrap.Size=UDim2.new(1,0,0,70)
local title=Instance.new('TextLabel',titleWrap);title.Name='Title';title.Text='Ваши игрушки';title.TextScaled=true;title.TextSize=40
local categories=Instance.new('Frame',toys);categories.Name='Categories'
local catLayout=Instance.new('UIListLayout',categories);catLayout.Padding=UDim.new(0,8)
local categoryButtons={}
for i=1,6 do local button=Instance.new('ImageButton',categories);button.Name='Category'..i;button.Image='rbxassetid://'..i;button.LayoutOrder=i;button.ImageTransparency=0;button.ImageColor3=Color3.fromRGB(0,255,153);categoryButtons[i]=button end
local globalFavorite=Instance.new('ImageButton',categories);globalFavorite.Name='Favorite';globalFavorite.Image='rbxassetid://star';globalFavorite.ImageTransparency=0
local nav=Instance.new('Frame',menu);nav.Name='Tabs';local navLayout=Instance.new('UIListLayout',nav)
local navButtons={}
for i=1,6 do local button=Instance.new('ImageButton',nav);button.Name='Nav'..i;button.Image='rbxassetid://nav'..i;button.ImageTransparency=0;navButtons[i]=button end
local footer=Instance.new('Frame',toys);footer.Name='ToyLimit';footer.Visible=true
local limitLabel=Instance.new('TextLabel',footer);limitLabel.Text='Лимит игрушек'
local count=Instance.new('TextLabel',footer);count.Text='5/100'
local sourceSize,scaleValue=menu.Size,nativeScale.Scale
local library={Toggles={},ScreenGui=Instance.new('ScreenGui')};local box={}
function box:AddToggle(id,info)local t={Value=info.Default};function t:SetValue(v)self.Value=v;info.Callback(v)end;library.Toggles[id]=t;return t end
function box:AddLabel(text)return{SetText=function(self,v)self.Text=v end,Text=text}end
local world={CurrentCamera={ViewportSize=Vector2.new(900,585)}}
local render=signal()
local controller=Shop.Install({Library=library,Tab={AddRightGroupbox=function()return box end},PlayerGui=playerGui,Workspace=world,Defer=task.defer,RunService={RenderStepped=render}})
controller:Sync();assert(menu.Size==sourceSize and title.TextScaled,'Settings was restyled before opening toys')
-- Stream the actual collection after the enclosing folders already exist.
local list=Instance.new('ScrollingFrame',toys);list.Name='Contents';list.ScrollBarThickness=12
local grid=Instance.new('UIGridLayout',list);grid.CellSize=UDim2.fromOffset(100,100)
local item=Instance.new('ImageButton',list);item.Name='StarToy';item.Image='rbxassetid://chair'
local star=Instance.new('ImageButton',item);star.Name='StarButton';star.Image='rbxassetid://star';star.Visible=false
local clicks=0;item.Activated:Connect(function()clicks+=1 end);star.Activated:Connect(function()clicks+=10 end);categoryButtons[1].Activated:Connect(function()clicks+=100 end)
menu.DescendantAdded:Fire(list);settings.Visible=false;toys.Visible=true;advance(.03)
assert(not controller.LastError,controller.LastError)
assert(controller.Active and controller.Layer.Visible,'Folder TabContents or streamed Contents disables the shop')
assert(menu.Size.X.Offset==364 and menu.Size.Y.Offset==272 and nativeScale.Scale==1,'Reference window dimensions not applied')
assert(grid.FillDirectionMaxCells==10 and math.abs(grid.CellSize.X.Offset-30.3)<.01 and grid.CellPadding.X.Offset==1,'Reference item density differs')
assert(controller.Panels.Title.Node.Position.X.Offset==44 and controller.Panels.Title.Node.Size.X.Offset==177,'Left header pill has wrong rectangle')
assert(controller.Panels.Categories.Node.Position.X.Offset==224 and controller.Panels.Body.Node.Position.Y.Offset==47,'Header or inventory body differs from reference')
assert(controller.TextCopies.YourToysTitle.Text=='Your Toys'and controller.TextCopies.YourToysTitle.TextScaled==false and controller.TextCopies.YourToysTitle.TextSize==8,'Native TextScaled expands the compact title')
assert(title.Text=='Ваши игрушки'and title.TextTransparency==1,'Native localized title text was replaced instead of cosmetically hidden')
assert(navButtons[1].Size.Y.Offset<31 and nav.Size.X.Offset==30,'Sidebar icon inherited whole-window height')
assert(categories.Position.X.Offset==224 and categoryButtons[1].Position.X.Offset==0 and catLayout.FillDirection==Enum.FillDirection.Horizontal,'Category layout overrides absolute button placement')
assert(categoryButtons[1].ImageTransparency==1 and controller.IconCopies[categoryButtons[1]].ImageColor3:ToHex()=='f5f5f5','Active green native category is not rendered as a white icon')
local nativeButton=categoryButtons[1];local originalPosition=nativeButton.Position
nativeButton.Position=UDim2.fromOffset(30,0);render:Fire()
local actual=nativeButton.AbsolutePosition-menu.AbsolutePosition
assert(controller.IconCopies[nativeButton].Position.X.Offset==actual.X,'White icon no longer matches the native button hit area')
nativeButton.Position=originalPosition;render:Fire()
assert(item.Parent==list and star.Parent==item and star.Visible and item.Image=='rbxassetid://chair','Native inventory controls/images changed')
assert(#list:GetChildren()==2,'Decorations pollute native toy collection enumeration')
item.Activated:Fire();star.Activated:Fire();categoryButtons[1].Activated:Fire();assert(clicks==111,'Native buttons stopped executing their handlers')
assert(controller.TextCopies.ToyLimitCount.Text=='5/100'and footer.Visible and limitLabel.TextTransparency==1 and footer.Size.Y.Offset==16,'Native giant footer remains visible')
count.Text='6/100';advance(.03);assert(controller.TextCopies.ToyLimitCount.Text=='6/100','Inventory count stopped updating')
-- Native controller writes after our initial install must be observed and repaired.
menu.Size=UDim2.fromScale(.96,.96);grid.CellSize=UDim2.fromOffset(100,100);advance(.03)
assert(menu.Size.X.Offset==364 and grid.CellSize.X.Offset<31,'Late game layout code restores the old inventory')
toys.Visible=false;settings.Visible=true;advance(.03)
assert(menu.Size==sourceSize and nativeScale.Scale==scaleValue and not controller.Layer.Visible,'Settings retains shop dimensions or background')
assert(hue.Text=='160'and hue.TextSize==40 and title.TextTransparency==0 and footer.Visible,'Native Settings or original toy visuals not restored')
settings.Visible=false;toys.Visible=true;advance(.03);library.Toggles.AstralGUIShopStyle:SetValue(false)
assert(menu.Size==sourceSize and categoryButtons[1].ImageTransparency==0 and not controller.Layer,'Disable leaks the custom layout/white icon copies')
library.Toggles.AstralGUIShopStyle:SetValue(true)
local oldLayer=controller.Layer;menu.Destroying:Fire();menu:Destroy()
assert(not oldLayer.Parent,'Replacing the native menu leaves a background ghost')
local nextMenu=Instance.new('Frame',gui);nextMenu.Name='Menu';nextMenu.Visible=true
local nextPages=Instance.new('Folder',nextMenu);nextPages.Name='TabContents'
local nextToys=Instance.new('Frame',nextPages);nextToys.Name='Toys';nextToys.Visible=true
local nextList=Instance.new('ScrollingFrame',nextToys);nextList.Name='Contents'
Instance.new('UIGridLayout',nextList);playerGui.DescendantAdded:Fire(nextMenu);advance(.03)
assert(controller.Menu==nextMenu and controller.Active and controller.Layer.Visible,'Native shop does not return after menu replacement/respawn')
local listeners={};for _,map in pairs(controller.Watches)do for _,c in pairs(map)do listeners[#listeners+1]=c end end
local layer=controller.Layer;local renderConnection=controller.IconConnection;controller:Dispose()
assert(not renderConnection or not renderConnection.Connected,'Mirror render observer survives unload')
for _,c in ipairs(listeners)do assert(not c.Connected,'Property observer survives unload')end
assert(not layer.Parent,'Shop skin survives unload')
print('PASS: reference rectangles, Folder/streaming discovery, native layout overwrite repair, white icons, original item/category/favorite actions, counter, Settings and unload')
