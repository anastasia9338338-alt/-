local function test(name,fn)fn();print('PASS '..name)end
-- Translation fixtures retain the actual HitboxPart offset from its assembly root.
frameMT.__index={Inverse=function(cf)return CFrame.new(-cf.Position.X,-cf.Position.Y,-cf.Position.Z)end,
 ToObjectSpace=function(cf,other)return CFrame.new(other.Position-cf.Position)end}
local Defense=modules.BlobmanDefense
local function setup()
 local f=fixture();local ctx=f.DefenseContext;ctx.Held=function()return f.Held end
 ctx.Wait=function(dt)f.Now+=dt;if f.WaitHook then f.WaitHook()end end
 local spawn=f.SpawnBanana
 function f:SpawnBanana()
  local model=spawn(self);self.Contact=model:FindFirstChild('HitboxPart');self.Contact.Position=Vector3.new(2,0,0)
  object('Part','EdiblePart',model);return model
 end
 ctx.Eat=function(model)f.Eats+=1;if f.EatHook then return f.EatHook(model)end;model:FindFirstChild('EdiblePart'):Destroy();return nil end
 local d=Defense.Install(ctx);return f,d
end
local function ready(f,d,mode)
 f:SeatOther();d:SetMode(mode or 'Banana',true);d:Step();f:RunJobs();d:Step()
 expect('real eaten peel kept',d.Prepared~=nil and f.Eats==1 and f.Spawns==1 and f.Destroyed==0)
 expect('controller has no swallowed failure',not d.LastError)
end
test('no avatar movement or shared pallet work from aura',function()
 local f,d=setup();d:SetMode('Aura',true);d:Step();f:RunJobs()
 expect('empty nearby Blobman needs no banana',f.Spawns==0)
 local rootWrites=0;f.R.Changed:Connect(function(k)if k=='CFrame'or k=='AssemblyLinearVelocity'or k=='AssemblyAngularVelocity'then rootWrites+=1 end end)
 f:SeatOther();f.Now=2;d:Step();f:RunJobs();d:Step()
 expect('aura uses owned real peel',d.Prepared and d.Session and d.Session.Purpose=='Aura')
 expect('aura touches real HitboxPart offset',d.Prepared.Root.CFrame.Position==f.TLeg.Position-Vector3.new(2,0,0))
 f.Now=2.2;f.TRag.Value=true;d:Step()
 expect('aura contact ends and parks',not d.Session and not f.Contact.CanTouch)
 expect('no local root/attachment/joint changes',rootWrites==0 and f.Att.Parent==f.R and f.Att:IsA('Attachment')and f.Motor.Enabled and f.Leg.Parent==f.C)
 expect('no shared pallet ragdoll request',#f.Ragdolls==0)
 d:Dispose();expect('aura dispose releases peel/listener',f.Destroyed==1 and not d.Connection.Connected)
end)
test('nil food return keeps the peel and spins after rider contact',function()
 local f,d=setup();ready(f,d)
 expect('trip phase touches rider',d.Session and d.Session.Phase=='Trip'and f.Contact.CanTouch and not f.Contact.CanCollide)
 f.Now=.2;d:Step();f.Now=.25;d:Step()
 expect('real peel spins inside Blobman',d.Session.Phase=='Spin'and d.Session.Mover.Parent==f.Peel and f.Peel.AssemblyAngularVelocity.Magnitude>2000)
 expect('self collisions excluded',#d.Session.Links>0 and f.Contact.CanCollide)
 local spin=d.Session.Mover;d:SetMode('Banana',false)
 expect('disable releases all physics and inventory',spin.Destroyed and not d.Session and not d.Prepared and not f.Reserved[f.LastBanana]and f.Destroyed==1)
 d:Dispose()
end)
test('ownership denial and held state leave physics alone',function()
 local f,d=setup();f.Owned=false;ready(f,d);expect('unowned peel cannot spin',not d.Session)
 f.Owned=true;f.Held=true;d:Step();expect('held aura pauses',not d.Session)
 f.Held=false;d:Step();expect('released aura can contact',d.Session~=nil)
 f.Held=true;d:Step();expect('grab cancels spin immediately',not d.Session);d:Dispose()
end)
test('foreign assembly and pending food are retained until disable',function()
 local f,d=setup();f.SpawnHook=function(model,root)root.ConnectedParts={f.R}end
 f:SeatOther();d:SetMode('Banana',true);d:Step();f:RunJobs()
 expect('foreign assembly rejected without deleting real peel',not d.Prepared and d.PendingModel==f.LastBanana and f.Destroyed==0)
 d:SetMode('Banana',false);expect('pending peel cleanup',f.Destroyed==1 and not d.PendingModel);d:Dispose()
end)
test('cancellation before spawn and during food remote',function()
 local f,d=setup();f:SeatOther();d:SetMode('Aura',true);d:Step();d:SetMode('Aura',false);f:RunJobs()
 expect('canceled queued prepare does not spawn',f.Spawns==0);d:Dispose()
 f,d=setup();f.EatHook=function(model)model:FindFirstChild('EdiblePart'):Destroy();d:SetMode('Banana',false)end
 f:SeatOther();d:SetMode('Banana',true);d:Step();f:RunJobs()
 expect('canceled eater cannot install prepared record',not d.Prepared and not d.Session and not f.LastBanana.Parent);d:Dispose()
end)
test('respawn and protected rider terminate sessions',function()
 local f,d=setup();ready(f,d);f.Protected=true;d:Step();expect('protected rider is released',not d.Session)
 f.Protected=false;f.Player.Character=nil;d:Step();expect('respawn releases peel',not d.Prepared and f.Destroyed==1);d:Dispose()
end)
test('arms hidden reversibly while native grab detectors stay live',function()
 local f,d=setup();f:SeatOther();d:SetMode('RemoveArms',true);d:Step()
 expect('arm geometry hidden locally',f.Right.LocalTransparencyModifier==1 and not f.Right.CanCollide)
 expect('detector and weld identity preserved',f.Right.Parent==f.Blob and f.RightWeld.Parent==f.Right)
 local hand=object('Part','RightHand',f.Blob);f.Now=1;d:Step();expect('streamed hand hidden',hand.LocalTransparencyModifier==1)
 local drops=0;f.Drop.OnFire=function()drops+=1 end
 local a=modules.BlobmanAura.Install({RunService=f.RunService,Clock=function()return f.Now end,Character=f.Character,
  LocalPlayer=f.Player,Enabled=function()return d.RemoveArms end,Models=function()return {f.Blob}end})
 a:Step();f.Ori.Attachment0=f.Att
 expect('stale orientation does not release another grab',drops==0)
 f.RightWeld.Attachment0=f.Att;expect('native weld drops actual local grab',drops==1 and not f.RightWeld.Enabled)
 d:SetMode('RemoveArms',false);a:Step()
 expect('disable restores native state',f.Right.LocalTransparencyModifier==0 and f.Right.CanCollide and f.Right.CanTouch and f.RightWeld.Enabled)
 a:Dispose();d:Dispose()
end)
test('own rider and protected/range exits restore arms',function()
 local f,d=setup();f:SeatLocal();d:SetMode('RemoveArms',true);d:Step();expect('own ridden Blobman untouched',next(d.Hidden)==nil)
 f.H.SeatPart=nil;f:SeatOther();f.Now=1;d:Step();expect('foreign arms suppressed',next(d.Hidden)~=nil)
 f.Protected=true;f.Now=2;d:Step();expect('protected arms restored',next(d.Hidden)==nil)
 f.Protected=false;f.R.Position=Vector3.new(1000,0,0);f.Now=3;d:Step();expect('range exit restores parts',next(d.Hidden)==nil);d:Dispose()
end)
print('ALL BLOBMAN DEFENSE CHECKS PASSED: '..checks)
