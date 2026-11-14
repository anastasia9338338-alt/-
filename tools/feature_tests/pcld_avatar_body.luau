local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local oldIsA=Proxy.IsA
function Proxy:IsA(class)
 local c=self.ClassName
 return oldIsA(self,class)or class=='LuaSourceContainer'and(c=='LocalScript'or c=='Script'or c=='ModuleScript')
  or class=='JointInstance'and(c=='Motor6D'or c=='Weld')or class=='Constraint'and c=='AlignPosition'or class=='BodyMover'and c=='BodyVelocity'
end
function Proxy:Clone()
 if self.Archivable==false then return end
 local copy=newNode(self.ClassName,self.Name)
 for k,v in pairs(self._props)do if k~='Parent'and not(type(v)=='table'and v.Connections)then copy[k]=v end end
 for _,child in ipairs(self:GetChildren())do local c=child:Clone();if c then c.Parent=copy end end
 return copy
end
function Proxy:GetScale()return self._scale or 1 end
function Proxy:ScaleTo(value)
 local ratio=value/self:GetScale();self._scale=value
 for _,p in ipairs(self:GetDescendants())do if p:IsA('BasePart')then p.Size=p.Size*ratio end end
end
local function add(parent,class,name)local n=newNode(class,name);n.Parent=parent;return n end
local function joint(c,a,b,cf0,cf1)
 local j=add(c,'Motor6D');j.Part0=a;j.Part1=b;j.C0=cf0 or CFrame.new();j.C1=cf1 or CFrame.new();return j
end
local function avatar(world,name,x)
 local c=add(world,'Model',name);c.Archivable=false
 local r=add(c,'Part','HumanoidRootPart');r.CFrame=CFrame.new(x,3,0)*CFrame.Angles(0,.7,0);r.Transparency=1
 local t=add(c,'Part','Torso');t.Size=Vector3.new(2,2,1);t.CFrame=r.CFrame;joint(c,r,t)
 local head=add(c,'MeshPart','Head');head.Size=Vector3.new(2,1,1);head.CFrame=r.CFrame*CFrame.new(0,1.5,0);head.Color=Color3.fromRGB(220,130,70)
 joint(c,t,head,CFrame.new(0,1,0),CFrame.new(0,-.5,0))
 for _,side in ipairs({-1,1})do local leg=add(c,'Part',side<0 and'Left Leg'or'Right Leg');leg.Size=Vector3.new(1,2,1);leg.CFrame=r.CFrame*CFrame.new(side*.5,-2,0);joint(c,t,leg,CFrame.new(side*.5,-1,0),CFrame.new(0,1,0))end
 local h=add(c,'Humanoid');h.Health=100;h.RootPart=r
 add(c,'Shirt').ShirtTemplate='rbxassetid://original-clothing'
 local hat=add(c,'Accessory','Hat');local handle=add(hat,'Part','Handle');handle.CFrame=r.CFrame*CFrame.new(0,3,0);local mesh=add(handle,'SpecialMesh');mesh.MeshId='rbxassetid://original-mesh'
 local j=add(c,'Weld');j.Part0=head;j.Part1=handle;j.C0=CFrame.new(0,1.5,0);j.C1=CFrame.new()
 for _,kind in ipairs({'LocalScript','Script','ModuleScript','AlignPosition','BodyVelocity','RemoteEvent','Sound','Animator'})do add(c,kind)end
 add(add(c,'Tool'),'Part','ToolHandle');local helper=add(c,'Part','AstralHelper');helper.Size=Vector3.new(100,100,100)
 local detector=add(world,'Part','PlayerCharacterLocationDetector');detector.CFrame=CFrame.new(x+100,8,-20)*CFrame.Angles(0,-.4,0);detector.Size=Vector3.new(2,10,2)
 return {Name=name,Character=c,Root=r,Humanoid=h,Detector=detector},head
end
local function fixture()
 local world=newNode('Folder','Workspace');local me=avatar(world,'Local',0);local other,head=avatar(world,'Other',10)
 local d={Enabled=true,Waiting=false,Players={me,other}};local beat,render=signal(),signal()
 local conf={FillColor=Color3.fromRGB(80,20,100),OutlineColor=Color3.fromRGB(230,50,130),FillTransparency=.6,OutlineTransparency=.1}
 local a=Avatars.Install({Workspace=world,RunService={Heartbeat=beat,RenderStepped=render},Player=me,
  Players={GetPlayers=function()return d.Players end},Enabled=function()return d.Enabled end,
  Character=function(p)return p.Character,p.Character and p.Root,p.Character and p.Humanoid end,
  Detector=function(p)return p.Detector end,Waiting=function()return d.Waiting end,Frame=function(p)return d.Frame or p.CFrame end,Config=function()return conf end})
 return a,d,world,me,other,head,beat,render,conf
end
do
 local a,d,w,me,other,head,beat,render,conf=fixture();check(next(a.Records)==nil,'Box mode creates avatars');a:SetMode('Avatar')
 local r=a.Records[other];check(r and a.Records[me]and a:Has(me.Detector),'Local player omitted')
 check(me.Character.Archivable==false and other.Character.Archivable==false,'Archivable changed')
 local clone=r.Model;check(clone.Shirt.ShirtTemplate=='rbxassetid://original-clothing'and clone.Head.Color==head.Color,'Skin appearance lost')
 check(clone.Hat.Handle.SpecialMesh.MeshId=='rbxassetid://original-mesh','Accessory skin lost')
 check(not clone:FindFirstChild('AstralHelper'),'Helper geometry distorts silhouette size')
 check(math.abs(r.Scale-2)<1e-6 and clone.Head.Size==head.Size*2,'Detector height does not normalize actual avatar size')
 -- R6 rest extent [-3,2] is centered before matching the detector's height.
 local expected=other.Detector.CFrame*CFrame.new(0,4,0)
 check((clone.Head.Position-expected.Position).Magnitude<1e-6,'Avatar center/feet do not match box center and height')
 for _,v in ipairs(clone:GetDescendants())do
  check(not v:IsA('LuaSourceContainer')and not v:IsA('JointInstance')and not v:IsA('Constraint')and not v:IsA('BodyMover')and not v:IsA('Tool')and not v:IsA('RemoteEvent'),'Cloned behavior remains')
  if v:IsA('BasePart')then check(v.Anchored and not v.CanCollide and not v.CanTouch and not v.CanQuery,'Clone affects physics')end
 end
 check(r.Highlight.FillColor==conf.FillColor and r.Highlight.OutlineColor==conf.OutlineColor,'Silhouette colors ignored')
 local pos=clone.Head.CFrame;local realRoot=other.Root.CFrame;local sensorFrame=other.Detector.CFrame
 head.CFrame=CFrame.new(900,900,900);other.Root.CFrame=CFrame.new(-300,-300,-300);render:Fire(1/60)
 check((clone.Head.Position-pos.Position).Magnitude<1e-6,'Live ragdoll/desync pose moves stationary server PCLD')
 check(other.Detector.CFrame==sensorFrame and other.Root.Position==Vector3.new(-300,-300,-300),'Renderer moved live detector/avatar')
 other.Root.CFrame=realRoot;d.Frame=CFrame.new(-50,7,11);a:Render()
 check((clone.Head.Position-(d.Frame*CFrame.new(0,4,0)).Position).Magnitude<1e-6,'Native smoothed frame not used in the same update')
 other.Detector.Size=Vector3.new(2,5,1);a:Render();check(math.abs(r.Scale-1)<1e-6 and clone.Head.Size==head.Size,'Detector size change compounds scale or is ignored')
 local hat=add(other.Character,'Accessory','NewHat');add(hat,'Part','Handle');beat:Fire(.2)
 check(a.Records[other].Model~=clone and not clone.Parent,'Appearance refresh leaks old clone')
 d.Waiting=true;a:Render();check(next(a.Records)==nil and not a:Has(other.Detector),'Waiting detector still renders')
 d.Waiting=false;beat:Fire(.2);check(a.Records[me]and a.Records[other],'Ready detectors do not return')
 other.Character=nil;beat:Fire(.2);check(not a.Records[other]and a.Records[me],'Respawn leaves ghost or removes other player')
 a:SetMode('Box');check(next(a.Records)==nil and not a.RenderConnection,'Mode switch leaks copy/callback');a:Dispose()
 check(not beat.Connections[1].Connected and not a.Container.Parent,'Avatar dispose leaks')
end
do
 local a,d,w,me,other,head,beat=fixture()
 for i=1,8 do table.insert(d.Players,(avatar(w,'Additional'..i,20+i*10)))end
 a:SetMode('Avatar');for _=1,6 do beat:Fire(.2)end
 local count=0;for _ in pairs(a.Records)do count+=1 end
 check(count==10,'Build budget permanently omits players')
 d.Enabled=false;a:Render();check(next(a.Records)==nil,'Disabled ESP leaks copies');a:Dispose()
end
do
 local a,d,w,me,other,head,beat=fixture()
 -- Native R15 upper/lower torso joints, scaled to this detector height.
 other.Character.Torso.Name='UpperTorso'
 local lower=add(other.Character,'MeshPart','LowerTorso');lower.Size=Vector3.new(2,1,1);joint(other.Character,other.Humanoid.RootPart,lower,CFrame.new(0,-1.5,0))
 other.Character['Left Leg'].Name='LeftLowerLeg';other.Character['Right Leg'].Name='RightLowerLeg'
 -- A desync control can return a helper actor instead of the skeleton root.
 me.Root=me.Character.AstralHelper;me.Root.CFrame=CFrame.new(700,300,-800)*CFrame.Angles(0,2,0)
 a:SetMode('Avatar');local selfCopy=a.Records[me];local r15=a.Records[other]
 check(selfCopy and selfCopy.Scale==2 and not selfCopy.Model:FindFirstChild('AstralHelper'),'Helper actor corrupts own PCLD geometry')
 check(r15 and r15.Model:FindFirstChild('UpperTorso')and r15.Model:FindFirstChild('LeftLowerLeg'),'R15 skin not rendered')
 check((selfCopy.Model.Head.Position-(me.Detector.CFrame*CFrame.new(0,4,0)).Position).Magnitude<1e-6,'Helper actor changes native PCLD orientation or position')
 a:Dispose()
end
print('PASS: '..checks..' native PCLD size, rest pose, self/all players, skin and lifecycle checks (mocked)')
