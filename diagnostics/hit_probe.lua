-- Run on the receiving account. BoolValue.Changed reads bound ragdoll payloads;
-- Blur signals read current properties, so deferred short pulses may be missed.
-- Discovery, geometry snapshots and UI refresh are limited to 10 Hz.
-- Native correction notifications and important state edges have a separate
-- bounded trace; they do not predict a server kick or acknowledge each impact.
-- Does not change camera effects, humanoid state, hitboxes, physics or remotes.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local HttpService=game:GetService('HttpService')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local player=assert(Players.LocalPlayer,'Hit probe requires a client')
local playerGui=player:FindFirstChildOfClass('PlayerGui')or player:WaitForChild('PlayerGui',10)
assert(playerGui,'PlayerGui is unavailable')

local host=type(getgenv)=='function'and getgenv()or _G
local registryKey='AstralReadOnlyHitProbe'
local previous=rawget(host,registryKey)
if type(previous)=='table'and previous.Tag=='hit-probe-1'and type(previous.Close)=='function'then previous.Close()end

local started=os.clock()
local state={Tag='hit-probe-1',Closed=false,Events={},CriticalEvents={},DetailedEventsDropped=0,CriticalEventsDropped=0,
    Connections={},CorrectionKinds={},CorrectionKindCount=0,Counts={Samples=0,CharacterChanges=0,
    RagdollChanges=0,RagdollRises=0,BlurChanges=0,BlurRises=0,BlurPositiveChanges=0,CorrectionNotifications=0},Snapshot={}}
local function rounded(n)
    if type(n)~='number'or n~=n or math.abs(n)==math.huge then return nil end
    return math.floor(n*100+.5)/100
end
local function vector(v)return{X=rounded(v.X),Y=rounded(v.Y),Z=rounded(v.Z)}end
local function serverTime()
    local ok,value=pcall(function()return workspace:GetServerTimeNow()end)
    if ok and type(value)=='number'and value==value and math.abs(value)<math.huge then return value end
    return nil
end
local function localRoot(character)
    local fallback
    if character then
        for _,name in ipairs({'HumanoidRootPart','realHRP','realHrp','saviHRP'})do
            local root=character:FindFirstChild(name)
            if root and root:IsA('BasePart')then
                fallback=fallback or root
                local receiver=root:FindFirstChild('RagdollTouchedHitbox')
                if receiver and receiver:IsA('BasePart')then return root end
            end
        end
    end
    return fallback
end
local function observedState()
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass('Humanoid')
    local rag=humanoid and humanoid:FindFirstChild('Ragdolled')
    if rag and not rag:IsA('BoolValue')then rag=nil end
    local root=localRoot(character)
    local camera=workspace.CurrentCamera
    local blur=camera and camera:FindFirstChild('Blur')
    if blur and not blur:IsA('BlurEffect')then blur=nil end
    return{CharacterPresent=character~=nil,HumanoidHealth=humanoid and rounded(humanoid.Health)or nil,
        RootName=root and root.Name or nil,RootPosition=root and vector(root.Position)or nil,
        RootVelocity=root and vector(root.AssemblyLinearVelocity)or nil,
        RagdolledPresent=rag~=nil,Ragdolled=rag and rag.Value,
        CameraBlur=blur and{Enabled=blur.Enabled,Size=rounded(blur.Size),Active=blur.Enabled and blur.Size>.01}or nil}
end
local function record(kind,data,critical)
    state.EventSerial=(state.EventSerial or 0)+1
    local event={Sequence=state.EventSerial,Seconds=math.floor((os.clock()-started)*10000+.5)/10000,
        ServerSeconds=serverTime(),Kind=kind,Data=data}
    state.Events[#state.Events+1]=event
    if #state.Events>20 then table.remove(state.Events,1);state.DetailedEventsDropped+=1 end
    if critical then
        state.CriticalEvents[#state.CriticalEvents+1]=event
        if #state.CriticalEvents>512 then table.remove(state.CriticalEvents,1);state.CriticalEventsDropped+=1 end
    end
end
local function connect(signal,fn)
    local c=signal:Connect(fn);state.Connections[#state.Connections+1]=c;return c
end

local gui=Instance.new('ScreenGui')
gui.Name='AstralReadOnlyHitProbe';gui.ResetOnSpawn=false;gui.DisplayOrder=1000
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local panel=Instance.new('Frame');panel.Name='Probe';panel.Size=UDim2.fromOffset(430,284)
panel.Position=UDim2.fromOffset(12,12);panel.BackgroundColor3=Color3.fromRGB(24,27,34)
panel.BorderSizePixel=0;panel.Parent=gui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,9);corner.Parent=panel
local function label(name,text,position,size,fontSize)
    local v=Instance.new('TextLabel');v.Name=name;v.BackgroundTransparency=1
    v.Position=position;v.Size=size;v.Font=Enum.Font.Code;v.TextSize=fontSize or 13
    v.TextColor3=Color3.fromRGB(230,233,240);v.TextXAlignment=Enum.TextXAlignment.Left
    v.TextYAlignment=Enum.TextYAlignment.Top;v.TextWrapped=true;v.AutoLocalize=false;v.Text=text;v.Parent=panel
    return v
end
label('Title','Hit probe — только наблюдение',UDim2.fromOffset(12,9),UDim2.new(1,-24,0,22),15)
label('Scope','Локальные состояния, не подтверждения серверных ударов.',UDim2.fromOffset(12,34),UDim2.new(1,-24,0,32),12)
local body=label('State','Ожидание первого замера…',UDim2.fromOffset(12,68),UDim2.new(1,-24,0,146),13)
label('Limit','События ragdoll/blur — по сигналам; поиск объектов — 10 Гц. Постоянное состояние не считает отдельные удары.',UDim2.fromOffset(12,215),UDim2.new(1,-24,0,32),11)
local function button(name,text,x,width)
    local v=Instance.new('TextButton');v.Name=name;v.Text=text;v.AutoLocalize=false
    v.Position=UDim2.fromOffset(x,251);v.Size=UDim2.fromOffset(width,25);v.BorderSizePixel=0
    v.BackgroundColor3=Color3.fromRGB(52,64,84);v.TextColor3=Color3.new(1,1,1)
    v.Font=Enum.Font.Code;v.TextSize=13;v.Parent=panel
    local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,5);c.Parent=v
    return v
end
local copyButton=button('Copy','Copy report',12,290)
local closeButton=button('Close','Close',312,106)

local lastCharacter,lastRag,lastRagValue,lastCamera,lastBlur,lastBlurState,lastReceiver,lastReceiverKey
local lastReceiverCriticalKey
local ragConnection
local blurConnections={}
local correctionRemote,correctionConnection,correctionInitialized
local function clearRagConnection()
    if ragConnection then ragConnection:Disconnect();ragConnection=nil end
end
local function clearBlurConnections()
    for _,connection in ipairs(blurConnections)do connection:Disconnect()end
    table.clear(blurConnections)
end
local function clearCorrectionConnection()
    if correctionConnection then correctionConnection:Disconnect();correctionConnection=nil end
end
local function nativeCorrections()
    local folder=ReplicatedStorage:FindFirstChild('GameCorrectionEvents')
    local remote=folder and folder:FindFirstChild('GameCorrectionsNotify')
    if remote and remote:IsA('RemoteEvent')then return remote end
    return nil
end
local function correctionKind(value)
    if type(value)~='string'then return'<'..type(value)..'>',false end
    local last=math.min(#value,80)
    -- Keep a byte bound without cutting a UTF-8 code point in the JSON report.
    while last>0 do
        local following=value:byte(last+1)
        if not following or following<128 or following>=192 then break end
        last-=1
    end
    local kind=value:sub(1,last)
    local ok,length=pcall(utf8.len,kind)
    if not ok or not length then return'<invalid text>',true end
    return kind,#value>last
end
local function observeCorrections()
    local remote=nativeCorrections()
    if not correctionInitialized or remote~=correctionRemote then
        clearCorrectionConnection();correctionInitialized=true;correctionRemote=remote
        record('game_corrections_binding',{Present=remote~=nil},true)
        if remote then
            correctionConnection=remote.OnClientEvent:Connect(function(value)
                if state.Closed or correctionRemote~=remote or nativeCorrections()~=remote then return end
                -- Observe only the known event's first kind. Do not dump other
                -- arguments or interpret this count as server kick progress.
                local kind,truncated=correctionKind(value)
                local key=kind
                if not state.CorrectionKinds[key]then
                    if state.CorrectionKindCount>=32 then key='<other kinds>'
                    else state.CorrectionKindCount+=1 end
                end
                state.Counts.CorrectionNotifications+=1
                state.CorrectionKinds[key]=(state.CorrectionKinds[key]or 0)+1
                record('game_correction',{Kind=kind,KindTruncated=truncated,
                    State=observedState()},true)
            end)
        end
    end
end
local function nativeRagdoll()
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass('Humanoid')
    local rag=humanoid and humanoid:FindFirstChild('Ragdolled')
    if rag and rag:IsA('BoolValue')then return rag end
    return nil
end
local function readRagdoll(value)
    if lastRagValue~=value then
        local previousValue=lastRagValue;lastRagValue=value
        state.Counts.RagdollChanges+=1
        if previousValue==false and value==true then state.Counts.RagdollRises+=1 end
        record('ragdoll_changed',{Previous=previousValue,Value=value,State=observedState()},true)
    end
    return value
end
local function observeRagdoll(rag)
    if rag~=lastRag then
        clearRagConnection();lastRag=rag;lastRagValue=rag and rag.Value
        record('ragdoll_baseline',{Present=rag~=nil,Value=lastRagValue},true)
        if rag then
            ragConnection=rag.Changed:Connect(function(value)
                -- BoolValue.Changed carries the transition value, even when
                -- a deferred callback runs after a second transition.
                if type(value)=='boolean'and not state.Closed and lastRag==rag and nativeRagdoll()==rag then readRagdoll(value)end
            end)
        end
    end
end
local function blurSnapshot(blur)
    if not blur then return nil end
    return{Enabled=blur.Enabled,Size=rounded(blur.Size),Active=blur.Enabled and blur.Size>.01}
end
local function readBlur(blur)
    local current=blurSnapshot(blur);local previousState=lastBlurState
    if current and previousState and(current.Enabled~=previousState.Enabled or current.Size~=previousState.Size)then
        -- The cache belongs to signal observation; polling reads snapshots
        -- separately and cannot double-count a deferred callback.
        lastBlurState=current;state.Counts.BlurChanges+=1
        if current.Active and not previousState.Active then state.Counts.BlurRises+=1 end
        if current.Active and(not previousState.Active or current.Size>previousState.Size+.01)then
            state.Counts.BlurPositiveChanges+=1
        end
        local onset=current.Active and not previousState.Active
        record('camera_blur_changed',{Previous=previousState,State=current,Onset=onset,
            CharacterState=onset and observedState()or nil},onset)
    end
    return current
end
local function observeBlur(camera,blur)
    if camera~=lastCamera or blur~=lastBlur then
        clearBlurConnections();lastCamera=camera;lastBlur=blur;lastBlurState=blurSnapshot(blur)
        record('camera_blur_baseline',{CameraPresent=camera~=nil,BlurPresent=blur~=nil,State=lastBlurState},true)
        if blur then
            local function changed()
                if state.Closed or lastCamera~=camera or lastBlur~=blur or workspace.CurrentCamera~=camera then return end
                if camera:FindFirstChild('Blur')==blur then readBlur(blur)end
            end
            for _,property in ipairs({'Enabled','Size'})do
                blurConnections[#blurConnections+1]=blur:GetPropertyChangedSignal(property):Connect(changed)
            end
        end
    end
    return blurSnapshot(blur)
end
local function receiverSnapshot(character)
    local root,part
    if character then
        for _,name in ipairs({'HumanoidRootPart','realHRP','realHrp','saviHRP'})do
            local candidate=character:FindFirstChild(name)
            local receiver=candidate and candidate:FindFirstChild('RagdollTouchedHitbox')
            if candidate and candidate:IsA('BasePart')and receiver and receiver:IsA('BasePart')then
                root=candidate;part=receiver;break
            end
        end
    end
    if not part then return nil,{Present=false}end
    local groupRead,group=pcall(function()return part.CollisionGroup end)
    return part,{Present=true,CanTouch=part.CanTouch,CanCollide=part.CanCollide,Anchored=part.Anchored,
        Size=vector(part.Size),OffsetFromRoot=vector(root.CFrame:PointToObjectSpace(part.Position)),
        CollisionGroup=groupRead and tostring(group)or 'unavailable'}
end
local function sample()
    if state.Closed then return end
    state.Counts.Samples+=1
    local character=player.Character
    if character~=lastCharacter then
        lastCharacter=character;clearRagConnection();lastRag=nil;lastRagValue=nil
        state.Counts.CharacterChanges+=1;record('character_changed',{Present=character~=nil},true)
    end
    local humanoid=character and character:FindFirstChildOfClass('Humanoid')
    local rag=humanoid and humanoid:FindFirstChild('Ragdolled')
    if rag and not rag:IsA('BoolValue')then rag=nil end
    local value=rag and rag.Value
    observeRagdoll(rag)
    local camera=workspace.CurrentCamera
    local blur=camera and camera:FindFirstChild('Blur')
    if blur and not blur:IsA('BlurEffect')then blur=nil end
    local blurState=observeBlur(camera,blur)
    observeCorrections()
    local receiver,receiverInfo=receiverSnapshot(character)
    local receiverKey=HttpService:JSONEncode(receiverInfo)
    local receiverCriticalKey=HttpService:JSONEncode({Present=receiverInfo.Present,CanTouch=receiverInfo.CanTouch,
        CanCollide=receiverInfo.CanCollide,Anchored=receiverInfo.Anchored,Size=receiverInfo.Size,CollisionGroup=receiverInfo.CollisionGroup})
    if receiver~=lastReceiver or receiverKey~=lastReceiverKey then
        local critical=receiver~=lastReceiver or receiverCriticalKey~=lastReceiverCriticalKey
        lastReceiver=receiver;lastReceiverKey=receiverKey;lastReceiverCriticalKey=receiverCriticalKey
        record('receiver_changed',receiverInfo,critical)
    end
    local native=observedState()
    state.Snapshot={CharacterPresent=character~=nil,HumanoidPresent=humanoid~=nil,
        HumanoidHealth=humanoid and rounded(humanoid.Health)or nil,
        RootName=native.RootName,RootPosition=native.RootPosition,RootVelocity=native.RootVelocity,
        RagdolledPresent=rag~=nil,Ragdolled=value,CameraPresent=camera~=nil,CameraBlur=blurState,
        GameCorrectionsPresent=correctionRemote~=nil,Receiver=receiverInfo}
    local ragText=rag and tostring(value)or 'не найден'
    local blurText=blurState and('Enabled='..tostring(blurState.Enabled)..' Size='..tostring(blurState.Size))or 'не найден'
    local receiverText='не найден'
    if receiverInfo.Present then
        local v,o=receiverInfo.Size,receiverInfo.OffsetFromRoot
        receiverText=string.format('CanTouch=%s, группа=%s\nSize %.2f %.2f %.2f | Offset %.2f %.2f %.2f',
            tostring(receiverInfo.CanTouch),receiverInfo.CollisionGroup,v.X,v.Y,v.Z,o.X,o.Y,o.Z)
    end
    body.Text=string.format('Ragdolled: %s\nНаблюдаемые изменения: %d | false→true: %d\nCamera.Blur: %s\nВсплески: %d | положит. изменения: %d\nКоррекции игры: %d | %s\nRagdollTouchedHitbox: %s',
        ragText,state.Counts.RagdollChanges,state.Counts.RagdollRises,blurText,
        state.Counts.BlurRises,state.Counts.BlurPositiveChanges,state.Counts.CorrectionNotifications,
        correctionRemote and'подключено'or'источник не найден',receiverText)
end
function state.Report()
    return{Probe='Astral read-only victim hit probe',Version=3,ElapsedSeconds=rounded(os.clock()-started),
        ServerSeconds=serverTime(),DiscoverySampleHz=10,EdgeObservation='BoolValue.Changed payloads for ragdoll; property signals read current camera blur',
        Scope='Local observations only. Not proof of server hit acceptance or a kick.',
        Limitations={'Objects are discovered at 10 Hz; pulses before an object is bound may be missed.','Camera blur signals read current properties; deferred short pulses may be missed.','Initial states are baselines, not hit counts.',
            'Continuously active ragdoll/blur cannot identify each impact.','Only CurrentCamera child named Blur is observed.',
            'Game corrections are observations on this receiving account, not a target kick-progress threshold.',
            'Only the bounded first correction kind is recorded; other remote arguments are ignored.',
            'State snapshots are taken when callbacks run; deferred event payloads can describe an earlier transition.',
            'ServerSeconds is the local GetServerTimeNow estimate when available.',
            'The critical trace keeps at most 512 events; dropped event counts are reported.'},
        Counts=state.Counts,GameCorrections={Present=correctionRemote~=nil and nativeCorrections()==correctionRemote,
            Kinds=state.CorrectionKinds},Snapshot=state.Snapshot,LastError=state.LastError,RecentEvents=state.Events,
        CriticalEvents=state.CriticalEvents,CriticalEventsDropped=state.CriticalEventsDropped,DetailedEventsDropped=state.DetailedEventsDropped}
end
function state.Close()
    if state.Closed then return end;state.Closed=true
    clearRagConnection();clearBlurConnections();clearCorrectionConnection()
    for _,connection in ipairs(state.Connections)do connection:Disconnect()end
    table.clear(state.Connections)
    if rawget(host,registryKey)==state then host[registryKey]=nil end
    gui:Destroy()
end
connect(copyButton.MouseButton1Click,function()
    local copy=setclipboard or toclipboard
    if type(copy)~='function'then copyButton.Text='Clipboard недоступен';return end
    local ok,why=pcall(function()copy(HttpService:JSONEncode(state.Report()))end)
    copyButton.Text=ok and 'Copied' or 'Copy failed'
    if not ok then state.LastError=tostring(why)end
end)
connect(closeButton.MouseButton1Click,state.Close)
connect(gui.Destroying,state.Close)
local elapsed=0
connect(RunService.Heartbeat,function(dt)
    if state.Closed then return end
    if not gui.Parent then state.Close();return end
    elapsed+=dt;if elapsed<.1 then return end;elapsed=elapsed%.1
    local ok,why=pcall(sample)
    if not ok then state.LastError=tostring(why);body.Text='Ошибка чтения: '..state.LastError end
end)
host[registryKey]=state
gui.Parent=playerGui
local ok,why=pcall(sample)
if not ok then state.LastError=tostring(why);body.Text='Ошибка чтения: '..state.LastError end
return state
