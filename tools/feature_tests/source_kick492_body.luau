-- Execute the delivered controller, including its native frame clock.
function Node:GetDescendants()
 local found={};for _,v in ipairs(self:GetChildren())do found[#found+1]=v;for _,child in ipairs(v:GetDescendants())do found[#found+1]=child end end;return found
end
local function setup(mode,fps,period)
 local sim=Sim.new();currentSim=sim
 local t=target('Victim');local actor=newNode('Part','Actor',WORLD);local player={Name='Victim'}
 local data={Mode=mode,Physical=false,Marker=false,Enabled=true,Selected=true,Grant=true,Log={},Period=period}
 local ctx={RunService=sim.RunService,Clock=function()return sim.Now end,SpawnThread=function(fn)sim:Spawn(fn)end,
  MaximumSpeed=true,NativePhases=true,SourceMode=function()return data.Mode end,
  Enabled=function()return data.Enabled end,Selected=function()return data.Selected end,Targets=function()return{player}end,
  Character=function()return t.Character,t.Torso,t.Humanoid end,LocalCharacter=function()return {},actor,t.Humanoid end,
  Owned=function()return data.Physical and data.Marker end,NetworkOwned=function()return data.Physical end,
  MarkerOwned=function()return data.Marker end,OwnershipBusy=function()return false end,
  Grab=function(root)
   check(root==t.Torso,'Source grabbed a replacement or unrelated root')
   data.Log[#data.Log+1]={Kind='G',Frame=data.Loop.Frame,Time=sim.Now}
   if data.Grant then data.Physical=true;data.Marker=true end
  end,
  Release=function(root)check(root==t.Torso,'Source released another root');data.Log[#data.Log+1]={Kind='R',Frame=data.Loop.Frame,Time=sim.Now};data.Marker=false end,
  Acquire=function()error('Nearby source fixture unexpectedly teleported for ownership')end,
  Collisions=function()end,Limbs=function()end,RestoreMotors=function()end,
  CancelRagdoll=function()end,RagdollEnabled=function()return false end,
  StickyEnabled=function()return false end,Height=function()return 15 end,
  EKIEnabled=function()return false end,PingSeconds=function()return .1 end,
  IntervalSeconds=function()return data.Period end}
 data.Loop=Loop.Install(ctx)
 return sim,data,t
end
for _,fps in ipairs({30,60,144,240})do for _,mode in ipairs({'Faster','Normal'})do
 local sim,d=setup(mode,fps);sim:Run(1,fps)
 check(d.Log[1].Kind=='G'and d.Log[2].Frame>d.Log[1].Frame,'First capture was released before its acknowledgement tick')
 local perFrame={};for _,event in ipairs(d.Log)do
  perFrame[event.Frame]=(perFrame[event.Frame]or'')..event.Kind
 end
 local seen=0
 for frame=2,d.Loop.Frame do if perFrame[frame]then
  seen+=1
  local expected=mode=='Faster'and'GR'or({'G','GRG','GG','GR'})[(seen-1)%4+1]
  check(perFrame[frame]==expected,'Wrong '..mode..' source phase: '..perFrame[frame]..' expected '..expected)
 end end
 check(seen>=10 and seen<=60,'Source cadence became render-FPS-dependent or stopped')
 local before=#d.Log;d.Enabled=false;sim:Run(.2,fps)
 check(not next(d.Loop.Sessions),'Disable retained source holding movers')
 local stopped=#d.Log;sim:Run(.2,fps);check(#d.Log==stopped,'Disabled source restarted requests')
 d.Loop:Dispose()
end end
do
 local sim,d=setup('Faster',60);d.Grant=false;d.Marker=true;d.Physical=false
 sim:Run(.5,60)
 for _,event in ipairs(d.Log)do check(event.Kind~='R','Foreign/stale marker was mistaken for initial physical capture')end
 d.Grant=true;sim:Run(.3,60);local firstRelease
 for _,event in ipairs(d.Log)do if event.Kind=='R'then firstRelease=event;break end end
 check(firstRelease~=nil,'Corrected acquisition did not resume source cadence');d.Loop:Dispose()
end
do
 local sim,d=setup('Faster',240,.2);sim:Run(1.1,240)
 local cycles=0;for _,event in ipairs(d.Log)do if event.Kind=='R'then cycles+=1 end end
 check(cycles>=4 and cycles<=6,'Loop MS did not time complete source cycles')
 d.Period=nil;local before=#d.Log;sim:Run(.3,240);check(#d.Log>before+15,'Disabling Loop MS did not restore native source cadence')
 d.Mode='Normal';sim:Run(.2,240);check(d.Loop.Sessions[next(d.Loop.Sessions)].SourceMode=='Normal','Live source mode switch was ignored')
 d.Selected=false;sim:Run(.1,240);check(not next(d.Loop.Sessions),'Unselected source target retained its session');d.Loop:Dispose()
end
do
 local sim,d,first=setup('Normal',60);local ctx=d.Loop.Context
 local p1=ctx.Targets()[1];local p2,p3={Name='Second'},{Name='Third'}
 local second,third=target('Second'),target('Third');local targets={p1,p2,p3};local map={[p1]=first,[p2]=second,[p3]=third}
 ctx.Targets=function()return targets end
 ctx.Character=function(player)local t=map[player];return t.Character,t.Torso,t.Humanoid end
 ctx.Grab=function()d.Physical=true;d.Marker=true end;ctx.Release=function()d.Marker=false end
 sim:Run(.1,60);local count=0
 for _,session in pairs(d.Loop.Sessions)do
  count+=1;check(session.Position.Position.Magnitude<30,'Source multi-target stack left native ownership range')
 end
 check(count==3,'Source mode did not maintain all three targets');d.Loop:Dispose()
end
print('PASS: '..checks..' source Faster/Normal sequences, initial capture, frame bounds, Loop MS, mode switching and lifecycle checks (mocked)')
