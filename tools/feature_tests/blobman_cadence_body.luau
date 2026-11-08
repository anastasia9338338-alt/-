local checks=0;local function check(v,m)assert(v,m);checks+=1 end
local function count(speed,fps)
 local now,waits,actions=0,0,0;local signal={}
 function signal:Wait()now+=1/fps;waits+=1 end
 local c=Cadence.new({Clock=function()return now end,Signal=signal});c:SetSpeed(speed)
 while now<2 do
  actions+=1;local before=waits
  check(c:Half(function()return true end),'Half cycle canceled unexpectedly');check(waits>before,'Two actions shared one physics callback')
 end
 return actions,now
end
for _,fps in ipairs({30,60,240})do
 local low=count(2,fps);local high=count(60,fps);check(high>low*3,'Hand speed did not change real action cadence')
end
do
 local now,valid,ticks=0,true,0;local signal={};local c
 function signal:Wait()now+=1/60;ticks+=1;if ticks==2 then valid=false end end
 c=Cadence.new({Clock=function()return now end,Signal=signal});c:SetSpeed(1)
 check(not c:Half(function()return valid end),'Canceled half-cycle admitted release')
 c:SetSpeed(10000);check(c.Speed==60,'Unbounded hand speed');c:SetSpeed(0/0);check(c.Speed==60,'Invalid hand speed accepted')
end
print('PASS: '..checks..' frame-bounded live hand cadence and cancellation checks (mocked)')
