-- Coordinates measured from the user's compact 364 x 272 reference.
-- Both runtime layout and the inspection preview consume this same plan.
local Layout={Width=364,Height=272}
function Layout.Build(viewWidth,viewHeight)
 local scale=math.min(viewWidth/900,viewHeight/585,2)
 scale=math.max(.45,math.min(scale,(viewWidth-24)/364,(viewHeight-32)/272))
 local function rect(x,y,w,h,r)return{X=x*scale,Y=y*scale,W=w*scale,H=h*scale,Radius=(r or 0)*scale}end
 return{Scale=scale,Width=364*scale,Height=272*scale,Columns=10,
  Sidebar=rect(12,70,30,181,11),Title=rect(44,25,177,19,9),Categories=rect(224,25,113,19,9),Favorite=rect(340,25,22,19,9),
  Body=rect(44,47,318,204,9),Grid=rect(47,49,312,200),Limit=rect(80,254,241,16,7),
  TitleText=rect(49,27,166,15),LimitText=rect(85,256,229,11),
  Cell=(312-9)/10*scale,Gap=scale,TitleSize=math.max(8,8*scale),SmallSize=math.max(7,6*scale),IconSize=18*scale,
 }
end
return Layout
