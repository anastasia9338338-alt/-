-- Execute the exact Main.SNO function with a stale marker and real-yield clock.
local sim=Sim.new();currentSim=sim
local t=target('Local');local part=newNode('Part','SoundPart',WORLD)
local tbl7={States={}};local flag11=false;local granted=false;local requests=0;local allowed=true
local tick=function()return sim.Now end
local RunService=sim.RunService;local workspace={SpawnLocation={}};local Players={}
local tbl12={Char=function()return t.Character,t.Torso,t.Humanoid end,GetMagnitude=function()return 0 end,
 IsPartOwner=function()return true end,IsNetworkOwner=function()return granted end,
 Grab=function()requests+=1;if requests>=3 then granted=true end end}
