-- Tests placements/cadence and cleanup, never server hit/blur/kick outcomes.
for _,fps in ipairs({15,30,60,100,120,144,240,260})do
    for _,mode in ipairs({"Normal","Faster","Super Fast"})do
        local f=referenceFixture(mode);local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
        f.Sim:Run(3,fps)
        check(f.Pallet.Passes>0,"Reference pallet stalled at "..fps.." / "..mode)
        check(f.Data.Spawned==0,"Cached pallet was respawned for each target pass")
        local minimum=mode=="Super Fast"and 2 or 3
        check(f.Pallet.Passes<=math.floor(3*fps/minimum)+1,"Source passes bypassed their impact/exit physics frames")
        if fps>=60 and mode=="Faster"then check(f.Pallet.Passes>=46 and f.Pallet.Passes<=51,"Faster did not inherit the previous Super Fast 0.06 s clock")end
        if fps>=100 and mode=="Super Fast"then check(f.Pallet.Passes>=149 and f.Pallet.Passes<=151,"Super Fast did not sustain 50 complete physical passes/s")end
        if fps==60 and mode=="Super Fast"then check(f.Pallet.Passes<=91,"60 physics frames were misreported as 50 complete passes/s")end
        check(not f.Target.Flag.Value and f.Pallet.Confirmed==0,"A placement was labelled a server-confirmed ragdoll")
        local before=f.Pallet.StrikeAttempts;f.Sim:Tick(1.5)
        check(f.Pallet.StrikeAttempts-before<=1,"A frame stall replayed a backlog of strikes")
        f.Data.Valid=false;f.Sim:Tick(1/fps)
        check(not next(f.Pallet.Entries),"Cancelled target stayed queued")
        check(f.Sound.Transparency==.3 and f.Main.Transparency==.2 and f.Sound.CanQuery,"Pallet styling was not restored")
        before=f.Pallet.StrikeAttempts;f.Sim:Run(.2,fps)
        check(f.Pallet.StrikeAttempts==before,"Cancelled worker continued placing the pallet")
        f.Pallet:Dispose()
        check(f.Data.Destroyed==1 and not f.Pallet.Connection.Connected and not f.Pallet.PhysicsConnection.Connected,"Reference pallet leaked on unload")
    end
end
do
    local f=referenceFixture("Normal");f.Pallet:Maintain(f.Target.Character,f.Valid)
    local stages={}
    for _=1,9 do
        f.Sim:Tick(1/60)
        stages[#stages+1]={Height=f.Sound.Position.Y-f.Target.Root.Position.Y,Velocity=f.Main.AssemblyLinearVelocity.Y}
    end
    for i=1,8 do
        check(math.abs(stages[i].Height-10000*(1-i/8))<1e-6,"Normal lost the donor's eight source positions")
        check(stages[i].Velocity==(i==8 and -10 or -9997),"Normal lost the donor's descent/impact velocities")
    end
    check(stages[9].Height==10000 and stages[9].Velocity==0,"Pallet did not leave the body after impact")
    f.Pallet:Dispose()
end
do
    local f=referenceFixture("Faster");local second=target("Second");second.Root=newNode("Part","HumanoidRootPart",second.Character)
    f.Pallet:Maintain(f.Target.Character,f.Valid);f.Pallet:Maintain(second.Character,f.Valid);f.Sim:Run(1,60)
    check(f.Pallet.Entries[f.Target.Character].Passes>0 and f.Pallet.Entries[second.Character].Passes>0,"One target monopolized the shared pallet")
    local token={};f.Pallet:Pause(token,true);local before=f.Pallet.StrikeAttempts;f.Sim:Run(.3,60)
    check(before==f.Pallet.StrikeAttempts,"Paused toy removal collided with a pallet worker")
    f.Pallet:Pause(token,false);f.Sim:Run(.2,60)
    check(f.Pallet.StrikeAttempts>before,"Source pallet did not resume after the grab channel was released")
    f.Pallet:Dispose()
end
do
    local f=referenceFixture("Faster");f.Data.Owned=false;f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.3,60)
    check(f.Pallet.StrikeAttempts==0 and f.Data.Grabs<=4,"An unowned pallet was moved or ownership requests flooded")
    f.Data.Valid=false;f.Pallet:Cancel(f.Target.Character);f.Sim:Run(.2,60)
    check(not f.Pallet.Preparing and not f.Pallet.Ownership.InFlight,"Cancellation left board acquisition locked")
    f.Pallet:Dispose()
end
do
    local f=referenceFixture("Faster");local result
    f.Sim:Spawn(function()result=f.Pallet:Apply(f.Target.Character,f.Valid)end)
    f.Sim:Run(.2,60);f.Target.Flag.Value=true;f.Sim:Run(.1,60)
    check(result==true and f.Pallet.Confirmed==1,"Manual Ragdoll did not finish on the real game-state value")
    f.Pallet:Dispose()
end
do
    local f=referenceFixture("Faster");f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.2,60)
    f.Target.Root:Destroy();f.Target.Root=newNode("Part","HumanoidRootPart",f.Target.Character)
    f.Sim:Tick(1/60);check(not next(f.Pallet.Entries),"Respawn retained an old root")
    f.Pallet:Dispose()
end
do
    -- Render callbacks alone cannot establish distinct physics contacts.
    local f=referenceFixture("Super Fast");local elapsed=0;local placements={}
    local original=f.Pallet.Place
    function f.Pallet:Place(entry,point,velocity)
        local frame=self.PhysicsFrame;local ok=original(self,entry,point,velocity)
        if ok then placements[#placements+1]=frame end
        return ok
    end
    f.Sim.Physics=function(dt)
        elapsed+=dt
        if elapsed+1e-9>=1/60 then elapsed-=1/60;f.Sim.RunService.PostSimulation:Fire(1/60)
        else f.Sim.RunService.PostSimulation:Fire(0)end
    end
    f.Pallet:SourceContact(f.Target.Character,f.Valid);f.Sim:Run(3,260)
    check(f.Pallet.Passes>0 and f.Pallet.Passes<=91,"260 rendered frames were mistaken for 260 solver updates")
    check(f.Pallet.PhysicsFrame==180,"Zero-time physics callbacks advanced the contact gate")
    for i=2,#placements do check(placements[i]>placements[i-1],"Contact or exit was overwritten before a positive physics step")end
    f.Pallet:Dispose()
end
do
    local f=referenceFixture("Super Fast");local other=target("Second")
    other.Root=newNode("Part","HumanoidRootPart",other.Character)
    f.Pallet:Request(f.Target.Character,f.Valid,true,true)
    f.Pallet:SourceContact(other.Character,f.Valid)
    f.Sim:Run(3,260)
    local first=f.Pallet.Entries[f.Target.Character].Passes or 0
    local second=f.Pallet.Entries[other.Character].Passes or 0
    check(f.Pallet.Passes>=149 and f.Pallet.Passes<=151,"Multiple targets multiplied the shared 50/s pallet limit")
    check(math.abs(first-second)<=1 and first>0 and second>0,"Accelerated Ragdoll or Kick starved the other target")
    f.Pallet:Dispose()
end
do
    local f=referenceFixture("Super Fast");f.Pallet:SourceContact(f.Target.Character,f.Valid)
    local pattern={1/240,1/300,1/260}
    for i=1,780 do f.Sim:Tick(pattern[(i-1)%#pattern+1])end
    check(math.abs(f.Pallet.Passes-f.Sim.Now*50)<=2,"Jitter around 260 FPS caused 50/s cadence drift")
    for _,invalid in ipairs({math.huge,-math.huge,0/0})do
        f.Pallet:SetContactRate(invalid)
        check(f.Pallet.ContactRate==50,"Invalid rate corrupted the accelerated clock")
    end
    f.Pallet:SetContactRate(1000);check(f.Pallet.ContactRate==50,"Requested rate exceeded 50/s")
    f.Pallet:SetContactRate(10);local before=f.Pallet.Passes;f.Sim:Run(1,260)
    check(f.Pallet.Passes-before>=9 and f.Pallet.Passes-before<=11,"Live rate decrease ignored the new complete-pass period")
    f.Pallet:SetContactRate(50);before=f.Pallet.Passes;f.Sim:Run(1,260)
    check(f.Pallet.Passes-before>=49 and f.Pallet.Passes-before<=51,"Live rate increase stayed limited by the previous period")
    f.Pallet:Dispose()
end
do
    local f=referenceFixture("Super Fast")
    local entry=f.Pallet:Request(f.Target.Character,f.Valid,false)
    check(f.Pallet:Profile(entry)==8,"Single-use Ragdoll lost its original game-state-confirmed trajectory")
    f.Pallet:Dispose()
end
print('PASS: '..checks..' source pallet stages, frame-independent clocks, ownership, fairness, cancellation and cleanup checks (mocked; no server kick timing proof)')
