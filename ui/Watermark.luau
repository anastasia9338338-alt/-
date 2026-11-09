-- Draggable telemetry pill. Center only once; later updates never touch the
-- user's position, anchor or saved layout. No remotes, coins or session clock.
local HUD={};HUD.__index=HUD
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
function HUD.Format(value)
    return string.format("astral  ·  %s/%s players  ·  %s fps  ·  %s ms",value.Players,value.MaxPlayers or"?",value.FPS,value.Ping)
end
function HUD.Install(context)
    local self=setmetatable({Context=context,Connections={},Frames=0,FrameTime=0,Elapsed=1,FPS="—"},HUD)
    local label=context.Widget.Label
    self.OriginalText=label.Text;context.Widget.Centered=nil
    label.AnchorPoint=Vector2.new(.5,0);label.Position=UDim2.new(.5,0,0,12);label.TextWrapped=false
    label.AutomaticSize=Enum.AutomaticSize.None
    label.TextXAlignment=Enum.TextXAlignment.Center;label.TextSize=13;label.BackgroundTransparency=.14
    label.TextTruncate=Enum.TextTruncate.AtEnd;label.BorderSizePixel=0
    local round=label:FindFirstChildOfClass("UICorner")or Instance.new("UICorner")
    round.CornerRadius=UDim.new(1,0);round.Parent=label
    self.Connections[#self.Connections+1]=context.RunService.RenderStepped:Connect(function(dt)
        if not finite(dt)or dt<=0 or dt>.5 then return end
        self.Frames+=1;self.FrameTime+=dt
        if self.FrameTime>=.5 then self.FPS=tostring(math.floor(self.Frames/self.FrameTime+.5));self.Frames=0;self.FrameTime=0 end
    end)
    self.Connections[#self.Connections+1]=context.RunService.Heartbeat:Connect(function(dt)
        if not finite(dt)or dt<=0 then return end
        self.Elapsed+=dt;if self.Elapsed<1 then return end;self.Elapsed=0;self:Update()
    end)
    self:Update();return self
end
function HUD:Update()
    if self.Closed then return end
    local ctx=self.Context;local label=ctx.Widget.Label
    if not label.Parent then self:Dispose();return end
    local ping="—";local ok,value=pcall(function()return ctx.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()end)
    if ok and finite(value)and value>=0 then ping=tostring(math.floor(value+.5))end
    local max=ctx.Players.MaxPlayers
    self.Values={Players=#ctx.Players:GetPlayers(),MaxPlayers=finite(max)and math.floor(max)or nil,FPS=self.FPS,Ping=ping}
    local content=HUD.Format(self.Values);ctx.Widget:SetText(content)
    local camera=ctx.Workspace.CurrentCamera;local viewport=camera and camera.ViewportSize.X or 1024
    local font=label.Font
    if typeof(font)~="EnumItem"or font==Enum.Font.Unknown then font=Enum.Font.Gotham end
    local bounds=game:GetService("TextService"):GetTextSize(content,13,font,Vector2.new(10000,40))
    local padding=label:FindFirstChildOfClass("UIPadding")
    local inset=padding and(padding.PaddingLeft.Offset+padding.PaddingRight.Offset)or 28
    local available=math.max(1,viewport-24)
    local size=UDim2.fromOffset(math.min(math.max(bounds.X+inset,240),available),32)
    if label.Size~=size then label.Size=size end
end
function HUD:Dispose()
    if self.Closed then return end;self.Closed=true
    for _,connection in ipairs(self.Connections)do connection:Disconnect()end
    if self.Context.Widget.Label.Parent then self.Context.Widget:SetText(self.OriginalText)end
end
return HUD
