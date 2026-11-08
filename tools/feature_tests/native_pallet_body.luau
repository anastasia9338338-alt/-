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
  Repeating=function()return options.Repeating==true end,
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
-- A maintained operation uses the SAME source placement/force parameters,
-- but an already-true state must not suppress those attempts or become a new
-- success acknowledgement. The fixture never changes this target's state.
do
 local f,states,start,read=sourceFixture({Repeating=true});f.Target.Flag.Value=true
 start();f.Sim:Run(1,240)
 local records,waits,acquires,result,done=read()
 check(done and result~=true and records>=5 and records<=7 and acquires==1,'Maintained source operation skipped a ragdolled target or falsely acknowledged it')
 check(f.Target.Flag.Value==true and f.Data.GameReactions==0,'Maintained source operation manufactured recovery or a new game hit')
 check(not states.Ragdolling,'Maintained source slice leaked its busy state')
 for _,seconds in ipairs(waits)do check(seconds==.1,'Maintained source operation changed the original retry interval')end
end
do
 local f,states,start,read=sourceFixture({Repeating=true,Record=function(f,n)if n==1 then f.Target.Flag.Value=true elseif n==3 then f.Target.Flag.Value=false end end})
 start();f.Sim:Run(1,240)
 local records,_,_,result,done=read()
 check(done and result~=true and records>=5 and records<=7,'Changing game state stopped a maintained native source slice')
 check(f.Target.Flag.Value==false and not states.Ragdolling,'External state changes were overwritten or stranded the maintained source')
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
-- A maintenance request keeps the original native operation active while the
-- victim is held and its game flag stays true. Hold objects and character
-- transforms below are inert fixture references: this is not a live hold test.
for _,fps in ipairs({20,60,240,1000})do
 local f=nativeFixture();f.Target.Flag.Value=true
 local root=newNode('Part','HumanoidRootPart',f.Target.Character);root.Position=f.Target.Torso.Position
 local hold=newNode('BodyPosition','KickAP',root);hold.Position=root.Position;hold.D=200;hold.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
 local orientation=newNode('BodyGyro','KickAO',root);orientation.CFrame=CFrame.new();orientation.D=200
 local rootPosition=root.Position;local torsoPosition=f.Target.Torso.Position
 local rootMoves=root.Teleports;local torsoMoves=f.Target.Torso.Teleports
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(2,fps)
 check(entry and not entry.Done and f.Pallet.Passes>=10,'Latched true held state suppressed maintained native attempts at '..fps)
 check(f.Pallet.StrikeAttempts==f.Pallet.Passes and f.Data.Acquires==0 and f.Data.Spawns==0,'Maintained native attempts respawned or reacquired a healthy pallet')
 check(f.Target.Flag.Value==true and f.Data.GameReactions==0,'Held target was forced out of ragdoll or given a fake state acknowledgement')
 check(root.Parent==f.Target.Character and hold.Parent==root and orientation.Parent==root,'Maintained pallet removed a fixture hold object')
 check(equalVector(root.Position,rootPosition)and equalVector(f.Target.Torso.Position,torsoPosition)and root.Teleports==rootMoves and f.Target.Torso.Teleports==torsoMoves,'Maintained pallet moved or dropped the held fixture character')
 check(equalVector(hold.Position,rootPosition)and hold.D==200 and hold.MaxForce.Y==math.huge and orientation.D==200,'Maintained pallet rewrote the fixture hold parameters')
 local evidence=f.Pallet:Evidence().Entries[1]
 check(evidence.StateAlreadyRagdolled==true and evidence.ContinuousStrikes==true and evidence.WaitingForGameRecovery==nil,'Evidence retained the obsolete recovery-wait contract')
 check(evidence.SourcePlacements>0 and evidence.ObservedRagdollRises==0,'Existing ragdoll state was claimed as a new hit')
 local count=f.Pallet.Passes
 f.Target.Flag.Value=false;f.Sim:Run(.16,fps)
 check(f.Pallet.Passes>count,'External false state stopped maintained native attempts at '..fps)
 f.Target.Flag.Value=true;f.Sim:Run(.2,fps);count=f.Pallet.Passes
 f.Sim:Run(2,fps)
 check(f.Pallet.Passes>count and not entry.Done,'External true state stopped a maintained operation at '..fps)
 f.Target.Flag.Value=false;f.Sim:Run(.2,fps)
 check(f.Pallet.Passes>count,'A later external game state stopped native operation')
 f.Pallet:Cancel(f.Target.Character);f.Sim:Run(.2,fps)
 check(entry.Done and not f.Pallet.Active and not f.Pallet.States.Ragdolling,'Maintained native cancellation leaked work')
 check(f.Main:FindFirstChild('RagdollBP').MaxForce.Magnitude==0,'Stopped maintained operation left the native lift enabled')
end
-- Original retry polling must retain its source interval at every rendering
-- rate. A new pass is not a catch-up event or a server hit acknowledgement.
for _,fps in ipairs({20,60,240,1000})do
 for _,initialTrue in ipairs({false,true})do
 local f=nativeFixture();f.Target.Flag.Value=initialTrue;f.Pallet:Maintain(f.Target.Character,f.Valid)
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
 check(f.Target.Flag.Value==initialTrue,'Maintained native retry rewrote the game state')
 end
end
-- A maintained target already ragdolled cannot monopolize the native worker.
do
 local f=nativeFixture();f.Target.Flag.Value=true
 local second=target('ReadySecond',Vector3.new(30,15,0));f.Data.Targets[#f.Data.Targets+1]=second
 local first=f.Pallet:Maintain(f.Target.Character,f.Valid)
 local other=f.Pallet:Maintain(second.Character,f.Valid);f.Sim:Run(1.5,240)
 check((first.Passes or 0)>0 and(other.Passes or 0)>0,'Ragdolled maintained target starved another target')
 check(not first.Done and not other.Done,'Shared native scheduling discarded a maintained target')
 check(f.Target.Flag.Value==true and second.Flag.Value==false,'Shared native scheduling rewrote the targets game states')
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
-- A maintained target becoming ragdolled during ownership handoff stays
-- eligible; a one-shot effect retains the original state-completion rule.
do
 local f=nativeFixture();f.Data.Owned=false;f.Data.Acquire=false
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.05,240)
 f.Target.Flag.Value=true;f.Data.Owned=true;f.Sim:Run(.25,240)
 check(f.Pallet.Passes>0 and f.Pallet.StrikeAttempts>0,'Ownership handoff suppressed maintained attempts at an already ragdolled target')
 check(not entry.Done and f.Data.Destroyed==0 and f.Target.Flag.Value==true,'State update during ownership destroyed a maintained target or changed its state')
end
do
 local f=nativeFixture();f.Data.Owned=false;f.Data.Acquire=false
 local entry=f.Pallet:Request(f.Target.Character,f.Valid);f.Sim:Run(.05,240)
 f.Target.Flag.Value=true;f.Data.Owned=true;f.Sim:Run(.25,240)
 check(entry.Done and entry.Success and f.Pallet.Passes==0 and f.Pallet.StrikeAttempts==0,'One-shot ownership handoff ignored the original state-completion guard')
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
 local before=f.Pallet.Passes;f.Sim:Run(.4,240)
 check(not promoted.Done and f.Pallet.Passes>before,'Promoted maintained request stopped when game state became true')
end
print('PASS: '..checks..' source-native operation parameters, maintained held contacts, unchanged one-shot state contract, ownership, fairness and lifecycle checks (mocked; no real game hit/blur/kick proof)')
-- Explicit collision-query inputs: a persistent overlap must not be counted
-- as many separate placements. These do not emulate accepted server hits.
do
 local f=nativeFixture();local overlap=false;local seen=0
 f.Pallet.Context.Overlaps=function(part,character)check(part==f.Sound and character==f.Target.Character,'Rearm queried wrong pair');return overlap end
 f.Pallet.Context.WaitPhysics=function()f.Sim:Wait(1/60)end
 f.Sim.After=function()if f.Pallet.Passes>seen then seen=f.Pallet.Passes;overlap=true end end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.35,240)
 check(f.Pallet.Passes==1 and entry.ContactPhase=='waiting for physical exit','Persistent contact was rewritten as repeated strikes')
 overlap=false;f.Sim.After=nil;f.Sim:Run(.15,240)
 check(f.Pallet.Passes>1 and(entry.Clearances or 0)>1,'Verified exit did not rearm maintained contact')
 check(not entry.Success and f.Target.Flag.Value==false,'Physical exit was mislabeled as server acceptance')
 f.Pallet:Dispose()
end
do
 local f=nativeFixture();f.Pallet.Context.Overlaps=function()return true end
 f.Pallet.Context.WaitPhysics=function()f.Sim:Wait(1/60)end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.2,240)
 check(f.Pallet.Passes==0,'Unseparated initial overlap admitted placement')
 f.Data.Valid=false;f.Sim:Run(.2,240)
 check(entry.Done and f.Pallet.Passes==0,'Canceled rearm sent a late placement');f.Pallet:Dispose()
end
do
 local f=nativeFixture();f.Pallet.Context.Overlaps=function()error('query unavailable')end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.2,240)
 check(f.Pallet.Passes==0 and f.Pallet.LastError~=nil,'Overlap query failure sent blind repeat placements');f.Pallet:Dispose()
end
print('PASS: physical-exit gate, persistent overlap, retry, query failure and cancellation (mocked; no server hit proof)')
-- The accelerated controller path has an explicit collision query and real
-- physics-frame waits. Its rate cap is a scheduling bound, NOT a game hit or
-- kick threshold. Long frames must never replay missed attempts in a burst.
for _,fps in ipairs({20,60,240,1000})do
 local f=nativeFixture();local samples={};local observed=0
 f.Pallet:SetContactRate(30)
 f.Pallet.Context.Overlaps=function()return false end
 f.Pallet.Context.WaitPhysics=function()return f.Sim.RunService.Heartbeat:Wait()end
 f.Sim.After=function()
  local count=f.Pallet.Passes
  if count~=observed then
   check(count==observed+1,'Accelerated scheduler replayed attempts in one tick at '..fps)
   samples[#samples+1]=f.Sim.Now;observed=count
  end
 end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 -- The first request may place synchronously before the first tick.
 if f.Pallet.Passes>0 then samples[#samples+1]=f.Sim.Now;observed=f.Pallet.Passes end
 f.Sim:Run(1,fps)
 check(#samples>10 and #samples<=31,'Collision-gated scheduling failed its local throughput/cap bound at '..fps)
 check(samples[2]-samples[1]<=math.ceil(fps/30)/fps+1e-6,'A completed physics frame still incurred a redundant extra wait at '..fps)
 for i=2,#samples do
  check(samples[i]-samples[i-1]>=1/30-1e-6,'Accelerated attempts lacked their minimum wall-time separation at '..fps)
 end
 check(not entry.Success and f.Pallet.Confirmed==0 and f.Target.Flag.Value==false and f.Data.GameReactions==0,
  'Faster local scheduling was mislabeled as an accepted hit or kick')
 local before=f.Pallet.Passes;f.Sim:Tick(.7)
 check(f.Pallet.Passes-before<=1,'A stalled physics frame replayed expired attempts')
 f.Pallet:Dispose()
end
-- Only maintained requests use the accelerated path. Even with collision
-- queries installed, an independent one-shot keeps the source polling wait.
do
 local f=nativeFixture();local samples={};local observed=0
 f.Pallet:SetContactRate(30)
 f.Pallet.Context.Overlaps=function()return false end
 f.Pallet.Context.WaitPhysics=function()return f.Sim.RunService.Heartbeat:Wait()end
 local entry=f.Pallet:Request(f.Target.Character,f.Valid)
 if f.Pallet.Passes>0 then samples[1]=f.Sim.Now;observed=f.Pallet.Passes end
 f.Sim.After=function()
  if f.Pallet.Passes~=observed then samples[#samples+1]=f.Sim.Now;observed=f.Pallet.Passes end
 end
 f.Sim:Run(.45,240)
 check(#samples>=4 and #samples<=5,'One-shot polling was accelerated by the maintained-contact path')
 for i=2,#samples do check(samples[i]-samples[i-1]>=.1-1e-6,'One-shot lost the source 100 ms wait')end
 check(not entry.Success and f.Target.Flag.Value==false,'Unaccepted one-shot became successful')
 f.Pallet:Dispose()
end
-- A shared slice budget also governs a collision wait that starts near the
-- end of that slice; it must not get a fresh half-second timeout per rearm.
do
 local f=nativeFixture();local durations={};local native=f.Pallet.Native
 f.Pallet:SetContactRate(30)
 f.Pallet.Context.Overlaps=function()return f.Sim.Now>=.42 end
 f.Pallet.Context.WaitPhysics=function()return f.Sim.RunService.Heartbeat:Wait()end
 f.Pallet.Native=function(character)
  local started=f.Sim.Now;local result=native(character)
  durations[#durations+1]=f.Sim.Now-started;return result
 end
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.65,240)
 check(#durations>=1 and durations[1]<=.5+2/240,
  'Late collision wait extended the native slice by another half second')
 check(f.Pallet.Passes>0 and f.Target.Flag.Value==false,'Budget fixture did not exercise unacknowledged maintained attempts')
 f.Pallet:Dispose()
end
-- Interrupting the shorter post-placement wait must still suppress all late
-- placements and disable the source force on the original owned pallet.
for _,mode in ipairs({'cancel','pause','dispose','dead','respawn','ownership'})do
 local f=nativeFixture()
 f.Pallet:SetContactRate(30)
 f.Pallet.Context.Overlaps=function()return false end
 f.Pallet.Context.WaitPhysics=function()return f.Sim.RunService.Heartbeat:Wait()end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.01,1000)
 local before=f.Pallet.Passes
 if mode=='cancel'then f.Pallet:Cancel(f.Target.Character)
 elseif mode=='pause'then f.Pallet:Pause('accelerated-test',true)
 elseif mode=='dispose'then f.Pallet:Dispose()
 elseif mode=='dead'then f.Target.Humanoid.Health=0
 elseif mode=='respawn'then f.Target.Character.Parent=nil
 else f.Data.Owned=false;f.Data.Acquire=false end
 f.Sim:Run(.3,240)
 check(f.Pallet.Passes==before,'Interrupted accelerated wait placed again: '..mode)
 if mode~='ownership'then
  check(entry.Done and not f.Pallet.Active and not f.Pallet.States.Ragdolling,'Accelerated lifecycle leaked its worker: '..mode)
  local mover=f.Main:FindFirstChild('RagdollBP')
  check(not mover or mover.MaxForce.Magnitude==0,'Accelerated lifecycle left a source force running: '..mode)
 end
 f.Pallet:Dispose()
end
print('PASS: physics-gated maintained scheduling, frame stalls, shared collision budget, unchanged one-shot polling and interruption (mocked; no server hit/kick timing proof)')
-- Invalid rates cannot remove the wall-time bound or silently create an
-- unlimited retry loop. This setting changes scheduling, never game state.
do
 local f=nativeFixture()
 f.Pallet:SetContactRate(1000)
 check(math.abs(f.Pallet.IntervalSeconds-1/30)<1e-8,'Contact-rate upper cap was not enforced')
 f.Pallet:SetContactRate(0)
 check(math.abs(f.Pallet.IntervalSeconds-.2)<1e-8,'Contact-rate lower cap was not enforced')
 for _,invalid in ipairs({math.huge,-math.huge,0/0,'30'})do
  f.Pallet:SetContactRate(invalid)
  check(math.abs(f.Pallet.IntervalSeconds-.2)<1e-8,'Invalid contact rate changed the retry bound')
 end
 f.Pallet:SetContactRate(nil)
 check(math.abs(f.Pallet.IntervalSeconds-.2)<1e-8,'Missing contact rate changed the retry bound')
 f.Pallet:Dispose()
end
-- Heartbeat progress is not proof that a PostSimulation frame happened when
-- the latter signal is available. Exercise their ordering independently.
do
 local f=nativeFixture();local previous=f.Pallet
 previous.Connection:Disconnect();previous.PhysicsConnection:Disconnect()
 local post=f.Sim:Signal();f.Sim.RunService.PostSimulation=post
 local originalPhysics=f.Sim.Physics;local enabled=false;local postCount=0
 f.Sim.Physics=function(dt)
  originalPhysics(dt)
  if enabled then postCount+=1;post:Fire(dt)end
 end
 f.Pallet=Pallet.Install(previous.Context);f.Pallet:SetContactRate(30)
 f.Pallet.Context.Overlaps=function()return false end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 check(f.Pallet.Passes==1,'Independent-post fixture did not make its first source placement')
 f.Sim:Run(.2,60)
 check(f.Pallet.Passes==1,'Heartbeat without PostSimulation admitted another maintained placement')
 local lastPost=0;local observed=1
 f.Sim.After=function()
  if f.Pallet.Passes~=observed then
   check(f.Pallet.Passes==observed+1 and postCount>lastPost,'A placement reused its predecessor physics frame')
   lastPost=postCount;observed=f.Pallet.Passes
  end
 end
 enabled=true;f.Sim:Run(.3,60)
 check(f.Pallet.Passes>5 and not entry.Success,'Independent PostSimulation failed to resume local attempts')
 local observer=f.Pallet.PhysicsConnection
 f.Pallet:Dispose()
 check(not observer.Connected,'PostSimulation observer survived disposal')
 local frame=f.Pallet.PhysicsFrame;post:Fire(1/60)
 check(f.Pallet.PhysicsFrame==frame,'Disposed controller kept observing physical frames')
end
-- Promotion during the original one-shot wait must replace the old predicate
-- and enter collision-gated scheduling without creating a second worker.
do
 local f=nativeFixture();local effect=true;local samples={0};local observed=0
 f.Pallet:SetContactRate(30);f.Pallet.Context.Overlaps=function()return false end
 f.Pallet.Context.WaitPhysics=function()return f.Sim.RunService.Heartbeat:Wait()end
 local first=f.Pallet:Request(f.Target.Character,function()return effect end);observed=f.Pallet.Passes
 f.Sim.After=function()
  if f.Pallet.Passes~=observed then
   check(f.Pallet.Passes==observed+1,'Promoted operation created duplicate placement workers')
   samples[#samples+1]=f.Sim.Now;observed=f.Pallet.Passes
  end
 end
 f.Sim:Run(.02,240)
 local maintained=f.Pallet:Maintain(f.Target.Character,f.Valid);effect=false
 f.Sim:Run(.35,240)
 check(first==maintained and not maintained.Done and #samples>5,'Accelerated promotion retained the obsolete one-shot predicate')
 check(samples[2]>=.1-1e-6,'Promotion discarded the original in-progress one-shot polling wait')
 for i=3,#samples do
  local gap=samples[i]-samples[i-1]
  check(gap>=1/30-1e-6 and gap<=1/30+2/240,'Promoted operation failed bounded accelerated scheduling')
 end
 check(f.Target.Flag.Value==false and not maintained.Success,'Promotion synthesized game acceptance')
 f.Pallet:Dispose()
end
-- Bounded accelerated slices must still share the same pallet fairly across
-- maintained targets, including a target whose Ragdolled flag stays true.
do
 local f=nativeFixture();f.Pallet:SetContactRate(30)
 f.Pallet.Context.Overlaps=function()return false end
 f.Pallet.Context.WaitPhysics=function()return f.Sim.RunService.Heartbeat:Wait()end
 f.Target.Flag.Value=true
 local second=target('AcceleratedSecond',Vector3.new(30,15,0));f.Data.Targets[#f.Data.Targets+1]=second
 local a=f.Pallet:Maintain(f.Target.Character,f.Valid)
 local b=f.Pallet:Maintain(second.Character,f.Valid)
 f.Sim:Run(1.5,240)
 check((a.Passes or 0)>5 and(b.Passes or 0)>5 and not a.Done and not b.Done,'Accelerated source slices starved a maintained target')
 check(f.Target.Flag.Value==true and second.Flag.Value==false,'Accelerated fairness fixture manufactured game-state changes')
 local count=b.Passes or 0;f.Pallet:Cancel(f.Target.Character);f.Sim:Run(.6,240)
 check(a.Done and(b.Passes or 0)>count and not b.Done,'Canceling one accelerated target stopped another')
 f.Pallet:Dispose()
end
print('PASS: independent PostSimulation ordering/disposal, accelerated promotion and multi-target fairness (mocked)')
-- A slow configured rate can outlast the remaining slice budget. Finishing
-- that slice must neither extend its budget nor reset the placement interval.
for _,fps in ipairs({20,60,240,1000})do
 local f=nativeFixture();local samples={};local observed=0;local durations={};local native=f.Pallet.Native
 f.Pallet:SetContactRate(5);f.Pallet.Context.Overlaps=function()return false end
 f.Pallet.Context.WaitPhysics=function()return f.Sim.RunService.Heartbeat:Wait()end
 f.Pallet.Native=function(character)
  local started=f.Sim.Now;local result=native(character)
  durations[#durations+1]=f.Sim.Now-started;return result
 end
 f.Sim.After=function()
  if f.Pallet.Passes~=observed then
   check(f.Pallet.Passes==observed+1,'Slow-rate slice replayed placement attempts')
   samples[#samples+1]=f.Sim.Now;observed=f.Pallet.Passes
  end
 end
 f.Pallet:Maintain(f.Target.Character,f.Valid)
 if f.Pallet.Passes>0 then samples[1]=f.Sim.Now;observed=f.Pallet.Passes end
 f.Sim:Run(1.7,fps)
 check(#samples>=6 and #durations>=2,'Slow-rate fixture did not cross multiple native slices at '..fps)
 for i=2,#samples do
  check(samples[i]-samples[i-1]>=.2-1e-6,'Native slice change reset the slow-rate interval at '..fps)
 end
 for _,duration in ipairs(durations)do
  check(duration<=.5+1/fps+1e-6,'Slow-rate contact wait exceeded its shared slice budget at '..fps)
 end
 f.Pallet:Dispose()
end
-- The cleanup transform itself also needs a subsequent physics frame. Here
-- the next rate window is already open, so only the parked-transform gate
-- prevents an immediate write without a new PostSimulation observation.
do
 local f=nativeFixture();local previous=f.Pallet
 previous.Connection:Disconnect();previous.PhysicsConnection:Disconnect()
 local post=f.Sim:Signal();f.Sim.RunService.PostSimulation=post
 local originalPhysics=f.Sim.Physics;local enabled=true;local postCount=0
 f.Sim.Physics=function(dt)
  originalPhysics(dt)
  if enabled then postCount+=1;post:Fire(dt)end
 end
 f.Pallet=Pallet.Install(previous.Context);f.Pallet:SetContactRate(10)
 f.Pallet.Context.Overlaps=function()return false end
 local park=f.Pallet.Park;local parked=false;local parkedPasses;local parkPost
 f.Pallet.Park=function(self)
  park(self)
  if self.Passes>0 and not parked then
   parked=true;parkedPasses=self.Passes;parkPost=postCount;enabled=false
  end
 end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.7,1000)
 check(parked and parkedPasses>=4,'Parked-transform fixture did not complete its first native slice')
 check(f.Pallet.Passes==parkedPasses and postCount==parkPost,
  'A parked pallet was placed again without a later PostSimulation frame')
 enabled=true;f.Sim:Run(.11,1000)
 check(f.Pallet.Passes>parkedPasses and not entry.Success,
  'A later physical frame did not release the parked-transform gate')
 f.Pallet:Dispose()
end
print('PASS: slow-rate intervals across bounded slices and physics after parking (mocked)')
