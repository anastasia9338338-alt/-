-- The uploaded UI uses one CanvasGroup; Roblox fades its descendants through
-- GroupTransparency without rewriting each text widget's own transparency.
local motion=Motion.new(RunService.RenderStepped)
local function node()
 local n=Instance.new("CanvasGroup",CoreGui);n.Position=UDim2.fromOffset(0,0)
 n.GroupTransparency=1;n.BackgroundTransparency=0;n.Visible=false;return n
end
local positions={}
for _,fps in {30,60,144}do
 local ui=node();motion:Move(ui,UDim2.fromOffset(300,150));motion:Step(1/fps)
 check(ui.Position.X.Offset>0 and ui.Position.X.Offset<300,"Drag teleported directly to the cursor")
 for _=2,fps do motion:Step(1/fps)end
 check(math.abs(ui.Position.X.Offset-300)<.15,"Drag did not settle at the cursor")
 positions[#positions+1]=ui.Position.X.Offset
end
check(math.abs(positions[1]-positions[3])<.15,"Smoothing depends on frame rate")
local gui=node();local text=Instance.new("TextLabel",gui);text.TextTransparency=0
local hidden=Instance.new("Frame",gui);hidden.Visible=false
local hiddenText=Instance.new("TextLabel",hidden);hiddenText.TextTransparency=.2
motion:Show(gui,true,true);motion:Step(.04)
check(gui.Visible and gui.GroupTransparency>0 and gui.GroupTransparency<1,"Opening has no opacity transition")
check(text.TextTransparency==0 and hiddenText.TextTransparency==.2,"Group fading rewrote child opacity")
local alpha=gui.GroupTransparency
motion:Show(gui,false,true);motion:Step(.02)
check(gui.GroupTransparency>alpha,"Interrupted opening did not reverse smoothly")
motion:Show(gui,true,true)
for _=1,40 do motion:Step(1/60)end
check(gui.Visible and gui.GroupTransparency==0,"A stale close transition hid a reopened window")
motion:Show(gui,false,true)
for _=1,40 do motion:Step(1/60)end
check(not gui.Visible and gui.GroupTransparency==1 and text.TextTransparency==0,"Closing did not finish group opacity")
motion:Show(gui,true,false)
check(gui.Visible and gui.GroupTransparency==0 and not motion.Connection,"Initial show still depends on render frames")
local watermark=node();motion:Move(watermark,UDim2.fromOffset(200,80));motion:Step(.02)
local restored=UDim2.fromOffset(50,60);watermark.Position=restored;motion:Step(.02)
check(watermark.Position==restored and not motion.Moves[watermark],"An old drag overwrote a restored HUD position")
local blocked=node();motion:Move(blocked,UDim2.fromOffset(100,0),function()return false end);motion:Step(.02)
check(blocked.Position.X.Offset==0 and not motion.Connection,"Hidden menu kept moving")
local dead=node();motion:Move(dead,UDim2.fromOffset(100,0));dead:Destroy();motion:Step(.02)
check(not motion.Connection,"Destroyed GUI retained a motion loop")
motion:Move(watermark,UDim2.fromOffset(200,80));local connection=motion.Connection
motion:Dispose();motion:Dispose()
check(not connection.Connected and not motion.Connection,"Motion listener survived unload")
print("PASS: "..checks.." CanvasGroup motion, FPS, interrupted fades, HUD layout and disposal checks (mocked)")
