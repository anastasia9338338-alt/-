-- Fake Instances/scale/pose math for model behavior checks.

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

-- Roblox-shaped test doubles. These checks model geometry/lifecycle, not the
-- renderer, network replication, or the live Roblox physics engine.
local function signal()
 local s={Connections={}}
 function s:Connect(fn)local c={Connected=true,Fn=fn};function c:Disconnect()self.Connected=false end;table.insert(self.Connections,c);return c end
 function s:Once(fn)local c;c=self:Connect(function(...)c:Disconnect();fn(...)end);return c end
 function s:Fire(...)for _,c in ipairs(table.clone(self.Connections))do if c.Connected then c.Fn(...)end end end
 function s:Wait()error('Unexpected yielding event in nonyielding module test')end
 return s
end
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function finiteVector(v)return v and finite(v.X)and finite(v.Y)and finite(v.Z)end
local ALL_INSTANCES={}
local baseParts={Part=true,MeshPart=true,WedgePart=true,CornerWedgePart=true,UnionOperation=true,Seat=true,VehicleSeat=true,SpawnLocation=true}
local Proxy={}
Proxy.__index=function(n,k)
 if k=='Position'and n._props.CFrame then return n._props.CFrame.Position end
 if k=='ClassName'then return n._class end
 if Proxy[k]then return Proxy[k]end
 if n._props[k]~=nil then return n._props[k]end
 for _,c in ipairs(n._children)do if c.Name==k then return c end end
end
Proxy.__newindex=function(n,k,v)
 if k:sub(1,1)=='_'then rawset(n,k,v);return end
 if k=='Parent'then
  local old=n._props.Parent
  if old==v then return end
  if old and old._children then local i=table.find(old._children,n);if i then table.remove(old._children,i)end;old.ChildRemoved:Fire(n)end
  n._props.Parent=v
  if v and v._children then
   table.insert(v._children,n);v.ChildAdded:Fire(n)
   local ancestor=v;while ancestor do if ancestor.DescendantAdded then ancestor.DescendantAdded:Fire(n)end;ancestor=ancestor.Parent end
  end
 elseif k=='CFrame'then assert(getmetatable(v)==cfMT,'CFrame property requires CFrame');assert(finiteVector(v.Position),'nonfinite CFrame');n._props.CFrame=v
 elseif k=='Position'and baseParts[n._class]then
  assert(finiteVector(v),'nonfinite Position');n._props.CFrame=CFrame.new(v)*(n._props.CFrame and n._props.CFrame.Rotation or CFrame.new())
 elseif k=='Size'and baseParts[n._class]then
  assert(finiteVector(v)and v.X>0 and v.Y>0 and v.Z>0,'invalid part size');n._props[k]=v
 else n._props[k]=v end
 if n._signals[k]then n._signals[k]:Fire()end
end
function Proxy:IsA(class)return self._class==class or class=='BasePart'and baseParts[self._class]==true or class=='PVInstance'and(baseParts[self._class]or self._class=='Model')end
function Proxy:GetChildren()return table.clone(self._children)end
function Proxy:GetDescendants()local all={};for _,c in ipairs(self._children)do table.insert(all,c);for _,d in ipairs(c:GetDescendants())do table.insert(all,d)end end;return all end
function Proxy:FindFirstChild(name,recursive)for _,c in ipairs(self._children)do if c.Name==name then return c end;if recursive then local d=c:FindFirstChild(name,true);if d then return d end end end end
function Proxy:FindFirstChildOfClass(class)for _,c in ipairs(self._children)do if c:IsA(class)then return c end end end
function Proxy:FindFirstChildWhichIsA(class,recursive)for _,c in ipairs(self._children)do if c:IsA(class)then return c end;if recursive then local d=c:FindFirstChildWhichIsA(class,true);if d then return d end end end end
function Proxy:IsDescendantOf(ancestor)local p=self.Parent;while p do if p==ancestor then return true end;p=p.Parent end;return false end
function Proxy:SetAttribute(k,v)self._attrs[k]=v end
function Proxy:GetAttribute(k)return self._attrs[k]end
function Proxy:GetAttributes()return table.clone(self._attrs)end
function Proxy:GetPropertyChangedSignal(k)self._signals[k]=self._signals[k]or signal();return self._signals[k]end
function Proxy:WaitForChild(name,timeout)if self._WaitForChild then return self._WaitForChild(self,name,timeout)end;return self:FindFirstChild(name)end
function Proxy:Destroy()if self._destroyed then return end;self.Destroying:Fire();for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil;self._destroyed=true end
function Proxy:ClearAllChildren()for _,c in ipairs(self:GetChildren())do c:Destroy()end end
function Proxy:GetPivot()if self:IsA('BasePart')then return self.CFrame end;return self._pivot or CFrame.new()end
function Proxy:PivotTo(cf)local delta=cf*self:GetPivot():Inverse();for _,p in ipairs(self:GetDescendants())do if p:IsA('BasePart')then p.CFrame=delta*p.CFrame end end;self._pivot=cf end
function Proxy:GetExtentsSize()return Vector3.new(12,12,12)end
function Proxy:GetBoundingBox()return self:GetPivot(),self:GetExtentsSize()end
function Proxy:Emit(n)self._props.Emitted=(self._props.Emitted or 0)+n end
function Proxy:Clear()self._props.Emitted=0 end
newNode=function(class,name)
 local n=setmetatable({_class=class,_children={},_signals={},_attrs={},_props={Name=name or class,Parent=nil,
  CFrame=CFrame.new(),Size=Vector3.new(4,1,2),Transparency=0,Reflectance=0,Anchored=false,CanCollide=true,CanTouch=true,CanQuery=true,
  AssemblyLinearVelocity=Vector3.zero,AssemblyAngularVelocity=Vector3.zero,LocalTransparencyModifier=0,Enabled=true,
  ChildAdded=signal(),ChildRemoved=signal(),DescendantAdded=signal(),DescendantRemoving=signal(),Destroying=signal(),Touched=signal(),Activated=signal(),InputBegan=signal(),InputEnded=signal()}},Proxy)
 table.insert(ALL_INSTANCES,n);return n
end
Instance.new=function(class,parent)local n=newNode(class);if parent then n.Parent=parent end;return n end
local Color3={};local colorMT={}
function Color3.new(r,g,b)return setmetatable({R=r,G=g,B=b},colorMT)end
function Color3.fromRGB(r,g,b)return Color3.new(r/255,g/255,b/255)end
function Color3.fromHSV(h,s,v)
 local a=math.floor(h*6);local f=h*6-a;local p,q,t=v*(1-s),v*(1-f*s),v*(1-(1-f)*s)
 local values={{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}};local c=values[a%6+1];return Color3.new(c[1],c[2],c[3])
end
colorMT.__index={Lerp=function(a,b,t)return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t)end}
colorMT.__eq=function(a,b)return a.R==b.R and a.G==b.G and a.B==b.B end
local Random={}
function Random.new(seed)
 local r={Value=seed or 5489}
 function r:NextNumber(a,b)self.Value=(self.Value*16807)%2147483647;local t=self.Value/2147483647;if a==nil then return t end;return a+(b-a)*t end
 function r:NextInteger(a,b)return math.min(b,math.floor(self:NextNumber(a,b+1)))end
 return r
end
local NumberRange={new=function(a,b)return{Min=a,Max=b or a}end}
local NumberSequence={new=function(a,b)return{a,b}end}
local NumberSequenceKeypoint={new=function(t,v,e)return{Time=t,Value=v,Envelope=e or 0}end}
local ColorSequence={new=function(a,b)return{a,b}end}
local RaycastParams={new=function()return{}end}
function CFrame.fromMatrix(p,right,up,back)back=back or right:Cross(up);return frame(p,{right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z})end
function CFMethods:PointToObjectSpace(p)return self:Inverse()*p end
function CFMethods:PointToWorldSpace(p)return self*p end
function Proxy:IsDescendantOfClass(class)local p=self.Parent;while p do if p:IsA(class)then return true end;p=p.Parent end;return false end

