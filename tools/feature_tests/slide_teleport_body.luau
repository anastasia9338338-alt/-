local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function fixture()
 local world=newNode('Folder');local c=newNode('Model');c.Parent=world;local r=newNode('Part');r.Parent=c
 local leg=newNode('Part');leg.Parent=c;leg.CanCollide=false
 local h={Health=100};local d={Now=0,Writes=0,Done={}};local pre=signal();local bound={}
 local run={PreSimulation=pre}
 function run:BindToRenderStep(name,priority,fn)check(priority==99,'TP render priority is after camera');bound[name]=fn end
 function run:UnbindFromRenderStep(name)bound[name]=nil end
 local ctx={RunService=run,RenderPriority=99,Clock=function()return d.Now end,Character=function()return c,r,h end,
  Teleport=function(part,cf)d.Writes+=1;part.CFrame=cf;return not d.Reject end,
  CollisionBlocked=function()return d.Noclip end}
 local slide=Slide.Install(ctx)
 local function step(fps)
  local dt=1/fps;d.Now+=dt;pre:Fire(dt)
  for _,fn in pairs(table.clone(bound))do fn(dt)end
 end
 return slide,d,step,ctx,c,r,h,leg,bound
end
for _,fps in ipairs({30,60,240})do
 local s,d,step,ctx,c,r,h,leg,bound=fixture();local start=r.Position;local count=0
 check(s:Go(Vector3.new(100,5,0),{Smooth=true,Source='cursor',Finished=function(reason)count+=1;check(reason=='completed','Smooth transfer failed')end}),'Smooth TP did not start')
 check(r.Position==start and not r.CanCollide,'TP jumped immediately or collision suppression missing')
 local last=start
 for _=1,fps do
  step(fps)
  check(r.Position.X>=last.X-1e-6 and(r.Position-last).Magnitude<11,'TP stepped backward or jumped abruptly')
  check(not r.Anchored,'Smooth TP anchored avatar');last=r.Position
 end
 check((r.Position-Vector3.new(100,5,0)).Magnitude<1e-5 and not s:IsMoving()and count==1,'TP did not land once at target')
 check(r.CanCollide and not leg.CanCollide and next(bound)==nil,'Collision/render bindings leaked')
 s:Dispose()
end
do
 local s,d,step,ctx,c,r,h=fixture();s:Go(Vector3.new(150,0,0),{Smooth=true,Source='cursor'})
 for _=1,10 do step(60)end
 local p=r.Position;local velocity=s.Session.Velocity
 s:Go(Vector3.new(200,0,0),{Smooth=true,Source='cursor'})
 check(r.Position==p and(s.Session.StartVelocity-velocity).Magnitude<1e-5,'Retargeting reset position/velocity abruptly')
 for _=1,60 do step(60)end;check(r.Position.X==200,'Retarget missed latest goal')
 s:Go(Vector3.new(300,0,0),{Smooth=true});h.SeatPart={};local before=r.Position;step(60)
 check(not s:IsMoving()and r.Position==before and r.CanCollide,'Seat change did not cancel cleanly')
 h.SeatPart=nil;s:Go(Vector3.new(400,0,0),{Smooth=true});h.Health=0;before=r.Position;step(60)
 check(not s:IsMoving()and r.Position==before,'Dead avatar kept sliding');s:Dispose()
end
do
 local s,d,step,ctx,c,r,h=fixture();s:Go(Vector3.new(30,0,0),{Smooth=true,Source='water',Arc=3})
 for _=1,8 do step(60)end;check(r.Position.Y>0,'Water recovery arc was absent')
 d.Noclip=true;s:Cancel();check(not r.CanCollide,'Cleanup overrode active noclip')
 local replacement=newNode('Part');replacement.Parent=c;ctx.Character=function()return c,replacement,h end
 local original=replacement.CFrame;s:Dispose();check(replacement.CFrame==original,'Unload touched replacement avatar')
end
print('PASS: '..checks..' smooth TP frame rates, camera order, retarget, collisions and cancellation checks (mocked)')
