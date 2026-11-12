-- Requires ui_engine_mock and the exact Watermark module bound to HUD.
local label=Instance.new("TextLabel",CoreGui)
label.BackgroundColor3=Color3.fromRGB(35,52,72)
label.TextColor3=Color3.fromRGB(38,45,56)
label.Font=Enum.Font.Gotham;label.Text="astral"
local padding=Instance.new("UIPadding",label)
padding.PaddingLeft=UDim.new(0,28);padding.PaddingRight=UDim.new(0,12)
local widget={Label=label,SetText=function(_,value)label.Text=value end,Centered=true}
local reads=0
local stats={Network={ServerStatsItem={["Data Ping"]={GetValue=function()reads+=1;return 73 end}}}}
Players.MaxPlayers=25
local library={Scheme={HeaderColor=Color3.new(1,1,1),HeaderTransparency=.30},Registry={[label]={}}}
local hud=HUD.Install({Widget=widget,RunService=RunService,Players=Players,Player=localPlayer,Workspace=workspace,Stats=stats,Library=library})
check(widget.Centered==nil,"HUD kept a center-lock flag that blocks saved positions")
check(label.Position.X.Scale==.5 and label.Position.Y.Offset==12,"HUD was not initially placed at top center")
check(label.BackgroundColor3:ToHex()=="ffffff" and label.TextColor3.R==38/255 and label.BackgroundTransparency==library.Scheme.HeaderTransparency,"HUD does not follow the translucent white header")
check(library.Registry[label].BackgroundColor3=="HeaderColor" and library.Registry[label].BackgroundTransparency=="HeaderTransparency","Theme changes will not update both HUD surface properties")
check(label.BackgroundTransparency<=.35 and label:FindFirstChildOfClass("UICorner").CornerRadius.Scale==1,"HUD lost its compact translucent pill surface")
check(not label.Text:find("Coins",1,true)and not label.Text:find(":",1,true),"HUD reintroduced removed coin/time fields")
local dragged=UDim2.fromOffset(210,180);label.Position=dragged;label.AnchorPoint=Vector2.new(0,0)
local afterDragReads=reads
advance(3.2)
check(label.Position==dragged and label.AnchorPoint.X==0,"Periodic telemetry snapped a dragged HUD back to center")
check(reads-afterDragReads<=4,"Telemetry sampled network stats more than once per second")
local saved=UDim2.new(.73,-40,.25,18);label.Position=saved
workspace.CurrentCamera.ViewportSize=Vector2.new(180,400)
hud:Update()
check(label.Size.X.Offset<=156,"HUD width exceeds the current viewport")
check(label.Position==saved,"Updating size overwrote the user's restored layout")
check(label.Text:find('<font color=',1,true)and label.Text:find("|",1,true),"HUD lost its subtle statistic dividers")
local before=reads
RunService.Heartbeat:Fire(0/0);RunService.Heartbeat:Fire(math.huge);RunService.Heartbeat:Fire(-1)
check(reads==before,"Invalid frame deltas performed a telemetry update")
hud:Dispose();hud:Dispose();before=reads;advance(2)
check(reads==before and label.Text=="astral","Disposed HUD kept sampling stats or lost original text")
for _,connection in ipairs(hud.Connections)do check(not connection.Connected,"HUD event listener survived disposal")end
print('PASS: '..checks..' draggable HUD position/config retention, shared white theme, minimal telemetry, viewport bounds, sampling and cleanup checks (mocked)')
