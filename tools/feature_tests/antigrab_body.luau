
local count=0
local function check(value,message)assert(value,message);count+=1 end
local function fixture(mode)
 local d={Now=0,Held=true,Enabled=true,Mode=mode or 'Normal',Struggles=0,Clears={},Active={},Tasks={},Changes={},Writes={}}
 local signal={}
 function signal:Connect(fn)self.Callback=fn;local c={Connected=true};function c:Disconnect()self.Connected=false end;self.Connection=c;return c end
 local c={Parent={}}
 local rootData={Parent=c,CFrame='original frame',AssemblyLinearVelocity='falling velocity',AssemblyAngularVelocity='angular',Anchored=false,CanCollide=true}
 local root=setmetatable({},{__index=rootData,__newindex=function(_,k,v)d.Writes[#d.Writes+1]='root.'..k;rootData[k]=v end})
 local rag={Value=true,IsA=function(_,class)return class=='BoolValue'end}
 local hdata={Parent=c,Health=100,AutoRotate=true,RequiresNeck=true,PlatformStand=false,Sit=false,WalkSpeed=22,FloorMaterial='Grass',State='Physics'}
 hdata.FindFirstChild=function(_,name)return name=='Ragdolled'and rag end
 hdata.GetState=function()return hdata.State end
 hdata.ChangeState=function(_,value)d.Changes[#d.Changes+1]=value;hdata.State=value end
 local hum=setmetatable({},{__index=hdata,__newindex=function(_,k,v)d.Writes[#d.Writes+1]='hum.'..k;hdata[k]=v end})
 local ctx={RunService={Heartbeat=signal},Clock=function()return d.Now end,
  Enabled=function()return d.Enabled end,Held=function()return d.Held end,Mode=function()return d.Mode end,
  Character=function()return d.Character or c,d.Root or root,d.Humanoid or hum end,
  SetActive=function(value)d.Active[#d.Active+1]=value end,
  Struggle=function()d.Struggles+=1;if d.Throw then error('remote denied')end end,
  Ragdoll=function(r,t)d.Clears[#d.Clears+1]={Root=r,Duration=t};if d.Throw then error('remote denied')end end,
  Spawn=function(fn)d.Tasks[#d.Tasks+1]=fn end,
  ExtraEscape=function(valid)if valid()then d.Escapes=(d.Escapes or 0)+1 end end}
 local guard=Guard.Install(ctx)
 local function step(n,fps)for _=1,n do d.Now+=1/fps;if signal.Connection.Connected then signal.Callback()end end end
 return {Data=d,Guard=guard,Signal=signal,Step=step,Root=root,Hum=hum,HumData=hdata,Rag=rag,Character=c,RootData=rootData}
end
for _,mode in ipairs({'Normal','No Ragdoll'})do for _,fps in ipairs({30,60,120,240,1000})do
 local f=fixture(mode);f.Guard:Refresh();f.Step(fps*3,fps)
 check(#f.Data.Writes==0,'Normal movement fields were overridden: '..mode..' / '..table.concat(f.Data.Writes,','))
 check(f.Root.CFrame=='original frame'and f.Root.AssemblyLinearVelocity=='falling velocity','Root motion/gravity was overwritten')
 check(f.Hum.WalkSpeed==22 and f.Hum.AutoRotate and f.Hum.RequiresNeck and not f.Hum.Sit and not f.Hum.PlatformStand,'Native character settings changed')
 check(f.Data.Struggles>=60 and f.Data.Struggles<=92,'Source native request cadence changed/grows with FPS')
 check(#f.Data.Changes==0,'Local recovery bypassed an active server ragdoll flag')
 for _,call in ipairs(f.Data.Clears)do check(call.Root==f.Root and call.Duration==0,'Normal mode sent seated ragdoll or wrong root')end
 f.Rag.Value=false;f.Step(math.ceil(fps*.2),fps)
 check(f.Data.Changes[1]=='Running','Acknowledged grounded recovery did not request native Running')
 check(#f.Data.Writes==0,'Grounded recovery rewrote movement properties')
 f.HumData.FloorMaterial='Air';f.HumData.State='Freefall';local changes=#f.Data.Changes;f.Step(math.ceil(fps*.2),fps)
 check(#f.Data.Changes==changes,'Jump/fall was forced into a grounded state')
 f.Data.Held=false;local before=#f.Data.Clears;f.Guard:Refresh()
 check(not f.Guard.Session and f.Data.Active[#f.Data.Active]==false,'Release kept its active session')
 check(#f.Data.Clears==before+1,'Release did not perform its one final native clear')
 f.Step(fps,fps);check(#f.Data.Clears==before+1,'Idle controller kept firing clear requests')
 f.Guard:Dispose();f.Guard:Dispose();check(not f.Signal.Connection.Connected,'Unload leaked heartbeat callback')
end end
do
 local f=fixture('Anti-Kill');f.Guard:Refresh()
 check(f.Hum.Sit==true and f.Data.Clears[1].Duration==.11,'Explicit Anti-Kill mode was lost')
 f.Data.Mode='Normal';f.Guard:Refresh()
 check(f.Hum.Sit==false and f.Guard.Session.Mode=='Normal','Mode change left intentional Anti-Kill sitting active')
 local before=#f.Data.Writes;f.Step(60,60);check(#f.Data.Writes==before,'Normal mode began writing movement after mode switch')
end
do
 local f=fixture('Escapes Anything, but buggy');f.Guard:Refresh()
 check(#f.Data.Tasks==1 and #f.Data.Clears==0,'Legacy escape cadence/mode changed')
 f.Data.Mode='Normal';f.Guard:Refresh();f.Data.Tasks[1]()
 check(not f.Data.Escapes,'Canceled pending legacy escape ran after switching to normal')
end
do
 local f=fixture();f.Guard:Refresh();f.Data.Enabled=false;f.Guard:Refresh()
 local n=#f.Data.Clears;f.Step(240,240)
 check(#f.Data.Clears==n and not f.Guard.Session,'Toggle off left requests alive')
 check(#f.Data.Writes==0,'Toggle cleanup changed walking/gravity properties')
end
do
 local f=fixture();f.Data.Throw=true;f.Step(120,120)
 check(f.Guard.LastError~=nil and f.Data.Struggles<32,'Request failures escaped or flooded retries')
 check(#f.Data.Writes==0,'Request errors triggered manual movement fallback')
end
do
 local f=fixture();f.Guard:Refresh();f.HumData.Health=0;f.Guard:Refresh()
 check(not f.Guard.Session and f.Data.Active[#f.Data.Active]==false,'Death kept old root session')
end
print('PASS: '..count..' native Anti Grab, gravity, cadence, mode and lifecycle assertions (mocked)')
