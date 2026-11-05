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
