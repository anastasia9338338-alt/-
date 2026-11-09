-- Additional service surface used by the native sidebar library.
services.GuiService={GetGuiInset=function()return Vector2.zero,Vector2.zero end}
services.SoundService=Instance.new("Folder")
services.Teams=Instance.new("Folder")
function services.Teams:GetTeams()return{}end
function RunService:IsStudio()return false end
function RunService:BindToRenderStep(name,priority,callback)self.Bindings=self.Bindings or{};self.Bindings[name]=callback end
function RunService:UnbindFromRenderStep(name)if self.Bindings then self.Bindings[name]=nil end end
function RunService.RenderStepped:Wait()if coroutine.running()==mainThread then return 1/60 end;return coroutine.yield(1/60)end
function UIS:GetPlatform()return Enum.Platform.Windows end
UIS.MouseEnabled=true
UIS.WindowFocused=signal()
services.TextService.GetTextBoundsAsync=function(_,params)return Vector2.new(#params.Text*params.Size*.5,params.Size)end
local nativeNew=Instance.new
function Instance.new(class,parent)
    local node=nativeNew(class,parent)
    node.Scale=1;node.Rotation=0
    if class=="GetTextBoundsParams"then node.Text="";node.Size=14 end
    return node
end
signals.DescendantRemoving=true
signals.Activated=true
function Node:SetAttribute(name,value)self._attributes=self._attributes or{};self._attributes[name]=value end
function Node:GetAttribute(name)return self._attributes and self._attributes[name]end
function Node:ClearAllChildren()for _,child in ipairs(self:GetChildren())do child:Destroy()end end
function Node:CaptureFocus()UIS.Focused=self end
function Node:ReleaseFocus()if UIS.Focused==self then UIS.Focused=nil end end
function Node:TweenSize(size)self.Size=size end
function Node:TweenPosition(position)self.Position=position end
function Node:FindFirstAncestorOfClass(class)local parent=self.Parent;while parent do if parent:IsA(class)then return parent end;parent=parent.Parent end end
function Node:QueryDescendants(query)
    local result={}
    for _,node in ipairs(self:GetDescendants())do
        local matched=false
        if query=="GuiObject:not(ImageButton)"then matched=node:IsA("GuiObject")and not node:IsA("ImageButton")
        elseif query=="GuiButton"then matched=node:IsA("TextButton")or node:IsA("ImageButton")
        else for name in query:gmatch("%w+")do if node:IsA(name)then matched=true end end end
        if matched then result[#result+1]=node end
    end
    return result
end
