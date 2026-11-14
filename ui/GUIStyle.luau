local Style={};Style.__index=Style
local function new(class,parent,props)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
function Style.Install(ctx)
 local self=setmetatable({Context=ctx,Library=ctx.Library,Records={},Adornments={},Connections={},Building=true},Style)
 self:Build(ctx.Tab);self.Building=false
 self.Previous=ctx.Library.UpdateColorsUsingRegistry
 self.Hook=function(library,...)
  self.Previous(library,...)
  if not self.Closed and not self.Applying then self:Apply()end
 end
 ctx.Library.UpdateColorsUsingRegistry=self.Hook
 self.Connections[1]=ctx.Library.ScreenGui.DescendantAdded:Connect(function(v)
  if self.Closed or self.Applying then return end
  if v:IsA('TextLabel')or v:IsA('TextButton')or v:IsA('TextBox')or v.Name=='SliderThumb'then
   if not self.Queued then self.Queued=true;ctx.Defer(function()self.Queued=false;self:Apply()end)end
  end
 end)
 self:Sync();return self
end
function Style:Build(tab)
 local lib=self.Library;local function changed()if not self.Building then self:Sync()end end
 local text=tab:AddLeftGroupbox('Текст и шрифт','type')
 text:AddDropdown('AstralGUIFont',{Text='Шрифт',Values={'Original','BuilderSans','Gotham','SourceSans','Arial','Code','Cartoon','Fantasy'},Default='Original',AllowNull=false,Callback=changed})
 text:AddSlider('AstralGUITextScale',{Text='Размер текста',Default=1,Min=.75,Max=1.5,Rounding=2,Compact=true,Callback=changed})
 text:AddToggle('AstralGUITextCustom',{Text='Свой цвет текста',Default=false,Callback=changed}):AddColorPicker('AstralGUITextColor',{Default=lib.Scheme.FontColor,Title='Цвет текста',Callback=changed})
 local icons=tab:AddRightGroupbox('Иконки и разделители','shapes')
 icons:AddToggle('AstralGUIFunctionIcons',{Text='Иконки функций',Default=false,Callback=changed})
 icons:AddSlider('AstralGUIIconSize',{Text='Размер иконок функций',Default=16,Min=10,Max=24,Rounding=0,Compact=true,Callback=changed})
 icons:AddLabel('Цвет иконок'):AddColorPicker('AstralGUIIconColor',{Default=lib.Scheme.FontColor,Title='Иконки функций',Callback=changed})
 icons:AddToggle('AstralGUISeparators',{Text='Линии между функциями',Default=false,Callback=changed})
 icons:AddSlider('AstralGUISeparatorAlpha',{Text='Прозрачность линий',Default=.6,Min=0,Max=1,Rounding=2,Compact=true,Callback=changed})
 icons:AddLabel('Цвет линий'):AddColorPicker('AstralGUISeparatorColor',{Default=lib.Scheme.OutlineColor,Title='Разделители',Callback=changed})
 local selected=icons:AddDropdown('AstralGUIIconTarget',{Text='Выбрать функцию',Values={'—'},Default='—',AllowNull=false,Searchable=true,Callback=function(v)
  if self.Building or self.Selecting then return end
  self.Selecting=true;lib.Options.AstralGUIIconOverride:SetValue((self.Overrides or{})[v]or'');self.Selecting=false
 end})
 self.Target=selected
 icons:AddInput('AstralGUIIconOverride',{Text='Иконка: Lucide или Roblox ID',Default='',Finished=true,ClearTextOnFocus=false,Callback=function(value)
  if self.Building or self.Selecting then return end
  local name=selected.Value;if type(name)~='string'or name=='—'then return end
  self.Overrides=self.Overrides or{};self.Overrides[name]=value~=''and value or nil
  local ok,json=pcall(self.Context.Encode,self.Overrides)
  if ok then lib.Options.AstralGUIIconMap:SetValue(json)end;self:Apply()
 end})
 local storage=icons:AddInput('AstralGUIIconMap',{Text='Saved icons',Default='{}',Callback=changed});storage:SetVisible(false)
 local slider=tab:AddLeftGroupbox('Ползунки','sliders-horizontal')
 slider:AddLabel('Заливка'):AddColorPicker('AstralGUISliderFill',{Default=lib.Scheme.AccentColor,Title='Цвет ползунков',Callback=changed})
 slider:AddLabel('Дорожка'):AddColorPicker('AstralGUISliderTrack',{Default=lib.Scheme.MainColor,Title='Дорожка',Callback=changed})
 slider:AddLabel('Бегунок'):AddColorPicker('AstralGUISliderThumb',{Default=Color3.new(1,1,1),Title='Бегунок',Callback=changed})
 slider:AddSlider('AstralGUISliderHeight',{Text='Толщина дорожки',Default=16,Min=4,Max=18,Rounding=0,Compact=true,Callback=changed})
 slider:AddToggle('AstralGUISliderSquare',{Text='Квадратный бегунок',Default=false,Callback=changed})
 local palette=tab:AddRightGroupbox('Прозрачность окна','blend')
 palette:AddSlider('AstralGUIWindowAlpha',{Text='Окно',Default=.55,Min=0,Max=.95,Rounding=2,Compact=true,Callback=changed})
 palette:AddSlider('AstralGUIRowAlpha',{Text='Строки функций',Default=.92,Min=0,Max=1,Rounding=2,Compact=true,Callback=changed})
 palette:AddButton({Text='Сбросить стиль',Func=function()
  for id,value in pairs({AstralGUIFont='Original',AstralGUITextScale=1,AstralGUITextCustom=false,AstralGUIFunctionIcons=false,AstralGUISeparators=false,AstralGUISliderHeight=16,AstralGUISliderSquare=false,AstralGUIWindowAlpha=.55,AstralGUIRowAlpha=.92})do
   local control=lib.Options[id]or lib.Toggles[id];control:SetValue(value)
  end
 end})
end
function Style:Sync()
 if self.Closed then return end
 local lib=self.Library;local function v(id,default)local x=lib.Options[id]or lib.Toggles[id];return x and x.Value~=nil and x.Value or default end
 self.Config={Font=v('AstralGUIFont','Original'),Scale=v('AstralGUITextScale',1),CustomText=v('AstralGUITextCustom',false),TextColor=v('AstralGUITextColor',lib.Scheme.FontColor),
  Icons=v('AstralGUIFunctionIcons',false),IconSize=v('AstralGUIIconSize',16),IconColor=v('AstralGUIIconColor',lib.Scheme.FontColor),
  Separators=v('AstralGUISeparators',false),LineAlpha=v('AstralGUISeparatorAlpha',.6),LineColor=v('AstralGUISeparatorColor',lib.Scheme.OutlineColor),
  Fill=v('AstralGUISliderFill',lib.Scheme.AccentColor),Track=v('AstralGUISliderTrack',lib.Scheme.MainColor),Thumb=v('AstralGUISliderThumb',Color3.new(1,1,1)),Height=v('AstralGUISliderHeight',16),Square=v('AstralGUISliderSquare',false)}
 local ok,map=pcall(self.Context.Decode,v('AstralGUIIconMap','{}'));self.Overrides=ok and type(map)=='table'and map or{}
 lib.GUICustomSlider={Fill=self.Config.Fill}
 lib.Scheme.GlassTransparency=v('AstralGUIWindowAlpha',.55);lib.Scheme.RowTransparency=v('AstralGUIRowAlpha',.92)
 if self.Config.CustomText then
  if not self.LastTextColor then self.OriginalTextColor=lib.Scheme.FontColor end
  lib.Scheme.FontColor=self.Config.TextColor;self.LastTextColor=self.Config.TextColor
 elseif self.LastTextColor then
  if lib.Scheme.FontColor==self.LastTextColor then lib.Scheme.FontColor=self.OriginalTextColor end;self.LastTextColor=nil
 end
 lib:UpdateColorsUsingRegistry();self:Apply()
end
function Style:Apply()
 if self.Closed or not self.Config or self.Applying then return end;self.Applying=true
 local lib,c=self.Library,self.Config;local names={};local seen={}
 local face=c.Font~='Original'and Font.fromEnum(Enum.Font[c.Font])or nil
 for _,node in ipairs(lib.ScreenGui:GetDescendants())do
  if node:IsA('TextLabel')or node:IsA('TextButton')or node:IsA('TextBox')then
   local record=self.Records[node]
   if not record then record={Size=node.TextSize,Face=node.FontFace,Position=node.Position,Bounds=node.Size};self.Records[node]=record end
   node.TextSize=math.clamp(math.floor(record.Size*c.Scale+.5),8,40)
   node.Position=UDim2.new(record.Position.X.Scale,record.Position.X.Offset,record.Position.Y.Scale,record.Position.Y.Offset*c.Scale)
   node.Size=UDim2.new(record.Bounds.X.Scale,record.Bounds.X.Offset,record.Bounds.Y.Scale,record.Bounds.Y.Offset*c.Scale)
   node.FontFace=face and Font.new(face.Family,record.Face.Weight,record.Face.Style)or record.Face
  elseif node.Name=='SliderFill'then node.BackgroundColor3=c.Fill
  elseif node.Name=='SliderTrack'then node.BackgroundColor3=c.Track;node.Size=UDim2.new(node.Size.X.Scale,node.Size.X.Offset,0,c.Height)
  elseif node.Name=='SliderThumb'then
   node.BackgroundColor3=c.Thumb
   local corner=node:FindFirstChildOfClass('UICorner');if corner then corner.CornerRadius=c.Square and UDim.new(0,2)or UDim.new(1,0)end
  end
 end
 for label,name in pairs(lib.FunctionLabels or{})do if label.Parent then
  if not seen[name]then seen[name]=true;names[#names+1]=name end
  local a=self.Adornments[label]
  if not a then
   a={Icon=new('ImageLabel',label,{Name='AstralStyleIcon',BackgroundTransparency=1,AnchorPoint=Vector2.new(0,.5),Active=false,Visible=false}),
    Line=new('Frame',label.Parent,{Name='AstralFunctionDivider',BorderSizePixel=0,Active=false,AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,8,1,0),Size=UDim2.new(1,-16,0,1),Visible=false}),Position=label.Position,Size=label.Size,RowSize=label.Parent.Size}
   self.Adornments[label]=a
  end
  local row=a.RowSize
  if row.Y.Scale==0 then label.Parent.Size=UDim2.new(row.X.Scale,row.X.Offset,0,row.Y.Offset*c.Scale)end
  a.Icon.Visible=c.Icons;a.Line.Visible=c.Separators;a.Line.BackgroundColor3=c.LineColor;a.Line.BackgroundTransparency=c.LineAlpha
  if c.Icons then
   local icon=lib:GetCustomIcon(self.Overrides[name]or self.Context.Icon(name)or'circle')
   if icon then lib:ApplyLucideIcon(a.Icon,icon)end
   a.Icon.ImageColor3=c.IconColor;a.Icon.Size=UDim2.fromOffset(c.IconSize,c.IconSize);a.Icon.Position=UDim2.new(0,-c.IconSize-5,.5,0)
   label.Position=UDim2.new(a.Position.X.Scale,a.Position.X.Offset+c.IconSize+5,a.Position.Y.Scale,a.Position.Y.Offset*c.Scale)
   label.Size=UDim2.new(a.Size.X.Scale,a.Size.X.Offset-c.IconSize-5,a.Size.Y.Scale,a.Size.Y.Offset*c.Scale)
  else label.Position=UDim2.new(a.Position.X.Scale,a.Position.X.Offset,a.Position.Y.Scale,a.Position.Y.Offset*c.Scale);label.Size=UDim2.new(a.Size.X.Scale,a.Size.X.Offset,a.Size.Y.Scale,a.Size.Y.Offset*c.Scale) end
 end end
 table.sort(names)
 if #names~=(self.NameCount or-1)then self.NameCount=#names;if #names>0 then self.Target:SetValues(names)end end
 self.Applying=false
end
function Style:Dispose()
 if self.Closed then return end;self.Closed=true
 if self.Library.UpdateColorsUsingRegistry==self.Hook then self.Library.UpdateColorsUsingRegistry=self.Previous end
 for _,c in ipairs(self.Connections)do c:Disconnect()end
 for label,a in pairs(self.Adornments)do
  if label.Parent then
   label.Position=a.Position;label.Size=a.Size
   local size=label.Parent.Size;label.Parent.Size=UDim2.new(size.X.Scale,size.X.Offset,a.RowSize.Y.Scale,a.RowSize.Y.Offset)
  end
  a.Icon:Destroy();a.Line:Destroy()
 end
 for node,r in pairs(self.Records)do if node.Parent then node.TextSize=r.Size;node.FontFace=r.Face;node.Position=r.Position;node.Size=r.Bounds end end
end
return Style
