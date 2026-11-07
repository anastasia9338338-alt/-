local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local world=newNode('Folder');local c=newNode('Model');c.Parent=world;local other=newNode('Model');other.Parent=world
local left=newNode('Part','LeftHand');left.Parent=c;local right=newNode('Part','RightHand');right.Parent=c
local held=newNode('Attachment');held.Parent=left;local foreign=newNode('Attachment');foreign.Parent=other
local inv=newNode('Folder');inv.Parent=world;local player={};local now=0;local queue={};local calls={}
local function item(attachment,enabled,valid)
 local model=newNode('Model');model.Parent=inv;local hold=newNode('Part','HoldPart');hold.Parent=model
 local rigid=newNode('RigidConstraint','RigidConstraint');rigid.Enabled=enabled;rigid.Attachment1=attachment;rigid.Parent=hold
 newNode('RemoteFunction','HoldItemRemoteFunction').Parent=hold
 if valid~=false then newNode('RemoteFunction','DropItemRemoteFunction').Parent=hold end
 return model,hold
end
local food,a=item(held,true);local _,b=item(foreign,true);local _,d=item(held,false);local _,e=item(held,true,false)
function left:GetConnectedParts()return {a,b,d,e}end;function right:GetConnectedParts()return {a}end
local removed=Remover.Install({Character=function()return c end,Clock=function()return now end,Inventory=function()return inv end,
 SpawnThread=function(fn)queue[#queue+1]=fn end,Break=function(model,timeout,force,valid)
  check(model==food and timeout==.6 and force and valid(),'Wrong/native food break arguments');calls[#calls+1]=model
 end})
local found=removed:Collect(c);check(#found==1 and found[1]==food,'Collection included foreign/detached/incomplete or duplicate food')
removed:Request(player);removed:Request(player);check(#queue==1,'Pending food workers duplicated');queue[1]()
check(#calls==1,'Food was not processed');removed:Request(player);check(#queue==1,'Food requests ignored cooldown')
now=1;removed:Request(player,function()return false end);queue[2]();check(#calls==1,'Canceled food request executed')
now=2;removed:Request(player);c=newNode('Model');c.Parent=world;queue[3]();check(#calls==1,'Queued food request followed respawn')
now=3;removed:Request(player);removed:Dispose();queue[4]();check(#calls==1,'Unload did not cancel queued food request')
print('PASS: '..checks..' food shield native protocol, R15, deduplication and cancellation checks (mocked)')
