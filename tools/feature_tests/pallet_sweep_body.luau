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
