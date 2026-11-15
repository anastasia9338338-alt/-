local checks=0
local function check(value,message)assert(value,message);checks+=1 end
local function fixture()
 local world=newNode('Folder','World');local player={Name='Target'}
 local part=newNode('Part','PlayerCharacterLocationDetector');part.Parent=world;part.Anchored=false;part.AssemblyRootPart=part
 local data={Part=part,Owned=true,Targets={player}};local beat=signal()
 local freeze=Freeze.Install({RunService={Heartbeat=beat},Targets=function()return data.Targets end,
  Detector=function()return data.Part end,Owned=function()return data.Owned end})
 return freeze,data,part,player,world,beat
end
do
 local f,d,p,player,w,beat=fixture();f:SetEnabled(true);beat:Fire(.1)
 local first=f.States[player].Mover
 check(first.Parent==p and first.Position==p.Position,'Owned detector did not receive a hold mover')
 first:Destroy();p.Position=Vector3.new(9,4,2);f:Step()
 local second=f.States[player].Mover
 check(second~=first and second.Parent==p,'Destroyed mover is still reported as an active freeze')
 check(second.Position==p.Position,'Replacement mover did not capture the current detector position')
 local unrelated=newNode('Part','Other');unrelated.Parent=w;second.Parent=unrelated;f:Step()
 local third=f.States[player].Mover
 check(third~=second and third.Parent==p and not second.Parent,'Reparented mover was not replaced and removed')
 p.Position=Vector3.new(19,6,4);f:Step()
 check(f.States[player].Mover==third and third.Position==Vector3.new(9,4,2),'Existing hold goal drifted or duplicated')
 check(#p:GetChildren()==1 and #unrelated:GetChildren()==0,'Freeze created duplicate or escaped movers')
 d.Owned=false;f:Step()
 check(not f.States[player]and not third.Parent,'Lost physical ownership retained the freeze mover')
 d.Owned=true;f:Step();local old=f.States[player].Mover
 local replacement=newNode('Part','PlayerCharacterLocationDetector');replacement.Parent=w;replacement.Anchored=false;replacement.AssemblyRootPart=replacement
 d.Part=replacement;f:Step()
 check(not old.Parent and f.States[player].Part==replacement,'Replaced detector retained the old hold')
 d.Targets={};local current=f.States[player].Mover;f:Step()
 check(not current.Parent and not next(f.States),'Deselected target retained its freeze mover')
 d.Targets={player};f:Step();current=f.States[player].Mover
 replacement:Destroy();f:Step()
 check(not current.Parent and not next(f.States),'Deleted detector retained its state')
 f:Dispose();check(not f.Connection.Connected and not f.Enabled,'Unload retained the heartbeat or enabled state')
 f:SetEnabled(true);beat:Fire(.1)
 check(not f.Enabled and not next(f.States),'Disposed freeze reactivated')
 f:Dispose()
end
for _,reason in ipairs({'anchored','otherAssembly','unowned'})do
 local f,d,p,player=fixture()
 if reason=='anchored'then p.Anchored=true elseif reason=='otherAssembly'then p.AssemblyRootPart=newNode('Part')else d.Owned=false end
 f:SetEnabled(true);f:Step();check(not next(f.States)and #p:GetChildren()==0,'Invalid detector frozen: '..reason)
 f:Dispose()
end
do
 local f,d,p,player=fixture();f:SetEnabled(true);f:Step();local mover=f.States[player].Mover
 f:SetEnabled(false);check(not mover.Parent and not next(f.States)and f.Status=='Disabled','Toggle off retained its mover')
 f:Dispose()
end
print('PASS: '..checks..' Freeze PCLD ownership, stale-mover recovery and lifecycle checks (mocked)')
