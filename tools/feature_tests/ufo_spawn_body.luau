local model=spawnBlasterToy('FlyingToyUfo',CFrame.new(),function()return valid end)
assert(model=='real-game-model'and now>=.7 and calls==1,'Temporary toy cooldown aborted blaster assembly')
markers.InPlot.Value=true;markers.InOwnedPlot.Value=false
assert(spawnBlasterToy('FlyingToyUfo',CFrame.new(),function()return true end)==nil and calls==1,'UFO spawned in another player plot')
markers.InPlot.Value=false;valid=false
assert(spawnBlasterToy('FlyingToyUfo',CFrame.new(),function()return valid end)==nil and calls==1,'Canceled preparation spawned UFO')
print('PASS: actual Main game-toy spawn cooldown, plot constraints and cancellation (mocked)')
