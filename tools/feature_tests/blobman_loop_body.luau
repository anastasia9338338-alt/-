local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function run(speed)
 local expectContinuous=onWait==nil
 now=0;stopAt=1;tbl8.LoopApplyMethod=true;events={};created={};poseUpdates=0;root.CFrame=CFrame.new(0,5,0)
 tbl12.BlobmanCadence:SetSpeed(speed);tbl14.LoopKick(player)
 local grabs=0;local lastGrab,lastDrop
 for _,e in ipairs(events)do
  if e.Kind=='CreatureGrab'then grabs+=1;lastGrab=e.At
  elseif lastGrab then check(e.At>lastGrab,'Grab/release sent in same callback');lastDrop=e.At end
 end
 check(attachment.Parent==root,'Native loop left RootAttachment in character model')
 check(parts.RightWeld.Enabled and parts.RightOri.Enabled,'Native loop left Blobman hand controllers disabled')
 for _,v in ipairs(created)do check(not v.Parent,'Native loop leaked target hold objects')end
 check(not tbl14.BlobLoopTokens[player],'Native loop token leaked')
 if expectContinuous then check(poseUpdates>100,'Slow hand speed stopped continuous limb/hold updates')end
 return grabs
end
local slow=run(2);local fast=run(60);check(fast>slow*8,'Hand speed did not affect actual Main native calls')
onWait=function()
 currentCharacter=newNode('Model');currentCharacter.Parent=world;currentRoot=newNode('Part');currentRoot.Parent=currentCharacter
 currentHumanoid={Health=100};onWait=nil
end
local before=root.CFrame;run(30)
check(attachment.Parent==root and next(tbl14.BlobLoopTokens)==nil,'Respawn failed old target cleanup')
for _,fn in ipairs(tasks)do fn()end
check(currentRoot.CFrame.Position.Magnitude==0,'Stale Blobman work moved replacement character')
print('PASS: '..checks..' actual Main Blobman hand speed, native calls, hold cleanup and respawn checks (mocked)')
