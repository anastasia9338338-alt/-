local world=Instance.new('Folder');local character=Instance.new('Model',world)
local root=Instance.new('Part',character);root.Name='HumanoidRootPart'
local hum=Instance.new('Humanoid',character);hum.Health=100
local rag=Instance.new('BoolValue',hum);rag.Name='Ragdolled';rag.Value=false
local head=Instance.new('Part',character);head.Name='Head'
local arm=Instance.new('Part',character);arm.Name='Left Arm'
local torso=Instance.new('Part',character);torso.Name='Torso'
local left=Instance.new('Part',character);left.Name='Left Leg'
local right=Instance.new('Part',character);right.Name='Right Leg'
local localPlayer={};local tbl8={};local moved={};local time=0
local task={wait=function(dt)time+=dt or .02 end};local function tick()return time end
local tbl12={Char=function()return character,root,hum end,
 Teleport=function(part)assert(part==left or part==right,'Legs-only operation teleported head/arm/torso/root');moved[#moved+1]=part end,
 Grab=function(part)assert(part==root,'Self recovery grabbed another root')end,ResetVelocity=function()end}
local tbl11={RagdollRemote={FireServer=function(_,part,duration)assert(part==root);rag.Value=duration>0 end}}
local function fn18()end
__ACTUAL_BREAK_LIMB__
tbl12.BreakLimb(localPlayer,'Legs',function()return true end)
assert(#moved==2 and moved[1]==left and moved[2]==right,'Native legs-only dispatch missed legs or included another body part')
assert(head.Parent==character and arm.Parent==character and torso.Parent==character and not rag.Value,'Native leg removal damaged other body parts or retained ragdoll')
local calls=#moved;tbl12.BreakLimb(localPlayer,'Legs',function()return false end)
assert(#moved==calls,'Cancelled native removal still moved body parts')
print('PASS: actual Main native leg removal selects only legs and preserves torso/head/arms, cancellation and recovery (mocked)')
