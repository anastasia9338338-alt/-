# Review of Astral v4.90

Baseline: v4.89 commit `eaa09ac58d4c0c62a2bdb336d9439612887043b3`.

Changed runtime: AntiGrabWalk, WalkingRig, AntiKickItems, FoodRemover, DestroyDesync, FreezePCLD, TargetPanel, Main integration and Bootstrap intro removal. LocalModels, Aqua/Sahur sources, UFOBlaster and Intro removed completely. The original notices are retained. GUI/shop/style/icons/watermark, avatar ESP and normal kick/Loop MS/pallet modules are byte-identical to the baseline.

Reviewed callers, actual sticky endpoints, native Hold/Drop argument shapes, attachment acknowledgements, ownership marker versus physics, exact-model Unstick exclusion, queued calls, plot waits, simultaneous AntiExplore/AntiGrab, seat handshake, cancellation, target selection, respawn and unload. Independent reviews found and resolved stale model blocking replacement, pre-IsHeld detection coverage, shared Humanoid state restoration, incomplete native Drop arguments and missing Food cancellation through TargetPanel.

The exact standalone file passed the repository verifier: all 87 executable modules and embedded gameplay compile; dependency/API checks cover 32 bound controllers; ZIP contains identical Lua bytes. New behavior checks include 1233 anti-grab/rig checks, 123 anti-kick attachment checks, 74 food protocol checks, 54 desync checks, 52 real FoodRemover/TargetPanel integration checks and 16 Freeze lifecycle checks, plus actual Main Unstick/discovery callbacks. Existing GUI, shop, avatar, kick, pallet, input and codec regressions pass.

Analyzer diagnostics across executable code were inspected. Changed modules introduce no new non-ambient diagnostics after normalizing inference placeholder IDs and shifted source lines; Roblox/executor globals are not supplied by the standalone analyzer. Missing definitions are not treated as proof of runtime errors.

The supplied script was read only. It contains no Freeze PCLD implementation. Freeze therefore keeps its existing mechanics with one reproduced stale-mover correction. The source-based kick verdict is in KICK_COMPARISON.md; no speculative kick speed tuning was applied.

No live Roblox server or executor was available. These tests establish code behavior under engine mocks, not immunity to other clients, server-side hit acceptance or a measured kick time.

Lua SHA-256: `cbf3b4d96b95b578a6c6c86a802eaade276dd763edb587820eb3f21bfc94c0f8`

ZIP SHA-256: `cb822c99c194f8dfaa1efba4239ff046acc47bee124c4e23897e2829cfe695cc`
