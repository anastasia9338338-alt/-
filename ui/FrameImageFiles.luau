-- Custom-asset files work without EditableImage or ImageContent permissions.
local requireModule=...
local decodePNG=requireModule('PNGDecode').Decode
local encodePNG=requireModule('PNGEncode')
local decodeJPEG=requireModule('JPEGDecode')
local Files={};Files.__index=Files
function Files.Install(ctx)return setmetatable({Context=ctx,Resources={},Serial=0},Files)end
function Files:Decode(asset)
 assert(not self.Closed,'Рамка выгружена')
 local ok,bytes=pcall(self.Context.ReadAsset,asset)
 if ok and type(bytes)=='string'and bytes:sub(1,8)=='\137PNG\13\10\26\10'then
  local source=buffer.fromstring(bytes :: string);local parsed,why=decodePNG(source)
  assert(parsed,why and why.message or'Некорректная PNG')
  assert(parsed.width<=4096 and parsed.height<=4096 and parsed.width*parsed.height<=4194304,'Рамка должна быть не больше 4 Мп')
  local image,errorInfo=parsed.cel(0,'rgba8');assert(image,errorInfo and errorInfo.message or'Не удалось прочитать PNG')
  return{Pixels=image.bitmap,Width=parsed.width,Height=parsed.height}
 end
 if ok and type(bytes)=='string'and bytes:byte(1)==255 and bytes:byte(2)==216 then
  local decoded,image=pcall(decodeJPEG.decode,bytes)
  if decoded then
   local pixels=buffer.create(image.width*image.height*4)
   for i=0,image.width*image.height-1 do
    local j=i*3;buffer.writeu8(pixels,i*4,image.pixels[j+1]);buffer.writeu8(pixels,i*4+1,image.pixels[j+2]);buffer.writeu8(pixels,i*4+2,image.pixels[j+3]);buffer.writeu8(pixels,i*4+3,255)
   end
   return{Pixels=pixels,Width=image.width,Height=image.height}
  end
 end
 if self.Context.NativeDecode then
  local decoded,result=pcall(self.Context.NativeDecode,asset)
  if decoded then return result end
 end
 error('Не удалось прочитать рамку. Вставь прямую ссылку на PNG с прозрачным фоном.')
end
function Files:Texture(p,w,h)
 assert(not self.Closed,'Рамка выгружена')
 if not(self.Context.Write and self.Context.Register)then return self.Context.NativeTexture(p,w,h)end
 self.Serial+=1
 local filename=self.Context.Name(self.Serial)
 local ok,asset=pcall(function()
  self.Context.Write(filename,encodePNG.Encode(p,w,h))
  return assert(self.Context.Register(filename),'Регистрация PNG не удалась')
 end)
 if not ok then if self.Context.Remove then pcall(self.Context.Remove,filename)end;error(asset)end
 if self.Closed then if self.Context.Remove then pcall(self.Context.Remove,filename)end;error('Рамка выгружена')end
 local resource={Filename=filename,Owner=self}
 function resource:Destroy()
  if self.Destroyed then return end;self.Destroyed=true;self.Owner.Resources[self]=nil
  if self.Owner.Context.Remove then pcall(self.Owner.Context.Remove,self.Filename)end
 end
 self.Resources[resource]=true
 return resource,asset
end
function Files:Dispose()
 if self.Closed then return end;self.Closed=true
 local all={};for r in pairs(self.Resources)do all[#all+1]=r end;for _,r in ipairs(all)do r:Destroy()end
end
return Files
