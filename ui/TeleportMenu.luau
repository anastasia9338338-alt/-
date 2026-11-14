local requireModule=...
local images=requireModule("AssetCatalog").Locations
local photos=requireModule("ProvidedPhotos")
local Menu={};Menu.__index=Menu
function Menu.Install(context)
    local self=setmetatable({Context=context,Connections={},Entries={},Rows={},Visible=false,Closed=false,Loop=false,Respawn=false,Elapsed=0},Menu)
    self:Refresh()
    if not context.Headless then self:BuildView()end
    self.Connections[#self.Connections+1]=context.Player.CharacterAdded:Connect(function(character)
        if not self.Respawn or self.Closed then return end
        local root=character:WaitForChild("HumanoidRootPart",.5)or character:FindFirstChild("realHrp")
        if root and not self.Closed and self.Respawn and context.Player.Character==character then self:TeleportSelected(root)end
    end)
    context.Library:OnUnload(function()self:Dispose()end)
    return self
end
function Menu:Refresh()
    local entries,seen={},{ }
    for _,location in ipairs(self.Context.Locations())do
        if typeof(location)=="Instance"and location.Parent and not seen[location]then
            seen[location]=true
            entries[#entries+1]={Location=location,Name=location==self.Context.VoidPlatform and "Void Platform"or location.Name,
                Image=photos.Get(location.Name)or images[location.Name]}
        end
    end
    local platform=self.Context.VoidPlatform
    if platform and platform.Parent and not seen[platform]then entries[#entries+1]={Location=platform,Name="Void Platform"}end
    table.sort(entries,function(a,b)if a.Name=="Void Platform"then return false elseif b.Name=="Void Platform"then return true end;return a.Name:lower()<b.Name:lower()end)
    self.Entries=entries
    local selected=false;for _,entry in ipairs(entries)do if entry.Location==self.Selected then selected=true;break end end
    if not selected then self.Selected=entries[1]and entries[1].Location or nil end
    if self.Context.OnSelected then self.Context.OnSelected(self.Selected)end
end
function Menu:Select(location)
    if self.Closed then return false end
    for _,entry in ipairs(self.Entries)do if entry.Location==location then
        self.Selected=location;if self.Context.OnSelected then self.Context.OnSelected(location)end;return true
    end end
    return false
end
function Menu:TeleportSelected(root)
    if self.Closed or not self.Selected or not self.Selected.Parent then return false end
    if not root then local _,part=self.Context.Character();root=part end
    if not root or not root.Parent then return false end
    local target=self.Selected
    local frame=target:IsA("BasePart")and target.CFrame or target:IsA("Model")and target:GetPivot()
    if not frame then return false end
    self.Context.Teleport(root,frame+Vector3.new(0,10,0));return true
end
function Menu:SetLoop(value)
    self.Loop=value==true and not self.Closed
    if self.LoopConnection then self.LoopConnection:Disconnect();self.LoopConnection=nil end
    self.Elapsed=0
    if self.Loop then self.LoopConnection=self.Context.RunService.Heartbeat:Connect(function(delta)
        self.Elapsed+=delta;if self.Elapsed<.1 then return end;self.Elapsed=0;self:TeleportSelected()
    end)end
end
function Menu:SetRespawn(value)self.Respawn=value==true and not self.Closed end
function Menu:SetVisible(value)
    value=value==true and not self.Closed
    if self.Visible==value then return end
    self.Visible=value
    if value then self:Refresh();if self.Frame then self:BuildRows()end end
    if self.Frame then self.Frame.Visible=value end
    if self.Context.OnVisible then self.Context.OnVisible(value)end
end
local function new(class,parent,properties)
    local object=Instance.new(class)
    for key,value in pairs(properties)do object[key]=value end
    object.Parent=parent;return object
end
function Menu:Preview(parent,entry)
    local source=entry.Location==self.Context.VoidPlatform and entry.Location or nil
    if not source then
        for _,container in ipairs(self.Context.Workspace:GetChildren())do
            if container.Name~="Waypoints"then
                local candidate=container.Name==entry.Name and container or container:FindFirstChild(entry.Name,true)
                if candidate and (candidate:IsA("Model")or candidate:IsA("BasePart"))then source=candidate;break end
            end
        end
    end
    if not source then return false end
    local viewport=new("ViewportFrame",parent,{Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(68,54),BackgroundTransparency=1,
        Ambient=Color3.fromRGB(190,190,190),LightColor=Color3.fromRGB(255,255,255)})
    local world=new("WorldModel",viewport,{})
    local model=new("Model",world,{Name="StaticPreview"})
    local parts=source:IsA("BasePart")and {source}or source:GetDescendants();local count=0
    for _,part in ipairs(parts)do
        if part:IsA("BasePart")and count<96 then
            local ok,copy=pcall(function()return part:Clone()end)
            if ok and copy then
                for _,child in ipairs(copy:GetDescendants())do
                    if child:IsA("LuaSourceContainer")or child:IsA("Constraint")or child:IsA("JointInstance")or child:IsA("RemoteEvent")
                        or child:IsA("RemoteFunction")or child:IsA("Sound")or child:IsA("ParticleEmitter")then child:Destroy()end
                end
                copy.Anchored=true;copy.CanCollide=false;copy.CanTouch=false;copy.Parent=model;count+=1
            end
        end
    end
    if count==0 then viewport:Destroy();return false end
    local frame,size=model:GetBoundingBox();local distance=math.max(size.X,size.Y,size.Z,2)*1.7
    local camera=new("Camera",viewport,{FieldOfView=40,CFrame=CFrame.lookAt(frame.Position+Vector3.new(distance,distance*.7,distance),frame.Position)})
    viewport.CurrentCamera=camera;return true
end
function Menu:BuildRows()
    for _,connection in ipairs(self.RowConnections or {})do connection:Disconnect()end
    self.RowConnections={};for _,row in ipairs(self.Rows)do row:Destroy()end;self.Rows={}
    local scheme=self.Context.Library.Scheme
    for index,entry in ipairs(self.Entries)do
        local row=new("TextButton",self.List,{Name=entry.Name,LayoutOrder=index,Size=UDim2.new(1,-6,0,62),Text="",
            AutoButtonColor=true,BackgroundColor3=scheme.MainColor,BackgroundTransparency=scheme.RowTransparency,BorderSizePixel=0})
        new("UICorner",row,{CornerRadius=UDim.new(0,8)});new("UIStroke",row,{Color=scheme.OutlineColor,Transparency=.25})
        if entry.Image then
            new("ImageLabel",row,{Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(68,54),BackgroundTransparency=1,Image=entry.Image,ScaleType=Enum.ScaleType.Fit})
        elseif not self:Preview(row,entry)then
            new("TextLabel",row,{Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(68,54),BackgroundTransparency=1,
                Text="No preview",TextSize=10,TextColor3=scheme.FontColor,FontFace=Font.fromEnum(Enum.Font.BuilderSansBold)})
        end
        new("TextLabel",row,{Position=UDim2.fromOffset(80,4),Size=UDim2.new(1,-88,1,-8),BackgroundTransparency=1,Text=entry.Name,
            TextColor3=scheme.FontColor,TextSize=13,FontFace=Font.fromEnum(Enum.Font.BuilderSansBold),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
        self.RowConnections[#self.RowConnections+1]=row.MouseButton1Click:Connect(function()
            if self:Select(entry.Location)then self:TeleportSelected()end
        end)
        self.Rows[#self.Rows+1]=row
    end
    if self.Frame and self.Context.Library.StyleFloatingPanel then
        self.Context.Library:StyleFloatingPanel(self.Frame)
        local artwork=self.Context.Library.AppearanceController
        if artwork then artwork:ApplySurfaces()end
    end
    self:Filter(self.Search.Text)
end
function Menu:Filter(text)
    text=tostring(text or ""):lower()
    for _,row in ipairs(self.Rows)do row.Visible=row.Name:lower():find(text,1,true)~=nil end
end
function Menu:BuildView()
    local library=self.Context.Library;local scheme=library.Scheme
    local viewport=self.Context.Workspace.CurrentCamera.ViewportSize
    local width=math.max(180,math.min(320,viewport.X-24));local height=math.max(180,math.min(440,viewport.Y-24))
    self.Frame=new("Frame",library.ScreenGui,{Name="AstralTeleportMenu",Size=UDim2.fromOffset(width,height),Position=UDim2.fromOffset(20,110),
        BackgroundColor3=scheme.BackgroundColor,BorderSizePixel=0,Visible=false,ZIndex=20})
    new("UICorner",self.Frame,{CornerRadius=UDim.new(0,library.CornerRadius)});new("UIStroke",self.Frame,{Color=scheme.OutlineColor})
    local header=new("TextLabel",self.Frame,{Size=UDim2.new(1,-36,0,34),Position=UDim2.fromOffset(10,0),Text="Teleports",TextColor3=scheme.FontColor,
        TextSize=14,FontFace=Font.fromEnum(Enum.Font.BuilderSansBold),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left})
    local close=new("TextButton",self.Frame,{Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-32,0,2),Text="×",TextColor3=scheme.FontColor,
        TextSize=20,FontFace=Font.fromEnum(Enum.Font.BuilderSansBold),BackgroundTransparency=1})
    self.Search=new("TextBox",self.Frame,{Position=UDim2.fromOffset(8,38),Size=UDim2.new(1,-16,0,26),Text="",PlaceholderText="Search places...",
        TextColor3=scheme.FontColor,PlaceholderColor3=scheme.FontColor,BackgroundColor3=scheme.MainColor,BackgroundTransparency=scheme.RowTransparency,BorderSizePixel=0,TextSize=12,FontFace=Font.fromEnum(Enum.Font.BuilderSansBold),ClearTextOnFocus=false})
    self.List=new("ScrollingFrame",self.Frame,{Position=UDim2.fromOffset(8,72),Size=UDim2.new(1,-16,1,-80),BackgroundTransparency=1,BorderSizePixel=0,
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=scheme.OutlineColor})
    new("UIListLayout",self.List,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)})
    if library.StyleFloatingPanel then library:StyleFloatingPanel(self.Frame)end
    local artwork=library.AppearanceController
    if not (artwork and artwork.Config.Floating and artwork.Background.Visible)then self.Frame.BackgroundTransparency=scheme.GlassTransparency end
    new("UICorner",self.Search,{CornerRadius=UDim.new(0,8)})
    new("UIStroke",self.Search,{Color=scheme.OutlineColor,Transparency=.2})
    library:MakeDraggable(self.Frame,header,true)
    table.insert(library.DraggableElements,self.Frame)
    self.Connections[#self.Connections+1]=close.MouseButton1Click:Connect(function()self:SetVisible(false)end)
    self.Connections[#self.Connections+1]=self.Search:GetPropertyChangedSignal("Text"):Connect(function()self:Filter(self.Search.Text)end)
end
function Menu:Dispose()
    if self.Closed then return end
    self.Closed=true;self.Respawn=false;self:SetLoop(false)
    for _,connection in ipairs(self.Connections)do connection:Disconnect()end
    for _,connection in ipairs(self.RowConnections or {})do connection:Disconnect()end
    if self.Frame then
        local frames=self.Context.Library.DraggableElements or {}
        local index=table.find(frames,self.Frame);if index then table.remove(frames,index)end
        self.Frame:Destroy()
    end
end
return Menu
