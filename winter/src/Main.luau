-- Independent local winter environment. No remotes, character or toy drivers.
local requireModule=...
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Workspace=game:GetService("Workspace")
local player=Players.LocalPlayer
assert(player,"Winter must run on the client")
local host=getgenv and getgenv()or shared or _G
local old=host.AstralWinter
if type(old)=="table"and type(old.Unload)=="function"then old:Unload()end

local Config={Quality="High",Snowfall=true,Footprints=true,Mood="Day"}
local state={Version="1.0",Config=Config,Closed=false,Connections={},Owned={},Restores={},TerrainColors={},Paletted=setmetatable({},{__mode="k"}),MapParts={},PaletteQueue={},PaletteIndex=1,Status="Подготовка зимы…"}
host.AstralWinter=state
local root=Instance.new("Folder");root.Name="AstralWinter_Visuals";root.Parent=Workspace;state.Root=root
local function owned(object)state.Owned[#state.Owned+1]=object;return object end
local function track(object,key,value)
    local record=state.Restores[object]
    if not record then record={};state.Restores[object]=record end
    local item=record[key]
    if not item then
        local ok,original=pcall(function()return object[key]end)
        if not ok then return end
        item={Original=original};record[key]=item
    end
    local ok=pcall(function()object[key]=value end)
    if ok then item.Applied=value end
end
local function connect(signal,fn)
    if state.Closed then return end
    local c=signal:Connect(fn);state.Connections[#state.Connections+1]=c;return c
end
function state:Unload()
    if self.Closed then return end;self.Closed=true
    for _,c in ipairs(self.Connections)do pcall(function()c:Disconnect()end)end
    for _,name in ipairs({"Weather","Snow","Decor"})do local v=self[name];if v then pcall(v.Destroy,v)end end
    for object,properties in pairs(self.Restores)do
        for key,item in pairs(properties)do
            pcall(function()if object[key]==item.Applied then object[key]=item.Original end end)
        end
    end
    for material,item in pairs(self.TerrainColors)do
        pcall(function()if Workspace.Terrain:GetMaterialColor(material)==item.Applied then Workspace.Terrain:SetMaterialColor(material,item.Original)end end)
    end
    for i=#self.Owned,1,-1 do pcall(function()self.Owned[i]:Destroy()end)end
    pcall(function()root:Destroy()end)
    table.clear(self.Connections);table.clear(self.Restores);table.clear(self.TerrainColors)
    if host.AstralWinter==self then host.AstralWinter=nil end
end

local function finite(n)return type(n)=="number"and n==n and math.abs(n)<1e7 end
local map=Workspace:FindFirstChild("Map")
local function isMapPart(part)
    if not part:IsA("BasePart")or not part.Anchored or part.Transparency>=.98 or part:IsDescendantOf(root)then return false end
    if not finite(part.Position.X)or not finite(part.Position.Y)or not finite(part.Position.Z)then return false end
    local node=part.Parent
    while node and node~=Workspace do
        if node:IsA("Model")and node:FindFirstChildOfClass("Humanoid")then return false end
        local name=node.Name
        if name:find("SpawnedInToys",1,true)or name=="PlotItems"or name=="AstralWinter_Visuals"then return false end
        if name=="Train"or name=="SantaSleigh"or name:find("Tractor",1,true)then return false end
        node=node.Parent
    end
    return not map or part:IsDescendantOf(map)or part==Workspace:FindFirstChild("Baseplate")
end
local min,max=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
local function include(part)
    local cf,s=part.CFrame,part.Size*.5
    local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
    local ext=Vector3.new(math.abs(r.X)*s.X+math.abs(u.X)*s.Y+math.abs(l.X)*s.Z,
        math.abs(r.Y)*s.X+math.abs(u.Y)*s.Y+math.abs(l.Y)*s.Z,math.abs(r.Z)*s.X+math.abs(u.Z)*s.Y+math.abs(l.Z)*s.Z)
    min=Vector3.new(math.min(min.X,cf.X-ext.X),math.min(min.Y,cf.Y-ext.Y),math.min(min.Z,cf.Z-ext.Z))
    max=Vector3.new(math.max(max.X,cf.X+ext.X),math.max(max.Y,cf.Y+ext.Y),math.max(max.Z,cf.Z+ext.Z))
end
local function palette(part)
    if state.Paletted[part]or not isMapPart(part)then return end
    state.Paletted[part]=true
    local material=part.Material
    if material==Enum.Material.Grass or material==Enum.Material.LeafyGrass or material==Enum.Material.Ground
        or material==Enum.Material.Mud or material==Enum.Material.Sand then
        track(part,"Color",Color3.fromRGB(231,241,249));track(part,"Material",Enum.Material.Snow)
        for _,v in ipairs(part:GetChildren())do if v:IsA("Texture")or v:IsA("Decal")then track(v,"Transparency",1)end end
    elseif material==Enum.Material.Rock or material==Enum.Material.Slate or material==Enum.Material.Basalt then
        track(part,"Color",part.Color:Lerp(Color3.fromRGB(203,220,235),.46))
    end
end
local function mood()
    local dusk=Config.Mood=="Dusk"
    track(Lighting,"ClockTime",dusk and 17.65 or 13.8)
    track(Lighting,"Brightness",dusk and 1.5 or 2.2)
    track(Lighting,"Ambient",dusk and Color3.fromRGB(101,118,151)or Color3.fromRGB(157,176,195))
    track(Lighting,"OutdoorAmbient",dusk and Color3.fromRGB(105,124,156)or Color3.fromRGB(174,192,210))
    track(Lighting,"FogColor",dusk and Color3.fromRGB(153,174,203)or Color3.fromRGB(207,226,242))
    track(Lighting,"FogStart",220);track(Lighting,"FogEnd",1500)
    track(Lighting,"EnvironmentDiffuseScale",.65);track(Lighting,"EnvironmentSpecularScale",.7)
end
function state:SetMood(value)
    if self.Closed then return end
    Config.Mood=value=="Dusk"and "Dusk"or "Day";mood()
end
function state:SetSnow(value)
    if self.Closed then return end
    Config.Snowfall=value==true
    if self.Weather then self.Weather:SetEnabled(Config.Snowfall)end
end
function state:SetFootprints(value)
    if self.Closed then return end
    Config.Footprints=value==true
    if self.Snow and self.Snow.SetFootprints then self.Snow:SetFootprints(Config.Footprints)end
end

local function texture()
    local getAsset=getcustomasset or getsynasset
    if type(writefile)~="function"or type(getAsset)~="function"then return nil end
    local ok,result=pcall(function()
        local path="AstralWinter_snowflake_v1.png"
        local base64=requireModule("Texture")
        local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";local codes={}
        for i=1,#alphabet do codes[alphabet:sub(i,i)]=i-1 end
        local bytes={}
        for i=1,#base64,4 do
            local a,b,c,d=base64:sub(i,i),base64:sub(i+1,i+1),base64:sub(i+2,i+2),base64:sub(i+3,i+3)
            local n=(codes[a]or 0)*262144+(codes[b]or 0)*4096+(codes[c]or 0)*64+(codes[d]or 0)
            bytes[#bytes+1]=string.char(math.floor(n/65536)%256)
            if c~="="then bytes[#bytes+1]=string.char(math.floor(n/256)%256)end
            if d~="="then bytes[#bytes+1]=string.char(n%256)end
        end
        writefile(path,table.concat(bytes));return getAsset(path)
    end)
    return ok and type(result)=="string"and result~=""and result or nil
end
local function buildUI()
    local gui=owned(Instance.new("ScreenGui"));gui.Name="AstralWinterUI";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false
    local parent=player:WaitForChild("PlayerGui",10);if not parent or state.Closed then gui:Destroy();return end
    gui.Parent=parent
    local panel=Instance.new("Frame");panel.Name="Winter";panel.AnchorPoint=Vector2.new(1,0)
    panel.Position=UDim2.new(1,-18,0,18);panel.Size=UDim2.fromOffset(246,178)
    panel.BackgroundColor3=Color3.fromRGB(18,32,48);panel.BackgroundTransparency=.12;panel.BorderSizePixel=0;panel.Parent=gui
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,14);corner.Parent=panel
    local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(174,214,236);stroke.Transparency=.55;stroke.Parent=panel
    local title=Instance.new("TextLabel");title.BackgroundTransparency=1;title.Position=UDim2.fromOffset(14,8);title.Size=UDim2.new(1,-55,0,25)
    title.Text="❄  ЗИМНЯЯ СКАЗКА";title.TextColor3=Color3.fromRGB(234,247,255);title.Font=Enum.Font.GothamBold;title.TextSize=14;title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=panel
    local status=Instance.new("TextLabel");status.BackgroundTransparency=1;status.Position=UDim2.fromOffset(14,34);status.Size=UDim2.new(1,-28,0,20)
    status.Text="Снег, следы и новогодние огни";status.TextColor3=Color3.fromRGB(165,196,216);status.Font=Enum.Font.Gotham;status.TextSize=11;status.TextXAlignment=Enum.TextXAlignment.Left;status.Parent=panel
    local function button(text,y,callback)
        local b=Instance.new("TextButton");b.Position=UDim2.fromOffset(12,y);b.Size=UDim2.new(1,-24,0,27)
        b.BackgroundColor3=Color3.fromRGB(38,60,78);b.BorderSizePixel=0;b.TextColor3=Color3.fromRGB(235,246,250);b.Text=text;b.TextSize=12;b.Font=Enum.Font.GothamMedium;b.Parent=panel
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=b
        connect(b.Activated,function()if not state.Closed then callback(b)end end);return b
    end
    button("Свет: зимний день",61,function(b)state:SetMood(Config.Mood=="Day"and "Dusk"or "Day");b.Text=Config.Mood=="Day"and "Свет: зимний день"or "Свет: праздничные сумерки"end)
    button("Снегопад: включён",93,function(b)state:SetSnow(not Config.Snowfall);b.Text=Config.Snowfall and "Снегопад: включён"or "Снегопад: выключен"end)
    button("Следы в снегу: включены",125,function(b)state:SetFootprints(not Config.Footprints);b.Text=Config.Footprints and "Следы в снегу: включены"or "Следы в снегу: выключены"end)
    local close=Instance.new("TextButton");close.BackgroundTransparency=1;close.Position=UDim2.new(1,-36,0,7);close.Size=UDim2.fromOffset(28,27);close.Text="×";close.TextSize=24;close.TextColor3=Color3.fromRGB(204,226,241);close.Parent=panel
    connect(close.Activated,function()state:Unload()end)
    local collapse=Instance.new("TextButton");collapse.AnchorPoint=Vector2.new(1,0);collapse.Position=UDim2.new(1,-18,0,18);collapse.Size=UDim2.fromOffset(42,38)
    collapse.BackgroundColor3=panel.BackgroundColor3;collapse.Text="❄";collapse.TextSize=23;collapse.TextColor3=title.TextColor3;collapse.Visible=true;collapse.Parent=gui
    panel.Visible=false
    local cc=Instance.new("UICorner");cc.CornerRadius=UDim.new(0,12);cc.Parent=collapse
    connect(title.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then panel.Visible=false;collapse.Visible=true end end)
    connect(collapse.Activated,function()panel.Visible=true;collapse.Visible=false end)
end

local function start()
    local source=(map or Workspace):GetDescendants()
    for i,part in ipairs(source)do
        if state.Closed then return end
        if isMapPart(part)then state.MapParts[#state.MapParts+1]=part;include(part);state.PaletteQueue[#state.PaletteQueue+1]=part end
        if i%400==0 then RunService.Heartbeat:Wait()end
    end
    local character=player.Character;local actor=character and character:FindFirstChild("HumanoidRootPart")
    local center=actor and actor.Position or Vector3.zero
    if #state.MapParts==0 then min=center-Vector3.new(280,40,280);max=center+Vector3.new(280,160,280)end
    -- Clamp spans around the playable area, not absolute world heights.
    -- An elevated map must still receive rays from above its actual floor.
    local function median(axis)
        local values={}
        for _,part in ipairs(state.MapParts)do values[#values+1]=part.Position[axis]end
        if #values==0 then return center[axis]end
        table.sort(values);return values[math.ceil(#values*.5)]
    end
    local pivot=Vector3.new(actor and actor.Position.X or median("X"),median("Y"),actor and actor.Position.Z or median("Z"))
    local function span(lo,hi,anchor,half)
        if hi-lo<=half*2 then return lo,hi end
        local at=math.clamp(anchor,lo+half,hi-half)
        return at-half,at+half
    end
    local ax,bx=span(min.X,max.X,pivot.X,1400)
    local ay,by=span(min.Y,max.Y,pivot.Y,3900)
    local az,bz=span(min.Z,max.Z,pivot.Z,1400)
    min,max=Vector3.new(ax,ay,az),Vector3.new(bx,by,bz)
    local params=RaycastParams.new();params.IgnoreWater=false;params.RespectCanCollide=true
    local function refreshFilters()
        if map then params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={map,Workspace.Terrain}
        else
            params.FilterType=Enum.RaycastFilterType.Exclude
            local excluded={root}
            for _,who in ipairs(Players:GetPlayers())do if who.Character then excluded[#excluded+1]=who.Character end end
            for _,child in ipairs(Workspace:GetChildren())do
                if child.Name:find("SpawnedInToys",1,true)or child.Name=="PlotItems"
                    or child:IsA("Model")and child:FindFirstChildOfClass("Humanoid")then excluded[#excluded+1]=child end
            end
            params.FilterDescendantsInstances=excluded
        end
    end
    refreshFilters()
    local ctx={World=Workspace,Root=root,Player=player,RunService=RunService,Bounds={Min=min,Max=max,Center=(min+max)*.5},
        Config=Config,MapParts=state.MapParts,RayParams=params,Alive=function()return not state.Closed end,IsMapPart=isMapPart}
    local rayTop=max.Y+80;local rayDepth=math.clamp(max.Y-min.Y+180,300,8000)
    ctx.Ground=function(x,z)
        local hit=Workspace:Raycast(Vector3.new(x,rayTop,z),Vector3.new(0,-rayDepth,0),params)
        if hit and hit.Normal.Y>.65 and(hit.Instance==Workspace.Terrain or isMapPart(hit.Instance))then return hit end
    end
    state.Context=ctx
    mood()
    local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then atmosphere=owned(Instance.new("Atmosphere"));atmosphere.Parent=Lighting end
    track(atmosphere,"Density",.18);track(atmosphere,"Offset",.1);track(atmosphere,"Haze",1.1)
    track(atmosphere,"Color",Color3.fromRGB(218,235,250));track(atmosphere,"Decay",Color3.fromRGB(144,174,206));track(atmosphere,"Glare",.08)
    local bloom=owned(Instance.new("BloomEffect"));bloom.Name="AstralWinterBloom";bloom.Intensity=.2;bloom.Size=20;bloom.Threshold=1.65;bloom.Parent=Lighting
    local color=owned(Instance.new("ColorCorrectionEffect"));color.Name="AstralWinterGrade";color.Brightness=.015;color.Contrast=.035;color.Saturation=-.06;color.TintColor=Color3.fromRGB(240,248,255);color.Parent=Lighting
    local terrain=Workspace.Terrain
    track(terrain,"WaterColor",Color3.fromRGB(135,193,218));track(terrain,"WaterWaveSize",.05);track(terrain,"WaterWaveSpeed",1);track(terrain,"WaterTransparency",.35)
    track(terrain,"Decoration",false)
    for _,material in ipairs({Enum.Material.Grass,Enum.Material.LeafyGrass,Enum.Material.Ground,Enum.Material.Mud,Enum.Material.Sand,Enum.Material.Rock,Enum.Material.Slate})do
        local ok,original=pcall(terrain.GetMaterialColor,terrain,material)
        if ok then
            local color=Color3.fromRGB(226,238,247)
            local set=pcall(terrain.SetMaterialColor,terrain,material,color)
            if set then state.TerrainColors[material]={Original=original,Applied=color}end
        end
    end
    ctx.SnowTexture=texture()
    if state.Closed then return end
    state.Weather=requireModule("Weather").Install(ctx)
    state.Snow=requireModule("Snow").Install(ctx)
    state.Decor=requireModule("Decor").Install(ctx)
    if state.Closed then return end
    buildUI()
    if state.Closed then return end
    connect(Workspace.DescendantAdded,function(part)
        if isMapPart(part)then state.PaletteQueue[#state.PaletteQueue+1]=part end
    end)
    local elapsed=0
    connect(RunService.Heartbeat,function(dt)
        if state.Closed then return end
        local ok,message=pcall(function()
            local count=0
            while state.PaletteIndex<=#state.PaletteQueue and count<35 do
                local part=state.PaletteQueue[state.PaletteIndex];state.PaletteIndex+=1;count+=1
                if part.Parent then palette(part)end
            end
            state.Weather:Update(dt,os.clock());state.Snow:Update(dt,os.clock());state.Decor:Update(dt,os.clock())
            elapsed+=dt
            if elapsed>=2 then elapsed=0;refreshFilters();state.Status="Зима включена"end
        end)
        if not ok then state.LastError=tostring(message);warn("Winter update: "..state.LastError);state:Unload()end
    end)
end
local ok,message=xpcall(start,function(err)return debug.traceback(tostring(err),2)end)
if not ok then state.LastError=tostring(message);state:Unload();warn("Winter initialization: "..tostring(message))end
return state
