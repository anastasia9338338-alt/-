local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function character(world)
 local c=newNode('Model','Avatar');c.Parent=world
 local root=newNode('Part','HumanoidRootPart');root.Size=Vector3.new(2,2,1);root.CFrame=CFrame.new(0,3,0);root.Parent=c
 local leg=newNode('Part','Left Leg');leg.Size=Vector3.new(1,2,1);leg.Parent=c
 local h=newNode('Humanoid','Humanoid');h.Health=100;h.HipHeight=2;h.State=Enum.HumanoidStateType.Running;h.States={};h.Parent=c
 function h:GetState()return self.State end;function h:ChangeState(v)self.State=v end
 function h:GetStateEnabled(k)return self.States[k]~=false end;function h:SetStateEnabled(k,v)self.States[k]=v end
 return c,root,h
end
do
 local world=newNode('Workspace','World');local c,r,h=character(world);local blob=newNode('Model','CreatureBlobman');blob.Parent=world
 local script=newNode('Folder','BlobmanSeatAndOwnerScript');script.Parent=blob
 local calls={};local drop=newNode('RemoteEvent','CreatureDrop');drop.Parent=script
 function drop:FireServer(...)check(select('#',...)==1,'Drop remote had extra arguments');calls[#calls+1]={...}end
 local det=newNode('Part','LeftDetector');det.CFrame=CFrame.new(10,3,0);det.Parent=blob
 local weld=newNode('WeldConstraint','LeftWeld');weld.Changed=signal();weld.Parent=det
 local now=0;local enabled=true;local pre=signal()
 local aura=Aura.Install({RunService={PreSimulation=pre},Clock=function()return now end,Enabled=function()return enabled end,Models=function()return{blob}end,Character=function()return c,r,h end})
 aura:Refresh();check(aura:IsNear()and not det.CanTouch,'Near detector was not suppressed')
 local original=r.CFrame;weld.Part1=r;weld.Changed:Fire('Part1')
 check(not weld.Enabled and #calls==1 and calls[1][1]==weld,'Immediate self-grab was not dropped with native protocol')
 for _=1,240 do now+=1/240;aura:Refresh()end
 check(#calls<=11 and r.CFrame==original,'Aura flooded requests or teleported the player')
 local other=newNode('Model','Other');other.Parent=world;local target=newNode('Part','Root');target.Parent=other
 weld.Part1=target;weld.Changed:Fire('Part1');check(weld.Enabled,'Aura disabled another player grab')
 local before=#calls;aura:Refresh();check(#calls==before,'Aura dropped another player')
 local seat=newNode('Seat','VehicleSeat');seat.Parent=blob;h.SeatPart=seat;aura:Refresh()
 check(det.CanTouch and not aura:IsNear(),'Aura interfered with the Blobman being driven by the local player')
 h.SeatPart=nil;aura:Refresh();check(aura:IsNear()and not det.CanTouch,'Leaving own seat did not reactivate protection')
 local old=c;c,r,h=character(world);aura:Refresh()
 for _,v in ipairs(old:GetDescendants())do check(not v:IsA('NoCollisionConstraint'),'Respawn retained old avatar constraints')end
 det.CFrame=CFrame.new(90,3,0);aura:Refresh();check(det.CanTouch and not aura:IsNear(),'Leaving radius did not restore touch')
 for _,v in ipairs(c:GetDescendants())do check(not v:IsA('NoCollisionConstraint'),'Aura leaked a collision constraint')end
 aura:Dispose();check(not pre.Connections[1].Connected,'Aura leaked its physics callback')
end
do
 local world=newNode('Workspace','World');local c,r,h=character(world);local pre=signal();local surface=Vector3.new(0,0,0);local blocked=false
 local walk=Walk.Install({RunService={PreSimulation=pre},Workspace=world,Character=function()return c,r,h end,Surface=function()return surface end,Blocked=function()return blocked end})
 local original=r.CFrame;walk:SetEnabled(true)
 check(walk.Part and walk.Part.Position.Y==-.25 and walk.Part.CanCollide,'Water support top is not at the detected surface')
 check(r.CFrame==original and not h:GetStateEnabled(Enum.HumanoidStateType.Swimming),'Water walk changed the character transform or allowed swimming')
 surface=Vector3.new(0,.15,0);walk:Refresh();check(walk.Part.Position.Y==-.25,'Water waves caused support-height jitter')
 walk.Part:Destroy();walk:Refresh();check(walk.Part and walk.Part.Parent==world and not h:GetStateEnabled(Enum.HumanoidStateType.Swimming),'Destroyed support was not safely recreated')
 local supportY=walk.Part.Position.Y
 r.CFrame=CFrame.new(12,3,0);walk:Refresh();check(walk.Part.Position.X==12 and walk.Part.Position.Y==supportY,'Horizontal support recenter changed height')
 blocked=true;walk:Refresh();check(not walk.Part and h:GetStateEnabled(Enum.HumanoidStateType.Swimming),'Blocked/flight cleanup did not restore swimming')
 blocked=false;surface=Vector3.new(0,0,0);r.CFrame=CFrame.new(0,-2,0);walk:Refresh();check(not walk.Part,'Submerged player was lifted onto the water')
 r.CFrame=CFrame.new(0,3,0);walk:Refresh();surface=nil;walk:Refresh();check(not walk.Part,'Leaving water retained invisible land support')
 walk:Dispose();check(not pre.Connections[1].Connected,'Water walk leaked physics callback')
end
print('PASS: '..checks..' Blobman self-only protection, drop cadence, water support and cleanup checks (mocked)')
