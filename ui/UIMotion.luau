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
-- Normal Frames render without the CanvasGroup texture/compositing path.
-- Capture only the displayed tab once; one observer fades its drawn properties.
local function snapshot(root)
    local entries={}
    local nodes=root:GetDescendants();table.insert(nodes,root)
    for _,node in nodes do
        local drawn=true;local ancestor=node
        while ancestor and ancestor~=root do
            if ancestor:IsA("GuiObject")and not ancestor.Visible then drawn=false;break end
            ancestor=ancestor.Parent
        end
        if drawn then
            local properties={}
            if node:IsA("GuiObject")then properties[#properties+1]="BackgroundTransparency"end
            if node:IsA("TextLabel")or node:IsA("TextButton")or node:IsA("TextBox")then properties[#properties+1]="TextTransparency"end
            if node:IsA("ImageLabel")or node:IsA("ImageButton")then properties[#properties+1]="ImageTransparency"end
            if node:IsA("UIStroke")then properties[#properties+1]="Transparency"end
            for _,property in properties do
                local value=node[property]
                if finite(value)and value<1 then entries[#entries+1]={Node=node,Property=property,Value=value}end
            end
        end
    end
    return entries
end
local function opacity(entries,alpha)
    for _,entry in entries do
        if entry.Node.Parent then entry.Node[entry.Property]=entry.Value+(1-entry.Value)*alpha end
    end
end
function Motion:Show(ui,visible,animate)
    if self.Closed then return end
    local previous=self.Fades[ui]
    if not animate or not visible and not ui.Visible then
        self.Fades[ui]=nil
        if previous then opacity(previous.Entries,0)end
        ui.Visible=visible;self:Sleep();return
    end
    local item=previous or{Entries=snapshot(ui),Alpha=ui.Visible and 0 or 1}
    item.Target=visible and 0 or 1;item.Visible=visible
    ui.Visible=true;opacity(item.Entries,item.Alpha)
    self.Fades[ui]=item;self:Wake()
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
            item.Alpha=item.Alpha+(item.Target-item.Alpha)*fade
            if math.abs(item.Alpha-item.Target)<.004 then
                ui.Visible=item.Visible
                opacity(item.Entries,0)
                self.Fades[ui]=nil
            else opacity(item.Entries,item.Alpha)end
        end
    end
    self:Sleep()
end
function Motion:Dispose()
    if self.Closed then return end;self.Closed=true
    table.clear(self.Moves);table.clear(self.Fades);self:Sleep()
end
return Motion
