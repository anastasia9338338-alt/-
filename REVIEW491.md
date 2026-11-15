# Review of v4.91 — Unstick rollback only

Baseline: v4.90 commit `3773f83f64b12ad5649fd0e169b1ebf412e22fc7`.

Removed the two defensive-item exceptions from Main.RemoveSticky and its explanatory UI tooltip. The exact function is byte-identical to v4.89. Aside from that change and version strings in Main/Bootstrap, every runtime module is unchanged from v4.90, including AntiKickItems. No new immunity or prevention behavior is claimed.

Reviewed connected-parts and inventory call paths. Updated the existing source-derived Unstick regression to require ordinary processing of registered as well as unregistered sticky toys. The exact bundle passes full verification: 87 executable modules, embedded gameplay, 32 controller bindings, existing behavior suites, and identical Lua inside ZIP. All executable analyzer diagnostics compared against v4.90 after normalizing shifted lines and inference IDs; no new diagnostics.

The user's primary requirement, continuous attachment under another client's Unstick Aura, remains unresolved. Available code sends SetNetworkOwner to a server-controlled handler; the source only demonstrates recovery after detachment. No verified prevention mechanism or server implementation was available, and a working protection snippet has been requested. Faster retry, local fake welds and local visibility are not treated as prevention.

No live Roblox validation was performed.

Lua SHA-256: `490dd9492dce97e0e1157b99c9a9f7ffd6b38c2dba17ac5e896662e7309bbc79`
