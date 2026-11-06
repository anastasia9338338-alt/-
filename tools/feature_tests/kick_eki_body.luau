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
  Position=mover,Orientation=mover,Physics={},EKIAt=0}
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
print('PASS: '..checks..' local EKI dirty-state, snapshot, failed-reset and cleanup retry checks (mocked; no server disconnect)')
