--!strict
-- Isolated transport RTT from Roblox. Data Ping includes replication processing
-- and must not be labelled internet latency or used to slow the kick controller.
local Telemetry = {}
Telemetry.__index = Telemetry

export type Context = {Player: Player, Clock: () -> number}
type State = {Context: Context, NextAt: number, Milliseconds: number?}

function Telemetry.Install(context: Context)
	return setmetatable({Context = context, NextAt = 0, Milliseconds = nil :: number?}, Telemetry)
end

function Telemetry.ReadMs(self: State): number?
	local now = self.Context.Clock()
	if now < self.NextAt then return self.Milliseconds end
	self.NextAt = now + 0.5
	local ok, seconds = pcall(function() return self.Context.Player:GetNetworkPing() end)
	if ok and type(seconds) == "number" and seconds == seconds and seconds >= 0 and seconds < math.huge then
		self.Milliseconds = seconds * 1000
	else
		self.Milliseconds = nil
	end
	return self.Milliseconds
end

function Telemetry.Seconds(self: State): number?
	local value = Telemetry.ReadMs(self)
	return if value then value / 1000 else nil
end

return Telemetry
