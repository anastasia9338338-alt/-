-- Preserve the user's v5 underfoot-lock implementation, not the older board mover.
local checks=0;local function check(value,message)assert(value,message);checks+=1 end
local world=newNode('Folder');local c=newNode('Model');c.Parent=world
local root=newNode('Part');root.Parent=c;local hum={Health=100}
local board=newNode('Part');board.Parent=world;board.Position=Vector3.new(4,1,7)
local heartbeat=signal();local current=c;local blocked=false
local magnet=Magnet.Install({RunService={Heartbeat=heartbeat},Character=function()return current,root,hum end,
    UnderFeet=function()return board end,Blocked=function()return blocked end})
check(magnet:SetEnabled(true)and magnet.Session.Part==board,'Underfoot lock did not activate on the selected part')
heartbeat:Fire()
check((root.Position-(board.Position+Vector3.new(0,3.5,0))).Magnitude<1e-6,'Uploaded underfoot offset changed')
check(root.AssemblyLinearVelocity.Magnitude==0 and root.AssemblyAngularVelocity.Magnitude==0,'Uploaded lock no longer cancels root velocity')
local connection=magnet.Connection;magnet:SetEnabled(true)
check(magnet.Connection==connection,'Repeated activation duplicated its frame listener')
board.Position=Vector3.new(8,2,-3);heartbeat:Fire()
check((root.Position-(board.Position+Vector3.new(0,3.5,0))).Magnitude<1e-6,'Moving part was not followed')
magnet:SetEnabled(false);check(not connection.Connected and not magnet.Session,'Disabling underfoot lock retained its listener/session')
hum.SeatPart={};check(not magnet:SetEnabled(true),'A seated character entered underfoot lock');hum.SeatPart=nil
blocked=true;check(not magnet:SetEnabled(true),'A blocked character entered underfoot lock');blocked=false
magnet:SetEnabled(true);current=newNode('Model');current.Parent=world;heartbeat:Fire()
check(not magnet.Enabled and not magnet.Session,'Respawn kept an old underfoot session')
current=c;magnet:SetEnabled(true);board:Destroy();heartbeat:Fire()
check(not magnet.Enabled,'Destroyed part remained locked')
magnet:Dispose();check(not magnet:SetEnabled(true),'Disposed underfoot lock restarted')
print('PASS: '..checks..' uploaded underfoot-lock offset, activation, velocity, movement and lifecycle checks (mocked)')
