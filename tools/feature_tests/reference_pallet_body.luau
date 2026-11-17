-- Tests placements/cadence and cleanup, never server hit/blur/kick outcomes.
for _,fps in ipairs({15,30,60,120,240})do
    for _,mode in ipairs({"Normal","Faster","Super Fast"})do
        local f=referenceFixture(mode);local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
        f.Sim:Run(3,fps)
        check(f.Pallet.Passes>0,"Reference pallet stalled at "..fps.." / "..mode)
        check(f.Data.Spawned==0,"Cached pallet was respawned for each target pass")
        check(f.Pallet.Passes<=math.floor(3*fps/3)+1,"Source passes bypassed their impact/exit physics frames")
        if fps>=60 and mode=="Faster"then check(f.Pallet.Passes>=27 and f.Pallet.Passes<=31,"Fast complete-pass clock drifted from 0.10 s")end
        if fps>=60 and mode=="Super Fast"then check(f.Pallet.Passes>=46 and f.Pallet.Passes<=51,"Super Fast complete-pass clock drifted from 0.06 s")end
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
print('PASS: '..checks..' source pallet stages, frame-independent clocks, ownership, fairness, cancellation and cleanup checks (mocked; no server kick timing proof)')
