# Astral v5.01 reference GUI

The user-provided `message.txt` uses Obsidian. The standalone bundle now uses its compatible upstream renderers, with the reference window options and Astral's tab names and functionality. Source revision and constraints are recorded in `../transfers/README.md`.

`Library.luau` retains Astral's item images, configuration IDs, startup guard, settings panels, theme registry roles, custom artwork and disposal APIs. Stock Obsidian renderers replace the previous BetterOrion presentation. Existing GUI customization options remain connected to the new controls, including window alpha, slider track height and an optional thumb. The source default has no visible thumb.

`UIStyle.luau` holds the reference palette/window options. `GUIStyle.luau` preserves the user's optional customization layer. `UIMotion.luau` and `Watermark.luau` are unchanged from the uploaded base. Native first show is explicit and synchronous; creating controls does not invoke gameplay callbacks. Closing the menu also hides Astral's settings panels.

Build the entire transferred standalone revision with `python tools/build_transfer.py`. Verify it with `python tools/verify.py --luau-dir /path/to/official-luau-tools`. The real bundled window/control code runs in the UI harness. These are modeled API checks, not a live Roblox screenshot or a live executor test.
