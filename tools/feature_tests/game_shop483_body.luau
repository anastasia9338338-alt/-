local playerGui=Instance.new('Folder');playerGui.Name='PlayerGui'
local gui=Instance.new('ScreenGui',playerGui);gui.Name='MenuGui'
local menu=Instance.new('Frame',gui);menu.Name='Menu';menu.Size=UDim2.fromScale(.92,.94);menu.Position=UDim2.fromScale(.5,.5);menu.Visible=true
local nav=Instance.new('Frame',menu);nav.Name='Tabs';local navButton=Instance.new('ImageButton',nav);navButton.Image='rbxassetid://native-tab'
local pages=Instance.new('Frame',menu);pages.Name='TabContents';pages.Size=UDim2.new(1,-100,1,0);pages.AnchorPoint=Vector2.new(.5,.5)
local settings=Instance.new('Frame',pages);settings.Name='Settings';settings.Visible=true
local hsv=Instance.new('TextBox',settings);hsv.Name='Hue';hsv.Text='160';hsv.TextSize=40;hsv.BackgroundColor3=Color3.fromRGB(240,240,240)
local grad=Instance.new('UIGradient',hsv);grad.Rotation=90
local toys=Instance.new('Frame',pages);toys.Name='Toys';toys.Visible=false
local title=Instance.new('TextLabel',toys);title.Name='Title';title.Text='Your Toys'
local category=Instance.new('Frame',toys);category.Name='Categories';local catLayout=Instance.new('UIListLayout',category)
local categoryButton=Instance.new('ImageButton',category);categoryButton.Name='Balls';categoryButton.Image='rbxassetid://balls'
local list=Instance.new('ScrollingFrame',toys);list.Name='Contents';list.ScrollBarThickness=8;list.AnchorPoint=Vector2.new(.5,.5)
local grid=Instance.new('UIGridLayout',list);grid.CellSize=UDim2.fromOffset(100,100)
local item=Instance.new('ImageButton',list);item.Name='Rocket';item.Image='rbxassetid://rocket';item.LayoutOrder=17
local favorite=Instance.new('ImageButton',item);favorite.Name='Favorite';favorite.Image='rbxassetid://star'
local original={MenuSize=menu.Size,PagesSize=pages.Size,Font=hsv.FontFace,HueSize=hsv.Size,HueColor=hsv.BackgroundColor3,Grid=grid.CellSize}
local clicks=0;item.Activated:Connect(function()clicks+=1 end);favorite.Activated:Connect(function()clicks+=10 end);categoryButton.Activated:Connect(function()clicks+=100 end)
local library={Toggles={},ScreenGui=Instance.new('ScreenGui')};local group={}
function group:AddToggle(id,info)local t={Value=info.Default};function t:SetValue(v)self.Value=v;info.Callback(v)end;library.Toggles[id]=t;return t end
function group:AddLabel(text)return{SetText=function(self,v)self.Text=v end,Text=text}end
local workspace={CurrentCamera={ViewportSize=Vector2.new(1366,768)}}
local controller=Shop.Install({Library=library,Tab={AddRightGroupbox=function()return group end},PlayerGui=playerGui,Defer=task.defer,Workspace=workspace});controller:Sync()
assert(menu.Size==original.MenuSize and pages.Size==original.PagesSize,'Settings inherited the inventory layout')
assert(hsv.FontFace==original.Font and hsv.TextSize==40 and hsv.BackgroundColor3==original.HueColor and grad.Rotation==90,'HSV controls were restyled')
settings.Visible=false;toys.Visible=true;advance(.02)
assert(pages.AnchorPoint==Vector2.zero and list.AnchorPoint==Vector2.zero,'Native center anchors shift inventory outside its card')
assert(menu.Size.X.Offset==720 and menu.Size.Y.Offset==530,'Shop reference aspect/compact size missing')
assert(menu.BackgroundTransparency==1 and toys.BackgroundColor3:ToHex()=='303235'and toys:FindFirstChildOfClass('UICorner'),'Shop card/transparent surrounding window missing')
assert(grid.FillDirectionMaxCells==10 and grid.CellSize.X.Offset<70 and grid.CellPadding.X.Offset==4,'Inventory is not the dense ten-column reference grid')
assert(item.BackgroundTransparency==1 and favorite.BackgroundTransparency==1,'Toy/favorite buttons have opaque boxes')
assert(category.Position.X.Scale==.56 and category.Size.Y.Offset==34,'Categories are not in the upper strip')
assert(item.Parent==list and favorite.Parent==item and categoryButton.Parent==category and item.Image=='rbxassetid://rocket'and item.LayoutOrder==17,'Native hierarchy/images/order changed')
item.Activated:Fire();favorite.Activated:Fire();categoryButton.Activated:Fire();assert(clicks==111,'Native item/category/favorite actions lost')
local header=Instance.new('Frame',toys);header.Name='NativeHeader';header.Size=UDim2.new(1,0,0,90)
title.Parent=header;category.Parent=header;controller:Find()
assert(header.Size.Y.Offset==34 and title.Position.X.Offset==10 and category.Position.X.Scale==.56,'Nested native header overlaps the first toy row')
local streamed=Instance.new('ImageButton',list);streamed.Name='NewToy';menu.DescendantAdded:Fire(streamed);advance(.02);assert(streamed.BackgroundTransparency==1,'New toy retains an opaque background')
toys.Visible=false;settings.Visible=true;advance(.02)
assert(pages.AnchorPoint==Vector2.new(.5,.5),'Native Settings anchor was not restored')
assert(menu.Size==original.MenuSize and pages.Size==original.PagesSize,'Opening Settings does not restore the native window')
assert(hsv.Size==original.HueSize and hsv.Text=='160'and hsv.FontFace==original.Font and hsv.TextSize==40 and grad.Rotation==90,'Settings changed after visiting the shop')
settings.Visible=false;toys.Visible=true;workspace.CurrentCamera.ViewportSize=Vector2.new(360,640);controller:Find()
assert(menu.Size.X.Offset<=328 and menu.Size.Y.Offset<640 and grid.FillDirectionMaxCells<10,'Small viewport overflows or keeps unreadably dense columns')
library.Toggles.AstralGUIShopStyle:SetValue(false)
assert(menu.Size==original.MenuSize and grid.CellSize==original.Grid and not toys:FindFirstChildOfClass('UICorner'),'Disable does not restore native layout')
library.Toggles.AstralGUIShopStyle:SetValue(true);local old=table.clone(controller.MenuConnections);gui:Destroy()
local replacement=Instance.new('ScreenGui',playerGui);replacement.Name='MenuGui';local nextMenu=Instance.new('Frame',replacement);nextMenu.Name='Menu';local nextPages=Instance.new('Frame',nextMenu);nextPages.Name='TabContents'
playerGui.DescendantAdded:Fire(nextMenu);advance(.02);assert(controller.Menu==nextMenu,'Replacement menu not rebound')
for _,c in ipairs(old)do assert(not c.Connected,'Old menu observer survives respawn')end
local observed=table.clone(controller.Connections);controller:Dispose();for _,c in ipairs(observed)do assert(not c.Connected,'Shop observer survives unload')end
print('PASS: scoped reference inventory layout, original HSV Settings, ten-column grid, category/favorite actions, small viewport, streaming, respawn and unload')
