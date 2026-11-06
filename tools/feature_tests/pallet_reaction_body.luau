-- Run after model_mock.luau + local Reaction=<actual PalletReaction module>.
-- These are read-only observation scenarios, not server-hit/blur simulation.
local total=0;local function expect(v,m)assert(v,m);total+=1 end
local function fixture(rootName,ragged,hitbox)
 local world=newNode('Workspace','World');local c=newNode('Model','Avatar');c.Parent=world
 local root=newNode('Part',rootName or'HumanoidRootPart');root.Parent=c
 local torso=newNode('Part','Torso');torso.Parent=c
 local h=newNode('Humanoid','Humanoid');h.Health=100;h.Parent=c
 local flag=newNode('BoolValue','Ragdolled');flag.Value=ragged==true;flag.Parent=h
 local receiver
 if hitbox~=false then receiver=newNode('Part','RagdollTouchedHitbox');receiver.Parent=root end
 local t=0;local r=Reaction.new(c,function()return t end)
 return{World=world,Character=c,Root=root,Torso=torso,Humanoid=h,Flag=flag,Receiver=receiver,Reaction=r,Tick=function()t+=.1 end}
end
for _,name in ipairs({'HumanoidRootPart','realHrp','realHRP','saviHRP'})do
 local f=fixture(name);local receiver,kind=Reaction.Resolve(f.Character)
 expect(receiver==f.Receiver and kind=='RagdollTouchedHitbox','Named game receiver was not preferred for '..name)
 local original=f.Receiver.CanTouch;f.Receiver.CanTouch=false
 local reason,detail
 receiver,kind,reason,detail=Reaction.Resolve(f.Character)
 expect(receiver==f.Torso and kind=='TorsoFallback'and reason==nil and detail~=nil,'Disabled named receiver lost the source torso fallback or its diagnostic')
 local token=f.Reaction:StartAttempt();expect(token and token.Receiver==f.Torso,'Disabled named receiver prevented a valid torso attempt')
 expect(f.Receiver.CanTouch==false,'Resolver enabled a disabled game receiver')
 expect(f.Reaction:Describe().FallbackReason==detail,'Fallback diagnostic was not retained by observer')
 f.Receiver.CanTouch=original;local token2=f.Reaction:StartAttempt();expect(token2 and token2.Receiver==f.Receiver,'Re-enabled receiver did not rebind')
 expect(not f.Reaction:ObservedSince(token),'Fallback token survived replacement by named receiver')
 f.Reaction:Dispose()
end
do
 local f=fixture(nil,false,false);local receiver,kind=Reaction.Resolve(f.Character)
 expect(receiver==f.Torso and kind=='TorsoFallback','Missing named receiver did not use explicit torso fallback')
 local invalid=newNode('Folder','RagdollTouchedHitbox');invalid.Parent=f.Root
 local fallback,_,failure,detail=Reaction.Resolve(f.Character)
 expect(fallback==f.Torso and failure==nil and detail~=nil,'Non-part named receiver prevented original torso fallback or lost its diagnostic')
 invalid:Destroy();f.Torso.CanTouch=false
 expect(Reaction.Resolve(f.Character)==nil,'Disabled torso fallback was accepted')
 f.Reaction:Dispose()
end
do
 local f=fixture(nil,false,false);local wrong=newNode('Part','RagdollTouchedHitbox');wrong.Parent=f.Character
 local receiver,kind,reason,detail=Reaction.Resolve(f.Character)
 expect(receiver==f.Torso and kind=='TorsoFallback'and reason==nil and detail~=nil,'Unexpected named receiver location prevented a valid source fallback')
 expect(wrong.CanTouch==true,'Mislocated receiver was mutated')
 f.Reaction:Dispose()
end
do
 local f=fixture();f.Receiver.CanTouch=false
 local root=newNode('Part','realHrp');root.Parent=f.Character
 local receiver=newNode('Part','RagdollTouchedHitbox');receiver.Parent=root
 local selected,kind=Reaction.Resolve(f.Character)
 expect(selected==receiver and kind=='RagdollTouchedHitbox','Unusable first named receiver hid another usable named receiver')
 expect(f.Receiver.CanTouch==false,'Resolver enabled first named receiver while choosing another')
 f.Reaction:Dispose()
end
do
 local f=fixture(nil,false,false);f.Torso.CanTouch=false
 local upper=newNode('Part','UpperTorso');upper.Parent=f.Character
 expect(Reaction.Resolve(f.Character)==upper,'Touchable UpperTorso was ignored when Torso was disabled')
 expect(f.Torso.CanTouch==false,'Resolver enabled disabled Torso')
 f.Reaction:Dispose()
end
do
 local f=fixture();local token=f.Reaction:StartAttempt();local before=f.Reaction:Describe()
 expect(token and token.Baseline==false and before.Rises==0,'Idle target produced a fake initial reaction')
 expect(not f.Reaction:ObservedSince(token),'No property transition was accepted as a game hit')
 f.Tick();f.Flag.Value=true
 expect(f.Reaction:ObservedSince(token),'New false-to-true game state was not observed')
 local after=f.Reaction:Describe();expect(after.Rises==1 and after.LastRiseAt==.1,'Reaction edge was lost or counted twice')
 f.Flag.Value=true;expect(f.Reaction:Describe().Rises==1,'Repeated true assignments counted as new hits')
 local same=f.Reaction:StartAttempt();expect(same.Baseline==true and not f.Reaction:ObservedSince(same),'Already ragdolled target counted as a new hit')
 f.Flag.Value=false;f.Tick();f.Flag.Value=true
 expect(f.Reaction:ObservedSince(same)and f.Reaction:Describe().Rises==2,'A later genuine reaction edge was not observed')
 f.Reaction:Dispose()
end
do
 local f=fixture(nil,true);local token=f.Reaction:StartAttempt()
 expect(token and token.Baseline==true and f.Reaction:Describe().Rises==0,'Initially true state was reported as a new hit')
 expect(not f.Reaction:ObservedSince(token),'Initially true state acknowledged an attempt')
 f.Flag.Value=false;f.Flag.Value=true
 expect(f.Reaction:ObservedSince(token),'Initially ragdolled target did not re-arm after a real new edge')
 f.Reaction:Dispose()
end
do
 local f=fixture();local token=f.Reaction:StartAttempt();local old=f.Flag
 old.Parent=nil;local replacement=newNode('BoolValue','Ragdolled');replacement.Value=true;replacement.Parent=f.Humanoid
 old.Value=true
 expect(not f.Reaction:ObservedSince(token),'Detached old flag acknowledged a replacement target binding')
 expect(f.Reaction:Describe().Rises==0,'True replacement flag generated a false reaction edge')
 local fresh=f.Reaction:StartAttempt();replacement.Value=false;replacement.Value=true
 expect(f.Reaction:ObservedSince(fresh),'Replacement flag could not observe its own new reaction')
 f.Reaction:Dispose()
end
do
 local f=fixture();local token=f.Reaction:StartAttempt();local old=f.Receiver
 old.Parent=nil;local replacement=newNode('Part','RagdollTouchedHitbox');replacement.Parent=f.Root
 f.Flag.Value=true
 expect(not f.Reaction:ObservedSince(token),'Receiver replacement accepted a stale contact attempt')
 local fresh=f.Reaction:StartAttempt();f.Flag.Value=false;f.Flag.Value=true
 expect(f.Reaction:ObservedSince(fresh),'Replacement receiver never re-armed observation')
 f.Reaction:Dispose()
end
do
 local f=fixture();local token=f.Reaction:StartAttempt();local old=f.Humanoid
 old.Parent=nil;local h=newNode('Humanoid','Humanoid');h.Health=100;h.Parent=f.Character
 local flag=newNode('BoolValue','Ragdolled');flag.Value=true;flag.Parent=h
 f.Flag.Value=true
 expect(not f.Reaction:ObservedSince(token),'Humanoid replacement accepted an old reaction')
 expect(f.Reaction:Describe().Rises==0,'True replacement humanoid generated a false reaction edge')
 f.Reaction:Dispose()
end
for _,mode in ipairs({'dead','removed','disposed'})do
 local f=fixture();local token=f.Reaction:StartAttempt();local signal=f.Flag:GetPropertyChangedSignal('Value')
 if mode=='dead'then f.Humanoid.Health=0 elseif mode=='removed'then f.Character.Parent=nil else f.Reaction:Dispose()end
 f.Flag.Value=true
 expect(not f.Reaction:ObservedSince(token),'Old attempt survived target lifecycle: '..mode)
 local info=f.Reaction:Describe();expect(not info.Ready and info.Rises==0,'Invalid lifecycle created a reaction edge: '..mode)
 f.Reaction:Dispose();f.Reaction:Dispose()
 for _,c in ipairs(signal.Connections)do expect(not c.Connected,'Disposed observer leaked a flag connection')end
end
do
 local a=fixture();local b=fixture();local token=a.Reaction:StartAttempt();b.Flag.Value=true
 expect(not a.Reaction:ObservedSince(token),'Another target reaction acknowledged this target')
 expect(not b.Reaction:ObservedSince(token),'Foreign observer token was accepted')
 a.Reaction:Dispose();b.Reaction:Dispose()
end
-- Unlike GPCS rereads, BoolValue.Changed's boolean payload preserves a pulse
-- that finishes before deferred callbacks run. Keep these events queued while
-- current Value advances, and poll diagnostics between queueing and delivery.
local function deferredFixture(initial)
 local f=fixture(nil,initial);f.Reaction:Dispose();f.Flag.Changed=signal()
 f.Reaction=Reaction.new(f.Character,function()return 0 end)
 local queue={}
 function f.Queue(value)
  f.Flag._props.Value=value
  for _,connection in ipairs(f.Flag.Changed.Connections)do
   if connection.Connected then queue[#queue+1]={Connection=connection,Value=value}end
  end
 end
 function f.Flush()
  for _,event in ipairs(queue)do event.Connection.Fn(event.Value)end
  table.clear(queue)
 end
 return f
end
do
 local f=deferredFixture(false);local token=f.Reaction:StartAttempt()
 expect(f.Reaction:Describe().Observation=='BoolValueChanged','BoolValue payload signal was not preferred')
 f.Queue(true);f.Queue(false)
 expect(f.Reaction:Describe().Rises==0,'Polling fabricated an undelivered deferred edge')
 f.Flush()
 expect(f.Reaction:ObservedSince(token)and f.Reaction:Describe().Rises==1,'Deferred complete true/false pulse was lost')
 expect(f.Reaction:StartAttempt().Baseline==false,'Deferred false payload did not restore the observation baseline')
 f.Queue(true)
 expect(f.Reaction:Describe().Rises==1,'Polling current true counted a deferred rise early')
 f.Flush();expect(f.Reaction:Describe().Rises==2,'Deferred rise was lost or double-counted after polling')
 f.Reaction:Dispose()
end
do
 local f=deferredFixture(true);local token=f.Reaction:StartAttempt()
 f.Queue(false);f.Queue(true)
 expect(not f.Reaction:ObservedSince(token),'Current true with undelivered callbacks was accepted as a new observed edge')
 f.Flush();expect(f.Reaction:ObservedSince(token)and f.Reaction:Describe().Rises==1,'Deferred false/true payload sequence was lost or double-counted')
 f.Reaction:Dispose()
end
for _,mode in ipairs({'replaced','disposed','removed'})do
 local f=deferredFixture(false);local token=f.Reaction:StartAttempt();f.Queue(true)
 if mode=='replaced'then
  f.Flag.Parent=nil
  local replacement=newNode('BoolValue','Ragdolled');replacement.Value=false;replacement.Changed=signal();replacement.Parent=f.Humanoid
  f.Reaction:Refresh()
 elseif mode=='disposed'then f.Reaction:Dispose()
 else f.Character.Parent=nil end
 f.Flush()
 expect(not f.Reaction:ObservedSince(token)and f.Reaction:Describe().Rises==0,'Queued callback survived invalid binding: '..mode)
 f.Reaction:Dispose()
end
print('PASS: '..total..' receiver selection, read-only ragdoll edges, stale bindings and lifecycle checks (mocked; no camera blur or server hits)')
