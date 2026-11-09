held(true);advance(1)
assert(#escapeCalls==0 and #stickyCalls==0, "disabled features sent requests")
tbl8.FasterEscape=true;held(true);advance(1.01)
assert(#escapeCalls>=3 and #escapeCalls<=4, "escape did not preserve bounded retries")
for i=2,#escapeCalls do assert(escapeCalls[i]-escapeCalls[i-1]>=.25-1e-8,"escape retry followed render FPS")end
assert(unbound==2,"native actions were repeatedly unbound")
local before=#escapeCalls
tbl8.FasterEscape=false;advance(.3)
assert(#escapeCalls==before and not label.Visible,"escape kept sending after disabled")
tbl8.FasterEscape=true
for i=1,20 do held(false);held(true)end
before=#escapeCalls;advance(1)
assert(#escapeCalls-before<=4,"held sessions accumulated workers")
held(false);before=#escapeCalls;advance(.3)
assert(#escapeCalls==before and not label.Visible,"released session kept sending")

stickyCallback(true);advance(.51)
assert(#stickyCalls==5,"duplicate connected limbs repeated ownership requests")
assert(stickyCalls[1].Part~=stickyCalls[2].Part,"one attached toy starved the other")
for i=1,25 do stickyCallback(false);stickyCallback(true)end
before=#stickyCalls;advance(.51)
assert(#stickyCalls-before==5,"quick off/on accumulated sticky workers")
stickyCallback(false);before=#stickyCalls;advance(.5)
assert(#stickyCalls==before,"sticky defense sent after disabling")
stickyCallback(true);tbl8.FasterEscape=true;held(true);advance(.2)
local escaped,stuck=#escapeCalls,#stickyCalls
for _,callback in ipairs(unloads)do callback()end
for _,signal in ipairs(signals)do signal:Disconnect()end
advance(1)
assert(#escapeCalls==escaped and #stickyCalls==stuck,"defense worker sent after unload")
print("defense workers: bounded retries, unique toy requests, off/on and unload cleanup passed")
