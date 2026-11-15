-- Real panel -> real FoodRemover -> mocked native Hold/Drop. This covers the
-- cancellation callback crossing the UI action dispatcher while Invoke yields.
function CFMethods:GetComponents()return self.X,self.Y,self.Z,table.unpack(self.R)end
local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function fixture()
 local f={Time=0,Queue={},Log={},Player={},Protected=false,MethodCalls=0,Results={},HoldDelay=.2}
 f.World=newNode('Folder');f.Inventory=newNode('Folder');f.Inventory.Parent=f.World
 local function character(name)
  local c=newNode('Model',name);c.Parent=f.World
  local root=newNode('Part','HumanoidRootPart');root.Parent=c
  local h=newNode('Humanoid');h.Health=100;h.Parent=c
  local hand=newNode('Part','LeftHand');hand.Parent=c;function hand:GetConnectedParts()return {}end
  newNode('Attachment','LeftGripAttachment').Parent=hand
  return c,root,h
 end
 f.Character=character
 f.Target,f.TargetRoot,f.TargetHumanoid=character('Target')
 f.Actor,f.ActorRoot,f.ActorHumanoid=character('Actor')
 f.Selected={[f.Player]=true};f.Beat=signal()
 function f:Spawn(fn)self.Queue[#self.Queue+1]={Thread=coroutine.create(fn),At=self.Time}end
 function f:Advance(seconds)
  local finish=self.Time+seconds
  while true do
   local i,entry
   for index,task in ipairs(self.Queue)do if task.At<=finish and(not entry or task.At<entry.At)then i,entry=index,task end end
   if not entry then break end
   table.remove(self.Queue,i);self.Time=entry.At
   local ok,delay=coroutine.resume(entry.Thread);assert(ok,delay)
   if coroutine.status(entry.Thread)~='dead'then entry.At=self.Time+(delay or .03);self.Queue[#self.Queue+1]=entry end
  end
  self.Time=finish
 end
 local food=newNode('Model','FoodBread');food.Parent=f.Inventory
 local hold=newNode('Part','HoldPart');hold.Parent=food
 local rigid=newNode('RigidConstraint','RigidConstraint');rigid.Parent=hold
 rigid.Attachment1=f.Target.LeftHand.LeftGripAttachment
 local remote=newNode('RemoteFunction','HoldItemRemoteFunction');remote.Parent=hold
 function remote:InvokeServer(model,actor)
  check(model==food,'Wrong food model');f.Log[#f.Log+1]='Hold'
  if f.HoldDelay>0 then coroutine.yield(f.HoldDelay)end
  rigid.Attachment1=actor.LeftHand.LeftGripAttachment
 end
 local drop=newNode('RemoteFunction','DropItemRemoteFunction');drop.Parent=hold
 function drop:InvokeServer(model,frame,velocity)
  check(model==food and typeof(frame)=='CFrame'and velocity==Vector3.zero,'Wrong native Drop protocol')
  f.Log[#f.Log+1]='Drop';rigid.Attachment1=nil
 end
 f.Rigid=rigid
 local function char(player)
  if player then return f.Target,f.TargetRoot,f.TargetHumanoid end
  return f.Actor,f.ActorRoot,f.ActorHumanoid
 end
 f.Remover=Remover.Install({Character=char,LocalCharacter=function()return char()end,Clock=function()return f.Time end,
  SpawnThread=function(fn)f:Spawn(fn)end,Wait=function(t)coroutine.yield(t)end,Inventory=function()return f.Inventory end})
 local api={Char=char,GetTargets=function()return {f.Player}end,IsProtectedPlayer=function()return f.Protected end,
  RunPlayerMethod=function(_,method,player)method(player)end,
  EatAntiInput=function(player,valid)
   f.MethodCalls+=1;local result=f.Remover:Apply(player,valid);f.Results[#f.Results+1]=result;return result
  end,
  Kill=function(...)check(select('#',...)==1 and(...)==f.Player,'Non-Food native signature changed');f.KillCalled=true end}
 f.Panel=Panel.Install({API=api,Data={SelectedPlayers=f.Selected},Library={OnUnload=function(_,fn)f.Unload=fn end},
  RunService={Heartbeat=f.Beat},Spawn=function(fn)f:Spawn(fn)end,Notify=function(message)error(message)end})
 return f
end
local function cancelled(name,change)
 local f=fixture();f.Panel:SetLoop('Food',true);f:Advance(.06);check(f.MethodCalls==1 and #f.Log==1,name..' fixture did not start a yielding Hold')
 change(f);f:Advance(.5)
 check(f.Results[1]==false,name..' did not reach real FoodRemover cancellation')
 check(#f.Log==2 and f.Log[2]=='Drop'and f.Rigid.Attachment1==nil,name..' stranded the already-issued native Hold')
 check(not f.Panel.Busy.Food[f.Player],name..' leaked the target worker')
 return f
end
cancelled('disable',function(f)f.Panel:SetLoop('Food',false)end)
cancelled('deselection',function(f)f.Selected[f.Player]=nil end)
cancelled('protection',function(f)f.Protected=true end)
cancelled('target respawn',function(f)f.Target,f.TargetRoot,f.TargetHumanoid=f.Character('ReplacementTarget')end)
cancelled('local respawn',function(f)f.Actor,f.ActorRoot,f.ActorHumanoid=f.Character('ReplacementActor')end)
cancelled('panel unload',function(f)f.Unload()end)
local epoch=cancelled('disable and immediate re-enable',function(f)f.Panel:SetLoop('Food',false);f.Panel:SetLoop('Food',true)end)
check(epoch.MethodCalls==1,'New epoch bypassed old worker busy coalescing')
epoch.HoldDelay=0;epoch.Panel:Run('Food',true);epoch:Advance(.3)
check(epoch.Results[2]==true,'New valid epoch could not resume food removal')
local queued=fixture();queued.Panel:SetLoop('Food',true)
queued.Target,queued.TargetRoot,queued.TargetHumanoid=queued.Character('QueuedReplacement');queued:Advance(.5)
check(queued.MethodCalls==0 and #queued.Log==0,'Queued Food dispatch followed target respawn')
local one=fixture();one.HoldDelay=0;one.Panel:Run('Food',false);one:Advance(.3)
check(one.Results[1]==true and #one.Log==2,'One-shot Food incorrectly requires the loop toggle')
one.Panel:Run('Kill',false);one:Advance(.1);check(one.KillCalled,'Non-Food native dispatch was removed')
print('PASS: '..checks..' real target panel / FoodRemover cancellation, selection, epoch, respawn and one-shot checks (mocked)')
