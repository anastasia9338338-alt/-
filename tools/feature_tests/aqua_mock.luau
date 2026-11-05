-- Extend the shared geometric Instance mock for full Source skeleton matrices.
local oldConstructor=CFrame.new
function CFrame.new(x,y,z,...)
    if select('#',...)==9 then return frame(Vector3.new(x,y,z),{...})end
    return oldConstructor(x,y,z)
end
local oldTypeof=typeof
function typeof(v)if getmetatable(v)==Proxy then return'Instance'end;return oldTypeof(v)end
local function scaleFrame(v,s)return v.Rotation+v.Position*s end
function Proxy:GetPivot()if self:IsA('Model')and self.PrimaryPart then return self.PrimaryPart.CFrame end;return self.CFrame or CFrame.new()end
function Proxy:ScaleTo(value)
    local factor=value/(self._Scale or 1)
    for _,v in ipairs(self:GetDescendants())do
        if v:IsA('BasePart')then v.Size=v.Size*factor
        elseif v:IsA('Bone')then v.CFrame=scaleFrame(v.CFrame,factor)end
    end
    self._Scale=value
end
local checks=0
local function check(v,message)assert(v,message);checks+=1 end
local function finiteVector(v)return v.X==v.X and v.Y==v.Y and v.Z==v.Z and v.Magnitude<100 end
