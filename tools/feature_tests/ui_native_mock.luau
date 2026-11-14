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
signals.MouseMoved=true
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
function Node:FindFirstChildWhichIsA(class,recursive)
    for _,child in ipairs(self:GetChildren())do
        if child:IsA(class)then return child end
        if recursive then local found=child:FindFirstChildWhichIsA(class,true);if found then return found end end
    end
end
function Font.new(family,weight,style)return{Family=family,Weight=weight,Style=style,__kind='Font'}end
local Content={fromUri=function(uri)return{Uri=uri}end,fromObject=function(object)return{Object=object}end}
local editableImages={}
local function editable(w,h,pixels)
 local image={Size=Vector2.new(w,h),Pixels=pixels or buffer.create(w*h*4),Destroyed=false}
 function image:ReadPixelsBuffer()return self.Pixels end
 function image:WritePixelsBuffer(_,_,p)self.Pixels=p end
 function image:Destroy()self.Destroyed=true end
 editableImages[#editableImages+1]=image;return image
end
services.AssetService={}
function services.AssetService:CreateEditableImageAsync()
 local w,h=96,64;local p=buffer.create(w*h*4)
 for y=0,h-1 do for x=0,w-1 do
  local v=(math.floor(x/8)+math.floor(y/8))%2==0 and 82 or 106
  if (x>=7 and x<=88 and(y>=7 and y<=11 or y>=52 and y<=56))or(y>=7 and y<=56 and(x>=7 and x<=11 or x>=84 and x<=88))then v=242 end
  local i=(y*w+x)*4;buffer.writeu8(p,i,v);buffer.writeu8(p,i+1,v);buffer.writeu8(p,i+2,v);buffer.writeu8(p,i+3,255)
 end end
 return editable(w,h,p)
end
function services.AssetService:CreateEditableImage(options)return editable(options.Size.X,options.Size.Y)end

local nativeIsA=Node.IsA
function Node:IsA(class)
 if class=='GuiObject'and(self.ClassName=='UIGridLayout'or self.ClassName=='UIAspectRatioConstraint')then return false end
 return nativeIsA(self,class)
end
