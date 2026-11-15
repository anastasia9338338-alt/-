-- Execute Main's actual Unstick implementation with the real protection registry.
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
assert(protectedTouch.Parent==protectedPart,'Our aura destroyed the protected touch detector')
assert(ordinaryTouch.Parent==nil,'Unstick stopped removing an unrelated sticky toy')
assert(#grabbed==2 and grabbed[1]==ordinaryPart and grabbed[2]==ordinaryPart,
 'Protected item reached native Grab, or unrelated same-name toy was excluded')
assert(#collided==1 and collided[1]==ordinary,'Protected collision settings were changed')
items.PendingModel=protected;items.ActiveModel=nil
assert(items:IsProtected(protectedPart),'Pending defensive spawn was not protected')
print('PASS: actual Unstick excludes active/pending defensive toys and preserves unrelated same-name targets (mocked)')
