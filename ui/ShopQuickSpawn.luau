-- Local inventory shortcuts. Only selected owned native inventory IDs can spawn;
-- one shared input observer, bounded requests and the existing game spawn API.
local Quick={};Quick.__index=Quick
local function theme(self,key,fallback)
 local scheme=self.Context.Library.Scheme
 return scheme and scheme[key]~=nil and scheme[key]or fallback
end
local function inside(node,root)return root and(node==root or node:IsDescendantOf(root))end
local function create(class,parent,props)
 local v=Instance.new(class);for k,value in pairs(props or{})do v[k]=value end;v.Parent=parent;return v
end
local function round(v,r)create('UICorner',v,{CornerRadius=UDim.new(0,r)})end
local function text(parent,value,size)
 return create('TextLabel',parent,{Text=value,TextSize=size or 9,FontFace=Font.fromEnum(Enum.Font.GothamBold),TextColor3=Color3.fromRGB(240,240,240),BackgroundTransparency=1,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd})
end
local modifiers={LeftControl='LCtrl',RightControl='RCtrl',LeftShift='LShift',RightShift='RShift',LeftAlt='LAlt',RightAlt='RAlt'}
local codes={LCtrl='LeftControl',RCtrl='RightControl',LShift='LeftShift',RShift='RightShift',LAlt='LeftAlt',RAlt='RightAlt'}
function Quick.Install(style,ctx)
 local self=setmetatable({Style=style,Context=ctx,Owned={},Selected={},Keys={},Rows={},Connections={},Tabs={},Picking=nil,NextSpawn=0,Open=false},Quick)
 local options=ctx.Options
 if options and ctx.Encode and ctx.Decode then
  local selected={Type='Input',Value='[]'}
  function selected:SetValue(value)
   local ok,data=pcall(ctx.Decode,value);if not ok or type(data)~='table'then return end
   self.Value=value;table.clear(self.Owner.Selected)
   for _,name in ipairs(data)do if type(name)=='string'then self.Owner.Selected[name]=true end end
   self.Owner:Redraw()
  end
  selected.Owner=self;self.SelectionOption=selected;options.AstralShopQuickItems=selected
 end
 for name in pairs(ctx.Catalog or{})do self:KeyOption(name)end
 self.Connections[#self.Connections+1]=ctx.Input.InputBegan:Connect(function(input,processed)self:Input(input,processed)end)
 return self
end
function Quick:KeyOption(name)
 if self.Keys[name]then return self.Keys[name]end
 local q=self;local option={Type='KeyPicker',Value='None',Mode='Press',Modifiers={},Toggled=false}
 function option:SetValue(data)
  if type(data)~='table'then return end
  local key=data[1];local valid=key=='None'
  if type(key)=='string'then local ok,value=pcall(function()return Enum.KeyCode[key]end);valid=valid or(ok and value and key~='Unknown')end
  if not valid then return end
  self.Value=key;self.Mode='Press';self.Modifiers={}
  for _,v in ipairs(type(data[3])=='table'and data[3]or{})do if codes[v]then table.insert(self.Modifiers,v)end end
  q:Redraw()
 end
 function option:Update()q:Redraw()end
 self.Keys[name]=option
 if self.Context.Options then self.Context.Options['AstralShopQuickKey_'..name]=option end
 return option
end
function Quick:Owns(node)return inside(node,self.Host)or inside(node,self.Clock)end
function Quick:Mount(menu,contents)
 if self.Host and self.Host.Parent==menu then return end
 self:Detach()
 self.Host=create('Frame',menu,{Name='AstralQuickSpawnPage',BackgroundTransparency=1,Visible=false,Size=UDim2.fromScale(1,1),ZIndex=menu.ZIndex+2})
 self.Clock=create('TextButton',menu,{Name='AstralQuickClock',Text='◷',TextSize=21,FontFace=Font.fromEnum(Enum.Font.GothamBold),TextColor3=theme(self,'FontColor',Color3.fromRGB(231,234,238)),BackgroundColor3=theme(self,'MainColor',Color3.fromRGB(37,39,42)),BackgroundTransparency=theme(self,'RowTransparency',.92),BorderSizePixel=0,ZIndex=menu.ZIndex+4})
 round(self.Clock,7)
 if self.Context.Library.GetIcon and self.Context.Library.ApplyLucideIcon then
  local ok,icon=pcall(self.Context.Library.GetIcon,self.Context.Library,'clock')
  if ok and icon then local image=create('ImageLabel',self.Clock,{Name='ClockIcon',BackgroundTransparency=1,ImageColor3=Color3.fromRGB(245,245,245),Size=UDim2.fromScale(.7,.7),Position=UDim2.fromScale(.15,.15),ZIndex=self.Clock.ZIndex+1});self.Context.Library:ApplyLucideIcon(image,icon);self.Clock.Text=''end
 end
 self.Record={Node=self.Host,List=self.Host,Items=self.Host,Kind='quick',Quick=true}
 self.Connections[#self.Connections+1]=self.Clock.Activated:Connect(function()self:Toggle()end)
end
function Quick:ConnectTabs(nodes)
 for _,node in ipairs(nodes)do if not self.Tabs[node]then
  self.Tabs[node]=node.Activated:Connect(function()
   if self.Open then self.Open=false;if self.Host then self.Host.Visible=false end;self:CancelPick();self.Style.Dirty=true;self.Style:Queue()end
  end)
 end end
end
function Quick:LayoutClock(plan,count)
 if not self.Clock then return end
 local r=plan.Sidebar;local h=r.H/math.max(count,1)
 self.Clock.Position=UDim2.fromOffset(r.X,r.Y+r.H-h);self.Clock.Size=UDim2.fromOffset(r.W,h)
 self.Clock.TextSize=math.min(r.W*.8,h*.8);self.Clock.Visible=true
 self.Host.Size=UDim2.fromOffset(plan.Width,plan.Height)
end
function Quick:Toggle()
 if self.Closed or not self.Host then return end
 self:CancelPick();self.Open=not self.Open
 self.Style.Applying=true
 if self.Open then
  self.Previous={}
  for _,record in ipairs(self.Style.Pages)do self.Previous[record.Node]=record.Node.Visible;record.Node.Visible=false end
 else
  for node,value in pairs(self.Previous or{})do if node.Parent then node.Visible=value end end
 end
 self.Host.Visible=self.Open;self.Style.Applying=false;self.Style.Dirty=true;self.Style:Find()
end
function Quick:RefreshOwned(pages)
 local owned={}
 for _,record in ipairs(pages)do if record.Node.Name:lower()=='toys'and record.Grid and record.Grid.Parent then
  for _,cell in ipairs(record.Grid.Parent:GetChildren())do if cell:IsA('GuiObject')then
   local name=self.Context.ResolveItem and self.Context.ResolveItem(cell)or cell.Name
   if type(name)=='string'and self.Context.Catalog and self.Context.Catalog[name]then
    -- The outer native ImageButton can be the favorite-star hit surface.
    -- Canonical item artwork has priority; do not inherit its star atlas.
    local picture=self.Context.Catalog[name]
    if type(picture)~='string'then picture=''end
    local offset,rect=Vector2.zero,Vector2.zero
    if picture==''then
     for _,node in ipairs(cell:GetDescendants())do
      local n=node.Name:lower()
      if(node:IsA('ImageLabel')or node:IsA('ImageButton'))and node.Image~=''and not n:find('star',1,true)and not n:find('favorit',1,true)and not n:find('background',1,true)then picture=node.Image;offset=node.ImageRectOffset;rect=node.ImageRectSize;break end
     end
    end
    owned[name]={Name=name,Image=picture,Offset=offset,Rect=rect}
    self:KeyOption(name)
   end
  end end
 end end
 self.Owned=owned
end
function Quick:SaveSelection()
 if self.SelectionOption then
  local names={};for name in pairs(self.Selected)do table.insert(names,name)end;table.sort(names)
  local ok,data=pcall(self.Context.Encode,names);if ok then self.SelectionOption.Value=data end
 end
end
function Quick:CancelPick()
 if self.Picking and self.Context.Library.IsPicking==true then self.Context.Library.IsPicking=false end
 self.Picking=nil
end
function Quick:Select(name)
 if not self.Owned[name]then return false end
 self.Selected[name]=true;self.Choosing=false;self:SaveSelection();self:Redraw();return true
end
function Quick:Spawn(name)
 local ctx=self.Context;local now=(ctx.Clock or os.clock)()
 if self.Closed or not self.Style.Enabled or not self.Selected[name]or not self.Owned[name]or self.Busy or now<self.NextSpawn then return false end
 self.Busy=true;self.NextSpawn=now+.25
 local function valid()return not self.Closed and self.Style.Enabled and self.Selected[name]and self.Owned[name]~=nil end
 (ctx.SpawnThread or task.spawn)(function()
  local ok,why=pcall(ctx.SpawnQuick,name,valid);self.Busy=false
  if not ok then self.LastError=tostring(why)end
 end)
 return true
end
function Quick:Input(input,processed)
 if self.Closed then return end
 local ctx=self.Context
 if input.UserInputType~=Enum.UserInputType.Keyboard then return end
 local name=input.KeyCode.Name
 if self.Picking then
  if ctx.Input:GetFocusedTextBox()then self:CancelPick();self:Redraw();return end
  if modifiers[name]then return end
  local selected=self.Picking;self:CancelPick()
  if name~='Escape'then
   local mods={};for key,code in pairs(codes)do if ctx.Input:IsKeyDown(Enum.KeyCode[code])then mods[#mods+1]=key end end
   self:KeyOption(selected):SetValue({(name=='Backspace'or name=='Delete')and'None'or name,'Press',mods})
  end
  self:Redraw();return
 end
 if processed or ctx.Input:GetFocusedTextBox()or ctx.Library.IsPicking or not self.Style.Enabled then return end
 for item in pairs(self.Selected)do
  local bind=self.Keys[item]
  if bind and bind.Value~='None'and bind.Value==name then
   local held=true;for _,key in ipairs(bind.Modifiers)do if not ctx.Input:IsKeyDown(Enum.KeyCode[codes[key]])then held=false end end
   if held then self:Spawn(item);return end
  end
 end
end
function Quick:Redraw()if self.Open and self.Style.Plan and self.Host then self:Render(self.Style.Plan)end end
function Quick:Render(plan)
 if not self.Host then return end
 self.Rendering=true
 for _,v in ipairs(self.Host:GetChildren())do v:Destroy()end
 local s=plan.Scale;local r=plan.Grid
 local add=create('TextButton',self.Host,{Name='AddItem',Text=self.Choosing and'Назад'or'+ Добавить предмет',TextSize=math.max(8,8*s),FontFace=Font.fromEnum(Enum.Font.GothamBold),TextColor3=theme(self,'FontColor',Color3.fromRGB(231,234,238)),BackgroundColor3=theme(self,'MainColor',Color3.fromRGB(37,39,42)),BackgroundTransparency=theme(self,'RowTransparency',.92),BorderSizePixel=0,Position=UDim2.fromOffset(r.X,r.Y),Size=UDim2.fromOffset(r.W,18*s),ZIndex=self.Host.ZIndex+1})
 round(add,5*s);add.Activated:Connect(function()self:CancelPick();self.Choosing=not self.Choosing;self:Redraw()end)
 local list=create('ScrollingFrame',self.Host,{Name='QuickItems',Position=UDim2.fromOffset(r.X,r.Y+23*s),Size=UDim2.fromOffset(r.W,math.max(1,r.H-23*s)),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2*s,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,ZIndex=self.Host.ZIndex+1})
 local names={};for name in pairs(self.Choosing and self.Owned or self.Selected)do if self.Owned[name]then table.insert(names,name)end end;table.sort(names)
 local columns=math.max(1,math.floor(r.W/(42*s)));local w=(r.W-(columns-1)*4*s)/columns;local h=w+17*s
 list.CanvasSize=UDim2.fromOffset(0,math.ceil(#names/columns)*(h+6*s));self.Rows={}
 for index,name in ipairs(names)do
  local item=self.Owned[name];local x=(index-1)%columns*(w+4*s);local y=math.floor((index-1)/columns)*(h+6*s)
  local cell=create('Frame',list,{Name=name,BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),ZIndex=list.ZIndex+1})
  local image=create('ImageButton',cell,{Name='Item',Image=item.Image,ImageRectOffset=item.Offset or Vector2.zero,ImageRectSize=item.Rect or Vector2.zero,ScaleType=Enum.ScaleType.Fit,BackgroundTransparency=1,Size=UDim2.fromOffset(w,w),ZIndex=cell.ZIndex+1})
  image.Activated:Connect(function()if self.Choosing then self:Select(name)else self:Spawn(name)end end)
  if not self.Choosing then
   local bind=create('TextButton',cell,{Name='Bind',Text=self.Picking==name and'…'or self:KeyOption(name).Value,TextSize=math.max(7,8*s),FontFace=Font.fromEnum(Enum.Font.Code),TextColor3=theme(self,'FontColor',Color3.fromRGB(231,234,238)),BackgroundColor3=theme(self,'MainColor',Color3.fromRGB(37,39,42)),BackgroundTransparency=theme(self,'RowTransparency',.92),BorderSizePixel=0,Position=UDim2.fromOffset(0,w+2*s),Size=UDim2.fromOffset(w,14*s),TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=cell.ZIndex+2})
   round(bind,4*s)
   bind.Activated:Connect(function()if self.Context.Library.IsPicking and not self.Picking then return end;self:CancelPick();self.Picking=name;self.Context.Library.IsPicking=true;self:Redraw()end)
   bind.MouseButton2Click:Connect(function()self:CancelPick();self:KeyOption(name):SetValue({'None','Press'})end)
   image.MouseButton2Click:Connect(function()self:CancelPick();self.Selected[name]=nil;self:SaveSelection();self:Redraw()end)
   self.Rows[name]={Image=image,Bind=bind,Cell=cell}
  end
 end
 if #names==0 then local hint=text(self.Host,self.Choosing and'Нет доступных предметов'or'Добавьте предмет из своего инвентаря',math.max(7,8*s));hint.Position=UDim2.fromOffset(r.X,r.Y+25*s);hint.Size=UDim2.fromOffset(r.W,30*s);hint.TextWrapped=true;hint.ZIndex=self.Host.ZIndex+2 end
 self.Rendering=false
end
function Quick:CloseForMenu()
 self:CancelPick()
 if not self.Open then return end
 local applying=self.Style.Applying;self.Style.Applying=true
 self.Open=false;if self.Host then self.Host.Visible=false end
 for node,value in pairs(self.Previous or{})do if node.Parent then node.Visible=value end end
 self.Style.Applying=applying
end
function Quick:Detach()
 local applying=self.Style.Applying;self.Style.Applying=true
 if self.Open then for node,value in pairs(self.Previous or{})do if node.Parent then node.Visible=value end end end
 self:CancelPick();self.Open=false
 self.Style.Applying=applying
 for _,connection in pairs(self.Tabs)do connection:Disconnect()end;self.Tabs={}
 if self.Host then self.Host:Destroy();self.Host=nil end
 if self.Clock then self.Clock:Destroy();self.Clock=nil end
 self.Record=nil
end
function Quick:Dispose()
 if self.Closed then return end;self.Closed=true;self:Detach()
 for _,connection in ipairs(self.Connections)do connection:Disconnect()end
 if self.Context.Options then
  if self.Context.Options.AstralShopQuickItems==self.SelectionOption then self.Context.Options.AstralShopQuickItems=nil end
  for name,option in pairs(self.Keys)do if self.Context.Options['AstralShopQuickKey_'..name]==option then self.Context.Options['AstralShopQuickKey_'..name]=nil end end
 end
end
return Quick
