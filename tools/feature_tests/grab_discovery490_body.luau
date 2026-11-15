local workspace=Instance.new('Folder')
local worldParts=Instance.new('Folder',workspace);worldParts.Name='GrabParts'
local worldWeld=Instance.new('Weld',worldParts)
local a=Instance.new('Model',workspace)
local partsA=Instance.new('Folder',a);partsA.Name='GrabParts'
local remoteWeld=Instance.new('WeldConstraint',partsA)
Instance.new('RigidConstraint',partsA)
local b=Instance.new('Model',workspace)
local partsB=Instance.new('Folder',b);partsB.Name='GrabParts'
local another=Instance.new('Weld',partsB)
local playerA={Character=a}
local Players={GetPlayers=function()return {playerA,{Character=b},{},playerA}end}
local discover=__ACTUAL_DISCOVERY__
local found=discover();local seen={}
for _,v in ipairs(found)do assert(not seen[v],'Duplicate grab-weld discovery');seen[v]=true end
assert(#found==3 and seen[worldWeld]and seen[remoteWeld]and seen[another],
 'Native grab discovery missed a remote character folder or included unrelated constraints')
partsA:Destroy();worldParts:Destroy()
found=discover()
assert(#found==1 and found[1]==another,'Destroyed/missing grab folders broke discovery')
print('PASS: actual Main grab discovery covers world and remote character folders, deduplication and missing folders (mocked)')
