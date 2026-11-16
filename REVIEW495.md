# Review v4.95

Latest authorised scope: BetterOrion main GUI; previous Faster becomes Normal, faster refresh in Faster, additional Super Fast inspired by the provided video. Main presentation preference overrides the earlier icon-only rail. All other gameplay modules, shop, PCLD and watermark implementation are byte-identical to v4.94.

Changed executable modules: UIStyle, Library, GUIStyle, Main, Bootstrap, KickLoop and PalletRagdoll. BetterOrion was read as source/layout reference; the external library/loader was not executed or introduced as a runtime dependency. Original attribution/notices remain. Video was downloaded and inspected as frames, not continuously played; no hidden algorithm/server timer is inferred as fact.

Reviewed actual Main routes and settings callbacks, startup, defaults, migration/restore, keybinds, popouts/dropdowns, cancellation, mode switch, ownership loss, respawn and unload. Fixed migration to use the RGB setter for ColorPicker; retained intentional custom values. Source sliders use full-track input mapping, verified at a quarter-track touch point, and preserve numeric input. New style keeps all existing control IDs. Capture stores the presentation marker so old layouts do not restore the obsolete geometry.

Normal is compared event-for-event with the immutable v4.94 Faster implementation on five frame rates. Faster has one additional pair only in a separate after-physics callback, never catch-up bursts or a release before initial capture. Loop MS still schedules full cycles. Super Fast reuses one isolated owned pallet; real upward clearance after a solver frame is separate from placement/API calls. Existing game ragdoll must recover before another physical strike. Blocked/unowned/cancelled contacts are cleaned and never reported as successful kicks.

Exact final artifacts verified by:

```sh
python tools/verify.py --luau-dir /workspace/work/luau-bin --analysis-dir /workspace/work/fix495/analysis
```

Full verification exit code 0: 90 executable modules, embedded gameplay, 35 controller bindings, ZIP bytes equal Lua. Mode/baseline checks: 8549; Super Fast checks: 897; shared-pallet checks: 3521; old source spin/contact checks: 732; Loop MS checks: 24527. UI checks include settings, text sidebar/header, both columns, source row/checkbox/slider geometry, input, migration and unload. Additional quarter-track input check passes against the exact Library. No live engine/server rendering, kick acceptance or 4–6-second timing claim.

Analyzer differences were reviewed. Normalised diagnostics: {'Main': {}, 'Library': {}, 'UIStyle': {"(W0) UnknownType: Unknown type 'Color3'": 3}, 'GUIStyle': {}, 'KickLoop': {}, 'PalletRagdoll': {"(W0) TypeError: the function 'math.clamp' expects to get a number as its 1st argument, but is being given a T & number": 1}, 'Bootstrap': {}}. UIStyle UnknownType Color3 is missing CLI Roblox definitions; PalletRagdoll math.clamp intersection inference follows the runtime type/NaN check for the multiplier and is exercised in mocks. No new unresolved obfuscated locals, SyntaxError or UninitializedLocal. This is not a clean Roblox typecheck claim.

Lua SHA-256: `49e7665ab79439d4b4999dc8d2d40bd3088709fcf3ffe9c5a34fb917681d670b`
ZIP SHA-256: `e51633c871ea65e23a809d067365d8cc3376490621193dfdd034ae102b30f636`
