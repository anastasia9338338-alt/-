-- Contract tests for the available source operation. External flag changes
-- below are explicit fixture inputs, never assertions of server hit acceptance.
-- The rigid-body fixture does not implement Roblox's ragdoll/blur handlers.
local function equalVector(a,b)return(a-b).Magnitude<1e-6 end
local function nativeFixture(pre)
 local f=fixture(Pallet,pre)
 f.Data.GameAccept=false;f.Data.Accept=false
 return f
end
local function sourceFixture(options)
 options=options or{}
 local f=nativeFixture();local states={};local records,waits,acquires=0,{},0
 local valid=true;local result,done
 local native=Source.new({Data={States=states},Inventory={FindFirstChild=function()return f.Model end},
  Clock=function()return f.Sim.Now end,Valid=function()return valid and f.Data.Valid end,
  CanContact=function()return f.Data.Owned and not f.Sound.Anchored and not f.Main.Anchored end,
  API={SpawnToy=function()f.Data.Spawns+=1 end,SNO=function()acquires+=1;return f.Data.Owned end,
   DestroyToy=function(model)if model then model:Destroy()end end},
  Wait=function(seconds)waits[#waits+1]=seconds;f.Sim:Wait(seconds)end,
  Record=function(part,character)
   records+=1
   check(part==f.Sound and character==f.Target.Character,'Native operation reported another target or part')
   check(equalVector(part.Position,f.Target.Torso.Position),'Native operation changed source torso placement')
   check(equalVector(part.Velocity,Vector3.new(0,-10,0)),'Native operation changed source downward velocity')
   local mover=f.Main:FindFirstChild('RagdollBP')
   check(mover and mover.D==1500 and equalVector(mover.Position,Vector3.new(0,100000,0)),'Native body mover no longer matches source parameters')
   check(mover.MaxForce.X==math.huge and mover.MaxForce.Y==math.huge and mover.MaxForce.Z==math.huge,'Native source lift was disabled or replaced')
   check(f.Main.CanCollide==false and f.Sound.CanCollide==false,'Source pallet collision setup changed')
   if options.Record then options.Record(f,records)end
  end,
 })
 local function start()f.Sim:Spawn(function()result=native(f.Target.Character);done=true end)end
 return f,states,start,function()return records,waits,acquires,result,done end,function(value)valid=value end
end
-- Verify the actual native source body at its observation callback. A flag
-- acknowledgement is injected by this fixture, not generated from placements.
do
 local f,states,start,read=sourceFixture({Record=function(f)f.Target.Flag.Value=true end})
 start();f.Sim:Run(.25,240)
 local records,waits,acquires,result,done=read()
 check(done and result==true and records==1 and acquires==1,'External true state failed to stop the original operation')
 check(#waits==1 and waits[1]==.1,'Source wait was replaced with frame-rate polling or another guessed interval')
 check(not states.Ragdolling,'Native success left the shared operation busy')
 check(#f.Data.Crossings==0,'Fixture unexpectedly converted source placement into a server-hit stand-in')
end
do
 local f,states,start,read=sourceFixture();f.Target.Flag.Value=true
 local before=f.Sound.Teleports;start();f.Sim:Run(.3,240)
 local records,waits,acquires,result,done=read()
 check(done and result==true and records==0 and acquires==0 and #waits==0,'Already-ragdolled state executed a source attempt')
 check(f.Sound.Teleports==before and f.Data.Spawns==0,'Already-true source state moved or spawned a pallet')
 check(not states.Ragdolling,'Already-true source state became busy')
end
do
 local f,states,start,read=sourceFixture();start();f.Sim:Run(1,240)
 local records,waits,_,result,done=read()
 check(done and result==false and records>=5 and records<=7,'Unacknowledged source operation lost its original half-second bound')
 check(f.Target.Flag.Value==false and not states.Ragdolling,'Native retry manufactured game state or leaked its busy flag')
 for _,seconds in ipairs(waits)do check(seconds==.1,'Retry substituted arbitrary cadence timing')end
end
do
 local f,states,start,read=sourceFixture({Record=function(f,n)if n==1 then f.Target.Head:FindFirstChild('PartOwner'):Destroy()end end})
 start();f.Sim:Run(.3,240)
 local records,_,_,_,done=read()
 check(done and records==1 and not states.Ragdolling,'Source owner-marker loss did not bound the attempt')
end
for _,mode in ipairs({'invalid','dead','respawn','replace_flag'})do
 local f,states,start,read,setValid=sourceFixture()
 start();f.Sim:Run(.04,240)
 if mode=='invalid'then setValid(false)
 elseif mode=='dead'then f.Target.Humanoid.Health=0
 elseif mode=='respawn'then f.Target.Character.Parent=nil
 else
  f.Target.Flag.Parent=nil
  local replacement=newNode('BoolValue','Ragdolled',f.Target.Humanoid);replacement.Value=true
  f.Target.Flag.Value=true
 end
 f.Sim:Run(.25,240)
 local records,_,_,result,done=read()
 check(done and result~=true and records==1 and not states.Ragdolling,'Old source binding survived lifecycle change: '..mode)
end
-- A maintenance request is pending while the GAME state is true. No elapsed
-- interval or prechosen number of placements may release that state gate.
for _,fps in ipairs({20,60,240,1000})do
 local f=nativeFixture();f.Target.Flag.Value=true
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(2,fps)
 check(entry and not entry.Done and f.Pallet.Passes==0,'Latched true game state did not remain pending at '..fps)
 check(f.Pallet.StrikeAttempts==0 and f.Data.Acquires==0 and f.Data.Spawns==0,'State wait attempted native contact or ownership acquisition')
 f.Target.Flag.Value=false;f.Sim:Run(.16,fps)
 check(f.Pallet.Passes>0,'Game false state did not make the source operation eligible at '..fps)
 local count=f.Pallet.Passes;f.Target.Flag.Value=true;f.Sim:Run(.2,fps);count=f.Pallet.Passes
 f.Sim:Run(2,fps)
 check(f.Pallet.Passes==count and not entry.Done and not f.Pallet.Active,'Latched true state was bypassed by a timer/burst at '..fps)
 check(f.Main:FindFirstChild('RagdollBP').MaxForce.Magnitude==0,'Native lift remained active while waiting for game recovery')
 f.Target.Flag.Value=false;f.Sim:Run(.2,fps)
 check(f.Pallet.Passes>count,'A later external game recovery failed to re-arm native operation')
 f.Pallet:Cancel(f.Target.Character);f.Sim:Run(.2,fps)
 check(entry.Done and not f.Pallet.Active and not f.Pallet.States.Ragdolling,'State-driven cancellation leaked work')
end
-- Original retry polling must retain its source interval at every rendering
-- rate. A new pass is not a catch-up event or a server hit acknowledgement.
for _,fps in ipairs({20,60,240,1000})do
 local f=nativeFixture();f.Pallet:Maintain(f.Target.Character,f.Valid)
 local count=f.Pallet.Passes;local last=0;local samples=0
 f.Sim.After=function()
  if f.Pallet.Passes~=count then
   check(f.Pallet.Passes==count+1,'Native retry replayed placements in one simulation tick')
   check(f.Sim.Now-last>=.1-1e-6,'Native controller replaced the source wait with rendering FPS')
   last=f.Sim.Now;count=f.Pallet.Passes;samples+=1
  end
 end
 f.Sim:Run(1,fps)
 check(samples>=5 and f.Pallet.Passes<=11,'Native retry interval no longer follows the source bounded cadence')
end
-- A maintained target already waiting on game state cannot starve a ready one.
do
 local f=nativeFixture();f.Target.Flag.Value=true
 local second=target('ReadySecond',Vector3.new(30,15,0));f.Data.Targets[#f.Data.Targets+1]=second
 local waiting=f.Pallet:Maintain(f.Target.Character,f.Valid)
 local ready=f.Pallet:Maintain(second.Character,f.Valid);f.Sim:Run(.25,240)
 check((waiting.Passes or 0)==0 and(ready.Passes or 0)>0,'Game-state waiting target occupied the shared native worker')
 check(not waiting.Done,'Scheduling another target discarded a valid game-state waiter')
end
-- Neither a local contact callback nor direct writes may stand in for the
-- native game state. The original operation has no synthetic touch requirement.
do
 local f=nativeFixture();local synthetic=0
 f.Pallet.Context.Touch=function()synthetic+=1;error('Synthetic touch must not be used')end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1,240)
 check(f.Pallet.Passes>0 and synthetic==0,'Native source operation depended on an injected touch API')
 check(f.Target.Flag.Value==false and f.Data.GameReactions==0,'Native attempt manufactured a game acknowledgement')
 check(f.Pallet.Contacts==0 and not entry.Success,'Native placements became local contacts or a successful server result')
end
-- Local contact telemetry keeps the source Torso distinct from the separate
-- named hitbox. Neither callback delivery acknowledges a native game hit.
do
 local f=nativeFixture();local t=f.Target
 local root=newNode('Part','HumanoidRootPart',t.Character)
 local receiver=newNode('Part','RagdollTouchedHitbox',root)
 receiver.Position=t.Torso.Position+Vector3.new(9,4,0);t.Receiver=receiver
 local entry=f.Pallet:Maintain(t.Character,f.Valid)
 check(entry.Receiver==t.Torso and entry.ReceiverKind=='SourceTorso','Controller changed the original source contact target')
 f.Sound.Touched:Fire(receiver)
 check(f.Pallet.Contacts==1 and not entry.ReceiverContacts,'Named hitbox contact was mislabeled as source Torso contact')
 f.Sound.Touched:Fire(t.Torso)
 check(f.Pallet.Contacts==2 and entry.ReceiverContacts==1,'Actual source contact telemetry ignored Torso')
 local evidence=f.Pallet:Evidence().Entries[1]
 check(evidence.SourcePlacements>0 and evidence.PlacementAttempts>0 and evidence.PhysicalTraversals==nil,'Evidence still mislabeled source placements as physical traversals')
 check(t.Flag.Value==false and not entry.Success and f.Pallet.Confirmed==0,'Local callback manufactured native state or confirmed a game result')
end
-- A game state received during the yielding ownership handoff must be
-- rechecked before the original placement operation begins.
do
 local f=nativeFixture();f.Data.Owned=false;f.Data.Acquire=false
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.05,240)
 f.Target.Flag.Value=true;f.Data.Owned=true;f.Sim:Run(.25,240)
 check(f.Pallet.Passes==0 and f.Pallet.StrikeAttempts==0,'Ownership handoff placed a board after the game already ragdolled the target')
 check(not entry.Done and not f.Pallet.Active and f.Data.Destroyed==0,'State update during ownership destroyed or ended a maintained target')
end
for _,mode in ipairs({'cancel','pause','dispose','dead','respawn'})do
 for _,initialTrue in ipairs({false,true})do
  local f=nativeFixture();f.Target.Flag.Value=initialTrue
  local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.04,240)
  if mode=='cancel'then f.Pallet:Cancel(f.Target.Character)
  elseif mode=='pause'then f.Pallet:Pause('state-test',true)
  elseif mode=='dispose'then f.Pallet:Dispose()
  elseif mode=='dead'then f.Target.Humanoid.Health=0
  else f.Target.Character.Parent=nil end
  f.Sim:Run(.25,240);local before=f.Pallet.Passes;f.Target.Flag.Value=false;f.Sim:Run(.5,240)
  check(entry.Done and f.Pallet.Passes==before and not f.Pallet.Active,'Native lifecycle failed: '..mode..' initialTrue='..tostring(initialTrue))
  check(not f.Pallet.States.Ragdolling and not f.Pallet.LastError,'Lifecycle became a source error: '..mode)
  if entry.Reaction then check(entry.Reaction:Describe().Disposed,'Stopped state observer survived lifecycle: '..mode)end
 end
end
do
 local f=nativeFixture();f.Target.Flag.Value=true
 local old=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.1,240)
 f.Pallet:Pause('pause',true);check(f.Pallet:Maintain(f.Target.Character,f.Valid)==nil,'Paused controller admitted a new request')
 f.Pallet:Pause('pause',false);f.Target.Flag.Value=false
 local fresh=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.2,240)
 check(old.Done and fresh~=old and not fresh.Done and(fresh.Passes or 0)>0,'Resume reused canceled state binding instead of a fresh request')
end
do
 local f=nativeFixture();f.Data.Owned=false;f.Data.Acquire=false
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1,240)
 check(f.Pallet.Passes==0 and f.Pallet.StrikeAttempts==0 and f.Data.Acquires>0 and f.Data.Destroyed==0,'Unowned pallet performed the native source operation')
 check(f.Data.Acquires<=7,'Failed native ownership recovery flooded requests')
 f.Data.Acquire=true;f.Sim:Run(1,240)
 check(f.Pallet.Passes>0 and not entry.Done,'Native source did not recover after real ownership became available')
end
do
 local f=nativeFixture()
 check(f.Pallet:Prepare(f.Valid)and f.Pallet.Model==f.Model and f.Data.Spawns==0,'Prepare failed to reuse the healthy native pallet')
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.2,240)
 check(not entry.Done and f.Pallet.Passes>0,'Prepared pallet failed to run state-driven native attempt')
 f.Pallet:Dispose();check(not f.Pallet:Prepare(f.Valid),'Disposed native controller still prepared a board')
end
do
 local f=nativeFixture();f.Target.Flag.Value=true
 local entry=f.Pallet:Request(f.Target.Character,f.Valid);f.Sim:Run(.2,240)
 check(entry.Done and entry.Success and f.Pallet.Passes==0,'Independent one-shot failed already-ragdolled state contract')
end
do
 local f=nativeFixture();local effect=true
 local one=f.Pallet:Request(f.Target.Character,function()return effect end)
 local promoted=f.Pallet:Maintain(f.Target.Character,f.Valid);effect=false;f.Sim:Run(.15,240)
 check(one==promoted and not promoted.Done and f.Pallet.Passes>0,'One-shot predicate invalidated a promoted maintenance request')
 f.Target.Flag.Value=true;f.Sim:Run(.2,240)
 check(not promoted.Done and not f.Pallet.Active,'Promoted native request did not wait on game state')
end
print('PASS: '..checks..' source-native operation parameters, state eligibility, ownership, waiting fairness and lifecycle checks (mocked; no real game hit/blur/kick proof)')
