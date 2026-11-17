local sim=Sim.new();currentSim=sim
local t=target("Victim");local player={Name="Victim"};local folder=newNode("Folder","Toys",WORLD)
local function toy(name,distance)
    local model=newNode("Model",name,folder);local part=newNode("Part","SoundPart",model);part.Position=t.Torso.Position+Vector3.new(distance,0,0);return part
end
local blob=toy("CreatureBlobman",1);local tractor=toy("TractorGreen",2);local far=toy("FarAway",6);local shield=toy("NinjaShuriken",3)
local calls={};local enabled=true
local remover=Remover.Install({Clock=function()return sim.Now end,Spawn=function(fn)sim:Spawn(fn)end,Wait=function()return sim:Wait()end,
    Enabled=function()return enabled end,Player=function()return player end,Containers=function()return{folder}end,
    Owner=function(part,cf)calls[#calls+1]={"owner",part,sim.Now};check(part==shield and cf==part.CFrame,"Source remover claimed another object")end,
    Grab=function(part,cf)calls[#calls+1]={"grab",part,sim.Now};check(part==shield and cf==part.CFrame,"Source grab changed its argument contract")end,
    Release=function(part)calls[#calls+1]={"release",part,sim.Now};check(part==shield,"Cleanup released an unrelated target")end,
    Begin=function()calls[#calls+1]={"begin"};return true end,Finish=function()calls[#calls+1]={"finish"}end})
check(remover:Request(t.Character,function()return true end),"Near-target shield was not selected")
check(remover.Busy and not remover:Request(t.Character),"The shared grab channel admitted overlapping removals")
sim:Run(.1,60)
check(calls[1][1]=="begin"and calls[2][1]=="owner"and calls[3][1]=="grab"and calls[4][1]=="release"and calls[5][1]=="finish","Native owner/grab/drop order changed")
check(calls[4][3]-calls[3][3]>=.05-1e-7 and not remover.Busy,"The 50 ms source hold or cleanup changed")
check(blob.Parent and tractor.Parent and far.Parent,"An excluded or distant toy was removed")
calls={};remover:Request(t.Character);enabled=false;remover:Cancel()
local before=#calls
check(not remover:Request(t.Character),"A new worker overlapped cancelled cleanup")
sim:Run(.1,60)
check(not remover.Busy and not remover.Held and not remover.Working,"Cancellation retained its grab lock")
for i=before+1,#calls do check(calls[i][1]~="owner"and calls[i][1]~="grab","Cancellation started another grab")end
remover:Dispose();check(not remover:Request(t.Character),"Disposed shield removal restarted")
print('PASS: '..checks..' supplied anti-kick removal arguments, proximity, exclusions, timing and cancellation checks (mocked)')
