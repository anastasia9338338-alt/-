local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function fixture()
 local world=newNode('Folder');local c=newNode('Model');c.Parent=world;local r=newNode('Part');r.Size=Vector3.new(2,2,1);r.CFrame=CFrame.new(-8,1,0);r.Parent=c
 local leg=newNode('Part','Left Leg');leg.Size=Vector3.new(1,2,1);leg.Parent=c
 local h={Health=100,HipHeight=0,State=Enum.HumanoidStateType.Swimming};function h:GetState()return self.State end;function h:ChangeState(v)self.State=v end
 local d={Now=0,Calls=0};local heart=signal();local slide={}
 function slide:IsMoving()return self.Session~=nil end
 function slide:Cancel(reason)local s=self.Session;self.Session=nil;if s and s.Options.Finished then s.Options.Finished(reason)end end
 function slide:Go(point,options)d.Calls+=1;self.Session={Point=point,Options=options,Source=options.Source};return true end
 local ctx={RunService={Heartbeat=heart},Clock=function()return d.Now end,Character=function()return c,r,h end,Slide=slide,
  Surface=function(p)return Vector3.new(p.X,0,p.Z)end,Blocked=function()return d.Blocked end,Supported=function()return d.Supported end,
  Probe=function(p)if p.X>=0 and not d.NoShore then return {Position=Vector3.new(p.X,0,p.Z),Normal=Vector3.yAxis,Material=Enum.Material.Sand}end end,
  Clear=function()return not d.BlockedShore end}
 local rescue=Rescue.Install(ctx);return rescue,d,ctx,c,r,h,slide,heart
end
do
 local a,d,ctx,c,r,h,s,heart=fixture();a:SetEnabled(true);a:Step()
 check(d.Calls==1 and s.Session.Options.Smooth and s.Session.Source=='water','Water did not start smooth recovery')
 local job=s.Session;check(job.Point.X>=4.9 and job.Point.X<10 and math.abs(job.Point.Y-3.2)<.001,'Recovery was not nearest dry shoreline with feet clearance')
 a:Step();check(d.Calls==1,'Recovery started parallel transfers')
 r.CFrame=CFrame.new(job.Point);s.Session=nil;job.Options.Finished('completed')
 check(h.State==Enum.HumanoidStateType.Running,'Recovery did not return normal walking')
 a:Step();check(a.LastSafe~=nil and d.Calls==1,'Dry shore was retriggered as water')
 a:Dispose();check(not heart.Connections[1].Connected,'Recovery callback leaked')
end
do
 local a,d,ctx,c,r,h,s=fixture();a:SetEnabled(true);d.Supported=true;a:Step();check(d.Calls==0,'Water walk support triggered rescue')
 d.Supported=false;h.SeatPart={};a:Step();check(d.Calls==0,'Vehicle rider was rescued');h.SeatPart=nil;d.Blocked=true;a:Step();check(d.Calls==0,'Blocked controller was interrupted')
 d.Blocked=false;d.NoShore=true;a:Step();check(d.Calls==0,'No-shore case used a guessed/spawn coordinate');a:Dispose()
end
do
 local a,d,ctx,c,r,h,s=fixture();a:SetEnabled(true);h.Health=20;a:Step();check(s.Session.Options.Duration<=.55,'Low-health recovery was delayed')
 local job=s.Session;a:SetEnabled(false);check(not s.Session,'Disabling left water transfer active')
 local state=h.State;job.Options.Finished('completed');check(h.State==state,'Canceled completion touched character')
 s.Session={Source='cursor'};a:Dispose();check(s.Session~=nil,'Water unload canceled unrelated cursor TP')
end
print('PASS: '..checks..' dry shoreline selection, smooth rescue, support, cancellation and lifecycle checks (mocked)')
