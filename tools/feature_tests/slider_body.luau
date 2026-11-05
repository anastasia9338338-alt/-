local root={AbsolutePosition={X=37,Y=61},AbsoluteSize={X=300,Y=400}}
local group=setmetatable({Container=root,Elements={},Resizes=0},{__index=Funcs})
function group:Resize()self.Resizes+=1 end
local callbackValue,changedValue
local s=group:AddSlider('Speed',{Text='Speed',Default=50,Min=0,Max=100,Compact=true,Rounding=3,Callback=function(v)callbackValue=v end})
s:OnChanged(function(v)changedValue=v end)
local function find(class,predicate)for _,n in ipairs(nodes)do if n.ClassName==class and predicate(n)then return n end end;error('node missing '..class)end
local bar=find('TextButton',function(n)return n.Parent==s.Holder end)
local track=find('Frame',function(n)return n.Parent==bar end)
local thumb=find('Frame',function(n)return n.Parent==track and n.Size.X.Offset==16 end)
local fill=find('Frame',function(n)return n.Parent==track and n~=thumb end)
local value=find('TextLabel',function(n)return n.Text=='50/100'end)
local input=find('TextBox',function()return true end)
local function layout()
 for _,n in ipairs(nodes)do
  if n.Parent and n.Size then
   local ps=n.Parent.AbsoluteSize;local pp=n.Parent.AbsolutePosition;local p=n.Position or UDim2.new(0,0,0,0);local a=n.AnchorPoint or Vector2.zero
   n.AbsoluteSize={X=ps.X*n.Size.X.Scale+n.Size.X.Offset,Y=ps.Y*n.Size.Y.Scale+n.Size.Y.Offset}
   n.AbsolutePosition={X=pp.X+ps.X*p.X.Scale+p.X.Offset-n.AbsoluteSize.X*a.X,Y=pp.Y+ps.Y*p.Y.Scale+p.Y.Offset-n.AbsoluteSize.Y*a.Y}
  end
 end
end
local function close(a,b,m)check(math.abs(a-b)<.00001,m)end
for _,width in ipairs({120,240,680})do
 root.AbsoluteSize.X=width
 for _,percent in ipairs({0,.01,.1,.25,.5,.75,.9,.99,1})do
  s:SetValue(percent*100);layout()
  close(track.AbsoluteSize.Y,thumb.AbsoluteSize.Y,'Track and circle have different thickness')
  close(thumb.AbsoluteSize.X,thumb.AbsoluteSize.Y,'Handle is not circular')
  close(track.AbsolutePosition.Y+track.AbsoluteSize.Y*.5,thumb.AbsolutePosition.Y+thumb.AbsoluteSize.Y*.5,'Handle vertical centre is misaligned')
  check(thumb.AbsolutePosition.X>=track.AbsolutePosition.X-.00001,'Handle overflows minimum endpoint')
  check(thumb.AbsolutePosition.X+thumb.AbsoluteSize.X<=track.AbsolutePosition.X+track.AbsoluteSize.X+.00001,'Handle overflows maximum endpoint')
  check(track.AbsolutePosition.Y>=bar.AbsolutePosition.Y and track.AbsolutePosition.Y+track.AbsoluteSize.Y<=bar.AbsolutePosition.Y+bar.AbsoluteSize.Y,'Track escapes touch hit region')
  local centre=thumb.AbsolutePosition.X+thumb.AbsoluteSize.X*.5
  Mouse.X=centre
  bar.InputBegan:Fire({UserInputType='MouseButton1',Once=true})
  close(s.Value,percent*100,'Mouse drag disagrees with handle position')
  Mouse.X=-999
  bar.InputBegan:Fire({UserInputType='Touch',Position={X=centre},Once=true})
  close(s.Value,percent*100,'Touch drag used mouse coordinates')
 end
end
s:SetValue(75);check(callbackValue==75 and changedValue==75,'Callbacks lost')
s:SetValue(-100);check(s.Value==0,'Minimum clamp failed')
s:SetValue(500);check(s.Value==100,'Maximum clamp failed')
s:SetDisabled(true);local before=s.Value;Mouse.X=0;bar.InputBegan:Fire({UserInputType='MouseButton1',Once=true});check(s.Value==before and not bar.Active,'Disabled slider accepts input')
s:SetDisabled(false)
bar.InputBegan:Fire({UserInputType='MouseButton2'})
check(input.Visible and not value.Visible,'Manual numeric editing does not open')
input.Text='23.4';input:GetPropertyChangedSignal('Text'):Fire();input.FocusLost:Fire()
check(s.Value==23.4 and not input.Visible and value.Visible,'Manual numeric edit failed')
s:SetVisible(false);check(not s.Holder.Visible,'Visibility failed')
s:Destroy();check(Options.Speed==nil and #group.Elements==0,'Destroy leaked slider registry')
print('PASS: '..checks..' real AddSlider geometry and input assertions')
