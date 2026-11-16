local Enum={ActuatorRelativeTo={World='World'}}
for _,fps in ipairs({20,60,240})do
 local f=fixture(Pallet);f.Pallet.Context.SourceKick=true
 f.Target.Torso.Name='HumanoidRootPart';f.Target.Torso.CanTouch=false
 for _,part in ipairs(f.Model:GetChildren())do part.CanQuery=true;part.Massless=false end
 local originalSize=f.Sound.Size
 local begins,ends,open=0,0,false
 f.Pallet.Context.NativeTouch=function(sound,root,phase)
  check(sound==f.Sound and root==f.Target.Torso,'Native kick called touch with the wrong model/root')
  check(root.CanTouch and sound.CanTouch,'Native root or transmitter was not touchable')
  if phase==0 then check(not open,'Native begin repeated without an end');begins+=1;open=true
  else check(open,'Unmatched native end');ends+=1;open=false end
 end
 -- ConfigureKickPallet resolves Enum lexically in the module, supplied by the
 -- real engine in production. This harness wraps the module with that enum.
 local old=getfenv(f.Pallet.ConfigureKickPallet)
 local env=setmetatable({Enum=Enum},{__index=old});setfenv(f.Pallet.ConfigureKickPallet,env)
 check(f.Pallet:Prepare(f.Valid),'Source kick could not prepare the existing owned pallet')
 local profile=f.Pallet.KickProfile
 local lift=f.Main:FindFirstChild('KickPalletPosition');local rotation=f.Sound:FindFirstChild('KickPalletRotation')
 check(profile and lift and rotation and f.Pallet.NativeKickReady,'Prepared pallet has no source rotation/lift profile')
 check(lift.MaxForce.Y==math.huge and lift.Position.Y==10000 and lift.D==100,'Idle pallet was left to fall on the floor')
 check(rotation.MaxTorque==math.huge and rotation.AngularVelocity.X==5000 and rotation.AngularVelocity.Z==5000,'Source rotation lacks torque or source angular velocity')
 check(f.Sound.Position.Y==1000 and f.Sound.Size.Y==2 and f.Sound.Size.X==6,'Source board remains next to the actor or uses incorrect transmitter dimensions')
 f.Data.Owned=false -- deliberate target Grab replaces the pallet PartOwner marker
 local parked=f.Sound.Position
 for _=1,fps do f.Pallet:SourceContact(f.Target.Character,f.Valid);f.Sim:Tick(1/fps)end
 check(begins>1 and ends==begins and not open,'Source root contacts stalled on the released pallet marker or left an open contact')
 check(not f.Target.Torso.CanTouch,'Native cleanup failed to restore the original receiver touch flag')
 check(f.Pallet.Passes==0 and f.Sound.Position.Y==parked.Y,'Primary root contact teleported/swept the board through the target')
 check(not f.Target.Flag.Value and f.Pallet.Confirmed==0,'A local native API call was counted as a server hit/ragdoll')
 f.Data.Valid=false;local count=begins;f.Pallet:SourceContact(f.Target.Character,f.Valid);check(begins==count,'Stopped kick emitted another native contact')
 f.Data.Valid=true;f.Sim:Run(.2,fps);f.Pallet:SourceContact(f.Target.Character,f.Valid)
 f.Pallet:Cancel(f.Target.Character);check(not open and not f.Target.Torso.CanTouch,'Cancellation left the contact or touch flag active')
 f.Pallet:DisableKickProfile()
 check(not rotation.Parent and not lift.Parent and f.Sound.Size==originalSize,'One-shot handoff retained conflicting spin/lift movers or changed the transmitter size')
 check(f.Sound.CanQuery and not f.Sound.Massless,'One-shot handoff did not restore native pallet properties')
 f.Pallet:Dispose();f.Sim:Run(.2,fps);check(not open,'Late native callback reopened after disposal')
 setfenv(f.Pallet.ConfigureKickPallet,old)
end
do
 local f=fixture(Pallet);local main=f.Main;main.Parent=nil
 local entry=f.Pallet:Request(f.Target.Character,f.Valid,true);f.Sim:Run(.4,60)
 check(f.Data.Destroyed==0 and f.Data.Spawns==0 and f.Pallet.Model==f.Model,'Missing streamed Main destroyed/replaced the retained native model')
 main.Parent=f.Model;f.Sim:Run(.3,60)
 check(f.Pallet.Passes>0 and f.Data.Spawns==0,'Existing partial pallet did not recover when Main arrived')
 f.Pallet:Dispose()
end
print('PASS: '..checks..' source spin/lift, real-root contact pairs, released marker reuse, read-only game state and partial-model recovery checks (mocked)')
