-- Coordinates measured from the compact reference supplied for v4.86.
local Layout={Width=346,Height=274}
function Layout.Build(viewWidth,viewHeight,nativeWidth,nativeHeight)
 local base=math.min(viewWidth/900,viewHeight/585,2)
 base=math.max(.45,math.min(base,(viewWidth-24)/346,(viewHeight-32)/274))
 local width,height=346*base,274*base
 local scale=math.min(width/346,height/274)
 local sx,sy=width/346,height/274
 local function rect(x,y,w,h,r)return{X=x*sx,Y=y*sy,W=w*sx,H=h*sy,Radius=(r or 0)*scale}end
 return{Scale=scale,Width=width,Height=height,Columns=10,
  Sidebar=rect(0,40,25,207,11),Title=rect(27,20,179,18,9),Categories=rect(210,20,108,18,9),Favorite=rect(321,20,23,18,9),
  Body=rect(27,40,317,207,8),Grid=rect(34,47,303,193),Limit=rect(64,250,238,17,8),
  TitleText=rect(32,22,170,14),LimitText=rect(69,253,226,10),
  Cell=(303*sx-9*scale)/10,Gap=scale,TitleSize=math.max(8,8*scale),SmallSize=math.max(6,6*scale),IconSize=18*scale,
 }
end
return Layout
