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

