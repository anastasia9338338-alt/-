-- Engine-independent rigid-body checks, never server-hit acknowledgements.
local function close(a,b)return(a-b).Magnitude<1e-6 end
local function overlap(a,b)
 local d=a.Position-b.Position;local h=(a.Size+b.Size)*.5
 return math.abs(d.X)<h.X and math.abs(d.Y)<h.Y and math.abs(d.Z)<h.Z
end
local function controlled(options)
 options=options or{}
 local f=fixture(Pallet);local previous=f.Pallet
 previous.Connection:Disconnect();previous.PhysicsConnection:Disconnect();previous.Ownership:Dispose()
 local root=newNode('Part','HumanoidRootPart',f.Target.Character);root.Position=f.Target.Torso.Position+Vector3.new(15,4,6)
 local receiver=newNode('Part','RagdollTouchedHitbox',root);receiver.Position=root.Position;receiver.CanQuery=false
 f.Target.Receiver=receiver;f.Sound.CanQuery=false
 f.Data.GameAccept=false
 local queryCount=0
 local ctx=previous.Context
 ctx.ReceiverOverlaps=function(part,expected)
  queryCount+=1
  check(part==f.Sound and expected==(f.Target.Receiver or f.Target.Torso),'Wrong physical receiver was queried')
  if options.Unavailable or part.CanQuery~=true then return nil end
  if options.Persistent then return true end
  return overlap(part,expected)
 end
 f.Pallet=Pallet.Install(ctx);f.Pallet:SetContactRate(options.Rate or 30)
 return f,root,receiver,function()return queryCount end
end
for _,fps in ipairs({20,60,240,1000})do
 local f,root,receiver,queries=controlled()
 local rootPosition,torsoPosition=root.Position,f.Target.Torso.Position
 local delta=f.Sound.Position-f.Main.Position
 local oldWrite=Node.__newindex;local stagedWrites=0
 Node.__newindex=function(node,key,value)
  oldWrite(node,key,value)
  if (key=='CFrame'or key=='Position')and(node==f.Main or node==f.Sound)then
   stagedWrites+=1
   check(not overlap(f.Sound,receiver),'A CFrame write was counted as physical receiver entry')
  end
 end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 check(entry.Receiver==receiver and entry.ReceiverKind=='RagdollTouchedHitbox','Maintained sweep still targets Torso instead of named receiver')
 check(f.Sound.CanQuery==true and receiver.CanQuery==false,'Controller changed receiver query properties or failed own-query setup')
 f.Sim.After=function()
  check(close(f.Sound.Position-f.Main.Position,delta),'Sweeping moved SoundPart relative to rigid assembly')
  check(close(root.Position,rootPosition)and close(f.Target.Torso.Position,torsoPosition),'Sweeping moved target character')
  local mover=f.Main:FindFirstChild('RagdollBP')
  check(not mover or mover.MaxForce.Magnitude==0,'Controlled sweep retained world-origin infinite lift')
  if f.Main.AssemblyLinearVelocity.Y>0 then
   check(math.abs(f.Main.AssemblyLinearVelocity.X)<1e-6 and math.abs(f.Main.AssemblyLinearVelocity.Z)<1e-6,'Pallet darts sideways toward world origin')
   check(f.Main.AssemblyLinearVelocity.Y<=80,'Sweep velocity exceeded its bound')
  end
 end
 f.Sim:Run(1,fps)
 Node.__newindex=oldWrite
 check((entry.PhysicalEntries or 0)>0 and(entry.PhysicalExits or 0)>0,'No physical entry/exit through the offset game receiver at '..fps)
 check((entry.ReceiverContacts or 0)>0 and #f.Data.Crossings>0,'Geometry crossing did not deliver fixture physical contact at '..fps)
 check(entry.EntryFrame>entry.PlacedFrame or(entry.SweepPasses or 0)>1,'Entry reused a placement frame')
 check(stagedWrites>0 and queries()>0,'Fixture did not exercise assembly staging and receiver queries')
 check(f.Target.Flag.Value==false and f.Pallet.Confirmed==0 and not entry.Success,'Local sweep manufactured server acceptance')
 local evidence=f.Pallet:Evidence().Entries[1]
 check(evidence.PhysicalSweepAttempts>0 and evidence.SourcePlacements==0,'Controlled sweeps mislabeled as original source placements')
 f.Pallet:Cancel(f.Target.Character);f.Sim:Run(.2,fps)
 check(entry.Done and not f.Pallet.Active and not f.Pallet.States.Ragdolling,'Controlled cancellation leaked a worker')
 f.Pallet:ForgetModel();check(f.Sound.CanQuery==false,'Owned query flag was not restored')
end
for _,mode in ipairs({'cancel','pause','dispose','dead','respawn','ownership','receiver'})do
 local f,root,receiver=controlled();local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(.01,1000)
 if mode=='cancel'then f.Pallet:Cancel(f.Target.Character)
 elseif mode=='pause'then f.Pallet:Pause('sweep-test',true)
 elseif mode=='dispose'then f.Pallet:Dispose()
 elseif mode=='dead'then f.Target.Humanoid.Health=0
 elseif mode=='respawn'then f.Target.Character.Parent=nil
 elseif mode=='receiver'then receiver.Parent=nil;f.Target.Receiver=nil
 else f.Data.Owned=false;f.Data.Acquire=false end
 local passes=f.Pallet.Passes;local teleports=f.Main.Teleports
 f.Sim:Run(.3,240)
 if mode=='receiver'then check(entry.Receiver~=receiver,'Removed game receiver remained selected')else check(f.Pallet.Passes==passes,'Controlled interruption launched another sweep: '..mode)end
 if mode=='ownership'then check(f.Main.Teleports==teleports,'Lost ownership still teleported pallet')end
 local lift=f.Main:FindFirstChild('RagdollBP');check(not lift or lift.MaxForce.Magnitude==0,'Interrupted sweep left uncontrolled lift: '..mode)
 if mode~='ownership'and mode~='receiver'then check(entry.Done or not f.Pallet:EntryValid(entry),'Interrupted controlled entry stayed valid: '..mode)end
 f.Pallet:Dispose()
end
for _,mode in ipairs({'Unavailable','Persistent'})do
 local f=controlled({[mode]=true});local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.4,240)
 check(f.Pallet.Passes==0 and(entry.PhysicalEntries or 0)==0,'Invalid separation query launched a physical sweep: '..mode)
 if mode=='Unavailable'then check(f.Pallet.LastError~=nil,'Unknown collision query became verified separation')end
 f.Pallet:Dispose()
end
do
 local f,root,receiver=controlled();local foreign=newNode('Part','ForeignAssembly',WORLD);f.Sound.AssemblyRootPart=foreign
 local before=f.Sound.Teleports;local foreignMoves=foreign.Teleports;f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.3,240)
 check(f.Pallet.Passes==0 and f.Sound.Teleports==before and foreign.Teleports==foreignMoves,'Controlled sweep or cleanup moved an external assembly')
 f.Pallet:Dispose()
end
do
 local f,root,receiver=controlled();root:FindFirstChild('RagdollTouchedHitbox'):Destroy();f.Target.Receiver=nil
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.5,240)
 check(entry.Receiver==f.Target.Torso and(entry.PhysicalEntries or 0)>0,'Missing named receiver lost the original Torso fallback')
 f.Pallet:Dispose()
end
do
 local f,root,receiver=controlled();local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 local effect=f.Target.Head:FindFirstChild('PartOwner');effect:Destroy();f.Sim:Run(.4,240)
 check((entry.PhysicalEntries or 0)>0,'Unrelated Head owner marker suppressed physical maintained contacts')
 f.Pallet:Dispose()
end
print('PASS: '..checks..' controlled receiver sweep, physical geometry/rigid offsets, no world-origin force, query/lifecycle and unchanged game-state checks (mocked; no server kick timing)')
do
 local f,root,receiver,queries=controlled()
 check(f.Pallet:Prepare(f.Valid)and f.Sound.CanQuery==false,'Warm changed the original one-shot query properties')
 local first=f.Pallet:Request(f.Target.Character,f.Valid);f.Sim:Run(.02,240)
 check(f.Sound.CanQuery==false and queries()==0,'Independent one-shot entered the controlled query path')
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.3,240)
 check(f.Sound.CanQuery and queries()>0 and(first.SweepPasses or 0)>0,'Existing bound source pallet did not enable queries after continuous promotion')
 f.Pallet:Cancel(f.Target.Character);f.Sim:Run(.2,240);f.Pallet:ForgetModel()
 check(f.Sound.CanQuery==false,'Promoted board query state failed to restore')
end
if ActualReceiverOverlaps then
 local part={Parent={},CanQuery=true,CollisionGroup='Grabbed'}
 local receiver={Parent={},CanQuery=false,CanTouch=true,CollisionGroup='Character'}
 QueryData.Part,QueryData.Receiver=part,receiver
 QueryData.Groups={Grabbed={Grabbed=false},Default={Grabbed=true}}
 QueryData.Registered={{name='Grabbed'},{name='Default'}}
 QueryData.Overlap=true
 check(ActualReceiverOverlaps(part,receiver)==true,'Actual Main query failed CanQuery=false receiver or nonself-colliding pallet group')
 check(QueryData.LastShape==receiver and QueryData.LastQuery.FilterDescendantsInstances[1]==part and QueryData.LastQuery.CollisionGroup=='Default','Actual query did not reverse owned part or select a collidable query group')
 check(receiver.CanQuery==false and part.CollisionGroup=='Grabbed','Query mutated a real collision group or remote receiver')
 QueryData.Overlap=false;check(ActualReceiverOverlaps(part,receiver)==false,'Actual separated geometry became unknown')
 QueryData.Fail=true;check(ActualReceiverOverlaps(part,receiver)==nil,'Query failure became verified separation');QueryData.Fail=false
 part.CanQuery=false;check(ActualReceiverOverlaps(part,receiver)==nil,'Unqueryable owned part became verified separation');part.CanQuery=true
 QueryData.Groups.Default.Grabbed=false;check(ActualReceiverOverlaps(part,receiver)==nil,'No collidable query group became verified separation')
 QueryData.Groups.Grabbed.Grabbed=true;QueryData.Overlap=true
 check(ActualReceiverOverlaps(part,receiver)==true and QueryData.LastQuery.CollisionGroup=='Grabbed','Self-collidable owned group was unnecessarily changed')
end
print('PASS: controlled path promotion/one-shot query isolation and exact Main reversed receiver query (mocked)')

do
 local f=controlled();local entry=f.Pallet:Request(f.Target.Character,f.Valid)
 f.Target.Head:FindFirstChild('PartOwner'):Destroy();f.Sim:Run(.15,240)
 check(entry.Done and f.Pallet.Passes==1 and(entry.SweepPasses or 0)==0,'Modern integration changed one-shot source marker-loss termination')
 f.Pallet:Dispose()
end
-- Production gravity and solver substeps are independent of the observation
-- rate. Only integration generates Touched: CFrame staging stays separated.
local function gravitational(options)
 options=options or{}
 local f,root,receiver=controlled(options)
 local g=options.Gravity or 196.2
 f.Pallet.Context.Gravity=function()return g end
 if options.Thin then receiver.Size=Vector3.new(2,.02,2);f.Sound.Size=Vector3.new(2,.05,2)end
 local integrate=f.Sim.Physics
 f.Sim.Physics=function(dt)
  local steps=math.max(1,math.ceil(dt*480));local step=dt/steps
  for _=1,steps do
   if f.Data.Owned and not f.Data.Blocked and f.Main.Parent then
    local velocity=f.Main.AssemblyLinearVelocity-Vector3.new(0,g*step,0)
    f.Main.AssemblyLinearVelocity=velocity;f.Sound.AssemblyLinearVelocity=velocity
   end
   integrate(step)
  end
 end
 if options.Moving then f.Sim.Before=function(dt)
  local shift=Vector3.new(dt*9,0,0)
  receiver.Position=receiver.Position+shift;root.Position=root.Position+shift
  -- The hold controller can reposition a limb without reporting matching
  -- assembly velocity. Feedback must follow current receiver geometry.
  receiver.AssemblyLinearVelocity=Vector3.zero
 end end
 return f,root,receiver
end
for _,fps in ipairs({15,20,60,240,1000})do
 local f,root,receiver=gravitational({Thin=true})
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(1.5,fps)
 check((entry.PhysicalEntries or 0)>=4 and(entry.PhysicalExits or 0)>=4,'Thin receiver stalls under gravity at '..fps..' FPS')
 check((entry.ReceiverContacts or 0)>0,'Gravity regression manufactured a physical entry without solver contact')
 check(f.Target.Flag.Value==false and f.Pallet.Confirmed==0,'Gravity feedback manufactured game ragdoll acceptance')
 f.Pallet:Dispose()
end
do
 local f=gravitational({Moving=true});local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(2,60)
 check((entry.PhysicalEntries or 0)>=20 and(entry.PhysicalExits or 0)>=20,'Pallet fails to follow receiver moved by hold controller')
 check((entry.ReusedExitFrames or 0)>0,'Every normal strike still pays a redundant fresh staging frame')
 local entries,passes=entry.PhysicalEntries,entry.Passes
 check(entries<=60 and passes<=60,'Alternating sweep bypassed 30/s global attempt cap')
 print(string.format('INFO: 2s local gravity/moving-receiver integration: %d physical entries, %d bounded attempts; not server kick timing',entries,passes))
 f.Pallet:Dispose()
end
do
 local f=gravitational({Rate=5});local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(2,60)
 check((entry.SweepPasses or 0)<=10,'Low-rate waiting generated excess normal strike attempts')
 local observed=entry.ReceiverContacts or 0
 check(observed<=(entry.SweepPasses or 0),'Board fell back through the receiver while waiting for a slower rate')
 f.Pallet:Cancel(f.Target.Character);local contacts=entry.ReceiverContacts or 0;f.Sim:Run(.5,60)
 check((entry.ReceiverContacts or 0)==contacts,'Cancelled board kept falling through receiver under gravity')
 f.Pallet:Dispose()
end
print('PASS: gravity/thin-trigger feedback, real Touched latch, moving hold receiver, reused physical exit and slow-rate isolation (mocked; no server speed proof)')

-- Requested pulse sequence is conditional on real fixture touch delivery,
-- independently observed game ragdoll state and an airborne/physical hold.
local function pulsed(accepted,held,already)
 local f=gravitational();f.Data.GameAccept=accepted;f.Data.Held=held
 f.Target.Flag.Value=already==true
 f.Pallet.Context.Held=function(character)return character==f.Target.Character and f.Data.Held end
 f.Pallet.Context.PingSeconds=function()return .05 end
 f.Pallet:SetPulsed(true);f.Pallet:SetPulsePause(.15);f.Pallet:SetPulseBurst(3);f.Pallet:SetPulseRecovery(.4)
 return f
end
for _,fps in ipairs({20,60,240})do
 local f=pulsed(true,true,false);local e=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(2.8,fps)
 local hits=f.Data.Crossings
 check(#hits>=5,'Pulse sequence never reached a real bounded series at '..fps)
 check(hits[2].At-hits[1].At>=.15-1/fps-1e-5,'Second isolated hit has no configured pause')
 check(hits[3].At-hits[2].At>=.15-1/fps-1e-5,'Series starts without the second-hit pause')
 check(hits[4].At-hits[3].At<.15+2/fps and hits[5].At-hits[4].At<.15+2/fps,'Bounded burst is still paced like isolated hits')
 if hits[6]then check(hits[6].At-hits[5].At>=.4-1/fps-1e-5,'After-burst recovery setting is ignored')end
 check(f.Data.GameReactions>=2 and(e.ReceiverContacts or 0)>=5,'Pulse logic invented observed game reactions or contacts')
 f.Data.Held=false;local passes=e.Passes;f.Sim:Run(.5,fps)
 check(e.Passes==passes and not e.Pulse,'Loss of physical airborne hold keeps a pending series')
 f.Data.Held=true;f.Sim:Run(.4,fps);check(e.Pulse~=nil,'Recovered hold never starts a fresh pulse')
 f.Pallet:Cancel(f.Target.Character);passes=e.Passes;f.Sim:Run(.5,fps);check(e.Passes==passes,'Pulse continues after cancellation')
 f.Pallet:Dispose()
end
do
 local f=pulsed(false,true,false);local e=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(2,60)
 check((e.ReceiverContacts or 0)>0 and f.Data.GameReactions==0,'Missing-game-reaction fixture did not produce independent local touch input')
 check(not e.Pulse or e.Pulse.Phase~='burst','No game ragdoll reaction still triggers a burst')
 check((e.SweepPasses or 0)<=6,'Unacknowledged hits degrade to a permanent continuous stream')
 f.Pallet:Dispose()
end
do
 local f=pulsed(false,false,false);local e=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.5,60)
 check((e.Passes or 0)==0,'Grounded/unowned hold starts strikes')
 f.Pallet:Dispose()
end
do
 local f=pulsed(false,true,true);local e=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1.5,60)
 check((e.ReceiverContacts or 0)>=4 and f.Data.GameReactions==0 and e.Reaction.Rises==0,'Existing ragdoll state becomes invented fresh game reactions')
 f.Pallet:Dispose()
end
print('PASS: state-aware isolated hits, pause/second hit/bounded burst/recovery, actual contacts, airborne hold, missing-reaction retries and cancellation (mocked; no server kick prediction)')

-- A captured avatar may need a real first ragdoll before its hold mover can
-- lift it. This is a bounded initial pass, never an unheld burst stream.
local function initialCaptured(accepted)
 local f,root,receiver=gravitational();f.Data.GameAccept=accepted;f.Data.Held=false;f.Data.InitialReady=true
 f.Pallet.Context.Held=function(character)return character==f.Target.Character and f.Data.Held end
 f.Pallet.Context.InitialContactReady=function(character)return character==f.Target.Character and f.Data.InitialReady end
 f.Pallet.Context.PingSeconds=function()return .05 end
 f.Pallet:SetPulsed(true);f.Pallet:SetPulsePause(.15);f.Pallet:SetPulseBurst(3);f.Pallet:SetPulseRecovery(.4)
 return f,root,receiver
end
for _,fps in ipairs({20,60,240})do
 local f,root,receiver=initialCaptured(true);local rootPosition=root.Position;local torsoPosition=f.Target.Torso.Position
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(.35,fps)
 check(#f.Data.Crossings==1 and(entry.PhysicalEntries or 0)==1 and(entry.PhysicalExits or 0)==1,'Captured initial contact did not physically enter/exit exactly once before airborne hold at '..fps)
 check(not entry.Pulse and entry.InitialContact and entry.InitialContact.Pulse.Phase=='pause_first','Initial pass started an unheld burst or lost its first-contact observation')
 check(root.Position==rootPosition and f.Target.Torso.Position==torsoPosition,'Initial contact moved target anatomy instead of the pallet')
 f.Data.Held=true;f.Sim:Run(2,fps)
 check(#f.Data.Crossings>=4 and not entry.InitialContact,'A stable airborne hold did not promote the initial physical contact into maintained pulses')
 check(f.Data.Crossings[2].At-f.Data.Crossings[1].At>=.15-1/fps-1e-5,'Initial-to-maintained handoff skipped the existing isolated-hit pause')
 f.Pallet:Dispose()
end
do
 local f=initialCaptured(false);local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(2,60)
 check(#f.Data.Crossings>=1 and #f.Data.Crossings<=5,'Missing game reaction caused unbounded unheld initial contacts')
 for i=2,#f.Data.Crossings do check(f.Data.Crossings[i].At-f.Data.Crossings[i-1].At>=.4-1/60-1e-5,'Initial retry ignored the existing recovery window')end
 check(not entry.Pulse and f.Data.GameReactions==0 and f.Pallet.Confirmed==0,'Unheld initial pass fabricated a game reaction or burst')
 f.Pallet:Dispose()
end
for _,mode in ipairs({'capture','cancel','pause','dispose','dead','respawn','ownership'})do
 local f=initialCaptured(false);local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.01,1000)
 if mode=='capture'then f.Data.InitialReady=false
 elseif mode=='cancel'then f.Pallet:Cancel(f.Target.Character)
 elseif mode=='pause'then f.Pallet:Pause('initial-contact-test',true)
 elseif mode=='dispose'then f.Pallet:Dispose()
 elseif mode=='dead'then f.Target.Humanoid.Health=0
 elseif mode=='respawn'then f.Target.Character.Parent=nil
 else f.Data.Owned=false;f.Data.Acquire=false end
 local passes=f.Pallet.Passes;f.Sim:Run(.5,240)
 check(f.Pallet.Passes==passes,'An invalidated initial capture launched a new physical pass: '..mode)
 check(not entry.Pulse and not entry.InitialActive,'Initial pulse state survived loss/cancellation: '..mode)
 f.Pallet:Dispose()
end
print('PASS: captured first physical entry/exit, airborne promotion, isolated recovery and initial-contact lifecycle (mocked; no faster rate values)')

do
 local f=initialCaptured(false);local delayed=false
 f.Sim.After=function()
  if not delayed and #f.Data.Crossings>0 and f.Sim.Now>=f.Data.Crossings[1].At+.05 then
   delayed=true;f.Target.Flag.Value=true -- independent delayed GAME input
  end
 end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1.1,60)
 check(delayed and entry.Reaction.Rises==1,'Fixture did not expose a delayed ragdoll reaction')
 check(#f.Data.Crossings==1 and entry.InitialContact and entry.InitialContact.GameObserved,'Delayed accepted first reaction was ignored and retried while unheld')
 check(not entry.Pulse and f.Pallet.Confirmed==0,'Delayed game input was fabricated into a fresh burst/kick acknowledgement')
 f.Pallet:Dispose()
end
for _,fps in ipairs({20,60,240})do
 local f,root,receiver=controlled();local velocity=Vector3.new(22,12,6);local gravity=196.2
 receiver.AssemblyLinearVelocity=velocity;f.Pallet.Context.Gravity=function()return gravity end
 local physics=f.Sim.Physics;local entry;local stages=0
 f.Sim.Physics=function(dt)
  -- Integrate both bodies in the SAME physical substeps; PreSimulation does
  -- not teleport the receiver ahead of the board's later solver step.
  local steps=math.max(1,math.ceil(dt*480));local step=dt/steps
  for _=1,steps do
   local delta=velocity*step;receiver.Position=receiver.Position+delta;root.Position=root.Position+delta
   if f.Data.Owned and not f.Data.Blocked and f.Main.Parent then
    local v=f.Main.AssemblyLinearVelocity-Vector3.new(0,gravity*step,0)
    f.Main.AssemblyLinearVelocity=v;f.Sound.AssemblyLinearVelocity=v
   end
   physics(step)
  end
  if entry and entry.ContactPhase=='staged below receiver'then
   stages+=1;local delta=receiver.Position-f.Sound.Position
   check(math.abs(delta.X)<1e-6 and math.abs(delta.Z)<1e-6,'Clear staging lost the moving receiver reference frame at '..fps)
   check(not overlap(f.Sound,receiver),'Co-moving staging teleported into the receiver')
  end
 end
 entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1.5,fps)
 check(stages>0 and(entry.PhysicalEntries or 0)>0 and(entry.PhysicalExits or 0)>0,'Moving-reference staging did not produce real entry/exit at '..fps)
 check(f.Target.Flag.Value==false and f.Pallet.Confirmed==0,'Co-moving staging manufactured game acceptance')
 f.Pallet:Dispose()
end
print('PASS: delayed first-reaction observation and co-moving clear staging with unchanged relative sweep/rate limits (mocked)')

do
 local f=pulsed(true,true,false);local entry;local locked,waiting=0,0
 f.Sim.After=function()
  if f.Pallet:IsContactActive()then locked+=1 end
  if entry and entry.ContactPhase and entry.ContactPhase:match('^pulse ')then
   waiting+=1;check(not f.Pallet:IsContactActive(),'Isolated-hit recovery monopolized the shared ownership channel')
  end
 end
 entry=f.Pallet:Maintain(f.Target.Character,f.Valid);check(f.Pallet:IsContactActive(),'Actual staging failed to reserve the native ownership channel')
 f.Sim:Run(2,60);check(locked>0 and waiting>0,'Reservation fixture did not cover physical crossing and pulse waits')
 f.Pallet:Cancel(f.Target.Character);check(not f.Pallet:IsContactActive()and not entry.ContactInFlight,'Cancellation retained the contact reservation')
 f.Pallet:Dispose()
end
do
 local f=controlled();local oldWrite=Node.__newindex;local thrown=false
 Node.__newindex=function(node,key,value)
  if not thrown and node==f.Main and key=='CFrame'and f.Pallet:IsContactActive()then
   thrown=true;error('simulated physical stage failure')
  end
  return oldWrite(node,key,value)
 end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.02,1000)
 Node.__newindex=oldWrite
 check(thrown and f.Pallet.LastError and not f.Pallet:IsContactActive()and not entry.ContactInFlight,'Physical-stage error leaked the shared grab reservation')
 f.Pallet:Dispose()
end
print('PASS: narrow physical-contact reservation, unlocked pulse recovery and guaranteed error/cancel cleanup (mocked)')
