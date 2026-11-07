local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function fixture()
 local world=newNode('Folder');local inv=newNode('Folder');inv.Parent=world
 local c=newNode('Model');c.Parent=world;local r=newNode('Part');r.Parent=c;local h=newNode('Humanoid');h.Parent=c;h.Health=100
 local blob=newNode('Model','CreatureBlobman');blob.Parent=inv;local sub=newNode('Model');sub.Parent=blob
 local seat=newNode('VehicleSeat','VehicleSeat');seat.Parent=sub;seat.CFrame=CFrame.new(30,3,0)
 local root=newNode('Part','HumanoidRootPart');root.Parent=blob;root.AssemblyMass=60
 local native=newNode('BodyPosition');native.Parent=root;native.MaxForce=Vector3.new(1,2,3)
 local d={Now=0,Queue={},Teleports=0,Owned=true,Spawned=0,Destroyed=0};local pre=signal()
 function seat:Sit(who)d.SitCalls=(d.SitCalls or 0)+1;self.Occupant=who;who.SeatPart=self;who.Sit=true end
 local ctx={RunService={PreSimulation=pre},Clock=function()return d.Now end,SpawnThread=function(fn)d.Queue[#d.Queue+1]=fn end,
  Character=function()return c,r,h end,Inventory=function()return inv end,Blocked=function()return d.Blocked end,
  Spawn=function()d.Spawned+=1 end,Wait=function(dt)d.Now+=dt end,
  Teleport=function(part,cf)d.Teleports+=1;part.CFrame=cf end,Owned=function()return d.Owned end,
  RequestOwner=function()d.OwnRequests=(d.OwnRequests or 0)+1 end,Direction=function()return Vector3.new(1,1,0),Vector3.new(0,0,-1)end}
 local ride=Ride.Install(ctx)
 return ride,d,pre,c,r,h,blob,seat,root,native
end
do
 local ride,d,pre,c,r,h,blob,seat,root,native=fixture()
 h.SeatPart=seat;seat.Occupant=h;ride:Step(1/60);check(ride:Current()==blob,'Already seated nested Blobman not detected')
 local original=native.MaxForce;ride:SetFrozen(true);ride:Step(1/60)
 check(ride.Session and ride.Session.Mode=='Freeze'and ride.Session.Position.MaxForce.Y>0,'Freeze has no force')
 check(native.MaxForce.Magnitude==0,'Native forces fight freeze');local position=ride.Session.Position.Position
 ride:Step(1/60);check((ride.Session.Position.Position-position).Magnitude==0,'Freeze point drifted')
 ride:SetFly(true);ride:Step(1/60);check(not ride.Frozen and ride.Session.Mode=='Fly','Flight/freeze conflict')
 check(ride.Session.Position.Velocity.Magnitude>0 and ride.Session.Position.Velocity.Magnitude<=ride.Speed,'Flight direction/speed invalid')
 d.Owned=false;ride:Step(1/60);check(not ride.Session and native.MaxForce==original,'Ownership loss leaked forces')
 check(d.OwnRequests==1,'Ownership request missing');ride:Step(1/60);check(d.OwnRequests==1,'Ownership requests flooded')
 d.Owned=true;ride:Step(1/60);h.SeatPart=nil;seat.Occupant=nil;ride:Step(1/60)
 check(not ride.Session and native.MaxForce==original,'Seat exit did not restore vehicle')
 ride:Dispose();check(not pre.Connections[1].Connected,'Ride physics callback leaked')
end
do
 local ride,d,pre,c,r,h,blob,seat=fixture();ride:SetAutoSit(true);ride:Step(1/60)
 check(#d.Queue==1,'Auto Sit failed to queue');d.Queue[1]()
 check(h.SeatPart==seat and d.Teleports==1 and d.Spawned==0,'Auto Sit did not seat or teleported back after seating')
 local p=r.CFrame;ride:Step(1/60);check(r.CFrame==p and not ride.Seating,'Seated update moved character')
 ride:Dispose()
end
do
 local ride,d,pre,c,r,h,blob,seat=fixture();ride:SitOnce();ride:SetAutoSit(false);d.Queue[1]()
 check(d.Teleports==0 and not h.SeatPart,'Canceled seat task acted on avatar');ride:Dispose()
end
do
 local ride,d,pre,c,r,h,blob,seat=fixture();seat.Occupant={};ride:SitOnce();d.Queue[1]()
 check(d.Teleports==0 and seat.Parent and blob.Parent and d.Spawned==1,'Occupied Blobman was reused/deleted');ride:Dispose()
end
do
 local ride,d,pre,c,r,h,blob,seat=fixture();ride:SitOnce();h.Health=0;d.Queue[1]()
 check(not h.SeatPart and d.Teleports==0,'Dead avatar was auto-seated');ride:Dispose()
end
print('PASS: '..checks..' Blobman seat, freeze, flight, ownership and cancellation checks (mocked)')
