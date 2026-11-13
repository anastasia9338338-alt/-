local function test(name,fn)fn();print('PASS '..name)end
local Kick=modules.BlobmanKick
local function kickFixture()
    local f=fixture();f:SeatLocal();f.Log={};f.Teleports=0;f.TargetOwned=false;f.Ack=true;f.Selected=true
    f.Heartbeat.OnWait=function()f.Now+=.025;if f.WaitHook then f.WaitHook()end end
    f.Grab.OnFire=function(_,root,weld)
        f.Log[#f.Log+1]='Grab'
        if f.ThrowGrab then error('grab failed')end
        if f.Ack then weld.Attachment0=f.TAtt end
    end
    f.Drop.OnFire=function(weld)
        f.Log[#f.Log+1]='Drop'
        if f.ThrowDrop then error('drop failed')end
        weld.Attachment0=nil
    end
    f.Release.OnFire=function(weld)f.Log[#f.Log+1]='Release';if not f.DenyOwnership then f.TargetOwned=true end;weld.Attachment0=nil end
    local ctx={Clock=function()return f.Now end,Signal=f.Heartbeat,Character=f.Character,
        Current=function()return f.H.SeatPart==f.Seat and f.Seat.Occupant==f.H and f.Blob end,
        Components=function()return {CreatureGrab=f.Grab,CreatureDrop=f.Drop,CreatureRelease=f.Release,RightWeld=f.RightWeld,RightOri=f.Ori}end,
        Protected=function()return f.Protected end,Owned=function()return f.TargetOwned end,
        Approach=function()f.Log[#f.Log+1]='Approach';if f.ApproachHook then f.ApproachHook()end end,
        Grab=function()if not f.DenyOwnership then f.TargetOwned=true end end,ReleaseOwner=function()end,
        Ping=function()return .1 end,
        Cadence=modules.BlobmanCadence.new({Clock=function()return f.Now end,Signal=f.Heartbeat}),
        Teleport=function(root,goal)f.Teleports+=1;f.Log[#f.Log+1]='Teleport';root.CFrame=goal end,
        Align=function(root)
            f.Position=object('AlignPosition','Position',root);f.Orientation=object('AlignOrientation','Orientation',root)
            return f.Position,f.Orientation
        end,
        Reposition=function()end,ResetVelocity=function(root)root.AssemblyLinearVelocity=Vector3.zero end,
        Goal=function(avatar)return avatar.CFrame*CFrame.new(0,25,0)end,
        Method=function()return f.Method or 1 end,NetworkSpam=function()return false end,
        Ragdoll=function(c,valid)f.Ragdolls[#f.Ragdolls+1]={Character=c,Valid=valid}end}
    f.Kick=Kick.new(ctx);f.Valid=function()return f.Selected end
    return f
end
test('ordinary target grabbed without FirePlayerPart; cleanup exact',function()
    local f=kickFixture();local result=f.Kick:Run(f.Other,f.Valid,.15)
    expect('ordinary target accepted',result and not f.TR:FindFirstChild('FirePlayerPart'))
    expect('native grab before teleport',f.Log[1]=='Grab'and table.find(f.Log,'Teleport')>1)
    expect('exactly one initial placement',f.Teleports==1)
    expect('RootAttachment stays in root',f.TAtt.Parent==f.TR)
    expect('hand properties restored',f.RightWeld.Enabled and f.Ori.Enabled)
    expect('target rig restored',f.TMotor.Enabled and f.TR.CanCollide and f.TH.RequiresNeck)
    expect('hold objects removed',f.Position.Destroyed and f.Orientation.Destroyed and not f.Kick.Session)
end)
test('no acknowledged grab means no rig or movement changes',function()
    local f=kickFixture();f.Ack=false;f.TargetOwned=true
    local result=f.Kick:Run(f.Other,f.Valid,.15)
    expect('ownership alone not called a grab',not result and f.Teleports==0)
    expect('target untouched',f.TMotor.Enabled and f.TR.CanCollide and f.TAtt.Parent==f.TR)
    expect('retries bounded',#f.Log<=10 and f.Now<1);expect('hand restored',f.RightWeld.Enabled and not f.Kick.Session)
end)
test('ownership denial does not move another character',function()
    local f=kickFixture();f.DenyOwnership=true
    f.Kick:Run(f.Other,f.Valid,.1)
    expect('no teleport without physics ownership',f.Teleports==0)
    expect('ownership retry bounded',f.Now<1.5 and #f.Log<35)
    expect('attachment is never reparented',f.TAtt.Parent==f.TR)
end)
test('fake RootAttachment and protected targets are rejected',function()
    local f=kickFixture();f.TAtt:Destroy();f.TAtt=object('BoolValue','RootAttachment',f.TR)
    expect('fake attachment rejected',not f.Kick:Run(f.Other,f.Valid,.1)and #f.Log==0)
    local g=kickFixture();g.Protected=true
    expect('protected target rejected',not g.Kick:Run(g.Other,g.Valid,.1)and #g.Log==0)
end)
test('cancellation immediately after native acknowledgement releases hand',function()
    local f=kickFixture();f.WaitHook=function()f.Selected=false end
    f.Kick:Run(f.Other,f.Valid,.1)
    expect('pending grab released on cancellation',table.find(f.Log,'Drop')~=nil and f.RightWeld.Attachment0==nil)
    expect('no post-cancel teleport',f.Teleports==0 and not f.Kick.Session)
end)
test('respawn and disposal stop running hand loop',function()
    local f=kickFixture();f.WaitHook=function()if f.Teleports>0 then f.Other.Character=nil end end
    f.Kick:Run(f.Other,f.Valid,5)
    expect('target respawn cancels',f.Now<1 and not f.Kick.Session and f.Position.Destroyed)
    local g=kickFixture();g.WaitHook=function()if g.Teleports>0 then g.Kick:Dispose()end end
    g.Kick:Run(g.Other,g.Valid,5)
    expect('unload cleans hold',g.Now<1 and g.Kick.Closed and not g.Kick.Session and g.Position.Destroyed)
end)
test('one physical hand cannot run simultaneous target jobs',function()
    local f=kickFixture();local tried=false;local second
    f.WaitHook=function()if not tried then tried=true;second=f.Kick:Run(f.Other,f.Valid,.1)end end
    f.Kick:Run(f.Other,f.Valid,.1)
    expect('concurrent job rejected',tried and second==false)
end)
test('remote failure restores properties and unlocks hand',function()
    local f=kickFixture();f.ThrowDrop=true;f.Kick:Run(f.Other,f.Valid,.2)
    expect('release error reported',f.Kick.LastError~=nil)
    expect('release error still cleans hold',not f.Kick.Session and f.Position.Destroyed and f.Orientation.Destroyed)
    expect('release error restores target and hand',f.TMotor.Enabled and f.TR.CanCollide and f.RightWeld.Enabled)
end)
test('seated target requests ragdoll; optional orientation supported',function()
    local f=kickFixture();f.TH.SeatPart=object('Seat','OtherSeat',f.World)
    expect('seated target deferred',not f.Kick:Run(f.Other,f.Valid,.1)and #f.Ragdolls==1 and f.Teleports==0)
    local g=kickFixture();g.Kick.Context.Components=function()return {CreatureGrab=g.Grab,CreatureDrop=g.Drop,RightWeld=g.RightWeld}end
    g.TargetOwned=true
    expect('optional align and release not required',g.Kick:Run(g.Other,g.Valid,.1))
end)
test('cadence settings reject nonfinite values and wait physics',function()
    local now=0;local s=signal();local steps=0
    s.OnWait=function()steps+=1;now+=1/240 end
    local cadence=modules.BlobmanCadence.new({Clock=function()return now end,Signal=s})
    cadence:SetSpeed(0/0);expect('NaN ignored',cadence.Speed==30)
    cadence:SetSpeed(999);expect('speed clamped',cadence.Speed==60)
    expect('half-cycle waits real callbacks',cadence:Half(function()return true end)and steps>=2)
end)

