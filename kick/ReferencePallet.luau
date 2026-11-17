-- ReferenceTrajectory: pallet motion transferred from the supplied message.txt.
-- Eight downward source stages, -9997 descent, -10 impact, then a real exit.
-- Faster profiles schedule complete passes, not a predicted server kick time.
local requireModule=...
local Ownership=requireModule("PalletOwnership")
local Pallet={};Pallet.__index=Pallet
local function alive(part)return part and part.Parent and part:IsA("BasePart")end
local function characterRoot(character)
    local root=character and character.Parent and character:FindFirstChild("HumanoidRootPart")
    local hum=character and character:FindFirstChildOfClass("Humanoid")
    return alive(root)and hum and hum.Health>0 and root or nil,hum
end
local function ragdolled(character)
    local _,hum=characterRoot(character);local value=hum and hum:FindFirstChild("Ragdolled")
    return value and value:IsA("BoolValue")and value.Value==true
end
local function isolated(sound,model)
    local assembly=sound and(sound.AssemblyRootPart or sound)
    if not alive(assembly)or assembly.Anchored or not assembly:IsDescendantOf(model)then return end
    if assembly.GetConnectedParts then
        for _,part in ipairs(assembly:GetConnectedParts(true))do if not part:IsDescendantOf(model)then return end end
    end
    return assembly
end
function Pallet.Install(context)
    local self=setmetatable({Context=context,Entries={},Queue={},Pauses={},PhysicsFrame=0,Passes=0,StrikeAttempts=0,
        Confirmed=0,MaximumSpeed=true,IntervalSeconds=1/50,ContactRate=50,Status="Ragdoll idle",PartState={},Generation=0},Pallet)
    self.FrameSignal=context.RunService.PreSimulation or context.RunService.Heartbeat
    self.PhysicsSignal=context.RunService.PostSimulation or context.RunService.Heartbeat
    self.Ownership=Ownership.new({Clock=context.Clock,Signal=self.FrameSignal,
        MarkerOwned=context.MarkerOwned or context.Owned,PhysicsOwned=context.PhysicsOwned or context.Owned,
        Grab=context.Grab,Busy=context.OwnershipBusy,Approach=context.Acquire,
        NeedsApproach=context.NeedsApproach,PingSeconds=context.PingSeconds})
    self.Connection=self.FrameSignal:Connect(function()
        if self.Closed then return end
        local ok,why=pcall(self.Step,self)
        if not ok then self.LastError=tostring(why);self.Status="Ragdoll error: "..self.LastError;self:Clear()end
    end)
    self.PhysicsConnection=self.PhysicsSignal:Connect(function(dt)
        -- A rendered frame with zero simulation time is not another contact.
        if type(dt)=="number"and dt==dt and dt>0 and dt<math.huge then self.PhysicsFrame+=1 end
    end)
    self:SetContactRate(context.ContactRate or 50)
    return self
end
function Pallet:Valid(entry)
    local root=entry and characterRoot(entry.Character)
    if self.Closed or not root or root~=entry.Root or root.Anchored or entry.Done then return false end
    if entry.Valid then local ok,value=pcall(entry.Valid);return ok and value==true end
    return true
end
function Pallet:Style()
    if not self.Model then return end
    for _,part in ipairs(self.Model:GetDescendants())do if part:IsA("BasePart")then
        if not self.PartState[part]then self.PartState[part]={Transparency=part.Transparency,CanCollide=part.CanCollide,CanQuery=part.CanQuery,CanTouch=part.CanTouch}end
        part.Transparency=1;part.CanCollide=false;part.CanQuery=false
    end end
    if alive(self.Sound)then self.Sound.CanTouch=true end
end
function Pallet:Restore()
    for part,props in pairs(self.PartState)do if part.Parent then for key,value in pairs(props)do part[key]=value end end end
    table.clear(self.PartState)
end
function Pallet:Park()
    local sound=self.Sound;local model=self.Model;local assembly=alive(sound)and isolated(sound,model)
    if not assembly then return end
    if self.Context.Owned(sound)then
        local point=self.Context.ParkPosition and self.Context.ParkPosition()or Vector3.new(0,1000,0)
        local offset=assembly==sound and CFrame.new()or sound.CFrame:ToObjectSpace(assembly.CFrame)
        assembly.CFrame=CFrame.new(point)*offset
        assembly.AssemblyLinearVelocity=Vector3.zero;assembly.AssemblyAngularVelocity=Vector3.zero
    end
end
function Pallet:Prepare(valid)
    local generation=self.Generation
    local function current()return not self.Closed and self.Generation==generation and not next(self.Pauses)and(not valid or valid())end
    if not current()then return false end
    if alive(self.Sound)and isolated(self.Sound,self.Model)and self.Context.Owned(self.Sound)then self.NativeKickReady=true;return true end
    if self.Preparing then return false end
    self.Preparing=true
    local ok,result=pcall(function()
        local model=self.Model and self.Model.Parent and self.Model or self.Context.Find()
        if not model then
            local allowed,why=self.Context.CanSpawn()
            if not allowed then self.Status=why or "Waiting to spawn pallet";return false end
            model=self.Context.Spawn(current)
        end
        if not model or not model.Parent or not current()then return false end
        if self.Model~=model then self:Restore();self.Model=model end
        local deadline=self.Context.Clock()+.75
        local sound,main
        repeat
            sound=model:FindFirstChild("SoundPart");main=model:FindFirstChild("Main")
            if alive(sound)and alive(main)then break end
            if not current()or not model.Parent or self.Context.Clock()>=deadline then return false end
            self.Context.Wait()
        until false
        if not isolated(sound,model)then self.Status="Pallet is attached to another assembly";return false end
        self.Sound,self.Main=sound,main
        if self.Context.Reserve then self.Context.Reserve(model,true)end
        if not self.Context.Owned(sound)then
            local acquired,why=self.Ownership:Acquire(sound,current)
            if not acquired then self.Status=why or "Waiting for pallet ownership";return false end
        end
        if not current()or not alive(sound)or not self.Context.Owned(sound)then return false end
        self:Style();self.NativeKickReady=true;self.Status="Reference ragdoll ready";return true
    end)
    self.Preparing=false
    if not ok then self.LastError=tostring(result);self.Status="Pallet preparation: "..self.LastError;return false end
    return result==true
end
function Pallet:Warm()
    if self.Closed or self.Preparing or self.Warming or next(self.Pauses)then return end
    local now=self.Context.Clock();if now<(self.NextWarm or 0)then return end
    self.NextWarm=now+.25;self.Warming=true;local generation=self.Generation
    self.Context.SpawnThread(function()
        local ok,why=pcall(self.Prepare,self,function()return not self.Closed and self.Generation==generation and not next(self.Pauses)end)
        self.Warming=false;if not ok then self.LastError=tostring(why)end
    end)
end
function Pallet:Request(character,valid,continuous,manual)
    local root=characterRoot(character)
    if self.Closed or not root or root.Anchored or next(self.Pauses)or(valid and not valid())then return end
    local old=self.Entries[character]
    if old and old.Root~=root then self:Cancel(character);old=nil end
    if old then
        if manual and old.Continuous and old.Manual==false then return old end
        old.Valid=valid or old.Valid;old.Continuous=old.Continuous or continuous
        if manual~=nil then old.Manual=manual end
        return old
    end
    local entry={Character=character,Root=root,Valid=valid,Continuous=continuous==true,Manual=manual,Stage=0,Phase="down",Started=self.Context.Clock(),NextAt=0}
    self.Entries[character]=entry;self.Queue[#self.Queue+1]=entry;self:Warm();return entry
end
function Pallet:SourceContact(character,valid)return self:Request(character,valid,true,false)~=nil end
function Pallet:Maintain(character,valid)return self:Request(character,valid,true)end
function Pallet:Apply(character,valid)
    if ragdolled(character)then return true end
    local entry=self:Request(character,valid,false);if not entry then return false end
    local deadline=self.Context.Clock()+4
    while self:Valid(entry)and not entry.Done and self.Context.Clock()<deadline do
        if ragdolled(character)then self.Confirmed+=1;entry.Success=true;if not entry.Continuous then self:Cancel(character,true)end;return true end
        self.Context.Wait()
    end
    if not entry.Continuous then self:Cancel(character)end
    return entry.Success==true
end
function Pallet:Profile(entry)
    local mode=self.Context.KickMode and self.Context.KickMode()or "Faster"
    -- Kick and continuous Loop Ragdoll share the selected Super Fast cadence.
    -- A single-use ragdoll still completes the donor trajectory and observes
    -- the game's Ragdolled state; extra requests never create another worker.
    if mode=="Super Fast"and entry.Continuous then return 1,0,self.IntervalSeconds end
    if entry.Manual or not entry.Continuous then return 8,1/60,0 end
    if mode=="Normal"then return 8,math.max(1/60,self.IntervalSeconds*.5),0 end
    return 2,0,.06 -- the v5.01 Super Fast profile is now Faster
end
function Pallet:Place(entry,point,velocity)
    local assembly=isolated(self.Sound,self.Model)
    if not assembly or not self.Context.Owned(self.Sound)or not self:Valid(entry)then return false end
    local offset=assembly==self.Sound and CFrame.new()or self.Sound.CFrame:ToObjectSpace(assembly.CFrame)
    assembly.CFrame=CFrame.new(point)*offset
    assembly.AssemblyLinearVelocity=velocity;assembly.AssemblyAngularVelocity=Vector3.zero
    self.LastPlacementFrame=self.PhysicsFrame
    return true
end
function Pallet:Step()
    if self.Closed or next(self.Pauses)then return end
    local now=self.Context.Clock()
    for character,entry in pairs(self.Entries)do
        if not self:Valid(entry)or not entry.Continuous and now-entry.Started>=4 then self:Cancel(character)end
    end
    if not self.Active then
        local count=#self.Queue
        for _=1,count do
            local entry=table.remove(self.Queue,1)
            if self:Valid(entry)then
                local segments=self:Profile(entry)
                local due=segments==1 and math.max(entry.NextAt,self.NextFastPassAt or 0)or entry.NextAt
                if now+1e-7>=due then self.Active=entry;break else self.Queue[#self.Queue+1]=entry end
            end
        end
    end
    local entry=self.Active;if not entry then return end
    if not alive(self.Sound)or not isolated(self.Sound,self.Model)or not self.Context.Owned(self.Sound)then
        self.NativeKickReady=false;self.Active=nil;entry.Stage=0;entry.Phase="down";entry.StartFrame=nil
        self.Queue[#self.Queue+1]=entry;self:Warm();return
    end
    if self.Preparing then return end
    self:Style()
    if now>=(self.RefreshAt or 0)and self.Context.RefreshOwnership then
        self.RefreshAt=now+1
        pcall(self.Context.RefreshOwnership,self.Sound)
    end
    -- No new entry or return can be overwritten before a solver step. This
    -- also prevents two callbacks on one Heartbeat fallback from making hits.
    if entry.LastFrame==self.PhysicsFrame or self.LastPlacementFrame==self.PhysicsFrame then return end
    local segments,step,period=self:Profile(entry)
    if step>0 and now+1e-7<(entry.StepAt or 0)then return end
    entry.StepAt=now+step;entry.LastFrame=self.PhysicsFrame
    if entry.Phase=="return"then
        if not self:Place(entry,entry.Root.Position+Vector3.new(0,10000,0),Vector3.zero)then return end
        entry.ExitFrame=self.PhysicsFrame;entry.Stage=0;entry.Phase="down";entry.StartFrame=nil
        local deadline=(entry.CycleAnchor or entry.PassStarted)+period
        entry.NextAt=deadline>now and deadline or now
        entry.CycleAnchor=entry.NextAt
        self.Active=nil;self.Queue[#self.Queue+1]=entry;return
    end
    if entry.ExitFrame and self.PhysicsFrame<=entry.ExitFrame then return end
    if entry.Stage==0 then entry.PassStarted=now;entry.CycleAnchor=entry.CycleAnchor or now end
    entry.Stage+=1
    local point=(entry.Root.Position+Vector3.new(0,10000,0)):Lerp(entry.Root.Position,entry.Stage/segments)
    if not self:Place(entry,point,Vector3.new(0,entry.Stage>=segments and -10 or -9997,0))then return end
    self.StrikeAttempts+=1
    if entry.Stage>=segments then
        if segments==1 then
            local expected=self.NextFastPassAt or now
            self.LastFastPassTime=now
            self.NextFastPassAt=now-expected>=period and now+period or expected+period
        end
        self.Passes+=1;entry.Passes=(entry.Passes or 0)+1;entry.Phase="return"
        self.Status="Reference pallet impact placement; awaiting physics"
    end
end
function Pallet:Cancel(character,success)
    local entry=self.Entries[character];if not entry then return end
    self.Entries[character]=nil;entry.Done=true;entry.Success=success==true or entry.Success
    if self.Active==entry then self.Active=nil;self:Park()end
    for i=#self.Queue,1,-1 do if self.Queue[i]==entry then table.remove(self.Queue,i)end end
    if not next(self.Entries)then
        self.Generation+=1;self:Park();self:Restore();self.NativeKickReady=false
        local model=self.Model;self.Model=nil;self.Sound=nil;self.Main=nil
        if model and model.Parent then local ok,why=pcall(self.Context.Destroy,model);if not ok then self.LastError=tostring(why)end end
    end
end
function Pallet:Clear()
    local characters={};for character in pairs(self.Entries)do characters[#characters+1]=character end
    for _,character in ipairs(characters)do self:Cancel(character)end
end
function Pallet:StopMaintaining(character)self:Cancel(character)end
function Pallet:Pause(token,value)
    if value then self.Pauses[token]=true;self:Park()
    else self.Pauses[token]=nil end
end
function Pallet:IsContactActive()return self.Active~=nil end
function Pallet:IsSuperMode()return self.Context.KickMode and self.Context.KickMode()=="Super Fast"end
function Pallet:SetKickMode()
    self:Park();self.Active=nil;table.clear(self.Queue)
    self.NextFastPassAt=nil;self.LastFastPassTime=nil
    for _,entry in pairs(self.Entries)do entry.Stage=0;entry.Phase="down";entry.NextAt=0;entry.CycleAnchor=nil;entry.LastFrame=self.PhysicsFrame;entry.ExitFrame=self.PhysicsFrame;self.Queue[#self.Queue+1]=entry end
end
function Pallet:SetContactRate(value)
    if type(value)~="number"or value~=value or math.abs(value)==math.huge then return end
    self.ContactRate=math.clamp(value,5,50);self.IntervalSeconds=1/self.ContactRate
    self.NextFastPassAt=self.LastFastPassTime and self.LastFastPassTime+self.IntervalSeconds or nil
    if self:IsSuperMode()then
        for _,entry in pairs(self.Entries)do
            if entry.Continuous then entry.NextAt=self.NextFastPassAt or 0;entry.CycleAnchor=nil end
        end
    end
end
function Pallet:Evidence()
    local targets={};for _,entry in pairs(self.Entries)do targets[#targets+1]={Name=entry.Character.Name,Stage=entry.Stage,Phase=entry.Phase,Passes=entry.Passes or 0,Continuous=entry.Continuous}end
    return {Mechanism="ReferenceTrajectory",PlacementAttempts=self.StrikeAttempts,CompletedPasses=self.Passes,ConfirmedRagdollStates=self.Confirmed,
        FastPassPeriod=.06,SuperFastPassPeriod=self.IntervalSeconds,RequestedSuperFastPassRate=self.ContactRate,
        SuperFastMinimumPhysicsFrames=2,ContinuousRagdollFollowsSuperFast=true,PhysicalFrames=self.PhysicsFrame,Targets=targets,LastError=self.LastError}
end
function Pallet:Summary()return string.format("%s | source passes: %d | placements: %d",self.Status,self.Passes,self.StrikeAttempts)end
function Pallet:Dispose()
    if self.Closed then return end
    self:Clear();self:Park();self:Restore();self.Closed=true
    self.Connection:Disconnect();self.PhysicsConnection:Disconnect()
    if self.Ownership.Dispose then self.Ownership:Dispose()end
    if self.Model and self.Model.Parent then self.Context.Destroy(self.Model)end
end
return Pallet
