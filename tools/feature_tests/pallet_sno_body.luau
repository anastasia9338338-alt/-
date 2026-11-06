local result
sim:Spawn(function()result=tbl12.SNO(part,.8,function()return allowed end,true)end)
check(result==nil,'Strict SNO returned on the old owner marker alone')
sim:Run(.4,240)
check(result==true and granted and requests==3 and not tbl7.States.Owning,'Strict SNO did not complete an active physical handoff')
local before=requests;granted=false
check(tbl12.SNO(part,.8,nil)==true and requests==before,'Legacy SNO changed behavior for unrelated callers')
requests=0;allowed=true;result=nil;tbl12.Grab=function()requests+=1 end
sim:Spawn(function()result=tbl12.SNO(part,.8,function()return allowed end,true)end)
sim:Run(.03,240);allowed=false;before=requests;sim:Run(.1,240)
check(result==false and requests==before and not tbl7.States.Owning,'Canceled strict SNO sent a late Grab or retained the ownership lock')
print('PASS: '..checks..' exact Main.SNO stale-marker, legacy and cancellation checks (mocked)')
