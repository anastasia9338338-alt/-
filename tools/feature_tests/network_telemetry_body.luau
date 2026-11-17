local clock, calls, latency=0,0,.08
local player={GetNetworkPing=function()calls+=1;return latency end}
local reader=Telemetry.Install({Player=player,Clock=function()return clock end})
check(reader:ReadMs()==80 and reader:Seconds()==.08,"Roblox isolated round-trip seconds were not converted to milliseconds exactly once")
for _=1,1000 do reader:ReadMs()end
check(calls==1,"Kick/HUD readers performed uncached per-frame telemetry calls")
latency=.093;clock=.51
check(reader:ReadMs()==93,"Transport latency stopped following the Roblox measurement")
for _,invalid in ipairs({0/0,math.huge,-1})do
    latency=invalid;clock+=1
    check(reader:ReadMs()==nil and reader:Seconds()==nil,"Invalid latency was displayed as an invented ping")
end
player.GetNetworkPing=function()error("unavailable")end;clock+=1
check(reader:ReadMs()==nil,"Failed latency API reused stale data or sampled replication Data Ping")
player.GetNetworkPing=function()return 3 end;clock+=1
check(reader:ReadMs()==3000,"An actual high transport RTT was hidden by an arbitrary clamp")
print('PASS: '..checks..' isolated Roblox RTT, single unit conversion, shared sampling and unavailable-data checks (mocked)')
