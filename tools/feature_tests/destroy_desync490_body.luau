local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function fixture()
 local f={Time=0,Queue={},Log={},Player={},Physical={},Marker={},Selected=true,Paused=false,Busy=false,AutoRagdoll=true,AcquireDelay=.25,ReleaseFailures=0}
 f.World=newNode('Folder');f.Character=newNode('Model');f.Character.Parent=f.World
 f.Root=newNode('Part','HumanoidRootPart');f.Root.Parent=f.Character;f.Root.Position=Vector3.new(10,0,0)
 f.Humanoid=newNode('Humanoid');f.Humanoid.Health=100;f.Humanoid.Parent=f.Character
 f.Ragdolled=newNode('BoolValue','Ragdolled');f.Ragdolled.Value=false;f.Ragdolled.Parent=f.Humanoid
 f.Actor=newNode('Model');f.Actor.Parent=f.World;f.ActorRoot=newNode('Part');f.ActorRoot.Parent=f.Actor
 f.ActorHumanoid=newNode('Humanoid');f.ActorHumanoid.Health=100;f.ActorHumanoid.Parent=f.Actor
 f.Beat=signal()
 function f:Spawn(fn)self.Queue[#self.Queue+1]={Thread=coroutine.create(fn),At=self.Time}end
 function f:Ready()
  while true do
   local index,task
   for i,entry in ipairs(self.Queue)do if entry.At<=self.Time and(not task or entry.At<task.At)then index,task=i,entry end end
   if not task then return end
   table.remove(self.Queue,index);local ok,delay=coroutine.resume(task.Thread);assert(ok,delay)
   if coroutine.status(task.Thread)~='dead'then task.At=self.Time+(delay or .05);self.Queue[#self.Queue+1]=task end
  end
 end
 function f:Advance(seconds)
  local finish=self.Time+seconds
  while self.Time<finish-1e-8 do local dt=math.min(.05,finish-self.Time);self.Time+=dt;self.Beat:Fire(dt);self:Ready()end
 end
 local ctx={RunService={Heartbeat=f.Beat},Clock=function()return f.Time end,Spawn=function(fn)f:Spawn(fn)end,Supported=true,
  Targets=function()return {f.Player}end,Selected=function()return f.Selected end,
  Character=function()return f.Character,f.Root,f.Humanoid end,
  LocalCharacter=function()return f.Actor,f.ActorRoot,f.ActorHumanoid end,
  KickSession=function()if f.Shared then return {Character=f.Character,Root=f.Root}end end,
  Paused=function()return f.Paused end,Busy=function()return f.Busy end,
  Owned=function(root)return f.Physical[root]==true and f.Marker[root]==true end,
  Grab=function(root)f.Log[#f.Log+1]='Grab';f.Marker[root]=true;if not f.NoPhysical then f.Physical[root]=true end end,
  Release=function(root)
   f.Log[#f.Log+1]='Release'
   if f.ReleaseAlwaysFails then error('Remote destroyed')end
   if f.ReleaseFailures>0 then f.ReleaseFailures-=1;error('Transient release failure')end
   if f.ReleaseReturnsFalse then f.ReleaseReturnsFalse=false;return false end
   f.Marker[root]=false;f.Physical[root]=false
  end,
  Acquire=function(root,valid)
   f.Log[#f.Log+1]='Acquire';f.Busy=true;coroutine.yield(f.AcquireDelay);f.Busy=false
   if valid()or f.GrantLate then f.Marker[root]=true;if not f.NoPhysical then f.Physical[root]=true end end
   return valid()
  end,
  RequestRagdoll=function(_,valid)
   check(valid(),'Invalid character submitted to pallet work');f.Log[#f.Log+1]='Ragdoll'
   if f.AutoRagdoll then f.Ragdolled.Value=true end
  end,
  CancelRagdoll=function()f.Log[#f.Log+1]='CancelRagdoll'end,
  PingSeconds=function()return .1 end,
  Reset=function(root,valid)
   check(valid()and f.Marker[root]and f.Physical[root],'Reset used stale/unowned/cancelled state')
   f.Log[#f.Log+1]='Reset';return true,'Local only',true
  end}
 f.Context=ctx;f.Destroy=Destroy.Install(ctx);f.Destroy:SetEnabled(true);return f
end
local function test(name,fn)local ok,err=pcall(fn);assert(ok,name..': '..tostring(err))end
local function count(list,value)local n=0;for _,v in ipairs(list)do if v==value then n+=1 end end;return n end

test('native acknowledgement and physics frame gate',function()
 local f=fixture();f:Advance(.2)
 check(f.Destroy.Applied==1 and count(f.Log,'Reset')==1,'Confirmed physical ownership/ragdoll never reached verified reset')
 check(table.find(f.Log,'Ragdoll')<table.find(f.Log,'Grab')and table.find(f.Log,'Grab')<table.find(f.Log,'Reset'),'Native recovery ordering changed')
 f.Destroy:SetEnabled(false);check(count(f.Log,'Release')==1 and not f.Physical[f.Root],'Disable left a native grab active')
end)
test('stale replicated owner marker is not physical authority',function()
 local f=fixture();f.NoPhysical=true;f.Marker[f.Root]=true;f:Advance(1)
 check(f.Destroy.Applied==0 and not table.find(f.Log,'Reset'),'A stale marker authorized a replication-root mutation')
end)
test('ragdoll acknowledgement is required',function()
 local f=fixture();f.AutoRagdoll=false;f:Advance(.8)
 check(f.Destroy.Applied==0 and count(f.Log,'Release')>=1,'Missing game ragdoll was mistaken for recovery or grab was never released')
end)
test('movement pause releases our own grab and queued pallet work',function()
 local f=fixture();f:Advance(.05);check(f.Physical[f.Root],'Fixture did not acquire')
 f.Paused=true;f:Advance(.05)
 check(not f.Physical[f.Root]and f.Destroy.States[f.Player]==nil,'Paused desync keeps fighting another movement/ownership controller')
 check(count(f.Log,'CancelRagdoll')==1 and count(f.Log,'Reset')==0,'Pause did not cancel queued pallet work')
end)
test('other ownership operation releases our grab',function()
 local f=fixture();f:Advance(.05);f.Busy=true;f:Advance(.05)
 check(not f.Physical[f.Root]and f.Destroy.States[f.Player]==nil,'Foreign ownership mutex leaves desync native grab active')
end)
test('own yielding acquisition does not cancel itself on the ownership mutex',function()
 local f=fixture();f.Root.Position=Vector3.new(100,0,0);f:Advance(.2)
 check(f.Destroy.Acquiring~=nil and f.Destroy.States[f.Player]~=nil,'Own SNO mutex cancelled its own acquisition')
 check(count(f.Log,'Acquire')==1 and count(f.Log,'Release')==0,'Own pending acquisition was repeated/released early')
 f:Advance(.3);check(f.Destroy.Applied>=1,'Far native acquisition never advances after its mutex clears')
end)
test('pause while acquiring releases after the last possible grant',function()
 local f=fixture();f.Root.Position=Vector3.new(100,0,0);f.GrantLate=true;f:Advance(.05)
 f.Paused=true;f:Advance(.05)
 check(count(f.Log,'Release')==0,'Release raced ahead of still-yielding native acquisition')
 f:Advance(.4)
 check(not f.Physical[f.Root]and count(f.Log,'Release')==1 and not f.Destroy.Acquiring,'Late native grant survived pause')
end)
test('shared kick owns its grab and ragdoll cleanup',function()
 local f=fixture();f.Shared=true;f.Marker[f.Root]=true;f.Physical[f.Root]=true;f.Ragdolled.Value=true
 f:Advance(.1);f.Paused=true;f:Advance(.05);f.Destroy:SetEnabled(false)
 check(f.Physical[f.Root]and count(f.Log,'Release')==0 and count(f.Log,'CancelRagdoll')==0,'Desync cleanup stole an existing kick grab/pallet')
end)
test('target respawn cancels old asynchronous acquisition',function()
 local f=fixture();f.Root.Position=Vector3.new(100,0,0);f.GrantLate=true;f:Advance(.05);local oldRoot=f.Root
 f.Character=newNode('Model');f.Character.Parent=f.World;f.Root=newNode('Part');f.Root.Parent=f.Character
 f.Humanoid=newNode('Humanoid');f.Humanoid.Health=0;f.Humanoid.Parent=f.Character;f:Advance(.5)
 check(not f.Physical[oldRoot]and not f.Physical[f.Root]and count(f.Log,'Reset')==0,'Old target acquisition followed the replacement avatar')
end)
test('unload retains only cleanup until a late acquisition is released',function()
 local f=fixture();f.Root.Position=Vector3.new(100,0,0);f.GrantLate=true;f.ReleaseFailures=1;f:Advance(.05)
 f.Destroy:Dispose();check(f.Beat.Connections[1].Connected,'Unload disconnected cleanup before acquisition completed')
 f:Advance(.7)
 check(not f.Physical[f.Root]and count(f.Log,'Release')==2,'Transient release failure stranded a late grant after unload')
 check(not f.Beat.Connections[1].Connected and f.Destroy.Connection==nil and next(f.Destroy.Cleanup)==nil,'Finished unload left a cleanup observer alive')
 local resets=count(f.Log,'Reset');f:Advance(.3);check(count(f.Log,'Reset')==resets,'Unloaded controller resumed mutations')
end)
test('explicit false release is retried rather than counted as success',function()
 local f=fixture();f:Advance(.05);f.ReleaseReturnsFalse=true;f.Destroy:Dispose();f:Advance(.3)
 check(not f.Physical[f.Root]and count(f.Log,'Release')==2 and not f.Beat.Connections[1].Connected,'False native release result was treated as acknowledged')
end)
test('permanently missing release remote does not leak an unload observer',function()
 local f=fixture();f:Advance(.05);f.ReleaseAlwaysFails=true;f.Destroy:Dispose();f:Advance(2.5)
 check(not f.Beat.Connections[1].Connected and f.Destroy.Connection==nil,'Permanent release failure leaks an unloaded Heartbeat')
 check(f.Physical[f.Root]and f.Destroy.AbandonedCleanup==1 and f.Destroy.LastError~=nil,'Failed cleanup was falsely reported as native release success')
end)
test('removed local root cancels an active native grab',function()
 local f=fixture();f:Advance(.05);f.ActorRoot.Parent=nil;f:Advance(.05)
 check(not f.Physical[f.Root]and next(f.Destroy.States)==nil,'Removed local root left native recovery running')
end)
test('selection and local death cancel active work',function()
 local f=fixture();f:Advance(.05);f.Selected=false;f:Advance(.05)
 check(not f.Physical[f.Root]and next(f.Destroy.States)==nil,'Deselection retained native grab')
 local g=fixture();g:Advance(.05);g.ActorHumanoid.Health=0;g:Advance(.05)
 check(not g.Physical[g.Root]and next(g.Destroy.States)==nil,'Local death retained native grab')
end)
print('PASS: '..checks..' desync physical-authority, shared-kick, pause, acquisition, retry and lifecycle checks (mocked)')
