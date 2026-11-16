local function setup()
 local sim=Sim.new();currentSim=sim
 local inventory=newNode('Folder','Inventory',WORLD);inventory.ChildAdded=sim:Signal()
 local plot=newNode('Folder','PlotInventory',WORLD);plot.ChildAdded=sim:Signal()
 local data={Containers={inventory,plot},Spawns=0,Reserved={},Destroyed={},Spawning=false,Locks=0,Unlocks=0,Valid=true,Delay=.2}
 local function delivery(container,parts)
  local value=newNode('Model','PalletLightBrown')
  if parts then newNode('Part','SoundPart',value);newNode('Part','Main',value)end
  value.Parent=container or data.Containers[1]
  return value
 end
 data.Spawn=function()
  sim:Wait(data.Delay)
  if data.Throw then error('simulated reply error')end
  if data.Reject then return false end
  if not data.Late then local value=delivery(nil,data.Parts);data.Delivered=value;if data.ReturnModel then return value end end
 end
 local supply=Supply.Install({Clock=function()return sim.Now end,SpawnThread=function(fn)sim:Spawn(fn)end,
  WaitFrame=function()sim.RunService.Heartbeat:Wait()end,
  Containers=function()return data.Containers end,CanSpawn=function()return not data.Spawning end,
  Spawning=function(on)data.Spawning=on;if on then data.Locks+=1 else data.Unlocks+=1 end end,
  Reserve=function(value,on)data.Reserved[value]=on and true or nil end,
  Spawn=function()data.Spawns+=1;return data.Spawn()end,
  Destroy=function(value)data.Destroyed[value]=(data.Destroyed[value]or 0)+1;value:Destroy()end})
 return sim,data,supply,delivery
end
for _,fps in ipairs({20,60,240})do
 local sim,data,supply,deliver=setup()
 local unrelated=deliver(data.Containers[1],true)
 local first,second
 sim:Spawn(function()first=supply:Get(function()return data.Valid end)end)
 sim:Spawn(function()second=supply:Get(function()return data.Valid end)end)
 sim:Run(.5,fps)
 check(data.Spawns==1 and first==second and first==data.Delivered,'Concurrent preparation and native worker sent duplicate spawn requests')
 check(first~=unrelated and unrelated.Name=='PalletLightBrown','Pending transaction adopted a pre-existing user pallet')
 check(first.Name=='RagdollRSC'and data.Reserved[first]and not first:FindFirstChild('Main'),'Partial model was not retained/reserved before parts arrived')
 check(supply:Get()==first and data.Spawns==1,'Missing pallet parts caused a second spawn')
 newNode('Part','SoundPart',first);newNode('Part','Main',first)
 check(supply:Find()==first,'Part streaming replaced the retained model')
 check(data.Locks==1 and data.Unlocks==1 and not data.Spawning,'Shared spawn lock was released more than once')
 local other=deliver(data.Containers[1],true)
 check(other.Name=='PalletLightBrown'and not data.Destroyed[other]and not data.Reserved[other],'Completed transaction intercepted a later manual spawn')
 supply:Dispose();sim:Run(.2,fps)
 check(data.Destroyed[first]==1 and not data.Destroyed[unrelated]and not data.Destroyed[other],'Unload destroyed unrelated toys or missed the shared pallet')
end
do
 local sim,data,supply,deliver=setup();data.Late=true
 for _=1,4 do sim:Spawn(function()supply:Get()end);sim:Run(2.1,60)end
 check(data.Spawns==1 and supply.Pending and not data.Spawning,'Unknown/late RPC outcome was retried and could leave duplicate boards')
 local late=deliver(data.Containers[1],false)
 check(supply:Get()==late and data.Reserved[late]and data.Spawns==1,'Late delivery was lost after a caller timeout')
 supply:Dispose()
end
do
 local sim,data,supply=setup();data.Reject=true
 sim:Spawn(function()supply:Get()end);sim:Run(.3,60)
 check(data.Spawns==1 and not supply.Pending and not data.Spawning,'Explicit server rejection retained the spawn lock')
 sim:Spawn(function()supply:Get()end);check(data.Spawns==1,'Server rejection caused an immediate retry burst')
 data.Reject=false;sim:Run(.6,60);sim:Spawn(function()supply:Get()end);sim:Run(.4,60)
 check(data.Spawns==2 and supply:Find()~=nil,'Definite rejected request could not be retried');supply:Dispose()
end
do
 local sim,data,supply,deliver=setup();data.Throw=true
 sim:Spawn(function()supply:Get()end);sim:Run(2.2,60)
 sim:Spawn(function()supply:Get()end);sim:Run(2.2,60)
 check(data.Spawns==1,'Ambiguous remote exception caused an automatic duplicate request')
 local late=deliver();check(supply:Find()==late,'Remote exception discarded a later server-created model');supply:Dispose()
end
do
 local sim,data,supply,deliver=setup();data.Delay=1;data.ReturnModel=true
 sim:Spawn(function()supply:Get(function()return data.Valid end)end);sim:Run(.1,60)
 data.Valid=false;sim:Run(.2,60);data.Valid=true
 sim:Spawn(function()supply:Get(function()return data.Valid end)end);sim:Run(1,60)
 check(data.Spawns==1 and supply:Find()==data.Delivered,'Cancellation followed by restart duplicated the in-flight spawn');supply:Dispose()
end
do
 local sim,data,supply=setup();data.Delay=20
 sim:Spawn(function()supply:Get(function()return data.Valid end)end);sim:Run(.1,60)
 data.Valid=false;sim:Run(2.2,60)
 check(not data.Spawning and data.Spawns==1 and supply.Pending,'Cancelled/hung RPC blocked the whole shop or discarded its late-result tracking')
 supply:Dispose();sim:Run(20,60)
 check(data.Delivered and data.Destroyed[data.Delivered]==1,'Late nil-returning RPC bypassed unload cleanup after the caller had cancelled')
end
do
 local sim,data,supply=setup();data.Delay=4;data.ReturnModel=true
 sim:Spawn(function()supply:Get()end);sim:Run(.1,60);supply:Dispose();sim:Run(4.2,60)
 check(data.Spawns==1 and data.Delivered and data.Destroyed[data.Delivered]==1,'RPC completion after unload left a returned pallet alive')
 check(not next(data.Reserved)and not data.Spawning,'Late unload cleanup retained a reservation/lock')
end
do
 local sim,data,supply=setup();data.Delay=5
 sim:Spawn(function()supply:Get(function()return data.Valid end)end);sim:Run(.1,60);data.Valid=false
 sim:Run(2.5,60)
 local replacement=newNode('Folder','AfterCancellation',WORLD);replacement.ChildAdded=sim:Signal();data.Containers={replacement}
 sim:Run(3,60)
 check(data.Delivered and supply:Find()==data.Delivered and data.Spawns==1,'Cancelled caller stopped observing late delivery into a replaced inventory')
 supply:Dispose()
end
do
 local sim,data,supply=setup();data.Delay=5
 sim:Spawn(function()supply:Get()end);sim:Run(.1,60);supply:Dispose()
 local replacement=newNode('Folder','AfterUnload',WORLD);replacement.ChildAdded=sim:Signal();data.Containers={replacement}
 sim:Run(5.2,60)
 check(data.Delivered and data.Destroyed[data.Delivered]==1,'Late nil RPC in a replaced inventory escaped unload cleanup')
end
do
 local sim,data,supply,deliver=setup();data.Delay=1
 sim:Spawn(function()supply:Get()end);sim:Run(.1,60)
 local replacement=newNode('Folder','Replacement',WORLD);replacement.ChildAdded=sim:Signal();data.Containers={replacement}
 sim:Run(.3,60);sim:Run(1,60)
 check(supply:Find()==data.Delivered and data.Spawns==1,'Inventory replacement/plot destination lost the existing spawn transaction');supply:Dispose()
end
print('PASS: '..checks..' single-pallet concurrency, partial/late replication, rejection, plot replacement, cancellation and late unload checks (mocked)')
