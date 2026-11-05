-- Hold-key callbacks must remain isolated across independently held keys.
local checks=0
local function check(v,m)assert(v,m);checks+=1 end
local function signal()
 local s={Connections={}}
 function s:Connect(fn)
  local c={Connected=true,Fn=fn};function c:Disconnect()self.Connected=false end
  self.Connections[#self.Connections+1]=c;return c
 end
 function s:Fire(...)for _,c in ipairs(self.Connections)do if c.Connected then c.Fn(...)end end end
 return s
end
local Library={Unloaded=false,Toggled=false,UnloadCallbacks={}}
function Library:OnUnload(fn)self.UnloadCallbacks[#self.UnloadCallbacks+1]=fn end
local Enum={UserInputType={Keyboard='Keyboard'}}
local SpecialKeysInput={}
local function IsMouseClickInput()return false end
local function AreModifiersHeld()return true end
local function makePicker(key)
 local ParentObj={Disabled=false}
 local KeyPicker={Mode='Hold',Value=key,Modifiers={},Connections={},Pressed=true,Updates=0}
 function KeyPicker:GetState()return self.Pressed end
 function KeyPicker:Update()self.Updates+=1 end
 local Picking=false
 local UserInputService={InputBegan=signal(),GetFocusedTextBox=function()return nil end}
