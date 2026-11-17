local requireModule=...
local Handoff=requireModule("KickHandoff")
-- Existing hold movers run before physics. Target ownership requests use
-- bounded source sequences after confirmed capture; pallet strikes are independent.
local Loop={};Loop.__index=Loop
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
function Loop.Install(context)
    local self=setmetatable({Context=context,Sessions={},Cleanup={},InFlight=0,Status="Kick idle",NextStatus=0,MaximumSpeed=context.MaximumSpeed==true,Frame=0,Calls=0,Released=0},Loop)
    local available,physics=pcall(function()return context.RunService.PreSimulation end)
    local signal=available and physics or context.RunService.Heartbeat
    self.Connection=signal:Connect(function(dt)
        self:FlushCleanup()
        -- Request phases advance on their own clock. A release and its next
        -- Grab occupy different ticks in the legacy path. Source modes own their
        -- ordered refresh batches after the initial capture acknowledgement.
        local now=context.Clock()
        local nextAt=self.NextNativeAt or now
        self.NativeTick=now+1e-7>=nextAt
        if self.NativeTick then
            self.Frame+=1
            self.NextNativeAt=now-nextAt>=1/60 and now+1/60 or nextAt+1/60
            self:FlushReleases()
        end
        if self.Closed then
            self:ReleaseCaptureMovement()
            if not next(self.Cleanup)and self.InFlight==0 or context.Clock()>=self.CloseDeadline then self.Connection:Disconnect()end
            return
        end
        local ok,err=pcall(self.Step,self,dt)
        if not ok then self.LastError=tostring(err);self.Status="Kick error: "..self.LastError;self:Clear()end
        self:ReleaseCaptureMovement()
    end)
    local hasPost,post=pcall(function()return context.RunService.PostSimulation end)
    local postSignal=hasPost and post or context.RunService.Heartbeat
    self.DistinctPhysicsPhases=postSignal~=signal
    self.PostConnection=postSignal:Connect(function()
        if self.Closed then return end
        local ok,err=pcall(self.AfterPhysics,self)
        if not ok then self.LastError=tostring(err);self.Status="Kick error: "..self.LastError;self:Clear()end
    end)
    return self
end
function Loop:RagdollRequired()return self.Context.RagdollEnabled()end
function Loop:Compatibility()return not self.MaximumSpeed and self.Context.FastMode()end
function Loop:ReleaseCaptureMovement()
    if self.CaptureMovementPending and self.Context.ReleaseCaptureMovement and self.InFlight==0 and not next(self.Sessions)then
        local ok,released=pcall(self.Context.ReleaseCaptureMovement)
        if ok and released~=false then self.CaptureMovementPending=nil
        elseif not ok then self.CleanupError='Capture movement restore: '..tostring(released)end
    end
end
function Loop:BeginExcursion(token)
    if self.Closed or self.Excursion then return false end
    for _,session in pairs(self.Sessions)do if session.Acquiring then return false end end
    local excursion={Token=token,Goals={}}
    for _,session in pairs(self.Sessions)do excursion.Goals[session]=session.Position.Position end
    self.Excursion=excursion
    if self.Context.PausePallet then self.Context.PausePallet(token,true)end
    return true
end
function Loop:EndExcursion(token)
    if not self.Excursion or self.Excursion.Token~=token then return end
    self.Excursion=nil
    if self.Context.PausePallet then self.Context.PausePallet(token,false)end
    local now=self.Context.Clock()
    for _,s in pairs(self.Sessions)do s.NextGrab=now end
end
function Loop:Valid(session)
    if self.Closed or self.Sessions[session.Player]~=session or not self.Context.Enabled()then return false end
    if not self.Context.Selected(session.Player)then return false end
    local c,r,h=self.Context.Character(session.Player)
    return c==session.Character and r==session.Root and h==session.Humanoid and h and h.Health>0 and r.Parent~=nil
end
-- Read-only compatibility for Gucci/effect guards; this is not another hold
-- controller and does not equate a queued request with a captured target.
function Loop:IsHolding(player)
    local session=self.Sessions[player]
    if not session or not self:Valid(session)or session.Acquiring then return false end
    local _,localRoot,hum=self.Context.LocalCharacter()
    if not localRoot or not hum or hum.Health<=0 then return false end
    local root,mover=session.Root,session.Position
    if root.Anchored or not mover or mover.Parent~=root then return false end
    local distance=(root.Position-mover.Position).Magnitude
    return finite(distance)and distance<=6 and self.Context.Owned(root)==true
end
-- Stable physical hold evidence for the independent pallet. A deliberately
-- released PartOwner marker is not loss of locally simulated airborne hold.
function Loop:IsPhysicallyHolding(player)
    local session=self.Sessions[player]
    if not session or not self:Valid(session)or session.Acquiring then return false end
    local _,actor,hum=self.Context.LocalCharacter()
    if not actor or not hum or hum.Health<=0 then return false end
    local root,mover=session.Root,session.Position
    if root.Anchored or not mover or mover.Parent~=root then return false end
    local owned
    if self.Context.NetworkOwned then owned=self.Context.NetworkOwned(root)else owned=self.Context.Owned(root)end
    local distance=(root.Position-mover.Position).Magnitude
    return owned==true and finite(distance)and distance<=6
end
function Loop:Release(session)
    if not session.Requested then return true end
    if not session.Root.Parent then session.Requested=false;return true end
    local now=self.Context.Clock()
    if now<(session.ReleaseRetryAt or 0)then return false end
    local ok,err=pcall(self.Context.Release,session.Root)
    if ok then self.Released+=1;session.Requested=false;session.ReleaseRetryAt=nil;return true end
    session.ReleaseRetryAt=now+.2;self.CleanupError=tostring(err)
    return false
end
function Loop:FlushCleanup()
    local now=self.Context.Clock()
    for root,session in pairs(self.Cleanup)do
        if now>=(session.CleanupAt or 0)then
            session.CleanupAt=now+.2
            self:Release(session)
            for key,restore in pairs(session.Restores or {})do
                local ok,err=pcall(restore)
                if ok then session.Restores[key]=nil else self.CleanupError=tostring(err)end
            end
            if not session.Requested and not next(session.Restores or {})then self.Cleanup[root]=nil end
        end
    end
    if not next(self.Cleanup)then self.CleanupError=nil end
end
function Loop:Remove(player)
    local session=self.Sessions[player];if not session then return end
    self.Sessions[player]=nil -- invalidates any yielding native acquisition first
    local restores={};session.Restores=restores
    restores.Position=function()if session.Position and session.Position.Parent then session.Position:Destroy()end end
    restores.Orientation=function()if session.Orientation and session.Orientation.Parent then session.Orientation:Destroy()end end
    if session.ShadowSit then restores.ShadowSit=function()
        if session.Humanoid.Parent and session.Humanoid.Sit==true then session.Humanoid.Sit=session.ShadowSit.Value end
    end end
    if session.EKI then restores.EKI=function()assert(self:RestoreEKI(session),session.EKIError or 'Replication reset rejected')end end
    if session.Weld then restores.Weld=function()if session.Weld.Parent then session.Weld.Enabled=session.WeldEnabled end end end
    if session.Physics then
        if not self.Context.PreserveCharacterRig then restores.Motors=function()self.Context.RestoreMotors(session.Character)end end
        for part,props in pairs(session.Physics)do restores[part]=function()if part.Parent then
            if not self.Context.PreserveCharacterRig or part.CanCollide==false then part.CanCollide=props.CanCollide end
            if not self.Context.PreserveCharacterRig then part.CustomPhysicalProperties=props.CustomPhysicalProperties end
        end end end
    end
    restores.Pallet=function()self.Context.CancelRagdoll(session.Character)end
    if self.Context.ForgetInterval then restores.Interval=function()self.Context.ForgetInterval(player)end end
    self.Cleanup[session.Root]=session;session.CleanupAt=0;self:FlushCleanup()
end
function Loop:RestoreEKI(session)
    if not session.EKI then return true end
    if not session.Root.Parent then session.EKI=nil;return true end
    local ok,restored=pcall(self.Context.ReplicationRoot,session.Root,session.EKIOriginal)
    if ok and restored==true then
        session.EKI=nil;session.EKIOriginal=nil;session.EKIError=nil;return true
    end
    session.EKIError=ok and 'Replication reset rejected'or tostring(restored)
    return false
end
function Loop:Clear()
    local players={};for player in pairs(self.Sessions)do players[#players+1]=player end
    for _,player in ipairs(players)do self:Remove(player)end
end
function Loop:Create(player,character,root,humanoid)
    local session={Player=player,Character=character,Root=root,Humanoid=humanoid,NextAttempt=0,NextGrab=0,NextSticky=0}
    local slot=0
    while true do
        local taken=false
        for _,other in pairs(self.Sessions)do if other.StackIndex==slot then taken=true;break end end
        if not taken then break end;slot+=1
    end
    session.StackIndex=slot
    local position=root:FindFirstChild("KickAP");local orientation=root:FindFirstChild("KickAO")
    if position then position:Destroy()end;if orientation then orientation:Destroy()end
    position=Instance.new("BodyPosition");position.Name="KickAP";position.D=self.Context.SourceMode and 100 or 200;position.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
    position.Position=root.Position;position.Parent=root
    orientation=nil
    if not self.Context.SourceMode or self.Context.ShadowSource then
        orientation=Instance.new("BodyGyro");orientation.Name="KickAO";orientation.MaxTorque=Vector3.new(math.huge,math.huge,math.huge);orientation.D=200
        orientation.CFrame=CFrame.new();orientation.Parent=root
    end
    session.Position,session.Orientation=position,orientation
    if self.Context.WarmRagdoll and self:RagdollRequired()then self.Context.WarmRagdoll()end
    self.Sessions[player]=session;return session
end
function Loop:ShadowHold(session)
    if not self.Context.ShadowSource then return end
    local source=true -- all source modes retain the donor's stable overhead hold
    session.Position.P=source and 20000 or 10000
    session.Position.D=source and 75 or 100
    local gyro=session.Orientation
    if source then
        if not gyro or gyro.Parent~=session.Root then
            gyro=Instance.new('BodyGyro');gyro.Name='KickAO'
            gyro.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
            gyro.Parent=session.Root;session.Orientation=gyro
        end
        gyro.P=3000;gyro.D=500
        local _,actor=self.Context.LocalCharacter()
        if actor then gyro.CFrame=actor.CFrame end
    elseif gyro then
        gyro:Destroy();session.Orientation=nil
    end
    if not source and session.ShadowSit then
        if session.Humanoid.Parent and session.Humanoid.Sit==true then session.Humanoid.Sit=session.ShadowSit.Value end
        session.ShadowSit=nil
    end
end
function Loop:Physics(session)
    if not session.Physics or self.Context.PreserveCharacterRig then
        session.Physics=session.Physics or{}
        for _,part in ipairs(session.Character:GetDescendants())do if part:IsA("BasePart")and not session.Physics[part]then
            local props={CanCollide=part.CanCollide}
            if not self.Context.PreserveCharacterRig then props.CustomPhysicalProperties=part.CustomPhysicalProperties end
            session.Physics[part]=props
        end end
    end
    local weld=session.Root:FindFirstChild("WeldHRP")
    if weld and not self.Context.PreserveCharacterRig then
        if session.Weld~=weld then session.Weld,session.WeldEnabled=weld,weld.Enabled end
        weld.Enabled=false
    end
    self.Context.Collisions(session.Character,false)
    if not self.Context.PreserveCharacterRig then self.Context.Limbs(session.Character,true)end
    if self.Context.Stabilize and not self.Context.ShadowSource and session.SourceReady and not session.RecoveringHold and(self.Context.NetworkOwned or self.Context.Owned)(session.Root)then
        self.Context.Stabilize(session.Character)
    end
end
function Loop:Acquire(session,now)
    local ctx=self.Context
    if session.Acquiring or now<session.NextGrab or ctx.OwnershipBusy()then return end
    session.Requested=true;session.NextGrab=now+.1;session.Acquiring=true
    self.CaptureMovementPending=true
    self.InFlight+=1
    ctx.SpawnThread(function()
        local recovery=session.HadPhysicalHold==true or session.RecoveringHold==true
        local ok,err=pcall(ctx.Acquire,session.Root,function()return self:Valid(session)end,recovery)
        session.Acquiring=false
        self.InFlight-=1
        if not ok then session.LastError=tostring(err)end
        -- Stop/respawn may happen while SNO yields. Release only this old root;
        -- never touch a replacement session for the same character/root.
        if not self:Valid(session)then
            local current=self.Sessions[session.Player]
            if not current or current.Root~=session.Root then
                if session.Root.Parent then
                    session.Requested=true;session.ReleaseRetryAt=nil
                    self.Cleanup[session.Root]=session;session.CleanupAt=0;self:FlushCleanup()
                end
            end
        end
    end)
end
-- Native order from the supplied Resonance 2.9 cycle: Grab; delayed RNO;
-- independent Ragdoll/RemoveSticky; collisions/limbs; delayed EKI. Scheduling
-- is token-guarded so a stopped/respawned session cannot release a new root.
-- The interval is a full cycle. Keep its sampled value until both halves
-- complete; switch-off/unavailable telemetry returns to native timing promptly.
function Loop:IntervalPeriod(session,now)
    local callback=self.Context.IntervalSeconds
    local ok,value=true,nil
    if callback then ok,value=pcall(callback,session.Player,session.Character)end
    local period=ok and finite(value)and value>0 and math.min(value,120)or nil
    if not period and session.IntervalSeconds then
        session.IntervalSeconds=nil
        Handoff.CancelTiming(session,now)
        for _,release in ipairs(session.Releases or{})do if release.Interval then
            release.Time=nil;release.Frame=(session.Handoff and session.Handoff.Frame or self.Frame)+1;release.Interval=nil
        end end
    end
    return period
end
function Loop:FlushReleases()
    if self.Excursion or self.CaptureAnchor or self.Context.OwnershipBusy()then return end
    local now=self.Context.Clock()
    for _,session in pairs(self.Sessions)do
        self:IntervalPeriod(session,now)
        local queue=session.Releases
        local first=queue and queue[1]
        local due=first and(first.Frame and self.Frame>=first.Frame or first.Time and now>=first.Time)
        if due then
            if self:Valid(session)then
                -- A replicated PartOwner marker can arrive before simulation
                -- ownership. Release immediately only after both facts agree;
                -- the bounded handoff timeout still recovers missing replies.
                local owned=self.Context.Owned(session.Root)==true
                if Handoff.CanRelease(session,self.Frame,now,owned)and self:Release(session)then
                    Handoff.Released(session,self.Frame,now,self.Context.PingSeconds(),self.Context.NativePhases==true and'Native'or self.Context.LowLatency==true,session.IntervalSeconds)
                    table.remove(queue,1)
                    -- After a deliberate Gucci pause, discard overdue release
                    -- callbacks instead of replaying them as a same-frame burst.
                    while queue[1]and(queue[1].Frame and self.Frame>=queue[1].Frame or queue[1].Time and now>=queue[1].Time)do table.remove(queue,1)end
                end
            else session.Releases={}end
        end
    end
end
-- Releasing an acknowledged marker is part of the healthy source cycle. A
-- real loss of simulation ownership/overhead hold is different: retain the new
-- grab while recovering instead of immediately releasing it and letting go.
function Loop:TrackHold(session,position,now,networkOwned)
    if not self.Context.RecoverLostHold then return end
    local distance=(session.Root.Position-position).Magnitude
    local close=networkOwned and finite(distance)and distance<=3
    if close then
        if session.HoldSampleFrame~=self.Frame then
            session.HoldSampleFrame=self.Frame;session.HoldSamples=(session.HoldSamples or 0)+1
        end
        if session.HoldSamples>=2 then
            session.HadPhysicalHold=true
            if session.RecoveringHold and(self.Context.Owned(session.Root)or self.Context.KeepCapture and networkOwned and session.CaptureAcknowledged)then
                session.RecoveringHold=nil;session.RecoveryStarted=nil;session.RecoveryGrabAt=nil
                session.SourceNextAt=nil;session.SourceDeadline=nil
            end
        end
    else
        session.HoldSamples=0;session.HoldSampleFrame=nil
        if session.HadPhysicalHold and not session.RecoveringHold then
            session.RecoveringHold=true;session.RecoveryStarted=now;session.RecoveryGrabAt=nil
            session.SourceReady=nil;session.SourceNextAt=nil;session.SourceDeadline=nil
            if self.Context.CancelRagdoll then self.Context.CancelRagdoll(session.Character)end
        end
    end
end
function Loop:RecoverHoldCycle(session,now)
    local ctx=self.Context
    if now<(session.RecoveryGrabAt or 0)or session.Acquiring then return end
    if not(ctx.NetworkOwned or ctx.Owned)(session.Root)and now-(session.RecoveryStarted or now)>=.2 then
        self:Acquire(session,now);return
    end
    if ctx.Grab(session.Root)~=false then session.Requested=true;self.Calls+=1 end
    session.RecoveryGrabAt=now+.1
end
function Loop:RepairHoldMover(session)
    if not self.Context.RecoverLostHold then return end
    local root=session.Root;local mover=session.Position
    if not mover or mover.Parent~=root then
        local old=root:FindFirstChild("KickAP");if old then old:Destroy()end
        mover=Instance.new("BodyPosition");mover.Name="KickAP";mover.D=self.Context.SourceMode and 100 or 200
        mover.Position=root.Position;mover.MaxForce=Vector3.new(math.huge,math.huge,math.huge);mover.Parent=root;session.Position=mover
    elseif mover.MaxForce.Magnitude==0 then mover.MaxForce=Vector3.new(math.huge,math.huge,math.huge)end
end
function Loop:Update(session,position,now,ping)
    local ctx=self.Context;local root=session.Root
    -- The native cycle intentionally releases its grab marker. Once the
    -- capture was acknowledged, only loss of actual simulation ownership
    -- invalidates it; a replicated marker is not a per-frame clock.
    local networkOwned=ctx.NetworkOwned and ctx.NetworkOwned(root)or not ctx.NetworkOwned and ctx.Owned(root)
    if not networkOwned then
        session.CapturedFrame=nil;session.CaptureAcknowledged=nil
    elseif ctx.Owned(root)then session.CaptureAcknowledged=true
    elseif ctx.NativePhases~=true then
        session.CapturedFrame=nil;session.CaptureAcknowledged=nil
    end
    self:RepairHoldMover(session)
    self:ShadowHold(session)
    session.Position.Position=position
    if self.Excursion or self.CaptureAnchor then return end
    if not self.NativeTick then
        if session.Physics then self:Physics(session)end
        return
    end
    if session.Acquiring then return end
    if ctx.OwnershipBusy()then if session.Physics then self:Physics(session)end;return end
    local _,localRoot=ctx.LocalCharacter();if not localRoot then return end
    if ctx.AcquireInitial and not session.CaptureAcknowledged and not ctx.Owned(root)then
        self:TrackHold(session,position,now,networkOwned)
        self:Acquire(session,now);return
    end
    if(root.Position-localRoot.Position).Magnitude>33 then
        if networkOwned and session.CaptureAcknowledged then
            if not ctx.ShadowSource then ctx.Teleport(root,position)end
        elseif ctx.Owned(root)then ctx.Teleport(root,position)
        else self:Acquire(session,now);return end
    end
    -- Ownership phases gate only the next outgoing Grab. Hold updates,
    -- collision maintenance and the pallet worker continue while waiting.
    local period=self:IntervalPeriod(session,now)
    local queued=session.Releases and #session.Releases>0
    local repeatReady=not queued and Handoff.CanGrab(session,self.Frame,now,(ctx.MarkerOwned or ctx.Owned)(root))
    if repeatReady and not ctx.IntervalSeconds and ctx.IntervalReady then repeatReady=ctx.IntervalReady(session.Player,session.Character)end
    self:TrackHold(session,position,now,networkOwned)
    if ctx.SourceMode then
        if self:SourceCycle(session,now,period,networkOwned)then session.SourcePrimaryFrame=self.Frame end
    elseif repeatReady then
        session.Requested=true;ctx.Grab(root);self.Calls+=1
        session.IntervalSeconds=period
        Handoff.Grabbed(session,self.Frame,now,ping,ctx.NativePhases==true and'Native'or ctx.LowLatency==true,period)
        session.Releases=session.Releases or {}
        if period then
            session.Releases[#session.Releases+1]={Time=now+period*.5,Interval=true}
        elseif self:Compatibility()then
            session.Releases[#session.Releases+1]={Time=now+.2}
        else session.Releases[#session.Releases+1]={Frame=self.Frame+1}end
    end
    if self:RagdollRequired()then
        ctx.RequestRagdoll(session.Character,function()
            return self:Valid(session)and self:RagdollRequired()and not self.Excursion and not self.CaptureAnchor and not session.Acquiring
        end)
    elseif ctx.CancelRagdoll then
        ctx.CancelRagdoll(session.Character)
    end
    if ctx.StickyEnabled()and not session.StickyBusy and now>=session.NextSticky then
        session.NextSticky=now+.2
        session.StickyBusy=true
        ctx.SpawnThread(function()
            if self:Valid(session)then pcall(ctx.RemoveSticky,session.Character)end
            session.StickyBusy=false
        end)
    end
    self:Physics(session)
    session.EKIAt=session.EKIAt or now+.6
    local ekiReady=not self.MaximumSpeed and now>=session.EKIAt
    -- The old unconditional 600ms delay also ran after an already-confirmed
    -- capture. In maximum-speed mode use the acknowledgement and a subsequent
    -- solver frame at the hold destination instead of that arbitrary pause.
    -- Initial capture still needs both acknowledgements. A later deliberate
    -- marker release does not tear down a physically held native capture.
    local captured=ctx.Owned(root)or ctx.NativePhases==true and session.CaptureAcknowledged==true
    if self.MaximumSpeed and networkOwned and captured and not root.Anchored then
        local distance=(root.Position-position).Magnitude
        if finite(distance)and distance<=6 then
            session.CapturedFrame=session.CapturedFrame or self.Frame
            if self.Frame>session.CapturedFrame then ekiReady=true end
        else session.CapturedFrame=nil end
    else session.CapturedFrame=nil end
    if ctx.EKIEnabled()and ekiReady and networkOwned and not(ctx.SuppressEKI and ctx.SuppressEKI(session.Player))then
        if not session.EKI then
            session.EKIOriginal=nil
            if ctx.ReadReplicationRoot then
                local ok,read,value=pcall(ctx.ReadReplicationRoot,root)
                if ok and read then session.EKIOriginal=value end
            end
        end
        local ok,applied=pcall(ctx.ReplicationRoot,root,root)
        if ok and applied==true then session.EKI=true;session.EKIError=nil
        else session.EKIError=ok and 'Replication write rejected'or tostring(applied)end
    elseif session.EKI then self:RestoreEKI(session)end
    session.OwnedAt=ctx.Owned(root)and(session.OwnedAt or now)or nil
end
-- Both modes retain v4.94 Faster's confirmed-capture -> Grab/Release cycle.
-- Normal keeps its old pre-physics cadence; Faster repeats that same pair once
-- after the solver, without same-callback bursts or catch-up traffic.
local sourceSteps={Faster={{'G','R'}},Normal={{'G','R'}},['Super Fast']={{'G','R'}}}
-- Supplied Shadow Core Normal: ownership refresh, P=20000/D=75 overhead
-- hold, actor-facing gyro, and six native release requests every three steps.
-- Faster retains that operation with a two-step period. The expensive initial
-- approach is separate and never restarts merely because a marker was released.
function Loop:ShadowCycle(session,now,period,networkOwned)
    local ctx=self.Context;local requested=ctx.SourceMode()
    local mode=requested=='Normal'and'Normal'or requested=='Super Fast'and'Super Fast'or'Faster'
    if session.SourceMode~=mode then
        session.ShadowNextAt=nil;session.ShadowFrame=0;session.SourceMode=mode
    end
    if not networkOwned or not session.CaptureAcknowledged then
        session.SourceReady=nil
        return self:MaintainCapture(session,now,period,networkOwned)
    end
    session.SourceReady=true
    if ctx.Grab(session.Root)~=false then session.Requested=true;self.Calls+=1 end
    session.ShadowFrame=(session.ShadowFrame or 0)+1
    local due=period and now+1e-7>=(session.ShadowNextAt or now+period)
        or not period and session.ShadowFrame>=(mode=='Normal'and 3 or mode=='Super Fast'and 1 or 2)
    if period and not session.ShadowNextAt then session.ShadowNextAt=now+period end
    if not due then return end
    session.ShadowSit=session.ShadowSit or{Value=session.Humanoid.Sit}
    session.Humanoid.Sit=true
    local complete=true
    for _=1,6 do
        if not self:Valid(session)then return end
        local ok,why=pcall(ctx.Release,session.Root)
        if not ok then complete=false;session.LastError=tostring(why);break end
        self.Released+=1
    end
    session.Requested=not complete;session.ShadowFrame=0
    session.ShadowNextAt=period and now+period or nil
    session.ShadowBursts=(session.ShadowBursts or 0)+1
    return true
end
-- A retained capture is not a refresh loop. Once both ownership facts were
-- observed, a transient marker change does not justify another Grab while
-- the same root is still locally simulated. Actual loss re-enters acquisition.
function Loop:MaintainCapture(session,now,period,networkOwned)
    local ctx=self.Context;local requested=ctx.SourceMode()
    session.SourceMode=requested=='Normal'and'Normal'or requested=='Super Fast'and'Super Fast'or'Faster'
    if ctx.Owned(session.Root)then session.CaptureAcknowledged=true end
    if networkOwned and session.CaptureAcknowledged then
        session.SourceReady=true;session.CaptureRetryAt=nil;return
    end
    session.SourceReady=nil
    if now<(session.CaptureRetryAt or 0)then return end
    if ctx.Grab(session.Root)~=false then session.Requested=true;self.Calls+=1 end
    session.CaptureRetryAt=now+math.max(period or .1,.1)
end
function Loop:SourceCycle(session,now,period,networkOwned)
    local ctx=self.Context;local root=session.Root
    if not self:Valid(session)then return end
    if ctx.ShadowSource then return self:ShadowCycle(session,now,period,networkOwned)end
    if ctx.KeepCapture then return self:MaintainCapture(session,now,period,networkOwned)end
    if ctx.RecoverLostHold and session.RecoveringHold then self:RecoverHoldCycle(session,now);return end
    local requested=ctx.SourceMode()
    local mode=requested=='Normal'and'Normal'or requested=='Super Fast'and'Super Fast'or'Faster'
    if session.SourceMode~=mode then
        if session.SourceMode and session.Requested and not self:Release(session)then return end
        session.SourceMode=mode;session.SourcePhase=1;session.SourceNextAt=nil
        session.SourceReady=nil;session.SourceDeadline=nil;session.SourceHoldFrame=nil
    end
    if not networkOwned then
        if session.SourceReady then session.SourceNextAt=nil;session.SourceDeadline=nil end
        session.SourceReady=nil;session.SourcePhase=1;session.SourceHoldFrame=nil
    end
    if ctx.Owned(root)then
        if not session.SourceReady then session.SourceNextAt=nil;session.SourceDeadline=nil end
        session.SourceReady=true
    end
    if not session.SourceReady then
        if session.SourceDeadline and now>=session.SourceDeadline then
            if not self:Release(session)then return end
            session.SourceDeadline=nil;session.SourceNextAt=now+.1;return
        end
        if now>=(session.SourceNextAt or 0)then
            if ctx.Grab(root)~=false then session.Requested=true;self.Calls+=1 end
            session.SourceNextAt=now+.1;session.SourceDeadline=session.SourceDeadline or now+.65
        end
        return
    end
    if ctx.StableHoldBeforeRefresh then
        if not self:IsPhysicallyHolding(session.Player)then
            -- Initial capture is not yet a stable physical hold. Keep that
            -- capture while the mover lifts the real rig; a refresh release
            -- here can hand it back before the body reaches its destination.
            session.SourceHoldFrame=nil;session.SourcePhase=1
            session.SourceNextAt=nil;session.SourcePeriod=nil
            if not(ctx.MarkerOwned or ctx.Owned)(root)and now>=(session.HoldGrabAt or 0)then
                if ctx.Grab(root)~=false then session.Requested=true;self.Calls+=1 end
                session.HoldGrabAt=now+.1
            end
            return
        end
        if not session.SourceHoldFrame then session.SourceHoldFrame=self.Frame;return end
        if self.Frame<=session.SourceHoldFrame then return end
    end
    if session.SourcePeriod and not period then session.SourceNextAt=nil end
    if now<(session.SourceNextAt or 0)then return end
    local steps=sourceSteps[mode];local phase=session.SourcePhase or 1
    if phase==1 then session.SourcePeriod=period end
    for _,operation in ipairs(steps[phase])do
        if not self:Valid(session)then return end
        if operation=='G'then
            if ctx.Grab(root)==false then session.SourceNextAt=now+.1;return end
            session.Requested=true;self.Calls+=1
        elseif not self:Release(session)then return end
    end
    session.SourcePhase=phase%#steps+1
    session.SourceNextAt=now+(session.SourcePeriod or 0)/#steps
    return true
end
function Loop:AfterPhysics()
    local ctx=self.Context
    local mode=ctx.SourceMode and ctx.SourceMode()
    if self.Closed or ctx.ShadowSource or ctx.KeepCapture or not self.DistinctPhysicsPhases or(mode~='Faster'and mode~='Super Fast')or not ctx.Enabled()
        or self.Excursion or self.CaptureAnchor or ctx.OwnershipBusy()then return end
    local _,actor,hum=ctx.LocalCharacter()
    if not actor or not hum or hum.Health<=0 then return end
    local now=ctx.Clock()
    for _,session in pairs(self.Sessions)do
        if session.SourceMode~=mode or session.SourcePrimaryFrame~=self.Frame or session.SourceSecondaryFrame==self.Frame
            or not session.SourceReady or session.Acquiring or not self:Valid(session)then continue end
        if session.Root.Anchored or(session.Root.Position-actor.Position).Magnitude>33 then continue end
        local owned=(ctx.NetworkOwned or ctx.Owned)(session.Root)==true
        if not owned then continue end
        -- This runs after an actual solver callback. A missing acknowledgement,
        -- ownership loss or unfinished initial capture never gets this extra pair.
        session.SourceSecondaryFrame=self.Frame
        self:SourceCycle(session,now,self:IntervalPeriod(session,now),owned)
    end
end
function Loop:Step(dt)
    local ctx=self.Context
    if not ctx.Enabled()then
        self:Clear();self.Status=next(self.Cleanup)and("Kick stopping: "..(self.CleanupError or "cleanup pending"))or "Kick idle"
        return
    end
    local _,root,hum=ctx.LocalCharacter()
    if not root or not hum or hum.Health<=0 then self:Clear();self.Status="Waiting for your character";return end
    local targets=ctx.Targets();local allowed={}
    for _,player in ipairs(targets)do allowed[player]=true end
    local remove={};for player,session in pairs(self.Sessions)do if not allowed[player]or not self:Valid(session)then remove[#remove+1]=player end end
    for _,player in ipairs(remove)do self:Remove(player)end
    -- Source Normal mode has two waits per outer cycle. 2x mode removes
    -- that extra frame; compatibility mode retains its source one-frame loop.
    if not self.MaximumSpeed and not self:Compatibility()and self.Frame%2==0 then return end
    local now=ctx.Clock();local ping=ctx.PingSeconds()
    ping=finite(ping)and math.clamp(ping,0,.5)or .1
    local held,waiting=0,0
    for index,player in ipairs(targets)do
        -- A target snapshot can outlive a selection/protection change while
        -- another acquisition yields. Do not recreate the removed session.
        if not ctx.Selected(player)then continue end
        local character,targetRoot,targetHum=ctx.Character(player)
        local torso=character and(character:FindFirstChild("Torso")or character:FindFirstChild("UpperTorso"))
        if targetRoot and torso and targetHum and targetHum.Health>0 then
            if self.Cleanup[targetRoot]then waiting+=1;continue end
            if self.Excursion and not self.Sessions[player]then continue end
            local session=self.Sessions[player]or self:Create(player,character,targetRoot,targetHum)
            local destination=(self.CaptureAnchor or root.Position)+Vector3.new(0,ctx.Height()+session.StackIndex*6,0)
            if ctx.SourceMode then
                local origin=self.CaptureAnchor or root.Position
                if #targets>1 then
                    local angle=(index-1)*math.pi*2/#targets
                    destination=origin+Vector3.new(math.cos(angle)*7,ctx.Height(),math.sin(angle)*7)
                else destination=origin+Vector3.new(0,ctx.Height(),0)end
            end
            if self.Excursion then destination=self.Excursion.Goals[session]or session.Position.Position end
            self:Update(session,destination,now,ping)
            if session.OwnedAt then held+=1 else waiting+=1 end
        end
    end
    if next(self.Cleanup)then self.Status="Kick cleanup retry: "..(self.CleanupError or "waiting")
    elseif #targets==0 then self.Status="Select a target"
    else self.Status=string.format("Kick %s | held: %d | awaiting: %d\nNative Grab calls: %d | RNO calls: %d",ctx.SourceMode and ctx.SourceMode()or(self.MaximumSpeed and "2x"or "source timing"),held,waiting,self.Calls,self.Released)end
end
function Loop:Evidence()
 local result={FullCycleTiming=self.Context.IntervalSeconds~=nil,NativeFrames=self.Context.NativePhases==true,LowLatency=self.Context.LowLatency==true,GrabRequests=self.Calls,ReleaseRequests=self.Released,Targets={}}
 for _,session in pairs(self.Sessions)do result.Targets[#result.Targets+1]={Name=session.Player.Name,Phase=session.Handoff and session.Handoff.Phase,
  LastObserved=session.LastHandoff and session.LastHandoff.Observed,PhysicsOwned=self.Context.NetworkOwned and self.Context.NetworkOwned(session.Root)==true,
  MarkerOwned=(self.Context.MarkerOwned or self.Context.Owned)(session.Root)==true,Acquiring=session.Acquiring==true,RecoveringHold=session.RecoveringHold==true}end
 return result
end
function Loop:Dispose()
    if self.Closed then return end
    if self.Excursion then self:EndExcursion(self.Excursion.Token)end
    self.Closed=true;self.CloseDeadline=self.Context.Clock()+2;self:Clear();self:FlushCleanup()
    if self.PostConnection then self.PostConnection:Disconnect()end
    if not next(self.Cleanup)and self.InFlight==0 then self.Connection:Disconnect()end
end
return Loop
