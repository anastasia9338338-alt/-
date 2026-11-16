local function typeof(value)return getmetatable(value)==Node and 'Instance'or type(value)end
local parentWrite=Node.__newindex
Node.__newindex=function(value,key,newValue)
 local previous=key=='Parent'and value.Parent
 parentWrite(value,key,newValue)
 if key=='Parent'and newValue~=previous and newValue and newValue.ChildAdded then newValue.ChildAdded:Fire(value)end
end
