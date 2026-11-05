-- Pure math/fake nodes for unit checks; not the Roblox renderer.

local Vector3={}
local vectorMT={}
function Vector3.new(x,y,z)return setmetatable({X=x,Y=y,Z=z},vectorMT)end
vectorMT.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vectorMT.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vectorMT.__index=function(v,k)if k=="Magnitude"then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end end
local CFrame={};local cfMT={}
function CFrame.new(x,y,z)return setmetatable({Position=type(x)=='table'and x or Vector3.new(x or 0,y or 0,z or 0)},cfMT)end
cfMT.__mul=function(a,b)return CFrame.new(a.Position+b.Position)end
local WORLD={}
local CURRENT_SIGNAL_FACTORY
local Node={}
Node.__index=function(n,k)if k=="Parent"then return rawget(n,"_parent")end;return Node[k]end
Node.__newindex=function(n,k,v)
    if k=="Parent"then
        local previous=rawget(n,"_parent")
        if previous and previous._children then
            local i=table.find(previous._children,n);if i then table.remove(previous._children,i)end
        end
        rawset(n,"_parent",v)
        if v and v._children then table.insert(v._children,n)end
    else rawset(n,k,v)end
end
function Node:IsA(c)return self.ClassName==c or c=="BasePart" and self.ClassName=="Part"end
function Node:FindFirstChild(name)for _,n in ipairs(self._children)do if n.Name==name then return n end end end
function Node:FindFirstChildOfClass(c)for _,n in ipairs(self._children)do if n:IsA(c)then return n end end end
function Node:WaitForChild(name)return self:FindFirstChild(name)end
function Node:GetChildren()return table.clone(self._children)end
function Node:GetDescendants()
    local result={};for _,n in ipairs(self._children)do table.insert(result,n);for _,d in ipairs(n:GetDescendants())do table.insert(result,d)end end
    return result
end
function Node:IsDescendantOf(parent)local p=self.Parent;while p do if p==parent then return true end;p=p.Parent end;return false end
function Node:Destroy()for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil end
local function newNode(class,name)
    local n=setmetatable({ClassName=class,Name=name or class,_children={},Position=Vector3.new(0,0,0),Velocity=Vector3.new(0,0,0),CanCollide=true,CFrame=CFrame.new()},Node)
    if class=="BodyPosition"then n.P=10000;n.D=1250 elseif class=="BodyGyro"then n.P=3000;n.D=500 end
    n.DescendantAdded=CURRENT_SIGNAL_FACTORY();n.ChildAdded=CURRENT_SIGNAL_FACTORY();n.ChildRemoved=CURRENT_SIGNAL_FACTORY();if class=="Part"then n.Touched=CURRENT_SIGNAL_FACTORY()end
    return n
end
local Instance={new=function(class)return newNode(class)end}
local Enum={PositionAlignmentMode={OneAttachment="OneAttachment"},OrientationAlignmentMode={OneAttachment="OneAttachment"}}

local VMethods={}
function VMethods:Dot(b)return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
function VMethods:Cross(b)return Vector3.new(self.Y*b.Z-self.Z*b.Y,self.Z*b.X-self.X*b.Z,self.X*b.Y-self.Y*b.X)end
function VMethods:Lerp(b,t)return self+(b-self)*t end
vectorMT.__index=function(v,k)
 if k=='Magnitude'then return math.sqrt(v:Dot(v))end
 if k=='Unit'then local m=v.Magnitude;return m>0 and v/m or Vector3.new(0,0,0)end
 return VMethods[k]
end
vectorMT.__mul=function(a,b)if type(a)=='number'then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
vectorMT.__div=function(a,b)return Vector3.new(a.X/b,a.Y/b,a.Z/b)end
vectorMT.__unm=function(a)return a*-1 end
Vector3.zero=Vector3.new(0,0,0);Vector3.yAxis=Vector3.new(0,1,0);Vector3.xAxis=Vector3.new(1,0,0);Vector3.zAxis=Vector3.new(0,0,1)
local Vector2={new=function(x,y)return Vector3.new(x,y,0)end};Vector2.zero=Vector2.new(0,0)
local identity={1,0,0,0,1,0,0,0,1}
local function mv(m,v)return Vector3.new(m[1]*v.X+m[2]*v.Y+m[3]*v.Z,m[4]*v.X+m[5]*v.Y+m[6]*v.Z,m[7]*v.X+m[8]*v.Y+m[9]*v.Z)end
local function mm(a,b)local r={};for i=0,2 do for j=1,3 do r[i*3+j]=a[i*3+1]*b[j]+a[i*3+2]*b[j+3]+a[i*3+3]*b[j+6]end end;return r end
local function frame(p,r)return setmetatable({Position=p,R=r or table.clone(identity)},cfMT)end
function CFrame.new(x,y,z)
 if type(x)=='table'then if type(y)=='table'then return CFrame.lookAt(x,y)end;return frame(x)end
 return frame(Vector3.new(x or 0,y or 0,z or 0))
end
local CFMethods={}
function CFMethods:VectorToWorldSpace(v)return mv(self.R,v)end
function CFMethods:VectorToObjectSpace(v)local r=self.R;return mv({r[1],r[4],r[7],r[2],r[5],r[8],r[3],r[6],r[9]},v)end
function CFMethods:Inverse()local r=self.R;local t={r[1],r[4],r[7],r[2],r[5],r[8],r[3],r[6],r[9]};return frame(-mv(t,self.Position),t)end
function CFMethods:ToObjectSpace(other)return self:Inverse()*other end
function CFMethods:Lerp(other,t)local r={};for i=1,9 do r[i]=self.R[i]+(other.R[i]-self.R[i])*t end;return frame(self.Position:Lerp(other.Position,t),r)end
cfMT.__index=function(cf,k)
 local r=cf.R
 if k=='LookVector'then return Vector3.new(-r[3],-r[6],-r[9])end
 if k=='UpVector'then return Vector3.new(r[2],r[5],r[8])end
 if k=='RightVector'then return Vector3.new(r[1],r[4],r[7])end
 return CFMethods[k]
end
cfMT.__mul=function(a,b)return frame(a.Position+mv(a.R,b.Position),mm(a.R,b.R))end
cfMT.__add=function(a,b)return frame(a.Position+b,a.R)end
cfMT.__sub=function(a,b)return frame(a.Position-b,a.R)end
function CFrame.lookAt(p,target,up)
 local f=(target-p).Unit;up=up or Vector3.yAxis
 local right=f:Cross(up).Unit;local top=right:Cross(f)
 return frame(p,{right.X,top.X,-f.X,right.Y,top.Y,-f.Y,right.Z,top.Z,-f.Z})
end
function CFrame.Angles(x,y,z)
 local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
 return frame(Vector3.zero,mm(mm({1,0,0,0,cx,-sx,0,sx,cx},{cy,0,sy,0,1,0,-sy,0,cy}),{cz,-sz,0,sz,cz,0,0,0,1}))
end
setmetatable(Enum,{__index=function(t,k)local v=setmetatable({},{__index=function(_,n)return k..'.'..n end});rawset(t,k,v);return v end})

local previousCFIndex=cfMT.__index
cfMT.__index=function(cf,k)
 if k=='Rotation'then return CFrame.new()*frame(Vector3.zero,cf.R)end
 if k=='X'or k=='Y'or k=='Z'then return cf.Position[k]end
 return previousCFIndex(cf,k)
end
cfMT.__mul=function(a,b)
 if getmetatable(b)==vectorMT then return a.Position+mv(a.R,b)end
 return frame(a.Position+mv(a.R,b.Position),mm(a.R,b.R))
end
local function typeof(v)
 if getmetatable(v)==vectorMT then return 'Vector3'end
 if getmetatable(v)==cfMT then return 'CFrame'end
 return type(v)
end
function Node:GetConnectedParts()return {}end
