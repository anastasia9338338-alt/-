-- Deterministic RGBA PNG writer. Stored DEFLATE blocks avoid native codecs.
local requireModule=...
local crc=requireModule('PNGCRC').Compute
local PNG={}
local function u32(b,o,n)buffer.writeu8(b,o,math.floor(n/16777216)%256);buffer.writeu8(b,o+1,math.floor(n/65536)%256);buffer.writeu8(b,o+2,math.floor(n/256)%256);buffer.writeu8(b,o+3,n%256)end
local function chunk(name,data)
 local n=buffer.len(data);local out=buffer.create(n+12);u32(out,0,n);buffer.writestring(out,4,name);buffer.copy(out,8,data)
 u32(out,n+8,crc(out,4,n+4));return out
end
function PNG.Encode(p,w,h)
 assert(w>0 and h>0 and w<=4096 and h<=4096 and w*h<=4194304,'Слишком большое изображение')
 assert(buffer.len(p)==w*h*4,'Неверная длина RGBA')
 local stride=w*4+1;local raw=buffer.create(stride*h)
 for y=0,h-1 do buffer.copy(raw,y*stride+1,p,y*w*4,w*4)end
 local length=buffer.len(raw);local count=math.ceil(length/65535);local z=buffer.create(2+count*5+length+4)
 buffer.writeu8(z,0,0x78);buffer.writeu8(z,1,1)
 local source,dest,a,b=0,2,1,0
 while source<length do
  local n=math.min(65535,length-source)
  buffer.writeu8(z,dest,source+n==length and 1 or 0);buffer.writeu16(z,dest+1,n);buffer.writeu16(z,dest+3,65535-n)
  buffer.copy(z,dest+5,raw,source,n)
  for i=source,source+n-1 do a=(a+buffer.readu8(raw,i))%65521;b=(b+a)%65521 end
  source+=n;dest+=n+5
 end
 u32(z,dest,b*65536+a)
 local header=buffer.create(13);u32(header,0,w);u32(header,4,h);buffer.writeu8(header,8,8);buffer.writeu8(header,9,6)
 local parts={buffer.fromstring('\137PNG\13\10\26\10'),chunk('IHDR',header),chunk('IDAT',z),chunk('IEND',buffer.create(0))}
 local total=0;for _,part in ipairs(parts)do total+=buffer.len(part)end
 local out=buffer.create(total);local offset=0
 for _,part in ipairs(parts)do buffer.copy(out,offset,part);offset+=buffer.len(part)end
 return buffer.tostring(out)
end
return PNG
