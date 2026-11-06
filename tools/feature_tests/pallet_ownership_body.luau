-- Owner acknowledgements and physics handoffs are intentionally independent.
-- Requests below only change fixture state; no server hit is simulated.
local function ownershipFixture()
 local sim=Sim.new();currentSim=sim
 local part=newNode('Part','PalletSound',WORLD)
 local d={Marker=true,Physics=false,Valid=true,Busy=false,Grabs={},Approaches=0}
 local ctx={Clock=function()return sim.Now end,Signal=sim.RunService.PreSimulation,PingSeconds=function()return .1 end,
  MarkerOwned=function(p)check(p==part,'Marker check used another part');if d.ThrowMarker then error('marker denied')end;return d.Marker end,
  PhysicsOwned=function(p)check(p==part,'Physics check used another part');return d.Physics end,
  Busy=function()if d.ThrowBusy then error('busy denied')end;return d.Busy end,
  Grab=function(p)
   check(p==part,'Grab used another part');check(not d.Busy,'Grab ran during another ownership operation')
   d.Grabs[#d.Grabs+1]=sim.Now
   if d.ThrowGrab then error('grab denied')end
   if d.GrantAfter and #d.Grabs>=d.GrantAfter then d.Physics=true end
  end}
 local owner=Ownership.new(ctx)
 local function valid()return d.Valid end
 local function start()
  d.Done=false;d.Success=nil;d.Reason=nil
  sim:Spawn(function()d.Success,d.Reason=owner:Acquire(part,valid);d.Done=true end)
 end
 return{Sim=sim,Part=part,Data=d,Context=ctx,Owner=owner,Valid=valid,Start=start}
end
for _,fps in ipairs({20,30,60,120,240,1000})do
 local f=ownershipFixture();f.Data.GrantAfter=3;local frame=f.Part.CFrame;local moves=f.Part.Teleports
 f.Start();f.Sim:Run(.7,fps)
 check(f.Data.Done and f.Data.Success and #f.Data.Grabs==3,'Stale owner marker did not trigger fresh physics requests at '..fps)
 for i=2,#f.Data.Grabs do check(f.Data.Grabs[i]-f.Data.Grabs[i-1]>=.1-1e-7,'Ownership retry cadence grew with rendering FPS')end
 check(f.Part.CFrame==frame and f.Part.Teleports==moves,'Ownership helper moved an unowned board')
 check(not f.Owner.InFlight,'Successful ownership left its lock enabled')
end
do
 local f=ownershipFixture();f.Data.Physics=true;f.Data.Busy=true;f.Start()
 check(f.Data.Done and f.Data.Success and #f.Data.Grabs==0,'Confirmed ownership performed another operation')
end
do
 local f=ownershipFixture();f.Data.Marker=false;f.Data.Physics=true;f.Start();f.Sim:Run(.2,240)
 check(not f.Data.Done,'Physics ownership alone was accepted without the marker')
 f.Data.Marker=true;f.Sim:Run(.05,240);check(f.Data.Done and f.Data.Success,'Second ownership condition did not complete the handoff')
end
do
 local f=ownershipFixture();f.Data.Busy=true;f.Data.GrantAfter=1
 f.Context.NeedsApproach=function()return true end
 f.Context.Approach=function(_,valid)check(not f.Data.Busy and valid(),'Approach ignored busy/cancellation');f.Data.Approaches+=1;return true end
 f.Start();f.Sim:Run(.25,240)
 check(#f.Data.Grabs==0 and f.Data.Approaches==0 and f.Owner.InFlight,'Busy ownership operation was bypassed')
 f.Data.Busy=false;f.Sim:Run(.3,240)
 check(f.Data.Done and f.Data.Success and f.Data.Approaches==1 and #f.Data.Grabs==1,'Busy operation did not resume a pending handoff')
end
for _,stop in ipairs({'cancel','dispose','destroy'})do
 local f=ownershipFixture();f.Start();f.Sim:Run(.15,240)
 if stop=='cancel'then f.Data.Valid=false elseif stop=='dispose'then f.Owner:Dispose()else f.Part:Destroy()end
 local before=#f.Data.Grabs;f.Sim:Run(.2,240)
 check(f.Data.Done and not f.Data.Success and not f.Owner.InFlight,'Ownership lifecycle failed: '..stop)
 check(#f.Data.Grabs==before,'Ownership kept requesting after '..stop)
end
do
 local f=ownershipFixture();f.Data.Busy=true;f.Start();f.Sim:Run(.1,240);f.Data.Valid=false;f.Sim:Run(.1,240)
 check(f.Data.Done and not f.Data.Success and #f.Data.Grabs==0 and not f.Owner.InFlight,'Cancelled busy wait retained the ownership lock')
end
do
 local f=ownershipFixture();f.Start();f.Sim:Run(1.1,240)
 check(f.Data.Done and not f.Data.Success and not f.Owner.InFlight,'Ownership timeout retained its lock')
 check(#f.Data.Grabs>=8 and #f.Data.Grabs<=10,'Ownership timeout did not use bounded retries')
 check(type(f.Data.Reason)=='string'and f.Data.Reason:find('physics',1,true),'Ownership timeout omitted the missing physics condition')
 f.Data.GrantAfter=#f.Data.Grabs+1;f.Start();f.Sim:Run(.2,240)
 check(f.Data.Done and f.Data.Success and not f.Owner.InFlight,'Timed-out cached board could not be retried')
 for i=2,#f.Data.Grabs do check(f.Data.Grabs[i]-f.Data.Grabs[i-1]>=.1-1e-7,'Retry clocks were reset between attempts')end
end
do
 local f=ownershipFixture();f.Data.ThrowMarker=true;f.Start()
 check(f.Data.Done and not f.Data.Success and f.Owner.LastError~=nil and not f.Owner.InFlight,'Ownership check error escaped or retained its lock')
 f.Data.ThrowMarker=false;f.Data.GrantAfter=1;f.Start();f.Sim:Run(.2,240)
 check(f.Data.Done and f.Data.Success,'Ownership did not recover from a check error')
end
do
 local f=ownershipFixture();f.Data.ThrowGrab=true;f.Start();f.Sim:Run(.25,240)
 check(f.Owner.LastGrabError~=nil and #f.Data.Grabs<=3,'Grab errors escaped or flooded retries')
 f.Data.ThrowGrab=false;f.Data.GrantAfter=#f.Data.Grabs+1;f.Sim:Run(.2,240)
 check(f.Data.Done and f.Data.Success and not f.Owner.InFlight,'Grab error permanently blocked the handoff')
end
do
 local f=ownershipFixture();f.Context.NeedsApproach=function()return true end
 f.Context.Approach=function(part,valid)
  check(part==f.Part and valid(),'Distant approach received the wrong part or token')
  f.Data.Approaches+=1;f.Sim:Wait(.03);check(valid(),'Distant approach was invalid too early')
  return true -- marker acknowledgement is not physics ownership
 end
 f.Data.GrantAfter=1;f.Start();f.Sim:Run(.3,240)
 check(f.Data.Done and f.Data.Success and f.Data.Approaches==1 and #f.Data.Grabs==1,'Marked distant board skipped physical reacquisition')
 check(f.Data.Grabs[1]>=.13-1e-7,'Distant approach immediately replayed an ownership request')
end
do
 local f=ownershipFixture();f.Data.Marker=false
 f.Context.Approach=function(_,valid)
  f.Data.Approaches+=1;f.Sim:Wait(.1)
  if valid()then f.Data.Marker=true end
  return true
 end
 f.Data.GrantAfter=1;f.Start();f.Sim:Run(.05,240);f.Data.Valid=false;f.Sim:Run(.2,240)
 check(f.Data.Done and not f.Data.Success and #f.Data.Grabs==0 and not f.Owner.InFlight,'Cancelled distant approach issued late direct requests')
end
do
 local f=ownershipFixture();f.Start();local ok=f.Owner:Acquire(f.Part,f.Valid)
 check(not ok and f.Owner.InFlight,'Concurrent request cleared the active acquisition lock')
 f.Data.Physics=true;f.Sim:Run(.05,240);check(f.Data.Done and f.Data.Success,'Concurrent request damaged the original acquisition')
end
print('PASS: '..checks..' independent pallet marker/physics acquisition, cadence, busy, cancellation and retry checks (mocked; no server hits)')
