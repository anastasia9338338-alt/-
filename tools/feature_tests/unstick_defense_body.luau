-- Execute the original Unstick with a defense registry present. It has no toy exceptions.
local inventory=Instance.new('Folder');inventory.Parent=WORLD
local character=Instance.new('Model');character.Parent=WORLD
local torso=Instance.new('Part',character)
local root=Instance.new('Part',character);root.Name='HumanoidRootPart'
local localPlayer={Name='Owner'}
local function stickyToy()
 local model=Instance.new('Model',inventory);model.Name='ShurikenRSC'
 local sticky=Instance.new('Part',model);sticky.Name='StickyPart'
 local touch=Instance.new('TouchInterest',sticky)
 return model,sticky,touch
end
local protected,protectedPart,protectedTouch=stickyToy()
local ordinary,ordinaryPart,ordinaryTouch=stickyToy()
local items=Items.Install({Enabled=function()return true end,
 IsInventoryModel=function(model)return model.Parent==inventory end})
items.ActiveModel=protected
local grabbed,collided={},{}
local tbl12={AntiKickItems=items,
 GetInventory=function()return inventory end,
 FindNicePart=function(model)return model:FindFirstChild('StickyPart')end,
 Grab=function(part)grabbed[#grabbed+1]=part end,
 ToggleCollisions=function(model)collided[#collided+1]=model end}
function character:QueryDescendants()return {torso}end
function torso:GetConnectedParts()return {protectedPart,ordinaryPart}end
local Players={GetPlayerFromCharacter=function(_,model)if model==character then return localPlayer end end}
local workspace={PlotItems=Instance.new('Folder')}
__ACTUAL_UNSTICK__
tbl12.RemoveSticky(character)
assert(protectedTouch.Parent==nil and ordinaryTouch.Parent==nil,
 'Original Unstick skipped a registered or unregistered sticky toy')
assert(#grabbed==4 and grabbed[1]==protectedPart and grabbed[2]==ordinaryPart
 and grabbed[3]==protectedPart and grabbed[4]==ordinaryPart,
 'Unstick changed native connected-part or inventory processing')
assert(#collided==2 and collided[1]==protected and collided[2]==ordinary,
 'Unstick still excludes registered defensive toys from collision processing')
print('PASS: actual Unstick retains original native behavior with no defensive toy exceptions (mocked)')
