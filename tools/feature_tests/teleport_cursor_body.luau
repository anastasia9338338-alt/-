local initial=root.CFrame
teleport();assert(calls==1 and canceled==0 and(tbl12.SlideTeleport.Goal-Vector3.new(14,8.7,-20)).Magnitude<.000001,'Z destination was not cursor point plus actual feet clearance')
assert(root.CFrame==initial,'Z performed an immediate root teleport')
mouse={TargetSurface='Right'};Vector3.FromNormalId=function()return Vector3.xAxis end
teleport();assert(math.abs(tbl12.SlideTeleport.Goal.X-16.35)<.00001,'Z landed inside clicked wall face');mouse=nil
focused=true;teleport();focused=false;flag11=true;teleport();flag11=false;h.Health=0;teleport();h.Health=100
target=nil;teleport();target=root;hit=nil;teleport()
assert(calls==2 and canceled==0,'Blocked Z action teleported or canceled ongoing motion')
print('PASS: actual Main Z callback routes cursor and feet clearance through shared smooth movement (mocked)')
