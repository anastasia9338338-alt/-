-- The uploaded v5 base uses native Hold/Drop, not the obsolete local Break API.
local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local world=newNode('Folder');local character=newNode('Model');character.Parent=world
local actor=newNode('Model');actor.Parent=world
local hand=newNode('Part','LeftHand');hand.Parent=character
local actorHand=newNode('Part','RightHand');actorHand.Parent=actor
local root=newNode('Part','HumanoidRootPart');root.Parent=actor
local hum=newNode('Humanoid');hum.Health=100;hum.Parent=actor
local targetHum=newNode('Humanoid');targetHum.Health=100;targetHum.Parent=character
local targetGrip=newNode('Attachment');targetGrip.Parent=hand
local actorGrip=newNode('Attachment');actorGrip.Parent=actorHand
local foreign=newNode('Model');foreign.Parent=world;local foreignGrip=newNode('Attachment');foreignGrip.Parent=foreign
local inventory=newNode('Folder');inventory.Parent=world
local calls={};local queue={};local now=0
local function item(name,grip,enabled,incomplete)
    local model=newNode('Model',name);model.Parent=inventory
    local hold=newNode('Part','HoldPart');hold.Parent=model
    local rigid=newNode('RigidConstraint','RigidConstraint');rigid.Attachment1=grip;rigid.Enabled=enabled;rigid.Parent=hold
    local holdRemote=newNode('RemoteFunction','HoldItemRemoteFunction');holdRemote.Parent=hold
    function holdRemote:InvokeServer(actual,actualActor)
        check(actual==model and actualActor==actor,'Hold used the wrong source arguments')
        calls[#calls+1]='hold';rigid.Attachment1=actorGrip;return true
    end
    if not incomplete then
        local drop=newNode('RemoteFunction','DropItemRemoteFunction');drop.Parent=hold
        function drop:InvokeServer(actual,frame,velocity)
            check(actual==model and typeof(frame)=='CFrame'and velocity.Magnitude==0,'Drop did not use the native model/pose/velocity arguments')
            check(rigid.Attachment1==actorGrip,'Drop was called before the grip acknowledgement')
            calls[#calls+1]='drop';rigid.Attachment1=nil;return true
        end
    end
    return model,hold,rigid
end
local a,holdA=item('FoodHamburger',targetGrip,true)
local b,holdB,rigidB=item('FoodPizza',targetGrip,false)
local c=item('FoodBanana',nil,true)
local _,foreignHold=item('ForeignFood',foreignGrip,true)
local _,incompleteHold=item('Incomplete',targetGrip,true,true)
function hand:GetConnectedParts()return{holdA,holdB,holdA,foreignHold,incompleteHold}end
local ctx={Clock=function()return now end,Character=function()return character,nil,targetHum end,
    LocalCharacter=function()return actor,root,hum end,Inventory=function()return inventory end,
    SpawnThread=function(fn)queue[#queue+1]=fn end,
    Wait=function()now+=.05;local fn=table.remove(queue,1);if fn then fn()end end}
local remover=Remover.Install(ctx);local found=remover:Collect(character)
check(#found==3,'Native collector lost an attached/disabled/inventory food or included a foreign/incomplete item')
local player={};check(remover:Apply(player),'Hold/grip acknowledgement/Drop did not remove all input shields')
check(#calls==6 and calls[1]=='hold'and calls[2]=='drop','Food removal did not complete native transactions')
check(rigidB.Enabled==false and holdB:FindFirstChild('DropItemRemoteFunction'),'Removal changed a constraint locally or destroyed a remote')
now+=1;calls={};remover:Request(player,function()return false end);remover:Request(player)
check(#queue==1,'Pending native food requests duplicated')
table.remove(queue,1)();check(#calls==0,'Cancelled native food request executed')
now+=1;remover:Request(player);remover:Dispose();table.remove(queue,1)()
check(#calls==0 and not next(remover.Pending),'Unloaded food removal restarted')
print('PASS: '..checks..' uploaded native food Hold/Drop acknowledgements, collection, remote preservation and cancellation checks (mocked)')
