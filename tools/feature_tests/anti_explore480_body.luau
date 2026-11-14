local Guard=modules.AntiExplore
local function test(name,fn)fn();print('PASS '..name)end
local function setup()
 local f=fixture();f.R.WalkSpeed=16;f.H.WalkSpeed=16;f.H.MoveDirection=Vector3.new(1,0,0)
 f.H.HipHeight=0;f.R.AssemblyLinearVelocity=Vector3.new(16,0,0);f.Recovers={};f.Unblocks=0
 local g=Guard.Install({RunService=f.RunService,Workspace=f.World,Clock=function()return f.Now end,Character=f.Character,
  Held=function()return f.Held end,WalkingGuard=function()return f.Walking end,Blocked=function()return f.Blocked end,
  Ignore=function(part)return f.Ignore and part:IsDescendantOf(f.Inventory)end,
  Recover=function(root,duration)f.Recovers[#f.Recovers+1]={Root=root,Duration=duration}end,UnblockJump=function()f.Unblocks+=1 end})
 return f,g
end
local function trip(f)
 f.Rag.Value=true;f.H.State=Enum.HumanoidStateType.Physics;f.H.PlatformStand=true;f.H.AutoRotate=false;f.Motor.Enabled=false
end
test('banana trip preserves intact walking rig even after peel is gone',function()
 local f,g=setup();local banana=object('Model','FoodBanana',f.Toys);local peel=object('Part','HitboxPart',banana)
 local hitbox=object('Part','RagdollTouchedHitbox',f.R);g:SetEnabled(true)
 expect('banana and native character trip sensor suppressed',not peel.CanTouch and not hitbox.CanTouch)
 banana:Destroy();trip(f);f.Now=.1;g:Step()
 expect('no streamed hazard needed to recover actual trip',f.Motor.Enabled and not f.H.PlatformStand and f.H.AutoRotate and f.H.State=='Running')
 expect('native clear uses real root',#f.Recovers==1 and f.Recovers[1].Root==f.R and f.Recovers[1].Duration==0)
 expect('legs and root joint intact',f.Leg.Parent==f.C and f.Att.Parent==f.R and f.H.HipHeight==0 and f.H.WalkSpeed==16)
 local pos=f.R.CFrame;for i=1,30 do f.Now=.1+i*.05;g:Step()end
 expect('recovery bounded and no coordinate lock',#f.Recovers<=5 and f.R.CFrame==pos and f.R.AssemblyLinearVelocity==Vector3.new(16,0,0))
 f.Rag.Value=false;f.Now=2;g:Step();f.Now=2.3;g:Step();g:SetEnabled(false)
 expect('disable restores touch and no lingering callbacks',hitbox.CanTouch and not g.Connection.Connected and not g.Rig.Active)
 g:Dispose()
end)
test('snowball freeze thaws with native timed reset then zero',function()
 local f,g=setup();local snow=object('Model','BallSnowball',f.Toys);local ball=object('Part','Snowball',snow);g:SetEnabled(true)
 local weld=object('Weld','WeldHRP',f.R);weld.Part0=f.R;weld.Part1=f.Leg;trip(f);f.Now=.1;g:Step()
 expect('snow contact suppressed',not ball.CanTouch)
 expect('freeze weld released without destroying it',weld.Parent==f.R and not weld.Enabled)
 expect('native snow reset is used',#f.Recovers==1 and f.Recovers[1].Duration==.5 and f.Unblocks>0)
 f.Now=.16;g:Step();expect('native reset completed by zero clear',f.Recovers[2].Duration==0)
 g:Dispose();expect('disable restores freeze controlled by game',weld.Enabled and ball.CanTouch)
end)
for _,kind in ipairs({'BombMissile','BombDarkMatter','BlackHoleKick','Explosion'})do
 test(kind..' absorbs impulse without anchoring or moving position',function()
  local f,g=setup();g:SetEnabled(true);local model=object('Model',kind,f.Toys);object('Part','Hitbox',model)
  f.Now=.1;g:Step();local position=f.R.CFrame;local anchored=f.R.Anchored
  local force=object('BodyVelocity','ImpactVelocity',f.R);local original=Vector3.new(400000,400000,400000);force.MaxForce=original
  f.R.AssemblyLinearVelocity=Vector3.new(900,700,800);f.R.AssemblyAngularVelocity=Vector3.new(200,200,200)
  trip(f);f.Now=.15;g:Step()
  expect('large impulse rejected while desired walking survives',f.R.AssemblyLinearVelocity==Vector3.new(16,0,0)and f.R.AssemblyAngularVelocity==Vector3.zero)
  expect('intact upright recovery',f.Motor.Enabled and f.Leg.Parent==f.C and f.H.State=='Running')
  expect('hazard force suppressed',force.MaxForce==Vector3.zero)
  expect('no persistent anchor/position/height changes',f.R.CFrame==position and f.R.Anchored==anchored and f.H.HipHeight==0)
  model:Destroy();f.Rag.Value=false;f.Now=2;g:Step()
  expect('expired protection restores force and ordinary walk',force.MaxForce==original and f.R.AssemblyLinearVelocity==Vector3.new(16,0,0))
  g:Dispose()
 end)
end
test('matter downward impulse is absorbed while ordinary gravity remains free',function()
 local f,g=setup();g:SetEnabled(true);local matter=object('Model','BombDarkMatter',f.Toys);object('Part','Main',matter)
 f.Now=.1;g:Step();f.R.AssemblyLinearVelocity=Vector3.new(0,-900,0);f.Now=.16;g:Step()
 expect('downward matter force stopped',f.R.AssemblyLinearVelocity.Y==0 and not f.R.Anchored)
 g:Dispose()
end)
test('instantaneous explosion effect is observed before scan and then expires',function()
 local f,g=setup();g:SetEnabled(true);local effect=object('Part','Part',f.World);f.Now=.1;g:Step()
 expect('new root effect opens impulse protection window',g.ExposedUntil and g.ExposedUntil>f.Now and effect.CanTouch and effect.CanCollide)
 f.Now=1;g:Step();f.Now=2;g:Step();expect('map part cannot rearm itself',g.ExposedUntil<f.Now)
 g:Dispose()
end)
for _,mode in ipairs({'held','walking','seat','blocked','anchored'})do
 test(mode..' yields every character and velocity write',function()
  local f,g=setup();g:SetEnabled(true);trip(f)
  if mode=='held'then f.Held=true elseif mode=='walking'then f.Walking=true elseif mode=='seat'then f.H.SeatPart=f.Seat elseif mode=='anchored'then f.R.Anchored=true else f.Blocked=true end
  f.R.AssemblyLinearVelocity=Vector3.new(700,800,900);local writes=0
  f.R.Changed:Connect(function(k)if k=='CFrame'or k=='AssemblyLinearVelocity'or k=='AssemblyAngularVelocity'or k=='Anchored'then writes+=1 end end)
  for i=1,15 do f.Now=i*.1;g:Step()end
  expect('external movement owns the rig',writes==0 and #f.Recovers==0 and not f.Motor.Enabled and f.H.PlatformStand and f.H.State=='Physics')
  g:Dispose()
 end)
end
test('free walking/jump is never slowed by a nearby peel',function()
 local f,g=setup();local banana=object('Model','FoodBanana',f.Toys);object('Part','Peel',banana);g:SetEnabled(true)
 f.H.State='Freefall';f.R.AssemblyLinearVelocity=Vector3.new(16,60,0);local cf=f.R.CFrame
 for i=1,120 do f.Now=i/60;g:Step()end
 expect('normal jump, speed and gravity preserved',f.R.AssemblyLinearVelocity==Vector3.new(16,60,0)and f.R.CFrame==cf and f.H.State=='Freefall'and f.H.WalkSpeed==16 and f.H.HipHeight==0)
 expect('untripped character sends no native requests',#f.Recovers==0 and not g.Rig.Active);g:Dispose()
end)
test('respawn and disable release the previous character',function()
 local f,g=setup();g:SetEnabled(true);trip(f);g:Step();f.Player.Character=nil;g:Step()
 expect('old rig released on respawn',not g.Rig.Active and g.Character==nil and next(g.Parts)==nil)
 g:Dispose();expect('all per-enable observers disconnected',#g.Connections==0)
end)
print('ALL ANTI EXPLORE CHECKS PASSED: '..checks)
