-- Full-cycle timing is local scheduling, not a prediction of a server kick.
function Node:GetDescendants()
 local result={}
 for _,child in ipairs(self:GetChildren())do result[#result+1]=child;for _,v in ipairs(child:GetDescendants())do result[#result+1]=v end end
 return result
end
do
 local sim=Sim.new();currentSim=sim;local ping,reads=100,0
 local interval=Interval.Install({RunService=sim.RunService,Clock=function()return sim.Now end,ReadPingMs=function()reads+=1;return ping end})
 check(interval:CycleSeconds()==nil,'Off mode changes native timing')
 interval:SetEnabled(true);check(interval:CycleSeconds()==.1,'Data Ping is not the complete cycle period')
 local originalReads=reads;sim:Run(.1,100);check(reads==originalReads,'Ping polling floods Stats every frame')
 ping=240;sim:Run(.2,100);check(interval:CycleSeconds()==.24,'Changing internet latency does not update cycle')
 interval:SetMode('Manual');interval:SetManual(120);check(interval:CycleSeconds()==.12,'Manual compatibility timing lost')
 interval:SetManual(0/0);check(interval.ManualMs==120,'NaN changes manual timing')
 interval:SetMode('Ping');ping=nil;sim:Run(.3,100);check(interval:CycleSeconds()==.24 and not interval.Available,'Brief missing telemetry loses last valid ping')
 sim:Run(1.1,100);check(interval:CycleSeconds()==nil,'Expired telemetry blocks native timing forever')
 interval:Dispose();check(interval:CycleSeconds()==nil and not interval.Connection.Connected,'Disposed telemetry observer remains active')
end
do
 local sim=Sim.new();currentSim=sim
 local interval=Interval.Install({RunService=sim.RunService,Clock=function()return sim.Now end,ReadPingMs=function()return 100 end})
 local controls={};local group={}
 function group:AddDivider()end
 function group:AddToggle(id,info)local t={Value=info.Default};function t:SetValue(v)self.Value=v;info.Callback(v)end;controls[id]=t;return t end
 function group:AddDependencyBox()return self end
 function group:SetupDependencies()end
 function group:AddDropdown(id,info)local t={};function t:SetValue(v)info.Callback(v)end;controls[id]=t;return t end
 function group:AddSlider(id,info)local t={Value=info.Default};function t:SetValue(v)self.Value=v;info.Callback(v)end;controls[id]=t;return t end
 function group:AddLabel(value)local t={Text=value};function t:SetText(v)self.Text=v end;return t end
 interval:BuildUI(group)
 check(controls.KickLoopIntervalEnabled and not controls.KickLoopIntervalSource and not controls.KickLoopIntervalMs,'Loop MS controls are missing or expose unrelated manual tuning')
 controls.KickLoopIntervalEnabled:SetValue(true)
 check(interval.Enabled and interval.Label.Text:find('cycle: 100 ms',1,true),'UI toggle is disconnected from full-cycle timing')
 interval:SetMode('Manual');interval:SetManual(400);check(interval:CycleSeconds()==.4,'Manual backend compatibility is disconnected')
 controls.KickLoopIntervalEnabled:SetValue(false);controls.KickLoopIntervalEnabled:SetValue(true);check(interval.Mode=='Ping'and interval:CycleSeconds()==.1,'UI activation does not select actual internet timing')
 interval:Dispose()
end
do
 local s={};Handoff.Grabbed(s,1,0,.1,'Native',.1)
 check(not Handoff.CanRelease(s,1,1,true),'Managed release skips physical-frame boundary')
 check(not Handoff.CanRelease(s,2,.049,true),'Release ignores internet half-cycle')
 check(Handoff.CanRelease(s,2,.05,false),'Managed timer waits on an unrelated owner marker')
 Handoff.Released(s,2,.05,.1,'Native',.1)
 check(not Handoff.CanGrab(s,2,1,false),'Managed re-grab skips physical-frame boundary')
 check(not Handoff.CanGrab(s,3,.099,false),'Next grab ignores released half-cycle')
 check(Handoff.CanGrab(s,3,.1,true),'Full cycle gained an extra acknowledgement delay')
end
local function setup(periodMs,fps)
 local sim=Sim.new();currentSim=sim;local t=target('IntervalVictim');local player={}
 local actor=newNode('Model','Actor',WORLD);local root=newNode('Part','HumanoidRootPart',actor);local hum=newNode('Humanoid','Humanoid',actor);hum.Health=100
 local data={Ping=periodMs,Enabled=true,Pallet=0,Hold=0,Events={},Physics=true,Marker=true}
 local interval=Interval.Install({RunService=sim.RunService,Clock=function()return sim.Now end,ReadPingMs=function()return data.Ping end})
 interval:SetEnabled(true)
 local ctx={RunService=sim.RunService,Clock=function()return sim.Now end,MaximumSpeed=true,LowLatency=true,NativePhases=true,
  Enabled=function()return data.Enabled end,Selected=function()return true end,Targets=function()return{player}end,
  Character=function()return t.Character,t.Torso,t.Humanoid end,LocalCharacter=function()return actor,root,hum end,
  OwnershipBusy=function()return false end,Owned=function()return data.Physics and data.Marker end,NetworkOwned=function()return data.Physics end,MarkerOwned=function()return data.Marker end,
  Grab=function(part)data.Events[#data.Events+1]={Kind='grab',At=sim.Now,Part=part}end,
  Release=function(part)data.Events[#data.Events+1]={Kind='release',At=sim.Now,Part=part}end,
  RequestRagdoll=function()data.Pallet+=1 end,RagdollEnabled=function()return true end,Height=function()return 15 end,
  PingSeconds=function()return(data.Ping or periodMs)/1000 end,StickyEnabled=function()return false end,EKIEnabled=function()return false end,
  Collisions=function()data.Hold+=1 end,Limbs=function()end,CancelRagdoll=function()end,RestoreMotors=function()end,
  IntervalSeconds=function()return interval:CycleSeconds()end,ForgetInterval=function(p)interval:Forget(p)end,
 }
 local loop=Loop.Install(ctx)
 sim.Before=function(dt)root.Position+=Vector3.new(3*dt,0,0)end
 sim.After=function()
  local session=loop.Sessions[player]
  if session then check((session.Position.Position-(root.Position+Vector3.new(0,15,0))).Magnitude<1e-6,'Network timer pauses target holding')end
 end
 return sim,data,interval,loop,player,function()return t end,function(v)t=v end
end
for _,fps in ipairs({20,30,60,120,240,1000})do
 for _,ms in ipairs({50,100,240,500})do
  local sim,data,interval,loop=setup(ms,fps);sim:Run(1.7,fps)
  local previous;local grabs=0
  for _,event in ipairs(data.Events)do
   if previous then
    check(event.Kind~=previous.Kind,'Duplicate phase was queued instead of one complete cycle')
    local gap=event.At-previous.At
    check(gap>=ms/2000-1e-6,'A half-cycle is shorter than the measured network timing')
    check(gap<=ms/2000+1/60+1/fps+1e-5,'Full-cycle timing gained a fixed extra pause')
   end
   if event.Kind=='grab'then grabs+=1 end
   previous=event
  end
  check(grabs>=2 and grabs<=math.ceil(1.7/(ms/1000))+1,'Loop MS emitted a catch-up burst or stopped completely')
  check(data.Pallet>grabs and data.Hold>grabs,'Network pacing also throttled ragdoll/holding')
  sim.After=nil;loop:Dispose();interval:Dispose();local count=#data.Events;sim:Run(.3,fps)
  check(#data.Events==count,'A timed release/grab runs after unload')
 end
end
-- A new sample affects the next whole cycle, not the pending half-cycle.
do
 local sim,data,interval,loop=setup(100,240);local changed=false
 sim.Before=function()
  if sim.Now>.025 and not changed then data.Ping=400;interval.LastSample=nil;changed=true end
 end
 sim:Run(.55,240)
 local e=data.Events
 check(#e>=5 and e[1].Kind=='grab'and e[2].Kind=='release','Changing ping cancels the active phase')
 check(e[2].At-e[1].At>=.05-1e-6 and e[2].At-e[1].At<.075,'New ping rewrites the pending release deadline')
 check(e[3].At-e[2].At>=.05-1e-6 and e[3].At-e[2].At<.075,'New ping rewrites the pending released half')
 check(e[4].At-e[3].At>=.2-1e-6 and e[5].At-e[4].At>=.2-1e-6,'Next complete cycle does not use new ping')
 sim.After=nil;loop:Dispose();interval:Dispose()
end
-- Disable removes old long deadlines on the next native frame; it never floods.
do
 local sim,data,interval,loop=setup(1000,240);sim:Run(.03,240)
 interval:SetEnabled(false);local at=sim.Now;sim:Run(.08,240)
 check(data.Events[2]and data.Events[2].Kind=='release'and data.Events[2].At-at<=1/60+1/240+1e-6,'Turning Loop MS off retains a long timed release')
 for i=2,#data.Events do check(data.Events[i].At>data.Events[i-1].At,'Switch-off flushes multiple phases in one frame')end
 sim.After=nil;loop:Dispose();interval:Dispose()
end
-- Cancellation and target replacement cannot release/grab the replacement root.
do
 local sim,data,interval,loop,player,get,set=setup(500,240);sim:Run(.03,240)
 local old=get();local before=#data.Events;local replacement=target('RespawnReplacement');set(replacement);local replacedAt=sim.Now
 sim:Run(.6,240)
 local current=loop.Sessions[player];check(current and current.Root==replacement.Torso,'Respawn lost the current timed session')
 for i=before+1,#data.Events do local e=data.Events[i];check(e.Kind~='grab'or e.Part~=old.Torso,'Old timed session grabbed after replacement')end
 check(data.Events[before+1].Kind=='release'and data.Events[before+1].Part==old.Torso,'Old pending phase cleanup did not release its exact root')
 data.Enabled=false;sim:Run(.03,240);local count=#data.Events;sim:Run(.6,240);check(#data.Events==count,'Disabled timing sends delayed callbacks')
 sim.After=nil;loop:Dispose();interval:Dispose()
end
print('PASS: '..checks..' Loop MS full-cycle ping/manual timing, dynamic samples, frame bounds, UI wiring, hold independence, cancellation and respawn checks (mocked; no server kick speed proof)')
