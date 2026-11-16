for _,fps in ipairs({20,60,240})do
 local f=fixture(Pallet);f.Target.Torso.Name='HumanoidRootPart'
 local log={};local open=false
 f.Pallet.Context.NativeTouch=function(sound,root,phase)
  check(sound==f.Sound and root==f.Target.Torso,'Source touch used the wrong real parts')
  if phase==0 then check(not open,'Source contact began before the previous one ended');open=true
  else check(open,'Source emitted an unmatched contact end');open=false end
  log[#log+1]={Phase=phase,Frame=f.Pallet.PhysicsFrame}
 end
 f.Pallet:Bind(f.Model)
 for _=1,fps do f.Pallet:SourceContact(f.Target.Character,f.Valid);f.Sim:Tick(1/fps)end
 f.Pallet:Cancel(f.Target.Character);check(not open,'Cancellation left native source contact open')
 for i=1,#log-1,2 do check(log[i].Phase==0 and log[i+1].Phase==1 and log[i+1].Frame>=log[i].Frame,'Source contact order was corrupted')end
 local count=#log;f.Data.Valid=false;f.Pallet:SourceContact(f.Target.Character,f.Valid)
 check(#log==count,'Cancelled source started a new touch')
 f.Data.Valid=true;f.Sim:Run(.2,fps);f.Pallet:SourceContact(f.Target.Character,f.Valid);f.Pallet:Dispose()
 check(not open,'Unload left a native contact active');f.Sim:Run(.2,fps)
 check(not open,'A late contact callback reopened after unload')
end
print('PASS: '..checks..' source pallet real-part routing, paired contacts, frame ordering and cancellation checks (mocked; no server hit claim)')
