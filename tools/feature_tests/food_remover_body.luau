function CFMethods:GetComponents()return self.X,self.Y,self.Z,table.unpack(self.R)end
local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function fixture()
 local f={Time=0,Queue={},Log={},Player={},CanHold=true,CanDrop=true,HoldDelay=0,DropDelay=0}
 function f:Spawn(fn)self.Queue[#self.Queue+1]={Thread=coroutine.create(fn),At=self.Time}end
 function f:Wait(seconds)coroutine.yield(seconds or .03)end
 function f:Advance(seconds)
  local finish=self.Time+seconds;local iterations=0
  while true do
   local index,nextTask
   for i,task in ipairs(self.Queue)do if task.At<=finish and(not nextTask or task.At<nextTask.At)then index,nextTask=i,task end end
   if not nextTask then break end
   table.remove(self.Queue,index);self.Time=nextTask.At;iterations+=1;assert(iterations<10000,'Unbounded worker')
   local ok,delay=coroutine.resume(nextTask.Thread);assert(ok,delay)
   if coroutine.status(nextTask.Thread)~='dead'then nextTask.At=self.Time+(delay or .03);self.Queue[#self.Queue+1]=nextTask end
  end
  self.Time=finish
 end
 f.World=newNode('Folder');f.Target=newNode('Model','Target');f.Target.Parent=f.World
 f.Actor=newNode('Model','Actor');f.Actor.Parent=f.World
 f.ActorRoot=newNode('Part','HumanoidRootPart');f.ActorRoot.Parent=f.Actor
 f.Humanoid=newNode('Humanoid');f.Humanoid.Health=100;f.Humanoid.Parent=f.Actor
 f.TargetHumanoid=newNode('Humanoid');f.TargetHumanoid.Health=100;f.TargetHumanoid.Parent=f.Target
 f.Inventory=newNode('Folder');f.Inventory.Parent=f.World
 function f:Grip(character,name)
  local hand=character:FindFirstChild(name or 'LeftHand')or newNode('Part',name or 'LeftHand');hand.Parent=character
  function hand:GetConnectedParts()return {}end
  local grip=newNode('Attachment','LeftGripAttachment');grip.Parent=hand;return grip
 end
 f.ActorGrip=f:Grip(f.Actor);f.TargetGrip=f:Grip(f.Target)
 function f:Item(name,attachment,enabled,incomplete)
  local model=newNode('Model',name or 'FoodBanana');model.Parent=self.Inventory
  local hold=newNode('Part','HoldPart');hold.Parent=model
  local rigid=newNode('RigidConstraint','RigidConstraint');rigid.Attachment1=attachment;rigid.Enabled=enabled~=false;rigid.Parent=hold
  local remote=newNode('RemoteFunction','HoldItemRemoteFunction');remote.Parent=hold
  local drop=newNode('RemoteFunction','DropItemRemoteFunction');if not incomplete then drop.Parent=hold end
  function remote:InvokeServer(item,actor)
   check(item==model and actor==f.Actor,'Hold used an uncaptured model/actor')
   f.Log[#f.Log+1]='Hold';if f.HoldDelay>0 then f:Wait(f.HoldDelay)end
   if f.HoldError then error('Hold rejected')end
   if f.CanHold then rigid.Attachment1=f.ActorGrip end
   return f.HoldReturn
  end
  function drop:InvokeServer(item,...)
   local frame,velocity=...
   check(item==model and select('#',...)==2 and typeof(frame)=='CFrame'and typeof(velocity)=='Vector3','Drop is missing native model, CFrame, velocity arguments')
   check(frame.Position==Vector3.new(0,0,-8)and velocity==Vector3.zero,'Drop did not use the finite captured root pose and zero velocity')
   f.Log[#f.Log+1]='Drop'
   if f.DetachEarly and f.CanDrop then rigid.Attachment1=nil end
   if f.DropDelay>0 then f:Wait(f.DropDelay)end
   if f.CanDrop then rigid.Attachment1=nil end
   return f.DropReturn
  end
  return model,hold,rigid,remote,drop
 end
 f.Remover=Remover.Install({Clock=function()return f.Time end,Character=function()return f.Target,nil,f.TargetHumanoid end,
  LocalCharacter=function()return f.Actor,f.ActorRoot,f.Humanoid end,Inventory=function()return f.Inventory end,
  SpawnThread=function(fn)f:Spawn(fn)end,Wait=function(t)f:Wait(t)end,PingSeconds=function()return .1 end})
 function f:Apply(valid)self:Spawn(function()self.Result=self.Remover:Apply(self.Player,valid)end)end
 return f
end
local function test(name,fn)local ok,err=pcall(fn);assert(ok,name..': '..tostring(err))end

test('food between grips and disabled legacy constraints are collected',function()
 local f=fixture();local food=f:Item('FoodBanana');local legacy=f:Item('FoodBread',f.TargetGrip,false)
 local other=newNode('Model');other.Parent=f.World;local foreign=f:Grip(other)
 f:Item('FoodPizza',foreign);f:Item('Chair');f:Item('FoodIncomplete',nil,true,true)
 local list=f.Remover:Collect(f.Target)
 check(#list==2 and table.find(list,food)and table.find(list,legacy),'Collector misses unheld food or includes unrelated/foreign toys')
end)
test('real acknowledgement and repeated reuse preserve native remotes',function()
 local f=fixture();local model,_,rigid,hold,drop=f:Item('FoodBanana',f.TargetGrip)
 f:Apply();f:Advance(1)
 check(f.Result==true and rigid.Attachment1==nil and f.Remover.Removed==1,'Hold/Drop detach was not acknowledged')
 check(hold.Parent and drop.Parent and rigid.Enabled,'Food removal damaged remotes or disabled constraint locally')
 check(#f.Log==2 and f.Log[1]=='Hold'and f.Log[2]=='Drop','Wrong protocol sequence')
 rigid.Attachment1=f.TargetGrip;f:Apply();f:Advance(1)
 check(f.Result and f.Remover.Removed==2 and #f.Log==4,'Second removal cannot reuse preserved Drop')
end)
test('R15 and attachment safety',function()
 local f=fixture();local model,hold,rigid=f:Item('InputShield',f.TargetGrip)
 function f.Target.LeftHand:GetConnectedParts(recursive)check(recursive==true,'Connected assembly was not searched recursively');return {hold,hold}end
 check(#f.Remover:Collect(f.Target)==1,'R15 connected shield missing or duplicated')
 f:Apply();f:Advance(1);check(f.Result and rigid.Attachment1==nil,'R15 native grip was not cleared')
end)
test('successful calls without grip replication are failures',function()
 local f=fixture();local _,_,rigid=f:Item('FoodBanana',f.TargetGrip);f.CanHold=false;f.HoldReturn=true
 f:Apply();f:Advance(2)
 check(f.Result==false and rigid.Attachment1==f.TargetGrip,'Remote return was mistaken for replicated hold acknowledgement')
 check(not table.find(f.Log,'Drop'),'Drop sent without acquiring the local native grip')
 check(#f.Log<=10,'Unacknowledged Hold flooded remotes')
end)
test('drop must detach before reporting success',function()
 local f=fixture();f:Item('FoodBread',f.TargetGrip);f.CanDrop=false;f.DropReturn=true
 f:Apply();f:Advance(2)
 check(f.Result==false and(not f.Remover.Removed or f.Remover.Removed==0),'Remote Drop return was mistaken for detach acknowledgement')
end)
test('detachment before returning Drop does not strand a busy item',function()
 local f=fixture();local model,_,rigid=f:Item('FoodBanana',f.TargetGrip);f.DropDelay=.4;f.DetachEarly=true
 f:Apply();f:Advance(1)
 check(f.Result and f.Remover.Items[model]==nil,'A delayed Drop response leaks the item lock after detach acknowledgement')
 rigid.Attachment1=f.TargetGrip;f:Apply();f:Advance(1);check(f.Result and f.Remover.Removed==2,'Item remains blocked after delayed Drop')
end)
test('in-flight acquisition is coalesced and cleaned after cancellation',function()
 local f=fixture();local model,_,rigid=f:Item('FoodBanana',f.TargetGrip);f.HoldDelay=2
 f:Apply();f:Advance(1);check(f.Result==false and f.Remover.Items[model]~=nil,'Timed-out remote was forgotten while still yielding')
 f:Apply();f:Advance(.3);check(#f.Log==1,'Timed-out InvokeServer caused duplicate in-flight Holds')
 f:Advance(1);check(#f.Log==2 and f.Log[2]=='Drop'and rigid.Attachment1==nil and f.Remover.Items[model]==nil,'Late Hold grant survived cancellation')
end)
test('disable cancels protocol while already-issued hold safely drops',function()
 local f=fixture();local _,_,rigid=f:Item('FoodBanana',f.TargetGrip);f.HoldDelay=.2;local enabled=true
 f:Apply(function()return enabled end);f:Advance(.06);enabled=false;f:Advance(.5)
 check(f.Result==false and #f.Log==2 and rigid.Attachment1==nil,'Cancelled job followed through or stranded its local grip')
end)
test('queued native calls recheck cancellation and holder identity',function()
 local f=fixture();local model,_,rigid,hold,drop=f:Item('FoodBanana',f.TargetGrip)
 local enabled=true;local job={Model=model,Actor=f.Actor,Rigid=rigid,Drop=drop,Valid=function()return enabled end}
 f.Remover.Items[model]=job;f.Remover:Call(job,hold,false);enabled=false;f:Advance(.1)
 check(#f.Log==0 and f.Remover.Items[model]==nil,'A queued Hold ignored cancellation before InvokeServer')
 local third=newNode('Model');third.Parent=f.World;rigid.Attachment1=f:Grip(third)
 local cleanup={Model=model,Actor=f.Actor,Rigid=rigid,Drop=drop,DropCFrame=CFrame.new(0,0,-8),Cancelled=true}
 f.Remover.Items[model]=cleanup;f.Remover:Call(cleanup,drop,true);f:Advance(.1)
 check(#f.Log==0 and f.Remover.Items[model]==nil,'A queued cleanup Drop stole a new foreign grip')
end)
test('queued Hold rechecks the actual item holder',function()
 local f=fixture();local _,_,rigid=f:Item('FoodBread',f.TargetGrip)
 local third=newNode('Model');third.Parent=f.World;local thirdGrip=f:Grip(third)
 f.Remover.Context.SpawnThread=function(fn)rigid.Attachment1=thirdGrip;f:Spawn(fn)end
 f:Apply();f:Advance(.5)
 check(#f.Log==0 and f.Result==false and rigid.Attachment1==thirdGrip,'Queued Hold stole an item after its holder changed')
end)
test('Drop never receives a nonfinite or out-of-map pose',function()
 local f=fixture();f:Item('FoodBread',f.TargetGrip);f.ActorRoot.CFrame=CFrame.Angles(0/0,0,0)
 f:Apply();f:Advance(.5);check(#f.Log==0 and f.Result==false,'Nonfinite drop orientation reached a remote')
 local g=fixture();g:Item('FoodBread',g.TargetGrip);g.ActorRoot.Position=Vector3.new(1e8,0,0)
 g:Apply();g:Advance(.5);check(#g.Log==0 and g.Result==false,'Out-of-map drop pose reached a remote')
end)
test('target respawn prevents touching replacement food',function()
 local f=fixture();f:Item('FoodBanana',f.TargetGrip);f.Remover:Request(f.Player)
 f.Target=newNode('Model');f.Target.Parent=f.World;f.TargetGrip=f:Grip(f.Target);f:Advance(1)
 check(#f.Log==0,'Queued request followed a target respawn')
end)
test('local respawn prevents starting a queued request',function()
 local f=fixture();f:Item('FoodBanana',f.TargetGrip);f.Remover:Request(f.Player)
 f.Actor=newNode('Model');f.Actor.Parent=f.World;f.ActorGrip=f:Grip(f.Actor);f:Advance(1)
 check(#f.Log==0,'Queued request followed a local respawn')
end)
test('unload and pending work',function()
 local f=fixture();local _,_,rigid=f:Item('FoodBanana',f.TargetGrip);f.HoldDelay=.2
 f.Remover:Request(f.Player);f.Remover:Request(f.Player);check(#f.Queue==1,'Pending requests duplicated')
 f:Advance(.06);f.Remover:Dispose();f:Advance(.5)
 check(#f.Log==2 and rigid.Attachment1==nil and next(f.Remover.Items)==nil,'Unload did not clean the outstanding captured native grip')
 f.Remover:Request(f.Player);f:Advance(.5);check(#f.Log==2,'Unload started new food operations')
end)
test('general holdable removal preserves native remotes and confirms detach',function()
 local f=fixture();local model,hold,rigid,holdRemote,drop=f:Item('Chair',f.TargetGrip)
 f:Spawn(function()f.Result=f.Remover:Detach(model,function()return true end)end);f:Advance(1)
 check(f.Result==true and rigid.Attachment1==nil,'General holdable protocol did not detach the exact item')
 check(holdRemote.Parent==hold and drop.Parent==hold,'General removal destroyed native remotes')
 rigid.Attachment1=f.TargetGrip
 f:Spawn(function()f.Result=f.Remover:Detach(model,function()return false end)end);f:Advance(.3)
 check(f.Result==false and rigid.Attachment1==f.TargetGrip,'Cancelled general removal grabbed the item')
end)
print('PASS: '..checks..' food native hold/drop acknowledgement, inventory, R15, retry, respawn and cancellation checks (mocked)')
