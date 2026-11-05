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
