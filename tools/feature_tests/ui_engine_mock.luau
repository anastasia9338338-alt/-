-- GUI-shaped test engine. Executes the actual vendored library and adapter;
-- this is not the Roblox renderer and does not validate a live executor.
local checks=0
local function check(value,message)assert(value,message);checks+=1 end
local function signal()
    local s={Connections={}}
    function s:Connect(fn)local c={Connected=true,Fn=fn,__kind="RBXScriptConnection"};function c:Disconnect()self.Connected=false end;self.Connections[#self.Connections+1]=c;return c end
    function s:Once(fn)local c;c=self:Connect(function(...)c:Disconnect();fn(...)end);return c end
    function s:Fire(...)for _,c in ipairs(table.clone(self.Connections))do if c.Connected then c.Fn(...)end end end
    function s:Wait()return coroutine.yield(.016)end
    return s
end
local Enum=setmetatable({}, {__index=function(t,kind)
    local values=setmetatable({}, {__index=function(v,name)
        if name=="None"then return nil end
        if name=="GetEnumItems"then return function()return{v.Code,v.Gotham,v.SourceSans}end end
        local item={Name=name,EnumType=kind,__kind="EnumItem"};setmetatable(item,{__tostring=function()return"Enum."..kind.."."..name end})
        rawset(v,name,item);return item
    end});rawset(t,kind,values);return values
end})
local function typeof(value)return type(value)=="table"and value.__kind or type(value)end
local vecMT={};vecMT.__index=vecMT
local Vector2={new=function(x,y)return setmetatable({X=x or 0,Y=y or 0,__kind="Vector2"},vecMT)end}
Vector2.zero=Vector2.new()
function vecMT.__add(a,b)return Vector2.new(a.X+b.X,a.Y+b.Y)end
function vecMT.__sub(a,b)return Vector2.new(a.X-b.X,a.Y-b.Y)end
function vecMT.__mul(a,b)if type(a)=="number"then a,b=b,a end;return Vector2.new(a.X*b,a.Y*b)end
function vecMT.__div(a,b)return Vector2.new(a.X/b,a.Y/b)end
function vecMT.__eq(a,b)return a.X==b.X and a.Y==b.Y end
function vecMT:Lerp(other,t)return self+(other-self)*t end
local UDim={new=function(s,o)return{Scale=s or 0,Offset=o or 0,__kind="UDim"}end}
local dimMT={}
local UDim2={}
function UDim2.new(xs,xo,ys,yo)
    if typeof(xs)=="UDim"then return setmetatable({X=xs,Y=xo,__kind="UDim2"},dimMT)end
    return setmetatable({X=UDim.new(xs,xo),Y=UDim.new(ys,yo),__kind="UDim2"},dimMT)
end
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
function dimMT.__add(a,b)return UDim2.new(a.X.Scale+b.X.Scale,a.X.Offset+b.X.Offset,a.Y.Scale+b.Y.Scale,a.Y.Offset+b.Y.Offset)end
function dimMT.__eq(a,b)return a.X.Scale==b.X.Scale and a.X.Offset==b.X.Offset and a.Y.Scale==b.Y.Scale and a.Y.Offset==b.Y.Offset end
local colors={};colors.__index=colors
local Color3={}
function Color3.new(r,g,b)return setmetatable({R=r or 0,G=g or 0,B=b or 0,__kind="Color3"},colors)end
function Color3.fromRGB(r,g,b)return Color3.new(r/255,g/255,b/255)end
function Color3.fromHex(s)s=s:gsub("#","");return Color3.fromRGB(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16))end
function Color3.fromHSV(h,s,v)
    local k=math.floor(h*6);local f=h*6-k;local p,q,t=v*(1-s),v*(1-f*s),v*(1-(1-f)*s)
    local a={{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}};return Color3.new(table.unpack(a[k%6+1]))
end
function colors:ToHSV()
    local max,min=math.max(self.R,self.G,self.B),math.min(self.R,self.G,self.B);local d=max-min;local h=0
    if d>0 then if max==self.R then h=((self.G-self.B)/d)%6 elseif max==self.G then h=(self.B-self.R)/d+2 else h=(self.R-self.G)/d+4 end end
    return h/6,max==0 and 0 or d/max,max
end
Color3.toHSV=colors.ToHSV
function colors:ToHex()return string.format("%02x%02x%02x",math.round(self.R*255),math.round(self.G*255),math.round(self.B*255))end
function colors:Lerp(other,t)return Color3.new(self.R+(other.R-self.R)*t,self.G+(other.G-self.G)*t,self.B+(other.B-self.B)*t)end
local Font={fromEnum=function(value)return{Family=value.Name,Weight=Enum.FontWeight.Regular,Style=Enum.FontStyle.Normal,__kind="Font"}end}
local TweenInfo={new=function(...)return{...}end}
local function seq(...)return{...}end
local ColorSequence,NumberSequence,ColorSequenceKeypoint,NumberSequenceKeypoint={new=seq},{new=seq},{new=seq},{new=seq}
local Node={}
local signals={InputBegan=true,InputEnded=true,InputChanged=true,MouseEnter=true,MouseLeave=true,MouseButton1Click=true,MouseButton2Click=true,
    MouseButton1Up=true,MouseButton1Down=true,MouseButton2Up=true,Focused=true,FocusLost=true,Changed=true,ChildAdded=true,ChildRemoved=true,DescendantAdded=true,Ended=true,Destroying=true}
local viewport=Vector2.new(1280,900)
local mt={}
mt.__index=function(n,k)
    if Node[k]then return Node[k]end
    if k=="__kind"then return"Instance"end
    if k=="Parent"then return rawget(n,"_parent")end
    if k=="AbsoluteSize"then
        if n.ClassName=="ScreenGui"then return viewport end
        local parent=n.Parent and n.Parent.AbsoluteSize or viewport;local size=n.Size or UDim2.fromOffset(100,30)
        return Vector2.new(math.max(0,parent.X*size.X.Scale+size.X.Offset),math.max(0,parent.Y*size.Y.Scale+size.Y.Offset))
    end
    if k=="AbsoluteCanvasSize"then
        local size=n.CanvasSize or UDim2.new();local frame=n.AbsoluteSize
        return Vector2.new(size.X.Scale*frame.X+size.X.Offset,size.Y.Scale*frame.Y+size.Y.Offset)
    end
    if k=="AbsolutePosition"then
        local parent=n.Parent;local origin=parent and parent.AbsolutePosition or Vector2.zero
        local size=parent and parent.AbsoluteSize or viewport;local pos=n.Position or UDim2.new();local anchor=n.AnchorPoint or Vector2.zero
        return origin+Vector2.new(pos.X.Scale*size.X+pos.X.Offset-anchor.X*n.AbsoluteSize.X,pos.Y.Scale*size.Y+pos.Y.Offset-anchor.Y*n.AbsoluteSize.Y)
    end
    if k=="TextBounds"then return Vector2.new(#tostring(n.Text or"")*(n.TextSize or 16)*.5,n.TextSize or 16)end
    if k=="AbsoluteContentSize"then
        local x,y=0,0
        for _,v in ipairs(n.Parent and n.Parent:GetChildren()or{})do if v~=n and v:IsA("GuiObject")and v.Visible then
            if n.FillDirection==Enum.FillDirection.Horizontal then x+=v.AbsoluteSize.X+(n.Padding and n.Padding.Offset or 0);y=math.max(y,v.AbsoluteSize.Y)
            else y+=v.AbsoluteSize.Y+(n.Padding and n.Padding.Offset or 0);x=math.max(x,v.AbsoluteSize.X)end
        end end
        return Vector2.new(x,y)
    end
    if signals[k]then local s=n._signals[k];if not s then s=signal();n._signals[k]=s end;return s end
    local p=n._props[k];if p~=nil then return p end
    for _,child in ipairs(n._children)do if child.Name==k then return child end end
    return nil
end
mt.__newindex=function(n,k,v)
    if k=="Parent"then
        local old=rawget(n,"_parent");if old then local i=table.find(old._children,n);if i then table.remove(old._children,i)end end
        rawset(n,"_parent",v);if v then v._children[#v._children+1]=n end
    else
        local old=n._props[k];n._props[k]=v
        if old~=v then
            local changed=n._properties[k];if changed then changed:Fire()end
            if k=="Text"and n._properties.TextBounds then n._properties.TextBounds:Fire()end
        end
    end
end
function Node:GetChildren()return table.clone(self._children)end
function Node:GetDescendants()local all={};for _,c in ipairs(self._children)do all[#all+1]=c;for _,d in ipairs(c:GetDescendants())do all[#all+1]=d end end;return all end
function Node:FindFirstChild(name,recursive)
    for _,c in ipairs(self._children)do if c.Name==name then return c end end
    if recursive then for _,c in ipairs(self._children)do local found=c:FindFirstChild(name,true);if found then return found end end end
end
function Node:FindFirstChildOfClass(class)for _,c in ipairs(self._children)do if c.ClassName==class then return c end end end
function Node:IsA(class)return self.ClassName==class or class=="GuiObject"and not table.find({"UIListLayout","UICorner","UIStroke","Folder","ScreenGui","UIScale","UIGradient","Sound"},self.ClassName)end
function Node:IsDescendantOf(parent)local p=self.Parent;while p do if p==parent then return true end;p=p.Parent end;return false end
function Node:GetPropertyChangedSignal(name)if not self._properties[name]then self._properties[name]=signal()end;return self._properties[name]end
function Node:Destroy()for _,child in ipairs(self:GetChildren())do child:Destroy()end;self.Parent=nil;self._props.Destroyed=true end
function Node:Play()end
function Node:Stop()end
local Instance={new=function(class,parent)
    local n=setmetatable({_props={ClassName=class,Name=class,Size=UDim2.fromOffset(100,30),Position=UDim2.new(),AnchorPoint=Vector2.zero,Visible=true,
        Text="",TextSize=16,TextTransparency=0,BackgroundTransparency=0,ImageTransparency=0,GroupTransparency=0,BackgroundColor3=Color3.new(),TextColor3=Color3.new(1,1,1),FontFace=Font.fromEnum(Enum.Font.Code),
        ZIndex=1,CanvasPosition=Vector2.zero,CanvasSize=UDim2.new()},_children={},_signals={},_properties={}},mt)
    n.Parent=parent;return n
end}
local timeNow=0;local jobs={};local mainThread=coroutine.running()
local function resume(thread,...)
    local ok,wait=coroutine.resume(thread,...);assert(ok,wait)
    if coroutine.status(thread)~="dead"then jobs[thread]=timeNow+(tonumber(wait)or .016)end
end
local task={}
function task.wait(seconds)if coroutine.running()==mainThread then return seconds or .016 end;return coroutine.yield(seconds or .016)end
function task.spawn(fn,...)local thread=coroutine.create(fn);resume(thread,...);return thread end
function task.defer(fn,...)local args=table.pack(...);local thread=coroutine.create(function()fn(table.unpack(args,1,args.n))end);jobs[thread]=timeNow;return thread end
function task.delay(seconds,fn,...)local args=table.pack(...);local thread=coroutine.create(function()fn(table.unpack(args,1,args.n))end);jobs[thread]=timeNow+seconds;return thread end
function task.cancel(thread)jobs[thread]=nil;if coroutine.status(thread)~="dead"then coroutine.close(thread)end end
local UIS={InputBegan=signal(),InputEnded=signal(),InputChanged=signal(),WindowFocusReleased=signal(),KeyboardEnabled=true,TouchEnabled=false,Down={},MouseIconEnabled=true}
function UIS:GetFocusedTextBox()return self.Focused end
function UIS:GetMouseLocation()return Vector2.new(120,200)end
function UIS:IsKeyDown(key)return self.Down[key.Name]==true end
function UIS:IsMouseButtonPressed(key)return self.Down[key.Name]==true end
local RunService={Heartbeat=signal(),RenderStepped=signal()}
local localPlayer={Name="Local",DisplayName="Local",GetMouse=function()return{X=120,Y=200}end,FindFirstChild=function()end,GetNetworkPing=function()return .05 end}
local Players={LocalPlayer=localPlayer,PlayerAdded=signal(),PlayerRemoving=signal(),List={localPlayer}}
function Players:GetPlayers()return table.clone(self.List)end
local CoreGui=Instance.new("ScreenGui")
local services={UserInputService=UIS,RunService=RunService,CoreGui=CoreGui,Players=Players,
    Stats={Workspace={Heartbeat={GetValue=function()return 60 end}},Network={ServerStatsItem={["Data Ping"]={GetValue=function()return 50 end}}}},
    TextService={GetTextSize=function(_,value,size,font,bounds)return Vector2.new(math.min(#value*size*.5,bounds.X),size)end},
    HttpService={GenerateGUID=function()return"test-guid"end},Debris={AddItem=function()end},
    TweenService={Create=function(_,object,info,values)
        local tween={Completed=signal()}
        function tween:Play()for k,v in pairs(values)do object[k]=v end;task.defer(function()self.Completed:Fire()end)end
        function tween:Cancel()end;return tween
    end}}
local workspace={CurrentCamera={ViewportSize=viewport}}
local function children(object)
    for _,v in pairs(object)do if type(v)=="table"then children(v)end end
    object.WaitForChild=function(self,name)assert(self[name],name);return self[name]end
end
children(services.Stats)
local game={CoreGui=CoreGui,Players=Players,GetService=function(_,name)assert(services[name],name);return services[name]end}
local tick=function()return timeNow end
local gethui=function()return CoreGui end
local env={};local getgenv=function()return env end
local clonefunction=function(fn)return fn end
local files,folders={},{}
local isfolder=function(path)return folders[path]==true end
local makefolder=function(path)folders[path]=true end
local isfile=function(path)return files[path]~=nil end
local writefile=function(path,value)files[path]=value end
local readfile=function(path)assert(files[path],path);return files[path]end
local delfile=function(path)files[path]=nil end
local listfiles=function(path)local all={};for p in pairs(files)do if p:sub(1,#path)==path then all[#all+1]=p end end;return all end
local function deep(value)
    if type(value)~="table"or value.__kind then return value end
    local result={};for k,v in pairs(value)do result[k]=deep(v)end;return result
end
local json={};local jsonCounter=0
function services.HttpService:JSONEncode(value)jsonCounter+=1;local key="json:"..jsonCounter;json[key]=deep(value);return key end
function services.HttpService:JSONDecode(value)assert(json[value],value);return deep(json[value])end
local warn=function(message)error(message)end
local function advance(seconds)
    for _=1,math.ceil(seconds*60)do
        timeNow+=1/60
        RunService.Heartbeat:Fire(1/60);RunService.RenderStepped:Fire(1/60)
        for thread,deadline in pairs(table.clone(jobs))do if deadline<=timeNow then jobs[thread]=nil;resume(thread)end end
    end
end
local function key(name,ending,processed)
    local input={KeyCode=Enum.KeyCode[name],UserInputType=Enum.UserInputType.Keyboard,Position=Vector2.zero,Changed=signal()}
    UIS.Down[name]=not ending;(ending and UIS.InputEnded or UIS.InputBegan):Fire(input,processed or false)
end
