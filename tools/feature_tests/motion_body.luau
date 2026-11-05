
local checks=0
local function check(v,message)assert(v,message);checks+=1 end
for _,fps in ipairs({30,60,120,240,480,1000})do
    local state=Motion.New(CFrame.new(),0);local nextSample=0;local last
    for i=1,fps*2 do
        local now=i/fps
        if now+1e-8>=nextSample then Motion.Sample(state,CFrame.new(now*16,0,0),now);nextSample=now+.05 end
        local frame=Motion.Step(state,now,1/fps)
        check(frame.Position.X==frame.Position.X,'NaN output')
        check(frame.Position.X<=state.Target.Position.X+2.001,'Prediction exceeded bounded lead')
        if last then check(frame.Position.X>=last-.001,'Constant forward motion reversed')end
        if now>1 then check(now*16-frame.Position.X<1.6,'Filtering trails the sampled motion too far')end
        last=frame.Position.X
    end
    Motion.Sample(state,CFrame.new(1000,15,0),2.1)
    local frame=Motion.Step(state,2.1,1/fps)
    check((frame.Position-Vector3.new(1000,15,0)).Magnitude<.001,'Teleport eased across map')
    local moving
    for i=1,fps do frame,moving=Motion.Step(state,2.1+i/fps,1/fps)end
    check(not moving,'Stationary detector kept render connection active')
    check(not Motion.Sample(state,CFrame.new(0/0,0,0),4),'Nonfinite sample accepted')
end
print('PASS: '..checks..' native ESP motion bounds, FPS, teleport and rest checks')
