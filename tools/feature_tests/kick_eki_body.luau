-- Exercise local replication-property bookkeeping only. Setter success and
-- readback are not server acknowledgement, a remote hit or a player kick.
local function ekiFixture(original,withReader)
 local sim=Sim.new();currentSim=sim
 local targetState=target('EKIVictim');local root=targetState.Torso
 local actor=newNode('Part','ActorRoot',WORLD);local player={}
 local state={Now=0,Enabled=true,Stored=original,ApplyCalls=0,ResetCalls=0,
  ApplyFailures=0,ResetFailures=0,ResetThrows=0,ResetValues={}}
 local mover={Position=root.Position,Parent=root,Destroy=function()end}
 local session={Player=player,Character=targetState.Character,Root=root,Humanoid=targetState.Humanoid,
  Position=mover,Orientation=mover,Physics={},EKIAt=0,CapturedFrame=0}
 local context={Clock=function()return state.Now end,Enabled=function()return true end,Selected=function()return true end,
  Character=function()return targetState.Character,root,targetState.Humanoid end,
  LocalCharacter=function()return {},actor,targetState.Humanoid end,
  OwnershipBusy=function()return false end,Owned=function()return true end,NetworkOwned=function()return true end,
  Grab=function()end,Release=function()end,Collisions=function()end,Limbs=function()end,RestoreMotors=function()end,
  RagdollEnabled=function()return false end,CancelRagdoll=function()end,StickyEnabled=function()return false end,
  EKIEnabled=function()return state.Enabled end,
  ReplicationRoot=function(actual,value)
   check(actual==root,'EKI mutation used another character root')
   if value==root then
    state.ApplyCalls+=1
    if state.ApplyFailures>0 then state.ApplyFailures-=1;return false end
   else
    state.ResetCalls+=1;state.ResetValues[#state.ResetValues+1]={Value=value}
    if state.ResetThrows>0 then state.ResetThrows-=1;error('forced EKI reset exception')end
    if state.ResetFailures>0 then state.ResetFailures-=1;return false end
   end
   state.Stored=value;return true
  end}
 if withReader~=false then context.ReadReplicationRoot=function(actual)
  check(actual==root,'EKI snapshot read another character root');return true,state.Stored
 end end
 local loop=setmetatable({Context=context,Sessions={[player]=session},Cleanup={},NativeTick=true,
  MaximumSpeed=true,Frame=1,Calls=0,Released=0},Loop)
 local function update()loop:Update(session,root.Position,state.Now,.1)end
 local function retryCleanup()state.Now+=.25;loop:FlushCleanup()end
 return{Loop=loop,Session=session,State=state,Root=root,Player=player,Update=update,RetryCleanup=retryCleanup}
end
do
 local f=ekiFixture(nil);f.Update()
 check(f.Session.EKI==true and f.State.Stored==f.Root,'Successful EKI write was not tracked')
 f.State.ApplyFailures=1;f.State.Now+=.25;f.Update()
 check(f.Session.EKI==true,'Failed EKI rewrite forgot a previous successful mutation')
 f.Loop:Remove(f.Player)
 check(f.State.ResetCalls>=1 and f.State.Stored==nil,'Remove skipped restoring a previously changed replication root')
end
do
 local f=ekiFixture(nil);f.Update();f.State.ResetFailures=1
 f.Loop:Remove(f.Player)
 check(f.Loop.Cleanup[f.Root]~=nil,'False EKI reset result was treated as completed cleanup')
 check(f.State.Stored==f.Root,'Failed reset unexpectedly changed the local fixture property')
 f.RetryCleanup()
 check(f.State.ResetCalls==2 and f.State.Stored==nil and f.Loop.Cleanup[f.Root]==nil,'Failed EKI cleanup did not retry to completion')
end
do
 local f=ekiFixture(nil);f.Update();f.State.Enabled=false;f.State.ResetFailures=1;f.State.Now+=.25;f.Update()
 check(f.Session.EKI==true and f.State.Stored==f.Root,'Toggle-off forgot a rejected EKI reset')
 f.State.Now+=.25;f.Update()
 check(not f.Session.EKI and f.State.Stored==nil,'Toggle-off did not finish restoring EKI after a retry')
end
do
 local f=ekiFixture(nil);f.Update();f.State.ResetThrows=1
 local ok=pcall(f.Loop.Remove,f.Loop,f.Player)
 check(ok and f.Loop.Cleanup[f.Root]~=nil,'EKI reset exception escaped or discarded pending cleanup')
 f.RetryCleanup()
 check(f.State.ResetCalls==2 and f.State.Stored==nil and f.Loop.Cleanup[f.Root]==nil,'EKI cleanup failed to recover after a setter exception')
end
do
 local original={Name='ExistingReplicationRoot'};local f=ekiFixture(original);f.Update()
 f.State.Now+=.25;f.Update();f.Loop:Remove(f.Player)
 check(f.State.Stored==original,'EKI removal cleared an existing replication root instead of restoring it')
 check(#f.State.ResetValues>=1 and f.State.ResetValues[#f.State.ResetValues].Value==original,'EKI original snapshot was overwritten by a later application')
end
do
 local f=ekiFixture(nil,false);f.Update();f.Loop:Remove(f.Player)
 check(f.State.Stored==nil and f.State.ResetCalls>=1,'Legacy setter-only EKI context could not clear its own mutation')
end
do
 local f=ekiFixture(nil);f.Update();f.State.Enabled=false;f.State.ResetThrows=1;f.State.Now+=.25
 local ok=pcall(f.Update)
 check(ok and f.Session.EKI==true and f.Loop.Sessions[f.Player]==f.Session,'Toggle-off setter exception escaped local EKI handling or lost its session')
 f.State.Now+=.25;f.Update()
 check(not f.Session.EKI and f.State.Stored==nil,'Toggle-off reset did not recover after a setter exception')
end
do
 local f=ekiFixture(nil);f.State.Stored=f.Root;f.Update();f.Loop:Remove(f.Player)
 check(f.State.Stored==f.Root,'EKI cleared a replication root that already pointed at itself before activation')
end
-- Maximum-speed capture uses confirmed ownership followed by one distinct
-- physics frame. This measures local scheduling, never server kick latency.
do
 local f=ekiFixture(nil);f.Session.EKIAt=nil;f.Session.CapturedFrame=nil;f.Update()
 check(f.State.ApplyCalls==0 and f.Session.EKIAt==.6,'Fast EKI ran in the ownership observation frame')
 f.State.Now=1/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==1 and f.Session.EKI,'Confirmed stable capture retained the fixed 600ms EKI pause')
 check(f.State.Now<.6,'Fast EKI test did not exercise earlier readiness')
end
do
 local f=ekiFixture(nil);f.Session.EKIAt=nil;f.Session.CapturedFrame=nil
 local owned=false;f.Loop.Context.NetworkOwned=function()return owned end
 f.Update();f.State.Now=1/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==0 and f.Session.CapturedFrame==nil,'Owner marker alone accelerated EKI')
 owned=true;f.State.Now=2/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==0,'Late physics handoff skipped its settling frame')
 f.State.Now=3/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==1,'Late confirmed capture failed to advance EKI readiness')
end
do
 local f=ekiFixture(nil);f.Session.EKIAt=nil;f.Session.CapturedFrame=nil;f.Update()
 local destination=f.Root.Position+Vector3.new(0,15,0)
 f.State.Now=1/60;f.Loop.Frame+=1;f.Loop:Update(f.Session,destination,f.State.Now,.1)
 check(f.State.ApplyCalls==0,'Unsettled target accelerated EKI before reaching its hold destination')
 f.Loop.MaximumSpeed=false;f.State.Now=2/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==0,'Normal mode lost its original EKI delay')
 f.State.Now=.6;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==1,'Normal mode never reached its original EKI readiness')
end
for _,lost in ipairs({'marker','physics','both'})do
 local f=ekiFixture(nil);local marker,physics=true,true
 f.Loop.Context.Owned=function()return marker and physics end
 f.Loop.Context.NetworkOwned=function()return physics end
 f.Update();check(f.State.ApplyCalls==1,'Lost-ownership case did not first establish EKI')
 marker=lost=='physics';physics=lost=='marker'
 f.State.Now=.8;f.Loop.Frame+=1;f.Update()
 check(f.Session.CapturedFrame==nil and not f.Session.EKI,'Ownership loss retained stale fast EKI readiness: '..lost)
 -- Physics may be observed again before the replicated owner marker.
 physics=true;marker=false;f.State.Now+=1/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==1 and not f.Session.EKI,'Physics-only reacquisition reused old EKI readiness: '..lost)
 marker=true;f.State.Now+=1/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==1,'Reacquisition skipped its new capture-observation frame: '..lost)
 f.State.Now+=1/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==2 and f.Session.EKI,'Fresh stable ownership failed to reapply EKI: '..lost)
end
for _,pause in ipairs({'busy','acquiring','distant'})do
 local f=ekiFixture(nil);local owned=true;local busy=false
 f.Loop.Context.Owned=function()return owned end
 f.Loop.Context.NetworkOwned=function()return owned end
 f.Loop.Context.OwnershipBusy=function()return busy end
 f.Update();check(f.State.ApplyCalls==1,'Early-return case did not establish EKI')
 owned=false;f.State.Now=.8;f.Loop.Frame+=1
 local original=f.Root.Position
 if pause=='busy'then busy=true
 elseif pause=='acquiring'then f.Session.Acquiring=true
 else
  f.Root.Position=Vector3.new(100,0,0)
  f.Loop.Acquire=function(_,session)session.ReacquireAttempted=true end
 end
 f.Update()
 check(f.Session.CapturedFrame==nil,'Early return retained an old capture frame: '..pause)
 if pause=='distant'then check(f.Session.ReacquireAttempted,'Distant regression did not take its acquisition return')end
 busy=false;f.Session.Acquiring=false;f.Root.Position=original;owned=true
 f.State.Now+=1/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==1 and not f.Session.EKI,'Paused reacquisition skipped a fresh observation frame: '..pause)
 f.State.Now+=1/60;f.Loop.Frame+=1;f.Update()
 check(f.State.ApplyCalls==2 and f.Session.EKI,'Paused reacquisition failed after a fresh settling frame: '..pause)
end
-- Native RNO deliberately removes the grab/owner marker. Once the initial
-- capture was acknowledged, continuing physical ownership keeps EKI valid.
-- Marker replication alone must neither initialize nor tear down this capture.
do
 local f=ekiFixture(nil);local marker,physics=true,true
 f.Loop.Context.NativePhases=true
 f.Loop.Context.Owned=function()return marker and physics end
 f.Loop.Context.NetworkOwned=function()return physics end
 f.Update();check(f.Session.EKI,'Native capture did not establish EKI')
 marker=false;f.State.Now=1/60;f.Loop.Frame+=1;f.Update()
 check(f.Session.EKI and f.State.ResetCalls==0 and f.State.ApplyCalls==2,'Intentional native marker release tore down a physically held EKI')
 physics=false;f.State.Now+=1/60;f.Loop.Frame+=1;f.Update()
 check(not f.Session.EKI and not f.Session.CaptureAcknowledged and not f.Session.CapturedFrame,'Actual ownership loss retained EKI or capture acknowledgement')
 physics=true;f.State.Now+=1/60;f.Loop.Frame+=1;f.Update()
 check(not f.Session.EKI and f.State.ApplyCalls==2,'Physical-only reacquisition reused an expired capture')
 marker=true;f.State.Now+=1/60;f.Loop.Frame+=1;f.Update()
 check(not f.Session.EKI,'Native reacquisition skipped its new capture frame')
 marker=false;f.State.Now+=1/60;f.Loop.Frame+=1;f.Update()
 check(f.Session.EKI and f.State.ApplyCalls==3,'Native capture readiness followed the marker instead of actual simulation ownership')
 f.Loop:Remove(f.Player)
 check(f.State.Stored==nil and f.Loop.Sessions[f.Player]==nil,'Native continuity path failed cancellation cleanup')
end
do
 local f=ekiFixture(nil);f.Loop.Context.NativePhases=true;f.Session.CapturedFrame=nil
 f.Loop.Context.Owned=function()return false end
 f.Update();f.Loop.Frame+=1;f.State.Now=1/60;f.Update()
 check(f.State.ApplyCalls==0 and not f.Session.CaptureAcknowledged,'Never-acknowledged native target was considered captured')
end
do
 local f=ekiFixture(nil);f.Loop.Context.NativePhases=true;f.Update()
 local elsewhere=f.Root.Position+Vector3.new(0,15,0)
 f.Loop.Frame+=1;f.State.Now=1/60;f.Loop:Update(f.Session,elsewhere,f.State.Now,.1)
 check(not f.Session.EKI and not f.Session.CapturedFrame,'Leaving the hold position preserved stale EKI settling readiness')
 f.Loop.Frame+=1;f.State.Now+=1/60;f.Update()
 check(not f.Session.EKI and f.State.ApplyCalls==1,'Returning to hold skipped a fresh physics frame')
 f.Loop.Frame+=1;f.State.Now+=1/60;f.Update()
 check(f.Session.EKI and f.State.ApplyCalls==2,'Stable return to hold did not resume native EKI')
end
print('PASS: '..checks..' local EKI dirty-state, snapshot, failed-reset and cleanup retry checks (mocked; no server disconnect)')
