-- These cases require separated -> overlapping transitions caused by velocity
-- integration. A placement or an explicit touch API call cannot satisfy them.
-- The fixture does not emulate a Roblox server or certify a successful kick.
for _,fps in ipairs({20,30,60,120,240,480,1000})do
 local f=fixture(Pallet);local physics=f.Sim.Physics
 f.Sim.Physics=function(dt)
  local before=f.Main.Position;physics(dt)
  check(math.abs(f.Main.Position.Y-before.Y)<=48*dt+1e-5,'Physical crossing skipped its bounded step at '..fps)
 end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(2,fps)
 check(not entry.Done and f.Pallet.Active==entry,'Continuous strikes stopped during external mocked game reactions at '..fps)
 check(#f.Data.Crossings>=5,'No repeated velocity-driven contact entries at '..fps)
 check(f.Pallet.Contacts==#f.Data.Crossings,'Observed natural contacts and fixture crossings diverged')
 check(f.Pallet.StrikeAttempts<=14,'Rendering FPS inflated physical strike scheduling')
 for _,cross in ipairs(f.Data.Crossings)do
  check(cross.Velocity.Y<0 and cross.Velocity.Y>=-48,'Crossing lacked bounded downward relative velocity')
  check(cross.Lift==0,'Opposing native lift remained enabled during a continuous strike')
 end
 local before=#f.Data.Crossings
 f.Target.Head:FindFirstChild('PartOwner'):Destroy();f.Sim:Run(.4,fps)
 check(#f.Data.Crossings>before,'Target owner-marker churn stopped the separate board worker')
 f.Data.Valid=false;f.Sim:Run(.1,fps);before=#f.Data.Crossings;f.Sim:Run(.3,fps)
 check(#f.Data.Crossings==before and entry.Done and not f.Pallet.Active,'Stopped kick left physical strikes alive')
 check(f.Main.AssemblyLinearVelocity.Magnitude==0,'Park did not stop the pallet assembly')
 check(f.Main:FindFirstChild('RagdollBP').MaxForce.Magnitude==0,'Park left native lift enabled')
 check(not f.Pallet.States.Ragdolling and not f.Pallet.LastError,'Cancellation leaked busy/error state')
end
do
 local f=fixture(Pallet);f.Data.Accept=false
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1,240)
 check(f.Pallet.StrikeAttempts>0 and #f.Data.Crossings>0,'Rejected contacts never attempted a physical crossing')
 check(f.Pallet.Contacts==0 and f.Pallet.Confirmed==0,'A crossing was presented as an observed touch or server hit')
 local entry=f.Pallet.Entries[f.Target.Character]
 check(entry.Reaction:Describe().Rises>0,'External game acceptance depended on delivery of a local touch callback')
end
for _,fps in ipairs({20,60,240,1000})do
 local f=fixture(Pallet)
 f.Sim.Before=function(dt)
  f.Target.Torso.Position+=Vector3.new(32*dt,0,0)
  f.Target.Torso.AssemblyLinearVelocity=Vector3.new(32,0,0)
 end
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(2,fps)
 check(#f.Data.Crossings>=5,'Physical striker lost a moving held target at '..fps)
 for _,cross in ipairs(f.Data.Crossings)do check(math.abs(cross.Velocity.X)<8,'Lateral follow lost target-relative velocity')end
end
do
 local f=fixture(Pallet,false);f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(2,60)
 check(#f.Data.Crossings>=5,'Heartbeat fallback lost physical crossings')
end
do
 local f=fixture(Pallet);f.Target.Flag.Value=false;local effect=true
 local one=f.Pallet:Request(f.Target.Character,function()return effect end)
 local promoted=f.Pallet:Maintain(f.Target.Character,f.Valid);effect=false;f.Sim:Run(2,240)
 check(one==promoted and not one.Done and #f.Data.Crossings>=5,'One-shot predicate canceled a promoted physical kick')
 f.Data.Valid=false;f.Sim:Run(.1,240);check(one.Done and not f.Pallet.Active,'Promoted kick ignored cancellation')
end
for _,mode in ipairs({'cancel','pause','dispose','dead','respawn'})do
 local f=fixture(Pallet);local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.4,240)
 if mode=='cancel'then f.Pallet:Cancel(f.Target.Character)
 elseif mode=='pause'then f.Pallet:Pause('test',true)
 elseif mode=='dispose'then f.Pallet:Dispose()
 elseif mode=='dead'then f.Target.Humanoid.Health=0
 else f.Target.Character.Parent=nil end
 f.Sim:Run(.1,240);local before=#f.Data.Crossings;f.Sim:Run(.4,240)
 check(#f.Data.Crossings==before and entry.Done and not f.Pallet.Active,'Physical strike lifecycle failed: '..mode)
 check(not f.Pallet.States.Ragdolling and not f.Pallet.LastError,'Stop became an error: '..mode)
end
do
 local f=fixture(Pallet);local second=target('Second',Vector3.new(30,15,0));f.Data.Targets[#f.Data.Targets+1]=second
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Pallet:Maintain(second.Character,f.Valid);f.Sim:Run(2,240)
 local counts={};for _,cross in ipairs(f.Data.Crossings)do counts[cross.Target]=(counts[cross.Target]or 0)+1 end
 check((counts[f.Target]or 0)>=3 and(counts[second]or 0)>=3,'Queued physical kick targets starved each other')
end
do
 local f=fixture(Pallet);f.Data.Owned=false;f.Data.Acquire=false
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1,240)
 check(#f.Data.Crossings==0 and f.Pallet.StrikeAttempts==0,'An unowned pallet attempted a physical strike')
 check(f.Data.Acquires<=12,'Unacknowledged ownership flooded acquisition')
 f.Data.Acquire=true;f.Sim:Run(1,240);check(#f.Data.Crossings>0,'Cached board failed to resume physical strikes after ownership returned')
end
do
 local f=fixture(Pallet);f.Target.Flag.Value=true
 local entry=f.Pallet:Request(f.Target.Character,f.Valid);f.Sim:Run(.2,60)
 check(entry.Done and entry.Success and f.Pallet.StrikeAttempts==0,'Independent one-shot became a continuous striker')
end
do
 local f=fixture(Pallet);f.Target.Flag.Value=false
 local entry=f.Pallet:Request(f.Target.Character,f.Valid);f.Target.Flag.Value=true;f.Sim:Run(.2,60)
 check(entry.Done and entry.Success,'One-shot lost its native ragdoll acknowledgment')
end
do
 local f=fixture(Pallet);f.Data.Owned=false;f.Data.Ack=false
 local moves=f.Sound.Teleports;f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.1,240)
 check(f.Pallet.StrikeAttempts==0 and f.Sound.Teleports==moves,'Owner marker was mistaken for completed physics handoff')
 f.Data.Owned=true;f.Sim:Run(.5,240)
 check(f.Data.Acquires==1 and #f.Data.Crossings>0,'Delayed physics handoff forced repeated acquisition')
end
do
 local f=fixture(Pallet);f.Data.Owned=false;f.Data.Ack=false
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.05,240);f.Data.Valid=false;f.Sim:Run(.1,240)
 check(entry.Done and not f.Pallet.Active and not f.Pallet.States.Ragdolling,'Canceled handoff leaked busy state')
end
do
 local f=fixture(Pallet);f.Data.Blocked=true
 local second=target('BlockedSecond',Vector3.new(30,15,0));f.Data.Targets[#f.Data.Targets+1]=second
 local a=f.Pallet:Maintain(f.Target.Character,f.Valid);local b=f.Pallet:Maintain(second.Character,f.Valid);f.Sim:Run(2,240)
 check((a.StrikeAttempts or 0)>=2 and(b.StrikeAttempts or 0)>=2,'Blocked strike never timed out to let another target proceed')
 check(f.Pallet.Contacts==0,'Blocked velocity was counted as a contact')
end
for _,mode in ipairs({'cancel','pause','dispose'})do
 local f=fixture(Pallet);local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.1,240)
 f.Pallet.Context.ParkPosition=function()error('forced park failure')end
 local ok=pcall(function()if mode=='cancel'then f.Pallet:Cancel(f.Target.Character)elseif mode=='pause'then f.Pallet:Pause('error-test',true)else f.Pallet:Dispose()end end)
 check(ok and f.Pallet.LastError~=nil,'Park failure escaped cleanup: '..mode)
 f.Sim:Run(.1,240);check(entry.Done and not f.Pallet.Active and not f.Pallet.States.Ragdolling,'Park failure stranded worker: '..mode)
end
do
 local f=fixture(Pallet);f.Data.Owned=false;f.Data.Acquire=false
 f.Pallet.Context.Find=function()return nil end;f.Pallet:Bind(f.Model)
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.5,240)
 check(f.Data.Acquires>0 and f.Data.Spawns==0,'Pending native pallet was replaced before ownership acknowledgment')
end
do
 local f=fixture(Pallet)
 check(f.Pallet:Prepare(f.Valid)and f.Pallet.Model==f.Model and f.Data.Spawns==0,'Preparation ignored a healthy native pallet')
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.2,60)
 local before=f.Pallet.StrikeAttempts;check(f.Pallet:Prepare(f.Valid),'Active ready pallet was rejected')
 f.Sim:Run(.3,60);check(not entry.Done and f.Pallet.StrikeAttempts>before,'Preparation interrupted an active kick')
end
do
 local f=fixture(Pallet);f.Pallet.Context.Find=function()return nil end;f.Pallet.Context.CanSpawn=function()return false,'Build area unavailable'end
 check(not f.Pallet:Prepare(f.Valid)and f.Data.Spawns==0 and not f.Pallet.Preparing,'Preparation spawned outside the build area or leaked its lock')
 f.Pallet:Dispose();check(not f.Pallet:Prepare(f.Valid),'Disposed pallet controller still prepared a toy')
end
do
 local f=fixture(Pallet);local apiCalls=0
 f.Pallet.Context.Touch=function()apiCalls+=1;error('synthetic touch deliberately unavailable')end
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1,240)
 check(#f.Data.Crossings>=3 and apiCalls==0,'Continuous physical strikes depended on an injected touch API')
end
do
 local f=fixture(Pallet);f.Main.LocalTransparencyModifier=.12;f.Sound.Transparency=1
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(2,240)
 local hits=f.Data.Crossings
 check(#hits>=6,'Physical probe/burst sequence did not complete')
 check(hits[1].Velocity.Y==-28 and hits[2].Velocity.Y==-48 and hits[5].Velocity.Y==-48 and hits[6].Velocity.Y==-28,'Physical velocities did not follow single/four-burst/single cadence')
 check(hits[2].At-hits[1].At>hits[3].At-hits[2].At+.04,'Hover gap was not distinct from the fast physical series')
 check(f.Main.LocalTransparencyModifier==.45 and f.Sound.LocalTransparencyModifier~=.45,'Pallet visibility changed invisible trigger geometry')
 f.Pallet:Dispose();check(f.Main.LocalTransparencyModifier==.12,'Pallet cleanup did not restore its original local transparency')
end
do
 local f=fixture(Pallet);f.Data.Blocked=true
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1,240)
 check(#f.Data.Crossings==0,'Blocked stroke was reported as a physical hit')
 local evidence=f.Pallet:Evidence().Entries[1]
 check(evidence.StrokeAttempts>0 and evidence.PhysicalTraversals==0,'Blocked stroke launches were reported as completed physical traversals')
 f.Data.Blocked=false;f.Sim:Run(.5,240)
 check(#f.Data.Crossings>0 and f.Data.Crossings[1].Velocity.Y==-28,'Failed traversal advanced the series before the first physical probe')
end
-- Local geometry contact alone is deliberately NOT a fake-game acceptance.
do
 local f=fixture(Pallet);f.Data.GameAccept=false;local notifications={}
 f.Pallet.Context.Notify=function(message)notifications[#notifications+1]=message end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(4,240)
 check(#f.Data.Crossings>=3 and f.Pallet.Contacts>=3,'Rejected-game scenario did not exercise real local contacts')
 check(f.Data.GameReactions==0 and f.Target.Flag.Value==false,'Production code fabricated a ragdoll value')
 check(entry.Reaction:Describe().Rises==0,'A local touch was reported as a game ragdoll transition')
 local evidence=f.Pallet:Evidence().Entries[1]
 check(evidence.PhysicalTraversals>0 and evidence.StrokeAttempts>=evidence.PhysicalTraversals and evidence.ObservedRagdollRises==0,'Completed physical traversal evidence required or fabricated an observed game flag')
 local baseline=fixture(Pallet);baseline.Pallet:Maintain(baseline.Target.Character,baseline.Valid);baseline.Sim:Run(4,240)
 check(#f.Data.Crossings==#baseline.Data.Crossings and #f.Data.Crossings>=6,'An absent Ragdolled edge changed physical strike scheduling')
 for i,hit in ipairs(f.Data.Crossings)do
  local expected=baseline.Data.Crossings[i]
  check(hit.Velocity.Y==expected.Velocity.Y and math.abs(hit.At-expected.At)<1e-6,'No-edge diagnostics delayed or altered the physical cadence')
 end
 check(f.Data.Crossings[2].Velocity.Y==-48,'No-edge diagnostic state suppressed the fast physical burst')
 check(#notifications>0,'Local touches silenced the missing-game-reaction warning')
end
do
 local f=fixture(Pallet);f.Data.GameAccept=false;f.Target.Flag.Value=true
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(2,240)
 check(#f.Data.Crossings>=6 and entry.Reaction:Describe().Rises==0,'Already-true Ragdolled became a fresh reaction or suppressed physical strikes')
 local hits=f.Data.Crossings
 check(hits[1].Velocity.Y==-28 and hits[2].Velocity.Y==-48 and hits[5].Velocity.Y==-48 and hits[6].Velocity.Y==-28,'A latched Ragdolled flag altered the physical probe/burst cadence')
end
do
 local f=fixture(Pallet);local t=f.Target
 local root=newNode('Part','HumanoidRootPart',t.Character);root.Position=t.Torso.Position
 local receiver=newNode('Part','RagdollTouchedHitbox',root);receiver.Position=t.Torso.Position+Vector3.new(9,4,0);receiver.Size=Vector3.new(2,2,1);t.Receiver=receiver
 local entry=f.Pallet:Maintain(t.Character,f.Valid);f.Sim:Run(2,240)
 check(#f.Data.Crossings>=3 and f.Data.GameReactions>=3,'Offset game receiver was ignored in favor of the torso')
 for _,hit in ipairs(f.Data.Crossings)do check(hit.Receiver==receiver,'Stroke contacted the wrong receiver')end
 check(entry.Reaction:Describe().ReceiverKind=='RagdollTouchedHitbox','Observer did not bind the actual named receiver')
 f.Pallet:Cancel(t.Character);check(entry.Reaction:Describe().Disposed,'Canceled target retained its ragdoll observation hook')
end
do
 local f=fixture(Pallet);local t=f.Target;f.Data.GameAccept=false
 local root=newNode('Part','HumanoidRootPart',t.Character);root.Position=t.Torso.Position
 local receiver=newNode('Part','RagdollTouchedHitbox',root);receiver.Position=t.Torso.Position+Vector3.new(9,4,0);receiver.CanTouch=false;t.Receiver=receiver
 local entry=f.Pallet:Maintain(t.Character,f.Valid);f.Sim:Run(2,240)
 check(f.Pallet.StrikeAttempts>=6 and #f.Data.Crossings>=6,'Disabled named receiver prevented the original touchable torso fallback')
 for _,hit in ipairs(f.Data.Crossings)do check(hit.Receiver==t.Torso,'Disabled named receiver was used instead of the touchable torso')end
 check(entry.Reaction:Describe().Ready and receiver.CanTouch==false,'Receiver fallback modified the disabled game hitbox')
 check(entry.Reaction:Describe().ReceiverKind=='TorsoFallback' and entry.Reaction:Describe().Rises==0,'Torso fallback claimed an unobserved game reaction')
end
-- Delayed replicated state is diagnostic input. It must not throttle or
-- otherwise control the independent physical probe/burst worker.
do
 local f=fixture(Pallet);f.Data.GameAccept=false;local injected=false
 f.Sim.After=function()
  local first=f.Data.Crossings[1]
  if first and not injected and f.Sim.Now>=first.At+.65 then f.Target.Flag.Value=true;injected=true end
 end
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(2,240)
 check(injected and entry.Reaction:Describe().Rises==1,'Delayed external ragdoll transition was lost or counted repeatedly')
 local baseline=fixture(Pallet);baseline.Pallet:Maintain(baseline.Target.Character,baseline.Valid);baseline.Sim:Run(2,240)
 check(#f.Data.Crossings==#baseline.Data.Crossings and #f.Data.Crossings>=6,'Delayed diagnostic state stranded or slowed the physical worker')
 for i,hit in ipairs(f.Data.Crossings)do
  local expected=baseline.Data.Crossings[i]
  check(hit.Velocity.Y==expected.Velocity.Y and math.abs(hit.At-expected.At)<1e-6,'Delayed external state changed the physical cadence')
 end
end
for _,mode in ipairs({'cancel','pause','dispose'})do
 local f=fixture(Pallet);f.Data.GameAccept=false
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.4,240)
 check(#f.Data.Crossings>0,'Lifecycle case did not exercise physical contacts without game reactions')
 if mode=='cancel'then f.Pallet:Cancel(f.Target.Character)
 elseif mode=='pause'then f.Pallet:Pause('diagnostics-test',true)
 else f.Pallet:Dispose()end
 f.Sim:Run(.1,240);local before=#f.Data.Crossings;f.Target.Flag.Value=true;f.Sim:Run(.5,240)
 check(entry.Done and not f.Pallet.Active and #f.Data.Crossings==before,'Late diagnostic update restarted a stopped physical striker: '..mode)
 check(entry.Reaction:Describe().Disposed and entry.Reaction:Describe().Rises==0,'Late flag update survived stopped observation: '..mode)
end
print('PASS: '..checks..' physical crossings, receiver choice, external game reaction, FPS and lifecycle checks (mocked; no server hits/blur)')
