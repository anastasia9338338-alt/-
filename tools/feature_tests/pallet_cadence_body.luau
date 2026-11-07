-- Pure scheduling tests: no touch, transform, game reaction or server kick.
local assertions=0
local function expect(value,message)assert(value,message);assertions+=1 end
local function near(a,b)return math.abs(a-b)<1e-8 end
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
local entry={Character='original character'}
expect(Cadence.Ready(entry,nil)and Cadence.WaitSeconds(entry,nil)==0 and entry.PalletCadence==nil,'Untouched target acquired an artificial deadline')
expect(not Cadence.Completed(entry,0)and entry.PalletCadence==nil,'Unplanned completion created or advanced a schedule')
local now=0
for n=0,17 do
 local step=n%6
 local phase=step<2 and'Single'or'Burst'
 local index=step<2 and step+1 or step-1
 local gap=step<2 and .7 or(step==5 and 1 or 0)
 local plan=Cadence.Plan(entry,.2)
 expect(plan.Speed==48 and plan.ClearSeconds==.06,'Single and burst strokes acquired different physical impacts')
 expect(plan.Phase==phase and plan.Index==index and near(plan.GapSeconds,gap),'Two-single/four-burst sequence changed at stroke '..n)
 expect(Cadence.Ready(entry,now),'Ready deadline prevented an on-time stroke')
 for _,ping in ipairs({0,.05,.9,9})do
  expect(Cadence.Plan(entry,ping)==plan,'Retry or changing telemetry replaced a pending plan')
 end
 local stepBefore=entry.PalletCadence.Step
 local stable=Cadence.Ready(entry,now);local wait=Cadence.WaitSeconds(entry,now)
 expect(stable and wait==0 and entry.PalletCadence.Step==stepBefore and entry.PalletCadence.Plan==plan,'Reading a deadline advanced the sequence')
 expect(not pcall(function()plan.Speed=1 end),'Plan was mutable after publication')
 now+=.1 -- Represents a completed real traversal, not a contact acknowledgement.
 expect(Cadence.Completed(entry,now),'Completed traversal did not advance its cached plan')
 expect(not Cadence.Completed(entry,now),'Duplicate completion advanced without another planned traversal')
 expect(plan.Phase==phase and near(plan.GapSeconds,gap),'Completion mutated a plan retained by a caller')
 expect(near(Cadence.WaitSeconds(entry,now),gap),'Post-stroke parked wait did not start from actual completion')
 if gap>0 then
  local deadline=now+gap
  expect(not Cadence.Ready(entry,now)and not Cadence.Ready(entry,deadline-.001),'Parked gap released a target early')
  expect(Cadence.Ready(entry,deadline),'Parked target was not ready at its deadline')
  now=deadline
 else expect(Cadence.Ready(entry,now),'Burst interior acquired a parked delay')end
end
-- Independent targets keep cached plans and deadlines separate.
do
 local a,b={},{}
 local first=Cadence.Plan(a,.2);expect(Cadence.Completed(a,10),'First target completion failed')
 local other=Cadence.Plan(b,1)
 expect(Cadence.Ready(b,10)and not Cadence.Ready(a,10),'One target parked another target')
 expect(other.Phase=='Single'and other.Index==1 and other.GapSeconds==1,'Second target inherited the first progression')
 expect(Cadence.Completed(b,10.1),'Second target completion failed')
 expect(near(Cadence.WaitSeconds(a,10.2),.5)and near(Cadence.WaitSeconds(b,10.2),.9),'Target waits shared a deadline')
 expect(Cadence.Plan(a,0).Index==2 and first.Index==1,'Target progression or retained plan was corrupted')
end
-- A long scheduler pause must not replay missed strokes or consume phases.
do
 local e={};Cadence.Plan(e,.1);expect(Cadence.Completed(e,1),'Late-schedule baseline failed')
 local snapshot=e.PalletCadence.Step
 for _=1,20 do expect(Cadence.Ready(e,100)and Cadence.WaitSeconds(e,100)==0,'Late ready state was inconsistent')end
 expect(e.PalletCadence.Step==snapshot and e.PalletCadence.Plan==nil,'A late poll replayed overdue strokes')
 local p=Cadence.Plan(e,.1)
 expect(p.Phase=='Single'and p.Index==2,'A late scheduler skipped to a burst')
 expect(Cadence.Completed(e,100),'Late real completion failed')
 expect(not Cadence.Ready(e,100.1)and near(Cadence.WaitSeconds(e,100.1),.55),'Next gap was measured from an old deadline')
end
local malformed={{Value=nil},{Value=false},{Value='bad'},{Value=0/0},{Value=math.huge},{Value=-math.huge},{Value=-1},{Value=0},{Value=.05},{Value=.4},{Value=1e100}}
for _,item in ipairs(malformed)do
 local e={};local clock=0
 for step=0,5 do
  local p=Cadence.Plan(e,item.Value)
  expect(p.Speed==48 and p.ClearSeconds==.06,'Malformed ping changed the physical impact')
  expect(finite(p.GapSeconds)and p.GapSeconds>=0 and p.GapSeconds<=1,'Malformed ping produced a nonfinite or unbounded parked wait')
  if step<2 then expect(p.Phase=='Single'and p.GapSeconds>=.65,'Single lost its isolated wait')
  elseif step<5 then expect(p.Phase=='Burst'and p.GapSeconds==0,'Burst interior gained an isolated wait')
  else expect(p.Phase=='Burst'and p.GapSeconds==1,'Burst final recovery changed')end
  clock+=.1;expect(Cadence.Completed(e,clock),'Malformed ping prevented a finite completion')
  clock+=p.GapSeconds
 end
end
-- Invalid/stale timestamps cannot consume a plan, shorten a parked gap, or
-- convert missed time into a sequence of same-tick catch-up completions.
for _,item in ipairs({{Value=nil},{Value=false},{Value='bad'},{Value=0/0},{Value=math.huge},{Value=-math.huge},{Value=1e100}})do
 local e={};local plan=Cadence.Plan(e,.1)
 expect(not Cadence.Completed(e,item.Value),'Invalid/unrepresentable clock advanced a plan')
 expect(e.PalletCadence.Step==0 and e.PalletCadence.Plan==plan and e.PalletCadence.Deadline==nil,'Rejected clock changed pending state')
 expect(Cadence.Completed(e,2),'A rejected clock poisoned later valid completion')
 local pending=Cadence.Plan(e,.1);local oldDeadline=e.PalletCadence.Deadline
 expect(not Cadence.Completed(e,1),'Regressed completion advanced a parked target')
 expect(not Cadence.Ready(e,1)and Cadence.WaitSeconds(e,1)==1,'Regressed clock released a parked target')
 expect(e.PalletCadence.Plan==pending and e.PalletCadence.Deadline==oldDeadline,'Regressed clock reset the valid deadline')
 if not finite(item.Value)then
  expect(not Cadence.Ready(e,item.Value),'Invalid clock released an existing target')
  local wait=Cadence.WaitSeconds(e,item.Value)
  expect(finite(wait)and wait>=0 and wait<=1,'Invalid clock escaped bounded diagnostic wait')
 end
end
do
 local e={};Cadence.Plan(e,.1);Cadence.Completed(e,0);local nextPlan=Cadence.Plan(e,.1)
 expect(not Cadence.Completed(e,.2)and e.PalletCadence.Plan==nextPlan,'Premature completion consumed an isolated wait')
 expect(Cadence.WaitSeconds(e,-1e100)==1,'Distant regressed clock produced unbounded wait')
end
Cadence.Reset(entry)
local reset=Cadence.Plan(entry,.9)
expect(reset.Speed==48 and reset.ClearSeconds==.06 and reset.Phase=='Single'and reset.Index==1 and near(reset.GapSeconds,1),'Reset did not restart with an isolated single')
expect(Cadence.Ready(entry,0)and Cadence.WaitSeconds(entry,0)==0,'Reset retained the old recovery deadline')
expect(entry.Character=='original character','Cadence reset changed unrelated target state')
print('PASS: '..assertions..' isolated single/burst scheduling, equal impacts, deadlines, invalid clocks, retries and per-target isolation checks (pure; no game hit/blur/kick proof)')
