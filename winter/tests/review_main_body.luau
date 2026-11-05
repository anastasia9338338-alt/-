do
 local f=fixture(true)
 local state=runMain(requireModule)
 check(state and not state.Closed and #warnings==0,'Main startup failed: '..table.concat(warnings,' / '))
 for _=1,60 do f.Heartbeat:Fire(1/60)end
 check(f.Ground.Material==Enum.Material.Snow,'Map palette did not apply')
 check(f.Ground.Anchored and f.Ground.CanCollide and f.Ground.CanTouch and f.Ground.CanQuery,'Main changed original collision flags')
 check(f.Lighting.ClockTime==13.8,'Day lighting did not apply')
 state:SetMood('Dusk');check(f.Lighting.ClockTime==17.65,'Dusk toggle failed')
 local replacement=runMain(requireModule)
 check(state.Closed and replacement and not replacement.Closed,'Re-execution did not unload old runtime')
 for _=1,60 do f.Heartbeat:Fire(1/60)end
 replacement:Unload();replacement:Unload()
 check(host.AstralWinter==nil and countConnected(f.Heartbeat)==0 and countConnected(f.World.DescendantAdded)==0,'Main unload left callbacks/runtime')
 check(f.World:FindFirstChild('AstralWinter_Visuals')==nil,'Main unload left winter geometry')
 check(f.Player:FindFirstChild('PlayerGui'):FindFirstChild('AstralWinterUI')==nil,'Main unload left UI')
 check(f.Ground.Material==Enum.Material.Grass and f.Ground.Color==f.OriginalColor,'Map original material/color were not restored')
 check(f.Lighting.ClockTime==9 and f.Lighting.Brightness==1,'Lighting originals were not restored')
 check(f.Terrain.WaterWaveSpeed==4 and f.Terrain.WaterTransparency==.6,'Water originals were not restored')
 check(f.Terrain.Decoration==true and f.Terrain:GetMaterialColor(Enum.Material.Grass)==Color3.fromRGB(90,100,110),'Terrain palette/grass decoration were not restored')
end
do
 local f=fixture(true);local state=runMain(requireModule)
 for _=1,3 do f.Heartbeat:Fire(1/60)end
 f.Ground.Parent=nil;state:Unload()
 check(f.Ground.Material==Enum.Material.Grass and f.Ground.Color==f.OriginalColor,'Temporarily unparented map part was not restored')
end
do
 local f=fixture(true);local state=runMain(requireModule)
 for _=1,3 do f.Heartbeat:Fire(1/60)end
 local changed=Color3.fromRGB(210,20,30)
 f.Ground.Color=changed;f.Lighting.ClockTime=22
 state:Unload()
 check(f.Ground.Color==changed and f.Lighting.ClockTime==22,'Unload overwrote later changes made outside Winter')
end
do
 local f=fixture(false)
 f.Player._WaitForChild=function(self,name)
  local child=self:FindFirstChild(name)
  if child then return child end
  return coroutine.yield('awaiting GUI')
 end
 local co=coroutine.create(function()runMain(requireModule)end)
 local ok,why=coroutine.resume(co)
 check(ok and why=='awaiting GUI','Main did not pause at expected GUI wait')
 local state=host.AstralWinter;check(state~=nil and not state.Closed,'Runtime not registered before GUI wait')
 state:Unload()
 local gui=newNode('PlayerGui','PlayerGui');gui.Parent=f.Player
 ok,why=coroutine.resume(co,gui)
 check(ok and coroutine.status(co)=='dead','GUI-wait cancellation failed: '..tostring(why))
 check(countConnected(f.Heartbeat)==0 and countConnected(f.World.DescendantAdded)==0,'GUI cancellation registered callbacks after unload')
 check(f.World:FindFirstChild('AstralWinter_Visuals')==nil and gui:FindFirstChild('AstralWinterUI')==nil,'GUI-wait cancellation left objects')
end
do
 local f=fixture(true)
 f.Ground.CFrame=CFrame.new(0,9999.5,0);f.Player.Character.HumanoidRootPart.CFrame=CFrame.new(0,10003,0)
 f.World.CurrentCamera={CFrame=CFrame.new(0,10008,10)}
 local state=runMain(requireModule)
 check(state and not state.Closed,'Elevated map startup failed: '..table.concat(warnings,' / '))
 check(state.Context.Bounds.Min.Y<=state.Context.Bounds.Max.Y,'Elevated bounds were inverted')
 local hit=state.Context.Ground(0,0)
 check(hit and hit.Position.Y==10000,'Elevated map Ground ray missed original floor')
 state:Unload()
end
print('PASS: '..checks..' fake-client Main startup/reload/unload/restoration assertions; live Roblox not tested')
