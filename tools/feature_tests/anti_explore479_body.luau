
local Guard=modules.AntiExplore
local function setup()
    local f=fixture();f.Held=false;f.Walking=false;f.Recovers=0
    f.H.WalkSpeed=16;f.R.AssemblyLinearVelocity=Vector3.new(4,0,2)
    local ctx={RunService=f.RunService,Workspace=f.World,Clock=function()return f.Now end,
        Character=f.Character,Recover=function()f.Recovers+=1 end,
        Held=function()return f.Held end,WalkingGuard=function()return f.Walking end,
        Ignore=function(part)return part:IsDescendantOf(f.Inventory)end,
        Blocked=function()return f.Blocked end}
    local g=Guard.Install(ctx)
    local banana=object('Model','FoodBanana',f.Toys)
    local peel=object('Part','HitboxPart',banana)
    f.Banana=banana;f.Peel=peel
    return f,g
end
local function test(name,fn)fn();print('PASS '..name)end
test('touch protection preserves walking physics and intact legs',function()
    local f,g=setup();local motor=f.Motor.Enabled;local state=f.H:GetState()
    g:SetEnabled(true);g:Step()
    expect('native food touch suppressed',not f.Peel.CanTouch and next(g.Parts)~=nil)
    expect('walking velocity preserved',f.R.AssemblyLinearVelocity==Vector3.new(4,0,2))
    expect('rig and Humanoid left alone',f.Motor.Enabled==motor and f.H:GetState()==state and f.H.WalkSpeed==16 and f.H.HipHeight==0)
    expect('legs intact',f.Leg.Parent==f.C)
    g:SetEnabled(false)
    expect('touch restored',f.Peel.CanTouch and next(g.Parts)==nil)
    g:Dispose();expect('event listener removed',not g.Connection.Connected)
end)
test('external grab owns all avatar motion and state',function()
    local f,g=setup();f.Held=true;f.Rag.Value=true;f.H.State='Ragdoll';f.Motor.Enabled=false
    f.H.PlatformStand=true;f.H.AutoRotate=false
    local rootWrites=0
    f.R.Changed:Connect(function(key)
        if key=='CFrame'or key=='Position'or key=='AssemblyLinearVelocity'or key=='AssemblyAngularVelocity'then rootWrites+=1 end
    end)
    g:SetEnabled(true)
    for i=0,30 do f.Now=i*.05;g:Step()end
    expect('no native ragdoll request while held',f.Recovers==0)
    expect('no root physics writes while held',rootWrites==0)
    expect('no local stand or joint changes',f.H.State=='Ragdoll'and not f.Motor.Enabled and f.H.PlatformStand and not f.H.AutoRotate)
    expect('no slowdown property lock',f.H.WalkSpeed==16 and f.H.HipHeight==0)
    f.Held=false;f.Now=2;g:Step()
    expect('stale held trip not replayed after release',f.Recovers==0)
    g:Dispose()
end)
test('another walking guard is never duplicated',function()
    local f,g=setup();f.Walking=true;f.Rag.Value=true;f.H.State='Ragdoll';f.Motor.Enabled=false
    g:SetEnabled(true)
    for i=0,20 do f.Now=i*.05;g:Step()end
    expect('native recovery yielded to walking guard',f.Recovers==0)
    expect('joint state untouched',not f.Motor.Enabled and f.H.State=='Ragdoll')
    f.Walking=false;f.Now=2;g:Step();expect('shared trip not replayed',f.Recovers==0)
    g:Dispose()
end)
test('fresh hazard trip requests bounded native clears',function()
    local f,g=setup();g:SetEnabled(true);g:Step()
    f.Rag.Value=true;f.H.State='Ragdoll';f.Motor.Enabled=false
    for i=1,40 do f.Now=i*.05;g:Step()end
    expect('only three clear attempts per trip',f.Recovers==3)
    expect('no duplicate walking rig',g.Rig==nil)
    expect('no local motor/velocity hacks',not f.Motor.Enabled and f.R.AssemblyLinearVelocity==Vector3.new(4,0,2))
    f.Rag.Value=false;f.H.State='Running';f.Now=3;g:Step()
    f.Rag.Value=true;f.Now=3.1;g:Step();expect('new actual trip may recover',f.Recovers==4)
    g:Dispose()
end)
test('held transition cancels retries immediately',function()
    local f,g=setup();g:SetEnabled(true);f.Rag.Value=true;g:Step()
    expect('first unheld hazard clear',f.Recovers==1)
    f.Held=true
    for i=1,30 do f.Now=i*.1;g:Step()end
    expect('no held follow-up request',f.Recovers==1 and g.Trip==nil)
    g:Dispose()
end)
test('ordinary Workspace Part is never made non-touching or non-colliding',function()
    local f,g=setup();f.Banana:Destroy()
    local platform=object('Part','Part',f.World);platform.Anchored=true
    g:SetEnabled(true);g:Step()
    expect('platform touch/collision untouched',platform.CanTouch and platform.CanCollide and g.Parts[platform]==nil)
    f.Now=1;g:Step();f.Rag.Value=true;f.Now=1.1;g:Step()
    expect('persistent generic part cannot keep recovery armed',f.Recovers==0)
    local effect=object('Part','Part',f.World)
    f.Rag.Value=false;f.Now=2;g:Step();f.Rag.Value=true;f.Now=2.1;g:Step()
    expect('new explosion candidate can arm recovery',f.Recovers==1)
    expect('effect itself not changed',effect.CanTouch and effect.CanCollide and g.Parts[effect]==nil)
    g:Dispose()
end)
test('owned peel remains active against the other rider',function()
    local f,g=setup();local own=object('Model','FoodBanana',f.Inventory);local hit=object('Part','HitboxPart',own)
    g:SetEnabled(true);g:Step()
    expect('our projectile is not globally suppressed',hit.CanTouch and g.Parts[hit]==nil)
    expect('other food protection remains active',not f.Peel.CanTouch)
    g.Context.Ignore=function(part)return part==f.Peel or part:IsDescendantOf(f.Inventory)end
    f.Now=1;g:Step();expect('ownership/ignore changes restore previous touch',f.Peel.CanTouch)
    g:Dispose()
end)
test('player or accessory names do not identify food',function()
    local f,g=setup();f.TC.Name='BananaUser';f.TR.Name='BananaAvatarPart'
    local hat=object('Part','BananaHat',f.TC)
    g:SetEnabled(true);g:Step()
    expect('remote avatar untouched',hat.CanTouch and f.TR.CanTouch and not g.Parts[hat]and not g.Parts[f.TR])
    g:Dispose()
end)
test('respawn and blocked state release all owned records',function()
    local f,g=setup();g:SetEnabled(true);f.Rag.Value=true;g:Step()
    f.Player.Character=nil;g:Step()
    expect('respawn clears old exposure and retries',g.Character==nil and g.Trip==nil and next(g.Parts)==nil and f.Peel.CanTouch)
    f.Player.Character=f.C;f.Rag.Value=false;g:Step()
    f.Blocked=true;g:Step();expect('blocked state restores touches',f.Peel.CanTouch and g.Trip==nil)
    g:Dispose()
end)
print('ALL DRIFT CHECKS PASSED: '..checks)
