
local checks=0
local function expect(message,value)
    checks+=1
    assert(value,message)
end
local function signal()
    local s={Listeners={}}
    function s:Connect(fn)
        local c={Connected=true,Fn=fn}
        function c:Disconnect()self.Connected=false end
        self.Listeners[#self.Listeners+1]=c;return c
    end
    function s:Fire(...)
        for _,c in ipairs(table.clone(self.Listeners))do if c.Connected then c.Fn(...)end end
    end
    function s:Wait()if self.OnWait then self.OnWait()end end
    return s
end
local vectorMT={}
local Vector3={}
function Vector3.new(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectorMT)end
vectorMT.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vectorMT.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vectorMT.__mul=function(a,b)if type(a)=='number'then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
vectorMT.__div=function(a,b)return Vector3.new(a.X/b,a.Y/b,a.Z/b)end
vectorMT.__eq=function(a,b)return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
vectorMT.__index=function(a,key)
    if key=='Magnitude'then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end
    if key=='Unit'then return a/math.max(a.Magnitude,.001)end
end
Vector3.zero=Vector3.new();Vector3.yAxis=Vector3.new(0,1,0)
local frameMT={};local CFrame={}
function CFrame.new(x,y,z)
    return setmetatable({Position=type(x)=='table'and x or Vector3.new(x,y,z),LookVector=Vector3.new(0,0,-1)},frameMT)
end
function CFrame.Angles()return CFrame.new()end
frameMT.__mul=function(a,b)return CFrame.new(a.Position+b.Position)end
local PhysicalProperties={new=function(...)return {...}end}
local Enum={HumanoidStateType={},Material={Air='Air'},RaycastFilterType={Exclude='Exclude'}}
for _,key in ipairs({'Ragdoll','FallingDown','Physics','PlatformStanding','GettingUp','Freefall','Running','Jumping'})do Enum.HumanoidStateType[key]=key end
local methods={};local objectMT={}
local Instance={};local allObjects={}
local base={Part=true,MeshPart=true,Seat=true,VehicleSeat=true}
function Instance.new(class,parent)
    local obj=setmetatable({_props={ClassName=class,Name=class,Enabled=true,Health=100,HipHeight=0,
        Sit=false,RequiresNeck=true,AutoRotate=true,PlatformStand=false,FloorMaterial='Ground',
        CanCollide=true,CanTouch=true,Anchored=false,AssemblyMass=10,ReceiveAge=0,
        AssemblyLinearVelocity=Vector3.zero,AssemblyAngularVelocity=Vector3.zero,
        Position=Vector3.zero,CFrame=CFrame.new(),Value=false},_children={},_signals={},_states={}},objectMT)
    obj._props.Changed=signal();obj._props.DescendantAdded=signal();obj._props.ChildAdded=signal()
    if base[class]then obj._props.AssemblyRootPart=obj end
    allObjects[#allObjects+1]=obj
    if parent then obj.Parent=parent end
    return obj
end
objectMT.__index=function(o,k)return methods[k]or o._props[k]end
objectMT.__newindex=function(o,k,v)
    local old=o._props[k]
    if old==v then return end
    if k=='Parent'then
        if old then local i=table.find(old._children,o);if i then table.remove(old._children,i)end end
        o._props[k]=v
        if v then
            v._children[#v._children+1]=o;v.ChildAdded:Fire(o)
            local ancestor=v
            while ancestor do ancestor.DescendantAdded:Fire(o);ancestor=ancestor.Parent end
        end
    else
        o._props[k]=v
        if k=='CFrame'then o._props.Position=v.Position end
        if k=='Position'then o._props.CFrame=CFrame.new(v)end
    end
    if o._signals[k]then o._signals[k]:Fire()end
    o.Changed:Fire(k)
end
function methods:IsA(class)return self.ClassName==class or class=='BasePart'and base[self.ClassName]==true end
function methods:GetChildren()return table.clone(self._children)end
function methods:GetDescendants()
    local list={}
    local function walk(p)for _,v in ipairs(p._children)do list[#list+1]=v;walk(v)end end
    walk(self);return list
end
function methods:FindFirstChild(name,recursive)
    for _,v in ipairs(self._children)do if v.Name==name then return v end end
    if recursive then for _,v in ipairs(self._children)do local found=v:FindFirstChild(name,true);if found then return found end end end
end
function methods:FindFirstChildWhichIsA(class,recursive)
    for _,v in ipairs(self._children)do if v:IsA(class)then return v end end
    if recursive then for _,v in ipairs(self._children)do local found=v:FindFirstChildWhichIsA(class,true);if found then return found end end end
end
methods.FindFirstChildOfClass=methods.FindFirstChildWhichIsA
function methods:IsDescendantOf(parent)local v=self.Parent;while v do if v==parent then return true end;v=v.Parent end;return false end
function methods:GetConnectedParts()return self.ConnectedParts or {}end
function methods:GetPropertyChangedSignal(name)if not self._signals[name]then self._signals[name]=signal()end;return self._signals[name]end
function methods:Destroy()
    if self.Destroyed then return end
    self.Destroyed=true
    for _,v in ipairs(self:GetChildren())do v:Destroy()end
    self.Parent=nil
end
function methods:GetStateEnabled(state)local v=self._states[state];return v==nil or v end
function methods:SetStateEnabled(state,value)self._states[state]=value end
function methods:GetState()return self.State or 'Running'end
function methods:ChangeState(state)self.State=state end
function methods:FireServer(...)if self.OnFire then self.OnFire(...)end end
local OverlapParams={new=function()return {}end}
local function object(class,name,parent)local o=Instance.new(class);o.Name=name;o.Parent=parent;return o end
local function avatar(world,name,x)
    local c=object('Model',name,world)
    local root=object('Part','HumanoidRootPart',c);root.Position=Vector3.new(x,0,0)
    local torso=object('Part','Torso',c);torso.Position=root.Position
    local leg=object('Part','Right Leg',c);leg.Position=root.Position
    local h=object('Humanoid','Humanoid',c)
    local rag=object('BoolValue','Ragdolled',h)
    local motor=object('Motor6D','Right Hip',torso);motor.Part0=torso;motor.Part1=leg
    local att=object('Attachment','RootAttachment',root)
    return c,root,h,rag,leg,motor,att
end
local function fixture()
    local f={Now=0,Jobs={},Ragdolls={},Spawns=0,Destroyed=0,Eats=0,Reserved={},Protected=false,Owned=true,Recovers=0}
    f.World=object('Folder','Workspace')
    f.Players=object('Folder','Players')
    f.Player=object('Player','Local',f.Players);f.Other=object('Player','Other',f.Players)
    f.C,f.R,f.H,f.Rag,f.Leg,f.Motor,f.Att=avatar(f.World,'Local',0);f.Player.Character=f.C
    f.TC,f.TR,f.TH,f.TRag,f.TLeg,f.TMotor,f.TAtt=avatar(f.World,'Other',10);f.Other.Character=f.TC
    f.Inventory=object('Folder','LocalSpawnedInToys',f.World)
    f.Toys=object('Folder','OtherSpawnedInToys',f.World)
    f.Blob=object('Model','CreatureBlobman',f.Toys)
    f.Seat=object('VehicleSeat','VehicleSeat',f.Blob);f.Seat.Position=Vector3.new(10,0,0)
    f.Body=object('Part','HumanoidRootPart',f.Blob);f.Body.Position=f.Seat.Position
    f.Body.AssemblyLinearVelocity=Vector3.new(3,2,1)
    f.Left=object('Part','LeftDetector',f.Blob);f.Right=object('Part','RightDetector',f.Blob)
    f.LeftWeld=object('RigidConstraint','LeftWeld',f.Left);f.RightWeld=object('RigidConstraint','RightWeld',f.Right)
    f.Ori=object('AlignOrientation','RightAlignOrientation',f.Right)
    f.Script=object('Folder','BlobmanSeatAndOwnerScript',f.Blob)
    f.Drop=object('RemoteEvent','CreatureDrop',f.Script)
    f.Grab=object('RemoteEvent','CreatureGrab',f.Script)
    f.Release=object('RemoteEvent','CreatureRelease',f.Script)
    f.Pre=signal();f.Heartbeat=signal()
    f.RunService={PreSimulation=f.Pre,Heartbeat=f.Heartbeat}
    f.Character=function(player)
        if player==f.Other then return f.Other.Character,f.Other.Character and f.TR,f.Other.Character and f.TH end
        return f.Player.Character,f.Player.Character and f.R,f.Player.Character and f.H
    end
    function f.World:GetPartBoundsInRadius(position,radius,query)
        local parts={}
        for _,part in ipairs(self:GetDescendants())do
            if part:IsA('BasePart')and not part:IsDescendantOf(query.FilterDescendantsInstances[1])and(part.Position-position).Magnitude<=radius then parts[#parts+1]=part end
        end
        return parts
    end
    function f:RunJobs()while #self.Jobs>0 do table.remove(self.Jobs,1)()end end
    function f:SeatOther()self.TH.SeatPart=self.Seat;self.Seat.Occupant=self.TH end
    function f:SeatLocal()self.H.SeatPart=self.Seat;self.Seat.Occupant=self.H;self.H.Sit=true end
    function f:SpawnBanana()
        self.Spawns+=1
        local model=object('Model','FoodBanana',self.Inventory)
        local root=object('Part','Main',model)
        local hit=object('Part','HitboxPart',model);hit.AssemblyRootPart=root
        root.ConnectedParts={hit}
        self.LastBanana=model;self.Peel=root
        if self.SpawnHook then self.SpawnHook(model,root)end
        return model
    end
    f.DefenseContext={RunService=f.RunService,Clock=function()return f.Now end,Player=f.Player,Character=f.Character,
        Models=function()return {f.Blob}end,
        PlayerForCharacter=function(c)return c==f.Other.Character and f.Other or c==f.Player.Character and f.Player end,
        Protected=function()return f.Protected end,
        Ragdoll=function(c,valid)f.Ragdolls[#f.Ragdolls+1]={Character=c,Valid=valid}end,
        SpawnThread=function(fn)f.Jobs[#f.Jobs+1]=fn end,CanSpawn=function()return f.CanSpawn~=false end,
        SpawnBanana=function()return f:SpawnBanana()end,
        Eat=function(model)f.Eats+=1;if f.EatHook then return f.EatHook(model)end;return model end,
        Owned=function()return f.Owned end,Acquire=function()end,
        Reserve=function(m,value)f.Reserved[m]=value or nil end,
        Destroy=function(m)f.Destroyed+=1;m:Destroy()end}
    return f
end
local modules={}
local function requireModule(name)return assert(modules[name],name)end
