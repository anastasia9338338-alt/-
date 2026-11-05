-- Fake Roblox geometry/signals for ESP behavior checks.

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
local checks=0
local function check(condition,message)
    assert(condition,message)
    checks+=1
end

local Scheduler={};Scheduler.__index=Scheduler
function Scheduler.new(preSimulation)
    local self=setmetatable({Now=0,Errors={},Sleepers={},Phase="idle"},Scheduler)
    local function signal()
        local sig={Listeners={},Waiters={}}
        function sig:Connect(fn)
            local c={Connected=true,Function=fn}
            function c:Disconnect()self.Connected=false end
            self.Listeners[#self.Listeners+1]=c
            return c
        end
        function sig:Wait()return coroutine.yield({Signal=self})end
        function sig:Fire(dt)
            local waiters=self.Waiters;self.Waiters={}
            local listeners=table.clone(self.Listeners)
            for _,c in ipairs(listeners)do if c.Connected then self.Scheduler:Spawn(c.Function,dt)end end
            for _,co in ipairs(waiters)do self.Scheduler:Resume(co,dt)end
        end
        sig.Scheduler=self
        return sig
    end
    self.NewSignal=signal
    self.RunService={Heartbeat=signal()}
    if preSimulation~=false then self.RunService.PreSimulation=signal()end
    return self
end
function Scheduler:Resume(co,...)
    local ok,value=coroutine.resume(co,...)
    if not ok then self.Errors[#self.Errors+1]=tostring(value);return end
    if coroutine.status(co)=="dead"then return end
    assert(type(value)=="table","Unexpected coroutine yield")
    if value.Signal then table.insert(value.Signal.Waiters,co)
    else table.insert(self.Sleepers,{Thread=co,At=value.At})end
end
function Scheduler:Spawn(fn,...)self:Resume(coroutine.create(fn),...)end
function Scheduler:Wait(seconds)return coroutine.yield({At=self.Now+(seconds or self.Dt or 1/60)})end
function Scheduler:Tick(dt)
    self.Dt=dt;self.Now+=dt
    self.Phase="PreSimulation"
    if self.RunService.PreSimulation then self.RunService.PreSimulation:Fire(dt)end
    self.Phase="Heartbeat";self.RunService.Heartbeat:Fire(dt)
    local sleepers=self.Sleepers;self.Sleepers={}
    for _,item in ipairs(sleepers)do
        if item.At<=self.Now+1e-9 then self:Resume(item.Thread,dt)
        else self.Sleepers[#self.Sleepers+1]=item end
    end
    self.Phase="idle"
    assert(#self.Errors==0,table.concat(self.Errors,"\n"))
end
function Scheduler:Run(frames,fps)for _=1,frames do self:Tick(1/fps)end end

local function character(sim,name)
    local c=newNode("Model",name);c.Parent=WORLD
    local root=newNode("Part","HumanoidRootPart");root.Parent=c
    local torso=newNode("Part","Torso");torso.Parent=c
    local head=newNode("Part","Head");head.Parent=c
    local owner=newNode("StringValue","PartOwner");owner.Parent=head
    local h=newNode("Humanoid","Humanoid");h.Health=100;h.Parent=c
    local rag=newNode("BoolValue","Ragdolled");rag.Value=false;rag.Parent=h
    return {Character=c,Root=root,Torso=torso,Head=head,Humanoid=h,Ragdolled=rag}
end
local function palletFixture(modules,maximum,pre)
    local sim=Scheduler.new(pre)
    CURRENT_SIGNAL_FACTORY=sim.NewSignal
    local c=character(sim,"Target")
    local model=newNode("Model","RagdollRSC");model.Parent=WORLD
    local sound=newNode("Part","SoundPart");sound.Parent=model
    local main=newNode("Part","Main");main.Parent=model
    local data={Owned=true,Acquires=0,Destroyed=0,Valid=true,CanSpawn=true}
    local pallet=modules.PalletRagdoll.Install({RunService=sim.RunService,Clock=function()return sim.Now end,
        Wait=function(t)return sim:Wait(t)end,SpawnThread=function(fn)sim:Spawn(fn)end,MaximumSpeed=maximum,States={},
        Find=function()return model.Parent and model end,CanSpawn=function()return data.CanSpawn end,
        Spawn=function()return nil end,Owned=function()return data.Owned end,
        Acquire=function()data.Acquires+=1;data.Owned=true;return true end,
        Destroy=function(m)data.Destroyed+=1;m:Destroy()end,
    })
    local function request()return pallet:Request(c.Character,function()return data.Valid end)end
    return {Sim=sim,Target=c,Model=model,Sound=sound,Main=main,Data=data,Pallet=pallet,Request=request}
end


local Vector2={};local v2mt={}
function Vector2.new(x,y)return setmetatable({X=x,Y=y},v2mt)end
v2mt.__add=function(a,b)return Vector2.new(a.X+b.X,a.Y+b.Y)end
v2mt.__sub=function(a,b)return Vector2.new(a.X-b.X,a.Y-b.Y)end
v2mt.__mul=function(a,b)if type(a)=='number'then a,b=b,a end;return Vector2.new(a.X*b,a.Y*b)end
v2mt.__eq=function(a,b)return a.X==b.X and a.Y==b.Y end
v2mt.__index=function(v,k)
 if k=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y)end
 if k=='Unit'then local m=math.sqrt(v.X*v.X+v.Y*v.Y);return Vector2.new(v.X/m,v.Y/m)end
 if k=='Lerp'then return function(a,b,alpha)return a+(b-a)*alpha end end
end
vectorMT.__mul=function(a,b)if type(a)=='number'then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
local oldV3Index=vectorMT.__index
vectorMT.__index=function(v,k)
 if k=='Lerp'then return function(a,b,alpha)return a+(b-a)*alpha end end
 return oldV3Index(v,k)
end
cfMT.__index={
 ToObjectSpace=function(a,b)return CFrame.new(b.Position-a.Position)end,
 Lerp=function(a,b,alpha)return CFrame.new(a.Position:Lerp(b.Position,alpha))end,
}
local UDim2={new=function(xs,xo,ys,yo)return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}}end}
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
local Color3={new=function(r,g,b)return {R=r,G=g,B=b}end,fromRGB=function(r,g,b)return {R=r/255,G=g/255,B=b/255}end}
local Enum={Font={Code='Code'},HighlightDepthMode={AlwaysOnTop='AlwaysOnTop',Occluded='Occluded'}}
local instanceClasses={}
local Instance={new=function(class)local n=newNode(class);instanceClasses[class]=(instanceClasses[class]or 0)+1;return n end}

Vector3.zero=Vector3.new(0,0,0)
local baseVectorIndex=vectorMT.__index
vectorMT.__index=function(v,k)if k=='Unit'then local m=v.Magnitude;return Vector3.new(v.X/m,v.Y/m,v.Z/m)end;return baseVectorIndex(v,k)end
cfMT.__add=function(a,v)return CFrame.new(a.Position+v)end
Enum.RenderPriority={Camera={Value=200}}
