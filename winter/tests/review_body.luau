local checks=0
local function check(v,m)assert(v,m);checks+=1 end
local function scene(quality)
 local world=newNode('Workspace','Workspace')
 local terrain=newNode('Terrain','Terrain');terrain.Parent=world
 local ground=newNode('Part','Original Map Ground');ground.Size=Vector3.new(400,1,400);ground.CFrame=CFrame.new(0,-.5,0)
 ground.Anchored=true;ground.CanCollide=true;ground.CanTouch=true;ground.CanQuery=true;ground.Material=Enum.Material.Concrete;ground.Color=Color3.fromRGB(128,128,128);ground.Parent=world
 local root=newNode('Folder','Winter');root.Parent=world
 local character=newNode('Model','Avatar');character.Parent=world
 local hrp=newNode('Part','HumanoidRootPart');hrp.Parent=character
 local left=newNode('Part','LeftFoot');left.Size=Vector3.new(.8,1,1);left.Parent=character
 local right=newNode('Part','RightFoot');right.Size=left.Size;right.Parent=character
 local humanoid=newNode('Humanoid','Humanoid');humanoid.Health=100;humanoid.FloorMaterial=Enum.Material.Concrete;humanoid.Sit=false;humanoid.State=Enum.HumanoidStateType.Running
 humanoid.GetState=function(self)return self.State end;humanoid.Parent=character
 local state={Closed=false,Rays=0}
 local function move(x,z)
  hrp.CFrame=CFrame.new(x,3,z);left.CFrame=CFrame.new(x-.5,.5,z);right.CFrame=CFrame.new(x+.5,.5,z)
  hrp.AssemblyLinearVelocity=Vector3.new(16,0,0)
 end
 move(0,0)
 local ctx={World=world,Root=root,Player={Character=character},MapParts={ground},Bounds={Min=Vector3.new(-200,-1,-200),Max=Vector3.new(200,60,200),Center=Vector3.new(0,0,0)},
  Config={Quality=quality or 'High',Footprints=true},Alive=function()return not state.Closed end}
 function ctx.IsMapPart(p)return p==ground end
 function ctx.Ground(x,z)
  state.Rays+=1
  if math.abs(x)>200 or math.abs(z)>200 then return nil end
  return {Position=Vector3.new(x,0,z),Normal=Vector3.yAxis,Material=ground.Material,Instance=ground}
 end
 world.Raycast=function(_,origin,direction)
  if direction.Y>=0 or origin.Y<0 then return nil end
  local t=-origin.Y/direction.Y
  if t<0 or t>1 then return nil end
  local p=origin+direction*t;return ctx.Ground(p.X,p.Z)
 end
 world.CurrentCamera={CFrame=CFrame.new(0,8,10)}
 return {Context=ctx,World=world,Root=root,Ground=ground,Move=move,HRP=hrp,Humanoid=humanoid,Character=character,State=state}
end
local function assertGeometry(root,limit)
 local count=0
 for _,object in ipairs(root:GetDescendants())do
  if object:IsA('BasePart')then
   count+=1;check(finiteVector(object.Size)and object.Size.X>0 and object.Size.Y>0 and object.Size.Z>0,'Invalid positive geometry')
   check(finiteVector(object.Position),'Nonfinite decoration position')
   check(object.Anchored and not object.CanCollide and not object.CanTouch and not object.CanQuery,'Local visual changed collision/query policy')
  end
 end
 check(count<=limit,'Unbounded geometry count '..count..' / '..limit)
 return count
end
if modules.Snow then
 for _,quality in ipairs({'High','Medium','Low'})do
  local f=scene(quality);local originalMaterial,originalColor=f.Ground.Material,f.Ground.Color
  local snow=modules.Snow.Install(f.Context)
  for i=1,600 do f.Move(i*.12,0);snow:Update(1/60,i/60)end
  check(snow.Stats.Steps>5,'Snow never created footstep marks')
  check(snow.Stats.Compressed>5,'Snow never applied pressure')
  local deepest=0
  for _,tile in pairs(snow.Tiles)do
   deepest=math.max(deepest,tile.Depth)
   if tile.Depth>.01 then check(tile.Part.Size.Y<tile.Top-tile.Ground-.095,'Compression failed to change actual snow height')end
  end
  check(deepest>.05,'Pressure only drew decals, not depressed geometry')
  for _,mark in pairs(snow.Marks)do for _,p in ipairs(mark.Parts)do
   if p.Transparency<.9 then
    local surface=snow:SurfaceAt(p.Position.X,p.Position.Z,mark.Point.Y)
    check(p.Position.Y-p.Size.Y*.5>=surface-.01,'Footprint was buried below the compressed snow surface')
   end
  end end
  local count=assertGeometry(f.Root,3000)
  local steps=snow.Stats.Steps
  f.Humanoid.FloorMaterial=Enum.Material.Air;f.Humanoid.State=Enum.HumanoidStateType.Freefall
  for i=601,660 do f.Move(i*.12,0);snow:Update(1/60,i/60)end
  check(snow.Stats.Steps==steps,'Flying created footprints')
  f.Humanoid.FloorMaterial=Enum.Material.Concrete;f.Humanoid.State=Enum.HumanoidStateType.Running
  f.Move(-150,0);snow:Update(1/60,12)
  check(snow.Stats.Steps==steps,'Teleport jump drew a connecting trail')
  f.Context.Config.Footprints=false
  for i=1,60 do f.Move(-150+i*.12,0);snow:Update(1/60,12+i/60)end
  check(snow.Stats.Steps==steps,'Disabled footprints kept stamping')
  check(f.Ground.Material==originalMaterial and f.Ground.Color==originalColor and f.Ground.Anchored and f.Ground.CanCollide,'Snow mutated original map state')
  snow:Destroy();snow:Destroy()
  check(#f.Root:GetDescendants()==0,'Snow cleanup left geometry')
  print(quality..' Snow: '..count..' local parts; pressure, movement, flight, teleport and cleanup checked')
 end
 do
  local f=scene('High');local snow=modules.Snow.Install(f.Context)
  for i=1,2400 do
   local angle=i*.012
   f.Move(math.cos(angle)*30,math.sin(angle)*30);snow:Update(1/60,i/60)
  end
  check(snow.TileCount<=snow.Profile.Tiles and #snow.FreeTiles<=60,'Long walking exceeded the snow tile pool')
  check(#snow.Marks<=snow.Profile.Marks,'Long walking exceeded the footprint ring')
  assertGeometry(f.Root,3000)
  f.Character.LeftFoot.Name='Left Leg'
  f.Character.RightFoot.Name='Right Leg'
  f.Character:FindFirstChild('Left Leg').Size=Vector3.new(.8,2,1)
  f.Character:FindFirstChild('Right Leg').Size=Vector3.new(.8,2,1)
  f.HRP.Name='realHrp'
  local before=snow.Stats.Steps
  for i=2401,2460 do
   f.Move(30+(i-2400)*.12,0)
   f.Character:FindFirstChild('Left Leg').CFrame=CFrame.new(f.HRP.Position.X-.5,1,0)
   f.Character:FindFirstChild('Right Leg').CFrame=CFrame.new(f.HRP.Position.X+.5,1,0)
   snow:Update(1/60,i/60)
  end
  check(snow.Stats.Steps>before,'R6/realHrp alias stopped footprint tracking')
  snow:Destroy()
  print('Snow: extended circular trail respected all pools; R6/realHrp tracking checked')
 end
end
if modules.Decor then
 for _,quality in ipairs({'High','Medium','Low'})do
  local f=scene(quality)
  local decor=modules.Decor.Install(f.Context)
  for i=1,1800 do
   local before=decor.Parts
   decor:Update(1/60,i/60)
   check(decor.Parts-before<=48,'Decoration build exceeded the per-frame slice')
  end
  local count=assertGeometry(f.Root,3000)
  check(count>100,'Decoration builder produced no holiday scene')
  check(not decor.LastError,'Decoration coroutine swallowed an error: '..tostring(decor.LastError))
  f.State.Closed=true
  decor:Update(1/60,31)
  decor:Destroy();decor:Destroy()
  check(#f.Root:GetDescendants()==0,'Decor cleanup left geometry')
  check(f.Ground.Anchored and f.Ground.CanCollide,'Decor changed map collision')
  print(quality..' Decor: '..count..' finite visual parts; bounded build and cleanup checked')
 end
end
if modules.Weather then
 local f=scene('High');f.Context.RayParams={}
 local originalRaycast=f.World.Raycast
 f.World.Raycast=function(world,origin,direction,params)
  if direction.Y>0 and f.State.Roof then return{Position=origin+Vector3.new(0,4,0),Normal=-Vector3.yAxis,Instance=f.Ground,Material=f.Ground.Material}end
  return originalRaycast(world,origin,direction,params)
 end
 local weather=modules.Weather.Install(f.Context)
 weather:Update(.25,.25)
 check(weather.Fine.Enabled and weather.Hero.Enabled,'Outdoor near snowfall did not start')
 check(#weather.Cells>0 and #weather.Cells<=81,'Map snowfall volumes missing or unbounded')
 for _,cell in ipairs(weather.Cells)do check(cell.Emitter.Enabled,'Nearby outdoor map volume remained disabled')end
 f.State.Roof=true;weather:Update(.25,.5)
 check(weather.UnderRoof and not weather.Fine.Enabled and not weather.Hero.Enabled,'Roof did not suppress snow')
 for _,cell in ipairs(weather.Cells)do check(not cell.Emitter.Enabled,'Indoor camera retained map snow emitters')end
 f.State.Roof=false;weather:Update(.25,.75)
 check(weather.Fine.Enabled,'Leaving roof failed to resume snow')
 weather:SetEnabled(false)
 check(not weather.Fine.Enabled and not weather.Hero.Enabled,'Snowfall toggle did not stop near layers')
 for _,cell in ipairs(weather.Cells)do check(not cell.Emitter.Enabled,'Snowfall toggle left map volume running')end
 weather:SetEnabled(true);weather:Update(.25,1)
 check(weather.Fine.Enabled,'Snowfall toggle did not restart near layers')
 assertGeometry(f.Root,100)
 weather:Destroy();weather:Destroy()
 check(#f.Root:GetDescendants()==0,'Weather cleanup left volumes')
 print('Weather: bounded map volumes, roof transitions, snow toggle and cleanup checked')
end
print('PASS: '..checks..' fake-Roblox geometry/lifecycle assertions; renderer/server not tested')
