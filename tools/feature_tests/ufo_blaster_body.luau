local checks=0;local function check(v,m)assert(v,m);checks+=1 end
function Proxy:GetConnectedParts()return self._connected or{}end
local oldIndex=Proxy.__index
Proxy.__index=function(n,k)if k=='Enabled'and n:IsA('Attachment')then error('Enabled is not a valid member of Attachment')end;return oldIndex(n,k)end
local function fixture(mode)
 local world=newNode('Folder');local c=newNode('Model');c.Parent=world;local r=newNode('Part');r.Parent=c;local h={Health=100}
 local ufo=newNode('Model','ObjectModel');ufo.Parent=world
 local emitter=newNode('Part','GreenEmitter');emitter.Parent=ufo;emitter.Color=Color3.fromRGB(30,255,70);emitter.Material=Enum.Material.Neon;emitter.CFrame=CFrame.new(2,2,-4)
 newNode('Attachment').Parent=emitter
 if mode=='anchored'then emitter.Anchored=true elseif mode=='noeffect'then emitter.Material=Enum.Material.SmoothPlastic end
 local d={Now=0,Queue={},Destroyed={},Reserved={},Spawned=0,Mount=CFrame.new(2,1,-1),Owned=true};local pre=signal()
 local ctx={RunService={PreSimulation=pre},Clock=function()return d.Now end,Character=function()return c,r,h end,
  Owned=function()return d.Owned end,RequestOwner=function()d.OwnerRequests=(d.OwnerRequests or 0)+1 end,
  SpawnThread=function(fn)d.Queue[#d.Queue+1]=fn end,Wait=function(dt)d.Now+=dt end,Blocked=function()return d.Blocked end,
  UFOModels=function()return {ufo}end,Mount=function()return d.Mount end,Aim=function()return Vector3.new(2,1,-100)end,
  Focused=function()return d.Focused end,Prepare=function()d.Prepared=(d.Prepared or 0)+1 end,
  Spawn=function(name,frame,valid)
   d.Spawned+=1;local model=newNode('Model',name);model.Parent=world;local p=newNode('Part','SoundPart');p.Color=Color3.new(.5,.5,.5);p.CFrame=frame;p.Parent=model
   if d.CancelSpawn then d.CancelSpawn()end
   return model
  end,
  Part=function(model)return model:FindFirstChild('SoundPart')end,
  Break=function(model,timeout,force,valid)check(force and valid(),'Native hold/drop detachment invalid')end,
  Reserve=function(model,value)d.Reserved[model]=value or nil end,Destroy=function(model)d.Destroyed[#d.Destroyed+1]=model;model:Destroy()end,
  BindFire=function(fn)d.Fire=fn end,UnbindFire=function()d.Fire=nil;d.Unbound=(d.Unbound or 0)+1 end}
 local blaster=Blaster.Install(ctx);return blaster,d,pre,ctx,c,r,h,ufo,emitter
end
do
 local b,d,pre,ctx,c,r,h,ufo,emitter=fixture();local original=emitter.CFrame;local color=emitter.Color;local size=emitter.Size
 local instances=#ALL_INSTANCES;b:Equip();d.Queue[1]()
 check(b.Enabled and not b.Building and d.Spawned==4 and d.Fire,'Real prop blaster not assembled')
 check(#b.Records==5,'Missing source/prop cleanup record');b:Step(1/60)
 check(emitter.CFrame~=original and emitter.Color==color and emitter.Size==size,'Native source was not moved or was visually forged')
 for i=instances+1,#ALL_INSTANCES do
  local p=ALL_INSTANCES[i];check(p:IsA('Model')or p:IsA('BasePart'),'Blaster manufactured a fake local laser/effect')
 end
 check(b:Fire()and not b:Fire(),'Shot/cooldown gate failed');local shot=b.Shot;d.Now+=.05;b:Step(.05)
 check((emitter.Position-shot.Origin).Magnitude>1 and emitter.AssemblyLinearVelocity.Magnitude==120,'Native piece did not travel')
 d.Now+=.3;b:Step(.05);check(not b.Shot,'Native projectile not recalled')
 d.Focused=true;d.Now+=1;check(not b:Fire(),'Text/UI focus fired weapon');check(b:Fire(true),'Explicit menu Fire button was blocked');d.Focused=false
 d.Owned=false;local before=emitter.CFrame;b:Step(1/60)
 check(not b.Enabled and emitter.CFrame==before and d.Unbound==1,'Ownership loss moved borrowed piece or leaked input')
 check(#d.Destroyed==4 and next(d.Reserved)==nil,'Gun props leaked');b:Dispose();check(not pre.Connections[1].Connected,'Blaster callback leaked')
end
do
 local b,d,pre,ctx,c,r,h,ufo,emitter=fixture('anchored');local original=emitter.CFrame;b:Equip();d.Queue[1]()
 check(not b.Enabled and d.Spawned==0 and d.Prepared==1,'Anchored source produced a forged weapon')
 check(emitter.Anchored and emitter.CFrame==original,'Anchored UFO was detached locally');b:Dispose()
end
do
 local b,d=fixture('noeffect');b:Equip();d.Queue[1]()
 check(not b.Enabled and d.Spawned==0,'Missing native green effect produced a local substitute');b:Dispose()
end
do
 local b,d,pre,ctx,c,r,h,ufo,emitter=fixture();b:Equip();d.Queue[1]();local source=b.Source;local original=source.Original
 b:Step(1/60);b:Stop();check(emitter.CFrame==original and emitter.CanCollide and emitter.CanTouch,'Borrowed UFO piece not restored')
 b:Equip();d.CancelSpawn=function()b:Stop()end;d.Queue[2]()
 check(not b.Enabled and #b.Records==0 and #d.Destroyed==5,'Canceled spawn leaked a prop or cleanup record');b:Dispose()
end
do
 local b,d,pre,ctx,c,r,h,ufo,emitter=fixture();local external=newNode('Part');external.Parent=c;emitter._connected={external}
 check(not Blaster.Assembly(emitter,ufo),'Source connected to avatar accepted');b:Equip();d.Queue[1]();check(d.Spawned==0,'Connected UFO fired');b:Dispose()
end
do
 local b,d,pre,ctx,c,r,h,ufo,emitter=fixture();b:Equip();h.Health=0;d.Queue[1]()
 check(not b.Enabled and d.Spawned==0,'Dead avatar completed pending equip');b:Dispose()
end
do
 local b,d,pre,ctx,c,r,h,ufo,emitter=fixture('noeffect');local source,nativeForce,align
 ctx.SpawnUFO=function(valid)
  check(valid(),'Canceled source spawn ran');d.UFOSpawns=(d.UFOSpawns or 0)+1
  source=newNode('Model','FlyingToyUfo');source.Parent=ufo.Parent
  local p=newNode('Part','SoundPart');p.Color=Color3.new(.5,.5,.5);p.CFrame=CFrame.new(2,2,-6);p.Parent=source
  local beam=newNode('Beam','UFOBeam');beam.Color={Keypoints={{Value=Color3.new(1,1,1)}}};beam.Enabled=true;beam.Parent=p
  nativeForce=newNode('BodyVelocity');nativeForce.MaxForce=Vector3.new(500,500,500);nativeForce.Parent=p
  align=newNode('AlignPosition');align.Enabled=true;align.Parent=p
  return source
 end
 b:Equip();d.Queue[1]()
 check(b.Enabled and not b.Building and d.UFOSpawns==1 and d.Spawned==4,'Automatic game UFO source was not assembled')
 check(b.Source.NativeUFO and nativeForce.MaxForce==Vector3.zero,'Native toy forces fight muzzle movement')
 check(align.Enabled==false,'Native UFO AlignPosition fights gun mount')
 align.Enabled=true;check(align.Enabled==false,'Native UFO script re-enabled a competing force')
 local late=newNode('VectorForce');late.Enabled=true;late.Parent=source
 check(late.Enabled==false,'Delayed native force was not suppressed')
 b:Step(1/60);check(b:Fire(),'Game UFO source could not fire')
 b:Stop();check(#d.Destroyed==5 and not source.Parent and next(d.Reserved)==nil,'Spawned UFO source/props leaked')
 check(b.LastInspection and #b.LastInspection.Models==2,'Failed/equipped source inspection was not preserved')
 b:Dispose()
end
do
 local b,d,pre,ctx,c,r,h,ufo,emitter=fixture('noeffect')
 ctx.SpawnUFO=function()
  local model=newNode('Model','FlyingToyUfo');model.Parent=ufo.Parent
  local p=newNode('Part','SoundPart');p.Color=Color3.new(.5,.5,.5);p.Parent=model
  return model
 end
 b:Equip();d.Queue[1]();check(not b.Enabled and d.Spawned==0 and #d.Destroyed==1,'UFO without original effect produced a fake laser')
 check(b.LastInspection~=nil,'Unavailable source tree lost its diagnostic snapshot');b:Dispose()
end
print('PASS: '..checks..' UFO game-source preparation, native piece, props, shot/recall and cleanup checks (mocked)')
