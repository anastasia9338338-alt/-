-- Deliberately small rigid-body mock: only velocity integration may generate
-- contacts. A teleport directly into a trigger never counts as a physical hit.
-- This checks lifecycle and stroke invariants, not Roblox/server validation.
local checks=0
local function check(ok,message)assert(ok,message);checks+=1 end
local Vector3={};local V={}
function Vector3.new(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},V)end
V.__index=function(v,k)
    if k=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end
    if k=='Unit'then return v/v.Magnitude end
end
V.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
V.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
V.__mul=function(a,b)if type(a)=='number'then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
V.__div=function(a,b)return a*(1/b)end
Vector3.zero=Vector3.new()
local CFrame={};local CF={}
function CFrame.new(x,y,z)
    return setmetatable({Position=type(x)=='table'and x or Vector3.new(x,y,z),
        RightVector=Vector3.new(1,0,0),UpVector=Vector3.new(0,1,0),LookVector=Vector3.new(0,0,-1)},CF)
end
CF.__add=function(cf,v)return CFrame.new(cf.Position+v)end
local Node={}
Node.__index=function(n,k)
    if k=='Parent'then return rawget(n,'_parent')end
    if k=='CFrame'then return rawget(n,'_cf')end
    if k=='Position'then return rawget(n,'_cf').Position end
    return Node[k]
end
local function translate(n,delta)
    rawset(n,'_cf',n.CFrame+delta)
    for _,part in ipairs(n.AssemblyMembers or {})do if part~=n then rawset(part,'_cf',part.CFrame+delta)end end
end
Node.__newindex=function(n,k,v)
    if k=='Parent'then
        local previous=rawget(n,'_parent')
        if previous and previous.Children then local i=table.find(previous.Children,n);if i then table.remove(previous.Children,i)end end
        rawset(n,'_parent',v)
        if v and v.Children then table.insert(v.Children,n)end
    elseif k=='CFrame'or k=='Position'then
        local position=k=='CFrame'and v.Position or v
        rawset(n,'Teleports',(n.Teleports or 0)+1)
        translate(n,position-n.Position)
    else rawset(n,k,v)end
end
function Node:IsA(class)return self.ClassName==class or class=='BasePart'and self.ClassName=='Part'end
function Node:FindFirstChild(name)for _,v in ipairs(self.Children)do if v.Name==name then return v end end end
function Node:FindFirstChildOfClass(class)for _,v in ipairs(self.Children)do if v:IsA(class)then return v end end end
function Node:WaitForChild(name)return self:FindFirstChild(name)end
function Node:GetChildren()return table.clone(self.Children)end
function Node:IsDescendantOf(ancestor)local p=self.Parent;while p do if p==ancestor then return true end;p=p.Parent end;return false end
function Node:Destroy()for _,v in ipairs(self:GetChildren())do v:Destroy()end;self.Parent=nil end
local WORLD={}
local currentSim
local function newNode(class,name,parent)
    local n=setmetatable({ClassName=class,Name=name or class,Children={},_cf=CFrame.new(),Size=Vector3.new(2,2,1),
        CanTouch=true,CanCollide=true,Anchored=false,AssemblyLinearVelocity=Vector3.zero,AssemblyAngularVelocity=Vector3.zero},Node)
    if class=='Part'then n.Touched=currentSim:Signal()end
    n.Parent=parent
    return n
end
local Instance={new=function(class)return newNode(class)end}
local Sim={};Sim.__index=Sim
function Sim.new(pre)
    local s=setmetatable({Now=0,Sleepers={},Errors={}},Sim)
    s.RunService={Heartbeat=s:Signal()}
    if pre~=false then s.RunService.PreSimulation=s:Signal()end
    return s
end
function Sim:Signal()
    local signal={Listeners={},Waiters={},Sim=self}
    function signal:Connect(fn)
        local c={Connected=true,Fn=fn}
        function c:Disconnect()self.Connected=false end
        table.insert(self.Listeners,c);return c
    end
    function signal:Wait()return coroutine.yield({Signal=self})end
    function signal:Fire(dt)
        local waiters=self.Waiters;self.Waiters={}
        for _,c in ipairs(table.clone(self.Listeners))do if c.Connected then self.Sim:Spawn(c.Fn,dt)end end
        for _,co in ipairs(waiters)do self.Sim:Resume(co,dt)end
    end
    return signal
end
function Sim:Resume(co,...)
    local ok,value=coroutine.resume(co,...)
    if not ok then table.insert(self.Errors,tostring(value));return end
    if coroutine.status(co)=='dead'then return end
    if value.Signal then table.insert(value.Signal.Waiters,co)
    else table.insert(self.Sleepers,{Co=co,At=value.At})end
end
function Sim:Spawn(fn,...)self:Resume(coroutine.create(fn),...)end
function Sim:Wait(dt)return coroutine.yield({At=self.Now+(dt or self.Dt or 1/60)})end
function Sim:Tick(dt)
    self.Now+=dt;self.Dt=dt
    if self.Before then self.Before(dt)end
    if self.RunService.PreSimulation then self.RunService.PreSimulation:Fire(dt)end
    if self.Physics then self.Physics(dt)end
    self.RunService.Heartbeat:Fire(dt)
    local sleepers=self.Sleepers;self.Sleepers={}
    for _,v in ipairs(sleepers)do if v.At<=self.Now+1e-7 then self:Resume(v.Co,dt)else table.insert(self.Sleepers,v)end end
    check(#self.Errors==0,table.concat(self.Errors,'\n'))
end
function Sim:Run(seconds,fps)for _=1,math.ceil(seconds*fps)do self:Tick(1/fps)end end
local function target(name,position)
    local t={};t.Character=newNode('Model',name,WORLD)
    t.Torso=newNode('Part','Torso',t.Character);t.Torso.Position=position or Vector3.new(0,15,0)
    t.Head=newNode('Part','Head',t.Character);newNode('StringValue','PartOwner',t.Head)
    t.Humanoid=newNode('Humanoid','Humanoid',t.Character);t.Humanoid.Health=100
    t.Flag=newNode('BoolValue','Ragdolled',t.Humanoid);t.Flag.Value=true
    return t
end
local function fixture(Pallet,pre)
    local sim=Sim.new(pre);currentSim=sim
    local t=target('First');local model=newNode('Model','RagdollRSC',WORLD)
    local sound=newNode('Part','SoundPart',model);sound.Size=Vector3.new(6,.5,4)
    local main=newNode('Part','Main',model);main.Position=Vector3.new(20,10,0)
    sound.Position=main.Position+Vector3.new(0,.25,0)
    sound.AssemblyRootPart=main;main.AssemblyRootPart=main;main.AssemblyMembers={main,sound}
    local data={Valid=true,Owned=true,Acquire=true,Targets={t},Crossings={},Spawns=0,Acquires=0,Destroyed=0,Accept=true}
    local function overlap(part,other)
        local delta=part.Position-other.Position;local half=(part.Size+other.Size)*.5
        return math.abs(delta.X)<half.X and math.abs(delta.Y)<half.Y and math.abs(delta.Z)<half.Z
    end
    sim.Physics=function(dt)
        if not main.Parent or not data.Owned then return end
        local before={};for _,p in ipairs(data.Targets)do before[p]=overlap(sound,p.Torso)end
        local mover=main:FindFirstChild('RagdollBP')
        if mover and mover.MaxForce.Magnitude>0 then
            -- Exposes the old opposing lift instead of treating placements as hits.
            translate(main,Vector3.new(0,1000*dt,0))
        elseif not data.Blocked then translate(main,main.AssemblyLinearVelocity*dt)end
        for _,p in ipairs(data.Targets)do
            if sound.CanTouch and not before[p]and overlap(sound,p.Torso)then
                data.Crossings[#data.Crossings+1]={Target=p,At=sim.Now,Velocity=sound.AssemblyLinearVelocity-p.Torso.AssemblyLinearVelocity,
                    Lift=mover and mover.MaxForce.Magnitude or 0}
                if data.Accept then sound.Touched:Fire(p.Torso)end
            end
        end
    end
    local controller=Pallet.Install({RunService=sim.RunService,Clock=function()return sim.Now end,
        Wait=function(ti)return sim:Wait(ti)end,SpawnThread=function(fn)sim:Spawn(fn)end,MaximumSpeed=true,States={},
        Find=function()return model.Parent and model end,CanSpawn=function()return true end,
        Spawn=function()data.Spawns+=1;return nil end,Owned=function()return data.Owned end,
        Acquire=function()data.Acquires+=1;data.Owned=data.Acquire and data.Ack~=false;return data.Acquire end,
        Destroy=function(m)data.Destroyed+=1;m:Destroy()end,
        ParkPosition=function()return Vector3.new(15,8,-12)end,
    })
    return {Sim=sim,Target=t,Model=model,Sound=sound,Main=main,Data=data,Pallet=controller,Valid=function()return data.Valid end}
end
