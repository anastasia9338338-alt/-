-- Embedded gallery images use local assets; custom URLs use the existing loader.
local requireModule = ...
local Catalog = requireModule("BackgroundCatalog")
local Assets = requireModule("BackgroundAssets")
local Store = {}
Store.__index = Store
local digits={}
for index=1,64 do digits[string.byte("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",index)]=index-1 end
function Store.Decode(data, valid, yieldFrame)
	assert(#data%4==0,"Invalid embedded image encoding")
	local padding=data:sub(-2)=="==" and 2 or data:sub(-1)=="=" and 1 or 0
	local output=buffer.create(#data/4*3-padding)
	local position=0
	for index=1,#data,4 do
		if index%65536==1 then
			if valid and not valid() then return nil end
			if index>1 and yieldFrame then yieldFrame() end
			if valid and not valid() then return nil end
		end
		local a,b,c,d=string.byte(data,index,index+3)
		local n=assert(digits[a])*262144+assert(digits[b])*4096+(digits[c]or 0)*64+(digits[d]or 0)
		buffer.writeu8(output,position,math.floor(n/65536)%256);position+=1
		if c~=61 then buffer.writeu8(output,position,math.floor(n/256)%256);position+=1 end
		if d~=61 then buffer.writeu8(output,position,n%256);position+=1 end
	end
	return buffer.tostring(output)
end

function Store.Install(context)
	return setmetatable({Context=context, Files={}, Serial=0}, Store)
end
function Store:Resolve(source, callback)
	local item
	for _,candidate in ipairs(Catalog.Items) do if candidate.Source==source then item=candidate; break end end
	if self.Closed or not item or not self.Context.Write or not self.Context.Register then return false end
	local data=Assets[item.Key]
	if type(data)~="string" then return false end
	self.Serial+=1
	local path=self.Context.Name(self.Serial)
	self.Context.Spawn(function()
		if self.Closed then return end
		local ok, asset=pcall(function()
			local bytes=Store.Decode(data,function()return not self.Closed end,self.Context.Wait)
			if self.Closed then return end
			self.Files[path]=true
			self.Context.Write(path,bytes)
			if self.Closed then return end
			return self.Context.Register(path)
		end)
		if self.Closed then
			if self.Context.Remove then pcall(self.Context.Remove,path) end
			self.Files[path]=nil
			return
		end
		callback(ok and type(asset)=="string" and asset or nil)
	end)
	return true
end
function Store:Dispose()
	if self.Closed then return end
	self.Closed=true
	for path in pairs(self.Files) do if self.Context.Remove then pcall(self.Context.Remove,path) end end
	table.clear(self.Files)
end
return Store
