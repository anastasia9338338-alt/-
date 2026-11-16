# Review of Astral v4.93

Baseline: v4.92 commit `87abcd44dd6edc1516ec4e18fff7d60abc433cad`.

Scope: KickLoop, PalletRagdoll, GameShopStyle, Main integration and Bootstrap version strings. Other executable modules are byte-identical to v4.92. The exact shop UI mirror equals its executable module. Theme, window bounds, icons, watermark, avatar ESP and unrelated defense features remain unchanged.

Physics review found three coupled implementation problems: source touch requests targeted the parked board/HRP instead of using a real receiver crossing; the holding path disabled WeldHRP and compensated by teleporting/zeroing ragdoll parts every update; ownership refresh began immediately after marker capture before the body reached its holding destination. The primary path now uses the physical worker, preserves native rig/mass, centers a single target overhead and waits for observed physical holding before refresh release. A drifting held target keeps its goal while release is paused and a missing marker is reacquired at the preexisting retry interval.

The physical worker has an optional initial isolated contact for genuine captured targets before they are airborne, avoiding a circular first-ragdoll/hold prerequisite. Subsequent bursts require physical hold. Delayed actual Ragdolled edges are observed before another isolated retry. Staging inherits actual receiver velocity while preserving relative sweep caps and explicit separation. The shared native channel is reserved only across stage/entry/exit, not pulse/rate waits; return/error/cancel/dispose clear it. No local hit is called a server kick acknowledgement.

Review covered Main callers, original one-shot behavior, ownership loss and native metadata, selection/protection changes, late collider creation/restoration, native joints and current physical properties, cancelled startup and live hold promotion, moving-receiver staging, narrow channel reservation, errors/respawn/unload, native item overwrite and structural streaming, page cache, original callbacks and GUI/registry cleanup. Independent read-only review was used for physics; separate agents owned pallet and shop changes.

Shop repairs restore only changed recorded properties through a coalesced queue. A cell's late native Size/UIScale/aspect/min constraints no longer survive merely because its style dimensions were cached. Layout/canvas/hover overwrites avoid full page Find/repaint. Dead own artwork labels are excluded from native footer discovery, fixing stale cached 5/100 readings. Observers and pending work are cleared on detach/unload.

The exact final standalone Lua/ZIP passed the required full verifier: 89 executable modules, embedded gameplay, 34 controller bindings and byte-identical Lua inside ZIP. This includes 3284 source timing/selection/physical-settle/drift recovery assertions, 11 actual Main physical-route/native-rig/mass/late-collider/shared-channel checks, the physical sweep/gravity/pulse/startup/moving-frame/cancellation suites, and 515 Folder / 521 Frame native shop assertions. Existing anti-grab/defense, PNG/JPEG, PCLD, Loop MS and input/UI suites pass.

Analyzer findings were inspected. Main/KickLoop/PalletRagdoll introduce no new nonambient diagnostics after normalizing shifted source lines and inference IDs. Shop adds two harmless LocalShadow diagnostics for lexically scoped records in loops; no unresolved callback or runtime argument issue was found. Existing ambient Roblox/executor globals and prior inference limitations remain documented; syntax/uninitialized-local failures are not accepted.

Source action batches, native request clock, contact-rate defaults, relative sweep caps and pulse speed settings were not increased. State gating and physical implementation changed. The later user clarification permits speed changes but does not require unsupported numerical acceleration.

No live Roblox/executor was available. These source/mocked checks do not establish a successful server disconnect in under 10 seconds or measured FPS; the game-specific result remains unmeasured.

Lua SHA-256: `096ee2b39a806e792db4ae60548b18c15107ddb856edddf800718fa5e4519398`

ZIP SHA-256: `722b013587a0f92fdfe3482f2e263b586bcdf7d382ca1ab86d8db6e864d90a41`
