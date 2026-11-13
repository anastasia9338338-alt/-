
local function test(name,fn)fn();print('PASS '..name)end
local Defense=modules.BlobmanDefense
test('passive startup and immediate seat observation',function()
    local f=fixture();local d=Defense.Install(f.DefenseContext);d:Step()
    expect('defaults are off',not d.Aura and not d.Banana and not d.RemoveArms)
    expect('no startup spawn',f.Spawns==0 and #f.Ragdolls==0)
    d:SetMode('Aura',true);d:Step();f:SeatOther()
    expect('occupant event requests ragdoll immediately',#f.Ragdolls==1 and f.Ragdolls[1].Character==f.TC)
    expect('request predicate current',f.Ragdolls[1].Valid())
    f.TH.SeatPart=nil;f.Seat.Occupant=nil
    expect('leaving seat cancels pending ragdoll',not f.Ragdolls[1].Valid())
    d:Dispose();expect('pre-simulation disconnected',not d.Connection.Connected)
end)
test('radius, own rider, protected rider and player respawn',function()
    local f=fixture();local d=Defense.Install(f.DefenseContext);d:SetMode('Aura',true)
    f.Protected=true;f:SeatOther();d:Step();expect('protected rider skipped',#f.Ragdolls==0)
    f.Protected=false;f.R.Position=Vector3.new(1000,0,0);f.Now=1;d:Step();expect('distant rider skipped',#f.Ragdolls==0)
    f.R.Position=Vector3.zero;f:SeatLocal();d:Step();expect('own rider skipped',#f.Ragdolls==0)
    f:SeatOther();f.Now=2;d:Step();local request=f.Ragdolls[#f.Ragdolls]
    expect('rider acquired',request and request.Valid())
    f.Other.Character=object('Model','Replacement',f.World)
    expect('stale character predicate rejected',not request.Valid());d:Dispose()
end)
test('arm removal is reversible and follows streamed parts',function()
    local f=fixture();f:SeatOther();local d=Defense.Install(f.DefenseContext)
    d:SetMode('RemoveArms',true);d:Step()
    expect('detectors unparented from Blobman',f.Left.Parent==d.Storage and f.Right.Parent==d.Storage)
    expect('seat and body preserved',f.Seat.Parent==f.Blob and f.Body.Parent==f.Blob)
    local hand=object('Part','RightHand',f.Blob);f.Now=1;d:Step()
    expect('newly streamed hand removed',hand.Parent==d.Storage)
    d:SetMode('RemoveArms',false)
    expect('exact instances restored',f.Left.Parent==f.Blob and f.Right.Parent==f.Blob and hand.Parent==f.Blob)
    expect('grab constraint not destroyed',f.RightWeld.Parent==f.Right and not f.RightWeld.Destroyed)
    d:Dispose()
end)
test('arm restoration on range exit and model deletion',function()
    local f=fixture();f:SeatOther();local d=Defense.Install(f.DefenseContext);d:SetMode('RemoveArms',true);d:Step()
    f.R.Position=Vector3.new(1000,0,0);f.Now=1;d:Step();expect('leaving radius restores arms',f.Right.Parent==f.Blob)
    f.R.Position=Vector3.zero;f.Now=2;d:Step();f.Blob:Destroy();f.Now=3;d:Step()
    expect('deleted model not resurrected',f.Right.Destroyed and f.Right.Parent==nil);d:Dispose()
end)
test('hidden detectors still release native grabs of the local avatar',function()
    local f=fixture();f:SeatOther();local d=Defense.Install(f.DefenseContext);d:SetMode('RemoveArms',true);d:Step()
    local drops=0;f.Drop.OnFire=function()drops+=1 end
    local a=modules.BlobmanAura.Install({RunService=f.RunService,Clock=function()return f.Now end,
        Character=f.Character,Enabled=function()return d.RemoveArms end,Models=function()return {f.Blob}end,
        Detector=function(model,side)
            for obj,saved in pairs(d.Hidden)do if saved.Model==model and obj.Name==side..'Detector'then return obj end end
        end})
    a:Step();f.RightWeld.Attachment0=f.Att
    expect('native grab suppressed after arms hidden',drops==1 and not f.RightWeld.Enabled and a:IsNear())
    d:SetMode('RemoveArms',false);a:Step()
    expect('hidden detector suppression restored',f.Right.Parent==f.Blob and f.RightWeld.Enabled and f.Right.CanTouch)
    a:Dispose();d:Dispose()
end)
test('one prepared real banana; spin and cleanup',function()
    local f=fixture();local d=Defense.Install(f.DefenseContext);d:SetMode('Banana',true)
    d:Step();expect('only one preparation job',#f.Jobs==1)
    f:RunJobs();expect('banana spawned and eaten once',f.Spawns==1 and f.Eats==1 and d.Prepared~=nil)
    expect('prepared peel reserved and harmless',f.Reserved[f.LastBanana] and not f.Peel.CanTouch and not f.Peel.CanCollide)
    f:SeatOther();d:Step()
    expect('spinning inside actual Blobman',d.Session~=nil and(f.Peel.Position-f.Body.Position).Magnitude<1)
    expect('high angular velocity on peel',f.Peel.AssemblyAngularVelocity.Magnitude>2000)
    expect('no direct velocity write to Blobman',f.Body.AssemblyLinearVelocity==Vector3.new(3,2,1))
    local mover=d.Session.Mover;local links=table.clone(d.Session.Links)
    expect('own avatar excluded from peel collisions',#links>0)
    f.Now=1.3;d:Step();expect('spin stops at configured duration',d.Session==nil and mover.Destroyed)
    expect('peel stopped and parked',f.Peel.AssemblyAngularVelocity==Vector3.zero and not f.Peel.CanTouch)
    expect('physics restored after spin',f.Peel.CustomPhysicalProperties==nil)
    for _,link in ipairs(links)do expect('self collision link removed',link.Destroyed)end
    d:SetMode('Banana',false)
    expect('owned banana deleted on disable',f.Destroyed==1 and f.LastBanana.Destroyed and f.Reserved[f.LastBanana]==nil)
    d:Dispose()
end)
test('banana preparation cancellation before spawn',function()
    local f=fixture();local d=Defense.Install(f.DefenseContext);d:SetMode('Banana',true);d:SetMode('Banana',false);f:RunJobs()
    expect('canceled worker never spawns',f.Spawns==0 and not d.Prepared and not d.Preparing);d:Dispose()
end)
test('banana cancellation while eating',function()
    local f=fixture();local d=Defense.Install(f.DefenseContext)
    f.EatHook=function(model)d:SetMode('Banana',false);return model end
    d:SetMode('Banana',true);f:RunJobs()
    expect('late eaten model cleaned',f.Destroyed==1 and not d.Prepared and not d.Preparing)
    expect('late reservation released',next(f.Reserved)==nil);d:Dispose()
end)
test('foreign connected assembly rejected',function()
    local f=fixture();local d=Defense.Install(f.DefenseContext)
    f.SpawnHook=function(_,root)root.ConnectedParts={f.R}end
    d:SetMode('Banana',true);f:RunJobs()
    expect('peel attached to avatar refused',not d.Prepared and f.Destroyed==1);d:Dispose()
end)
test('spin cancellation for protected player and lost ownership',function()
    local f=fixture();local d=Defense.Install(f.DefenseContext);d:SetMode('Banana',true);f:RunJobs();f:SeatOther();d:Step()
    f.Protected=true;d:Step();expect('protection change stops spin',not d.Session)
    f.Protected=false;f.Now=3;d:Step();expect('spin may restart after cooldown',d.Session~=nil)
    f.Owned=false;d:Step();expect('lost ownership stops spin',not d.Session);d:Dispose()
end)
test('banana released on local respawn',function()
    local f=fixture();local d=Defense.Install(f.DefenseContext);d:SetMode('Banana',true);f:RunJobs();f:SeatOther();d:Step()
    f.Player.Character=nil;d:Step()
    expect('respawn clears old spin and peel',not d.Session and not d.Prepared and f.Destroyed==1);d:Dispose()
end)
local Guard=modules.AntiExplore
local function explore(f)
    return Guard.Install({RunService=f.RunService,Workspace=f.World,Clock=function()return f.Now end,
        Character=f.Character,Blocked=function()return f.Blocked end,Recover=function()f.Recovers+=1 end})
end
test('Anti Explore preserves legs, motor and HipHeight',function()
    local f=fixture();local g=explore(f)
    local banana=object('Model','FoodBanana',f.Toys);local hit=object('Part','HitboxPart',banana)
    f.Rag.Value=true;f.Motor.Enabled=false;f.H.State='Ragdoll';f.H.PlatformStand=true
    g:SetEnabled(true);g:Step()
    expect('legs intact',f.Leg.Parent==f.C and not f.Leg.Destroyed)
    expect('walking joint recovers',f.Motor.Enabled and f.H.State=='Running'and not f.H.PlatformStand)
    expect('HipHeight unchanged',f.H.HipHeight==0)
    expect('banana touch suppressed',not hit.CanTouch and next(g.Parts)~=nil)
    expect('native recovery requested',f.Recovers==1)
    g:Step();expect('native recovery throttled',f.Recovers==1)
    g:SetEnabled(false);expect('hazard touch restored',hit.CanTouch and next(g.Parts)==nil)
    expect('legs still intact after disable',f.Leg.Parent==f.C and f.H.HipHeight==0);g:Dispose()
end)
test('Anti Explore filters hazards and reverses changes',function()
    local f=fixture();local g=explore(f)
    local snow=object('Model','BallSnowball',f.Toys);local s=object('Part','Main',snow)
    local blast=object('Part','Part',f.World)
    local prop=object('Part','Box',f.Toys)
    local untouched=object('Part','AlreadyDisabled',snow);untouched.CanTouch=false
    g:SetEnabled(true);g:Step()
    expect('snowball and blast suppressed',not s.CanTouch and not blast.CanTouch)
    expect('ordinary props untouched',prop.CanTouch)
    f.R.Position=Vector3.new(1000,0,0);f.Now=1;g:Step()
    expect('range exit restores touches',s.CanTouch and blast.CanTouch and not untouched.CanTouch)
    g:Dispose();expect('all links removed',next(g.Parts)==nil)
end)
test('Anti Explore blocks nearby explosion impulse without height lock',function()
    local f=fixture();local g=explore(f);object('Part','Part',f.World)
    g:SetEnabled(true);g:Step();f.R.AssemblyLinearVelocity=Vector3.new(400,500,0);f.Now=.02;g:Step()
    expect('sudden explosion impulse cleared',f.R.AssemblyLinearVelocity==Vector3.zero)
    expect('root remains unanchored',not f.R.Anchored and f.H.HipHeight==0);g:Dispose()
end)
test('Anti Explore respects seats and clears on respawn',function()
    local f=fixture();local g=explore(f);f:SeatLocal();f.Rag.Value=true;f.H.Sit=true
    g:SetEnabled(true);g:Step();expect('vehicle seating preserved',f.H.Sit and f.H.SeatPart==f.Seat)
    f.Player.Character=nil;g:Step();expect('rig unbound on respawn',g.Character==nil and g.Rig.Character==nil);g:Dispose()
end)
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

test('default theme retains gradient and popup scheme keys',function()
    local typeof=type
    local Color3={fromHex=function(value)return value end}
    local Enum={Font={BuilderSans='BuilderSans',Code='Code'}}
    local Font={fromEnum=function(value)return value end}
    local SchemeIndexes={'BackgroundColor','MainColor','FontColor'}
    local Library={Scheme={HeaderColor='header',BodyTopColor='top',BodyBottomColor='bottom',CheckColor='check',
        PopupColor='popup',PopupTextColor='text',PopupOutlineColor='outline',PopupRowColor='row',
        RedColor='red',DarkColor='dark',WhiteColor='white',DestructiveColor='danger'}}
    local updates=0
    function Library:UpdateColorsUsingRegistry()
        updates+=1
        expect('gradient survives before registry refresh',self.Scheme.BodyTopColor~=nil and self.Scheme.BodyBottomColor~=nil)
        expect('popup colors survive before registry refresh',self.Scheme.PopupColor~=nil and self.Scheme.PopupTextColor~=nil)
    end
    local ThemeManager={Library=Library,BuiltInThemes={Default={1,{BackgroundColor='#111111',MainColor='#222222',FontColor='#ffffff'}}}}
    __THEME_FUNCTION__
    ThemeManager:SetDefaultTheme({BackgroundColor='#010101',MainColor='#020202',FontColor='#fdfdfd',FontFace='BuilderSans'})
    expect('one registry refresh',updates==1)
    expect('standard colors change',Library.Scheme.BackgroundColor=='#010101'and Library.Scheme.FontColor=='#fdfdfd')
    expect('custom theme keys retained',Library.Scheme.HeaderColor=='header'and Library.Scheme.PopupRowColor=='row')
end)
test('settings popup has opaque background and readable controls',function()
    local Library={Registry={},Scheme={PopupColor='popup',PopupTextColor='text',PopupRowColor='row',PopupOutlineColor='outline'}}
    local function FillInstance(values,node)
        Library.Registry[node]=Library.Registry[node]or{}
        for key,value in pairs(values)do
            node[key]=type(value)=='string'and(Library.Scheme[value]or value)or value
            Library.Registry[node][key]=value
        end
    end
    __POPUP_FUNCTION__
    local frame=object('Frame','ControlSettings');frame.Visible=false
    local stroke=object('UIStroke','Border',frame)
    local label=object('TextLabel','Caption',frame);Library.Registry[label]={TextColor3='FontColor'}
    local row=object('TextButton','Setting',frame);Library.Registry[row]={BackgroundColor3='MainColor',TextColor3='FontColor'}
    local risky=object('TextLabel','Risky',frame);risky.TextColor3='red';Library.Registry[risky]={TextColor3='RedColor'}
    Library:StylePopup(frame)
    expect('opaque active popup',frame.BackgroundTransparency==0 and frame.Active and frame.BackgroundColor3=='popup')
    expect('clear popup boundary',stroke.Color=='outline'and stroke.Thickness==2)
    expect('caption and controls readable',label.TextColor3=='text'and row.TextColor3=='text'and row.BackgroundColor3=='row')
    expect('risk color preserved',risky.TextColor3=='red')
    expect('styling does not open settings',frame.Visible==false)
end)

print('ALL CHECKS PASSED: '..checks)
