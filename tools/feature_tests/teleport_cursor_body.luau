teleport();assert(calls==1 and canceled==1 and(root.Position-Vector3.new(14,10.5,-20)).Magnitude<.000001,'Z destination was not hit CFrame plus avatar clearance')
assert(tbl12.CharacterTools.LockPoint==root.Position,'Z did not update active position lock')
focused=true;teleport();focused=false;flag11=true;teleport();flag11=false;h.Health=0;teleport();h.Health=100
target=nil;teleport();target=root;hit=nil;teleport()
assert(calls==1 and canceled==1,'Blocked Z action teleported or canceled ongoing motion')
print('PASS: actual Main Z callback, cursor CFrame, lock synchronization, focus and lifecycle checks (mocked)')
