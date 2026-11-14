-- Pixel processing stays on the Roblox client. No image is sent to a service.
local Art={}
local function gray(p,i)
 local r,g,b=buffer.readu8(p,i),buffer.readu8(p,i+1),buffer.readu8(p,i+2)
 if math.max(r,g,b)-math.min(r,g,b)>12 or buffer.readu8(p,i+3)<248 then return end
 return(r+g+b)/3
end
function Art.Clean(p,w,h,enabled)
 local out=buffer.create(w*h*4);buffer.copy(out,0,p,0,w*h*4)
 local histogram={};local neutral,transparent,sampled=0,0,0;local step=math.max(1,math.floor(math.sqrt(w*h/100000)))
 for y=0,h-1,step do for x=0,w-1,step do
  sampled+=1;if buffer.readu8(p,(y*w+x)*4+3)<248 then transparent+=1 end
  local v=gray(p,(y*w+x)*4)
  if v then local bin=math.floor(v/4);histogram[bin]=(histogram[bin]or 0)+1;neutral+=1 end
 end end
 local candidates={}
 for bin,count in pairs(histogram)do candidates[#candidates+1]={Bin=bin,Count=count}end
 table.sort(candidates,function(a,b)return a.Count>b.Count end)
 local function regularGrid(tones)
  local rows,columns=0,0
  for _,fraction in ipairs({.05,.25,.5,.75,.95})do for axis=1,2 do
   local limit=axis==1 and w or h;local fixed=math.floor((axis==1 and h-1 or w-1)*fraction)
   local last,run,changes,runs=nil,0,0,{}
   for k=0,limit-1 do
    local i=axis==1 and(fixed*w+k)*4 or(k*w+fixed)*4;local v=gray(p,i)
    local tag=v and math.min(math.abs(v-tones[1]),math.abs(v-tones[2]))<=8 and(math.abs(v-tones[1])<math.abs(v-tones[2])and 1 or 2)or nil
    if tag and tag==last then run+=1 else
     if tag and last and run>=3 and run<=80 then changes+=1;runs[#runs+1]=run end
     last=tag;run=1
    end
   end
   if changes>=5 then
    table.sort(runs);local median=runs[math.ceil(#runs/2)];local count=0
    for _,v in ipairs(runs)do if math.abs(v-median)<=math.max(2,median*.35)then count+=1 end end
    if count>=#runs*.65 then if axis==1 then rows+=1 else columns+=1 end end
   end
  end end
  return rows,columns
 end
 local tones,best=nil,-1
 if enabled and transparent<sampled*.05 then
  for i=1,math.min(#candidates,16)do for j=i+1,math.min(#candidates,16)do
   local a,b=candidates[i],candidates[j];local diff=math.abs(a.Bin-b.Bin)
   if diff>=3 and diff<=22 and a.Count+b.Count>neutral*.12 and math.min(a.Count,b.Count)>neutral*.025 then
    local pair={a.Bin*4+2,b.Bin*4+2};local rows,columns=regularGrid(pair)
    local score=rows+columns+(a.Count+b.Count)/math.max(neutral,1)
    if rows>0 and columns>0 and score>best then best=score;tones=pair end
   end
  end end
 end
 local removed=0
 if enabled and tones then
  for i=0,w*h-1 do
   local v=gray(p,i*4)
   if v and math.min(math.abs(v-tones[1]),math.abs(v-tones[2]))<=9 then buffer.writeu8(out,i*4+3,0);removed+=1 end
  end
 end
 local x0,y0,x1,y1=w,h,-1,-1
 for y=0,h-1 do for x=0,w-1 do
  if buffer.readu8(out,(y*w+x)*4+3)>16 then x0=math.min(x0,x);y0=math.min(y0,y);x1=math.max(x1,x);y1=math.max(y1,y)end
 end end
 if x1<x0 then error('В рамке не осталось видимых пикселей')end
 return{Pixels=out,Width=w,Height=h,X0=x0,Y0=y0,X1=x1,Y1=y1,Removed=removed}
end
local function inside(x,y,w,h,r)
 if x<0 or y<0 or x>=w or y>=h then return false end
 local dx=math.max(r-x,x-(w-r),0);local dy=math.max(r-y,y-(h-r),0)
 return dx*dx+dy*dy<=r*r
end
function Art.Raster(data,width,height,border,radius,edge)
 local ow,oh=width+border*2,height+border*2
 local scale=math.min(1,960/math.max(ow,oh));local w,h=math.max(1,math.floor(ow*scale)),math.max(1,math.floor(oh*scale))
 local result=buffer.create(w*h*4);local corner=math.min(radius+border,ow/3,oh/3)
 local function uv(v,total)
  if v<corner then return v/corner*edge end
  if v>total-corner then return 1-edge+(v-total+corner)/corner*edge end
  return edge+(v-corner)/(total-corner*2)*(1-edge*2)
 end
 for y=0,h-1 do for x=0,w-1 do
  local px,py=(x+.5)/scale,(y+.5)/scale
  if inside(px,py,ow,oh,radius+border)and not inside(px-border,py-border,width,height,radius)then
   local u,v=uv(px,ow),uv(py,oh)
   local sx=math.clamp(math.floor(data.X0+u*(data.X1-data.X0)),0,data.Width-1)
   local sy=math.clamp(math.floor(data.Y0+v*(data.Y1-data.Y0)),0,data.Height-1)
   buffer.copy(result,(y*w+x)*4,data.Pixels,(sy*data.Width+sx)*4,4)
  end
 end end
 return result,w,h
end
function Art.Decode(asset,service)
 local image=assert(service:CreateEditableImageAsync(Content.fromUri(asset)),'EditableImage недоступен')
 local ok,result=pcall(function()
  local size=image.Size
  return{Pixels=image:ReadPixelsBuffer(Vector2.zero,size),Width=size.X,Height=size.Y}
 end)
 image:Destroy();if not ok then error(result)end;return result
end
function Art.Texture(p,w,h,service)
 local image=assert(service:CreateEditableImage({Size=Vector2.new(w,h)}),'Недостаточно памяти для рамки')
 local ok,content=pcall(function()
  image:WritePixelsBuffer(Vector2.zero,Vector2.new(w,h),p)
  return assert(Content.fromObject(image),'ImageContent недоступен')
 end)
 if not ok then image:Destroy();error(content)end
 return image,content
end
return Art
