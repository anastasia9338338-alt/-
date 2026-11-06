local Guard
-- Small rig/state fixture; it does not emulate a Roblox server or ownership.
local Enum={Material={Air='Air',Grass='Grass'},HumanoidStateType={Running='Running',Physics='Physics',Ragdoll='Ragdoll',FallingDown='FallingDown',Freefall='Freefall',PlatformStanding='PlatformStanding',GettingUp='GettingUp'}}
local count=0
local function check(value,message)assert(value,message);count+=1 end
local function signal()
 local s={Connections={}}
 function s:Connect(fn)local c={Connected=true,Fn=fn};function c:Disconnect()self.Connected=false end;self.Connections[#self.Connections+1]=c;return c end
 function s:Fire(...)for _,c in ipairs(table.clone(self.Connections))do if c.Connected then c.Fn(...)end end end
 return s
end
local function node(class,parent,props)
 local data=props or{};data.Parent=parent;data.Signals={};data.ClassName=class
 local n
 n=setmetatable({},{__index=function(_,k)
  if k=='IsA'then return function(_,name)return name==class or name=='BasePart'and class=='Part'end end
  if k=='IsDescendantOf'then return function(_,ancestor)local p=data.Parent;while p do if p==ancestor then return true end;p=p.Parent end;return false end end
  if k=='GetPropertyChangedSignal'then return function(_,name)data.Signals[name]=data.Signals[name]or signal();return data.Signals[name]end end
  return data[k]
 end,__newindex=function(_,k,v)local old=data[k];data[k]=v;if old~=v and data.Signals[k]then data.Signals[k]:Fire()end end})
 return n,data
end
local function fixture(mode)
 local d={Now=0,Held=false,Enabled=true,Mode=mode or'Normal',Struggles=0,Clears={},Active={},Tasks={},Changes={},Writes={},Falls=0}
 local pre,heart=signal(),signal()
 local c={Parent={},DescendantAdded=signal(),Descendants={}}
 function c:GetDescendants()return table.clone(self.Descendants)end
 local rootData={Parent=c,CFrame='original frame',AssemblyLinearVelocity='native gravity',AssemblyAngularVelocity='native angular',Anchored=false,CanCollide=true}
 local root=setmetatable({},{__index=function(_,k)if k=='IsA'then return function(_,name)return name=='BasePart'end end;return rootData[k]end,__newindex=function(_,k,v)d.Writes[#d.Writes+1]='root.'..k;rootData[k]=v end})
 local torso=node('Part',c,{Name='Torso'});local leg=node('Part',c,{Name='Left Leg'})
 local motor=node('Motor6D',torso,{Name='Left Hip',Enabled=true,Part0=torso,Part1=leg})
 local a=node('Attachment',torso,{});local b=node('Attachment',leg,{})
 local socket=node('BallSocketConstraint',leg,{Name='BallSocketConstraint',Enabled=false,Attachment0=a,Attachment1=b})
 local collider=node('Part',leg,{Name='RagdollLimbPart',CanCollide=false})
 c.Descendants={torso,leg,motor,a,b,socket,collider}
 local rag={Value=false,IsA=function(_,name)return name=='BoolValue'end}
 local hsignals={}
 local hdata={Parent=c,Health=100,AutoRotate=true,RequiresNeck=true,PlatformStand=false,Sit=false,SeatPart=nil,WalkSpeed=22,HipHeight=2,FloorMaterial='Grass',State='Running',StateEnabled={}}
 hdata.FindFirstChild=function(_,name)return name=='Ragdolled'and rag end
 hdata.GetState=function()return hdata.State end
 hdata.ChangeState=function(_,value)d.Changes[#d.Changes+1]=value;hdata.State=value end
 hdata.GetStateEnabled=function(_,state)return hdata.StateEnabled[state]~=false end
 hdata.SetStateEnabled=function(_,state,value)hdata.StateEnabled[state]=value end
 hdata.GetPropertyChangedSignal=function(_,key)hsignals[key]=hsignals[key]or signal();return hsignals[key]end
 local hum=setmetatable({},{__index=hdata,__newindex=function(_,k,v)d.Writes[#d.Writes+1]='hum.'..k;local before=hdata[k];hdata[k]=v;if before~=v and hsignals[k]then hsignals[k]:Fire()end end})
 local ctx={RunService={Heartbeat=heart,PreSimulation=pre},Clock=function()return d.Now end,
  Enabled=function()return d.Enabled end,Held=function()return d.Held end,Mode=function()return d.Mode end,
  Character=function()return d.Character or c,d.Root or root,d.Humanoid or hum end,
  GrabWelds=function()return d.GrabWelds or{}end,RecoverAnimation=function()d.AnimationRecoveries=(d.AnimationRecoveries or 0)+1 end,
  SetActive=function(value)d.Active[#d.Active+1]=value end,
  Struggle=function()d.Struggles+=1;if d.Throw then error('remote denied')end end,
  Ragdoll=function(r,t)d.Clears[#d.Clears+1]={Root=r,Duration=t};if d.Throw then error('remote denied')end end,
  Spawn=function(fn)d.Tasks[#d.Tasks+1]=fn end,
  ExtraEscape=function(valid)if valid()then d.Escapes=(d.Escapes or 0)+1 end end}
 local guard=Guard.Install(ctx)
 local function step(n,fps)
  for _=1,n do d.Now+=1/fps;pre:Fire();if d.Held and not motor.Enabled then d.Falls+=1 end;heart:Fire()end
 end
 local function grab()
  d.Held=true;rag.Value=true;motor.Enabled=false;socket.Enabled=true;collider.CanCollide=true;hdata.PlatformStand=true;hdata.AutoRotate=false;hdata.State='Physics'
 end
 return {Data=d,Guard=guard,Pre=pre,Heart=heart,Step=step,Grab=grab,Root=root,RootData=rootData,Hum=hum,HumData=hdata,Rag=rag,Character=c,Motor=motor,Socket=socket,Collider=collider,Torso=torso,Leg=leg}
end
