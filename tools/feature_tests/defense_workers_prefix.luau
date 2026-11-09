local now, scheduled, unloads, signals = 0, {}, {}, {}
local task = {}
function task.spawn(callback)
    local job = coroutine.create(callback)
    local ok, delay = coroutine.resume(job)
    assert(ok, delay)
    if coroutine.status(job) ~= "dead" then scheduled[job] = now + (delay or 0) end
    return job
end
function task.wait(delay) return coroutine.yield(delay or 1/60) end
function task.cancel(job) scheduled[job] = nil; coroutine.close(job) end
local function advance(duration)
    local untilAt = now + duration
    while true do
        local selected, earliest = nil, math.huge
        for job, due in pairs(scheduled) do if due < earliest then selected, earliest = job, due end end
        if not selected or earliest > untilAt + 1e-8 then break end
        now = earliest; scheduled[selected] = nil
        local ok, delay = coroutine.resume(selected)
        assert(ok, delay)
        if coroutine.status(selected) ~= "dead" then scheduled[selected] = now + (delay or 0) end
    end
    now = untilAt
end
local function tick() return now end
local lib = {}
function lib:OnUnload(callback) unloads[#unloads+1] = callback end
function lib:GiveSignal(signal) signals[#signals+1] = signal; return signal end
local heldCallbacks = {}
local isHeld = {Value = false}
function isHeld:GetPropertyChangedSignal()
    return {Connect = function(_, callback)
        local connection = {Connected = true}
        function connection:Disconnect() self.Connected = false end
        heldCallbacks[#heldCallbacks+1] = {Callback=callback,Connection=connection}
        return connection
    end}
end
local function held(value)
    isHeld.Value = value
    for _, listener in ipairs(heldCallbacks) do if listener.Connection.Connected then listener.Callback() end end
end
local label = {Parent = true, Visible = false}
local timer = {Parent = true, Value = 4}
local pc = {FindFirstChild = function(_,name) if name == "Astral/Escape" then return label end end}
local controls = {PCFrame=pc, FindFirstChild = function(_,name) if name == "PCFrame" then return pc end end}
local playerGui = {FindFirstChild = function(_,name) if name == "ControlsGui" then return controls end end}
local localPlayer = {InOwnedPlot={Value=true}}
function localPlayer:FindFirstChild(name) if name == "HeldTimer" then return timer elseif name == "PlayerGui" then return playerGui end end
local Enum = {KeyCode={Space="Space"}}
local UserInputService = {IsKeyDown=function()return true end}
local unbound = 0
local ContextActionService = {UnbindAction=function()unbound+=1 end}
local escapeCalls, stickyCalls = {}, {}
local tbl11 = {Struggle={FireServer=function(_,player)assert(player==localPlayer);escapeCalls[#escapeCalls+1]=now end}}
local tbl8, tbl9 = {FasterEscape=false,AntiSticky=false}, {FasterEscape=0}
local flag11 = false
local workspace, v17 = {PlotItems={}}, {}
local function sticky(name)
    local parent, part = {}, {Name="StickyPart"}
    parent.Part=part;part.Parent=parent;part.Id=name
    function part:IsDescendantOf()return false end
    function part:GetChildren()return{}end
    return part
end
local a, b = sticky("A"), sticky("B")
local limb = {GetConnectedParts=function()return {a,b,a,b}end}
local character = {QueryDescendants=function()return {limb,limb,limb}end}
local tbl12 = {
    Char=function()return character end,
    FindNicePart=function(model)return model.Part end,
    Grab=function(part)stickyCalls[#stickyCalls+1]={At=now,Part=part}end,
}
local stickyCallback
local Antis = {AddToggle=function(_,id,info)assert(id=="AntiSticky");stickyCallback=info.Callback end}
