for _,mode in ipairs({'Normal','No Ragdoll'})do for _,fps in ipairs({20,30,60,120,240,1000})do
 local f=fixture(mode);f.Guard:Refresh()
 check(not f.Guard.Rig.Active and #f.Data.Writes==0,'Idle anti-grab changed normal movement')
 f.Grab();f.Step(fps*3,fps)
 check(f.Guard.Rig.Active and f.Motor.Enabled and not f.Socket.Enabled and not f.Collider.CanCollide,'Walking rig collapsed during an active server ragdoll')
 check(f.Data.Falls==0 and f.HumData.State=='Running','Held character was allowed to enter limp physics')
 check(not f.Hum.PlatformStand and f.Hum.AutoRotate,'Humanoid walking controls remained disabled')
 check(f.Root.CFrame=='original frame'and f.Root.AssemblyLinearVelocity=='native gravity'and f.Hum.WalkSpeed==22 and f.Hum.HipHeight==2,'Anti-grab replaced root movement, gravity, height or speed')
 check(f.Data.Struggles>=60 and f.Data.Struggles<=92,'Native request cadence grew with FPS')
 for _,call in ipairs(f.Data.Clears)do check(call.Root==f.Root and call.Duration==0,'Walking mode sent wrong root or duration')end
 for _,property in ipairs(f.Data.Writes)do check(not property:match('^root%.')and property~='hum.WalkSpeed'and property~='hum.HipHeight','Walking protection wrote '..property)end
 -- A second ragdoll callback between frames must be corrected immediately.
 f.Motor.Enabled=false;f.Socket.Enabled=true
 check(f.Motor.Enabled and not f.Socket.Enabled,'Replicated ragdoll writes bypassed the armed property handlers')
 f.HumData.FloorMaterial='Air';f.HumData.State='Physics';f.Step(1,fps)
 check(f.HumData.State=='Freefall','Recovery while airborne suppressed natural falling')
 f.HumData.State='Freefall';f.Step(3,fps)
 check(f.HumData.State=='Freefall','Ordinary freefall was forced into grounded Running')
 f.Data.Held=false;f.Step(1,fps)
 check(f.Guard.Rig.Active,'Release dropped protection before the native ragdoll flag cleared')
 f.Rag.Value=false;f.Step(math.ceil(.3*fps),fps)
 check(not f.Guard.Rig.Active and f.Motor.Enabled and not f.Socket.Enabled,'Release left ragdoll constraints or protection latched')
 check(f.Hum:GetStateEnabled('Physics')and f.Hum:GetStateEnabled('FallingDown'),'Original state permissions were not restored')
 local before=#f.Data.Clears;f.Step(fps,fps);check(#f.Data.Clears==before,'Idle anti-grab kept firing requests')
 f.Guard:Dispose();f.Guard:Dispose()
 check(not f.Pre.Connections[1].Connected and not f.Heart.Connections[1].Connected,'Unload leaked frame handlers')
end end
do
 local f=fixture();f.Guard:Refresh();f.Grab();f.Step(1,60)
 local late=node('Motor6D',f.Torso,{Name='Replacement hip',Enabled=false,Part0=f.Torso,Part1=f.Leg})
 f.Character.DescendantAdded:Fire(late)
 check(late.Enabled,'New ragdoll joint was not protected')
 f.Data.Enabled=false;f.Guard:Refresh()
 check(not f.Guard.Rig.Character and not f.Motor.Enabled and f.Socket.Enabled,'Disabling protection did not restore current native ragdoll')
 late.Enabled=false;check(not late.Enabled,'Disabled anti-grab retained a property hook')
end
do
 local f=fixture();f.Grab();f.Guard:Refresh();f.Rag.Value=false;f.Data.Held=false;f.Step(30,60)
 check(f.Motor.Enabled and not f.Socket.Enabled and not f.Hum.PlatformStand and f.Hum.AutoRotate,'Late enable captured ragdoll as a permanent resting pose')
 f.Guard:Dispose()
end
do
 local f=fixture('Anti-Kill');f.Data.Held=true;f.Guard:Refresh()
 check(f.Hum.Sit and not f.Guard.Rig.Active and f.Data.Clears[1].Duration==.11,'Explicit Anti-Kill behavior changed')
 f.Data.Mode='Normal';f.Guard:Refresh();check(not f.Hum.Sit,'Switching out of Anti-Kill kept forced sitting')
 f.Guard:Dispose()
end
do
 local f=fixture('Escapes Anything, but buggy');f.Data.Held=true;f.Guard:Refresh()
 check(#f.Data.Tasks==1 and #f.Data.Clears==0,'Legacy escape behavior changed')
 f.Data.Mode='Normal';f.Guard:Refresh();f.Data.Tasks[1]();check(not f.Data.Escapes,'Canceled legacy escape still executed')
 f.Guard:Dispose()
end
do
 local f=fixture();f.Guard:Refresh();f.HumData.SeatPart={};f.HumData.Sit=true;f.Grab();f.Step(5,60)
 check(not f.Guard.Rig.Active and f.Hum.Sit,'Real seat was forced into walking')
 f.Guard:Dispose()
end
do
 local f=fixture();f.Guard:Refresh();f.Grab();f.Data.Throw=true;f.Step(120,120)
 check(f.Guard.LastError and f.Data.Struggles<=32 and f.Motor.Enabled,'Remote errors disabled the local walking rig or flooded retries')
 f.HumData.Health=0;f.Guard:Refresh();check(not f.Guard.Session and not f.Guard.Rig.Character,'Death retained the old rig')
 f.Guard:Dispose()
end
do
 local f=fixture();f.Guard:Refresh();f.Grab();f.HumData.Sit=true;f.Guard:Refresh()
 check(f.Guard.Rig.Active and not f.Hum.Sit and f.Motor.Enabled,'Grab-induced Sit incorrectly disabled walking protection')
 local hrp=node('WeldConstraint',f.Root,{Name='WeldHRP',Enabled=true,Part0=f.Root,Part1=f.Torso});f.Character.DescendantAdded:Fire(hrp)
 check(not hrp.Enabled,'Ragdoll HRP weld fought the restored root motor')
 f.Hum.Sit=true;f.Hum.PlatformStand=true;f.Hum.AutoRotate=false
 check(not f.Hum.Sit and not f.Hum.PlatformStand and f.Hum.AutoRotate,'Late humanoid writes bypassed active protection')
 check((f.Data.AnimationRecoveries or 0)>0,'Struggle animation was not recovered during a native grab')
 local foreign=node('Part',{},{});local weld=node('WeldConstraint',{}, {Enabled=true,Part0=f.Torso,Part1=foreign})
 local other=node('Part',{},{});local irrelevant=node('WeldConstraint',{}, {Enabled=true,Part0=foreign,Part1=other})
 f.Data.GrabWelds={weld,irrelevant};f.Guard:Refresh()
 check(not weld.Enabled and irrelevant.Enabled,'Grab link suppression affected another avatar or ignored the local grab')
 weld.Enabled=true;check(not weld.Enabled,'Active external grab link was re-enabled between physics frames')
 weld.Part0=foreign;weld.Part1=other;check(weld.Enabled,'Reused grab weld remained disabled for another avatar')
 weld.Part0=f.Torso;check(not weld.Enabled,'Reused grab weld did not protect the local avatar again')
 f.Data.Held=false;f.Rag.Value=false;f.Step(20,60)
 check(weld.Enabled and not f.Guard.Rig.Active and not f.Hum.Sit,'Released grab link or Sit flag remained latched')
 f.Guard:Dispose();f.Hum.Sit=true;check(f.Hum.Sit,'Disposed guard retained humanoid hooks')
end
print('PASS: '..count..' walking-rig, native cadence, gravity, cancellation and lifecycle assertions (mocked)')
