-- Winter Wonderland 1.0 | standalone client-side winter scenery.
-- Snow, soft footprints, holiday decor. Re-executing replaces this instance.
-- Open the snowflake button for controls; close (×) restores the scenery.
local loaders,cache,loading={},{},{}
loaders.Texture=function(...)
-- Embedded six-armed snow crystal; optional custom-asset texture.
return "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"

end
loaders.Weather=function(...)
-- Layered snow volumes cover the map; a finer layer follows the camera.
local Weather={};Weather.__index=Weather
local function emitter(parent,texture,rate,size,life,speed)
    local e=Instance.new("ParticleEmitter")
    e.Name="Snowflakes";e.Texture=texture;e.Rate=rate
    e.EmissionDirection=Enum.NormalId.Bottom;e.SpreadAngle=Vector2.new(12,12)
    e.Lifetime=NumberRange.new(life*.8,life);e.Speed=NumberRange.new(speed*.7,speed)
    e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size*.7),NumberSequenceKeypoint.new(.4,size),NumberSequenceKeypoint.new(1,size*.65)})
    e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.12,.12),NumberSequenceKeypoint.new(.8,.2),NumberSequenceKeypoint.new(1,1)})
    e.Color=ColorSequence.new(Color3.fromRGB(244,250,255),Color3.fromRGB(210,231,250))
    e.LightEmission=.18;e.LightInfluence=.12;e.Rotation=NumberRange.new(-180,180)
    e.RotSpeed=NumberRange.new(-35,35);e.Drag=.15;e.Acceleration=Vector3.new(1,-1,0)
    e.LockedToPart=false;e.Enabled=false;e.Parent=parent
    return e
end
local function volume(parent,name,size,position)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=position
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
    p.Transparency=1;p.CastShadow=false;p.Parent=parent;return p
end
function Weather.Install(ctx)
    local self=setmetatable({Context=ctx,Cells={},Elapsed=0,WindAt=0,UnderRoof=false,Enabled=true},Weather)
    self.Folder=Instance.new("Folder");self.Folder.Name="Snowfall";self.Folder.Parent=ctx.Root
    local bounds=ctx.Bounds;local size=bounds.Max-bounds.Min
    local high=ctx.Config.Quality=="High"
    local nx=math.clamp(math.ceil(size.X/140),1,high and 9 or 6)
    local nz=math.clamp(math.ceil(size.Z/140),1,high and 9 or 6)
    local sx,sz=math.max(size.X/nx,40),math.max(size.Z/nz,40)
    local texture=ctx.SnowTexture or "rbxasset://textures/particles/sparkles_main.dds"
    for ix=0,nx-1 do for iz=0,nz-1 do
        local x,z=bounds.Min.X+(ix+.5)*sx,bounds.Min.Z+(iz+.5)*sz
        local hit=ctx.Ground(x,z)
        if hit then
            local p=volume(self.Folder,"MapSnow",Vector3.new(sx,1,sz),Vector3.new(x,hit.Position.Y+58,z))
            local e=emitter(p,texture,high and 7 or 4,.16,8,11)
            self.Cells[#self.Cells+1]={Part=p,Emitter=e,Rate=e.Rate,Position=p.Position}
        end
    end end
    self.Near=volume(self.Folder,"NearSnow",Vector3.new(64,1,64),Vector3.zero)
    self.Fine=emitter(self.Near,texture,high and 155 or 85,.18,5.5,11)
    self.FineRate=self.Fine.Rate
    self.Hero=emitter(self.Near,texture,high and 24 or 12,.34,5,8)
    self.HeroRate=self.Hero.Rate
    return self
end
function Weather:SetEnabled(value)
    self.Enabled=value==true
    if not self.Enabled then
        self.Fine.Enabled=false;self.Fine:Clear();self.Hero.Enabled=false;self.Hero:Clear()
        for _,c in ipairs(self.Cells)do c.Emitter.Enabled=false;c.Emitter:Clear()end
    end
end
function Weather:Update(dt,now)
    if self.Closed then return end
    local ctx=self.Context;local camera=ctx.World.CurrentCamera
    if not camera then return end
    local position=camera.CFrame.Position
    self.Near.Position=position+Vector3.new(0,26,0)
    self.Elapsed+=dt
    if self.Elapsed<.2 then return end;self.Elapsed=0
    local hit=ctx.World:Raycast(position+Vector3.new(0,.5,0),Vector3.new(0,100,0),ctx.RayParams)
    local roof=hit~=nil
    if roof and not self.UnderRoof then
        self.Fine:Clear();self.Hero:Clear()
        for _,c in ipairs(self.Cells)do c.Emitter:Clear()end
    end
    self.UnderRoof=roof
    local active=self.Enabled and ctx.Config.Snowfall~=false and not roof
    self.Fine.Enabled=active;self.Hero.Enabled=active
    local radius=ctx.Config.Quality=="High"and 720 or 480
    for _,c in ipairs(self.Cells)do
        local offset=c.Position-position
        c.Emitter.Enabled=active and offset.X*offset.X+offset.Z*offset.Z<radius*radius
    end
    if now>=self.WindAt then
        self.WindAt=now+1
        local wind=Vector3.new(1.8+math.sin(now*.13)*1.1,-1,math.cos(now*.17)*1.4)
        self.Fine.Acceleration=wind;self.Hero.Acceleration=wind*.7
        for _,c in ipairs(self.Cells)do c.Emitter.Acceleration=wind end
    end
end
function Weather:Destroy()
    if self.Closed then return end;self.Closed=true
    self.Folder:Destroy();table.clear(self.Cells)
end
return Weather

end
loaders.Snow=function(...)
-- Snow is client geometry. Original surfaces, collision and Terrain are untouched.
-- A thin map coat sits below pooled detail tiles; actual tile heights compress
-- beneath feet. Sole/heel/tread marks add detail at the compressed surface.
local Snow={};Snow.__index=Snow
local UP=Vector3.new(0,1,0)
local WHITE=Color3.fromRGB(240,247,251)
local SHADE=Color3.fromRGB(203,220,231)
local profiles={
    High={Cell=.9,Radius=8,Tiles=1000,Marks=80,Caps=550,Terrain=260,Build=12},
    Medium={Cell=1.1,Radius=7,Tiles=700,Marks=60,Caps=400,Terrain=220,Build=10},
    Low={Cell=1.5,Radius=6,Tiles=360,Marks=40,Caps=260,Terrain=140,Build=8},
}
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
local function live(v)return v and v.Parent~=nil end
local function vfinite(v)return v and finite(v.X)and finite(v.Y)and finite(v.Z)end
local function key(x,z)return x..":"..z end
local function flat(v)return Vector3.new(v.X,0,v.Z)end
local function make(parent,name,size,frame,color)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=frame
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
    p.CastShadow=false;p.Material=Enum.Material.Snow;p.Color=color or WHITE
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent
    return p
end
local function folder(parent,name)local f=Instance.new("Folder");f.Name=name;f.Parent=parent;return f end
local function outdoorPart(self,p)
    if p:IsA("Terrain")then return false end
    if not p:IsA("BasePart")or not p.Anchored or not p.CanCollide or p.Transparency>=.85
        or p:IsDescendantOf(self.Context.Root)or not self.Context.IsMapPart(p)then return false end
    if p.Size.X<1.8 or p.Size.Z<1.8 or p.Size.X>5000 or p.Size.Z>5000 then return false end
    if p.CFrame.UpVector:Dot(UP)<.985 then return false end
    if p.Material==Enum.Material.Glass or p.Material==Enum.Material.Neon or p.Material==Enum.Material.Water then return false end
    if p:IsA("MeshPart")and p.Size.Y>1 then return false end
    return true
end
function Snow.Install(context)
    local profile=profiles[context.Config.Quality]or profiles.High
    local self=setmetatable({Context=context,Profile=profile,Queue={},Queued=setmetatable({},{__mode="k"}),
        Caps={},CapCount=0,TerrainCount=0,Tiles={},FreeTiles={},TileCount=0,Marks={},MarkIndex=0,
        ScanIndex=1,GridQueue={},GridIndex=1,LastGrid=nil,Elapsed=0,Now=0,Side=false,
        LastStep=0,Travel=0,NextPressure=0,Stats={Steps=0,Compressed=0}},Snow)
    self.Folder=folder(context.Root,"Snow Cover")
    self.CapFolder=folder(self.Folder,"Map Frost")
    self.TileFolder=folder(self.Folder,"Soft Snow")
    self.MarkFolder=folder(self.Folder,"Footprints")
    local list=context.MapParts or context.World:GetDescendants()
    for _,p in ipairs(list)do
        if #self.Queue>=12000 then break end
        if p:IsA("BasePart")and not p:IsDescendantOf(context.Root)and context.IsMapPart(p)then
            self.Queue[#self.Queue+1]=p;self.Queued[p]=true
        end
    end
    self.Added=context.World.DescendantAdded:Connect(function(p)
        if self.Closed or #self.Queue-self.ScanIndex>1600 or self.CapCount>=profile.Caps then return end
        if p:IsA("BasePart")and not p:IsDescendantOf(context.Root)and not self.Queued[p]and context.IsMapPart(p)then
            self.Queued[p]=true;self.Queue[#self.Queue+1]=p
        end
    end)
    local b=context.Bounds
    local width=math.max(1,b.Max.X-b.Min.X);local depth=math.max(1,b.Max.Z-b.Min.Z)
    self.TerrainCell=math.max(8,math.sqrt(width*depth/profile.Terrain))
    self.TerrainX,self.TerrainZ=b.Min.X+self.TerrainCell*.5,b.Min.Z+self.TerrainCell*.5
    self.TerrainDone=false
    return self
end
function Snow:Coat(p)
    if self.CapCount>=self.Profile.Caps or not live(p)or self.Caps[p]or not outdoorPart(self,p)then return end
    local top=p.CFrame*CFrame.new(0,p.Size.Y*.5,0)
    local probes={Vector3.zero,Vector3.new(p.Size.X*.38,0,p.Size.Z*.38),Vector3.new(-p.Size.X*.38,0,-p.Size.Z*.38)}
    local exposed=false
    for _,offset in ipairs(probes)do
        local point=top*offset;local hit=self.Context.Ground(point.X,point.Z)
        if hit and hit.Instance==p and hit.Normal.Y>.95 and math.abs(hit.Position.Y-point.Y)<.4 then exposed=true;break end
    end
    if not exposed then return end
    local coat=make(self.CapFolder,"Snow Cap",Vector3.new(math.max(.1,p.Size.X-.025),.12,math.max(.1,p.Size.Z-.025)),
        top*CFrame.new(0,.035,0),WHITE)
    self.Caps[p]={Part=coat,Frame=p.CFrame,Size=p.Size};self.CapCount+=1
end
function Snow:BuildTerrain()
    if self.TerrainDone or self.TerrainCount>=self.Profile.Terrain then self.TerrainDone=true;return end
    local bounds=self.Context.Bounds;local x,z=self.TerrainX,self.TerrainZ
    local hit=self.Context.Ground(x,z)
    if hit and hit.Instance:IsA("Terrain")and hit.Normal.Y>.94 and hit.Material~=Enum.Material.Water then
        local half=self.TerrainCell*.47;local acceptable=true
        for _,offset in ipairs({Vector3.new(half,0,half),Vector3.new(-half,0,-half)})do
            local edge=self.Context.Ground(x+offset.X,z+offset.Z)
            if not edge or not edge.Instance:IsA("Terrain")or math.abs(edge.Position.Y-hit.Position.Y)>.18 then acceptable=false;break end
        end
        if acceptable then
            make(self.CapFolder,"Terrain Powder",Vector3.new(self.TerrainCell+.03,.12,self.TerrainCell+.03),
                CFrame.new(x,hit.Position.Y+.035,z),WHITE)
            self.TerrainCount+=1
        end
    end
    self.TerrainX+=self.TerrainCell
    if self.TerrainX>bounds.Max.X then self.TerrainX=bounds.Min.X+self.TerrainCell*.5;self.TerrainZ+=self.TerrainCell end
    if self.TerrainZ>bounds.Max.Z then self.TerrainDone=true end
end
function Snow:QueueGrid(position)
    local c=self.Profile.Cell;local gx,gz=math.floor(position.X/c+.5),math.floor(position.Z/c+.5)
    local level=math.floor(position.Y/4)
    if self.LastGrid and self.LastGrid.X==gx and self.LastGrid.Z==gz and self.LastGrid.Level==level then return end
    self.LastGrid={X=gx,Z=gz,Level=level};self.GridQueue={};self.GridIndex=1
    local radius=math.ceil(self.Profile.Radius/c)
    for dx=-radius,radius do for dz=-radius,radius do
        if dx*dx+dz*dz<=(radius+.5)^2 then
            local x,z=gx+dx,gz+dz;local k=key(x,z);local cached=self.Tiles[k]
            if cached and math.abs(cached.Ground-(position.Y-3))>5 then self:RemoveTile(k);cached=nil end
            if not cached then self.GridQueue[#self.GridQueue+1]={X=x,Z=z,Distance=dx*dx+dz*dz}end
        end
    end end
    table.sort(self.GridQueue,function(a,b)return a.Distance<b.Distance end)
end
function Snow:RemoveTile(k)
    local tile=self.Tiles[k]
    if tile then
        if live(tile.Part)and #self.FreeTiles<60 then
            tile.Part.Transparency=1;tile.Part.CFrame=CFrame.new(0,-10000,0);self.FreeTiles[#self.FreeTiles+1]=tile.Part
        else tile.Part:Destroy()end
        self.Tiles[k]=nil;self.TileCount-=1
    end
end
function Snow:Prune(position)
    local c=self.Profile.Cell;local keep=self.Profile.Radius+2*c
    local remove={}
    for k,tile in pairs(self.Tiles)do
        local d=(Vector3.new(tile.X,position.Y,tile.Z)-position).Magnitude
        if not live(tile.Source)or not live(tile.Part)or d>keep and(self.Now-tile.Pressed>65 or d>100)then remove[#remove+1]=k end
    end
    for _,k in ipairs(remove)do self:RemoveTile(k)end
    if self.TileCount>=self.Profile.Tiles then
        local ranked={}
        for k,tile in pairs(self.Tiles)do
            local distance=(Vector3.new(tile.X,position.Y,tile.Z)-position).Magnitude
            ranked[#ranked+1]={Key=k,Rank=distance+(self.Now-tile.Pressed)*.08}
        end
        table.sort(ranked,function(a,b)return a.Rank>b.Rank end)
        local limit=self.Profile.Tiles-math.max(32,self.Profile.Build*2)
        for _,item in ipairs(ranked)do if self.TileCount<=limit then break end;self:RemoveTile(item.Key)end
    end
end
function Snow:BuildTile(cell,position)
    local c=self.Profile.Cell;local k=key(cell.X,cell.Z)
    if self.Tiles[k]then return end
    if self.TileCount>=self.Profile.Tiles then self:Prune(position)end
    if self.TileCount>=self.Profile.Tiles then return end
    local x,z=cell.X*c,cell.Z*c;local hit=self.Context.Ground(x,z)
    if not hit or hit.Normal.Y<.94 or hit.Material==Enum.Material.Water then return end
    -- Do not grow a local snow sheet on a roof high above the walking avatar.
    if hit.Position.Y>position.Y+2 or hit.Position.Y<position.Y-12 then return end
    if not hit.Instance:IsA("Terrain")and hit.Instance:IsA("BasePart")then
        -- Conservative source bounds prevent detail squares bridging ledges.
        local localPoint=hit.Instance.CFrame:PointToObjectSpace(hit.Position)
        local pad=c*.72
        if math.abs(localPoint.X)+pad>hit.Instance.Size.X*.5 or math.abs(localPoint.Z)+pad>hit.Instance.Size.Z*.5 then return end
    else
        local edge=self.Context.Ground(x+c*.45,z+c*.45)
        if not edge or math.abs(edge.Position.Y-hit.Position.Y)>.22 then return end
    end
    local noise=math.noise(x*.07,z*.07,0)*.018
    local top=hit.Position.Y+.29+noise
    local height=top-hit.Position.Y-.095
    local p=table.remove(self.FreeTiles)
    if not p or not live(p)then p=make(self.TileFolder,"Soft Snow Tile",Vector3.new(c+.035,height,c+.035),CFrame.new(x,top-height*.5,z),WHITE)
    else p.Size=Vector3.new(c+.035,height,c+.035);p.CFrame=CFrame.new(x,top-height*.5,z);p.Color=WHITE;p.Transparency=0 end
    self.Tiles[k]={Part=p,Source=hit.Instance,X=x,Z=z,Ground=hit.Position.Y,Top=top,Noise=noise,Surface=top,Depth=0,Target=0,Pressed=-1000}
    self.TileCount+=1
end
function Snow:Press(point,heading,strength)
    local c=self.Profile.Cell;local gx,gz=math.floor(point.X/c+.5),math.floor(point.Z/c+.5)
    local right=Vector3.new(-heading.Z,0,heading.X)
    local compressed=false
    for dx=-2,2 do for dz=-2,2 do
        local tile=self.Tiles[key(gx+dx,gz+dz)]
        if tile and math.abs(tile.Ground-point.Y)<.55 then
            local delta=Vector3.new(tile.X-point.X,0,tile.Z-point.Z)
            local side=math.abs(delta:Dot(right));local forward=math.abs(delta:Dot(heading))
            local weight=math.max(0,1-(side/.82)^2-(forward/1.15)^2)
            if weight>0 then
                tile.Target=math.max(tile.Target,.17*weight*strength);tile.Pressed=self.Now;compressed=true
            end
            -- Feather a retained little drift around old boot impressions.
            local radial=math.max(0,1-delta.Magnitude/2.2)
            if radial>0 then tile.Support=math.max(tile.Support or 0,radial);tile.SupportAt=self.Now end
        end
    end end
    if compressed then self.Stats.Compressed+=1 end
    return compressed
end
function Snow:SurfaceAt(x,z,fallback)
    local c=self.Profile.Cell;local gx,gz=math.floor(x/c+.5),math.floor(z/c+.5)
    local tile=self.Tiles[key(gx,gz)]
    return tile and tile.Surface or fallback+.095
end
function Snow:CreateMark()
    local m={};local f=folder(self.MarkFolder,"Boot Impression");m.Folder=f;m.Parts={}
    for _,name in ipairs({"Sole","Heel","Tread 1","Tread 2","Tread 3"})do
        local p=make(f,name,Vector3.new(.42,.018,.4),CFrame.new(0,-10000,0),SHADE)
        if name=="Sole"then p.Shape=Enum.PartType.Ball end
        p.Transparency=1;m.Parts[#m.Parts+1]=p
    end
    return m
end
function Snow:RenderMark(mark)
    local point,heading=mark.Point,mark.Heading
    local frame=CFrame.lookAt(Vector3.new(point.X,point.Y,point.Z),Vector3.new(point.X,point.Y,point.Z)+heading)
    local offsets={Vector3.new(mark.Side*.025,0,-.15),Vector3.new(0,0,.31),Vector3.new(0,.01,-.34),Vector3.new(0,.01,-.14),Vector3.new(0,.01,.06)}
    for i,p in ipairs(mark.Parts)do
        local pose=frame*CFrame.new(offsets[i]);local position=pose.Position
        local surface=self:SurfaceAt(position.X,position.Z,point.Y)
        p.CFrame=CFrame.new(position.X,surface+.014+offsets[i].Y,position.Z)*frame.Rotation
    end
end
function Snow:Stamp(point,heading,side)
    self.MarkIndex=self.MarkIndex%self.Profile.Marks+1
    local mark=self.Marks[self.MarkIndex]
    if not mark then mark=self:CreateMark();self.Marks[self.MarkIndex]=mark end
    mark.At=self.Now;mark.Point=point;mark.Heading=heading;mark.Side=side
    local sizes={Vector3.new(.46,.018,.65),Vector3.new(.39,.02,.26),Vector3.new(.32,.012,.035),Vector3.new(.35,.012,.035),Vector3.new(.33,.012,.035)}
    for i,p in ipairs(mark.Parts)do p.Size=sizes[i];p.Transparency=i>2 and .28 or .12 end
    self:RenderMark(mark);self.Stats.Steps+=1
end
function Snow:Feet(character,root)
    local left=character:FindFirstChild("LeftFoot")or character:FindFirstChild("Left Leg")
    local right=character:FindFirstChild("RightFoot")or character:FindFirstChild("Right Leg")
    local heading=flat(root.CFrame.LookVector)
    heading=heading.Magnitude>.01 and heading.Unit or Vector3.new(0,0,-1)
    local sideways=Vector3.new(-heading.Z,0,heading.X)
    local function point(p,side)
        if p and p:IsA("BasePart")then return p.Position-Vector3.new(0,p.Size.Y*.5,0)end
        return root.Position-Vector3.new(0,3,0)+sideways*side*.45
    end
    return point(left,-1),point(right,1),heading
end
function Snow:Footsteps(root,humanoid,character)
    local pos=root.Position
    local previous=self.LastPosition;self.LastPosition=pos
    if not previous then self.Travel=0;return end
    local delta=flat(pos-previous).Magnitude
    if delta>14 or math.abs(pos.Y-previous.Y)>8 then self.Travel=0;self.LastStep=self.Now;return end
    local state=humanoid:GetState()
    if humanoid.Health<=0 or humanoid.Sit or humanoid.SeatPart or humanoid.FloorMaterial==Enum.Material.Air
        or state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall
        or state==Enum.HumanoidStateType.Swimming then self.Travel=0;return end
    self.Travel+=delta
    local left,right,heading=self:Feet(character,root)
    if self.Now>=self.NextPressure then
        self.NextPressure=self.Now+.1
        for _,foot in ipairs({left,right})do
            local hit=self.Context.Ground(foot.X,foot.Z)
            if hit and hit.Normal.Y>.94 and hit.Material~=Enum.Material.Water and math.abs(hit.Position.Y-foot.Y)<1.1 then
                self:Press(hit.Position,heading,.9)
            end
        end
    end
    local speed=flat(root.AssemblyLinearVelocity).Magnitude
    local spacing=math.clamp(1.5+speed*.035,1.7,3.2)
    if self.Travel<spacing or self.Now-self.LastStep<.16 or delta<.005 then return end
    self.Travel=0;self.LastStep=self.Now;self.Side=not self.Side
    local foot=self.Side and left or right;local hit=self.Context.Ground(foot.X,foot.Z)
    if hit and hit.Normal.Y>.94 and hit.Material~=Enum.Material.Water and math.abs(hit.Position.Y-foot.Y)<1.1 then
        if self:Press(hit.Position,heading,1)then self:Stamp(hit.Position,heading,self.Side and -1 or 1)end
    end
end
function Snow:Update(dt,now)
    if self.Closed or not self.Context.Alive()then return end
    if not finite(dt)or dt<=0 then return end
    self.Now=finite(now)and now or self.Now+dt;dt=math.min(dt,.1)
    for _=1,5 do
        local source=self.Queue[self.ScanIndex]
        if not source then break end
        self.Queue[self.ScanIndex]=false;self.ScanIndex+=1;self:Coat(source)
    end
    if not self.TerrainDone then for _=1,2 do self:BuildTerrain()end end
    local character=self.Context.Player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and(character:FindFirstChild("realHrp")or character:FindFirstChild("saviHRP")or character:FindFirstChild("HumanoidRootPart"))
    if not root or not root:IsA("BasePart")or not humanoid or humanoid.Health<=0 then self.LastPosition=nil;return end
    if character~=self.Character then self.Character=character;self.LastPosition=nil;self.Travel=0;self.LastGrid=nil end
    local pos=root.Position
    if not vfinite(pos)then return end
    self:QueueGrid(pos)
    for _=1,self.Profile.Build do
        local cell=self.GridQueue[self.GridIndex]
        if not cell then break end;self.GridIndex+=1;self:BuildTile(cell,pos)
    end
    local footprints=self.Context.Config.Footprints~=false
    if footprints~=self.FootprintsEnabled then self:SetFootprints(footprints)end
    if footprints then self:Footsteps(root,humanoid,character)else self.LastPosition=pos;self.Travel=0 end
    local smoothing=1-math.exp(-dt*18)
    for _,tile in pairs(self.Tiles)do
        if self.Now-tile.Pressed>40 then tile.Target=math.max(0,tile.Target-dt*.007)end
        local distance=(Vector3.new(tile.X,pos.Y,tile.Z)-pos).Magnitude
        local edge=math.clamp((self.Profile.Radius+self.Profile.Cell-distance)/2.5,0,1)
        edge=edge*edge*(3-2*edge)
        local supported=tile.Support and tile.Support*math.clamp((65-(self.Now-(tile.SupportAt or 0)))/25,0,1)or 0
        local cover=math.max(edge,supported)
        local desiredTop=tile.Ground+.12+(.17+tile.Noise)*cover
        local oldTop=tile.Top;tile.Top+=(desiredTop-tile.Top)*smoothing
        if math.abs(tile.Depth-tile.Target)>.001 or math.abs(oldTop-tile.Top)>.0003 then
            tile.Depth+=(tile.Target-tile.Depth)*smoothing
            local top=math.max(tile.Ground+.12,tile.Top-tile.Depth);local height=math.max(.025,top-tile.Ground-.095)
            tile.Surface=top
            if live(tile.Part)then tile.Part.Size=Vector3.new(self.Profile.Cell+.035,height,self.Profile.Cell+.035)
                tile.Part.CFrame=CFrame.new(tile.X,top-height*.5,tile.Z)
                tile.Part.Color=WHITE:Lerp(SHADE,math.clamp(tile.Depth/.17,0,1)*.16)
            end
        end
    end
    -- New impressions track the rapidly compressing surface each frame;
    -- settled old impressions need only a 20 Hz placement/fade refresh.
    for _,mark in pairs(self.Marks)do if self.Now-mark.At<.5 then self:RenderMark(mark)end end
    if self.Now>=(self.NextMarks or 0)then
        self.NextMarks=self.Now+.05
        for _,mark in pairs(self.Marks)do
            local fade=math.clamp((self.Now-mark.At-35)/30,0,1)
            if fade<1 then self:RenderMark(mark)end
            for i,p in ipairs(mark.Parts)do p.Transparency=(i>2 and .28 or .12)+(1-(i>2 and .28 or .12))*fade end
        end
    end
    self.Elapsed+=dt
    if self.Elapsed>=1 then
        self.Elapsed=0;self:Prune(pos)
        local gone={}
        for source,record in pairs(self.Caps)do
            if not live(source)or not source.Anchored or source.CFrame~=record.Frame or source.Size~=record.Size then gone[#gone+1]=source end
        end
        for _,source in ipairs(gone)do local record=self.Caps[source];record.Part:Destroy();self.Caps[source]=nil;self.CapCount-=1 end
    end
end
function Snow:SetFootprints(value)
    if self.Closed then return end
    self.Context.Config.Footprints=value==true;self.FootprintsEnabled=value==true
    self.LastPosition=nil;self.Travel=0
    if not value then
        for _,mark in pairs(self.Marks)do mark.At=-10000;for _,p in ipairs(mark.Parts)do p.Transparency=1 end end
        for _,tile in pairs(self.Tiles)do tile.Target=0;tile.Pressed=-1000;tile.Support=nil end
    end
end
function Snow:Destroy()
    if self.Closed then return end;self.Closed=true
    if self.Added then self.Added:Disconnect();self.Added=nil end
    if self.Folder then self.Folder:Destroy()end
    table.clear(self.Queue);table.clear(self.Tiles);table.clear(self.FreeTiles);table.clear(self.Caps);table.clear(self.Marks)
end
return Snow

end
loaders.Decor=function(...)
-- Procedural winter tableaux. Only local, non-colliding decorations are made.
-- No external meshes, no remotes and no changes to the original map.
local Decor={};Decor.__index=Decor
local V=Vector3.new
local C={Snow=Color3.fromRGB(238,246,252),Ice=Color3.fromRGB(178,211,226),Pine=Color3.fromRGB(24,73,56),
    PineLight=Color3.fromRGB(36,95,67),Wood=Color3.fromRGB(83,54,42),Bark=Color3.fromRGB(53,38,34),
    Red=Color3.fromRGB(171,42,53),Gold=Color3.fromRGB(246,194,83),Cream=Color3.fromRGB(255,234,188),
    Coal=Color3.fromRGB(26,29,37),Orange=Color3.fromRGB(235,130,51),Teal=Color3.fromRGB(39,127,128),
    Blue=Color3.fromRGB(89,135,188),Pink=Color3.fromRGB(224,132,161)}
local bulbColors={C.Cream,C.Red,C.Gold,Color3.fromRGB(99,195,149),Color3.fromRGB(141,180,246)}
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
local function flatDistance(a,b)local d=a-b;return math.sqrt(d.X*d.X+d.Z*d.Z)end
local function characterRoot(ctx)
    local character=ctx.Player and ctx.Player.Character
    return character and(character:FindFirstChild("realHrp")or character:FindFirstChild("saviHRP")or character:FindFirstChild("HumanoidRootPart"))
end

function Decor.Install(ctx)
    local quality=ctx.Config and ctx.Config.Quality or "High"
    local self=setmetatable({Context=ctx,Closed=false,Parts=0,MaxParts=quality=="Low"and 1000 or quality=="Medium"and 1600 or 2200,
        MaxLights=quality=="Low"and 3 or quality=="Medium"and 6 or 10,Lights={},Bulbs={},Queue={},Cursor=1,
        Random=Random.new(414121),NextBuild=0,NextAnimate=0,BulbCursor=1,Scenes=0,BuildSlice=48},Decor)
    local folder=Instance.new("Folder");folder.Name="HolidayDecor";folder.Parent=ctx.Root;self.Folder=folder
    local b=ctx.Bounds;local center=b.Center
    local halfX=math.clamp((b.Max.X-b.Min.X)*.5,24,900)
    local halfZ=math.clamp((b.Max.Z-b.Min.Z)*.5,24,900)
    -- Leave the current player/spawn area clear. The first valid site becomes
    -- the focal tree plaza; all positions are verified against the actual map.
    local root=characterRoot(ctx)
    self.ReferenceY=root and(root.Position.Y-3)or center.Y
    local plaza=center+V(halfX*.12,0,-halfZ*.14)
    if root and flatDistance(plaza,root.Position)<20 then plaza+=V(24,0,12)end
    self:AddJob("Plaza",plaza,10,0)
    if root then
        for _,offset in ipairs({V(34,0,24),V(-34,0,24),V(24,0,-34),V(-24,0,-34)})do
            self:AddJob("Plaza",root.Position+offset,10,math.atan2(offset.X,offset.Z))
        end
    end
    local scenes={"FirGifts","Snowmen","Reindeer","LanternWalk","Igloo","SnowSculpture","GarlandGate","FirGifts","Snowmen","Reindeer","LanternWalk","SnowSculpture"}
    for i,kind in ipairs(scenes)do
        local angle=(i-1)*math.pi*2/#scenes+.34
        local ring=i%2==0 and .7 or .42
        local position=center+V(math.cos(angle)*halfX*ring,0,math.sin(angle)*halfZ*ring)
        self:AddJob(kind,position,kind=="GarlandGate"and 8 or kind=="Igloo"and 6 or 5,angle+math.pi/2)
    end
    -- Small natural drifts distribute the winter look between the tableaux.
    for i=1,32 do
        local x=self.Random:NextNumber(-halfX*.84,halfX*.84)
        local z=self.Random:NextNumber(-halfZ*.84,halfZ*.84)
        self:AddJob("Drift",center+V(x,0,z),2,self.Random:NextNumber(0,math.pi*2))
    end
    local eaves={}
    for index,part in ipairs(ctx.MapParts or {})do
        if index>1500 or #eaves>=4 then break end
        if part.Parent and part:IsA("BasePart")and part.Anchored and ctx.IsMapPart(part)
            and part.CFrame.UpVector.Y>.98 and part.Size.Y>=8 and part.Size.Y<=55
            and part.Position.Y<self.ReferenceY+65 then
            local width=math.max(part.Size.X,part.Size.Z);local depth=math.min(part.Size.X,part.Size.Z)
            if width>=14 and depth<=7 then
                local spaced=true
                for _,point in ipairs(eaves)do if flatDistance(point,part.Position)<35 then spaced=false;break end end
                if spaced then
                    eaves[#eaves+1]=part.Position
                    self:AddJob("Eave",part.Position,0,0)
                    self.Queue[#self.Queue].Part=part
                end
            end
        end
    end
    return self
end
function Decor:AddJob(kind,position,radius,yaw)
    self.Queue[#self.Queue+1]={Kind=kind,Position=position,Radius=radius,Yaw=yaw,Tries=0,At=0}
end
function Decor:Part(name,size,frame,color,shape,material)
    if self.Closed or not self.Context.Alive()or self.Parts>=self.MaxParts then return end
    local part=Instance.new("Part");part.Name=name;part.Size=size;part.CFrame=frame
    part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
    part.CastShadow=true;part.Material=material or Enum.Material.SmoothPlastic;part.Color=color
    part.TopSurface=Enum.SurfaceType.Smooth;part.BottomSurface=Enum.SurfaceType.Smooth
    if shape then part.Shape=shape end
    part.Parent=self.Folder;self.Parts+=1;self:YieldBuild();return part
end
function Decor:YieldBuild()
    if self.BuildBudget then
        self.BuildBudget-=1
        if self.BuildBudget<=0 then coroutine.yield()end
    end
end
function Decor:AdvanceBuild()
    local worker=self.Worker;if not worker then return end
    self.BuildBudget=self.BuildSlice
    local ok,err=coroutine.resume(worker)
    self.BuildBudget=nil
    if not ok then self.LastError=tostring(err);self.Worker=nil
    elseif coroutine.status(worker)=="dead"then self.Worker=nil end
end
function Decor:Ball(name,size,frame,color,material)return self:Part(name,size,frame,color,Enum.PartType.Ball,material)end
function Decor:Rod(name,a,b,width,color,material)
    local delta=b-a;if delta.Magnitude<.01 then return end
    return self:Part(name,V(width,delta.Magnitude,width),CFrame.lookAt((a+b)*.5,b)*CFrame.Angles(math.pi/2,0,0),color,nil,material)
end
function Decor:Disc(name,radius,depth,frame,color,material)
    return self:Part(name,V(depth,radius*2,radius*2),frame*CFrame.Angles(0,0,math.pi/2),color,Enum.PartType.Cylinder,material)
end
function Decor:Light(part,brightness,range,color)
    if not part or #self.Lights>=self.MaxLights then return end
    local light=Instance.new("PointLight");light.Color=color or C.Cream;light.Brightness=brightness;light.Range=range
    light.Shadows=false;light.Parent=part
    self.Lights[#self.Lights+1]={Object=light,Part=part,Brightness=brightness};return light
end
function Decor:Triangle(a,b,c,color)
    local ab,ac,bc=b-a,c-a,c-b
    if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then a,c=c,a
    elseif ac.Magnitude>ab.Magnitude and ac.Magnitude>bc.Magnitude then a,b=b,a end
    ab,ac,bc=b-a,c-a,c-b
    local cross=ac:Cross(ab);if cross.Magnitude<.001 or bc.Magnitude<.001 then return end
    local right,back=cross.Unit,bc.Unit;local up=back:Cross(right).Unit
    local height=math.abs(ab:Dot(up));if height<.01 then return end
    for _,d in ipairs({{(a+b)*.5,right,back,math.abs(ab:Dot(back))},{(a+c)*.5,-right,-back,math.abs(ac:Dot(back))}})do
        if d[4]>.01 and self.Parts<self.MaxParts and self.Context.Alive()then
            local part=Instance.new("WedgePart");part.Name="FirBranch";part.Size=V(.11,height,d[4]);part.CFrame=CFrame.fromMatrix(d[1],d[2],up,d[3])
            part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Material=Enum.Material.SmoothPlastic
            part.Color=color;part.CastShadow=true;part.Parent=self.Folder;self.Parts+=1;self:YieldBuild()
        end
    end
end
function Decor:Cone(frame,radius,height,color)
    local apex=frame*V(0,height,0)
    for i=0,7 do
        local a,b=i*math.pi/4,(i+1)*math.pi/4
        self:Triangle(apex,frame*V(math.cos(a)*radius,0,math.sin(a)*radius),frame*V(math.cos(b)*radius,0,math.sin(b)*radius),color)
    end
end
function Decor:Star(frame,scale)
    local front=frame*V(0,0,.04)
    for i=0,4 do
        local angle=i*math.pi*2/5
        local a=frame*V(math.sin(angle)*scale,math.cos(angle)*scale,0)
        local b=frame*V(math.sin(angle+math.pi*.8)*scale,math.cos(angle+math.pi*.8)*scale,0)
        self:Rod("GoldenStar",a,b,scale*.14,C.Gold,Enum.Material.Neon)
    end
    local glow=self:Ball("StarHeart",V(scale*.35,scale*.35,scale*.2),CFrame.new(front),C.Cream,Enum.Material.Neon)
    self:Light(glow,.7,14,C.Gold)
end
function Decor:Fir(frame,scale,ornaments)
    self:Disc("FirTrunk",.38*scale,2*scale,frame*CFrame.new(0,scale,0),C.Wood)
    for tier=0,3 do
        local radius=(3.5-tier*.7)*scale;local height=3.15*scale;local base=frame*CFrame.new(0,(1.2+tier*2.1)*scale,0)
        self:Cone(base,radius,height,tier%2==0 and C.Pine or C.PineLight)
        self:Cone(base*CFrame.new(0,height*.4+.04,0),radius*.64,height*.6,C.Snow)
    end
    if ornaments then
        for i=1,22 do
            local level=(i-1)%4;local angle=i*2.39996;local radius=(3.35-level*.7)*scale
            self:Ball("Bauble",V(.37,.42,.37)*scale,frame*CFrame.new(math.cos(angle)*radius,(1.45+level*2.1)*scale,math.sin(angle)*radius),i%3==0 and C.Gold or i%3==1 and C.Red or C.Teal)
        end
        self:Star(frame*CFrame.new(0,11.1*scale,0),.85*scale)
    end
    self:Ball("FirSnowSkirt",V(8,.5,8)*scale,frame*CFrame.new(0,.1,0),C.Snow)
end
function Decor:Gift(frame,scale,index)
    local color=({C.Red,C.Teal,C.Blue,C.Pink})[(index-1)%4+1]
    self:Part("WrappedGift",V(1.4,1.15,1.35)*scale,frame*CFrame.new(0,.58*scale,0),color)
    self:Part("GiftLid",V(1.48,.16,1.43)*scale,frame*CFrame.new(0,1.2*scale,0),color:Lerp(C.Cream,.14))
    self:Part("Ribbon",V(.18,1.34,1.45)*scale,frame*CFrame.new(0,.65*scale,0),C.Gold)
    self:Part("Ribbon",V(1.5,1.34,.18)*scale,frame*CFrame.new(0,.65*scale,0),C.Gold)
    for _,side in ipairs({-1,1})do self:Ball("BowLoop",V(.48,.22,.25)*scale,frame*CFrame.new(side*.24*scale,1.38*scale,0)*CFrame.Angles(0,0,side*.35),C.Gold)end
end
function Decor:Snowman(frame,scale,red)
    local scarf=red and C.Red or C.Teal
    self:Ball("SnowmanBase",V(2.8,2.65,2.8)*scale,frame*CFrame.new(0,1.28*scale,0),C.Snow)
    self:Ball("SnowmanBody",V(2.1,2.05,2.1)*scale,frame*CFrame.new(0,3.2*scale,0),C.Snow)
    self:Ball("SnowmanHead",V(1.55,1.5,1.55)*scale,frame*CFrame.new(0,4.66*scale,0),C.Snow)
    self:Disc("ScarfCollar",.94*scale,.22*scale,frame*CFrame.new(0,4*scale,0),scarf)
    self:Part("ScarfTail",V(.34,1.15,.16)*scale,frame*CFrame.new(.4*scale,3.5*scale,-.94*scale)*CFrame.Angles(0,0,-.1),scarf)
    for i=1,3 do self:Ball("CoalButton",V(.16,.17,.12)*scale,frame*CFrame.new(0,(2.65+i*.36)*scale,-(i==3 and .94 or 1.03)*scale),C.Coal)end
    for _,side in ipairs({-1,1})do
        self:Ball("CoalEye",V(.13,.14,.1)*scale,frame*CFrame.new(side*.28*scale,4.85*scale,-.715*scale),C.Coal)
        local elbow=frame*V(side*1.55*scale,3.7*scale,0);local hand=frame*V(side*2.25*scale,4.0*scale,0)
        self:Rod("TwigArm",frame*V(side*.85*scale,3.45*scale,0),hand,.11*scale,C.Bark)
        self:Rod("TwigFinger",elbow,frame*V(side*1.8*scale,4.35*scale,.12*scale),.08*scale,C.Bark)
    end
    self:Rod("Carrot",frame*V(0,4.6*scale,-.68*scale),frame*V(0,4.58*scale,-1.35*scale),.19*scale,C.Orange)
    for i=-2,2 do self:Ball("CoalSmile",V(.08,.08,.06)*scale,frame*CFrame.new(i*.13*scale,(4.34+math.abs(i)*.045)*scale,-.735*scale),C.Coal)end
    self:Disc("HatBrim",1.02*scale,.15*scale,frame*CFrame.new(0,5.3*scale,0),C.Coal)
    self:Disc("TopHat",.65*scale,.78*scale,frame*CFrame.new(0,5.73*scale,0),C.Coal)
    self:Disc("HatRibbon",.66*scale,.15*scale,frame*CFrame.new(0,5.45*scale,0),scarf)
    self:Ball("HatSnow",V(1.38,.16,1.38)*scale,frame*CFrame.new(0,6.13*scale,0),C.Snow)
end
function Decor:Reindeer(frame,scale,redNose)
    local tan=Color3.fromRGB(144,103,73);local cream=Color3.fromRGB(225,204,165)
    self:Ball("ReindeerBody",V(1.55,1.65,3.1)*scale,frame*CFrame.new(0,2.0*scale,0),tan)
    self:Ball("ReindeerChest",V(1.1,1.4,.8)*scale,frame*CFrame.new(0,2.3*scale,-1.05*scale),cream)
    for _,side in ipairs({-1,1})do for _,z in ipairs({-.92,.92})do
        self:Rod("ReindeerLeg",frame*V(side*.53*scale,1.7*scale,z*scale),frame*V(side*.59*scale,.3*scale,(z+.1)*scale),.25*scale,tan)
        self:Part("Hoof",V(.35,.3,.5)*scale,frame*CFrame.new(side*.59*scale,.18*scale,(z+.05)*scale),C.Bark)
    end end
    self:Rod("ReindeerNeck",frame*V(0,2.2*scale,-.8*scale),frame*V(0,3.45*scale,-1.2*scale),.85*scale,tan)
    self:Ball("ReindeerHead",V(1.05,1.2,1.65)*scale,frame*CFrame.new(0,3.65*scale,-1.55*scale),tan)
    self:Ball("ReindeerMuzzle",V(.86,.7,.75)*scale,frame*CFrame.new(0,3.45*scale,-2.25*scale),cream)
    local nose=self:Ball("ReindeerNose",V(.28,.28,.25)*scale,frame*CFrame.new(0,3.58*scale,-2.65*scale),redNose and C.Red or C.Bark,redNose and Enum.Material.Neon or nil)
    if redNose then self:Light(nose,.35,5,C.Red)end
    for _,side in ipairs({-1,1})do
        self:Ball("ReindeerEye",V(.12,.12,.13)*scale,frame*CFrame.new(side*.5*scale,3.88*scale,-1.96*scale),C.Coal)
        self:Ball("ReindeerEar",V(.28,.7,.6)*scale,frame*CFrame.new(side*.62*scale,4.05*scale,-1.13*scale)*CFrame.Angles(0,0,-side*.7),tan)
        local stem=frame*V(side*.38*scale,4.12*scale,-1.22*scale)
        local tip=frame*V(side*1.03*scale,5.48*scale,-.95*scale)
        self:Rod("Antler",stem,tip,.11*scale,C.Cream)
        for i=1,3 do
            local base=stem:Lerp(tip,i*.23)
            self:Rod("AntlerProng",base,base+frame:VectorToWorldSpace(V(side*.42,.26,i%2==0 and -.28 or .12)*scale),.085*scale,C.Cream)
        end
    end
    self:Disc("ReindeerCollar",.5*scale,.19*scale,frame*CFrame.new(0,2.92*scale,-1.06*scale)*CFrame.Angles(.3,0,0),C.Red)
    self:Ball("CollarBell",V(.2,.23,.2)*scale,frame*CFrame.new(0,2.86*scale,-1.58*scale),C.Gold)
    self:Ball("ReindeerTail",V(.38,.35,.7)*scale,frame*CFrame.new(0,2.48*scale,1.6*scale)*CFrame.Angles(-.6,0,0),cream)
end
function Decor:Lantern(frame,scale)
    self:Part("LanternBase",V(.8,.16,.8)*scale,frame*CFrame.new(0,.1*scale,0),C.Coal)
    local glow=self:Part("LanternGlow",V(.47,.7,.47)*scale,frame*CFrame.new(0,.58*scale,0),C.Cream,nil,Enum.Material.Neon)
    for _,x in ipairs({-.31,.31})do for _,z in ipairs({-.31,.31})do self:Part("LanternFrame",V(.07,.88,.07)*scale,frame*CFrame.new(x*scale,.61*scale,z*scale),C.Coal)end end
    self:Part("LanternCap",V(.86,.15,.86)*scale,frame*CFrame.new(0,1.12*scale,0),C.Coal)
    self:Ball("LanternSnow",V(.9,.12,.9)*scale,frame*CFrame.new(0,1.24*scale,0),C.Snow)
    self:Light(glow,.9,18,C.Cream)
end
function Decor:Garland(a,b,count)
    local function point(t)return a:Lerp(b,t)-V(0,math.sin(t*math.pi)*1.45,0)end
    local previous=a
    for i=1,count do
        local t=i/count;local p=point(t)
        self:Rod("GarlandCable",previous,p,.065,C.Bark)
        self:Rod("FirGarland",previous-V(0,.08,0),p-V(0,.08,0),.19,C.Pine)
        local color=bulbColors[(i-1)%#bulbColors+1]
        self:Rod("BulbSocket",p,p-V(0,.3,0),.08,C.Coal)
        local bulb=self:Ball("FestiveBulb",V(.2,.28,.2),CFrame.new(p-V(0,.36,0)),color,Enum.Material.Neon)
        if bulb then self.Bulbs[#self.Bulbs+1]={Part=bulb,Color=color,Phase=i*.72}end
        previous=p
    end
end
function Decor:Gate(frame,scale)
    for _,x in ipairs({-6,6})do
        self:Part("FestivePost",V(.35,7,.35)*scale,frame*CFrame.new(x*scale,3.5*scale,0),C.Wood)
        self:Ball("PostSnow",V(.65,.25,.65)*scale,frame*CFrame.new(x*scale,7.1*scale,0),C.Snow)
        self:Lantern(frame*CFrame.new(x*scale,0,-1.3*scale),.85*scale)
    end
    self:Garland(frame*V(-6*scale,6.7*scale,0),frame*V(6*scale,6.7*scale,0),12)
end
function Decor:Igloo(frame)
    local r=3.9
    for row=0,3 do
        local y=.42+row*.78;local ring=r*math.sqrt(math.max(.1,1-(y/4.2)^2))
        for i=0,11 do
            local angle=(i+(row%2)*.5)*math.pi/6
            -- Leave a real-looking dark arched opening on the front side.
            if not(row<2 and math.cos(angle)>.72)then
                local p=V(math.sin(angle)*ring,y,-math.cos(angle)*ring)
                self:Part("IglooBlock",V(1.1,.75,.58),frame*CFrame.new(p)*CFrame.Angles(0,-angle,0),row%2==0 and C.Snow or C.Snow:Lerp(C.Ice,.13))
            end
        end
    end
    self:Ball("IglooRoof",V(3.65,1,3.65),frame*CFrame.new(0,3.65,0),C.Snow)
    for i=0,6 do
        local angle=i*math.pi/6
        self:Part("IglooEntrance",V(.65,.66,.85),frame*CFrame.new(math.cos(angle)*1.05,.65+math.sin(angle)*1.05,-3.8)*CFrame.Angles(0,0,angle),C.Snow)
    end
    self:Lantern(frame*CFrame.new(1.9,0,-4.4),.85)
end
function Decor:Drift(frame,scale)
    self:Ball("SnowDrift",V(5.2,.8,3.1)*scale,frame*CFrame.new(0,.12*scale,0),C.Snow)
    self:Ball("WindblownSnow",V(2.7,.45,1.8)*scale,frame*CFrame.new(1.4*scale,.16*scale,.25*scale),C.Snow:Lerp(C.Ice,.08))
end
function Decor:Sculpture(frame)
    self:Disc("SnowSculpturePlinth",1.7,.5,frame*CFrame.new(0,.26,0),C.Ice)
    -- A little snow penguin, with an icy belly and flippers.
    self:Ball("SnowPenguin",V(1.75,2.5,1.65),frame*CFrame.new(0,1.7,0),C.Snow)
    self:Ball("PenguinBelly",V(1.2,1.7,.5),frame*CFrame.new(0,1.55,-.72),C.Ice:Lerp(C.Snow,.5))
    self:Ball("PenguinHead",V(1.2,1.15,1.15),frame*CFrame.new(0,3.0,-.1),C.Snow)
    for _,side in ipairs({-1,1})do
        self:Ball("PenguinFlipper",V(.35,1.6,.65),frame*CFrame.new(side*.93,1.9,0)*CFrame.Angles(0,0,side*.35),C.Ice)
        self:Ball("PenguinEye",V(.11,.13,.09),frame*CFrame.new(side*.25,3.12,-.63),C.Coal)
        self:Ball("PenguinFoot",V(.54,.15,.75),frame*CFrame.new(side*.4,.65,-.38),C.Orange)
    end
    self:Rod("PenguinBeak",frame*V(0,2.96,-.58),frame*V(0,2.91,-1.02),.2,C.Orange)
    self:Disc("PenguinScarf",.65,.16,frame*CFrame.new(0,2.54,-.05),C.Red)
end
function Decor:Site(job)
    if job.Kind=="Eave"then
        local part=job.Part
        if not part or not part.Parent or not self.Context.IsMapPart(part)then return end
        local side=part.CFrame:VectorToObjectSpace(self.Context.Bounds.Center-part.Position)
        job.Span=math.min(math.max(part.Size.X,part.Size.Z)*.4,12)
        if part.Size.X>=part.Size.Z then
            return part.CFrame*CFrame.new(0,part.Size.Y*.5-1.1,(side.Z<0 and -1 or 1)*(part.Size.Z*.5+.3))
        end
        return part.CFrame*CFrame.new((side.X<0 and -1 or 1)*(part.Size.X*.5+.3),part.Size.Y*.5-1.1,0)*CFrame.Angles(0,math.pi/2,0)
    end
    local p=job.Position
    local ok,hit=pcall(self.Context.Ground,p.X,p.Z)
    if not ok or not hit or not hit.Position or not hit.Normal or hit.Normal.Y<.92 then return end
    local root=characterRoot(self.Context)
    if root and flatDistance(hit.Position,root.Position)<(job.Kind=="Drift"and 5 or 12)then return end
    if job.Kind=="Plaza"and hit.Position.Y>self.ReferenceY+20 then return end
    if job.Kind~="Drift"then
        -- Avoid decorating a ledge, roof edge, staircase, or narrow platform.
        for _,offset in ipairs({V(job.Radius,0,0),V(-job.Radius,0,0),V(0,0,job.Radius),V(0,0,-job.Radius)})do
            local sample=self.Context.Ground(p.X+offset.X,p.Z+offset.Z)
            if not sample or sample.Normal.Y<.9 or math.abs(sample.Position.Y-hit.Position.Y)>1.3 then return end
        end
    end
    return CFrame.new(hit.Position+V(0,.04,0))*CFrame.Angles(0,job.Yaw,0)
end
function Decor:Build(job,frame)
    local kind=job.Kind
    if kind=="Plaza"then
        self.PlazaBuilt=true
        self:Fir(frame,1.25,true)
        for i=1,7 do local angle=i*math.pi*2/7;self:Gift(frame*CFrame.new(math.cos(angle)*4.5,0,math.sin(angle)*4.5)*CFrame.Angles(0,angle,0),.8+(i%3)*.12,i)end
        self:Snowman(frame*CFrame.new(7,0,2)*CFrame.Angles(0,-.3,0),.84,true)
        self:Snowman(frame*CFrame.new(8.5,0,5)*CFrame.Angles(0,.3,0),.58,false)
        self:Gate(frame*CFrame.new(0,0,-7),1)
    elseif kind=="FirGifts"then
        self:Fir(frame,.8,true);self:Gift(frame*CFrame.new(2.5,0,-1),.8,2);self:Gift(frame*CFrame.new(1.5,0,-2.4),.65,1)
    elseif kind=="Snowmen"then
        self:Snowman(frame,.85,true);self:Snowman(frame*CFrame.new(3,0,1)*CFrame.Angles(0,.5,0),.58,false);self:Drift(frame*CFrame.new(-2,0,2),.7)
    elseif kind=="Reindeer"then
        self:Reindeer(frame,1,true);self:Reindeer(frame*CFrame.new(3.5,0,1.8)*CFrame.Angles(0,-.2,0),.7,false);self:Gift(frame*CFrame.new(-2,0,1.8),.75,1)
    elseif kind=="LanternWalk"then
        for i=1,3 do self:Lantern(frame*CFrame.new((i-2)*3.1,0,(i%2)*1.5),.8)end
        self:Drift(frame*CFrame.new(0,0,2),1)
    elseif kind=="Igloo"then self:Igloo(frame)
    elseif kind=="SnowSculpture"then self:Sculpture(frame);self:Gift(frame*CFrame.new(2.2,0,.5),.65,3)
    elseif kind=="GarlandGate"then self:Gate(frame,1.1)
    elseif kind=="Drift"then self:Drift(frame,self.Random:NextNumber(.55,1.25))
    elseif kind=="Eave"then self:Garland(frame*V(-job.Span,0,0),frame*V(job.Span,0,0),12)end
    self.Scenes+=1
end
function Decor:Update(_,now)
    if self.Closed then return end
    if not self.Context.Alive()then self:Destroy();return end
    now=finite(now)and now or os.clock()
    if self.Worker then self:AdvanceBuild()
    elseif now>=self.NextBuild and self.Cursor<=#self.Queue and self.Parts<self.MaxParts then
        self.NextBuild=now+.045
        local job=self.Queue[self.Cursor];self.Cursor+=1
        if job.Kind=="Plaza"and self.PlazaBuilt then
            -- A successful fallback site replaces the other plaza candidates.
        elseif now<job.At then self.Queue[#self.Queue+1]=job
        else
            local frame=self:Site(job)
            if frame then
                self.Worker=coroutine.create(function()self:Build(job,frame)end)
                self:AdvanceBuild()
            elseif job.Tries<2 then
                job.Tries+=1;job.At=now+5
                if job.Kind=="Plaza"then job.Position+=V(job.Tries%2==1 and 24 or -48,0,job.Tries%2==0 and 24 or 0)end
                self.Queue[#self.Queue+1]=job
            end
        end
    end
    if now<self.NextAnimate then return end;self.NextAnimate=now+.15
    local root=characterRoot(self.Context)
    local camera=self.Context.World.CurrentCamera
    local point=root and root.Position or camera and camera.CFrame.Position
    for _,record in ipairs(self.Lights)do if record.Object.Parent and record.Part.Parent then
        record.Object.Enabled=point~=nil and(record.Part.Position-point).Magnitude<145
    end end
    local count=math.min(#self.Bulbs,48)
    for _=1,count do
        if self.BulbCursor>#self.Bulbs then self.BulbCursor=1 end
        local record=self.Bulbs[self.BulbCursor];self.BulbCursor+=1
        if record and record.Part.Parent then
            local fade=.04+(math.sin(now*.9+record.Phase)*.5+.5)*.12
            record.Part.Color=record.Color:Lerp(C.Coal,fade)
        end
    end
end
function Decor:Destroy()
    if self.Closed then return end
    self.Closed=true;self.Worker=nil;self.BuildBudget=nil
    if self.Folder then self.Folder:Destroy();self.Folder=nil end
    table.clear(self.Queue);table.clear(self.Lights);table.clear(self.Bulbs)
end
return Decor

end
loaders.Main=function(...)
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

end
local function requireModule(name)
    if cache[name]~=nil then return cache[name]end
    assert(not loading[name],"Circular winter module: "..tostring(name))
    local loader=assert(loaders[name],"Missing winter module: "..tostring(name))
    loading[name]=true
    local result=loader(requireModule)
    loading[name]=nil;cache[name]=result
    return result
end
return requireModule("Main")
