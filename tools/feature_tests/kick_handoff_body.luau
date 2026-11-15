-- Local scheduling only; this transport never represents a server kick.
-- RemoteEvents are delivered in order, not collapsed into a property update.
do
 local s={}
 check(Handoff.CanGrab(s,0,0,nil),'Initial grab was blocked')
 Handoff.Grabbed(s,4,1,.25)
 check(not Handoff.CanGrab(s,5,1.2,false),'Pending grab admitted another grab')
 check(not Handoff.CanRelease(s,4,2,true),'Acquisition released in its own frame')
 check(not Handoff.CanRelease(s,5,1.049,true),'Acquisition ignored minimum hold')
 check(Handoff.CanRelease(s,5,1.05,true),'Observed acquisition did not admit release')
 check(s.Handoff.Phase=='grab','Release readiness consumed its phase before RPC success')
 Handoff.Released(s,5,1.05,.25)
 check(not Handoff.CanGrab(s,5,2,false),'Release admitted a same-frame grab')
 check(not Handoff.CanGrab(s,6,1.099,false),'Release ignored minimum gap')
 check(Handoff.CanGrab(s,6,1.10,false)and s.Handoff==nil,'Observed release failed to admit/clear the next grab')
 check(s.LastHandoff.Observed and s.LastHandoff.Phase=='released','Observed release diagnostics were lost')
end
do
 local s={};Handoff.Grabbed(s,1,0,.25)
 check(not Handoff.CanRelease(s,2,.349,nil),'Unknown acquisition was treated as acknowledged')
 check(Handoff.CanRelease(s,2,.35,nil)and not s.LastHandoff.Observed,'Acquisition timeout was not bounded or became an acknowledgment')
 Handoff.Released(s,2,.35,.25)
 check(not Handoff.CanGrab(s,3,.524,nil),'Unknown release was treated as observed')
 check(Handoff.CanGrab(s,3,.525,nil)and not s.LastHandoff.Observed,'Release timeout was not bounded or became an acknowledgment')
end
for _,ping in ipairs({0,.05,.25,1,math.huge,-1,0/0})do
 local s={};Handoff.Grabbed(s,1,0,ping)
 check(s.Handoff.Deadline>=.15 and s.Handoff.Deadline<=.7,'Acquisition deadline escaped its bounds')
 Handoff.Released(s,2,1,ping)
 check(s.Handoff.Deadline>=1.05 and s.Handoff.Deadline<=1.3,'Release deadline escaped its bounds')
end
if Loop then
 local function setup(fps,enabledInterval,throwRelease,lowLatency,batchSeconds,allowNoEdges)
  local sim=Sim.new();currentSim=sim;local t=target('Victim')
  local actor=newNode('Model','Actor',WORLD);local ar=newNode('Part','HumanoidRootPart',actor)
  local ah=newNode('Humanoid','Humanoid',actor);ah.Health=100
  batchSeconds=batchSeconds or .05
  local player={};local wire,history={},{};local owner=false;local exposedReleases=0;local nextBatch=batchSeconds
  local grabs,pallet,releaseCalls=0,0,0;local enabled=true;local lastInterval=-1
  local function send(kind)wire[#wire+1]=kind;history[#history+1]={Kind=kind,At=sim.Now}end
  local ctx={RunService=sim.RunService,Clock=function()return sim.Now end,MaximumSpeed=true,LowLatency=lowLatency==true,
   NativePhases=lowLatency=='Native',Enabled=function()return enabled end,Selected=function()return true end,Targets=function()return{player}end,
   Character=function()return t.Character,t.Torso,t.Humanoid end,LocalCharacter=function()return actor,ar,ah end,
   OwnershipBusy=function()return false end,Owned=function()return owner end,NetworkOwned=function()return owner end,
   Grab=function()grabs+=1;send('grab')end,
   Release=function()releaseCalls+=1;if throwRelease and releaseCalls==1 then error('first release rejected')end;send('release')end,
   RequestRagdoll=function()pallet+=1 end,RagdollEnabled=function()return true end,
   Height=function()return 15 end,PingSeconds=function()return .15 end,StickyEnabled=function()return false end,EKIEnabled=function()return false end,
   Collisions=function()end,Limbs=function()end,CancelRagdoll=function()end,RestoreMotors=function()end,
   IntervalReady=function()
    if not enabledInterval then return true end
    if sim.Now-lastInterval<.2-1e-7 then return false end
    lastInterval=sim.Now;return true
   end,
  }
  local loop=Loop.Install(ctx);local session=loop:Create(player,t.Character,t.Torso,t.Humanoid);session.Physics={}
  sim.Before=function(dt)ar.Position+=Vector3.new(4*dt,0,0)end
  sim.After=function()
   if sim.Now+1e-7>=nextBatch then
    for _,command in ipairs(wire)do
     local was=owner;owner=command=='grab'
     if was and not owner then exposedReleases+=1 end
    end
    table.clear(wire)
    nextBatch=nextBatch+batchSeconds
   end
   check((session.Position.Position-(ar.Position+Vector3.new(0,15,0))).Magnitude<1e-6,'Handoff gate stopped the existing hold from following its actor')
  end
  sim:Run(2,fps)
  check(allowNoEdges or exposedReleases>=2,'Batched transport never exposed a released owner at '..fps..' FPS')
  check(grabs>=3 and grabs<=(lowLatency and 61 or 21)and pallet>0,'Handoff gate stopped grabbing/pallet or recreated an FPS-sized flood')
  local previous
  for _,event in ipairs(history)do
   if event.Kind=='grab'and previous and previous.Kind=='release'then
    check(event.At>previous.At and event.At-previous.At>=(lowLatency and math.max(0,1/60-1/fps)or .05)-1e-7,'Release and re-grab shared one native callback')
   end
   if enabledInterval and event.Kind=='grab'then
    if previous and previous.LastGrab then check(event.At-previous.LastGrab>=.2-1e-7,'Enabled interval was bypassed by maximum-speed mode')end
   end
   event.LastGrab=event.Kind=='grab'and event.At or previous and previous.LastGrab;previous=event
  end
  if throwRelease then check(releaseCalls>=2,'Failed release was never retried')end
  loop:Dispose();local before=grabs;sim.After=nil;sim:Run(.3,fps)
  check(grabs==before,'Disposed handoff sent a late grab')
  return grabs,exposedReleases
 end
 for _,fps in ipairs({20,30,60,120,240,1000})do setup(fps,false,false)end
 setup(240,true,false);setup(240,false,true)
 for _,fps in ipairs({30,60,240,1000})do
  local legacy=setup(fps,false,false,false);local fast=setup(fps,false,false,true)
  check(fast>=legacy,'Observed-state path became slower at '..fps..' FPS')
  local native=setup(fps,false,false,'Native');check(native>legacy*1.5,'Source-frame cadence failed to remove acknowledgement bottleneck')
 end
 -- Native SetNetworkOwner/DestroyGrabLine are separate ordered RemoteEvents.
 -- Batching delivery must not erase every intermediate call in the test.
 for _,batch in ipairs({.05,.1,.2})do
  local nativeRequests,nativeReleases=setup(60,false,false,'Native',batch)
  local observedRequests=setup(60,false,false,true,batch)
  check(nativeReleases>=50,'Ordered native release callbacks vanished in delayed delivery')
  check(nativeRequests>=55 and nativeRequests<=61,'Native phase gained an RTT-sized request delay')
  check(nativeRequests>observedRequests,'Acknowledgement gate silently replaced native cadence')
  print(string.format('INFO: ordered %.0fms RemoteEvent delivery / 2s: native %d requests; acknowledgement-gated %d requests (not server kicks)',batch*1000,nativeRequests,observedRequests))
 end
end
-- A stale owner marker cannot acknowledge an acquisition before actual local
-- simulation ownership arrives. The bounded timeout is tested above.
do
 local sim=Sim.new();currentSim=sim;local t=target('StaleMarker');local actor=newNode('Part','Actor',WORLD)
 local player={};local physics=false;local releases=0
 local ctx={Clock=function()return sim.Now end,RunService=sim.RunService,MaximumSpeed=true,LowLatency=true,
  Enabled=function()return true end,Selected=function()return true end,Targets=function()return{player}end,
  Character=function()return t.Character,t.Torso,t.Humanoid end,LocalCharacter=function()return{},actor,t.Humanoid end,
  OwnershipBusy=function()return false end,Owned=function()return physics end,NetworkOwned=function()return physics end,
  MarkerOwned=function()return true end,Grab=function()end,Release=function()releases+=1 end,
  PingSeconds=function()return .15 end,Height=function()return 15 end,RagdollEnabled=function()return false end,
  StickyEnabled=function()return false end,EKIEnabled=function()return false end,
  Collisions=function()end,Limbs=function()end,CancelRagdoll=function()end,RestoreMotors=function()end}
 local loop=Loop.Install(ctx);local session=loop:Create(player,t.Character,t.Torso,t.Humanoid);session.Physics={}
 sim:Run(.1,60)
 check(releases==0,'Stale owner marker released a grab before physical ownership was observed')
 physics=true;sim:Run(1/60,60)
 check(releases==1,'Confirmed physics handoff retained an unnecessary acknowledgment delay')
 loop:Dispose()
end
do
 local s={};Handoff.Grabbed(s,1,0,.1,true)
 check(not Handoff.CanRelease(s,1,.1,true),'Low latency allowed same-frame release')
 check(Handoff.CanRelease(s,2,1/60,true),'Confirmed grab retained the old 50ms pause')
 Handoff.Released(s,2,1/60,.1,true)
 check(not Handoff.CanGrab(s,2,.1,false),'Low latency allowed same-frame regrab')
 check(Handoff.CanGrab(s,3,2/60,false),'Confirmed release retained the old 50ms pause')
 Handoff.Grabbed(s,4,0,.2,true)
 check(not Handoff.CanRelease(s,5,.02,nil),'Unobserved grab bypassed bounded acknowledgement wait')
 Handoff.Grabbed(s,10,0,.5,'Native')
 check(not Handoff.CanRelease(s,10,1,nil)and Handoff.CanRelease(s,11,1/60,nil),'Native phase was same-frame or still waited for marker')
 check(not s.LastHandoff.Observed and s.LastHandoff.Native,'Unobserved native phase was reported as acknowledgement')
 Handoff.Released(s,11,1/60,.5,'Native')
 check(not Handoff.CanGrab(s,11,1,false)and Handoff.CanGrab(s,12,2/60,nil),'Native re-grab ignored frame separation')
end
-- DestroyGrabLine does not promise a replicated PartOwner change next frame.
-- That marker must not impose an RTT/deadline wait on the source native cycle.
do
 local session={}
 for frame=1,120 do
  local now=frame/60
  if frame%2==1 then
   check(Handoff.CanGrab(session,frame,now,true),'Persistent marker throttled native re-grab')
   Handoff.Grabbed(session,frame,now,.5,'Native')
  else
   check(Handoff.CanRelease(session,frame,now,true),'Native release waited for an unrelated marker clock')
   Handoff.Released(session,frame,now,.5,'Native')
  end
 end
end
print('PASS: '..checks..' ownership phase, timeout, batched transport, interval and hold tests (mocked; no server kicks)')
