-- A shared game grab channel is reserved while the board changes owner. Holding
-- movers still follow the actor; refresh traffic resumes as one release/grab.
local sim=Sim.new();currentSim=sim;local t=target('Victim');local actor=newNode('Part','ActorRoot',WORLD)
local busy=true;local grabs,releases,requests,physics=0,0,0,0
local player={};local s={Player=player,Character=t.Character,Root=t.Torso,Humanoid=t.Humanoid,
 Position={Position=t.Torso.Position},Physics={},Requested=true,Releases={{Frame=1}}}
local ctx={Clock=function()return sim.Now end,Enabled=function()return true end,Selected=function()return true end,
 Character=function()return t.Character,t.Torso,t.Humanoid end,LocalCharacter=function()return {},actor,t.Humanoid end,
 OwnershipBusy=function()return busy end,Owned=function()return true end,NetworkOwned=function()return true end,
 Grab=function()grabs+=1 end,Release=function()releases+=1 end,RequestRagdoll=function()requests+=1 end,
 Collisions=function()physics+=1 end,Limbs=function()end,RagdollEnabled=function()return true end,
 StickyEnabled=function()return false end,EKIEnabled=function()return false end}
local loop=setmetatable({Context=ctx,Sessions={[player]=s},NativeTick=true,MaximumSpeed=true,Frame=1,Calls=0,Released=0},Loop)
Handoff.Grabbed(s,0,-.1,.1)
ctx.PingSeconds=function()return .1 end
local destination=Vector3.new(4,15,0)
loop:FlushReleases();loop:Update(s,destination,0,.1)
check(releases==0 and grabs==0 and requests==0,'Target refresh interrupted board acquisition')
check(physics>0 and s.Position.Position==destination and #s.Releases==1,'Board acquisition stopped the existing hold')
busy=false;loop:FlushReleases();loop:Update(s,destination,0,.1)
check(releases==1 and grabs==0 and requests==1,'Target was regrabbed in the release callback')
loop.Frame=2;sim.Now=.12;loop:Update(s,destination,sim.Now,.1)
check(releases==1 and grabs==1 and requests==2,'Target native refresh did not resume after a bounded release phase')
check(#s.Releases==1 and s.Releases[1].Frame==3,'Overdue release callbacks were replayed as a burst')
print('PASS: '..checks..' shared grab channel and hold continuation checks (mocked)')
