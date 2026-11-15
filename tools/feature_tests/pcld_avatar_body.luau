local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local oldIsA=Proxy.IsA
function Proxy:IsA(class)
 local c=self.ClassName
 return oldIsA(self,class)or class=='LuaSourceContainer'and(c=='LocalScript'or c=='Script'or c=='ModuleScript')
  or class=='JointInstance'and(c=='Motor6D'or c=='Weld')or class=='Constraint'and(c=='AlignPosition'or c=='VectorForce')or class=='BodyMover'and c=='BodyVelocity'or class=='ControllerBase'and c=='GroundController'
  or class=='Clothing'and(c=='Shirt'or c=='Pants')or class=='DataModelMesh'and c=='SpecialMesh'or class=='Accoutrement'and c=='Accessory'
end
function Proxy:Clone()
 if self.Archivable==false then return end
 local twins={}
 local function copy(source)
  local twin=newNode(source.ClassName,source.Name);twins[source]=twin
  for k,v in pairs(source._props)do if k~='Parent'and not(type(v)=='table'and v.Connections)then twin[k]=v end end
  for _,child in ipairs(source:GetChildren())do if child.Archivable~=false then copy(child).Parent=twin end end
  return twin
 end
 local root=copy(self)
 -- Roblox retargets cloned references within the subtree, retaining references
 -- outside it. This is exactly why external WeldConstraint.Part1 is dangerous.
 for _,twin in pairs(twins)do for k,v in pairs(twin._props)do if k~='Parent'and twins[v]then twin[k]=twins[v]end end end
 return root
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
 for _,side in ipairs({-1,1})do local arm=add(c,'Part',side<0 and'Left Arm'or'Right Arm');arm.Size=Vector3.new(1,2,1);joint(c,t,arm,CFrame.new(side*1.5,0,0))end
 for _,side in ipairs({-1,1})do local leg=add(c,'Part',side<0 and'Left Leg'or'Right Leg');leg.Size=Vector3.new(1,2,1);leg.CFrame=r.CFrame*CFrame.new(side*.5,-2,0);joint(c,t,leg,CFrame.new(side*.5,-1,0),CFrame.new(0,1,0))end
 local h=add(c,'Humanoid');h.Health=100;h.RootPart=r;h.WalkToPart=r
 local face=add(head,'Decal','face');face.Transparency=.2
 -- WeldConstraint inherits Instance, not Constraint or JointInstance. Clone
 -- retains external references: an anchored visual can otherwise weld a live root.
 local external=add(world,'Part','LiveExternal/'..name);external.Anchored=false
 local weld=add(t,'WeldConstraint','ExternalVisualWeld');weld.Part0=t;weld.Part1=external;weld.Enabled=true
 local object=add(c,'ObjectValue','LiveReference');object.Value=external
 local selection=add(c,'SelectionBox','InheritedSelection');selection.Adornee=external
 local force=add(t,'VectorForce','InheritedForce');force.Attachment0=add(r,'Attachment');force.Enabled=true
 add(c,'Shirt').ShirtTemplate='rbxassetid://original-clothing'
 local hat=add(c,'Accessory','Hat');local handle=add(hat,'Part','Handle');handle.CFrame=r.CFrame*CFrame.new(0,3,0);local mesh=add(handle,'SpecialMesh');mesh.MeshId='rbxassetid://original-mesh'
 local j=add(c,'Weld');j.Part0=head;j.Part1=handle;j.C0=CFrame.new(0,1.5,0);j.C1=CFrame.new()
 for _,kind in ipairs({'LocalScript','Script','ModuleScript','AlignPosition','BodyVelocity','RemoteEvent','Sound','Animator','ControllerManager','GroundController','ProximityPrompt'})do add(c,kind)end
 add(add(c,'Tool'),'Part','ToolHandle');local helper=add(c,'Part','AstralHelper');helper.Size=Vector3.new(100,100,100)
 local detector=add(world,'Part','PlayerCharacterLocationDetector');detector.CFrame=CFrame.new(x+100,8,-20)*CFrame.Angles(0,-.4,0);detector.Size=Vector3.new(2,10,2)
 return {Name=name,Character=c,Root=r,Humanoid=h,Detector=detector},head
end
local function fixture()
 local world=newNode('Folder','Workspace');local me=avatar(world,'Local',0);local other,head=avatar(world,'Other',10)
 local d={Enabled=true,Waiting=false,Players={me,other}};local beat,render=signal(),signal()
 local conf={FillColor=Color3.fromRGB(80,20,100),OutlineColor=Color3.fromRGB(230,50,130),FillTransparency=.6,OutlineTransparency=.1}
 local a=Avatars.Install({Workspace=world,RunService={Heartbeat=beat,RenderStepped=render},Player=me,ExternalRender=true,
  Players={GetPlayers=function()return d.Players end},Enabled=function()return d.Enabled end,
  Character=function(p)return p.Character,p.Character and p.Root,p.Character and p.Humanoid end,
  Detector=function(p)return p.Detector end,Waiting=function()return d.Waiting end,Frame=function(p)return d.Frame or p.CFrame end,Config=function()return conf end})
 return a,d,world,me,other,head,beat,render,conf
end
do
 local a,d,w,me,other,head,beat,render,conf=fixture();check(next(a.Records)==nil,'Box mode creates avatars');a:SetMode('Avatar')
 local r=a.Records[other];check(r and a.Records[me]and a:Has(me.Detector),'Local player omitted')
 check(me.Character.Archivable==false and other.Character.Archivable==false,'Archivable changed')
 for _,part in ipairs(r.Parts)do check(part.Part.Size==part.Source.Size,'A skin part/accessory differs from its source size')end
 local clone=r.Model;check(clone.Shirt.ShirtTemplate=='rbxassetid://original-clothing'and clone.Head.Color==head.Color,'Skin appearance lost')
 check(not clone:FindFirstChild('ExternalVisualWeld',true),'External WeldConstraint remains and can connect visual to live assembly')
 check(not clone:FindFirstChild('LiveReference',true)and not clone:FindFirstChild('InheritedSelection',true)and not clone:FindFirstChild('InheritedForce',true),'Clone retains external references or active inherited contents')
 check(other.Character.Torso.ExternalVisualWeld.Part1.Parent==w and other.Character.Torso.ExternalVisualWeld.Enabled,'Source external weld was modified')
 check(math.abs(clone.Torso.Transparency*clone.PCLDColors.FillTransparency-conf.FillTransparency)<1e-6 and clone.HumanoidRootPart.Transparency==1,'Visible clone skin is opaque instead of a ghost')
 check(math.abs(clone.Head.face.Transparency-(.2+.8*math.sqrt(conf.FillTransparency)))<1e-6,'Face decal stays opaque over ghost skin')
 for _,v in ipairs(clone:GetDescendants())do for key,value in pairs(v._props)do
  if key~='Parent'and type(value)=='table'and value._class then check(value==clone or value:IsDescendantOf(clone),'Clone retains a live external object reference in '..v.Name..'.'..key)end
 end end
 check(clone.Hat.Handle.SpecialMesh.MeshId=='rbxassetid://original-mesh','Accessory skin lost')
 check(not clone:FindFirstChild('AstralHelper'),'Helper geometry distorts silhouette size')
 check(r.Scale==1 and clone.Head.Size==head.Size,'Avatar was stretched to detector height')
 -- R6 body remains five studs tall, even with a ten-stud detector.
 local expected=other.Detector.CFrame*CFrame.new(0,2,0)
 check((clone.Head.Position-expected.Position).Magnitude<1e-6,'Avatar center/feet do not match box center and height')
 for _,v in ipairs(clone:GetDescendants())do
  check(not v:IsA('LuaSourceContainer')and not v:IsA('JointInstance')and not v:IsA('Constraint')and not v:IsA('BodyMover')and not v:IsA('Tool')and not v:IsA('RemoteEvent')and not v:IsA('ControllerManager')and not v:IsA('ControllerBase')and not v:IsA('ProximityPrompt'),'Cloned behavior remains')
  if v:IsA('BasePart')then check(v.Anchored and not v.CanCollide and not v.CanTouch and not v.CanQuery,'Clone affects physics')end
 end
 check(not a.RenderConnection and #render.Connections==0,'Avatar adds a second render-step/filter loop')
 check(clone.Humanoid.EvaluateStateMachine==false and clone.Humanoid.AutomaticScalingEnabled==false,'Cloned humanoid can simulate or resize the rig')
 for _,property in ipairs({'CanCollide','CanTouch','CanQuery'})do clone.Torso[property]=true;check(clone.Torso[property]==false,'Engine can re-enable '..property)end
 clone.Torso.Anchored=false;clone.Torso.Massless=false
 check(clone.Torso.Anchored and clone.Torso.Massless,'Visual copy acquires physical mass or becomes unanchored')
 clone.Humanoid.EvaluateStateMachine=true;check(clone.Humanoid.EvaluateStateMachine==false,'Humanoid collision/force controller re-enabled')
 local injected=add(clone.Torso,'WeldConstraint','InjectedVisualWeld');injected.Part0=clone.Torso;injected.Part1=other.Root
 check(not injected.Parent,'Engine-added physical content survives on visual clone')
 check(r.Highlight.FillColor==conf.FillColor and r.Highlight.OutlineColor==conf.OutlineColor,'Silhouette colors ignored')
 conf.FillTransparency=.85;a:Render()
 check(math.abs(clone.Torso.Transparency*clone.PCLDColors.FillTransparency-.85)<1e-6 and math.abs(clone.Head.face.Transparency-(.2+.8*math.sqrt(.85)))<1e-6,'Transparency settings do not update body and decals')
 check(head.Transparency==0 and head.face.Transparency==.2,'Ghost transparency changed live source appearance')
 head.face.Transparency=1;head.Transparency=1;a:Render()
 check(clone.Head.Transparency==1 and clone.Head.face.Transparency==1,'Originally hidden skin or decals became visible')
 head.face.Transparency=.2;head.Transparency=0
 conf.FillTransparency=0;a:Render()
 check(clone.Torso.Transparency==0 and clone.PCLDColors.FillTransparency==0,'User opacity=0 does not remain explicit')
 conf.FillTransparency=.6;a:Render()
 local pos=clone.Head.CFrame;local realRoot=other.Root.CFrame;local sensorFrame=other.Detector.CFrame
 head.CFrame=CFrame.new(900,900,900);other.Root.CFrame=CFrame.new(-300,-300,-300);render:Fire(1/60);a:Render()
 check((clone.Head.Position-pos.Position).Magnitude<1e-6,'Live ragdoll/desync pose moves stationary server PCLD')
 check(other.Detector.CFrame==sensorFrame and other.Root.Position==Vector3.new(-300,-300,-300),'Renderer moved live detector/avatar')
 other.Root.CFrame=realRoot;d.Frame=CFrame.new(-50,7,11);a:Render()
 check((clone.Head.Position-(d.Frame*CFrame.new(0,2,0)).Position).Magnitude<1e-6,'Native smoothed frame not used in the same update')
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
 me.Root=me.Character.AstralHelper;me.Humanoid.RootPart=me.Root;me.Root.CFrame=CFrame.new(700,300,-800)*CFrame.Angles(0,2,0)
 a:SetMode('Avatar');local selfCopy=a.Records[me];local r15=a.Records[other]
 check(selfCopy and selfCopy.Scale==1 and not selfCopy.Model:FindFirstChild('AstralHelper'),'Helper actor corrupts own PCLD geometry')
 check(r15 and r15.Model:FindFirstChild('UpperTorso')and r15.Model:FindFirstChild('LeftLowerLeg'),'R15 skin not rendered')
 check((selfCopy.Model.Head.Position-(me.Detector.CFrame*CFrame.new(0,2,0)).Position).Magnitude<1e-6,'Helper actor changes native PCLD orientation or position')
 a:Dispose()
end
do
 local a,d,w,me,other,head,beat,render=fixture();a:SetMode('Avatar')
 local visual=a.Records[other];local box=add(w,'Part','SmoothPCLD');box.CFrame=other.Detector.CFrame
 a.Context.Frame=function(part)return part==other.Detector and box.CFrame or part.CFrame end
 local now=0;local pending={};local record={Part=other.Detector,Clone=box,Moving=true,Motion=Motion.New(box.CFrame,now)}
 pending[record]=true;other.Detector.CFrame=box.CFrame*CFrame.new(10,0,0);now=.05;Motion.Sample(record.Motion,other.Detector.CFrame,now)
 local api={ESPMotion=Motion,PCLDAvatars=a,SetSmoothPCLDConnection=function()end}
 AttachNativeMotion(api,pending,function()return now end)
 for _=1,20 do
  now+=1/60;api.UpdateSmoothPCLD(1/60)
  local expected=box.CFrame*CFrame.new(0,2,0)
  check((visual.Model.Head.Position-expected.Position).Magnitude<1e-6,'Avatar uses another motion sample/filter than native Box PCLD')
  check((visual.Model.Head.CFrame.LookVector-expected.LookVector).Magnitude<1e-6,'Avatar orientation differs from the native PCLD frame')
 end
 local fixed=visual.Model.Head.Position;render:Fire(1/60)
 check((visual.Model.Head.Position-fixed).Magnitude==0,'Independent render callback moves avatar outside native PCLD update')
 a:Dispose()
end
print('PASS: '..checks..' 1:1 PCLD size, inert humanoid/collision guards, external-weld stripping, ghost skin/decals, same-frame native motion and lifecycle checks (mocked)')
