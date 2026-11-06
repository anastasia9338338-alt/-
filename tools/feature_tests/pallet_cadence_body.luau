-- Pure scheduling tests: no touch, transform or server-kick simulation.
local assertions=0
local function expect(value,message)assert(value,message);assertions+=1 end
local function near(a,b)return math.abs(a-b)<1e-8 end
local entry={Character='original character'}
local speeds={28,48,48,48,48,28,48,48,48,48,28}
local clears={.06,.2,.06,.06,.06,.25,.2,.06,.06,.06,.25}
for i=1,#speeds do
 local plan=Cadence.Plan(entry,.2)
 expect(plan.Speed==speeds[i]and near(plan.ClearSeconds,clears[i]),'Single/hover/four-hit/recovery sequence changed at stroke '..i)
 -- A failed attempt does not call Completed; telemetry changes cannot alter
 -- the plan already being used by a pending physical stroke.
 for _,ping in ipairs({0,.05,.9,9})do
  local retry=Cadence.Plan(entry,ping)
  expect(retry==plan and retry.Speed==speeds[i]and near(retry.ClearSeconds,clears[i]),'A retry advanced or changed the pending plan')
 end
 Cadence.Completed(entry)
 expect(plan.Speed==speeds[i]and near(plan.ClearSeconds,clears[i]),'Completion mutated a plan still referenced by a caller')
end
local first,second={},{}
local initial=Cadence.Plan(first,.2);Cadence.Completed(first)
local burst=Cadence.Plan(first,.2);local independent=Cadence.Plan(second,0)
expect(initial.Speed==28 and independent.Speed==28 and independent.ClearSeconds==.06,'Targets shared their stroke progression')
expect(burst.Speed==48 and near(burst.ClearSeconds,.2),'First target lost its separate burst plan')
Cadence.Completed(second)
expect(near(Cadence.Plan(second,0).ClearSeconds,.12)and Cadence.Plan(first,.8)==burst,'Target telemetry or completion leaked to another target')
local malformed={{Value=nil},{Value=false},{Value='bad'},{Value=0/0},{Value=math.huge},{Value=-math.huge},{Value=-1},{Value=0},{Value=.05},{Value=.4},{Value=1e100}}
for _,item in ipairs(malformed)do
 local target={}
 for n=0,5 do
  local plan=Cadence.Plan(target,item.Value)
  expect(plan.Speed==28 or plan.Speed==48,'Plan produced an unsupported stroke speed')
  expect(type(plan.ClearSeconds)=='number'and plan.ClearSeconds==plan.ClearSeconds and plan.ClearSeconds<math.huge,'Malformed ping produced nonfinite clear time')
  if n==0 then expect(plan.ClearSeconds==.06,'Initial probe acquired an unintended pause')
  elseif n==1 then expect(plan.ClearSeconds>=.12 and plan.ClearSeconds<=.25,'Burst hover escaped its bounds')
  elseif n<5 then expect(plan.ClearSeconds==.06,'Burst interior acquired an unintended pause')
  else expect(plan.ClearSeconds>=.18 and plan.ClearSeconds<=.35,'Recovery probe escaped its bounds')end
  Cadence.Completed(target)
 end
end
Cadence.Reset(entry)
local reset=Cadence.Plan(entry,.9)
expect(reset.Speed==28 and reset.ClearSeconds==.06,'Reset did not restart with the initial single probe')
expect(entry.Character=='original character','Cadence reset changed unrelated target state')
print('PASS: '..assertions..' per-target single/hover/burst cadence, retries, reset and malformed-ping checks (pure)')
