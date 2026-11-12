-- One render listener for active GUI transitions. No idle loop or network calls.
local Motion={};Motion.__index=Motion
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
local function mix(a,b,t)return UDim2.new(a.X.Scale+(b.X.Scale-a.X.Scale)*t,a.X.Offset+(b.X.Offset-a.X.Offset)*t,a.Y.Scale+(b.Y.Scale-a.Y.Scale)*t,a.Y.Offset+(b.Y.Offset-a.Y.Offset)*t)end
local function distance(a,b)
    return math.abs(a.X.Scale-b.X.Scale)*2000+math.abs(a.Y.Scale-b.Y.Scale)*2000+math.abs(a.X.Offset-b.X.Offset)+math.abs(a.Y.Offset-b.Y.Offset)
end
function Motion.new(signal)
    return setmetatable({Signal=signal,Moves={},Fades={}},Motion)
end
function Motion:Wake()
    if self.Closed or self.Connection then return end
    self.Connection=self.Signal:Connect(function(dt)self:Step(dt)end)
end
function Motion:Move(ui,target,allowed)
    if self.Closed or not ui.Parent then return end
    local item=self.Moves[ui]
    if not item then item={Last=ui.Position};self.Moves[ui]=item end
    item.Target=target;item.Allowed=allowed;self:Wake()
end
function Motion:StopMove(ui)self.Moves[ui]=nil;self:Sleep()end
function Motion:Show(ui,visible,animate)
    if self.Closed then return end
    if not animate then self.Fades[ui]=nil;ui.GroupTransparency=visible and 0 or 1;ui.Visible=visible;self:Sleep();return end
    ui.Visible=true;self.Fades[ui]={Target=visible and 0 or 1,Visible=visible};self:Wake()
end
function Motion:Sleep()
    if not next(self.Moves)and not next(self.Fades)and self.Connection then
        self.Connection:Disconnect();self.Connection=nil
    end
end
function Motion:Step(dt)
    if not finite(dt)or dt<=0 then return end
    local drag=1-math.exp(-30*dt);local fade=1-math.exp(-26*dt)
    for ui,item in self.Moves do
        if not ui.Parent or item.Allowed and not item.Allowed()or ui.Position~=item.Last then
            self.Moves[ui]=nil
        else
            local position=mix(ui.Position,item.Target,drag)
            if distance(position,item.Target)<.15 then position=item.Target;self.Moves[ui]=nil end
            ui.Position=position;item.Last=position
        end
    end
    for ui,item in self.Fades do
        if not ui.Parent then self.Fades[ui]=nil
        else
            local alpha=ui.GroupTransparency+(item.Target-ui.GroupTransparency)*fade
            if math.abs(alpha-item.Target)<.004 then alpha=item.Target;ui.Visible=item.Visible;self.Fades[ui]=nil end
            ui.GroupTransparency=alpha
        end
    end
    self:Sleep()
end
function Motion:Dispose()
    if self.Closed then return end;self.Closed=true
    table.clear(self.Moves);table.clear(self.Fades);self:Sleep()
end
return Motion
