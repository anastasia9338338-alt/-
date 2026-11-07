local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local world=newNode('Folder');local hole=newNode('Part','Hole');hole.Parent=world;hole.Size=Vector3.new(8,8,1)
local original=hole.CFrame;local camera={CFrame=CFrame.new(0,0,20)}
check(#Volume.Names==18,'Missing volume styles')
for _,style in ipairs(Volume.Names)do
 local fx=Volume.new(hole,style);local before=#ALL_INSTANCES
 check(#fx.Parts<=205,'Unbounded volume geometry')
 fx:Update(0,1,Color3.new(1,1,1),camera,true);local first=fx.Debris[1].CFrame
 for i=1,30 do fx:Update(i/30,1,Color3.new(.8,1,1),camera,true)end
 check((fx.Debris[1].CFrame.Position-first.Position).Magnitude>.05,'Fragments are static')
 check(#ALL_INSTANCES==before,'Per-frame volume allocation')
 for _,p in ipairs(fx.Parts)do check(not p.CanCollide and not p.CanTouch and not p.CanQuery and p.Anchored,'FX introduced physics')end
 check(hole.CFrame==original and hole.Transparency==0,'FX changed original hole')
 camera.CFrame=CFrame.new(1000,0,0);fx:Update(1,1,Color3.new(1,1,1),camera,true)
 for _,p in ipairs(fx.Parts)do check(p.Transparency==1,'Distant geometry not culled')end
 camera.CFrame=CFrame.new(0,0,20);fx:Update(1,1,Color3.new(1,1,1),camera,false);check(not fx.Visible,'Disabled volume remained visible')
 fx:Destroy();fx:Destroy();check(not fx.Folder.Parent,'Volume folder leaked')
end
print('PASS: '..checks..' blackhole volume geometry, animation, budget and cleanup checks (mocked)')
