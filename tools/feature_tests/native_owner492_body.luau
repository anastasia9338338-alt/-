function CFMethods:GetComponents()return self.X,self.Y,self.Z,table.unpack(self.R)end
local world=newNode('Folder');local c=newNode('Model');c.Parent=world
local actor=newNode('Part');actor.Parent=c;local h=newNode('Humanoid');h.Health=100
local part=newNode('Part');part.Parent=world;part.Position=Vector3.new(0,15,0)
local flag11=false;local sent=0
local tbl12={Char=function()return c,actor,h end}
local tbl11={SetNetworkOwner={FireServer=function(_,target,frame)
 assert(target==part and frame==part.CFrame,'Source ownership did not use the native part/CFrame argument pair');sent+=1
end}}
__ACTUAL_REQUEST__
assert(tbl12.RequestNativeOwnership(part)==true and sent==1,'Source native request was blocked')
part.Position=Vector3.new(100,0,0)
assert(tbl12.RequestNativeOwnership(part)==false and sent==1,'Out-of-range source request was sent')
part.CFrame=CFrame.Angles(0/0,0,0)
assert(tbl12.RequestNativeOwnership(part)==false and sent==1,'Nonfinite source request reached the remote')
part.CFrame=CFrame.new(0,10,0);h.Health=0
assert(tbl12.RequestNativeOwnership(part)==false and sent==1,'Dead actor sent a source ownership request')
h.Health=100;flag11=true
assert(tbl12.RequestNativeOwnership(part)==false and sent==1,'Unloaded script sent a source ownership request')
print('PASS: actual Main source ownership argument shape, distance, finite frames, death and unload checks (mocked)')
