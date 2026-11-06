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
 check(not entry.Done and f.Pallet.Active==entry,'Existing ragdoll flag stopped continuous strikes at '..fps)
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
print('PASS: '..checks..' physical pallet crossings, FPS bounds, promotion, ownership and lifecycle checks (mocked; no server hits)')
