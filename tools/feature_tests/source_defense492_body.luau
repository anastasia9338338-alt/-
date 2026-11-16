local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function actor(world,name)
 local c=newNode('Model',name);c.Parent=world
 local r=newNode('Part','HumanoidRootPart');r.Parent=c
 local h=newNode('Humanoid');h.Parent=c;h.Health=100
 return c,r,h
end
do
 local world=newNode('Folder','Workspace');local c,r,h=actor(world,'Me');local tc,tr,th=actor(world,'Rider')
 local me,other={Name='Me'},{Name='Rider'};local now=0;local calls=0;local protected=false
 local blob=newNode('Model','CreatureBlobman');blob.Parent=world
 local seat=newNode('Part','VehicleSeat');seat.Parent=blob;th.SeatPart=seat;tr.Position=Vector3.new(15,0,0)
 local beat=signal()
 local guard=Rider.Install({RunService={Heartbeat=beat},Clock=function()return now end,Player=me,Workspace=world,
  Players=function()return{me,other}end,Protected=function()return protected end,
  Character=function(p)if p==other then return tc,tr,th end;return c,r,h end,
  Grab=function(part)check(part==tr,'Rider guard targeted local body/PCLD/detector');calls+=1 end})
 guard:SetEnabled(true);for _=1,120 do now+=1/120;beat:Fire()end
 check(calls>=5 and calls<=8,'Rider ownership request cadence is missing or unbounded')
 check(r.Position==Vector3.zero and tr.Position==Vector3.new(15,0,0),'Rider guard moved an avatar')
 local before=calls;tr.Position=Vector3.new(20,0,0)
 for _=1,60 do now+=1/60;beat:Fire()end
 check(calls==before,'Rider source radius exceeds 19 studs')
 tr.Position=Vector3.new(10,0,0);protected=true;now+=.2;beat:Fire();check(calls==before,'Protected rider was targeted')
 protected=false;th.SeatPart=nil;now+=.2;beat:Fire();check(calls==before,'Standing player was targeted')
 th.SeatPart=seat;guard:SetEnabled(false);now+=1;beat:Fire();check(calls==before,'Disabled rider guard sent ownership requests')
 guard:Dispose();check(not guard.Connection.Connected,'Rider guard leaked a frame connection')
end
for _,cancel in ipairs({'none','disable','respawn','unload'})do
 local world=newNode('Folder');local c,r,h=actor(world,'Me');local now=0;local beat=signal();local queue={}
 local head=newNode('Part','Head');head.Parent=c;local arm=newNode('Part','Left Arm');arm.Parent=c
 local l=newNode('Part','Left Leg');l.Parent=c;local rr=newNode('Part','Right Leg');rr.Parent=c
 local suspended,resumed,removed,cleared=0,0,0,0
 local guard=Legs.Install({RunService={Heartbeat=beat},Clock=function()return now end,
  Character=function()return c,r,h end,Spawn=function(fn)queue[#queue+1]=fn end,
  Suspend=function()suspended+=1;return function()resumed+=1 end end,
  RemoveLegs=function(valid)check(valid(),'Native leg transaction started stale');removed+=1;l:Destroy();rr:Destroy()end,
  Recover=function(root)check(root==r,'Leg cleanup followed another root');cleared+=1 end})
 guard:SetEnabled(true);beat:Fire();check(#queue==1,'Leg operation did not coalesce')
 if cancel=='disable'then guard:SetEnabled(false)
 elseif cancel=='respawn'then c,r,h=actor(world,'NewMe')
 elseif cancel=='unload'then guard:Dispose()end
 queue[1]()
 if cancel=='none'then
  check(removed==1 and suspended==1 and resumed==1 and cleared==1,'Native leg removal or guard restoration failed')
  check(head.Parent~=nil and arm.Parent~=nil,'Leg protection removed head or arms')
  now+=2;beat:Fire();check(#queue==1,'Already removed legs queued again')
 else check(removed==0 and suspended==0 and cleared==0,'Cancelled queued leg operation touched an avatar')end
 guard:Dispose();check(not guard.Connection.Connected,'Leg protection leaked a connection')
end
do
 local now=0;local waits=0;local cadence=Cadence.new({Clock=function()return now end,Signal={Wait=function()now+=1/60;waits+=1 end}})
 check(cadence:SetDelay(0),'Zero source delay was rejected');cadence:Half(function()return true end);check(waits==1,'Zero delay did not wait for an actual frame')
 now=0;waits=0;cadence:SetDelay(1000);cadence:Half(function()return true end);cadence:Half(function()return true end)
 check(now>=1 and now<1.05,'1000ms source delay did not time the complete Grab/Drop cycle')
 check(not cadence:SetDelay(0/0)and cadence.DelayMS==1000,'Nonfinite Blobman delay was accepted')
end
print('PASS: '..checks..' source rider guard, legs-only native dispatch, 0–1000ms delay and cancellation checks (mocked)')
