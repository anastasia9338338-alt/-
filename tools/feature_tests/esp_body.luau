local function fixture(kind,mode)
    kind=kind or 'Gucci'
    local sim=Scheduler.new();CURRENT_SIGNAL_FACTORY=sim.NewSignal
    sim.RunService.RenderStepped=sim.NewSignal()
    local world=newNode('Folder','Workspace');world.Parent=WORLD
    local actor=character(sim,'LocalActor');actor.Character.Parent=world
    local model=newNode('Model','Train');model.Parent=world
    local root=newNode('Part','VehicleSeat');root.Parent=model
    root.Position=Vector3.new(kind=='Gucci'and 2000 or 20,0,0);root.CFrame=CFrame.new(root.Position)
    root.Size=Vector3.new(3,3,3);root.Transparency=1;root.LocalTransparencyModifier=0;root.AssemblyLinearVelocity=Vector3.zero
    model.PrimaryPart=root;model.Bounds=Vector3.new(3,3,3)
    function model:GetBoundingBox()return root.CFrame,self.Bounds end
    local function camera(offset)
        local c={ViewportSize=Vector2.new(800,600),OffsetX=offset or 0,OffsetY=0,Scale=.01}
        function c:WorldToViewportPoint(point)
            local x=self.ViewportSize.X*.5+point.X*self.Scale+self.OffsetX
            local y=self.ViewportSize.Y*.5-point.Y*.1+self.OffsetY
            return Vector3.new(x,y,100),x>=0 and x<=self.ViewportSize.X and y>=0 and y<=self.ViewportSize.Y
        end
        return c
    end
    local data={Camera=camera(0),CategoryCalls=0,Callbacks={},Bound=0,Unbound=0,Kind=kind}
    if mode then
        sim.RunService.BindToRenderStep=function(_,key,priority,fn)data.Bound+=1;data.Callbacks[key]=fn;data.Priority=priority end
        sim.RunService.UnbindFromRenderStep=function(_,key)data.Unbound+=1;data.Callbacks[key]=nil end
    end
    local context={Workspace=world,Parent=world,RunService=sim.RunService,
        Players={GetPlayers=function()return {}end,GetPlayerFromCharacter=function()return nil end},
        Camera=function()return data.Camera end,Character=function()return actor.Character,actor.Root,actor.Humanoid end}
    if mode=='context'then
        context.BindRender=function(fn)
            data.Callbacks.context=fn;data.CustomBound=true
            return{Disconnect=function()data.Callbacks.context=nil;data.CustomDisconnected=true end}
        end
    end
    local esp=ObjectESP.Install(context)
    esp.Config[kind].Enabled=true
    esp.Category=function(_,m)data.CategoryCalls+=1;return m==model and kind or nil,kind..' · Test'end
    esp:Update()
    local function render(dt)
        if mode then for _,fn in pairs(data.Callbacks)do fn(dt or 1/60)end
        else sim.RunService.RenderStepped:Fire(dt or 1/60)end
    end
    local function move(position)root.Position=position;root.CFrame=CFrame.new(position)end
    render()
    return {ESP=esp,Sim=sim,World=world,Actor=actor,Model=model,Root=root,Data=data,Render=render,Move=move,NewCamera=camera}
end
do
    local f=fixture();local r=f.ESP.Records[f.Model]
    check(r and r.Screen.Visible and r.Label.Parent==r.Screen,'Gucci screen marker unavailable')
    check(r.Highlight.Adornee==f.Model and r.Box.Adornee==f.Root,'ESP detached from its actual model/root')
    local x=r.Screen.Position.X.Offset;f.Data.Camera.OffsetX=100;f.Render(1/1000)
    check(math.abs(r.Screen.Position.X.Offset-x-100)<1e-7,'Camera pan was smoothed in pixel space and lagged behind')
    check(f.Data.CategoryCalls==1,'Render repeated slow discovery/classification')
    f.Data.Camera.OffsetX=0;f.Move(Vector3.new(2001,0,0));f.Render(1/240)
    check(r.MotionFrame.Position.X>2000 and r.MotionFrame.Position.X<2001,'Replication step was not smoothed in world space')
    local old=r.Box.Size.X;f.Model.Bounds=Vector3.new(8,6,2);f.ESP:Update();f.Render(1/240)
    check(r.Box.Size.X>old and r.Box.Size.X<8,'Invisible model box dimensions jumped at discovery cadence')
    check(math.abs(r.Box.CFrame.Position.X-(r.MotionFrame.Position.X-f.Root.Position.X))<1e-7,'Box did not share world motion smoothing')
end
do
    local expected
    for _,fps in ipairs({30,60,120,240,480,1000})do
        local f=fixture();f.Move(Vector3.new(2001,0,0))
        for _=1,math.floor(fps*.2)do f.Render(1/fps)end
        local x=f.ESP.Records[f.Model].MotionFrame.Position.X
        expected=expected or x
        check(math.abs(expected-x)<1e-6,'World response depends on render FPS at '..fps)
        check(math.abs(x-(2001-math.exp(-32*.2)))<1e-6,'Motion response lost time-based interpolation')
    end
end
do
    local f=fixture();local r=f.ESP.Records[f.Model]
    f.Root.AssemblyLinearVelocity=Vector3.new(16,0,0)
    for _=1,12 do f.Render(1/240)end
    check(r.MotionFrame.Position.X>2000.05,'Held replication sample was not bridged with a small prediction')
    f.Root.AssemblyLinearVelocity=Vector3.new(1e9,0,0)
    for _=1,12 do f.Render(1/240)end
    check((r.MotionFrame.Position-f.Root.Position).Magnitude<=3.00001,'Bad velocity projected the marker far away')
    for _=1,240 do f.Render(1/240)end
    check((r.MotionFrame.Position-f.Root.Position).Magnitude<.01,'Obsolete velocity left a persistent phantom marker')
end
do
    local f=fixture();local r=f.ESP.Records[f.Model]
    f.Data.Camera.Scale=100;f.Data.Camera.OffsetX=-200000
    f.Move(Vector3.new(2010,0,0));f.Render(1/240)
    check(math.abs((r.MotionFrame.Position.X-f.Root.Position.X)*100)<=12.0001,'Close-up camera produced unbounded world-filter lag')
    f.Move(Vector3.new(2200,0,0));f.Render(0)
    check(r.MotionFrame.Position.X==2200,'Teleport retained the old marker location')
    f.Data.Camera=f.NewCamera(50);f.Render(0)
    check(math.abs(r.Screen.Position.X.Offset-472)<1e-7,'Camera replacement carried old projected coordinates')
    f.Data.Camera.ViewportSize=Vector2.new(1024,768);f.Render(0)
    check(math.abs(r.Screen.Position.X.Offset-584)<1e-7,'Viewport resize kept the old screen location')
    f.Data.Camera=nil;f.Render()
    check(not r.Screen.Visible and r.MotionFrame==nil,'Camera loss left a visible/stale marker')
    f.Data.Camera=f.NewCamera();f.Render()
    f.Root.Parent=nil;f.Render()
    check(f.ESP.Records[f.Model]==nil,'Streamed-out root left a ghost marker')
end
for _,kind in ipairs({'Item','Blobman'})do
    local f=fixture(kind);local r=f.ESP.Records[f.Model]
    f.Move(Vector3.new(20.2,0,0));f.Render(1/240)
    check(r.MotionFrame.Position.X>20 and r.MotionFrame.Position.X<20.2,kind..' label still updated at native jumps')
    check(r.Billboard.Enabled and r.Label.Parent==r.Billboard,kind..' native billboard was replaced')
    check(math.abs(r.Billboard.StudsOffsetWorldSpace.X-(r.MotionFrame.Position.X-20.2))<1e-7,kind..' billboard ignored world smoothing')
    f.ESP.Config[kind].Enabled=false;f.Render()
    check(f.ESP.Records[f.Model]==nil,kind..' disable left visuals alive')
end
do
    local f=fixture();local r=f.ESP.Records[f.Model]
    f.ESP.Config.Gucci.ThroughWalls=false;f.ESP:Update();f.Render()
    check(not r.Screen.Visible and r.Billboard.Enabled and r.Label.Parent==r.Billboard,'Occlusion settings were lost')
    f.Data.Camera.OffsetX=800;f.Render()
    check(r.Edge and r.Edge.Visible,'Offscreen direction marker unavailable')
    local y=r.Edge.Position.Y.Offset;f.Data.Camera.OffsetY=8;f.Render(1/1000)
    check(math.abs(r.Edge.Position.Y.Offset-y)>0,'Direction marker waited on discovery instead of rendering')
    f.ESP.GucciArrows=false;f.Render();check(not r.Edge.Visible,'Disabled arrow persisted')
    f.ESP:Dispose();f.ESP:Dispose()
    for _,c in ipairs(f.ESP.Connections)do check(not c.Connected,'Unload left a fallback callback alive')end
    check(f.ESP.Container.Parent==nil,'Unload left the marker container')
end
for _,mode in ipairs({'native','context'})do
    local f=fixture('Gucci',mode)
    if mode=='native'then check(f.Data.Bound==1 and f.Data.Priority>Enum.RenderPriority.Camera.Value,'Render was not bound after the camera')
    else check(f.Data.CustomBound and f.Data.Bound==0,'Preferred render callback was not used')end
    check(#f.Sim.RunService.RenderStepped.Listeners==0,'Two render drivers were active')
    f.ESP:Dispose()
    check(not next(f.Data.Callbacks),'Bound render key leaked on unload')
    if mode=='native'then check(f.Data.Unbound==1,'Native render key was not unbound')else check(f.Data.CustomDisconnected,'Context render connection not disconnected')end
end
check(not instanceClasses.Part,'ESP created proxy physics parts')
print('PASS: '..checks..' world-ESP, camera, prediction, occlusion, lifecycle and render-binding assertions')
