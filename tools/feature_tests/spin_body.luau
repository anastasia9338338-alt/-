check(not spinInfo.Default and spinKey.Default == "None", "Spin starts active or has an action key")
spinInfo.Callback(false); spinInfo.Callback(true)
check(#movers == 0 and RunService.Heartbeat:Count() == 0, "Startup callback began spinning")
lib.Starting = false
spinInfo.Callback(false); spinInfo.Callback(false)
check(#movers == 0, "Disabling an inactive spin created a worker")
spinInfo.Callback(true); spinInfo.Callback(true)
check(#movers == 1 and movers[1].Parent == root and not humanoid.AutoRotate, "Spin did not attach to the living avatar")
check(RunService.Heartbeat:Count() == 1 and localPlayer.CharacterRemoving:Count() == 1, "Spin attached duplicate workers")
options.SpinS.Value = 31; RunService.Heartbeat:Fire()
check(movers[1].AngularVelocity.Y == 31, "Spin speed stopped updating")
spinInfo.Callback(false)
check(movers[1].Destroyed and humanoid.AutoRotate and root.AssemblyAngularVelocity.Y == 0, "Stopping spin left torque or disabled autorotation")
check(root.AssemblyAngularVelocity.X == 2 and root.AssemblyAngularVelocity.Z == 3, "Spin cleanup changed unrelated angular velocity")
check(RunService.Heartbeat:Count() == 0 and localPlayer.CharacterRemoving:Count() == 0, "Spin stop leaked listeners")
for _ = 1, 4 do spinInfo.Callback(true); spinInfo.Callback(false) end
spinInfo.Callback(true)
check(RunService.Heartbeat:Count() == 1, "Rapid off/on accumulated spin workers")
local oldCharacter, oldHumanoid, oldMover = character, humanoid, movers[#movers]
localPlayer.CharacterRemoving:Fire(character)
check(oldMover.Destroyed and oldHumanoid.AutoRotate, "Respawn left spin on the old avatar")
character, root, humanoid = nil, nil, nil
RunService.Heartbeat:Fire()
character, root, humanoid = avatar(false)
RunService.Heartbeat:Fire()
check(movers[#movers].Parent == root and not humanoid.AutoRotate, "Enabled spin did not resume on the new avatar")
local deadMover = movers[#movers]
humanoid.Health = 0; RunService.Heartbeat:Fire()
check(deadMover.Destroyed and not humanoid.AutoRotate, "Death failed cleanup or overwrote the original autorotate setting")
character, root, humanoid = avatar(true)
RunService.Heartbeat:Fire()
local finalMover = movers[#movers]
flag11 = true; lib.Unloaded = true
for _, callback in ipairs(lib.UnloadCallbacks) do callback() end
check(finalMover.Destroyed and humanoid.AutoRotate, "Unload left an active spin mover")
check(RunService.Heartbeat:Count() == 0 and localPlayer.CharacterRemoving:Count() == 0, "Unload leaked spin listeners")
local total = #movers
spinInfo.Callback(true); RunService.Heartbeat:Fire()
check(#movers == total, "Stale callback restarted spin after unload")
print("spin: " .. checks .. " lifecycle checks passed")
