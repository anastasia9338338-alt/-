for _,mode in ipairs({"Normal","Faster","Super Fast"})do
    local f=referenceFixture(mode);f.Pallet:Dispose()
    local session={Player={},Character=f.Target.Character,Root=f.Target.Root,Humanoid=f.Target.Humanoid,CaptureAcknowledged=true}
    local valid=true;local grabs,releases=0,0
    local context={ShadowSource=true,KeepCapture=true,SourceMode=function()return mode end,Owned=function()return true end,
        Grab=function()grabs+=1;return true end,Release=function()releases+=1 end}
    local loop=setmetatable({Context=context,Sessions={},Calls=0,Released=0,Frame=0},Loop)
    function loop:Valid(entry)return valid and entry==session end
    for i=1,60 do loop.Frame=i;loop:SourceCycle(session,i/60,nil,true)end
    local expected=mode=="Normal"and 120 or 360
    check(releases==expected and grabs==60,"Source refresh cadence changed or Super Fast stayed in capture-only mode: "..mode)
    valid=false;local before=grabs+releases;loop:SourceCycle(session,2,nil,true)
    check(grabs+releases==before,"Cancelled source cycle kept issuing remote requests")
end
do
    local f=referenceFixture("Super Fast");f.Pallet:Dispose()
    local valid=true;local releases=0
    local session={Root=f.Target.Root,Humanoid=f.Target.Humanoid,CaptureAcknowledged=true}
    local loop=setmetatable({Calls=0,Released=0,Context={ShadowSource=true,KeepCapture=true,SourceMode=function()return"Super Fast"end,
        Grab=function()return true end,Release=function()releases+=1;valid=false end}},Loop)
    function loop:Valid()return valid end
    loop:SourceCycle(session,0,nil,true)
    check(releases==1,"Source burst ignored cancellation between native operations")
end
print('PASS: '..checks..' unchanged Normal refresh, faster profiles, Super Fast release routing and mid-burst cancellation checks (mocked; no server kick timing proof)')
