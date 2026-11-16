# Review of Astral v4.92

Baseline: v4.91 commit `c72f4378cb6240a3a75064d84e171f82e854b48a`.

Changes: source Faster/Normal ownership scheduling in KickLoop, native paired pallet contact with physical fallback, exact finite source ownership request arguments in Main, source ring hold for multiple targets, Blobman rider grab and millisecond delay, legs-only Anti Explosion native dispatch with guard suspension, common confirmed holdable detachment, Anti Kick metadata/self-regrab correction and simplified main driver, cached shop layout and preview-aware structural traversal. The source attachment was read as data and not executed.

Review covered initial capture versus refresh, stale foreign markers, paired contact end/cleanup, frame and Loop MS bounds, target selection/protection changes, shared grab channel, actual source method caller wiring, both selected/server toggles, late acquisition, actual attachment endpoints, queued ownership cancellation after a genuine weld, both inventory folders, respawn/disable/unload, native Hold/Drop argument shapes, leg-only part selection and guard restoration, cached hidden-page geometry, native callbacks and registry cleanup.

Main.RemoveSticky is byte-identical to v4.91: no defensive toy exceptions were added to Unstick. Library, base UI style, icons, watermark, GUI customization, frame codecs, shop size/layout, QuickSpawn, Avatar PCLD and walking rig modules are unchanged. The shop UI source mirror matches its executable module.

The exact Lua and ZIP passed the required full verifier: 89 executable modules and embedded gameplay compile, 34 controller bindings checked, ZIP bytes equal standalone Lua. Checks include 3192 source Faster/Normal/capture/timing/lifecycle assertions, 622 paired source pallet contact assertions, 135 Anti Kick attachment/metadata/lifecycle assertions, 80 food/general holdable assertions, 34 source rider/legs/delay assertions, actual Main native ownership and legs-only dispatch, plus all previous UI/physics/codec/selection/cancellation suites. Shop fixtures pass 500 Folder and 506 Frame assertions, including no full collection scan/restyle on 50 counter updates, no cell reprocessing on warm page switches, hidden-menu reopen caching and no full invalidation for 100 streamed 3D preview meshes.

Standalone analyzer findings were inspected. Changed/new modules add no non-ambient findings except a Main CFrame:GetComponents numeric-inference diagnostic at math.abs(value), where Roblox supplies numbers and an explicit type(value)==number guard already precedes the call. The dynamic recursive T & number inference is not a runtime argument error. Missing Roblox/executor globals remain expected. No syntax/uninitialized-local or unresolved obfuscated-local diagnostics were accepted.

TheWorst Anti explosion has only a flag setter in the supplied version. The new explicit legs-only control therefore calls our native leg-removal method; it is not represented as a transplant of absent code. Normal is explicitly documented as source Stronger. No server immunity or measured disconnect time is claimed.

No live Roblox game/executor was available: tests establish mocked behavior and source invariants, not real server hit acceptance, successful kicks, immunity under another client’s aura, or measured FPS.

Lua SHA-256: `7c2d8833e074eaf047c7ab8308b130407d2693972849480b1b70302db37fe9fe`

ZIP SHA-256: `4ecd660d793a8f5af97c2cc8636539eb251fb97204a5a04d9c3af4ce22b44a02`
