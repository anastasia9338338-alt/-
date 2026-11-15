-- Coordinates measured from the compact reference supplied for v4.86.
local Layout={Width=346,Height=274}
function Layout.Build(viewWidth,viewHeight)
 local scale=math.min(viewWidth/900,viewHeight/585,2)
 scale=math.max(.45,math.min(scale,(viewWidth-24)/346,(viewHeight-32)/274))
 local function rect(x,y,w,h,r)return{X=x*scale,Y=y*scale,W=w*scale,H=h*scale,Radius=(r or 0)*scale}end
 return{Scale=scale,Width=346*scale,Height=274*scale,Columns=10,
  Sidebar=rect(0,69,25,181,11),Title=rect(27,20,179,18,9),Categories=rect(210,20,108,18,9),Favorite=rect(321,20,23,18,9),
  Body=rect(27,40,317,207,8),Grid=rect(29,42,312,203),Limit=rect(64,250,238,17,8),
  TitleText=rect(32,22,170,14),LimitText=rect(69,253,226,10),
  Cell=(312-9)/10*scale,Gap=scale,TitleSize=math.max(8,8*scale),SmallSize=math.max(6,6*scale),IconSize=18*scale,
 }
end
return Layout
