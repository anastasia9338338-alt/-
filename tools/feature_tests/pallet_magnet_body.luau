local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function fixture()
 local world=newNode('Folder');local c=newNode('Model');c.Parent=world
 local r=newNode('Part','HumanoidRootPart');r.Parent=c;r.CFrame=CFrame.new(2,5,7)*CFrame.Angles(.2,1.2,.3)
 local h=newNode('Humanoid');h.Parent=c;h.Health=100
 local board=newNode('Part','Pallet');board.Parent=world;board.CFrame=CFrame.new(10,2,-3)
 local d={Part=board};local beat=signal()
 local m=Magnet.Install({RunService={Heartbeat=beat},Character=function()return d.Character or c,d.Root or r,d.Humanoid or h end,
  UnderFeet=function()return d.Part end,Blocked=function()return d.Blocked end})
 return m,d,c,r,h,board,beat
end
do
 local m,d,c,r,h,board,beat=fixture();local original=board.CFrame;local rotation=r.CFrame.Rotation
 check(not m.Connection and not m.Enabled,'Disabled magnet has an idle callback')
 check(m:SetEnabled(true),'Valid underfoot part rejected')
 r.AssemblyLinearVelocity=Vector3.new(10,-3,2);r.AssemblyAngularVelocity=Vector3.new(1,2,3);beat:Fire(1/60)
 check(r.Position==board.Position+Vector3.new(0,3.5,0),'Avatar does not follow the supplied underfoot lock')
 check((r.CFrame.LookVector-rotation.LookVector).Magnitude<1e-6,'Supplied lock changed player rotation')
 check(r.AssemblyLinearVelocity==Vector3.zero and r.AssemblyAngularVelocity==Vector3.zero,'Lock does not stop local drift')
 board.CFrame=CFrame.new(-9,4,8)*CFrame.Angles(.1,.2,.3);beat:Fire(1/60)
 check(r.Position==board.Position+Vector3.new(0,3.5,0),'Moving underfoot part not followed')
 check(board.CanTouch and board.CanCollide and #board:GetChildren()==0,'Magnet modified board physics')
 local conn=m.Connection;m:SetEnabled(false);local released=r.CFrame;board.Position=Vector3.zero;beat:Fire(1/60)
 check(not conn.Connected and not m.Connection and r.CFrame==released,'Disabled magnet retained lock')
 m:Dispose();check(not m:SetEnabled(true),'Disposed magnet reactivated')
end
for _,reason in ipairs({'death','respawn','seat','deleted','blocked'})do
 local m,d,c,r,h,board,beat=fixture();m:SetEnabled(true);local conn=m.Connection
 if reason=='death'then h.Health=0 elseif reason=='respawn'then d.Character=newNode('Model')elseif reason=='seat'then h.SeatPart=newNode('Seat')elseif reason=='deleted'then board:Destroy()else d.Blocked=true end
 local cf=r.CFrame;beat:Fire(1/60)
 check(not m.Enabled and not m.Session and not conn.Connected and r.CFrame==cf,'Lock retained after '..reason);m:Dispose()
end
do local m,d,c,r,h=fixture();d.Part=nil;check(not m:SetEnabled(true)and not m.Connection,'No-part enable retained active state');d.Part=r;check(not m:SetEnabled(true),'Own avatar accepted as floor');m:Dispose()end
print('PASS: '..checks..' supplied underfoot magnet, rotation, cancellation and cleanup checks (mocked)')
