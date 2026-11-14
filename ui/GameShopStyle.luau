-- Reskin the real MenuGui/Menu only. Native buttons, favorites, category
-- pages, item images, ordering and event connections are retained.
local Shop={};Shop.__index=Shop
local function add(class,parent,props)local v=Instance.new(class);for k,x in pairs(props)do v[k]=x end;v.Parent=parent;return v end
function Shop.Install(ctx)
 local self=setmetatable({Context=ctx,Records={},Created={},Connections={},Enabled=false},Shop)
 local box=ctx.Tab:AddRightGroupbox('Игровой магазин','shopping-bag')
 box:AddToggle('AstralGUIShopStyle',{Text='Магазин как на образце',Default=true,Callback=function(v)self:SetEnabled(v)end})
 box:AddLabel('Оформляется игровой Your Toys. Предметы, категории и звёзды остаются игровыми.',true)
 self.Status=box:AddLabel('Ожидание игрового магазина.',true)
 self.Connections[1]=ctx.PlayerGui.DescendantAdded:Connect(function(v)
  if self.Enabled and(v.Name=='MenuGui'or v.Name=='Menu')then ctx.Defer(function()self:Find()end)end
 end)
 return self
end
function Shop:Write(node,key,value)
 local r=self.Records[node];if not r then r={};self.Records[node]=r end
 if r[key]==nil then r[key]={Original=node[key]}end
 node[key]=value;r[key].Forced=value
end
function Shop:Round(node,radius)
 local c=node:FindFirstChildOfClass('UICorner')
 if not c then c=add('UICorner',node,{CornerRadius=UDim.new(0,radius)});self.Created[#self.Created+1]=c
 else self:Write(c,'CornerRadius',UDim.new(0,radius))end
end
function Shop:Style(node)
 if not self.Enabled or not self.Menu or not node:IsDescendantOf(self.Menu)and node~=self.Menu then return end
 if node:GetAttribute('AstralShopOwned')then return end
 local name=node.Name:lower()
 if node==self.Menu then
  self:Write(node,'BackgroundColor3',Color3.fromRGB(61,63,66));self:Write(node,'BackgroundTransparency',.18);self:Write(node,'BorderSizePixel',0);self:Round(node,20)
 elseif node:IsA('TextLabel')or node:IsA('TextButton')or node:IsA('TextBox')then
  self:Write(node,'TextColor3',Color3.fromRGB(245,245,245));self:Write(node,'FontFace',Font.fromEnum(Enum.Font.BuilderSansBold))
  if node:IsA('TextLabel')then self:Write(node,'BackgroundTransparency',1)end
 end
 if node:IsA('ImageButton')or node:IsA('TextButton')then
  if name:find('star',1,true)or name:find('fav',1,true)then self:Write(node,'BackgroundTransparency',1)
  else self:Write(node,'BackgroundColor3',Color3.fromRGB(38,40,42));self:Write(node,'BackgroundTransparency',.3);self:Write(node,'BorderSizePixel',0);self:Round(node,9)end
 elseif node:IsA('Frame')or node:IsA('ScrollingFrame')then
  if node~=self.Menu and(node.BackgroundTransparency<1 or name:find('bar',1,true)or name:find('tab',1,true))then
   self:Write(node,'BackgroundColor3',Color3.fromRGB(59,61,64));self:Write(node,'BackgroundTransparency',.3);self:Write(node,'BorderSizePixel',0);self:Round(node,12)
  end
  if node:IsA('ScrollingFrame')then self:Write(node,'ScrollBarThickness',3);self:Write(node,'ScrollBarImageColor3',Color3.fromRGB(225,225,225))end
 end
 -- The native inventory already owns its grid and category geometry. Preserve
 -- that layout, including cell ordering and favorite hitboxes.
end
function Shop:Find()
 if not self.Enabled or self.Closed then return end
 local gui=self.Context.PlayerGui:FindFirstChild('MenuGui');local menu=gui and gui:FindFirstChild('Menu')
 if not menu or not menu:IsA('GuiObject')then self.Status:SetText('Ожидание MenuGui / Menu.');return end
 if self.Menu~=menu then
  self:Restore();self.Menu=menu
  self.MenuConnection=menu.DescendantAdded:Connect(function(v)self.Context.Defer(function()if v.Parent then self:Style(v)end end)end)
 end
 self:Style(menu);for _,v in ipairs(menu:GetDescendants())do self:Style(v)end
 self.Status:SetText('Игровой магазин оформлен.')
end
function Shop:Restore()
 if self.MenuConnection then self.MenuConnection:Disconnect();self.MenuConnection=nil end
 for node,properties in pairs(self.Records)do if node.Parent then for key,r in pairs(properties)do if node[key]==r.Forced then node[key]=r.Original end end end end
 for _,v in ipairs(self.Created)do v:Destroy()end
 self.Records={};self.Created={};self.Menu=nil
end
function Shop:SetEnabled(value)
 if self.Closed then return end
 self.Enabled=value==true
 if self.Enabled then
  if self.Context.Before then self.Context.Before()end
  if self.Status then self:Find()end
 else self:Restore();if self.Status then self.Status:SetText('Оригинальное оформление магазина.')end end
end
function Shop:Sync()local t=self.Context.Library.Toggles.AstralGUIShopStyle;self:SetEnabled(t and t.Value)end
function Shop:Dispose()
 if self.Closed then return end;self.Closed=true;self.Enabled=false;self:Restore();for _,c in ipairs(self.Connections)do c:Disconnect()end
end
return Shop
