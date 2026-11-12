local Font={fromEnum=function(v)return v end}
local checks=0
local function check(x,m)assert(x,m);checks+=1 end
local function signal()
 local s={C={}};function s:Connect(f)local c={Connected=true,F=f};function c:Disconnect()self.Connected=false end;table.insert(self.C,c);return c end
 function s:Fire(...)for _,c in ipairs(self.C)do if c.Connected then c.F(...)end end end
 return s
end
local function enum()return setmetatable({},{__index=function(t,k)rawset(t,k,k);return k end})end
local Enum={Font=enum(),TextXAlignment=enum(),TextTruncate=enum(),UserInputType=enum(),ApplyStrokeMode=enum(),LineJoinMode=enum()}
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local UDim2={}
function UDim2.new(a,b,c,d)return {X=UDim.new(a,b),Y=UDim.new(c,d)}end
function UDim2.fromScale(a,b)return UDim2.new(a,0,b,0)end
function UDim2.fromOffset(a,b)return UDim2.new(0,a,0,b)end
local Vector2={new=function(x,y)return {X=x,Y=y}end};Vector2.zero=Vector2.new(0,0)
local nodes={}
local Node={};Node.__index=Node
function Node:GetPropertyChangedSignal(k)self.Props[k]=self.Props[k]or signal();return self.Props[k]end
function Node:CaptureFocus()self.Focused:Fire()end
function Node:Destroy()self.Destroyed=true end
local Library={Scheme={AccentColor='blue',OutlineColor='outline',FontColor='text',WhiteColor='white',MainColor='main'},Registry={},Corners={}}
function Library:Validate(info,template)local result=table.clone(template);for k,v in pairs(info)do result[k]=v end;return result end
function Library:FunctionIcon(label,text)label.FunctionIcon=text end
function Library:SafeCallback(f,...)if f then f(...)end end
local function New(class,p)
 local n=setmetatable({ClassName=class,ZIndex=1,Props={},AbsolutePosition={X=0,Y=0},AbsoluteSize={X=200,Y=32},InputBegan=signal(),Focused=signal(),FocusLost=signal()},Node)
 Library.Registry[n]={}
 for k,v in pairs(p)do
  if type(v)=='string'and Library.Scheme[v]then n[k]=Library.Scheme[v];Library.Registry[n][k]=v else n[k]=v end
 end
 nodes[#nodes+1]=n;return n
end
local Templates={Slider={Text='Slider',Default=0,Min=0,Max=100,Rounding=0,Prefix='',Suffix='',Callback=function()end,Changed=function()end,Disabled=false,Visible=true,AllowRightClickInput=true}}
local Options={};local Funcs={}
local TweenService={Create=function(_,n,_,props)return {Play=function()for k,v in pairs(props)do n[k]=v end end}end}
local task={spawn=function(fn,...)fn(...)end}
local Mouse={X=100};local ticks=0
local RunService={RenderStepped={Wait=function()ticks+=1 end}}
local function tick()return ticks end
local function typeof(v)return type(v)end
local function IsClickInput(i)return i.UserInputType=='MouseButton1'or i.UserInputType=='Touch'end
local function IsDragInput(i)if i.Once then i.Once=false;return true end;return false end
local function Round(v,r)local m=10^r;return math.floor(v*m+.5)/m end
