local originalTypeof=typeof
typeof=function(v)if getmetatable(v)==Proxy then return "Instance"end;return originalTypeof(v)end
local checks=0
local function check(v,m)assert(v,m);checks+=1 end
local originalIsA=Proxy.IsA
function Proxy:IsA(class)
 if class=='LuaSourceContainer'then return self.ClassName=='Script'or self.ClassName=='LocalScript'or self.ClassName=='ModuleScript'end
 if class=='BodyMover'then return self.ClassName=='BodyPosition'or self.ClassName=='BodyVelocity'end
 if class=='Constraint'then return self.ClassName=='WeldConstraint'or self.ClassName=='AlignPosition'end
 return originalIsA(self,class)
end
local function sf(cf,scale)return cf.Rotation+cf.Position*scale end
local originalPivot=Proxy.GetPivot
function Proxy:GetPivot()if self.ClassName=='Model'and self.PrimaryPart then return self.PrimaryPart.CFrame end;return originalPivot(self)end
function Proxy:ScaleTo(scale)
 local factor=scale/(self._modelScale or 1);local pivot=self:GetPivot()
 for _,v in ipairs(self:GetDescendants())do
  if v:IsA('BasePart')then v.CFrame=pivot*sf(pivot:ToObjectSpace(v.CFrame),factor);v.Size=v.Size*factor
  elseif v:IsA('Motor6D')or v:IsA('Weld')then v.C0=sf(v.C0,factor);v.C1=sf(v.C1,factor)
  elseif v:IsA('Bone')then v.CFrame=sf(v.CFrame,factor)
  elseif v:IsA('SpecialMesh')then v.Scale=v.Scale*factor;v.Offset=v.Offset*factor end
 end
 self._modelScale=scale
end
local oldDestroy=Proxy.Destroy
function Proxy:Destroy()
 if self.ClassName=='Sound'then check(self.PlayOnRemove==false and self.Volume==0 and self.Stopped==true,'Sound destruction happened before neutralization')end
 self.Destroyed=true;oldDestroy(self)
end
local function fixture()
 local world=newNode('Workspace','World')
 local original=newNode('Part','OriginalAvatarRoot');original.Anchored=false;original.CanCollide=true;original.Parent=world
 local asset=newNode('Model','TungSource')
 local function part(name,pos,size,visible)
  local p=newNode('Part',name);p.CFrame=CFrame.new(pos);p.Size=size;p.Transparency=visible==false and 1 or 0;p.Parent=asset;return p
 end
 local root=part('HumanoidRootPart',Vector3.new(0,3,0),Vector3.new(100,100,100),false)
 local torso=part('Torso',Vector3.new(0,3,0),Vector3.new(2,2,1))
 local head=part('Head',Vector3.new(0,4.5,0),Vector3.new(2,1,1))
 local left=part('Left Leg',Vector3.new(-.5,1,0),Vector3.new(1,2,1))
 local right=part('Right Leg',Vector3.new(.5,1,0),Vector3.new(1,2,1))
 asset.PrimaryPart=root
 local function joint(name,a,b,c0,c1)
  local j=newNode('Motor6D',name);j.Part0=a;j.Part1=b;j.C0=c0;j.C1=c1;j.Transform=CFrame.new();j.Parent=a;return j
 end
 joint('RootJoint',root,torso,CFrame.new(),CFrame.new())
 joint('Neck',torso,head,CFrame.new(0,1.5,0),CFrame.new())
 joint('Left Hip',torso,left,CFrame.new(-.5,-1,0)*CFrame.Angles(0,-math.pi/2,0),CFrame.new(0,1,0)*CFrame.Angles(0,-math.pi/2,0))
 joint('Right Hip',torso,right,CFrame.new(.5,-1,0)*CFrame.Angles(0,math.pi/2,0),CFrame.new(0,1,0)*CFrame.Angles(0,math.pi/2,0))
 local weld=newNode('WeldConstraint','External');weld.Part0=left;weld.Part1=original;weld.Parent=left
 local script=newNode('Script','Untrusted');script.Parent=asset
 local sound=newNode('Sound','RemovalSound');sound.PlayOnRemove=true;sound.Volume=1;sound.Stop=function(self)self.Stopped=true end;sound.Parent=script
 local emitter=newNode('ParticleEmitter','Payload');emitter.Enabled=true;emitter.Clear=function(self)self.Cleared=true end;emitter.Parent=torso
 local remote=newNode('RemoteEvent','Payload');remote.Parent=asset
 local humanoid=newNode('Humanoid','Humanoid');humanoid.Parent=asset
 local data={Valid=true,Preloaded=false}
 local context={Workspace=world,LoadAsset=function(id)check(id==123969132800771,'Wrong model asset requested');return{asset}end,
  Preload=function(objects,valid)
   check(objects[1].Parent==nil,'Imported model parented before preload completed')
   for _,v in ipairs(objects[1]:GetDescendants())do check(not v:IsA('LuaSourceContainer')and not v:IsA('RemoteEvent')and not v:IsA('Sound'),'Active content remained before parenting')end
   check(valid(),'Preload received invalid request');data.Preloaded=true
  end}
 local function valid()return data.Valid end
 return{World=world,Original=original,Asset=asset,Root=root,Torso=torso,Left=left,Right=right,Sound=sound,Emitter=emitter,Context=context,Data=data,Valid=valid}
end
do
 local f=fixture();local renderer=Sahur.Build(f.Context,f.Valid,function()end)
 check(f.Data.Preloaded and renderer.Model.Parent==f.World,'Exact-asset renderer did not initialize')
 check(renderer.BaseScale>1,'Invisible root collider incorrectly controlled visible model height')
 check(f.Sound.Destroyed and f.Emitter.Destroyed and f.Emitter.Emitted==0,'Imported effects were not removed')
 check(f.Original.Parent==f.World and not f.Original.Anchored and f.Original.CanCollide,'Original avatar physics changed')
 for _,record in ipairs(renderer.Parts)do
  local p=record.Part
  check(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery and p.Massless and not p.CastShadow,'Cosmetic part has physical/query side effects')
  check(p.LocalTransparencyModifier==1,'Unpositioned imported model flashed onscreen')
 end
 check(renderer:Render(renderer:Sample('walk',.25),CFrame.new(10,0,20),false),'Model did not render')
 check(f.Torso.LocalTransparencyModifier==0,'Positioned model remained hidden')
 local leftRotation=f.Left.CFrame.UpVector;local rightRotation=f.Right.CFrame.UpVector
 check((leftRotation-rightRotation).Magnitude>.1,'Internal joints were not procedurally animated')
 check(math.abs(leftRotation.X)<1e-6 and math.abs(rightRotation.X)<1e-6,'R6 hip basis rotated forward walking into sideways leg swings')
 renderer:SetScale(1.3);renderer:Render(renderer:Sample('idle',.2),CFrame.new(),false)
 check(math.abs(renderer.Model._modelScale-renderer.BaseScale*1.3)<1e-6,'Model scale did not update native meshes/bones')
 renderer:Render(renderer:Sample('sit',0),CFrame.new(),true)
 check(f.Torso.LocalTransparencyModifier==1,'First-person hide did not apply')
 f.Torso:Destroy();f.Left:Destroy();f.Right:Destroy();for _,r in ipairs(renderer.Parts)do if r.Visible and r.Part.Parent then r.Part:Destroy()end end
 check(not renderer:IsReady(),'An invisible surviving root was considered a ready model')
 renderer:Dispose();renderer:Dispose();check(renderer.Model.Parent==nil,'Dispose leaked imported model')
end
do
 local f=fixture();f.Context.LoadAsset=function()f.Data.Valid=false;return{f.Asset}end
 local ok=pcall(Sahur.Build,f.Context,f.Valid,function()end)
 check(not ok and f.Asset.Destroyed and f.Sound.Destroyed,'Cancellation after a yielding loader leaked the returned asset')
 check(#f.World:GetChildren()==1,'Cancelled asset was parented or leaked into Workspace')
end
do
 local f=fixture();f.Context.LoadAsset=function()return{f.Original}end
 local ok=pcall(Sahur.Build,f.Context,f.Valid,function()end)
 check(not ok and not f.Original.Destroyed and f.Original.Parent==f.World,'Invalid loader could destroy an existing world instance')
end
do
 local f=fixture();for i=1,193 do local p=newNode('Part','TooMany');p.Parent=f.Asset end
 local ok=pcall(Sahur.Build,f.Context,f.Valid,function()end)
 check(not ok and f.Asset.Destroyed,'Oversized asset exceeded retained part budget')
end
-- Controller visibility and cancellation are independent from actual Roblox asset availability.
local function localFixture()
 local world=newNode('Workspace','World');local character=newNode('Model','Avatar');character.Parent=world
 local root=newNode('Part','HumanoidRootPart');root.Size=Vector3.new(2,2,1);root.AssemblyLinearVelocity=Vector3.zero;root.Parent=character
 local leg=newNode('Part','Left Leg');leg.Size=Vector3.new(1,2,1);leg.Parent=character
 local head=newNode('Part','Head');head.Parent=character
 local h=newNode('Humanoid','Humanoid');h.Health=100;h.HipHeight=2;h.MoveDirection=Vector3.zero;h.GetState=function()return Enum.HumanoidStateType.Running end;h.Parent=character
 local d={RenderResult=true,Ready=true,Disposed=0,Builds=0,Queue={}}
 local renderer={Sample=function()return{}end,Blend=function()return{}end,SetScale=function()end,
  IsReady=function()return d.Ready end,Render=function()return d.RenderResult end,SetVisible=function()end,
  Dispose=function()d.Disposed+=1 end}
 local controller=Models.Install({Character=function()return character,root,h end,Camera=function()return nil end,
  Spawn=function(fn)table.insert(d.Queue,fn)end,RendererContext={},
  BuildRenderer=function()d.Builds+=1;return renderer end,
  BindRender=function()return{Disconnect=function()d.Disconnected=true end}end})
 return{Controller=controller,Data=d,Root=root,Leg=leg,Character=character}
end
do
 local f=localFixture();f.Controller:SetEnabled(true)
 check(f.Root.LocalTransparencyModifier~=1,'Loading hid the source avatar')
 f.Data.Queue[1]();f.Data.RenderResult=false;f.Controller:Step(1/60)
 check(f.Root.LocalTransparencyModifier~=1,'Failed renderer hid the source avatar')
 f.Data.RenderResult=true;f.Controller:Step(1/60)
 check(f.Root.LocalTransparencyModifier==1,'Verified rendered model did not hide source avatar')
 f.Data.Ready=false;f.Controller:Step(1/60)
 check(f.Root.LocalTransparencyModifier~=1 and not f.Controller.Renderer,'Removed model left source avatar invisible')
 f.Controller:Dispose();check(f.Data.Disconnected,'Model controller render callback leaked')
end
do
 local f=localFixture();f.Controller:SetEnabled(true);f.Controller:SetEnabled(false);f.Data.Queue[1]()
 check(not f.Controller.Renderer and not f.Controller.Loading and f.Root.LocalTransparencyModifier~=1,'Late disabled loader hid the source avatar')
end

-- Regression: detached avatar parts must not stay hidden after cleanup.
do
 local f=localFixture();f.Controller:SetEnabled(true);f.Data.Queue[1]();f.Controller:Step(1/60)
 check(f.Root.LocalTransparencyModifier==1,'Fixture did not hide source part')
 f.Root.Parent=nil;f.Controller:SetEnabled(false)
 check(f.Root.LocalTransparencyModifier==0,'Unparented original source root remained hidden')
end
do
 local f=localFixture();f.Controller:SetEnabled(true);f.Data.Queue[1]();f.Controller:Step(1/60)
 f.Leg.Parent=nil;f.Controller:Step(1/60)
 check(f.Leg.LocalTransparencyModifier==0 and f.Controller.Hidden[f.Leg]==nil,'Detached original limb remained hidden/owned')
end
do
 local f=localFixture();f.Controller:SetEnabled(true);f.Data.Queue[1]();f.Controller:Step(1/60)
 f.Root.LocalTransparencyModifier=.35;f.Controller:SetEnabled(false)
 check(f.Root.LocalTransparencyModifier==.35,'Cleanup overwrote a later external transparency value')
end
-- R15 joint chains inherit a single proximal swing rather than compounding it.
do
 local f=fixture();f.Left.Name='LeftUpperLeg'
 local lower=newNode('Part','LeftLowerLeg');lower.Size=Vector3.new(1,1,1);lower.CFrame=CFrame.new(-.5,0,0);lower.Parent=f.Asset
 local foot=newNode('Part','LeftFoot');foot.Size=Vector3.new(1,.5,1);foot.CFrame=CFrame.new(-.5,-.75,0);foot.Parent=f.Asset
 local knee=newNode('Motor6D','LeftKnee');knee.Part0=f.Left;knee.Part1=lower;knee.C0=CFrame.new(0,-1,0);knee.C1=CFrame.new();knee.Transform=CFrame.new();knee.Parent=f.Left
 local ankle=newNode('Motor6D','LeftAnkle');ankle.Part0=lower;ankle.Part1=foot;ankle.C0=CFrame.new(0,-.75,0);ankle.C1=CFrame.new();ankle.Transform=CFrame.new();ankle.Parent=lower
 local renderer=Sahur.Build(f.Context,f.Valid,function()end)
 local roles={};for _,edge in ipairs(renderer.Joints)do roles[edge.B]=edge.Role or 'rest'end
 check(roles[f.Left]=='LeftLeg'and roles[lower]=='rest'and roles[foot]=='rest','R15 knee/ankle compounded full hip swing')
 renderer:Render(renderer:Sample('walk',.25),CFrame.new(),false)
 check((f.Left.CFrame.UpVector-lower.CFrame.UpVector).Magnitude<1e-6 and(lower.CFrame.UpVector-foot.CFrame.UpVector).Magnitude<1e-6,'R15 lower chain failed to inherit proximal pose')
 renderer:Dispose()
end
-- Reversed WeldConstraints and separate mesh pieces both require real limb
-- articulation; neither is an assurance that a one-piece mesh has a rig.
do
 local f=fixture();local arms={}
 for _,side in ipairs({'Left','Right'})do
  local arm=newNode('Part',side..'Arm');arm.Size=Vector3.new(2,.4,.4)
  arm.CFrame=CFrame.new(side=='Left'and -2 or 2,3.5,0);arm.Parent=f.Asset;arms[side]=arm
  local weld=newNode('WeldConstraint',side..'Shoulder');weld.Part0=arm;weld.Part1=f.Torso;weld.Parent=arm
 end
 local renderer=Sahur.Build(f.Context,f.Valid,function()end)
 renderer:Render(renderer:Sample('idle',0),CFrame.new(),false)
 check(arms.Left.Position.Y<f.Torso.Position.Y and arms.Right.Position.Y<f.Torso.Position.Y,'Reversed welded T-pose arms did not hang below shoulders')
 local roles={};for _,edge in ipairs(renderer.Joints)do roles[edge.B]=edge.Role end
 check(roles[arms.Left]=='LeftArm'and roles[arms.Right]=='RightArm','WeldConstraint edges lost limb animation roles')
 local torsoIdle=f.Torso.CFrame.UpVector;local idleY=f.Torso.Position.Y
 renderer:Render(renderer:Sample('crouch',0),CFrame.new(),false)
 check(f.Torso.Position.Y<idleY-.2 and(f.Torso.CFrame.UpVector-torsoIdle).Magnitude>.1,'Crouching did not bend/lower the torso')
 renderer:Render(renderer:Sample('sit',0),CFrame.new(),false)
 check((f.Torso.CFrame.UpVector-torsoIdle).Magnitude>.05,'Sitting did not change torso posture')
 renderer:Dispose()
end
do
 local f=fixture()
 for _,v in ipairs(f.Asset:GetDescendants())do if v:IsA('Motor6D')or v:IsA('WeldConstraint')then v:Destroy()end end
 f.Torso.Name='MeshBody';f.Left.Name='Mesh001';f.Right.Name='Mesh002'
 local arm=newNode('Part','Mesh003');arm.Size=Vector3.new(2,.4,.4);arm.CFrame=CFrame.new(-2,3.5,0);arm.Parent=f.Asset
 local renderer=Sahur.Build(f.Context,f.Valid,function()end)
 local roles={};for _,edge in ipairs(renderer.Joints)do roles[edge.B]=edge.Role end
 check(roles[f.Left]=='LeftLeg'and roles[f.Right]=='RightLeg'and roles[arm]=='LeftArm','Disconnected unnamed geometry lacked inferred hips/shoulder')
 renderer:Render(renderer:Sample('walk',.25),CFrame.new(),false)
 check((f.Left.CFrame.UpVector-f.Right.CFrame.UpVector).Magnitude>.1,'Disconnected inferred legs stayed rigid')
 check(not renderer.RigidOnly,'Articulated separate limbs were reported rigid')
 renderer:Dispose()
end
do
 local world=newNode('Workspace','World');local asset=newNode('Model','StaticModel')
 local mesh=newNode('MeshPart','SingleMesh');mesh.Size=Vector3.new(2,6,2);mesh.Parent=asset
 local renderer=Sahur.Build({Workspace=world,LoadAsset=function()return{asset}end},function()return true end,function()end)
 check(renderer.RigidOnly and not renderer.HasFaceRig,'Single textured mesh incorrectly advertised limbs/facial rig')
 renderer:Render(renderer:Sample('run',.25),CFrame.new(),false)
 check(mesh.Size.Y>5,'Rigid mesh was stretched to invent separate limb motion')
 renderer:Dispose()
end
do
 local f=fixture();local head=f.Asset:FindFirstChild('Head');local face=newNode('FaceControls','FaceControls');face.Parent=head
 local renderer=Sahur.Build(f.Context,f.Valid,function()end)
 check(renderer.HasFaceRig,'DynamicHead FaceControls was not discovered')
 renderer:Render(renderer:Sample('idle',3.55/4),CFrame.new(),false)
 check(face.LeftEyeClosed>.9 and face.RightEyeClosed>.9,'Available facial controls did not blink')
 renderer:Dispose()
end
-- Import order and a rotated first child must not rotate a loose model sideways.
do
 local world=newNode('Workspace','World');local asset=newNode('Model','Loose')
 local arm=newNode('Part','LeftArm');arm.Size=Vector3.new(.4,2,.4);arm.CFrame=CFrame.new(-2,3.5,0)*CFrame.Angles(0,0,math.pi/2);arm.Parent=asset
 local body=newNode('Part','Torso');body.Size=Vector3.new(2,3,1);body.CFrame=CFrame.new(0,3,0);body.Parent=asset
 local leg=newNode('Part','LeftLeg');leg.Size=Vector3.new(.6,2,.6);leg.CFrame=CFrame.new(-.5,.5,0);leg.Parent=asset
 local renderer=Sahur.Build({Workspace=world,LoadAsset=function()return{asset}end},function()return true end,function()end)
 renderer:Render(renderer:Sample('idle',0),CFrame.new(),false)
 check(renderer.Root==body and body.CFrame.UpVector.Y>.99,'Rotated first asset child changed the core/up basis')
 renderer:Dispose()
end
-- A skinned rest Transform translation scales, and torso bones do not receive
-- the same body lean a second time from their carrier mesh.
do
 local world=newNode('Workspace','World');local asset=newNode('Model','Skinned')
 local mesh=newNode('MeshPart','Body');mesh.Size=Vector3.new(2,6,2);mesh.Parent=asset
 local spine=newNode('Bone','Spine');spine.CFrame=CFrame.new();spine.Transform=CFrame.new(0,.1,0);spine.WorldCFrame=CFrame.new();spine.Parent=mesh
 local renderer=Sahur.Build({Workspace=world,LoadAsset=function()return{asset}end},function()return true end,function()end)
 renderer:SetScale(1.3);renderer:Render(renderer:Sample('crouch',0),CFrame.new(),false)
 check(math.abs(spine.Transform.Position.Y-.13)<1e-6,'Authored Bone.Transform translation did not scale')
 check(mesh.CFrame.UpVector.Y>.99 and spine.Transform.UpVector.Z>.1,'Carrier and spine compounded the same torso lean')
 renderer:Dispose()
end
-- Controller smooths input-driven pose transitions while leaving the actual
-- avatar movement properties and velocity completely unchanged.
do
 local f=localFixture();local h=f.Character:FindFirstChild('Humanoid')
 local crouch=true;f.Controller.Context.Crouching=function()return crouch end
 local poses={};f.Controller:SetEnabled(true);f.Data.Queue[1]()
 f.Controller.Renderer.Sample=Sahur.Sample;f.Controller.Renderer.Blend=Sahur.Blend
 f.Controller.Renderer.Render=function(_,pose)poses[#poses+1]=pose;return true end
 h.WalkSpeed=24;h.MoveDirection=Vector3.new(0,0,-1);f.Root.AssemblyLinearVelocity=Vector3.new(0,0,-24)
 f.Controller:Step(1/60);f.Controller:Step(1/60)
 local partial=poses[#poses].Crouch
 check(partial>0 and partial<1,'Crouch transition snapped instead of blending')
 for _=1,45 do f.Controller:Step(1/60)end
 check(poses[#poses].Crouch>.99 and poses[#poses].Run<.01,'Crouch pose failed to settle or incorrectly sprinted')
 crouch=false;for _=1,60 do f.Controller:Step(1/60)end
 check(poses[#poses].Run>.7 and poses[#poses].Walk>.99,'Running failed to derive from actual locomotion')
 f.Controller.CrouchInput=false;crouch=true;for _=1,30 do f.Controller:Step(1/60)end
 check(poses[#poses].Crouch<.01,'Disabled crouch input still changed the pose')
 check(h.WalkSpeed==24 and f.Root.AssemblyLinearVelocity.Z==-24 and f.Root.CanCollide,'Cosmetic locomotion changed real avatar physics')
 f.Controller:Dispose()
end
print('PASS: '..checks..' model sanitizer/articulation/locomotion/scale/cancellation/visibility checks (mocked)')
