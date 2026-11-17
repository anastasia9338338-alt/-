-- Native near-target toy removal from message.txt's Remove Anti Kick.
-- A single Grab channel is held for 50 ms and always released on cancellation.
local Remover={};Remover.__index=Remover
local excluded={CreatureBlobman=true,TractorGreen=true,TractorRed=true,TractorOrange=true}
function Remover.Install(context)return setmetatable({Context=context,NextAt=0,Generation=0},Remover)end
function Remover:Valid(character,valid,generation)
    return not self.Closed and self.Generation==generation and character and character.Parent
        and self.Context.Enabled()and(not valid or valid())
end
function Remover:Release()
    local part=self.Held;if not part then return true end
    local ok=pcall(self.Context.Release,part)
    if ok then self.Held=nil end
    return ok
end
function Remover:Request(character,valid)
    local ctx=self.Context;local now=ctx.Clock()
    if self.Closed or self.Busy or now<self.NextAt or not ctx.Enabled()then return false end
    local torso=character and(character:FindFirstChild("Torso")or character:FindFirstChild("UpperTorso")or character:FindFirstChild("HumanoidRootPart"))
    if not torso or not torso.Parent then return false end
    self.NextAt=now+.1
    local target=ctx.Player(character);if not target then return false end
    local selected
    for _,container in ipairs(ctx.Containers(target))do if container and container.Parent then
        for _,toy in ipairs(container:GetChildren())do
            if toy:IsA("Model")and not excluded[toy.Name]then
                local part=toy:FindFirstChild("SoundPart")or toy:FindFirstChildWhichIsA("BasePart")
                if part and not part.Anchored and(part.Position-torso.Position).Magnitude<=5 then selected=part;break end
            end
        end
        if selected then break end
    end end
    if not selected then return false end
    self.Busy=true;self.Working=true;local generation=self.Generation
    ctx.Spawn(function()
        local ok,why=pcall(function()
            if not self:Valid(character,valid,generation)or not selected.Parent then return end
            if ctx.Begin and ctx.Begin(self)==false then return end
            self.Excursion=true
            ctx.Owner(selected,selected.CFrame)
            if not self:Valid(character,valid,generation)or not selected.Parent then return end
            self.Held=selected
            ctx.Grab(selected,selected.CFrame)
            local deadline=ctx.Clock()+.05
            repeat ctx.Wait()until ctx.Clock()>=deadline or not self:Valid(character,valid,generation)or not selected.Parent
        end)
        if not ok then self.LastError=tostring(why)end
        -- Busy remains set if release fails, preventing another feature from
        -- inheriting this half-completed grab. Stop and unload retry it too.
        for _=1,3 do if self:Release()then break end;ctx.Wait()end
        local cleanupUntil=ctx.Clock()+2;local retryAt=ctx.Clock()+.1
        while self.Held and ctx.Clock()<cleanupUntil do
            ctx.Wait()
            if ctx.Clock()>=retryAt then self:Release();retryAt=ctx.Clock()+.1 end
        end
        if self.Excursion and ctx.Finish then pcall(ctx.Finish,self)end
        self.Excursion=nil;self.Working=false;self.Busy=self.Held~=nil
    end)
    return true
end
function Remover:Cancel()
    self.Generation+=1
    if self:Release()and not self.Working then self.Busy=false end
    if self.Excursion and self.Context.Finish then pcall(self.Context.Finish,self)end
    self.Excursion=nil
end
function Remover:Dispose()if self.Closed then return end;self:Cancel();self.Closed=true end
return Remover
