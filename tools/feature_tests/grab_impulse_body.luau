local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local world=newNode('Folder');local root=newNode('Part');root.Parent=world
local h={Health=100,WalkSpeed=16,JumpPower=50,MoveDirection=Vector3.xAxis}
local guard=Impulse.new({Gravity=function()return 196.2 end});local now=0
local function step(v,held,enabled)
 now+=1/60;root.AssemblyLinearVelocity=v;guard:Step(root,h,enabled~=false,held,now,1/60);return root.AssemblyLinearVelocity
end
local frame=root.CFrame
check(step(Vector3.new(80,-200,2),false).Y==-200,'Unattacked falling was changed')
check(step(Vector3.new(16,50,0),true).Y==50,'Native jump was suppressed')
for _=1,90 do
 local v=step(Vector3.new(1500,900,700),true)
 check(v.X==16 and v.Z==0 and v.Y<=50,'Repeated grab impulse escaped the bound')
 check(root.CFrame==frame,'Impulse protection moved the root')
end
check(guard.Corrections>=90,'No repeated-attack correction recorded')
check(root.AssemblyLinearVelocity.Y<0,'Repeated upward injections produced levitation')
local falling=step(Vector3.new(16,0,0),true)
for _=1,40 do falling=step(falling-Vector3.yAxis*(196.2/60),true)end
check(math.abs(falling.Y+40*196.2/60)<.00001,'Protection canceled native gravity')
step(Vector3.new(16,-5000,0),true);check(root.AssemblyLinearVelocity.Y>-1000,'Injected downward impulse was retained')
now+=.4;check(step(Vector3.new(300,120,0),false).X==300,'Release grace did not end')
check(step(Vector3.new(900,900,0),true,false).X==900,'Disabled guard wrote velocity')
h.SeatPart={};check(step(Vector3.new(800,200,0),true).X==800,'Real seated vehicle was clamped');h.SeatPart=nil
root.AssemblyAngularVelocity=Vector3.new(0,300,0);step(Vector3.new(16,0,0),true)
check(root.AssemblyAngularVelocity.Magnitude==0,'Injected angular spin survived')
local replacement=newNode('Part');replacement.Parent=world;replacement.AssemblyLinearVelocity=Vector3.new(1,50,0)
guard:Step(replacement,h,true,false,now,1/60);check(replacement.AssemblyLinearVelocity.Y==50,'Respawn inherited old vertical bound')
guard:Reset();replacement.AssemblyLinearVelocity=Vector3.new(900,2000,0)
guard:Step(replacement,h,true,true,now,1/60);check(replacement.AssemblyLinearVelocity.Y<=0,'First observed grab launch escaped protection')
print('PASS: '..checks..' grab impulse, native movement, gravity, release and respawn checks (mocked)')
