local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local world=Instance.new('Folder');local c=Instance.new('Model',world)
local root=Instance.new('Part',c);root.Name='HumanoidRootPart'
local torso=Instance.new('Part',c);torso.Name='Torso';torso.CustomPhysicalProperties={Native=true}
local motor=Instance.new('Motor6D',torso);motor.Enabled=false
local socket=Instance.new('BallSocketConstraint',torso);socket.Enabled=true
local weld=Instance.new('WeldConstraint',root);weld.Name='WeldHRP';weld.Part0=root;weld.Part1=torso;weld.Enabled=true
local player={};local nativeMass=torso.CustomPhysicalProperties
local collisions=__COLLISIONS__
local ctx={Clock=function()return 0 end,PreserveCharacterRig=true,Collisions=collisions,
 Limbs=function()error('Kick rewrote limb positions/velocities')end,
 RestoreMotors=function()error('Cleanup rewrote untouched native motors')end,CancelRagdoll=function()end}
local session={Player=player,Character=c,Root=root,Requested=false}
session.Position=Instance.new('BodyPosition',root);session.Orientation=Instance.new('BodyGyro',root)
local loop=setmetatable({Context=ctx,Sessions={[player]=session},Cleanup={},Released=0},Loop)
loop:Physics(session)
check(weld.Enabled and not motor.Enabled and socket.Enabled,'Physical holding changed native root coupling or ragdoll joints')
check(not torso.CanCollide and torso.CustomPhysicalProperties==nativeMass,'Collision suppression changed native body mass/material')
local late=Instance.new('Part',torso);late.Name='RagdollLimbPart';late.CanCollide=true
loop:Physics(session)
check(not late.CanCollide and session.Physics[late].CanCollide==true,'Late native collider was not snapshotted before suppression')
local changed={GameChanged=true};torso.CustomPhysicalProperties=changed
loop:Remove(player)
check(torso.CanCollide and late.CanCollide,'Cleanup did not restore initial and late colliders')
check(torso.CustomPhysicalProperties==changed and weld.Enabled and not motor.Enabled and socket.Enabled,'Cleanup overwrote current mass, root weld or native ragdoll state')
check(not session.Position.Parent and not session.Orientation.Parent and not next(loop.Cleanup),'Physical holding movers or cleanup record leaked')
local character,valid={},function()return true end
local calls=0;local entry={}
local tbl12={PalletRagdoll={Maintain=function(_,c,predicate)check(c==character and predicate==valid,'Physical route lost target identity/cancellation');calls+=1;return entry end,
 SourceContact=function()error('Kick used synthetic SourceContact instead of physical worker')end}}
local route=__ROUTE__
check(route(character,valid)==entry and calls==1,'Main kick did not route to the physical worker')
local contact=false
local tbl7={States={Owning=false}}
local tbl12={PalletRagdoll={Preparing=false,Ownership={InFlight=false},IsContactActive=function()return contact end}}
local busy=__OWNERSHIP_BUSY__
check(not busy(),'Idle board reserved target ownership requests')
contact=true;check(busy(),'Physical crossing did not reserve the shared ownership channel')
contact=false;check(not busy(),'Finished crossing retained the shared channel')
print('PASS: '..checks..' actual physical kick routing, native mass/joints, late-collider restoration and unload checks (mocked)')
