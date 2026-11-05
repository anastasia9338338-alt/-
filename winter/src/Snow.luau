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
