for _,stop in ipairs({"disable","unselect","unload"})do
    local f=referenceFixture("Super Fast");local player={};local actor=newNode("Model","Actor",WORLD)
    local data={SelectedPlayers={[player]=true}}
    local cleanups={};local api={GetTargets=function()return{player}end,IsProtectedPlayer=function()return false end,
        Char=function(p)if p then return f.Target.Character,f.Target.Root,f.Target.Humanoid end;return actor end,
        RequestReferenceRagdoll=function(character,valid)return f.Pallet:Request(character,valid,true,true)end,
        RunPlayerMethod=function(_,method,p)method(p)end}
    local panel=Panel.Install({API=api,Data=data,RunService=f.Sim.RunService,Spawn=function(fn)f.Sim:Spawn(fn)end,
        Library={OnUnload=function(_,fn)cleanups[#cleanups+1]=fn end},Notify=function(message)error(message)end})
    panel:SetLoop("Ragdoll",true);f.Sim:Run(.2,60)
    local entry=f.Pallet.Entries[f.Target.Character]
    check(entry and entry.Manual and f.Pallet:Profile(entry)==8,"Standalone Ragdoll inherited a faster kick profile instead of the donor trajectory")
    if stop=="disable"then panel:SetLoop("Ragdoll",false)
    elseif stop=="unselect"then data.SelectedPlayers[player]=nil
    else panel:Dispose()end
    f.Sim:Tick(1/60)
    check(not next(f.Pallet.Entries),"Standalone Ragdoll kept running after "..stop)
    panel:Dispose();f.Pallet:Dispose()
end
do
    local f=referenceFixture("Faster");local player={};local actor=newNode("Model","Actor",WORLD);local session={}
    local requested=0
    local api={KickLoop={Sessions={[player]=session},Valid=function()return true end},
        GetTargets=function()return{player}end,IsProtectedPlayer=function()return false end,
        Char=function(p)return p and f.Target.Character or actor end,
        RequestReferenceRagdoll=function()requested+=1 end,RunPlayerMethod=function(_,method,p)method(p)end}
    local panel=Panel.Install({API=api,Data={SelectedPlayers={[player]=true}},RunService=f.Sim.RunService,
        Spawn=function(fn)f.Sim:Spawn(fn)end,Library={OnUnload=function()end},Notify=function(message)error(message)end})
    panel:SetLoop("Ragdoll",true);f.Sim:Run(.4,60)
    check(requested==0,"Standalone Ragdoll stole a pallet already controlled by the kick")
    panel:Dispose();f.Pallet:Dispose()
end
print('PASS: '..checks..' standalone source Ragdoll routing, original trajectory, selection, cancellation and shared-kick checks (mocked)')
