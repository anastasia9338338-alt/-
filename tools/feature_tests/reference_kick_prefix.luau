-- Extra rigid transforms and lifecycle for the new source trajectory checks.
local oldVIndex=V.__index
V.__index=function(v,key)
    if key=="Lerp"then return function(a,b,t)return a+(b-a)*t end end
    return oldVIndex(v,key)
end
CF.__mul=function(a,b)return CFrame.new(a.Position+b.Position)end
CF.__index={ToObjectSpace=function(a,b)return CFrame.new(b.Position-a.Position)end}
function Node:GetDescendants()
    local result={};for _,child in ipairs(self:GetChildren())do result[#result+1]=child;for _,n in ipairs(child:GetDescendants())do result[#result+1]=n end end;return result
end
function Node:FindFirstChildWhichIsA(class)return self:FindFirstChildOfClass(class)end
function Node:GetConnectedParts()return self.ConnectedParts or{}end
local function referenceFixture(mode)
    local sim=Sim.new();currentSim=sim
    sim.RunService.PostSimulation=sim:Signal()
    sim.Physics=function(dt)sim.RunService.PostSimulation:Fire(dt)end
    local t=target("Target")
    t.Root=newNode("Part","HumanoidRootPart",t.Character);t.Root.Position=Vector3.new(0,15,0)
    local model=newNode("Model","RagdollRSC",WORLD)
    local main=newNode("Part","Main",model);local sound=newNode("Part","SoundPart",model)
    main.Position=Vector3.new(0,10,0);sound.Position=Vector3.new(0,10.25,0)
    main.AssemblyMembers={main,sound};main.AssemblyRootPart=main;sound.AssemblyRootPart=main
    main.ConnectedParts={main,sound}
    main.Transparency=.2;sound.Transparency=.3;main.CanQuery=true;sound.CanQuery=true
    local data={Valid=true,Owned=true,Marker=true,Mode=mode or"Faster",Spawned=0,Destroyed=0,Grabs=0,Refresh=0}
    local ctx={RunService=sim.RunService,Clock=function()return sim.Now end,Wait=function()return sim:Wait()end,
        SpawnThread=function(fn)sim:Spawn(fn)end,ContactRate=50,
        KickMode=function()return data.Mode end,
        Find=function()return model.Parent and model end,CanSpawn=function()return true end,
        Spawn=function(valid)data.Spawned+=1;return valid()and model or nil end,
        Destroy=function(value)check(value==model,"Destroyed an unrelated pallet");data.Destroyed+=1;value:Destroy()end,
        Owned=function()return data.Owned and data.Marker end,
        MarkerOwned=function()return data.Marker end,PhysicsOwned=function()return data.Owned end,
        Grab=function()data.Grabs+=1 end,OwnershipBusy=function()return false end,
        RefreshOwnership=function()data.Refresh+=1 end,
        ParkPosition=function()return Vector3.new(0,50,0)end}
    local pallet=Pallet.Install(ctx)
    return {Sim=sim,Target=t,Model=model,Main=main,Sound=sound,Data=data,Context=ctx,Pallet=pallet,Valid=function()return data.Valid end}
end
