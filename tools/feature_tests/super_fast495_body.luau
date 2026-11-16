local Enum={ActuatorRelativeTo={World='World'}}
local function setup()
 local f=fixture(Pallet);local c=f.Pallet.Context
 c.SourceKick=true;c.KickMode=function()return f.Mode or'Super Fast'end;c.ContactMultiplier=function()return f.Mode=='Normal'and 1 or 2 end
 f.Target.Torso.Name='HumanoidRootPart';f.Pallet:SetContactRate(30)
 for _,part in ipairs(f.Model:GetChildren())do part.CanQuery=true;part.Massless=false end
 local old=getfenv(f.Pallet.ConfigureKickPallet);setfenv(f.Pallet.ConfigureKickPallet,setmetatable({Enum=Enum},{__index=old}))
 local touches={};c.NativeTouch=function(sound,root,phase)
  touches[#touches+1]={Phase=phase,At=f.Sim.Now}
  check(sound==f.Sound and root==f.Target.Torso,'Super Fast used a clone or wrong receiver')
 end
 check(f.Pallet:Prepare(f.Valid),'Existing source pallet failed to prepare')
 local owned=c.Owned;c.PhysicsOwned=function()return f.Data.Owned end
 -- Fake solver movement is external to the production controller. Without it
 -- a placement is never called an observed upward departure or server hit.
 f.Sim.Physics=function(dt)
  if not f.Data.Blocked and f.Data.Owned and f.Pallet.SuperFlight then
   translate(f.Main,Vector3.new(0,600*dt,0))
  end
 end
 f.Touches=touches
 f.Restore=function()setfenv(f.Pallet.ConfigureKickPallet,old)end
 return f
end
for _,fps in ipairs({20,60,240})do
 local f=setup();local board=f.Model
 check(f.Pallet:SourceContact(f.Target.Character,f.Valid),'Super Fast failed its initial body contact')
 check(f.Pallet.SuperFlight and f.Pallet:IsContactActive(),'Contact did not reserve the board until physical exit')
 check((f.Sound.Position-f.Target.Torso.Position).Magnitude<1e-6,'Super Fast never placed the actual source board at the held body')
 check(f.Pallet.KickProfile.Lift.Position.X==f.Target.Torso.Position.X and f.Pallet.KickProfile.Lift.Position.Z==f.Target.Torso.Position.Z,'Lift pulls the contact diagonally towards the world origin')
 check(f.Pallet.SuperDepartures==nil and not f.Target.Flag.Value,'Placement was counted as physics departure or game acknowledgement')
 check(not f.Pallet:SourceContact(f.Target.Character,f.Valid),'One board started a second strike before leaving the body')
 f.Target.Flag.Value=true -- external game acknowledgement, never written by production
 f.Sim:Run(.2,fps)
 check(not f.Pallet.SuperFlight and f.Pallet.SuperDepartures==1,'Real upward solver movement did not complete the flight')
 check(#f.Touches==2 and f.Touches[1].Phase==0 and f.Touches[2].Phase==1,'Lift contact was not ended exactly once')
 local strikes=f.Pallet.SuperStrikes
 for _=1,10 do f.Pallet:SourceContact(f.Target.Character,f.Valid);f.Sim:Tick(1/fps)end
 check(f.Pallet.SuperStrikes==strikes,'Existing game ragdoll was continuously struck instead of waiting for recovery')
 f.Target.Flag.Value=false
 check(f.Pallet:SourceContact(f.Target.Character,f.Valid),'Recovered game ragdoll did not rearm the upward contact')
 f.Mode='Faster';f.Pallet:SetKickMode('Faster')
 check(not f.Pallet.SuperFlight and not f.Sound.CanQuery,'Mode switch retained the flight reservation/query override')
 check(f.Sound.Position.Y==1000,'Mode switch left the board within reach next to the victim')
 f.Sim:Run(.1,fps);check(f.Pallet:SourceContact(f.Target.Character,f.Valid),'Switching back broke the working native-contact path')
 f.Pallet:Cancel(f.Target.Character);f.Sim:Run(.1,fps)
 check(f.Pallet.Model==board and f.Data.Spawns==0,'Super Fast replaced/spammed the shared pallet')
 f.Pallet:Dispose();f.Restore()
end
do
 local f=setup();f.Data.Blocked=true
 f.Pallet:SourceContact(f.Target.Character,f.Valid);f.Sim:Run(.5,60)
 check(not f.Pallet.SuperFlight and not f.Pallet.SuperDepartures,'Blocked board was called a successful physical exit or retained the shared lock')
 check(f.Sound.Position.Y==1000,'Blocked-flight timeout left a board on/inside the victim')
 f.Pallet:Dispose();f.Restore()
end
do
 local f=setup();f.Data.Owned=false
 local position=f.Sound.Position;f.Pallet:SourceContact(f.Target.Character,f.Valid)
 check(not f.Pallet.SuperFlight and #f.Touches==0 and f.Sound.Position==position,'Super Fast moved or touched with an unowned board')
 f.Data.Owned=true;f.Pallet:SourceContact(f.Target.Character,f.Valid);f.Data.Valid=false;f.Sim:Tick(1/60)
 check(not f.Pallet.SuperFlight and f.Sound.Position.Y==1000,'Cancellation left an active upward contact')
 local count=#f.Touches;f.Sim:Run(.2,60);check(#f.Touches==count,'Cancelled flight resumed its touch callback')
 f.Pallet:Dispose();f.Restore()
end
do
 local f=setup();local position=f.Sound.Position
 f.Pallet.Context.PhysicsOwned=function(part)return part~=f.Target.Torso end
 f.Pallet:SourceContact(f.Target.Character,f.Valid)
 check(not f.Pallet.SuperFlight and #f.Touches==0 and f.Sound.Position==position,'Super Fast struck before target physics capture was acknowledged')
 f.Pallet:Dispose();f.Restore()
end
do
 local f=setup();local external=newNode('Part','External',WORLD)
 f.Main.GetConnectedParts=function()return{f.Main,f.Sound,external}end
 local before=f.Sound.Position;f.Pallet:SourceContact(f.Target.Character,f.Valid)
 check(not f.Pallet.SuperFlight and #f.Touches==0 and f.Sound.Position==before,'Coupled board moved an external character assembly')
 f.Main.GetConnectedParts=nil;f.Pallet:SourceContact(f.Target.Character,f.Valid);f.Pallet:Dispose();f.Sim:Run(.2,60)
 check(not f.Pallet.SuperFlight and f.Touches[#f.Touches].Phase==1,'Unload failed to end an active Super Fast contact');f.Restore()
end
do
 -- Normal's native contacts preserve v4.94's rate; Faster samples the same
 -- source operation twice as often without changing rotation/lift constants.
 local f=setup();f.Mode='Normal';local normal=0
 for _=1,120 do if f.Pallet:SourceContact(f.Target.Character,f.Valid)then normal+=1 end;f.Sim:Tick(1/60)end
 f.Mode='Faster';local fast=0
 for _=1,120 do if f.Pallet:SourceContact(f.Target.Character,f.Valid)then fast+=1 end;f.Sim:Tick(1/60)end
 check(normal>=59 and normal<=61 and fast>=119,'Native-contact speed profiles do not retain Normal=30/s, Faster=60/s')
 check(not f.Pallet.SuperFlight,'Normal/Faster invoked Super Fast physical positioning')
 f.Pallet:Dispose();f.Restore()
end
print('PASS: '..checks..' video-inspired contact/lift/observed exit, recovery, native speed profiles and cancellation checks (mocked; no server kick timing)')
