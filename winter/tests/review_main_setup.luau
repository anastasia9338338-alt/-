local checks=0
local function check(v,m)assert(v,m);checks+=1 end
local services,host,warnings={},{},{}
local game={GetService=function(_,name)return assert(services[name],'Missing fake service '..name)end}
local getgenv=function()return host end
local shared={}
local warn=function(message)table.insert(warnings,tostring(message))end
local UDim={new=function(scale,offset)return{Scale=scale,Offset=offset}end}
local UDim2={new=function(x,xo,y,yo)return{X=UDim.new(x,xo),Y=UDim.new(y,yo)}end}
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
local function countConnected(sig)
 local n=0;for _,c in ipairs(sig.Connections)do if c.Connected then n+=1 end end;return n
end
local function fixture(withGui)
 host={};warnings={}
 local dataModel=newNode('DataModel','Game')
 local world=newNode('Workspace','Workspace');world.Parent=dataModel
 local terrain=newNode('Terrain','Terrain');terrain.Parent=world
 terrain.WaterColor=Color3.fromRGB(0,90,150);terrain.WaterWaveSize=.3;terrain.WaterWaveSpeed=4;terrain.WaterTransparency=.6
 terrain.Decoration=true;terrain._colors={}
 terrain.GetMaterialColor=function(self,key)return self._colors[key]or Color3.fromRGB(90,100,110)end
 terrain.SetMaterialColor=function(self,key,value)self._colors[key]=value end
 world.Terrain=terrain
 local ground=newNode('Part','Baseplate');ground.Size=Vector3.new(400,1,400);ground.CFrame=CFrame.new(0,-.5,0)
 ground.Color=Color3.fromRGB(20,140,60);ground.Material=Enum.Material.Grass
 ground.Anchored=true;ground.CanCollide=true;ground.CanTouch=true;ground.CanQuery=true;ground.Parent=world
 local originalColor=ground.Color
 world.CurrentCamera={CFrame=CFrame.new(0,8,10)}
 world.Raycast=function(_,origin,direction,params)
  local top=ground.Position.Y+ground.Size.Y*.5
  if direction.Y>=0 or origin.Y<top then return end
  local t=(top-origin.Y)/direction.Y;if t<0 or t>1 then return end
  local p=origin+direction*t
  if math.abs(p.X)>200 or math.abs(p.Z)>200 then return end
  return{Instance=ground,Position=Vector3.new(p.X,top,p.Z),Normal=Vector3.yAxis,Material=ground.Material}
 end
 local player=newNode('Player','Player')
 local character=newNode('Model','Avatar');character.Parent=world
 local hrp=newNode('Part','HumanoidRootPart');hrp.CFrame=CFrame.new(0,3,0);hrp.Parent=character
 local humanoid=newNode('Humanoid','Humanoid');humanoid.Health=100;humanoid.FloorMaterial=Enum.Material.Grass;humanoid.State=Enum.HumanoidStateType.Running
 humanoid.GetState=function(self)return self.State end;humanoid.Parent=character;player.Character=character
 if withGui then local gui=newNode('PlayerGui','PlayerGui');gui.Parent=player end
 local lighting=newNode('Lighting','Lighting');lighting.Parent=dataModel
 lighting.ClockTime=9;lighting.Brightness=1;lighting.Ambient=Color3.fromRGB(20,30,40);lighting.OutdoorAmbient=Color3.fromRGB(40,50,60)
 lighting.FogColor=Color3.fromRGB(100,120,130);lighting.FogStart=100;lighting.FogEnd=2000;lighting.EnvironmentDiffuseScale=.5;lighting.EnvironmentSpecularScale=.5
 local heartbeat=signal()
 services={Players={LocalPlayer=player,GetPlayers=function()return{player}end},RunService={Heartbeat=heartbeat},Lighting=lighting,Workspace=world}
 return{World=world,Player=player,Ground=ground,OriginalColor=originalColor,Lighting=lighting,Heartbeat=heartbeat,Terrain=terrain}
end
local function requireModule(name)return assert(modules[name],'Unexpected module '..name)end
