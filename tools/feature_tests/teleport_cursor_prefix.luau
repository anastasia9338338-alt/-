local flag11=false;local focused=false;local calls=0;local canceled=0
local root=newNode('Part');root.Parent=newNode('Folder');local h={HipHeight=2,Health=100}
local hit=CFrame.new(14,6,-20);local target=root
local UserInputService={GetFocusedTextBox=function()return focused end}
local tbl12={Char=function()return root.Parent,root,h end,GetTarget=function()return target end,GetHit=function()return hit end,
 SlideTeleport={Cancel=function()canceled+=1 end},CharacterTools={Locked=true},
 Teleport=function(part,destination)assert(part==root);calls+=1;root.CFrame=destination end}
