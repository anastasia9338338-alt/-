local QueryData={Groups={},Registered={}}
local PhysicsService={}
function PhysicsService:CollisionGroupsAreCollidable(a,b)return QueryData.Groups[a]and QueryData.Groups[a][b]==true end
function PhysicsService:GetRegisteredCollisionGroups()return QueryData.Registered end
local game={GetService=function(_,name)assert(name=='PhysicsService');return PhysicsService end}
local Enum={RaycastFilterType={Include='Include'}}
local OverlapParams={new=function()return{}end}
local workspace={GetPartsInPart=function(_,shape,query)
 if QueryData.Fail then error('query unavailable')end
 QueryData.LastShape,QueryData.LastQuery=shape,query
 assert(shape==QueryData.Receiver and query.FilterDescendantsInstances[1]==QueryData.Part)
 if QueryData.Overlap then return{QueryData.Part}end
 return{}
end}
