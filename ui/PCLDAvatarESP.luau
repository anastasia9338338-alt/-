-- A visual-only avatar at the exact native Box PCLD frame. Source body sizes
-- are copied 1:1; Humanoid simulation and every contact/query are disabled.
local Avatars={};Avatars.__index=Avatars
local V=Vector3.new
local bodyNames={Head=true,Torso=true,UpperTorso=true,LowerTorso=true,['Left Arm']=true,['Right Arm']=true,['Left Leg']=true,['Right Leg']=true,
 LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,
 LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true}
local function alive(v)return v and v.Parent~=nil end
local function finite(v)return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z and v.Magnitude<1e7 end
local function cosmetic(v,c,root)
 if v==root then return true end
 if v.Parent==c then return bodyNames[v.Name]==true end
 local parent=v.Parent
 while parent and parent~=c do
  if parent:IsA('Tool')then return false end
  if parent:IsA('Accessory')and parent.Parent==c then return true end
  parent=parent.Parent
 end
 return false
end
-- Clone preserves references to objects outside Character. A class blacklist is
-- unsafe here: WeldConstraint inherits Instance rather than Constraint, and a
-- surviving external weld can connect an anchored visual to a live assembly.
-- Keep appearance-only contents, never mechanical links or object references.
local visualClasses={Model=true,Folder=true,Humanoid=true,BodyColors=true,CharacterMesh=true,
 SurfaceAppearance=true,FaceControls=true,NumberValue=true,WrapLayer=true,WrapTarget=true,
 Shirt=true,Pants=true,ShirtGraphic=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true}
local function visual(v)
 return visualClasses[v.ClassName]or v:IsA('BasePart')or v:IsA('Accoutrement')or v:IsA('Clothing')
  or v:IsA('DataModelMesh')or v:IsA('Decal')or v:IsA('Attachment')or v:IsA('BaseWrap')
end
local function transparency(v)
 local n=tonumber(v);return n and n==n and math.clamp(n,0,1)or 0
end
local function skeletonRoot(character,humanoid,fallback)
 -- Desync helpers may replace Humanoid.RootPart. The actual root joint still
 -- identifies the body skeleton; its rest transforms do not use helper CFrames.
 for _,j in ipairs(character:GetDescendants())do
  if j:IsA('Motor6D')and j.Part0 and j.Part1 and j.Part0.Parent==character and j.Part1.Parent==character
   and(j.Part1.Name=='Torso'or j.Part1.Name=='LowerTorso')and not bodyNames[j.Part0.Name]then return j.Part0 end
 end
 local root=humanoid and humanoid.RootPart or character:FindFirstChild('HumanoidRootPart')or fallback
 return root and root:IsDescendantOf(character)and root or fallback
end
local function restFrames(character,root)
 local frames={[root]=CFrame.new()};local joints={}
 for _,v in ipairs(character:GetDescendants())do
  if v:IsA('JointInstance')and v.Part0 and v.Part1 and cosmetic(v.Part0,character,root)and cosmetic(v.Part1,character,root)then joints[#joints+1]=v end
 end
 for _=1,20 do
  local changed=false
  for _,j in ipairs(joints)do
   if frames[j.Part0]and not frames[j.Part1]then frames[j.Part1]=frames[j.Part0]*j.C0*j.C1:Inverse();changed=true
   elseif frames[j.Part1]and not frames[j.Part0]then frames[j.Part0]=frames[j.Part1]*j.C1*j.C0:Inverse();changed=true end
  end
  if not changed then break end
 end
 local inverse=root.CFrame:Inverse()
 for _,v in ipairs(character:GetDescendants())do if v:IsA('BasePart')and cosmetic(v,character,root)and not frames[v]then frames[v]=inverse*v.CFrame end end
 return frames
end
function Avatars.Install(ctx)
 local self=setmetatable({Context=ctx,Mode='Box',Records={},Elapsed=0,Limit=150,Status='Box'},Avatars)
 self.Container=Instance.new('Folder');self.Container.Name='AstralPCLDAvatars';self.Container.Parent=ctx.Workspace
 self.Connection=ctx.RunService.Heartbeat:Connect(function(dt)
  if self.Closed then return end
  self.Elapsed+=dt or 0;if self.Elapsed<.2 then return end;self.Elapsed=0
  local ok,why=pcall(self.Refresh,self)
  if not ok then self.LastError=tostring(why);self:Clear();self.Status='Avatar PCLD: '..self.LastError end
 end)
 return self
end
function Avatars:Active()return not self.Closed and self.Mode=='Avatar'and self.Context.Enabled()end
function Avatars:Has(detector)
 if not self:Active()then return false end
 for _,r in pairs(self.Records)do if r.Detector==detector and alive(r.Model)and not r.Dirty then return true end end
 return false
end
function Avatars:Remove(player)
 local r=self.Records[player];if not r then return end;self.Records[player]=nil
 for _,c in ipairs(r.Connections)do c:Disconnect()end;r.Model:Destroy()
end
function Avatars:Clear()
 local list={};for p in pairs(self.Records)do list[#list+1]=p end
 for _,p in ipairs(list)do self:Remove(p)end
 if self.RenderConnection then self.RenderConnection:Disconnect();self.RenderConnection=nil end
end
function Avatars:SetMode(value)
 if value~='Box'and value~='Avatar'then return false end
 self.Mode=value;self.Status=value
 if not self:Active()then self:Clear()else self:Refresh()end;return true
end
function Avatars:Build(player,character,root,detector)
 local saved=character.Archivable;local model
 local ok,why=pcall(function()character.Archivable=true;model=character:Clone()end);character.Archivable=saved
 if not ok or not model then self.LastError=tostring(why or'Character clone unavailable');return end
 local result
 local prepared,prepareWhy=pcall(function()
  local humanoid=character:FindFirstChildOfClass('Humanoid')
  local rigRoot=skeletonRoot(character,humanoid,root)
  local frames=restFrames(character,rigRoot);local pairsOfParts={};local allowed={};local originals={}
  local function pair(source,copy)
   local grouped={}
   for _,child in ipairs(copy:GetChildren())do local key=child.Name..'\0'..child.ClassName;grouped[key]=grouped[key]or{};table.insert(grouped[key],child)end
   for _,child in ipairs(source:GetChildren())do if child.Archivable~=false then
    local list=grouped[child.Name..'\0'..child.ClassName];local twin=list and table.remove(list,1)
    if twin then
     originals[twin]=child
     if child:IsA('BasePart')and cosmetic(child,character,rigRoot)then pairsOfParts[#pairsOfParts+1]={Source=child,Part=twin,Frame=frames[child]};allowed[twin]=child end
     pair(child,twin)
    end
   end end
  end
  pair(character,model)
  for _,v in ipairs(model:GetDescendants())do
   if not visual(v)then v:Destroy()
   elseif v:IsA('BasePart')then
    if not allowed[v]then v:Destroy()
    else
     v.Anchored=true;v.Massless=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.CastShadow=false;v.LocalTransparencyModifier=0
     if allowed[v]==rigRoot then v.Transparency=1 end
     if v:IsA('Seat')or v:IsA('VehicleSeat')then v.Disabled=true end
    end
   elseif v:IsA('Model')then v.PrimaryPart=nil
   elseif v:IsA('Humanoid')then
    -- EvaluateStateMachine=false preserves clothing rendering, without
    -- humanoid forces, collision re-enabling, auto-scaling or locomotion.
    local inert=pcall(function()v.EvaluateStateMachine=false end)
    if not inert then v:Destroy()else
    v.RequiresNeck=false;v.BreakJointsOnDeath=false;v.AutomaticScalingEnabled=false
    v.AutoRotate=false;v.PlatformStand=true;v.AutoJumpEnabled=false;v.WalkToPart=nil
    v.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;v.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
    end
   elseif v:IsA('ParticleEmitter')or v:IsA('Trail')or v:IsA('Beam')then v.Enabled=false end
  end
  local lo=V(math.huge,math.huge,math.huge);local hi=V(-math.huge,-math.huge,-math.huge);local parts={}
  for _,p in ipairs(pairsOfParts)do if p.Part:IsDescendantOf(model)and p.Frame then
   parts[#parts+1]=p
   if p.Source.Parent==character and p.Source~=rigRoot and bodyNames[p.Source.Name]then
    local half=p.Source.Size*.5
    for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
     local point=p.Frame*V(half.X*x,half.Y*y,half.Z*z)
     lo=V(math.min(lo.X,point.X),math.min(lo.Y,point.Y),math.min(lo.Z,point.Z));hi=V(math.max(hi.X,point.X),math.max(hi.Y,point.Y),math.max(hi.Z,point.Z))
    end end end
   end
  end end
  if #parts==0 or #parts>320 or not finite(lo)or not finite(hi)or hi.Y-lo.Y<.1 then return end
  model.PrimaryPart=nil
  local center=(lo+hi)*.5
  for _,p in ipairs(parts)do p.Offset=(CFrame.new(-center)*p.Frame)end
  model.Name='AstralPCLD/'..player.Name
  local highlight=Instance.new('Highlight');highlight.Name='PCLDColors';highlight.Adornee=model;highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;highlight.Parent=model
  local surfaces={}
  for _,v in ipairs(model:GetDescendants())do if v:IsA('Decal')then surfaces[#surfaces+1]={Part=v,Source=originals[v],Transparency=transparency(v.Transparency)}end end
  local record={Player=player,Character=character,Root=root,Model=model,Parts=parts,Highlight=highlight,Connections={},Detector=detector,
   BodyHeight=hi.Y-lo.Y,Scale=1,Surfaces=surfaces,RigRoot=rigRoot}
  local function dirty(v)
   if v:IsA('BasePart')or v:IsA('Accessory')or v:IsA('Shirt')or v:IsA('Pants')or v:IsA('BodyColors')then record.Dirty=true end
  end
  if character.DescendantAdded then record.Connections[#record.Connections+1]=character.DescendantAdded:Connect(dirty)end
  if character.DescendantRemoving then record.Connections[#record.Connections+1]=character.DescendantRemoving:Connect(dirty)end
  for _,p in ipairs(parts)do
   for _,property in ipairs({'Size','Color','Transparency'})do
    record.Connections[#record.Connections+1]=p.Source:GetPropertyChangedSignal(property):Connect(function()record.Dirty=true end)
   end
  end
  local function guard(instance,property,value)
   record.Connections[#record.Connections+1]=instance:GetPropertyChangedSignal(property):Connect(function()
    if instance.Parent and instance[property]~=value then instance[property]=value end
   end)
  end
  for _,p in ipairs(parts)do
   if p.Part:IsDescendantOf(model)then
    for _,property in ipairs({'CanCollide','CanTouch','CanQuery'})do guard(p.Part,property,false)end
    guard(p.Part,'Anchored',true);guard(p.Part,'Massless',true)
   end
  end
  for _,v in ipairs(model:GetDescendants())do if v:IsA('Humanoid')then guard(v,'EvaluateStateMachine',false);guard(v,'AutomaticScalingEnabled',false)end end
  -- Engine/game callbacks must not add a fresh weld, controller or collider to
  -- this frozen appearance copy after its initial sanitization.
  local known={};for _,v in ipairs(model:GetDescendants())do known[v]=true end
  record.Connections[#record.Connections+1]=model.DescendantAdded:Connect(function(v)if not known[v]then v:Destroy()end end)
  self.Records[player]=record;model.Parent=self.Container;result=record
 end)
 if not prepared or not result then model:Destroy();self.LastError=not prepared and tostring(prepareWhy)or self.LastError end
 return result
end
function Avatars:Refresh()
 if not self:Active()then self:Clear();return end
 local keep={};local built=0;local count=0
 -- LocalPlayer is deliberately included, just like the native detector boxes.
 for _,player in ipairs(self.Context.Players:GetPlayers())do
  local character,root,h=self.Context.Character(player);local detector=self.Context.Detector(player)
  if character and root and root.Parent and h and h.Health>0 and alive(detector)and not self.Context.Waiting(detector)then
   count+=1
   if count<=self.Limit then
    local r=self.Records[player]
    if r and(r.Character~=character or r.Root~=root or not alive(r.Model)or r.Dirty)then self:Remove(player);r=nil end
    if not r and built<3 then built+=1;r=self:Build(player,character,root,detector)end
    if r then r.Detector=detector;keep[player]=true end
   end
  end
 end
 local remove={};for player in pairs(self.Records)do if not keep[player]then remove[#remove+1]=player end end
 for _,player in ipairs(remove)do self:Remove(player)end
 if next(self.Records)and not self.Context.ExternalRender and not self.RenderConnection then
  self.RenderConnection=self.Context.RunService.RenderStepped:Connect(function()self:Render()end)
 end
 self:Render();self.Status='Avatar PCLD: '..tostring(count)
end
function Avatars:Render(detector)
 if not self:Active()then self:Clear();return end
 local conf=self.Context.Config()
 -- Skin and colored Highlight are two layers. Split their alpha so their
 -- combined transparency is the same value used by ordinary Box PCLD.
 local alpha=math.sqrt(transparency(conf.FillTransparency))
 for player,r in pairs(self.Records)do if not detector or detector==r.Detector then
  local character,root,h=self.Context.Character(player)
  if character~=r.Character or root~=r.Root or not h or h.Health<=0 or not alive(r.Detector)or self.Context.Waiting(r.Detector)then self:Remove(player)
  else
   local frame=self.Context.Frame(r.Detector)
   if frame and finite(frame.Position)then
    -- No fit-to-box scale and no second interpolation/prediction pass.
    for _,p in ipairs(r.Parts)do if p.Part:IsDescendantOf(r.Model)then
     p.Part.CFrame=frame*p.Offset
     local value=p.Source==r.RigRoot and 1 or 1-(1-transparency(p.Source.Transparency))*(1-alpha)
     if p.Part.Transparency~=value then p.Part.Transparency=value end
    end end
    for _,s in ipairs(r.Surfaces)do if s.Part.Parent then
     local original=s.Source and s.Source.Parent and transparency(s.Source.Transparency)or s.Transparency
     s.Part.Transparency=1-(1-original)*(1-alpha)
    end end
    r.Highlight.FillColor=conf.FillColor;r.Highlight.OutlineColor=conf.OutlineColor
    r.Highlight.FillTransparency=alpha;r.Highlight.OutlineTransparency=conf.OutlineTransparency;r.Highlight.Enabled=true
   else r.Highlight.Enabled=false end
  end
 end end
end
function Avatars:Dispose()
 if self.Closed then return end;self.Closed=true;self:Clear();self.Connection:Disconnect();self.Container:Destroy()
end
return Avatars
