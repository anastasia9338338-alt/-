-- Shared white-glass surfaces. Styling never calls gameplay callbacks.
local P={Radius=24,Transparency=.42,RowTransparency=.62}
function P.Theme()
    return{BackgroundColor=Color3.fromRGB(255,255,255),MainColor=Color3.fromRGB(244,247,251),
        AccentColor=Color3.fromRGB(77,91,113),OutlineColor=Color3.fromRGB(183,194,210),
        FontColor=Color3.fromRGB(23,28,36),FontFace="Gotham",BackgroundImage=""}
end
local function corner(frame,radius)
    local value=frame:FindFirstChildOfClass("UICorner")or Instance.new("UICorner")
    value.CornerRadius=UDim.new(0,radius);value.Parent=frame
end
local paths={
    house={{{2,8},{9,2},{16,8}},{{4,7},{4,16},{14,16},{14,7}},{{7,16},{7,11},{11,11},{11,16}}},
    ["user-round"]={{{3,16},{4,12},{7,10},{11,10},{14,12},{15,16}}},
    hand={{{3,16},{2,10},{3,8},{5,11},{5,4},{7,3},{8,9},{8,2},{10,2},{11,9},{12,4},{14,4},{14,11},{16,8},{17,10},{14,16},{3,16}}},
    shield={{{9,2},{15,4},{14,11},{9,16},{4,11},{3,4},{9,2}}},
    ["locate-fixed"]={{{9,0},{9,4}},{{9,14},{9,18}},{{0,9},{4,9}},{{14,9},{18,9}}},
    ["refresh-cw"]={{{4,4},{7,2},{12,3},{15,6},{16,10},{14,14},{10,16},{5,15},{2,11}},{{1,5},{4,4},{5,7}}},
    eye={{{1,9},{5,4},{9,3},{13,4},{17,9},{13,14},{9,15},{5,14},{1,9}}},
    crosshair={{{9,0},{9,5}},{{9,13},{9,18}},{{0,9},{5,9}},{{13,9},{18,9}}},
    sparkles={{{9,1},{11,7},{17,9},{11,11},{9,17},{7,11},{1,9},{7,7},{9,1}}},
    settings={{{6,2},{12,2},{13,5},{16,6},{16,12},{13,13},{12,16},{6,16},{5,13},{2,12},{2,6},{5,5},{6,2}}},
}
function P.Icon(image,name,color)
    name=name=="astral-fun"and"sparkles"or name
    local drawing=image:FindFirstChild("AstralSectionIcon")
    if not drawing then
        drawing=Instance.new("Frame");drawing.Name="AstralSectionIcon";drawing.BackgroundTransparency=1
        drawing.Size=UDim2.fromScale(1,1);drawing.Parent=image
        local function line(a,b)
            local dx,dy=b[1]-a[1],b[2]-a[2]
            local f=Instance.new("Frame");f.BorderSizePixel=0;f.AnchorPoint=Vector2.new(.5,.5)
            f.Position=UDim2.fromScale((a[1]+b[1])/36,(a[2]+b[2])/36)
            f.Size=UDim2.new(math.sqrt(dx*dx+dy*dy)/18,0,0,1.5);f.Rotation=math.deg(math.atan2(dy,dx));f.Parent=drawing
        end
        for _,path in ipairs(paths[name]or paths.sparkles)do for i=2,#path do line(path[i-1],path[i])end end
        local function ring(x,y,r)
            local f=Instance.new("Frame");f.BackgroundTransparency=1;f.Size=UDim2.fromScale(r/9,r/9);f.Position=UDim2.fromScale((x-r)/18,(y-r)/18);f.Parent=drawing;corner(f,99)
            local stroke=Instance.new("UIStroke");stroke.Thickness=1.5;stroke.Parent=f
        end
        if name=="user-round"then ring(9,5,3)
        elseif name=="eye"then ring(9,9,3)
        elseif name=="settings"then ring(9,9,3)
        elseif name=="locate-fixed"or name=="crosshair"then ring(9,9,5)end
    end
    image.ImageTransparency=1
    for _,node in ipairs(drawing:GetDescendants())do
        if node:IsA("Frame")then node.BackgroundColor3=color elseif node:IsA("UIStroke")then node.Color=color end
    end
end
function P.NativeElement(object,scheme)
    if object.Name=="Noise"then object.ImageTransparency=.96 end
    if object.Name=="Vingette"then object.ImageTransparency=1 end
    if object.Name=="ColorpickerItemHolder"or object.Name=="DropdownItemHolder"or object.Name=="ItemHolder"then
        object.BackgroundColor3=(scheme or P.Theme()).BackgroundColor;object.BackgroundTransparency=P.Transparency;corner(object,P.Radius)
    end
end
function P.Control(control)
    local holder,label=control.Holder,control.TextLabel
    if not holder then return end
    local reserved=control.Type=="Button"and 34 or 112
    local field=holder:FindFirstChild(control.Type=="Dropdown"and"SelectedItemBox"or"Value")
    if field and(control.Type=="Dropdown"or control.Type=="Input"or control.Type=="Slider")then
        local limit=math.max(40,math.min(160,holder.AbsoluteSize.X*.45))
        local width=math.min(limit,math.max(40,field.Size.X.Offset))
        local size=UDim2.new(0,width,field.Size.Y.Scale,field.Size.Y.Offset)
        if field.Size~=size then field.Size=size end
        field.AnchorPoint=Vector2.new(1,field.AnchorPoint.Y)
        field.Position=UDim2.new(1,-10,field.Position.Y.Scale,field.Position.Y.Offset)
        reserved=width+30
        local valueText=field:FindFirstChild("NameText")
        if valueText then valueText.Size=UDim2.new(1,-8,1,0);valueText.TextTruncate=Enum.TextTruncate.AtEnd;valueText.TextWrapped=false end
    end
    if label then
        if control.Library then label.FontFace=control.Library.Scheme.Font end;label.TextSize=14
        label.TextWrapped=control.Type=="Label"
        if control.Type~="Label"then
            label.TextTruncate=Enum.TextTruncate.AtEnd
            local left=10
            local size=UDim2.new(1,-reserved,0,26)
            if label.Size~=size then label.Size=size end
            label.Position=UDim2.fromOffset(left,0)
        end
    end
    if control.Type=="Slider"then
        holder.Size=UDim2.new(1,0,0,40)
        local bar=holder:FindFirstChild("SliderBar")
        if bar then bar.Position=UDim2.new(0,10,0,31);bar.Size=UDim2.new(1,-20,0,8)end
    end
end
function P.Section(group)
    local frame=group.Frame
    if frame then
        local size=UDim2.new(1,0,frame.Size.Y.Scale,frame.Size.Y.Offset)
        if frame.Size~=size then frame.Size=size end
        frame.BackgroundTransparency=1
    end
    local list=group.Container and group.Container:FindFirstChildOfClass("UIListLayout")
    if list then list.Padding=UDim.new(0,0)end
end
function P.Tab(tab)
    local raw=tab.Raw
    if raw.Button then
        local icon=raw.Button:FindFirstChild("Icon")
        local title=raw.Button:FindFirstChild("NameText")
        if icon then icon.Position=UDim2.new(0,18,.5,0);icon.Size=UDim2.fromOffset(18,18);P.Icon(icon,tab.Icon,tab.Library.Scheme.FontColor)end
        if title then
            title.Position=UDim2.fromOffset(34,0);title.Size=UDim2.new(1,-40,1,0);title.TextXAlignment=Enum.TextXAlignment.Left
            title.FontFace=tab.Library.Scheme.Font;title.TextSize=14;title.TextWrapped=false;title.TextTruncate=Enum.TextTruncate.AtEnd
        end
    end
    local frame=raw.Frame
    if not frame then return end
    frame.Size=UDim2.fromScale(1,1)
    for _,side in ipairs({"Left","Right"})do
        local clip=frame:FindFirstChild("FakeDescendantClipperFrame"..side)
        if clip then
            clip.Size=UDim2.new(.5,0,1,0);clip.Position=UDim2.new(side=="Left"and 0 or .5,0,0,0)
            local holder=clip:FindFirstChild(side.."HolderFrame")
            if holder then
                holder.Position=UDim2.new();holder.Size=UDim2.fromScale(1,1)
                local list=holder:FindFirstChildOfClass("UIListLayout");if list then list.Padding=UDim.new(0,0)end
            end
        end
    end
end
function P.Window(window,scheme)
    local frame=window.MainFrame
    if not frame then return end
    frame.BackgroundColor3=scheme.BackgroundColor;frame.BackgroundTransparency=P.Transparency;frame.BorderSizePixel=0;corner(frame,P.Radius)
    local top=frame:FindFirstChild("TopBar")
    if top then top.Visible=false;top.Size=UDim2.new()end
    local holder=frame:FindFirstChild("Holder")
    if holder then
        holder.AnchorPoint=Vector2.zero;holder.Position=UDim2.fromOffset(0,38);holder.Size=UDim2.new(1,0,1,-38)
        holder.BackgroundTransparency=1
        for _,child in ipairs(holder:GetChildren())do
            if child.Name=="Noise"or child.Name=="Vingette"or child.Name=="BackgroundImage"or child:IsA("UIStroke")then
                if child:IsA("UIStroke")then child.Transparency=1 else child.Visible=false end
            end
        end
    end
    local tabs=frame:FindFirstChild("TabButtonsHolder")
    if tabs then
        tabs.Position=UDim2.new();tabs.Size=UDim2.new(1,0,0,38);tabs.BackgroundTransparency=1
        local list=tabs:FindFirstChild("ButtonsListFrame")
        if list then
            list.Position=UDim2.fromOffset(6,3);list.Size=UDim2.new(1,-12,1,-6)
            local layout=list:FindFirstChildOfClass("UIListLayout");if layout then layout.Padding=UDim.new(0,0)end
        end
    end
    for _,tab in pairs(window.Tabs)do P.Tab(tab)end
end
function P.Floating(panel,scheme)
    panel.BackgroundColor3=scheme.BackgroundColor;panel.BackgroundTransparency=P.Transparency;panel.BorderSizePixel=0;corner(panel,P.Radius)
    local border=panel:FindFirstChildOfClass("UIStroke")or Instance.new("UIStroke")
    border.Color=scheme.OutlineColor;border.Transparency=.55;border.Thickness=1;border.Parent=panel
end
function P.FloatingChild(child,scheme,panel)
    if child:IsA("TextLabel")or child:IsA("TextButton")or child:IsA("TextBox")then
        child.TextColor3=scheme.FontColor;child.FontFace=scheme.Font
        if child:IsA("TextBox")then child.PlaceholderColor3=scheme.AccentColor end
    end
    if(child:IsA("Frame")or child:IsA("TextButton")or child:IsA("TextBox"))and child.BackgroundTransparency<1 then
        child.BackgroundColor3=scheme.MainColor;child.BackgroundTransparency=P.RowTransparency;child.BorderSizePixel=0;corner(child,14)
    end
    if child:IsA("UICorner")then child.CornerRadius=UDim.new(0,child.Parent==panel and P.Radius or 14)end
end
return P
