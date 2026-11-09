-- Astral's existing control API backed by actual TheWorstUIV2 widgets.
-- Gameplay callbacks, flag IDs and config formats remain owned by Astral.
local requireModule=...
local Native=requireModule("TheWorstUIV2")
local Icons=requireModule("Icons")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TextService=game:GetService("TextService")
local Players=game:GetService("Players")
local originalMouseBehavior,originalMouseIcon=UIS.MouseBehavior,UIS.MouseIconEnabled
local modifierNames={LAlt="LeftAlt",RAlt="RightAlt",LCtrl="LeftControl",RCtrl="RightControl",LShift="LeftShift",RShift="RightShift",LMeta="LeftMeta",RMeta="RightMeta"}
local Library={Options={},Toggles={},Labels={},Tabs={},Registry={},DraggableElements={},DependencyBoxes={},
    Connections={},UnloadSignals={},Controls={},KeyPickers={},CornerRadius=30,DPIScale=1,Toggled=true,Unloaded=false,
    IsMobile=UIS.TouchEnabled and not UIS.KeyboardEnabled,ScreenGui=Native.ScreenGui,
    Scheme={BackgroundColor=Color3.fromRGB(20,20,20),MainColor=Color3.fromRGB(28,28,28),
        AccentColor=Color3.fromRGB(240,240,240),OutlineColor=Color3.fromRGB(52,52,52),FontColor=Color3.fromRGB(240,240,240),
        RedColor=Color3.fromRGB(240,75,75),DestructiveColor=Color3.fromRGB(240,75,75),DarkColor=Color3.fromRGB(16,16,16),
        WhiteColor=Color3.new(1,1,1),Font=Font.fromEnum(Enum.Font.Code),BackgroundImage=""}}
local Control,Container,Tab,Window={},{},{},{}
Control.__index=Control;Container.__index=Container;Tab.__index=Tab;Window.__index=Window
local function plain(value)return(tostring(value or ""):gsub("<[^>]*>",""))end
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
local function copy(t)local z={};for k,v in pairs(t or{})do z[k]=v end;return z end
local function new(class,parent,props)
    local object=Instance.new(class)
    for k,v in pairs(props or{})do object[k]=v end
    object.Parent=parent;return object
end
local function text(parent,value)
    return new("TextLabel",parent,{Name="NameText",Text=plain(value),Font=Enum.Font.Code,TextSize=16,
        TextColor3=Library.Scheme.FontColor,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true,Size=UDim2.new(1,-20,1,0),Position=UDim2.fromOffset(10,0),BorderSizePixel=0})
end
local function corner(object,radius)new("UICorner",object,{CornerRadius=UDim.new(0,radius or Library.CornerRadius)})end
local function frameLabel(raw)
    local f=raw and raw.Frame
    return f and(f:FindFirstChild("NameText")or f:FindFirstChild("TextName"))
end
function Library:GiveSignal(connection)
    if self.Unloaded then connection:Disconnect()else self.Connections[#self.Connections+1]=connection end
    return connection
end
function Library:OnUnload(fn)self.UnloadSignals[#self.UnloadSignals+1]=fn end
function Library:SafeCallback(fn,...)
    if type(fn)~="function"then return end
    local ok,result=pcall(fn,...)
    if not ok then warn("Astral callback: "..tostring(result))end
    if ok then return result end
end
function Library:AddToRegistry(object,props)self.Registry[object]=props;return object end
function Library:RemoveFromRegistry(object)self.Registry[object]=nil end
function Library:GetIcon(name)
    if not name then return end
    return Icons.GetAsset(name)
end
function Library:GetCustomIcon(name)
    if type(name)=="table"then return name end
    if type(name)=="number"then return{Url="rbxassetid://"..name,ImageRectOffset=Vector2.zero,ImageRectSize=Vector2.zero}end
    if type(name)=="string"and name:find("://",1,true)then return{Url=name,ImageRectOffset=Vector2.zero,ImageRectSize=Vector2.zero}end
    return self:GetIcon(name=="astral-fun"and"sparkles"or name)
end
function Library:ApplyLucideIcon(object,icon,rotation)
    icon=type(icon)=="table"and icon or self:GetCustomIcon(icon)
    if icon then object.Image=icon.Url or"";object.ImageRectOffset=icon.ImageRectOffset or Vector2.zero;object.ImageRectSize=icon.ImageRectSize or Vector2.zero end
    if rotation then object.Rotation=rotation end
end
function Library:SetIconModule()end -- Icons are already bundled.
function Library:UpdateColorsUsingRegistry()
    if self.Taskbar then
        self.Taskbar:SetWindowsColor(self.Scheme.BackgroundColor,.16,"Main")
        self.Taskbar:SetWindowsColor(self.Scheme.AccentColor,.25,"Second")
        self.Taskbar:SetWindowsColor(self.Scheme.MainColor,.2,"Third")
        self.Taskbar:SetWindowsColor(self.Scheme.MainColor,.6,"Sections")
        self.Taskbar:SetFont({Color=self.Scheme.FontColor,Transparency=0,Type="Main"})
        self.Taskbar:SetFont({Color=self.Scheme.FontColor,Transparency=.35,Type="Little"})
    end
    for object,props in pairs(self.Registry)do
        if object.Parent then for key,value in pairs(props)do
            pcall(function()object[key]=type(value)=="function"and value()or self.Scheme[value]or value end)
        end else self.Registry[object]=nil end
    end
end
function Library:SetFont(font)
    local enum=typeof(font)=="EnumItem"and font or Enum.Font.Code
    self.Scheme.Font=Font.fromEnum(enum)
    if self.Taskbar then
        self.Taskbar:SetFont({Font=enum.Name,Type="Main"});self.Taskbar:SetFont({Font=enum.Name,Type="Little"})
    end
end
function Library:SetBackgroundImage(image)
    self.Scheme.BackgroundImage=tostring(image or"")
    if self.Taskbar then self.Taskbar:SetBackground({Image=self.Scheme.BackgroundImage,Transparency=.8})end
end
function Library:GetBetterColor(color,delta)
    return Color3.new(math.clamp(color.R+delta/255,0,1),math.clamp(color.G+delta/255,0,1),math.clamp(color.B+delta/255,0,1))
end
function Library:GetTextBounds(value,font,size,width)
    local v=TextService:GetTextSize(plain(value),size or 16,Enum.Font.Code,Vector2.new(width or 1000,10000))
    return v.X,v.Y
end
function Library:MouseIsOverFrame(frame,point)
    if not frame or not frame.Parent or not frame.Visible then return false end
    local p,s=frame.AbsolutePosition,frame.AbsoluteSize
    return point.X>=p.X and point.Y>=p.Y and point.X<=p.X+s.X and point.Y<=p.Y+s.Y
end
function Library:IsPointerOverUI(point)
    local candidates={self.Window and self.Window.MainFrame,self.KeybindFrame,self.Taskbar and self.Taskbar.Frame,
        self.Taskbar and self.Taskbar.StartFrame,self.Taskbar and self.Taskbar.NotificationsHubFrame}
    for _,frame in pairs(candidates)do if self:MouseIsOverFrame(frame,point)then return true end end
    for _,widget in ipairs(self.DraggableElements)do if self:MouseIsOverFrame(widget,point)then return true end end
    for _,node in ipairs(self.ScreenGui:GetChildren())do if node:IsA("GuiObject")and node.ZIndex>=1500 and self:MouseIsOverFrame(node,point)then return true end end
    return false
end
function Library:MakeDraggable(frame,handle)
    local active,start,position,tracked
    self:GiveSignal((handle or frame).InputBegan:Connect(function(input)
        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
        active=true;start=input.Position;position=frame.Position;tracked=input
    end))
    self:GiveSignal(UIS.InputChanged:Connect(function(input)
        if active and(input.UserInputType==Enum.UserInputType.MouseMovement or input==tracked)then
            local delta=input.Position-start;frame.Position=position+UDim2.fromOffset(delta.X,delta.Y)
        end
    end))
    self:GiveSignal(UIS.InputEnded:Connect(function(input)
        if input==tracked or input.UserInputType==Enum.UserInputType.MouseButton1 then active=false end
    end))
end
function Library:AddDraggableLabel(value)
    local label=new("TextLabel",self.ScreenGui,{Name="AstralHUD",Text=plain(value),BackgroundColor3=self.Scheme.BackgroundColor,
        BackgroundTransparency=.16,Font=Enum.Font.Code,TextSize=13,TextColor3=self.Scheme.FontColor,TextWrapped=true,
        Size=UDim2.fromOffset(360,32),Position=UDim2.fromOffset(20,20),ZIndex=300,BorderSizePixel=0})
    corner(label,12);self:MakeDraggable(label);table.insert(self.DraggableElements,label)
    local widget={Label=label}
    function widget:SetText(v)label.Text=plain(v)end
    function widget:SetVisible(v)label.Visible=v end
    function widget:SetSize(v)label.Size=v end
    function widget:Destroy()label:Destroy()end
    self:AddToRegistry(label,{BackgroundColor3="BackgroundColor",TextColor3="FontColor"})
    return widget
end
function Library:AddDraggableButton(info,fn)
    if type(info)=="string"then info={Text=info,Func=fn}end
    local button=new("TextButton",self.ScreenGui,{Name="AstralMobileButton",Text=plain(info.Text),Font=Enum.Font.Code,TextSize=14,
        TextColor3=self.Scheme.FontColor,BackgroundColor3=self.Scheme.MainColor,BackgroundTransparency=.2,
        Size=UDim2.fromOffset(130,38),Position=UDim2.fromOffset(20,160),ZIndex=300,BorderSizePixel=0})
    corner(button,16);self:MakeDraggable(button);table.insert(self.DraggableElements,button)
    local result={Button=button}
    self:GiveSignal(button.MouseButton1Click:Connect(function()self:SafeCallback(info.Func or info.Callback,result)end))
    function result:Destroy()button:Destroy()end
    function result:SetVisible(v)button.Visible=v end
    return result
end

local function enabled(control)return not control.Destroyed and not control.Disabled and not(control.ParentControl and(control.ParentControl.Destroyed or control.ParentControl.Disabled))end
function Control:_RawSet(value,transparency)
    if not self.Raw then return end
    self._Syncing=true
    local ok,err=pcall(function()self.Raw:Set(value,transparency)end)
    self._Syncing=false
    if not ok then error("Astral UI "..tostring(self.Id)..": "..tostring(err),0)end
end
function Control:RunChanged()
    if self.Initializing or self.Destroyed or not enabled(self)then return end
    Library:SafeCallback(self.Callback,self.Value,self.Transparency)
    Library:SafeCallback(self.Changed,self.Value,self.Transparency)
end
function Control:OnChanged(fn)self.Changed=fn;return self end
function Control:OnClick(fn)self.Clicked=fn;return self end
function Control:SetText(value)
    self.Text=plain(value)
    if self.Raw and self.Type=="Label"then self.Raw:Set(self.Text)
    elseif self.TextLabel then self.TextLabel.Text=self.Text end
    return self
end
Control.SetTitle=Control.SetText;Control.SetDescription=Control.SetText
function Control:SetVisible(value)self.Visible=value==true;self:_Visibility();return self end
function Control:_Visibility()
    local visible=self.Visible~=false
    local parent=self.ParentContainer
    while parent do visible=visible and parent.Visible~=false and not parent.Collapsed;parent=parent.ParentContainer end
    if self.Holder then self.Holder.Visible=visible end
end
function Control:SetDisabled(value)
    self.Disabled=value==true
    if self.Holder then
        if self.Disabled and not self.Blocker then
            self.Blocker=new("TextButton",self.Holder,{Name="DisabledCover",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=1000,Active=true})
        elseif self.Blocker then self.Blocker.Visible=self.Disabled end
    end
    if self.TextLabel then self.TextLabel.TextTransparency=self.Disabled and .6 or 0 end
    return self
end
function Control:SetValue(value,alpha)
    if self.Destroyed then return self end
    if self.Type=="Toggle"then
        self.Value=value==true;self:_RawSet(self.Value)
        for _,picker in ipairs(self.Addons)do if picker.SyncToggleState then picker.Toggled=self.Value;picker:Update()end end
        Library:UpdateDependencyBoxes();self:RunChanged()
    elseif self.Type=="Slider"then
        local n=tonumber(value);if not finite(n)then return self end
        n=math.clamp(n,self.Min,self.Max)
        n=math.clamp(math.round(n/self.Increment)*self.Increment,self.Min,self.Max)
        if n==self.Value then return self end
        self.Value=n;self:_RawSet(n);self:RunChanged()
    elseif self.Type=="Input"then
        value=tostring(value or"")
        if self.Info.Numeric and value~=""and not tonumber(value)then return self end
        if self.Info.AllowEmpty==false and value:match("^%s*$")then value=self.Info.EmptyReset or tostring(self.Default or"")end
        if self.Info.MaxLength then value=value:sub(1,self.Info.MaxLength)end
        if self.Info.VerifyValue and not self.Info.VerifyValue(value)then return self end
        self.Value=value;self:_RawSet(value);self:RunChanged()
    elseif self.Type=="Dropdown"then
        local selected={}
        if self.Multi then
            for k,v in pairs(type(value)=="table"and value or{})do
                local candidate=type(k)=="number"and v or(v and k or nil)
                if self.ValueToLabel[candidate]and not self.DisabledValues[candidate]then selected[candidate]=true end
            end
            if not self.AllowNull and not next(selected)and self.Values[1]then selected[self.Values[1]]=true end
            self.Value=selected
            local labels={};for _,v in ipairs(self.Values)do if selected[v]then labels[#labels+1]=self.ValueToLabel[v]end end
            self:_RawSet(labels)
        else
            if type(value)=="number"then value=self.Values[value]end
            if not self.ValueToLabel[value]or self.DisabledValues[value]then
                if self.AllowNull then value=nil else value=self.Values[1]end
            end
            self.Value=value;self:_RawSet(self.ValueToLabel[value]or"")
        end
        Library:UpdateDependencyBoxes();self:RunChanged()
    elseif self.Type=="ColorPicker"then
        if typeof(value)~="Color3"then
            if type(value)~="table"then return self end
            value=Color3.fromHSV(value[1],value[2],value[3])
        end
        self.Value=value;self.Transparency=self.Info.Transparency and math.clamp(tonumber(alpha)or self.Transparency or 0,0,1)or 0
        self:_RawSet(value,self.Transparency);self:RunChanged()
    elseif self.Type=="KeyPicker"then
        local key,mode,mods
        if type(value)=="table"then key,mode,mods=value[1],value[2],value[3]else key=value end
        if typeof(key)=="EnumItem"then key=key.Name end
        key=tostring(key or"None")
        self.Value=key==""and"None"or key;self.Mode=mode or self.Mode;self.Modifiers=copy(mods or{})
        self.Toggled=false;self._Held=false;self:_RawSet(self.Value);self:Update()
        local ok,enum=pcall(function()return self.Value:find("MouseButton",1,true)and Enum.UserInputType[self.Value]or Enum.KeyCode[self.Value]end)
        if not ok then enum=nil end
        Library:SafeCallback(self.Info.ChangedCallback,enum,self.Modifiers);Library:SafeCallback(self.Changed,enum,self.Modifiers)
    end
    return self
end
Control.SetValueRGB=Control.SetValue
function Control:SetMin(value)self.Min=value;if self.Raw and self.Raw.SetMin then self.Raw:SetMin(value)end;return self:SetValue(self.Value)end
function Control:SetMax(value)self.Max=value;if self.Raw and self.Raw.SetMax then self.Raw:SetMax(value)end;return self:SetValue(self.Value)end
function Control:SetValues(values)
    self.Values=copy(values);self.ValueToLabel={};self.LabelToValue={};local labels={}
    for _,value in ipairs(self.Values)do
        local label=plain(self.Info.FormatListValue and self.Info.FormatListValue(value)or value)
        if self.LabelToValue[label]then label=label.." ["..tostring(#labels+1).."]"end
        self.ValueToLabel[value]=label;self.LabelToValue[label]=value;labels[#labels+1]=label
    end
    local identical=self.DisplayLabels and #self.DisplayLabels==#labels
    if identical then for i,label in ipairs(labels)do if self.DisplayLabels[i]~=label then identical=false;break end end end
    if self.Raw and not identical then self._Syncing=true;self.Raw:Refresh(labels);self._Syncing=false end
    self.DisplayLabels=labels
    if self.ValueImages then self:SetValueImages(self.ValueImages)end
    if self.Value~=nil then self:SetValue(self.Value)end
    return self
end
function Control:AddValues(values)local all=copy(self.Values);for _,v in ipairs(values)do if not table.find(all,v)then all[#all+1]=v end end;return self:SetValues(all)end
function Control:SetDisabledValues(values)
    self.DisabledValues={};for k,v in pairs(values or{})do self.DisabledValues[type(k)=="number"and v or k]=type(k)=="number"or v==true end
    return self:SetValue(self.Value)
end
function Control:SetValueImages(images)
    self.ValueImages=images
    local itemHolder=self.Holder and self.Holder:FindFirstChild("ItemHolder")
    local holder=itemHolder and itemHolder:FindFirstChild("Holder")
    if not holder then return end
    for value,image in pairs(images or{})do
        local label=self.ValueToLabel and self.ValueToLabel[value]
        local row=label and holder:FindFirstChild("ButtonFrame_"..label)
        local icon=Library:GetCustomIcon(image)
        if row and icon then
            local picture=row:FindFirstChild("AstralOptionImage")or new("ImageLabel",row,{Name="AstralOptionImage",BackgroundTransparency=1,
                Size=UDim2.fromOffset(22,22),Position=UDim2.fromOffset(4,4),ZIndex=row.ZIndex+1,ScaleType=Enum.ScaleType.Fit})
            Library:ApplyLucideIcon(picture,icon)
            local line=row:FindFirstChild("FakeTextName")
            local title=line and line:FindFirstChild("TextName")
            if title then title.Position=UDim2.fromOffset(30,0);title.Size=UDim2.new(1,-34,1,0)end
        end
    end
end
function Control:GetState()
    if self.Mode=="Always"then return true end
    if self.Mode=="Hold"then return self._Held==true and not UIS:GetFocusedTextBox()end
    return self.Toggled==true
end
function Control:SetMenuVisibility(value)self.MenuVisible=value;self:Update()end
function Control:Update()
    local prefix=table.concat(self.Modifiers or{},"+")
    if prefix~=""then prefix..="+"end
    if self.MenuLabel then self.MenuLabel.Text=string.format("[%s] %s (%s)",prefix..self.Value,self.Text,self.Mode);self.MenuLabel.Visible=self.MenuVisible~=false end
end
function Control:DoClick()
    if not enabled(self)then return end
    if self.SyncToggleState and self.ParentControl and self.ParentControl.Type=="Toggle"then self.ParentControl:SetValue(self.Toggled)end
    Library:SafeCallback(self.Callback,self.Toggled);Library:SafeCallback(self.Clicked,self.Toggled)
    if self.ParentControl and self.ParentControl.Type=="Button"then self.ParentControl:Press()end
    if Library.ToggleKeybind==self then Library:Toggle()end
    if self.Mode=="Press"then self.Toggled=false end
    self:Update()
end
function Control:Press()if enabled(self)then Library:SafeCallback(self.Func or self.Callback)end end
function Control:SetHeight(value)self.Height=value;if self.Holder then self.Holder.Size=UDim2.new(1,0,0,value)end end
function Control:SetInstance(value)if self.Instance then self.Instance.Parent=nil end;self.Instance=value;value.Parent=self.Holder end
Control.SetObject=Control.SetInstance
function Control:Destroy()
    self.Destroyed=true;if self.Holder then self.Holder:Destroy()end
    if Library.Options[self.Id]==self then Library.Options[self.Id]=nil end
    if Library.Toggles[self.Id]==self then Library.Toggles[self.Id]=nil end
end
function Control:AddKeyPicker(id,info)return self.ParentContainer:_Control("KeyPicker",id,info,self)end
function Control:AddColorPicker(id,info)return self.ParentContainer:_Control("ColorPicker",id,info,self)end

function Container:_Control(kind,id,info,parentControl)
    info=info or{}
    local c=setmetatable({Type=kind,Id=id,Info=info,Text=plain(info.Text or info.Title or id),Default=info.Default,
        Value=info.Default,Visible=info.Visible~=false,Disabled=info.Disabled==true,Callback=info.Callback,
        ParentContainer=self,ParentControl=parentControl,Addons={},DisabledValues={},Initializing=true},Control)
    self.Elements[#self.Elements+1]=c;Library.Controls[#Library.Controls+1]=c
    if id then(kind=="Toggle"and Library.Toggles or Library.Options)[id]=c end
    if parentControl then parentControl.Addons[#parentControl.Addons+1]=c end
    local rawParent=self.Raw
    if parentControl and parentControl.Type=="Toggle"and parentControl.Raw and(kind=="ColorPicker"or kind=="KeyPicker")then rawParent=parentControl.Raw end
    local initializing=true
    local cfg={Name=c.Text,Flag=id,Default=info.Default}
    cfg.Callback=function(value,alpha)
        if initializing or c._Syncing or c.Destroyed or Library.Unloaded then return end
        if not enabled(c)then return c:_SyncCurrent()end
        if kind=="Dropdown"then
            if c.Multi then local selected={};for _,label in ipairs(type(value)=="table"and value or{})do local actual=c.LabelToValue[label];if actual then selected[actual]=true end end;value=selected
            else value=c.LabelToValue[value]end
        end
        return c:SetValue(value,alpha)
    end
    if kind=="Toggle"then
        c.Value=info.Default==true;cfg.Default=c.Value;c.Raw=rawParent:CreateToggle(cfg)
    elseif kind=="Slider"then
        c.Min=info.Min or 0;c.Max=info.Max or 100;c.Increment=10^-(info.Rounding or 0)
        c.Value=math.clamp(tonumber(info.Default)or c.Min,c.Min,c.Max)
        cfg.Min=c.Min;cfg.Max=c.Max;cfg.Default=c.Value;cfg.Increment=c.Increment;cfg.ValueName=info.Suffix or""
        cfg.InputEndedCallback=info.InputEndedCallback;c.Raw=rawParent:CreateSlider(cfg)
    elseif kind=="Input"then
        c.Value=tostring(info.Default or"");cfg.Default=c.Value;cfg.PlaceholderText=info.Placeholder or"Input"
        cfg.TextDisappear=info.ClearTextOnFocus==true;c.Raw=rawParent:CreateTextbox(cfg)
    elseif kind=="Dropdown"then
        c.Multi=info.Multi==true;c.AllowNull=info.AllowNull~=false;c.Values={};c.Value=nil
        c.SpecialType=info.SpecialType;c.ExcludeLocalPlayer=info.ExcludeLocalPlayer
        local values=info.Values or{}
        if info.SpecialType=="Player"then
            values=Players:GetPlayers()
            if info.ExcludeLocalPlayer then local i=table.find(values,Players.LocalPlayer);if i then table.remove(values,i)end end
            table.sort(values,function(a,b)return a.Name:lower()<b.Name:lower()end)
        end
        c:SetValues(values)
        cfg.Multi=c.Multi;cfg.Options={};for _,v in ipairs(c.Values)do cfg.Options[#cfg.Options+1]=c.ValueToLabel[v]end
        cfg.Default=c.Multi and{}or"";c.Raw=rawParent:CreateDropdown(cfg)
        c:SetValue(info.Default)
    elseif kind=="ColorPicker"then
        c.Value=info.Default or Color3.new(1,1,1);c.Transparency=type(info.Transparency)=="number"and info.Transparency or 0
        cfg.DefaultColor=c.Value;cfg.DefaultTransparency=c.Transparency;c.Raw=rawParent:CreateColorpicker(cfg)
    elseif kind=="KeyPicker"then
        c.Mode=info.Mode or"Toggle";c.SyncToggleState=info.SyncToggleState==true;c.Toggled=false;c.Value=info.Default or"None";c.Modifiers=copy(info.DefaultModifiers)
        if typeof(c.Value)=="EnumItem"then c.Value=c.Value.Name end
        cfg.Default=c.Value;cfg.Hold=false;cfg.Callback=function()end;c.Raw=rawParent:CreateBind(cfg)
        c.Raw.OnAssigned=function(key)if not c._Syncing then c:SetValue({key,c.Mode,c.Modifiers})end end
        Library.KeyPickers[#Library.KeyPickers+1]=c
        c.MenuLabel=text(Library.KeybindContainer,"");c.MenuLabel.Size=UDim2.new(1,-16,0,25);c.MenuLabel.Position=UDim2.new();c.MenuLabel.TextSize=13
        c.MenuVisible=not info.NoUI;c:Update()
        if c.Raw.Frame then Library:GiveSignal(c.Raw.Frame.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton2 then
                local modes={"Toggle","Hold","Press","Always"};c.Mode=modes[(table.find(modes,c.Mode)or 1)%#modes+1];c:Update()
            end
        end))end
    end
    c.Holder=c.Raw and c.Raw.Frame;c.TextLabel=frameLabel(c.Raw)
    if kind=="Dropdown"and info.ValueImages then c:SetValueImages(info.ValueImages)end
    if parentControl and parentControl.Type=="Label"and c.Holder then
        -- The native library has inline toggle/button binds, but labels use
        -- a standalone native row; keep one clear title rather than duplicates.
        if parentControl.Holder then parentControl.Visible=false;parentControl.Holder.Visible=false end
    end
    if info.Tooltip and c.Holder then Library:AddTooltip(info.Tooltip,info.DisabledTooltip,c.Holder)end
    initializing=false;c.Initializing=false;c:SetDisabled(c.Disabled);c:_Visibility()
    return c
end
function Control:_SyncCurrent()
    if self.Type=="Dropdown"then local cb=self.Callback;self.Callback=nil;self:SetValue(self.Value);self.Callback=cb
    else self:_RawSet(self.Value,self.Transparency)end
end
for _,kind in ipairs({"Toggle","Slider","Dropdown","Input","KeyPicker","ColorPicker"})do
    Container["Add"..kind]=function(self,id,info)return self:_Control(kind,id,info)end
end
Container.AddCheckbox=Container.AddToggle
function Container:AddLabel(value,wrap)
    local id=type(wrap)=="table"and value or nil
    local info=type(wrap)=="table"and wrap or(type(value)=="table"and value or{Text=value,DoesWrap=wrap})
    local raw=self.Raw:CreateLabel({Name=plain(info.Text or"")})
    local c=setmetatable({Type="Label",Text=plain(info.Text),Raw=raw,Holder=raw.Frame,TextLabel=frameLabel(raw),
        ParentContainer=self,Addons={},Visible=info.Visible~=false,Info=info},Control)
    if c.TextLabel then c.TextLabel.RichText=true;c.TextLabel.Text=tostring(info.Text or"")end
    self.Elements[#self.Elements+1]=c;Library.Controls[#Library.Controls+1]=c
    if id or info.Index then Library.Labels[id or info.Index]=c end
    c:_Visibility();return c
end
function Container:AddButton(info,callback)
    info=type(info)=="string"and{Text=info,Func=callback}or info or{}
    local c=setmetatable({Type="Button",Text=plain(info.Text),Func=info.Func or info.Callback,Info=info,ParentContainer=self,
        Addons={},Visible=info.Visible~=false,Disabled=info.Disabled==true},Control)
    c.Raw=self.Raw:CreateButton({Name=c.Text,DoubleTap=info.DoubleClick==true,Callback=function()c:Press()end})
    c.Holder=c.Raw.Frame;c.TextLabel=frameLabel(c.Raw)
    self.Elements[#self.Elements+1]=c;Library.Controls[#Library.Controls+1]=c;c:SetDisabled(c.Disabled);c:_Visibility()
    if info.Tooltip then Library:AddTooltip(info.Tooltip,info.DisabledTooltip,c.Holder)end
    return c
end
function Container:AddDivider(value)
    if value then return self:AddLabel(value,true)end
    self.Raw:CreateDividier();return self
end
function Container:AddUIPassthrough(id,info)
    local holder=new("Frame",self.Raw.Container,{Name=id,Size=UDim2.new(1,0,0,info.Height or 100),BackgroundTransparency=1,BorderSizePixel=0})
    info.Instance.Parent=holder
    local c=setmetatable({Type="UIPassthrough",Id=id,Instance=info.Instance,Holder=holder,Visible=info.Visible~=false,ParentContainer=self},Control)
    self.Elements[#self.Elements+1]=c;Library.Options[id]=c;c:_Visibility();return c
end
function Container:AddImage(id,info)
    local image=new("ImageLabel",nil,{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Image=tostring(info.Image or info.Asset or""),ScaleType=Enum.ScaleType.Fit})
    local c=self:AddUIPassthrough(id,{Instance=image,Height=info.Height or 150,Visible=info.Visible});c.Type="Image"
    function c:SetImage(value)image.Image=tostring(value)end
    return c
end
function Container:AddDependencyBox()
    local c=setmetatable({Raw=self.Raw,Elements={},ParentContainer=self,Visible=true,IsDependency=true,Tab=self.Tab,Side=self.Side},Container)
    self.Elements[#self.Elements+1]=c;Library.DependencyBoxes[#Library.DependencyBoxes+1]=c;return c
end
Container.AddDependencyGroupbox=Container.AddDependencyBox
function Container:SetupDependencies(items)
    self.Dependencies=items;Library:UpdateDependencyBoxes();return self
end
function Container:_Visibility()
    for _,element in ipairs(self.Elements)do if element._Visibility then element:_Visibility()end end
end
function Library:UpdateDependencyBoxes()
    for _,box in ipairs(self.DependencyBoxes)do
        local show=true
        for _,rule in ipairs(box.Dependencies or{})do
            local control,expected=rule[1],rule[2]
            local value=control and control.Value
            if type(value)=="table"then show=show and value[expected]==true else show=show and value==expected end
        end
        box.Visible=show;box:_Visibility()
    end
end
function Container:Resize()end -- Native UIListLayouts drive sizing.
function Container:SetVisible(value)self.Visible=value==true;if self.Frame and not self.IsDependency then self.Frame.Visible=self.Visible end;self:_Visibility()end
function Container:SetCollapsed(value)self.Collapsed=value==true;self:_Visibility()end
function Container:SetPoppedOut()end
function Container:AddTabbox(info)
    return setmetatable({Tab=self.Tab,Side=self.Side,Name=type(info)=="table"and(info.Name or self.Name or"Options")or self.Name or"Options",GroupId=tostring({}),Tabs={},IsTabbox=true},Container)
end
function Container:AddTab(name,icon)
    assert(self.IsTabbox,"AddTab requires a native section group")
    local group=self.Tab:_Group(name or plain(icon),self.Side,self.GroupId or self.Name)
    self.Tabs[name or tostring(#self.Tabs+1)]=group;return group
end
function Tab:_Group(name,side,groupName)
    name=plain(name);local raw=self.Raw:CreateSection({Name=name,Side=side or"Left",Group=groupName or(name.."_"..tostring(#self.Groups+1))})
    local group=setmetatable({Raw=raw,Frame=raw.Frame,Container=raw.Container,Name=name,Tab=self,Side=side or"Left",Elements={},Visible=true,Collapsed=false,PopOutEnabled=false},Container)
    if not groupName and raw.Frame then
        local title=raw.Frame:FindFirstChild("ButtonsHolder")
        title=title and title:FindFirstChild("SectionText")
        if title then Library:GiveSignal(title.MouseButton1Up:Connect(function()group:SetCollapsed(not group.Collapsed)end))end
    end
    self.Groupboxes[name]=group;self.Groups[#self.Groups+1]=group;return group
end
function Tab:AddLeftGroupbox(name,icon,visible,collapsed)
    local group=self:_Group(name,"Left");if visible==false then group:SetVisible(false)end;if collapsed then group:SetCollapsed(true)end;return group
end
function Tab:AddRightGroupbox(name,icon,visible,collapsed)
    local group=self:_Group(name,"Right");if visible==false then group:SetVisible(false)end;if collapsed then group:SetCollapsed(true)end;return group
end
function Tab:AddGroupbox(info)return info.Side=="Right"and self:AddRightGroupbox(info.Name)or self:AddLeftGroupbox(info.Name)end
function Tab:_Tabbox(name,side)
    name=plain(name or"Options");local b=setmetatable({Tab=self,Side=side,Name=name,IsTabbox=true,Tabs={}},Container);self.Tabboxes[name]=b;return b
end
function Tab:AddLeftTabbox(name)return self:_Tabbox(name,"Left")end
function Tab:AddRightTabbox(name)return self:_Tabbox(name,"Right")end
function Tab:SetVisible(value)
    self.Visible=value==true;if self.Raw.Button then self.Raw.Button.Visible=self.Visible end
    if self.Raw.Frame then self.Raw.Frame.Visible=self.Visible end
end
function Tab:Show()self.Raw:Show();Library.Window.SelectedTab=self;Library.Window.Raw:Toggle(true)end
function Tab:SetDescription(value)self.Description=value end
function Window:AddTab(name,icon,description)
    local label=plain(name);local asset=Library:GetCustomIcon(icon)
    local raw=self.Raw:CreateTab({Name=label,Icon=asset and asset.Url or""})
    if asset and raw.Button and raw.Button:FindFirstChild("Icon")then
        raw.Button.Icon.ImageRectOffset=asset.ImageRectOffset or Vector2.zero;raw.Button.Icon.ImageRectSize=asset.ImageRectSize or Vector2.zero
    end
    local tab=setmetatable({Name=label,Raw=raw,Groupboxes={},Tabboxes={},Groups={},Visible=true,Description=description},Tab)
    self.Tabs[label]=tab;Library.Tabs[name]=tab
    if not self.SelectedTab then self.SelectedTab=tab end
    if label=="Home"and next(self.FooterActions)then
        local tools=tab:AddLeftGroupbox("Tools")
        for _,item in ipairs(self.FooterActions)do tools:AddButton(item)end
    end
    return tab
end
function Window:AddFooterAction(name,callback)
    self.FooterActions[#self.FooterActions+1]={Text=name,Func=callback}
end
function Window:SetCornerRadius(value)
    Library.CornerRadius=math.clamp(tonumber(value)or 30,0,40)
    Native.Themes[Native.CurrentTheme].CornerRadius=Library.CornerRadius
    for _,node in ipairs(Library.ScreenGui:GetDescendants())do if node:IsA("UICorner")then node.CornerRadius=UDim.new(0,Library.CornerRadius)end end
end
function Window:GetSidebarWidth()return 0 end
function Window:SetSidebarWidth()end -- Navigation now uses the native tab strip.
function Window:SetTitle(value)self.Title=plain(value)end
function Window:SetFooter(value)self.Footer=plain(value)end
function Window:SetAnimations()end
function Window:AddDialog(id,info)
    local previous=self.Dialogs[id];if previous then previous:Destroy()end
    local shade=new("TextButton",Library.ScreenGui,{Name=id,Size=UDim2.fromScale(1,1),Text="",BackgroundColor3=Color3.new(),BackgroundTransparency=.35,ZIndex=1500,AutoButtonColor=false})
    local panel=new("Frame",shade,{Size=UDim2.fromOffset(500,230),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=Library.Scheme.BackgroundColor,ZIndex=1501,BorderSizePixel=0});corner(panel)
    local title=text(panel,info.Title);title.Size=UDim2.new(1,-30,0,45);title.Position=UDim2.fromOffset(15,10);title.ZIndex=1502;title.TextSize=20
    local desc=text(panel,info.Description);desc.Size=UDim2.new(1,-30,0,100);desc.Position=UDim2.fromOffset(15,55);desc.ZIndex=1502
    local result={};function result:Destroy()shade:Destroy()end
    local buttons=info.FooterButtons or{}
    for i,button in ipairs(buttons)do
        local b=new("TextButton",panel,{Text=button.Title,Size=UDim2.new(1/#buttons,-20,0,36),Position=UDim2.new((i-1)/#buttons,10,1,-50),BackgroundColor3=Library.Scheme.MainColor,TextColor3=Library.Scheme.FontColor,Font=Enum.Font.Code,TextSize=15,ZIndex=1502,BorderSizePixel=0});corner(b,16)
        Library:GiveSignal(b.MouseButton1Click:Connect(function()result:Destroy();Library:SafeCallback(button.Callback)end))
    end
    self.Dialogs[id]=result;return result
end
function Library:CreateWindow(info)
    self.Taskbar=Native:CreateTaskbar({Name="astral",Description=plain(info.Footer),Icon="sparkles",LoadedSound=""})
    self.Taskbar:ConfigNotifications({Enabled=true,Volume=0,Sound=""})
    local raw=self.Taskbar:CreateWindow({Name="astral",Description=plain(info.Footer),Icon="sparkles",Pinned=true})
    local viewport=workspace.CurrentCamera.ViewportSize
    raw.OldSize=UDim2.fromOffset(math.min(1040,viewport.X-24),math.min(720,viewport.Y-110))
    raw.OldPosition=UDim2.new(.5,-raw.OldSize.X.Offset/2,.5,-raw.OldSize.Y.Offset/2-24)
    self.Window=setmetatable({Raw=raw,MainFrame=raw.Frame,Tabs={},FooterActions={},Dialogs={},Title=plain(info.Title)},Window)
    local toggle=raw.Toggle
    raw.Toggle=function(window,open)self.Toggled=open==true;return toggle(window,open)end
    self.Scale=new("UIScale",raw.Frame,{Scale=1})
    self.KeybindFrame=new("Frame",self.ScreenGui,{Name="AstralKeybinds",Size=UDim2.fromOffset(260,360),Position=UDim2.fromOffset(12,180),Visible=false,BackgroundColor3=self.Scheme.BackgroundColor,BackgroundTransparency=.16,BorderSizePixel=0,ZIndex=250});corner(self.KeybindFrame)
    local title=text(self.KeybindFrame,"Keybinds");title.Size=UDim2.new(1,-20,0,35);self:MakeDraggable(self.KeybindFrame,title)
    self.KeybindContainer=new("ScrollingFrame",self.KeybindFrame,{Size=UDim2.new(1,-16,1,-45),Position=UDim2.fromOffset(8,38),BackgroundTransparency=1,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,BorderSizePixel=0})
    new("UIListLayout",self.KeybindContainer,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3)})
    self.Taskbar:Init();self:UpdateColorsUsingRegistry()
    task.defer(function()if not self.Unloaded and info.AutoShow~=false then raw:Toggle(true)end end)
    return self.Window
end
function Library:Toggle(value)
    self.Toggled=value==nil and not self.Toggled or value==true
    if self.Window then self.Window.Raw:Toggle(self.Toggled)end
end
function Library:Notify(info,time)
    if type(info)~="table"then info={Description=tostring(info),Time=time}end
    if not self.Taskbar or self.Unloaded then return{Destroy=function()end,ChangeDescription=function()end}end
    return self.Taskbar:CreateNotification({Name=plain(info.Title or"astral"),Description=tostring(info.Description or""),
        Duration=info.Time or 5,Sound=info.SoundId and tostring(info.SoundId)or"",Volume=info.Volume or 0,
        Persist=info.Persist,Group=info.Group or tostring({})})
end
function Library:SetDPIScale(value)self.DPIScale=(tonumber(value)or 100)/100;if self.Scale then self.Scale.Scale=self.DPIScale end end
function Library:SetNotifySide(side)
    self.NotifySide=side
    local holder=self.ScreenGui:FindFirstChild("NotificationsHubFrame",true)
    if holder then
        local old=holder.Position;holder.AnchorPoint=Vector2.new(side=="Left"and 0 or 1,1)
        holder.Position=UDim2.new(side=="Left"and 0 or 1,side=="Left"and 10 or -10,old.Y.Scale,old.Y.Offset)
    end
end
function Library:UpdateSearch(value)
    self.SearchText=plain(value or""):lower()
    for _,c in ipairs(self.Controls)do c:_Visibility();if self.SearchText~=""and c.Holder and not plain(c.Text):lower():find(self.SearchText,1,true)then c.Holder.Visible=false end end
end
function Library:AddTooltip(normal,disabled,holder)
    if not holder then return end
    self:GiveSignal(holder.MouseEnter:Connect(function()
        if self.Tooltip then self.Tooltip:Destroy()end
        local point=UIS:GetMouseLocation()
        self.Tooltip=new("TextLabel",self.ScreenGui,{Name="AstralTooltip",Text=plain(normal or disabled),Font=Enum.Font.Code,TextSize=13,TextWrapped=true,
            TextColor3=self.Scheme.FontColor,BackgroundColor3=self.Scheme.MainColor,BackgroundTransparency=.1,Size=UDim2.fromOffset(340,80),Position=UDim2.fromOffset(point.X+12,point.Y+16),ZIndex=2000,BorderSizePixel=0});corner(self.Tooltip,14)
    end))
    self:GiveSignal(holder.MouseLeave:Connect(function()if self.Tooltip then self.Tooltip:Destroy();self.Tooltip=nil end end))
end
function Library:ChangeCursorIcon(image)self.CursorImage=image;if self.Cursor then self.Cursor.Image=image end end
function Library:ChangeCursorIconSize(size)self.CursorSize=size;if self.Cursor then self.Cursor.Size=size end end
function Library:ChangeCursorIconColor(color)self.CursorColor=color;if self.Cursor then self.Cursor.ImageColor3=color end end
Library.ChangeCursorCrossColor=Library.ChangeCursorIconColor
function Library:ResetCursorIcon()self:ChangeCursorIcon("")end
function Library:ResetCursorCross()end

local function modifiersHeld(picker)
    for _,name in ipairs(picker.Modifiers or{})do
        local key=type(name)=="string"and Enum.KeyCode[modifierNames[name]or name]or name
        if not key or not UIS:IsKeyDown(key)then return false end
    end
    return true
end
Library:GiveSignal(UIS.InputBegan:Connect(function(input,processed)
    if Library.Unloaded or processed or UIS:GetFocusedTextBox()then return end
    for _,picker in ipairs(Library.KeyPickers)do if picker.Raw.IsBinding and picker.Raw.IsBinding()then return end end
    for _,picker in ipairs(Library.KeyPickers)do
        if(picker.Value==input.KeyCode.Name or picker.Value==input.UserInputType.Name)and modifiersHeld(picker)and enabled(picker)then
            if picker.Mode=="Hold"then picker._Held=true;picker.Toggled=true
            elseif picker.Mode=="Toggle"then picker.Toggled=not picker.Toggled
            elseif picker.Mode=="Press"then picker.Toggled=true
            else continue end
            picker:DoClick()
        end
    end
end))
Library:GiveSignal(UIS.InputEnded:Connect(function(input)
    for _,picker in ipairs(Library.KeyPickers)do
        if picker.Mode=="Hold"and picker._Held and(picker.Value==input.KeyCode.Name or picker.Value==input.UserInputType.Name or not modifiersHeld(picker))then
            picker._Held=false;picker.Toggled=false;picker:DoClick()
        end
    end
end))
Library:GiveSignal(UIS.WindowFocusReleased:Connect(function()
    for _,picker in ipairs(Library.KeyPickers)do if picker._Held then picker._Held=false;picker.Toggled=false;picker:DoClick()end end
end))
local function refreshPlayers()
    for _,control in pairs(Library.Options)do
        if control.Type=="Dropdown"and control.SpecialType=="Player"then
            local values=Players:GetPlayers()
            if control.ExcludeLocalPlayer then local i=table.find(values,Players.LocalPlayer);if i then table.remove(values,i)end end
            table.sort(values,function(a,b)return a.Name:lower()<b.Name:lower()end)
            control:SetValues(values)
        end
    end
end
Library:GiveSignal(Players.PlayerAdded:Connect(refreshPlayers))
Library:GiveSignal(Players.PlayerRemoving:Connect(function(player)
    for _,control in pairs(Library.Options)do
        if control.Type=="Dropdown"and control.SpecialType=="Player"then
            local values={};for _,value in ipairs(control.Values)do if value~=player then values[#values+1]=value end end
            control:SetValues(values)
        end
    end
end))
Library:GiveSignal(RunService.RenderStepped:Connect(function()
    if Library.ShowCustomCursor and Library.CursorImage and Library.CursorImage~=""and Library.Toggled then
        if not Library.Cursor then Library.Cursor=new("ImageLabel",Library.ScreenGui,{Name="AstralCursor",BackgroundTransparency=1,ZIndex=2100,Size=Library.CursorSize or UDim2.fromOffset(20,20),Image=Library.CursorImage})end
        local point=UIS:GetMouseLocation();Library.Cursor.Position=UDim2.fromOffset(point.X,point.Y);Library.Cursor.Visible=true
    elseif Library.Cursor then Library.Cursor.Visible=false end
end))
function Library:Unload()
    if self.Unloaded or self.Unloading then return end
    self.Unloading=true
    for _,fn in ipairs(self.UnloadSignals)do self:SafeCallback(fn)end
    self.Unloaded=true
    for _,connection in ipairs(self.Connections)do connection:Disconnect()end
    table.clear(self.Connections)
    Native:Unload()
    UIS.MouseBehavior=originalMouseBehavior;UIS.MouseIconEnabled=originalMouseIcon
    self.Unloading=false
end
return Library
