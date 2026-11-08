local now=0;local os={clock=function()return now end};local flag11=false
local world=newNode('Folder');local actor=newNode('Model');actor.Parent=world;local avatar=newNode('Part');avatar.CFrame=CFrame.new(0,3,0);avatar.Parent=actor
local driver={Health=100,Sit=true};local blob=newNode('Model','CreatureBlobman');blob.Parent=world
local character=newNode('Model');character.Parent=world;local root=newNode('Part','HumanoidRootPart');root.CFrame=CFrame.new(0,5,0);root.Parent=character
local humanoid=newNode('Humanoid');humanoid.Health=100;humanoid.RequiresNeck=true;humanoid.Parent=character
local attachment=newNode('Attachment','RootAttachment');attachment.Parent=root
local fire=newNode('Part','FirePlayerPart');fire.Parent=root;local fireWeld=newNode('WeldConstraint','WeldConstraint');fireWeld.Parent=fire
local player={Parent=world,Name='Target',Character=character}
local tbl7={SelectedPlayersBlob={[player]=true}};local tbl8={LoopApplyMethod=true,BlobRemoveInputFood=false,DeleteShurInBlobK=false};local tbl9={BlobMethod='Kick',BKMethod=1}
local options={BlobKickX={Value=0},BlobKickY={Value=15},BlobKickZ={Value=0}}
local parts={RightWeld=newNode('AlignPosition'),RightOri=newNode('AlignOrientation'),LeftWeld=newNode('AlignPosition')}
parts.RightWeld.Parent=blob;parts.RightOri.Parent=blob;parts.LeftWeld.Parent=blob
local events={};local tasks={};local task={spawn=function(fn,...)local args={...};tasks[#tasks+1]=function()fn(unpack(args))end end}
local stopAt=1;local fps=240;local onWait
local physics={Wait=function()now+=1/fps;if onWait then onWait()end;if now>=stopAt then tbl8.LoopApplyMethod=false end end}
for _,kind in ipairs({'CreatureGrab','CreatureDrop','CreatureRelease'})do
 parts[kind]={FireServer=function(_,a,b,w)
  events[#events+1]={Kind=kind,At=now,Root=b,Weld=w or a}
  if kind=='CreatureGrab'then parts.RightWeld.Attachment0=attachment else parts.RightWeld.Attachment0=nil end
 end}
end
local poseUpdates=0;local created={};local currentCharacter,currentRoot,currentHumanoid=character,root,humanoid
local tbl12={Char=function(p)if p then return currentCharacter,currentRoot,currentHumanoid end;return actor,avatar,driver end,
 BlobmanRide={Current=function()return blob end},BlobmanCadence=Cadence.new({Clock=function()return now end,Signal=physics}),
 SNO=function()return true end,Teleport=function(p,cf)p.CFrame=cf end,ResetVelocity=function()end,
 ToggleMotor6D=function(_,enabled)if not enabled then assert(humanoid.RequiresNeck==false,'Disabling neck could kill target')end end,
 RepositionLimbs=function()poseUpdates+=1 end,ToggleCollisions=function()end,Grab=function()end,RNO=function()end,
 PalletRagdoll={Apply=function()end},CreateAlign=function(p)
  local a=newNode('BodyPosition');a.Parent=p;local b=newNode('Attachment');b.Parent=p;created[#created+1]=a;created[#created+1]=b;return a,b
 end}
local tbl14={GetBlobmanComponents=function()return parts end,Release=function()return true end}
