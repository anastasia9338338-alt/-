local checks=0
local function check(value,message)assert(value,message);checks+=1 end
local function fixture()
    local f={Now=0,Enabled=true,Owner=true,Marker=true,Ack=false,Calls={},Jobs={},Destroyed={},Reserved={}}
    f.World=newNode('Folder','Workspace')
    f.Inventory=newNode('Folder','Mine');f.Inventory.Parent=f.World
    f.Foreign=newNode('Folder','Other');f.Foreign.Parent=f.World
    f.Character=newNode('Model','Me');f.Character.Parent=f.World
    f.Humanoid=newNode('Humanoid','Humanoid');f.Humanoid.Health=100;f.Humanoid.Parent=f.Character
    f.Root=newNode('Part','HumanoidRootPart');f.Root.Parent=f.Character
    f.Target=newNode('Part','RagdollTouchedHitbox');f.Target.Parent=f.Root
    local function toy()
        local model=newNode('Model','NinjaShuriken');model.Parent=f.Inventory
        local sticky=newNode('Part','StickyPart');sticky.Parent=model
        sticky.CFrame=CFrame.new(3,6,9)
        local sound=newNode('Part','SoundPart');sound.Parent=model
        local weld=newNode('WeldConstraint','StickyWeld');weld.Part0=sticky;weld.Parent=sticky
        f.Model,f.Part,f.Sound,f.Weld=model,sticky,sound,weld
        return model
    end
    f.Items=Items.Install({
        Clock=function()return f.Now end,Enabled=function()return f.Enabled end,
        Character=function()return f.Character end,
        IsInventoryModel=function(model)return model and model.Parent==f.Inventory end,
        Spawn=function(id)check(id=='NinjaShuriken','Wrong selected toy');return toy()end,
        Destroy=function(model)f.Destroyed[model]=(f.Destroyed[model]or 0)+1;model:Destroy()end,
        Reserve=function(model,value)f.Reserved[model]=value or nil end,
        IsOwner=function()return f.Marker end,IsPhysicsOwner=function()return f.Owner end,
        Own=function(part,valid)
            check(part==f.Part,'Acquired unrelated item')
            if f.CheckValid then f.CheckValid(valid)end
            return f.Owner
        end,
        SpawnThread=function(fn)table.insert(f.Jobs,fn)end,
        ApplyOffset=function(part,target,offset)
            table.insert(f.Calls,{Part=part,Target=target,Time=f.Now})
            check(part==f.Part and target==f.Target,'Attachment escaped exact item or target')
            if f.Ack then
                local weld=part:FindFirstChild('StickyWeld')
                if weld then weld.Part0=part;weld.Part1=target end
            end
        end,
        Wait=function(dt)f.Now+=dt;if f.OnWait then f.OnWait()end end,
        Notify=function()end,
    })
    function f:Spawn()return self.Items:Spawn(self.Root)end
    function f:Step(seconds)
        local deadline=self.Now+seconds
        while self.Now<deadline do self.Now+=1/60;self.Items:Update(self.Now)end
    end
    return f
end
-- An unacknowledged send must never report protection or destroy every .5s.
do
    local f=fixture();f:Spawn()
    check(f.Reserved[f.Model]and f.Items:IsProtected(f.Part),'Spawned toy was not protected during attachment')
    check(not f.Items:Attach(f.Target,.5),'Remote send was counted as an acknowledged weld')
    check(not f.Destroyed[f.Model]and f.Model.Parent==f.Inventory,'Short attachment wait destroyed the pending defense')
    check(not f.Items:IsAttached(),'Unacknowledged item was reported attached')
    check(#f.Calls<=4,'Attachment flooded remotes during short wait')
    f.Ack=true;f:Step(.8)
    check(f.Items:IsAttached()and f.Items.ActiveModel==f.Model,'Acknowledged repair failed to preserve original toy')
    f.Items:Dispose();check(not f.Reserved[f.Model]and f.Destroyed[f.Model]==1,'Unload leaked toy/reservation or double-destroyed')
end
-- Our aura must protect exact identity, never another player's same-named toy.
do
    local f=fixture();f:Spawn();f.Ack=true;check(f.Items:Attach(f.Target,.3),'Fixture did not attach')
    local other=newNode('Model','ShurikenRSC');other.Parent=f.Foreign
    local otherPart=newNode('Part','StickyPart');otherPart.Parent=other
    check(f.Items:IsProtected(f.Model)and f.Items:IsProtected(f.Sound),'Exact active model protection ignored descendants')
    check(not f.Items:IsProtected(other)and not f.Items:IsProtected(otherPart),'Name-based exclusion protected another player')
    f.Model.Parent=f.Foreign
    check(not f.Items:IsProtected(f.Model),'Transferred toy kept defensive reservation identity')
    f:Step(.1);check(not f.Items.ActiveModel and not f.Destroyed[f.Model]and not f.Reserved[f.Model],'Invalid inventory toy was mutated or remained reserved')
end
-- Handle both real weld directions, disabled/broken welds, server replacement.
do
    local f=fixture();f:Spawn();f.Ack=true;check(f.Items:Attach(f.Target,.3),'Fixture did not attach')
    f.Weld.Part0=f.Target;f.Weld.Part1=f.Sound
    check(f.Items:IsAttached(),'Reversed real toy endpoint was rejected')
    f.Weld.Enabled=false;check(not f.Items:IsAttached(),'Disabled weld counted as protection');f.Weld.Enabled=true
    local before=f.Part.CFrame;f.Items:SetRotation('Y',45)
    check(f.Part.CFrame==before,'Changing pose rewrote local welded assembly')
    f.Weld:Destroy();f.Ack=false
    local calls=#f.Calls;f:Step(.2)
    check(#f.Calls>calls and not f.Items:IsAttached(),'Missing constraint was accepted or repair did not request server attachment')
    check(not f.Part:FindFirstChild('StickyWeld'),'Guard invented a local protection weld')
    local replacement=newNode('WeldConstraint','StickyWeld');replacement.Part0=f.Part;replacement.Parent=f.Part
    f.Ack=true;f:Step(.7)
    check(f.Items:IsAttached(),'Replicated replacement weld was not reacquired')
    f.Items:Dispose()
end
-- A malicious/irrelevant same-named weld is not a connection to the toy.
do
    local f=fixture();f:Spawn();local stranger=newNode('Part','Foreign');stranger.Parent=f.Foreign
    f.Weld.Part0=stranger;f.Weld.Part1=f.Target
    check(not f.Items:IsAttached(f.Target),'Wrong assembly endpoint counted as defense')
    f.Items:Dispose()
end
-- Ownership marker is insufficient; recovery is bounded and canceled on respawn.
do
    local f=fixture();f:Spawn();f.Ack=true;check(f.Items:Attach(f.Target,.3),'Fixture did not attach')
    f.Owner=false;f.Weld.Part1=nil;local calls=#f.Calls
    f:Step(.3);check(#f.Jobs==1 and #f.Calls>calls and f.Items:IsAttached(),'Delayed physics ownership blocked a genuine server attachment');calls=#f.Calls
    local old=f.Character;f.Character=newNode('Model','NewMe');f.Character.Parent=f.World
    f.CheckValid=function(valid)check(not valid(),'Ownership worker survived respawn')end
    f.Jobs[1]();f:Step(.1)
    check(not f.Items.ActiveModel and not f.Reserved[f.Model]and f.Destroyed[f.Model]==1,'Respawn retained old defense')
    check(#f.Calls==calls,'Canceled ownership worker sent attachment to previous character')
    f.Items:Dispose();check(f.Destroyed[f.Model]==1,'Dispose repeated destruction after respawn cleanup')
end
-- Physical ownership with a stale server marker still needs acquisition.
do
    local f=fixture();f:Spawn();f.Marker=false;f.Ack=true
    check(f.Items:Attach(f.Target,.1),'A genuine server weld was rejected while the marker was delayed')
    check(#f.Calls>0 and #f.Jobs==1 and not f.Items:_Owned(f.Part),'Transport was incorrectly gated on local ownership, or reported ownership without evidence')
    f.CheckValid=function(valid)check(valid(),'Current marker-repair ownership worker was canceled');f.Marker=true end
    f.Jobs[1]();f:Step(.2)
    check(f.Items:IsAttached()and #f.Calls>0,'Marker reacquisition failed to restore genuine attachment')
    f.Items:Dispose()
end
-- Single-callback contexts remain supported, but no evidence means no owner.
do
    for _,mode in ipairs({'marker','physics','none'})do
        local f=fixture();f:Spawn()
        if mode~='marker'then f.Items.Context.IsOwner=nil end
        if mode~='physics'then f.Items.Context.IsPhysicsOwner=nil end
        check(f.Items:_Owned(f.Part)==(mode~='none'),'Ownership callback compatibility failed for '..mode)
        f.Items:Dispose()
    end
end
-- No response: fixed repair deadline, bounded sends, no endless retention.
do
    local f=fixture();f:Spawn();check(not f.Items:Attach(f.Target,.3),'Unexpected fixture acknowledgement')
    f:Step(4)
    check(not f.Items.ActiveModel and f.Destroyed[f.Model]==1 and not f.Reserved[f.Model],'Failed repair did not release item at deadline')
    check(#f.Calls<=14,'Broken attachment caused an unbounded send loop')
    f.Items:Dispose()
end
-- A transport error retries the requested pose without moving the welded toy.
do
    local f=fixture();f:Spawn();f.Ack=true;check(f.Items:Attach(f.Target,.3),'Fixture did not attach')
    local apply=f.Items.Context.ApplyOffset;local failures=0
    f.Items.Context.ApplyOffset=function(...)
        failures+=1;if failures<=2 then error('Temporary transport failure')end
        return apply(...)
    end
    local before=f.Part.CFrame;f.Items:SetRotation('X',20);f:Step(.7)
    check(failures==3 and not f.Items.RemoteDirty and f.Part.CFrame==before,'Failed pose request was lost, flooded or moved the welded toy')
    f.Items:Dispose()
end
-- Server destruction releases stale reservation before the next spawn.
do
    local f=fixture();f:Spawn();local old=f.Model
    old:Destroy();f:Spawn()
    check(f.Model~=old and not f.Reserved[old] and f.Reserved[f.Model],'Server-destroyed toy leaked reservation during respawn')
    local again=f:Spawn();check(again==f.Model,'Concurrent outer retry duplicated active toy')
    f.Items:Dispose()
end
-- Respawn/unload during a yielding spawn rejects the old toy before adoption.
for _,mode in ipairs({'respawn','unload'})do
    local f=fixture()
    local original=f.Items.Context.Spawn
    f.Items.Context.Spawn=function(id,...)
        local model=original(id,...)
        model._WaitForChild=function(self,name,...)
            if mode=='respawn'then f.Character=newNode('Model','Respawn');f.Character.Parent=f.World
            else f.Items:Dispose()end
            return self:FindFirstChild(name)
        end
        return model
    end
    check(not f:Spawn(),'Stale yielding spawn was adopted after '..mode)
    check(not f.Items.ActiveModel and not f.Items.PendingModel and not f.Reserved[f.Model] and f.Destroyed[f.Model]==1,'Yielding '..mode..' leaked defense')
end
-- Death, toggle off and unload cancel ownership workers and clear reservations.
for _,mode in ipairs({'death','disable','unload'})do
    local f=fixture();f:Spawn();f.Ack=true;check(f.Items:Attach(f.Target,.3),'Fixture did not attach')
    f.Owner=false;f.Weld.Part1=nil;f:Step(.1);check(#f.Jobs==1,'Missing ownership job')
    local count=#f.Calls
    if mode=='death'then f.Humanoid.Health=0;f:Step(.1)
    elseif mode=='disable'then f.Enabled=false;f:Step(.1)
    else f.Items:Dispose()end
    f.Jobs[1]()
    check(not f.Items.ActiveModel and not f.Reserved[f.Model]and f.Destroyed[f.Model]==1,mode..' leaked defense')
    check(#f.Calls==count,mode..' worker sent a stale attachment')
end
-- A delayed ownership worker must not Unstick an attachment that the server
-- has already acknowledged while executor metadata is still stale.
do
 local f=fixture();f:Spawn();f.Owner=false;f.Marker=false;f.Ack=false
 f.Items:Attach(f.Target,.1);check(#f.Jobs==1,'Missing queued ownership retry fixture')
 local own=f.Items.Context.Own;local requests=0
 f.Items.Context.Own=function(...)requests+=1;return own(...)end
 f.Weld.Part0=f.Part;f.Weld.Part1=f.Target
 f.Jobs[1]();f:Step(1)
 check(requests==0 and #f.Jobs==1 and f.Items:IsAttached(),'Ownership health check detached or regrabbed a genuine current attachment')
 f.Items:Dispose()
end
print('PASS: '..checks..' anti-kick server-authorized attachment, delayed metadata, repair bounds and lifecycle assertions (mocked)')
