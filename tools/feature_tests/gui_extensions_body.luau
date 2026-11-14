local w,h=96,64
local function picture(pixel)
 local p=buffer.create(w*h*4)
 for y=0,h-1 do for x=0,w-1 do
  local r,g,b,a=pixel(x,y);local i=(y*w+x)*4
  buffer.writeu8(p,i,r);buffer.writeu8(p,i+1,g);buffer.writeu8(p,i+2,b);buffer.writeu8(p,i+3,a or 255)
 end end
 return p
end
local function checker(x,y)
 if(x>=7 and x<=88 and(y>=7 and y<=11 or y>=52 and y<=56))or(y>=7 and y<=56 and(x>=7 and x<=11 or x>=84 and x<=88))then return 242,242,242 end
 local v=(math.floor(x/8)+math.floor(y/8))%2==0 and 82 or 106;return v,v,v
end
local p=picture(checker);local cleaned=Art.Clean(p,w,h,true)
assert(cleaned.Removed>3000 and buffer.readu8(cleaned.Pixels,3)==0 and buffer.readu8(p,3)==255,'Checker not removed or original modified')
assert(buffer.readu8(cleaned.Pixels,(8*w+8)*4+3)==255,'White ornament removed')
assert(cleaned.X0==7 and cleaned.Y0==7 and cleaned.X1==88 and cleaned.Y1==56,'Transparent margin bounds incorrect')
assert(buffer.tostring(Art.Clean(p,w,h,false).Pixels)==buffer.tostring(p),'Removal toggle ignored')
local stripes=picture(function(x)local v=math.floor(x/8)%2==0 and 82 or 106;return v,v,v end)
assert(Art.Clean(stripes,w,h,true).Removed==0,'Striped photo mistaken for checker')
local photo=picture(function(x,y)return(x*3+y)%256,(y*4+120)%256,(x+y*2+40)%256 end)
assert(Art.Clean(photo,w,h,true).Removed==0,'Color photo changed')
local png=picture(function(x,y)if y<8 then return 0,0,0,0 end;return checker(x,y)end)
assert(Art.Clean(png,w,h,true).Removed==0,'Transparent PNG destructively processed')
local opaque=picture(function()return 255,255,255 end);local data=Art.Clean(opaque,w,h,true)
for _,dims in ipairs({{320,260,2,22},{660,624,14,22},{1280,900,80,18},{64,48,8,6}})do
 local iw,ih,border,radius=table.unpack(dims);local pixels,rw,rh=Art.Raster(data,iw,ih,border,radius,.22)
 assert(rw<=960 and rh<=960 and buffer.len(pixels)==rw*rh*4,'Oversized raster')
 local scale=math.min(1,960/math.max(iw+border*2,ih+border*2))
 assert(buffer.readu8(pixels,(math.floor(rh/2)*rw+math.floor(rw/2))*4+3)==0 and buffer.readu8(pixels,3)==0,'Opaque center or square corner')
 assert(buffer.readu8(pixels,(math.floor(border*.5*scale)*rw+math.floor(rw/2))*4+3)==255,'Missing top edge')
 for y=0,rh-1 do for x=0,rw-1 do
  local px,py=(x+.5)/scale-border,(y+.5)/scale-border
  if px>=radius and px<iw-radius and py>=radius and py<ih-radius then assert(buffer.readu8(pixels,(y*rw+x)*4+3)==0,'Ornament covers contents')end
 end end
end
local dead={Size=Vector2.new(1,1),ReadPixelsBuffer=function()error('read failed')end,Destroy=function(self)self.Destroyed=true end}
assert(not pcall(Art.Decode,'rbxassetid://1',{CreateEditableImageAsync=function()return dead end})and dead.Destroyed,'Read failure leaks image')
local failed={Destroy=function(self)self.Destroyed=true end,WritePixelsBuffer=function()error('write failed')end}
assert(not pcall(Art.Texture,buffer.create(4),1,1,{CreateEditableImage=function()return failed end})and failed.Destroyed,'Write failure leaks image')
local original=Content.fromObject;Content.fromObject=function()error('content failed')end
failed={Destroy=function(self)self.Destroyed=true end,WritePixelsBuffer=function()end}
local ok=pcall(Art.Texture,buffer.create(4),1,1,{CreateEditableImage=function()return failed end});Content.fromObject=original
assert(not ok and failed.Destroyed,'ImageContent failure leaks image')
print('PASS: checker pixel removal, transparent PNG/photo preservation, rounded resizing and image failure cleanup')

local playerGui=Instance.new('Folder');playerGui.Name='PlayerGui'
local gui=Instance.new('ScreenGui',playerGui);gui.Name='MenuGui'
local menu=Instance.new('Frame',gui);menu.Name='Menu';menu.Size=UDim2.fromOffset(400,300);menu.Position=UDim2.fromOffset(70,90);menu.Visible=false
local grid=Instance.new('ScrollingFrame',menu);grid.Name='YourToys';grid.ScrollBarThickness=8
local layout=Instance.new('UIGridLayout',grid);layout.CellSize=UDim2.fromOffset(32,32)
local item=Instance.new('ImageButton',grid);item.Name='Rocket';item.Image='rbxassetid://rocket';item.LayoutOrder=17
local favorite=Instance.new('ImageButton',item);favorite.Name='Favorite';favorite.Image='rbxassetid://star'
local category=Instance.new('ImageButton',menu);category.Name='Balls';category.Image='rbxassetid://balls'
local caption=Instance.new('TextLabel',menu);caption.Text='Your Toys'
local clicks=0;item.Activated:Connect(function()clicks+=1 end);favorite.Activated:Connect(function()clicks+=10 end)
local oldColor,oldFont,oldSize,oldPos=menu.BackgroundColor3,caption.FontFace,menu.Size,menu.Position
local library={Toggles={}};local group={}
function group:AddToggle(id,info)local t={Value=info.Default};function t:SetValue(v)self.Value=v;info.Callback(v)end;library.Toggles[id]=t;return t end
function group:AddLabel(text)return{SetText=function(self,v)self.Text=v end,Text=text}end
local controller=Shop.Install({Library=library,Tab={AddRightGroupbox=function()return group end},PlayerGui=playerGui,Defer=task.defer});controller:Sync()
assert(controller.Menu==menu and menu.BackgroundColor3:ToHex()=='3d3f42'and menu:FindFirstChildOfClass('UICorner').CornerRadius.Offset==20,'Native rounded gray shop missing')
assert(menu.Size==oldSize and menu.Position==oldPos and not menu.Visible and item.Parent==grid and item.LayoutOrder==17 and layout.Parent==grid,'Native shop geometry changed')
assert(item.Image=='rbxassetid://rocket'and favorite.Image=='rbxassetid://star'and category.Image=='rbxassetid://balls'and favorite.BackgroundTransparency==1,'Native images/favorites changed')
item.Activated:Fire();favorite.Activated:Fire();assert(clicks==11,'Native actions lost')
local streamed=Instance.new('ImageButton',grid);streamed.Name='NewToy';menu.DescendantAdded:Fire(streamed);advance(.02)
assert(streamed:FindFirstChildOfClass('UICorner'),'Streamed item unstyled')
library.Toggles.AstralGUIShopStyle:SetValue(false)
assert(menu.BackgroundColor3==oldColor and caption.FontFace==oldFont and grid.ScrollBarThickness==8 and not item:FindFirstChildOfClass('UICorner')and not menu:FindFirstChildOfClass('UICorner'),'Disable failed to restore native shop')
library.Toggles.AstralGUIShopStyle:SetValue(true);local previousConnection=controller.MenuConnection;gui:Destroy()
local replacement=Instance.new('ScreenGui',playerGui);replacement.Name='MenuGui';local nextMenu=Instance.new('Frame',replacement);nextMenu.Name='Menu'
playerGui.DescendantAdded:Fire(nextMenu);advance(.02)
assert(controller.Menu==nextMenu and not previousConnection.Connected and nextMenu.BackgroundColor3:ToHex()=='3d3f42','Replacement/respawn shop unstyled')
local connections=table.clone(controller.Connections);controller:Dispose()
for _,c in ipairs(connections)do assert(not c.Connected,'Shop observer survives unload')end
assert(not nextMenu:FindFirstChildOfClass('UICorner'),'Shop decoration survives unload')
playerGui.DescendantAdded:Fire(nextMenu);advance(.02);assert(controller.Menu==nil,'Shop restyles after unload')
print('PASS: native shop actions, images, layout, streamed items, disable restoration, respawn and unload')
