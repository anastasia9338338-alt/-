local data=Assets.Metadata
check(data.Source.SourceTriangles==11783 and #data.Bones==103,'Source Aqua skeleton/triangle data was substituted')
local pose=Pose.new(data);local totalFaces=0
for _,part in ipairs(data.Parts)do
 local raw=Assets.Bytes(part.Key,function()return true end)
 local parsed=Mesh.Parse(raw,part);totalFaces+=parsed.FaceCount
 for _,v in ipairs(parsed.Vertices)do
  local sum=0;for _,w in ipairs(v.Weights)do sum+=w end
  check(sum==255 and finiteVector(v.Position),'Vertex weights/coordinates invalid')
 end
 -- Skin complete original geometry, not a single representative vertex.
 for _,style in ipairs({'idle','walk','run','crouch_idle','crouch_walk','sit','air'})do
  local localFrame=pose.Clips[style].Frames[1];local bytes,center=Mesh.Bake(parsed,pose:Skin(localFrame),function()return true end)
  check(bytes:sub(1,13)=='version 2.00\n'and finiteVector(center),'Pose baking produced invalid mesh/centre')
  local bufferData=buffer.fromstring(bytes)
  for i=0,parsed.VertexCount-1 do
   local o=25+i*40
   local v=Vector3.new(buffer.readf32(bufferData,o),buffer.readf32(bufferData,o+4),buffer.readf32(bufferData,o+8))
   local n=Vector3.new(buffer.readf32(bufferData,o+12),buffer.readf32(bufferData,o+16),buffer.readf32(bufferData,o+20))
   check(finiteVector(v)and math.abs(n.Magnitude-1)<.001,'Skinned geometry is nonfinite or normals are not unit length')
  end
 end
end
check(totalFaces==11783,'Export lost source triangles')
-- Resolution is checked in the actual embedded PNG header.
do
 local png=Assets.Bytes('MainTexture',function()return true end)
 local w,h=string.unpack('>I4I4',png,17)
 check(w==4096 and h==2048,'Main texture was downsampled')
end
local store,writes={},0
local files={Write=function(path,bytes)writes+=1;store[path]=bytes end,Read=function(path)return store[path]end,
 IsFile=function(path)return store[path]~=nil end,CustomAsset=function(path)return'custom://'..path end}
local function fixture()
 local state={Valid=true,Created={},Preloads=0}
 local world=newNode('Workspace','World');local original=newNode('Part','OriginalAvatar');original.Parent=world
 local context={Workspace=world,Files=files,CreateSkinned=function()
  local part=newNode('MeshPart','Native');state.Created[#state.Created+1]=part
  if state.CancelNative then state.Valid=false end
  return part
 end,Preload=function(_,valid)check(valid(),'Preload continued after cancellation');state.Preloads+=1 end}
 return state,context,world,original
end
do
 local state,context,world,original=fixture()
 local model=Model.Build(context,function()return state.Valid end,function()end)
 check(model.Mode=='Skinned'and model:IsReady()and #state.Created==#data.Parts,'Native GPU skeleton did not initialize')
 for _,part in pairs(model.Parts)do
  check(part.Anchored and not part.CanCollide and not part.CanQuery and part.LocalTransparencyModifier==1,'Model flashed or modified gameplay physics')
 end
 for _,activity in ipairs({'idle','walk','run','crouch','sit','jump'})do
  local p=model:Sample(activity,.25);model:Render(p,CFrame.new(4,0,8),false)
  for _,list in pairs(model.Bones)do for _,bone in ipairs(list)do check(finiteVector(bone.Transform.Position),'Native bone transform invalid')end end
 end
 model:SetScale(1.3);check(model.Model._Scale==1.3,'Native model scale did not update')
 model:Render(model:Sample('walk',.25),CFrame.new(),true)
 check(model.Parts.Main.LocalTransparencyModifier==1,'First person hide failed')
 check(original.Parent==world and not original.Anchored,'Source avatar physics changed')
 check(model:DescribeRig().BoneCount==103,'Rig report did not identify real Aqua bones')
 local detached=model.Parts.Eyes;detached.Parent=nil;check(not model:IsReady(),'Missing eye geometry remained ready')
 model:Dispose();model:Dispose();check(not model.Model.Parent and detached._destroyed,'Native cleanup leaked detached geometry')
end
do
 local state,context,world=fixture();state.CancelNative=true
 local ok=pcall(Model.Build,context,function()return state.Valid end,function()end)
 check(not ok and #state.Created==1 and state.Created[1].Parent==nil and state.Created[1]._destroyed,'Canceled yielding mesh creation leaked an unparented MeshPart')
 check(#world:GetChildren()==1,'Canceled load added a visible model')
end
-- Use the real fallback orchestration with a tiny baker to verify its bounded
-- cache/lifecycle, independently of the full-geometry skinning checks above.
do
 local counts={Bakes=0};local tiny={}
 function tiny.Parse(_,spec)return{Template=buffer.create(1),Spec=spec}end
 function tiny.Bake(_,matrices,valid)assert(valid());counts.Bakes+=1;return'M',Vector3.new(0,2,0)end
 local fallback=BuildModel(tiny)
 local state,context,world,original=fixture();context.CreateSkinned=function()error('Native mesh loader unavailable')end
 local progress={};local model=fallback.Build(context,function()return state.Valid end,function(text)progress[#progress+1]=text end)
 check(model.Mode=='FileMesh'and model:IsReady()and counts.Bakes==73*#data.Parts,'File fallback did not prepare the bounded animation set')
 for _,phase in ipairs({0,.2,.5,.99})do
  for _,activity in ipairs({'idle','walk','run','crouch','sit','jump'})do
   local p=model:Sample(activity,phase);model:Render(p,CFrame.new(5,0,9),false)
   check(model.Meshes.Main.MeshId:find('custom://',1,true)~=nil,'Fallback frame URI missing')
  end
 end
 model:SetScale(.8);check(math.abs(model.Meshes.Main.Scale.X-.8)<1e-6,'File mesh scale failed')
 model:Dispose();check(#world:GetChildren()==1 and original.Parent==world,'Fallback cleanup affected the original avatar')
 local before=counts.Bakes
 local again=fallback.Build(context,function()return true end,function()end)
 check(counts.Bakes==before,'Valid pose disk cache was rebuilt on every toggle')
 again:Dispose()
 context.CreateSkinned=function()local p=newNode('MeshPart','Static');p.HasSkinnedMesh=false;return p end
 local static=fallback.Build(context,function()return true end,function()end)
 check(static.Mode=='FileMesh'and static.NativeError:find('skin weights',1,true)~=nil,'A loader that discarded skin weights produced a rigid model')
 static:Dispose()
end
-- Grounding must also work between stance/crouch endpoints.
do
 for n=0,10 do
  local f=pose:Resolve({Crouch=n/10,Walk=.25,Phase=.31},false);local matrices=pose:Skin(f);local bottom=math.huge
  for _,v in ipairs(data.FootContacts)do
   local p=Vector3.zero;for k,id in ipairs(v.Bones)do p+=(matrices[id]*Vector3.new(table.unpack(v.Position)))*v.Weights[k]end
   bottom=math.min(bottom,p.Y)
  end
  check(bottom>=-.001,'Interpolated crouch put feet below the surface')
 end
 local t=0;local fx=Effects.new({Clock=function()return t end,Wind=function()return Vector3.new(20,0,0),1 end})
 local maxBlink=0;local previous=0
 for _=1,600 do t+=1/120;local e=fx:Step(CFrame.new(),nil);maxBlink=math.max(maxBlink,e.Blink);check(math.abs(e.WindX-previous)<.01,'Wind animation snapped');previous=e.WindX end
 check(maxBlink>.99,'Eyes did not fully close during a blink')
end
-- Optional face/preload errors must leave a usable body, including failures
-- discovered after the local model has already been attached.
do
 local state,context,world=fixture();local preload=context.Preload
 context.Preload=function(instances,valid)
  if instances[1].Name=='AquaEyelid1'then error('forced optional lid load failure')end
  preload(instances,valid)
 end
 local model=Model.Build(context,function()return state.Valid end,function()end)
 check(model:IsReady()and #model.Lids==0 and model.EffectError~=nil,'Optional eyelids destroyed a working body')
 model.Effects.Step=function()error('forced optional wind failure')end
 check(model:Render(model:Sample('idle',0),CFrame.new(),false)and model.Parts.Main.LocalTransparencyModifier==0,'Optional wind failure hid the body')
 model:Dispose()
end
do
 local counts={Bakes=0};local tiny={}
 function tiny.Parse(_,spec)return{Template=buffer.create(1),Spec=spec}end
 function tiny.Bake(_,matrices,valid)assert(valid());counts.Bakes+=1;return'M',Vector3.zero end
 local fallback=BuildModel(tiny);local state,context,world=fixture();local jobs={}
 context.Files={Write=function()end,CustomAsset=function(path)return'custom://'..path end}
 context.CreateSkinned=function()error('No native loader')end
 context.Spawn=function(fn)jobs[#jobs+1]=fn end
 local model=fallback.Build(context,function()return state.Valid end,function()end)
 check(model:IsReady()and counts.Bakes==#data.Parts and #jobs==2,'Fallback waited for every animation before showing Aqua')
 check(model:Render(model:Sample('jump',0),CFrame.new(),false),'Missing background clip hid the ready idle pose')
 model:Dispose();local before=counts.Bakes
 for _,job in ipairs(jobs)do job()end
 check(counts.Bakes==before and #world:GetChildren()==1,'Canceled background animation or lids leaked into the world')
end
do
 local counts=0;local tiny={}
 function tiny.Parse(_,spec)return{Template=buffer.create(1),Spec=spec}end
 function tiny.Bake(_,matrices,valid)assert(valid());counts+=1;if counts>#data.Parts then error('forced later animation failure')end;return'M',Vector3.zero end
 local state,context=fixture();local jobs={};context.Files={Write=function()end,CustomAsset=function(path)return'custom://'..path end}
 context.CreateSkinned=function()error('No native loader')end;context.Spawn=function(fn)jobs[#jobs+1]=fn end
 local model=BuildModel(tiny).Build(context,function()return state.Valid end,function()end)
 for _,job in ipairs(jobs)do job()end
 check(model:IsReady()and model.AnimationError~=nil,'Background animation failure discarded a valid model')
 check(model:Render(model:Sample('walk',.5),CFrame.new(),false),'Background animation failure made the model unrenderable')
 model:Dispose()
end
-- Build and deform the real original triangles without loading any .mesh URI.
do
 local state,context,world=fixture();local editables={};local clock=0
 context.Clock=function()return clock end;context.CreateSkinned=function()error('Mesh URI unsupported')end
 context.CreateEditableMesh=function()
  local e={Positions={},Normals={},UVs={},Faces={},Edits=0};editables[#editables+1]=e
  function e:AddVertex(p)self.Positions[#self.Positions+1]=p;return #self.Positions end
  function e:AddNormal(n)self.Normals[#self.Normals+1]=n;return #self.Normals end
  function e:AddUV(uv)self.UVs[#self.UVs+1]=uv;return #self.UVs end
  function e:AddTriangle(a,b,c)assert(self.Positions[a]and self.Positions[b]and self.Positions[c]);self.Faces[#self.Faces+1]={a,b,c};return #self.Faces end
  function e:SetFaceNormals(id,ids)for _,n in ipairs(ids)do assert(self.Normals[n])end end
  function e:SetFaceUVs(id,ids)for _,n in ipairs(ids)do assert(self.UVs[n])end end
  function e:SetPosition(id,p)self.Positions[id]=p;self.Edits+=1 end
  function e:SetNormal(id,n)self.Normals[id]=n end
  function e:Destroy()self.Destroyed=true end
  return e
 end
 context.CreateEditablePart=function(e)
  local p=newNode('MeshPart','Editable');return p
 end
 local model=Model.Build(context,function()return state.Valid end,function()end)
 check(model.Mode=='EditableMesh'and model:IsReady()and #editables==#data.Parts,'Editable geometry fallback was not selected')
 local faces=0;for _,e in ipairs(editables)do faces+=#e.Faces;check(#e.Positions==#e.UVs and #e.Positions==#e.Normals,'Editable geometry lost source UVs or normals')end
 check(faces==11783,'Editable fallback replaced the source geometry')
 local stance={Crouch=.7,Walk=.2,Phase=.3};local expected=pose:Skin(pose:Resolve(stance));model:Render(stance,CFrame.new(),false)
 for _,r in ipairs(model.Editable.Records)do
  for i,v in ipairs(r.Parsed.Vertices)do
   local p=Vector3.zero;for k,id in ipairs(v.Bones)do p+=(expected[id]*v.Position)*(v.Weights[k]/255)end
   check((r.Editable.Positions[r.Vertices[i]]+r.Center-p).Magnitude<.001,'Editable deformation differs from the source skeleton')
  end
 end
 local edits=editables[1].Edits
 for _=1,60 do clock+=1/240;model:Render(stance,CFrame.new(),false)end
 check(editables[1].Edits-edits<=#editables[1].Positions*9,'Editable CPU work grew with rendering FPS')
 model:Dispose();for _,e in ipairs(editables)do check(e.Destroyed,'Editable resource leaked on unload')end
 check(#world:GetChildren()==1,'Editable body cleanup removed the source avatar or leaked geometry')
 -- A yielding part creator may complete after the requested model was cancelled.
 local late
 context.CreateEditablePart=function(e)late=newNode('MeshPart','Late');state.Valid=false;return late end
 local ok=pcall(Model.Build,context,function()return state.Valid end,function()end)
 check(not ok and late._destroyed and #world:GetChildren()==1,'Cancelled EditableMesh load leaked a late part')
 for _,e in ipairs(editables)do check(e.Destroyed,'Cancelled EditableMesh load leaked source geometry')end
 state.Valid=true;context.CreateEditablePart=function()return world:GetChildren()[1] end
 local textures={MainTexture='custom://main',DetailTexture='custom://details',EyeTexture='custom://eyes'}
 local accepted=pcall(Editable.Build,context,data,pose,Assets,textures,function()return state.Valid end,function()end)
 check(not accepted and #world:GetChildren()==1 and not world:GetChildren()[1]._destroyed,'Editable loader could destroy an existing world part')
end
print('PASS: '..checks..' Aqua source geometry, texture, GPU rig, file fallback and cancellation assertions (mocked)')
