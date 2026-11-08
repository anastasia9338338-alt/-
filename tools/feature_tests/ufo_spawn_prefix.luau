local now=0;local valid=true;local calls=0;local os={clock=function()return now end}
local localPlayer=newNode('Folder');local markers={}
for _,name in ipairs({'InPlot','InOwnedPlot','CanSpawnToy'})do local p=newNode('BoolValue',name);p.Value=false;p.Parent=localPlayer;markers[name]=p end
local task={wait=function(dt)now+=dt;if now>=.7 then markers.CanSpawnToy.Value=true end end}
local tbl7={States={},SpawnQueue={}};local function requireModule(name)assert(name=='GameFlags');return Flags end
local tbl12={SpawnToy=function(name,frame,priority,reserved,check)
 assert(name=='FlyingToyUfo'and priority==1 and reserved and check());calls+=1;return 'real-game-model'
end}
