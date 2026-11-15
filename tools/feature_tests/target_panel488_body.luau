-- Tests the delivered panel, native action dispatch and removed UI surface.
local checks=0
local function check(value,message)assert(value,message);checks+=1 end
local function signal()
 local s={Listeners={}}
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;c.Fn=fn;self.Listeners[#self.Listeners+1]=c;return c end
 function s:Fire(...)for _,c in ipairs(self.Listeners)do if c.Connected then c.Fn(...)end end end
 return s
end
local groups,toggles,buttons,deps={},{},{},{}
local function group(name)
 local g={Name=name,Labels={}}
 function g:AddToggle(id,config)
  local t={Value=config.Default,Config=config,Id=id}
  function t:SetValue(v)self.Value=v;config.Callback(v)end
  function t:AddKeyPicker(key,data)self.Binding={Id=key,Data=data};return self end
  toggles[id]=t;return t
 end
 function g:AddButton(config)buttons[#buttons+1]=config;return config end
 function g:AddLabel(value)local l={Text=value,Parent=self};function l:SetText(v)self.Text=v end;self.Labels[#self.Labels+1]=l;return l end
 function g:AddDependencyBox()
  local d=group('Dependency');deps[#deps+1]=d
  function d:SetupDependencies(values)self.Dependencies=values end
  return d
 end
 groups[#groups+1]=g;return g
end
local tab={AddLeftGroupbox=function(_,name)return group(name)end}
local beat=signal();local unload;local library={OnUnload=function(_,fn)unload=fn end}
local a,b={Name='Selected'},{Name='Protected'}
local selected={[a]=true,[b]=true};local queue={};local called={};local protected={[b]=true}
local function action(name)return function(player)called[#called+1]={Name=name,Player=player}end end
local api={Void=action('Void'),Kill=action('Kill'),BringPlayer=action('Bring'),EatAntiInput=action('Food'),DeleteSeatables=action('Seatables'),RemoveGucci=action('Gucci'),
 GetTargets=function()return{a,b}end,IsProtectedPlayer=function(p)return protected[p]==true end,
 RunPlayerMethod=function(_,fn,p)fn(p)end,Char=function(p)return{Owner=p},{Massless=true}end,Ragdoll=action('Ragdoll'),RemoveSticky=action('AntiKick'),HoldableActions={Apply=function(_,p)action('Holdable')(p)end}}
local gucci={Enabled=false,Requests={}}
function gucci:SetEnabled(v)self.Enabled=v;self.Requests[#self.Requests+1]=v end
local desync={Enabled=false,Supported=true,Status='Disabled'}
function desync:SetEnabled(v)self.Enabled=v;self.Status=v and 'Active'or'Disabled' end
local decoyCalls=0
local controller=Panel.Install({API=api,Data={SelectedPlayers=selected},Library=library,RunService={Heartbeat=beat},Spawn=function(fn)queue[#queue+1]=fn end,
 Notify=function(message)error(message)end,Gucci=gucci,Desync=desync,Decoy={Enabled=true,BuildUI=function()decoyCalls+=1 end}})
controller:BuildUI(tab)
check(#buttons==0 and not controller.GucciButton,'Removed Destroy/Stop Gucci buttons remain in the panel')
check(decoyCalls==0,'Removed YouDecoy Gucci still creates controls')
for _,name in ipairs({'TargetLoopVoid','TargetLoopKill','TargetLoopBring','TargetLoopRagdoll','TargetDestroyFood','TargetDeleteSeatables','AntiKickRemoverNK','TargetLoopGucci','TargetRemoveInvisibility','TargetDestroyDesync','TargetBreakHoldable'})do
 check(toggles[name]~=nil,'Existing independent toggle was removed: '..name)
 check(toggles[name].Binding.Data.Mode=='Toggle'and toggles[name].Binding.Data.SyncToggleState,'Native toggle binding lost: '..name)
end
check(gucci.Label.Parent.Dependencies[1][1]==toggles.TargetLoopGucci,'Gucci disabled status clutters the main panel')
check(controller.DesyncLabel.Parent.Dependencies[1][1]==toggles.TargetDestroyDesync,'Desync disabled status clutters the main panel')
toggles.TargetLoopGucci:SetValue(true);check(gucci.Enabled,'Auto Destroy Gucci lost its real controller callback')
toggles.TargetLoopGucci:SetValue(false);check(not gucci.Enabled,'Auto Destroy Gucci cannot stop')
toggles.TargetLoopKill:SetValue(true)
check(#queue==2,'Selected target dispatch was not queued')
for _,fn in ipairs(queue)do fn()end;table.clear(queue)
check(#called==1 and called[1].Name=='Kill'and called[1].Player==a,'Protected target was processed or native action changed')
beat:Fire(.25);check(#queue==2,'Loop does not use the shared heartbeat')
toggles.TargetLoopKill:SetValue(false)
for _,fn in ipairs(queue)do fn()end;table.clear(queue)
check(#called==1,'Stopped loop executed a stale pending request')
toggles.TargetDestroyDesync:SetValue(true);check(desync.Enabled,'Desync controller callback was removed')
beat:Fire(.25);check(controller.DesyncLabel.Text=='Active','Native controller status is stale')
toggles.TargetDeleteSeatables:SetValue(true)
check(#queue==2,'Seatables callback no longer dispatches')
selected[a]=nil
for _,fn in ipairs(queue)do fn()end;table.clear(queue)
check(#called==1,'Deselected player received a stale action')
unload()
check(controller.Closed and not controller.Connection.Connected and not gucci.Enabled and not desync.Enabled,'Unload did not stop controllers and observer')
controller:SetLoop('Kill',true);beat:Fire(1)
check(#queue==0,'Closed panel restarted a target worker')
print('PASS: '..checks..' target panel removal, native toggles, protection, queued cancellation, compact status and disposal checks (mocked)')
