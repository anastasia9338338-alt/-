-- Exercise the actual source contact protocol and its lifecycle. This rigid-body
-- mock does not model Roblox's touch/replication rules, so placements are never
-- treated as evidence of a server strike or a successful player kick.
local function observe(f)
 local records={};local original=f.Pallet.Context.Clock
 -- Native callbacks record through Passes. Observe the actual Position writes
 -- and the source force/velocity immediately when each request yields.
 f.Sim.After=function()
  local n=f.Pallet.Passes
  if n>(records.Last or 0)then
   records.Last=n
   records[#records+1]={At=original(),Velocity=f.Sound.Velocity,Lift=f.Main:FindFirstChild('RagdollBP').MaxForce.Magnitude}
  end
 end
 return records
end
for _,fps in ipairs({20,30,60,120,240,480,1000})do
 local f=fixture(Pallet);local records=observe(f)
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid)
 f.Sim:Run(2,fps)
 check(not entry.Done and f.Pallet.Active==entry,'Existing ragdoll flag stopped source contacts at '..fps)
 check(f.Pallet.Passes>=24 and f.Pallet.Passes<=42,'Native contact cadence depends on rendering FPS at '..fps)
 check(f.Pallet.StrikeAttempts==f.Pallet.Passes,'Contact attempts and native placements diverged')
 for _,v in ipairs(records)do
  check(v.Velocity.Y==-10,'Source downward velocity was replaced')
  check(v.Lift==math.huge,'Native Main lift was disabled during contact')
 end
 local before=f.Pallet.Passes
 f.Target.Head:FindFirstChild('PartOwner'):Destroy();f.Sim:Run(.4,fps)
 check(f.Pallet.Passes>before,'Owner marker churn stopped the independent board worker')
 f.Data.Valid=false;f.Sim:Run(.1,fps);before=f.Pallet.Passes;f.Sim:Run(.3,fps)
 check(f.Pallet.Passes==before and entry.Done and not f.Pallet.Active,'Stopped kick left source contacts alive')
 check(f.Main.AssemblyLinearVelocity.Magnitude==0 and f.Main:FindFirstChild('RagdollBP').MaxForce.Magnitude==0,'Park left native lift or velocity enabled')
 check(not f.Pallet.States.Ragdolling and not f.Pallet.LastError,'Cancellation leaked busy/error state')
end
do
 local f=fixture(Pallet);f.Data.Accept=false
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.4,240)
 check(f.Pallet.Passes>0 and f.Pallet.Contacts==0 and f.Pallet.Confirmed==0,'A placement was presented as a server hit')
 local before=f.Pallet.Contacts;f.Sound.Touched:Fire(f.Target.Torso)
 check(f.Pallet.Contacts==before+1 and f.Pallet.Confirmed==0,'Observed local touch was mistaken for server confirmation')
end
do
 local f=fixture(Pallet,false);f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.5,60)
 check(f.Pallet.Passes>=7,'Heartbeat fallback lost source contacts')
end
do
 local f=fixture(Pallet);f.Target.Flag.Value=false;local effect=true
 local one=f.Pallet:Request(f.Target.Character,function()return effect end)
 local promoted=f.Pallet:Maintain(f.Target.Character,f.Valid);effect=false;f.Sim:Run(.5,240)
 check(one==promoted and not one.Done and f.Pallet.Passes>2,'One-shot predicate canceled a promoted kick')
 f.Data.Valid=false;f.Sim:Run(.1,240);check(one.Done and not f.Pallet.Active,'Promoted kick ignored cancellation')
end
for _,mode in ipairs({'cancel','pause','dispose','dead','respawn'})do
 local f=fixture(Pallet);local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.4,240)
 if mode=='cancel'then f.Pallet:Cancel(f.Target.Character)
 elseif mode=='pause'then f.Pallet:Pause('test',true)
 elseif mode=='dispose'then f.Pallet:Dispose()
 elseif mode=='dead'then f.Target.Humanoid.Health=0
 else f.Target.Character.Parent=nil end
 f.Sim:Run(.1,240);local before=f.Pallet.Passes;f.Sim:Run(.4,240)
 check(f.Pallet.Passes==before and entry.Done and not f.Pallet.Active,'Native contact lifecycle failed: '..mode)
 check(not f.Pallet.States.Ragdolling and not f.Pallet.LastError,'Stop became an error: '..mode)
end
do
 local f=fixture(Pallet);local second=target('Second',Vector3.new(30,15,0));f.Data.Targets[#f.Data.Targets+1]=second
 local a=f.Pallet:Maintain(f.Target.Character,f.Valid);local b=f.Pallet:Maintain(second.Character,f.Valid);f.Sim:Run(2,240)
 check((a.Passes or 0)>=5 and(b.Passes or 0)>=5,'Queued kick targets starved each other')
end
do
 local f=fixture(Pallet);f.Data.Owned=false;f.Data.Acquire=false
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(1,240)
 check(f.Pallet.Passes==0 and f.Data.Acquires<=12,'Unowned board moved or acquisition flooded')
 f.Data.Acquire=true;f.Sim:Run(1,240);check(f.Pallet.Passes>0,'Board failed to resume after ownership returned')
end
do
 local f=fixture(Pallet);f.Target.Flag.Value=true
 local entry=f.Pallet:Request(f.Target.Character,f.Valid);f.Sim:Run(.2,60)
 check(entry.Done and entry.Success and f.Pallet.StrikeAttempts==0,'One-shot became a repeating kick')
end
do
 local f=fixture(Pallet);f.Target.Flag.Value=false
 local entry=f.Pallet:Request(f.Target.Character,f.Valid);f.Target.Flag.Value=true;f.Sim:Run(.2,60)
 check(entry.Done and entry.Success,'One-shot lost its ragdoll acknowledgment')
end
do
 local f=fixture(Pallet);f.Data.Owned=false;f.Data.Ack=false
 local moves=f.Sound.Teleports;f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.1,240)
 check(f.Pallet.Passes==0 and f.Sound.Teleports==moves,'Owner marker was mistaken for completed physics handoff')
 f.Data.Owned=true;f.Sim:Run(.5,240);check(f.Data.Acquires==1 and f.Pallet.Passes>0,'Delayed handoff forced repeated acquisition')
end
do
 local f=fixture(Pallet);f.Data.Owned=false;f.Data.Ack=false
 local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.05,240);f.Data.Valid=false;f.Sim:Run(.1,240)
 check(entry.Done and not f.Pallet.Active and not f.Pallet.States.Ragdolling,'Canceled handoff leaked busy state')
end
for _,mode in ipairs({'cancel','pause','dispose'})do
 local f=fixture(Pallet);local entry=f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.1,240)
 f.Pallet.Context.ParkPosition=function()error('forced park failure')end
 local ok=pcall(function()if mode=='cancel'then f.Pallet:Cancel(f.Target.Character)elseif mode=='pause'then f.Pallet:Pause('error-test',true)else f.Pallet:Dispose()end end)
 check(ok and f.Pallet.LastError~=nil,'Park failure escaped cleanup: '..mode)
 f.Sim:Run(.1,240);check(entry.Done and not f.Pallet.Active and not f.Pallet.States.Ragdolling,'Park failure stranded worker: '..mode)
end
do
 local f=fixture(Pallet);f.Sim.Physics=function()end
 local mainFrame=f.Main.CFrame;f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.3,240)
 check((f.Sound.Position-f.Target.Torso.Position).Magnitude<.001,'Native SoundPart was not placed on the torso')
 check(f.Main.CFrame==mainFrame,'Native contact moved the whole assembly instead of SoundPart')
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
 local before=f.Pallet.Passes;check(f.Pallet:Prepare(f.Valid),'Active ready pallet was rejected')
 f.Sim:Run(.2,60);check(not entry.Done and f.Pallet.Passes>before,'Preparation interrupted an active kick')
end
do
 local f=fixture(Pallet);f.Pallet.Context.Find=function()return nil end;f.Pallet.Context.CanSpawn=function()return false,'Build area unavailable'end
 check(not f.Pallet:Prepare(f.Valid)and f.Data.Spawns==0 and not f.Pallet.Preparing,'Preparation spawned outside the allowed area or leaked its lock')
 f.Pallet:Dispose();check(not f.Pallet:Prepare(f.Valid),'Disposed pallet controller still prepared a toy')
end
for _,stop in ipairs({'cancel','pause','dispose'})do
 local f=fixture(Pallet);local calls={};f.Pallet.Context.Touch=function(part,target,begin)
  check(part==f.Sound and target==f.Target.Torso,'Touch bridge used another body')
  calls[#calls+1]=begin
 end
 f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.3,240)
 check(#calls>=5 and #calls<=15 and f.Pallet.TouchPair~=nil,'Explicit contact bridge did not repeat at a bounded rate')
 for i=2,#calls do check(calls[i]~=calls[i-1],'Contact bridge missed a begin/end transition')end
 if stop=='cancel'then f.Pallet:Cancel(f.Target.Character)elseif stop=='pause'then f.Pallet:Pause('bridge',true)else f.Pallet:Dispose()end
 check(calls[#calls]==false and f.Pallet.TouchPair==nil,'Contact bridge left a touch active on '..stop)
end
do
 local f=fixture(Pallet);f.Data.Owned=false;f.Data.Acquire=false;local calls=0
 f.Pallet.Context.Touch=function()calls+=1 end;f.Pallet:Maintain(f.Target.Character,f.Valid);f.Sim:Run(.3,240)
 check(calls==0,'Contact bridge ran on an unowned pallet')
end
print('PASS: '..checks..' native pallet protocol, cadence, promotion, ownership and lifecycle checks (mocked; no server hits)')
