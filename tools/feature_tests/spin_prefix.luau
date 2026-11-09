-- Exercise the real Main spin block through fake signals and avatars.
local checks = 0
local function check(value, message) assert(value, message); checks += 1 end
local function signal()
    local item = {Connections = {}}
    function item:Connect(callback)
        local connection = {Connected = true, Callback = callback}
        function connection:Disconnect() self.Connected = false end
        table.insert(self.Connections, connection)
        return connection
    end
    function item:Fire(...)
        for _, connection in ipairs(table.clone(self.Connections)) do
            if connection.Connected then connection.Callback(...) end
        end
    end
    function item:Count()
        local count = 0
        for _, connection in ipairs(self.Connections) do if connection.Connected then count += 1 end end
        return count
    end
    return item
end
local Vector3 = {new = function(x, y, z) return {X = x, Y = y, Z = z} end}
local movers = {}
local Instance = {new = function(class)
    check(class == "BodyAngularVelocity", "Unexpected spin instance")
    local mover = {Parent = nil, Destroyed = false}
    function mover:Destroy() self.Parent = nil; self.Destroyed = true end
    table.insert(movers, mover)
    return mover
end}
local function avatar(autoRotate)
    local character = {}
    return character, {Parent = character, AssemblyAngularVelocity = Vector3.new(2, 15, 3)},
        {Parent = character, Health = 100, AutoRotate = autoRotate}
end
local character, root, humanoid = avatar(true)
local RunService = {Heartbeat = signal()}
local localPlayer = {CharacterRemoving = signal()}
local flag11 = false
local lib = {UnloadCallbacks = {}, Starting = true, Unloaded = false}
function lib:OnUnload(callback) table.insert(self.UnloadCallbacks, callback) end
local connections = {}
local tbl12 = {Char = function() return character, root, humanoid end}
function tbl12.SetRuntimeConnection(name, event, enabled, callback)
    if connections[name] then connections[name]:Disconnect(); connections[name] = nil end
    if enabled then connections[name] = event:Connect(callback) end
end
local options = {SpinS = {Value = 15}}
local spinInfo, spinKey
local Character = {}
function Character:AddToggle(id, info)
    check(id == "SpinT", "Unexpected spin toggle")
    spinInfo = info
    return {AddKeyPicker = function(_, key, definition)
        check(key == "CSKey", "Spin bind ID changed")
        spinKey = definition
    end}
end
