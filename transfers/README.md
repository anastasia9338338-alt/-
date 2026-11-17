# Source provenance and transfer review

Base: the user's `astral(6).zip`, containing `astral.lua` v5.00. The JSON manifest records the uploaded Lua SHA-256, every original module hash, and all literal control IDs. The archived source was not replaced with the older repository HEAD.

Reference: the user's `message.txt` (Shadow Core branding). Its GUI loads deividcomsono/Obsidian. This transfer bundles compatible upstream window/control renderers from commit `fb0b7b22604664ab94bea7c67e2a14ab1a47ec27`; it retains Astral's image and appearance extensions, initialization guards and disposal. Stock window, label, button, checkbox, toggle, input and slider code is used; the dropdown uses stock geometry with the user's item-picture and value-image support.

Transferred source operations:

- `message.txt` Ragdoll: eight stages between target HRP + (0,10000,0) and target HRP, velocity −9997 during descent, −10 at the endpoint, then return. `kick/ReferencePallet.luau` owns the real toy supply and uses independent solver frames. The source's leaked local loop flag and untracked late worker are replaced with cancellation predicates and shared resource ownership.
- `message.txt` Remove Anti Kick: nearby target inventory models within 5 studs of Torso/UpperTorso/HRP, excluding CreatureBlobman, TractorGreen, TractorRed and TractorOrange. Owner and native grab requests precede the 50 ms hold and native drop. `kick/ReferenceAntiKick.luau` serializes the channel and pairs cancellation with cleanup.
- The existing Normal ownership refresh is preserved. Faster and Super Fast use the same source trajectory with shorter complete-pass clocks. Super Fast no longer exits through the capture-only branch. Placement counters remain distinct from game-state confirmations and server results.

The uploaded base already contains its own prearmed walking rig, native food Hold/Drop protocol and underfoot lock. Those modules are unchanged. Their harnesses were updated to exercise their actual v5 APIs; removed Decoy and old inline Blobman helpers were not reintroduced to satisfy obsolete source-extraction checks.

Original user notices are preserved as the prefix of Notices. Obsidian's MIT notice remains intact. The ready-to-use Lua and matching ZIP are provided as `astral.lua` and `astral.zip` at the repository root.

v5.02 follows the user's subsequent requests: the frame editor is removed, wallpaper surfaces are shared across the window/HUD/panels, and ten winter JPEGs are bundled with byte hashes and source URLs in `ui/background-sources.json`. The first two are the user's exact Pinterest photographs. Seven old literal ID entries associated with the replaced editor (including its concatenated prefix) are the only exceptions to the preservation check. Source Normal/manual Ragdoll behavior is unchanged; Faster inherits v5.01 Super Fast, while Super Fast uses one physical contact frame and a separate exit, bounded by the existing contact-rate setting. HUD and optional kick timing use the current Roblox Player:GetNetworkPing isolated RTT rather than replication Data Ping.

v5.03 raises the requested Super Fast limit/default to 50 complete passes/s and makes continuous Loop Ragdoll follow that profile. Single-use Ragdoll and the Normal/Faster profiles retain their trajectories. Positive simulation steps gate contact/exit globally across the shared pallet; a single phase clock prevents multiple targets or repeated callbacks from multiplying the requested rate. Tests cover 260 simulation updates/s, jitter, rate changes, stale requests and 260 rendered frames with only 60 positive simulation steps/s. The existing network request cadence is unchanged. Legacy default 30/s migrates once; the saved AstralUI metadata records the cadence revision.
