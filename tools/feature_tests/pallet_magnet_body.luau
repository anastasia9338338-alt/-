local checks=0;local function check(v,m)assert(v,m);checks+=1 end
function Proxy:GetConnectedParts()return self._connected or{}end
local function fixture(owned)
 local world=newNode('Folder');local c=newNode('Model');c.Parent=world;local r=newNode('Part');r.Size=Vector3.new(2,2,1);r.CFrame=CFrame.new(0,3.2,0);r.Parent=c
 local leg=newNode('Part','Left Leg');leg.Size=Vector3.new(1,2,1);leg.Parent=c
 local h={Health=100,HipHeight=0,State=Enum.HumanoidStateType.Running};function h:GetState()return self.State end
 local model=newNode('Model','PalletLightBrown');model.Parent=world;local root=newNode('Part','Main');root.Size=Vector3.new(8,.4,6);root.Parent=model;root.AssemblyMass=60
 local d={Now=0,Owned=owned~=false,Queue={},Reserved=nil};local pre=signal()
 local ctx={RunService={PreSimulation=pre},Clock=function()return d.Now end,Character=function()return c,r,h end,Owned=function()return d.Owned end,
  UnderFeet=function()return root,Vector3.new(0,.2,0),Vector3.yAxis end,Blocked=function()return d.Blocked end,
  SpawnThread=function(fn)d.Queue[#d.Queue+1]=fn end,Acquire=function(p,valid)if valid()then d.Owned=true end end,
  Reserved=function()return d.Reserved end,Reserve=function(_,v)d.Reserved=v end}
 return Magnet.Install(ctx),d,ctx,c,r,h,model,root,pre
end
do
 local m,d,ctx,c,r,h,model,root,pre=fixture();local original=r.CFrame;m:SetEnabled(true);m:Step(1/60)
 check(m.Session and d.Reserved and not root.CanTouch,'Pallet was not attached/reserved')
 check(m.Session.Position.MaxForce.Y>0 and m.Session.Position.MaxForce.Y<math.huge,'Pallet force invalid')
 r.CFrame=CFrame.new(4,3.2,-2);original=r.CFrame;m:Step(1/60)
 check(math.abs(m.Session.Position.Position.X-4)<.001 and math.abs(m.Session.Position.Position.Z+2)<.001,'Board did not follow feet')
 for _=1,100 do m:Step(1/60);check(r.CFrame==original and r.AssemblyLinearVelocity==Vector3.zero,'Magnet wrote avatar transform/velocity')end
 h.State=Enum.HumanoidStateType.Jumping;r.CFrame=CFrame.new(4,5,-2);m:Step(1/60)
 check(m.Session.Height>1.5,'Genuine jump did not move attached board')
 d.Owned=false;m:Step(1/60);check(not m.Session and root.CanTouch and not d.Reserved,'Ownership loss retained magnet')
 m:Dispose();check(not pre.Connections[1].Connected,'Magnet callback leaked')
end
do
 local m,d,ctx,c,r,h,model,root=fixture(false);m:SetEnabled(true);m:Step(1/60)
 check(not m.Session and #d.Queue==1,'Unowned board moved before acquisition')
 m:SetEnabled(false);d.Queue[1]();check(not d.Owned and not m.Session,'Canceled acquisition acted on board');m:Dispose()
end
do
 local m,d,ctx,c,r,h,model,root=fixture();local other=newNode('Part');other.Parent=c;root._connected={other}
 m:SetEnabled(true);m:Step(1/60);check(not m.Session,'Avatar-connected board accepted');root._connected={};model.Name='RagdollRSC';m:Step(1/60)
 check(not m.Session,'Native kick pallet was captured');m:Dispose()
end
do
 local m,d,ctx,c,r,h,model,root=fixture();model.Name='PalletPlayer';newNode('Humanoid').Parent=model
 m:SetEnabled(true);m:Step(1/60);check(not m.Session,'Player avatar with pallet in its name was captured');m:Dispose()
end
print('PASS: '..checks..' pallet feet target, ownership, native movement and cleanup checks (mocked)')
