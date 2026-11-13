local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local oldIsA=Proxy.IsA
function Proxy:IsA(class)
 local c=self.ClassName
 return oldIsA(self,class)or class=='LuaSourceContainer'and(c=='LocalScript'or c=='Script'or c=='ModuleScript')
  or class=='JointInstance'and(c=='Motor6D'or c=='Weld')or class=='Constraint'and c=='AlignPosition'
  or class=='BodyMover'and c=='BodyVelocity'
end
function Proxy:Clone()
 if self.Archivable==false then return end
 local copy=newNode(self.ClassName,self.Name)
 for k,v in pairs(self._props)do
  if k~='Parent'and not(type(v)=='table'and v.Connections)then copy[k]=v end
 end
 for _,child in ipairs(self:GetChildren())do local c=child:Clone();if c then c.Parent=copy end end
 return copy
end
local function fixture()
 local world=newNode('Folder','Workspace');local char=newNode('Model','Other');char.Parent=world;char.Archivable=false
 local root=newNode('Part','HumanoidRootPart');root.Parent=char;root.CFrame=CFrame.new(4,3,2)*CFrame.Angles(0,.7,0)
 local head=newNode('MeshPart','Head');head.Parent=char;head.CFrame=root.CFrame*CFrame.new(0,2,0);head.Color=Color3.fromRGB(200,150,100)
 local hum=newNode('Humanoid');hum.Parent=char;hum.Health=100
 local shirt=newNode('Shirt');shirt.ShirtTemplate='rbxassetid://original-clothing';shirt.Parent=char
 local hat=newNode('Accessory','Hat');hat.Parent=char;local handle=newNode('Part','Handle');handle.CFrame=root.CFrame*CFrame.new(1,3,0);handle.Parent=hat
 local mesh=newNode('SpecialMesh');mesh.MeshId='rbxassetid://original-mesh';mesh.Parent=handle
 for _,kind in ipairs({'LocalScript','Script','ModuleScript','Motor6D','AlignPosition','BodyVelocity','RemoteEvent','Sound','Animator'})do newNode(kind).Parent=char end
 local tool=newNode('Tool');tool.Parent=char;newNode('Part','ToolHandle').Parent=tool
 local detector=newNode('Part','PlayerCharacterLocationDetector');detector.CFrame=CFrame.new(100,8,-20)*CFrame.Angles(0,-.4,0);detector.Parent=char
 local other={Name='Other',Character=char};local localPlayer={Name='Local'};local d={Enabled=true,Waiting=false,Players={localPlayer,other}}
 local beat,render=signal(),signal();local conf={FillColor=Color3.fromRGB(80,20,100),OutlineColor=Color3.fromRGB(230,50,130),FillTransparency=.6,OutlineTransparency=.1}
 local a=Avatars.Install({Workspace=world,RunService={Heartbeat=beat,RenderStepped=render},Player=localPlayer,
  Players={GetPlayers=function()return d.Players end},Enabled=function()return d.Enabled end,
  Character=function(p)return p.Character,p.Character and p.Character:FindFirstChild('HumanoidRootPart'),p.Character and p.Character:FindFirstChildOfClass('Humanoid')end,
  Detector=function()return detector end,Waiting=function()return d.Waiting end,Frame=function(p)return d.Frame or p.CFrame end,Config=function()return conf end})
 return a,d,world,char,root,head,hum,detector,other,beat,render,conf
end
do
 local a,d,w,c,r,head,h,p,other,beat,render,conf=fixture()
 check(next(a.Records)==nil,'Box mode created avatar copies');a:SetMode('Avatar');render:Fire(1/60)
 local record=a.Records[other];check(record and c.Archivable==false,'Avatar clone unavailable or Archivable not restored')
 local clone=record.Model;check(clone.Parent==a.Container and clone:FindFirstChildOfClass('Shirt').ShirtTemplate=='rbxassetid://original-clothing','Skin clothing lost')
 local hc=clone:FindFirstChild('Head');check(hc.Color==head.Color,'Skin colors lost')
 check(clone:FindFirstChild('Hat').Handle.SpecialMesh.MeshId=='rbxassetid://original-mesh','Accessory mesh lost')
 check((hc.Position-(p.CFrame*r.CFrame:Inverse()*head.CFrame).Position).Magnitude<1e-6,'Avatar is not at actual replicated PCLD frame')
 for _,v in ipairs(clone:GetDescendants())do
  check(not v:IsA('LuaSourceContainer')and not v:IsA('JointInstance')and not v:IsA('Constraint')and not v:IsA('BodyMover')and not v:IsA('Tool')and not v:IsA('RemoteEvent'),'Unsafe cloned behavior retained')
  if v:IsA('BasePart')then check(v.Anchored and not v.CanCollide and not v.CanTouch and not v.CanQuery,'Clone can affect physics')end
 end
 check(not clone:FindFirstChild('PlayerCharacterLocationDetector'),'Clone contains another PCLD')
 check(record.Highlight.FillColor==conf.FillColor and record.Highlight.OutlineColor==conf.OutlineColor,'Independent silhouette colors ignored')
 local original=r.CFrame;local detectorOriginal=p.CFrame;local v=r.AssemblyLinearVelocity
 d.Frame=CFrame.new(-50,7,11);head.CFrame=r.CFrame*CFrame.new(0,3,1);render:Fire(1/60)
 check((hc.Position-(d.Frame*r.CFrame:Inverse()*head.CFrame).Position).Magnitude<1e-6,'Smoothing/live pose not followed')
 check(r.CFrame==original and p.CFrame==detectorOriginal and r.AssemblyLinearVelocity==v and not r.Anchored and r.CanCollide,'Avatar rendering modified live physics')
 local hat=newNode('Accessory','NewHat');hat.Parent=c;newNode('Part','Handle').Parent=hat;beat:Fire(.2)
 check(a.Records[other].Model~=clone and not clone.Parent,'Skin changes did not rebuild/clean old copy')
 d.Waiting=true;render:Fire(1/60);check(not a.Records[other],'Waiting PCLD remained visible')
 d.Waiting=false;beat:Fire(.2);check(a.Records[other]~=nil,'Ready PCLD failed to return')
 other.Character=nil;beat:Fire(.2);check(next(a.Records)==nil,'Respawn left a ghost avatar')
 a:Dispose();check(not beat.Connections[1].Connected and not a.Container.Parent,'Avatar listeners/container leaked')
end
do
 local a,d,w,c,r,head,h,p,other,beat,render=fixture();a:SetMode('Avatar');local model=a.Records[other].Model
 a:SetMode('Box');check(next(a.Records)==nil and not model.Parent and not a.RenderConnection,'Mode switch retained avatars/render callback')
 a:SetMode('Avatar');d.Enabled=false;render:Fire(1/60);check(next(a.Records)==nil and not a.RenderConnection,'ESP disable retained copies')
 a:Dispose();check(not a:SetMode('Nonsense'),'Invalid PCLD style accepted')
end
print('PASS: '..checks..' actual PCLD avatar, skin, colors, physics isolation and lifecycle checks (mocked)')
