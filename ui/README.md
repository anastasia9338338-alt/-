# Astral v5.03 reference GUI

The user-provided `message.txt` uses Obsidian. The standalone bundle now uses its compatible upstream renderers, with the reference window options and Astral's tab names and functionality. Source revision and constraints are recorded in `../transfers/README.md`.

`Library.luau` retains Astral's item images, configuration IDs, startup guard, settings panels, theme registry roles, custom artwork and disposal APIs. Stock Obsidian renderers replace the previous BetterOrion presentation. Existing GUI customization options remain connected to the new controls, including window alpha, slider track height and an optional thumb. The source default has no visible thumb.

`UIStyle.luau` holds the reference palette/window options. `GUIStyle.luau` preserves the user's optional customization layer without rolling back native control layout when fonts change. Native first show is explicit and synchronous; creating controls does not invoke gameplay callbacks. Closing the menu also hides Astral's settings panels. The control rail reserves consistent columns for keybind, activation and settings.

`GUIAppearance.luau` replaces the external-frame editor with a shared wallpaper gallery. The native full-window overlay has been removed: image surfaces sit below captions, follow their owner by property signals, and cover all tabs, the sidebar, watermark and registered floating panels. `BackgroundCatalog.luau` lists the two exact user photographs plus eight related winter wallpapers. `BackgroundAssets.luau` embeds their original JPEGs; `BackgroundStore.luau` decodes them lazily, yields between chunks and cleans temporary files on unload. Custom URLs retain the existing loader. The source and SHA-256 manifest is `background-sources.json`.

`NetworkTelemetry.luau` caches isolated Roblox round-trip latency for the HUD and kick settings. Conversion is seconds × 1000 as documented by the current Roblox Player:GetNetworkPing API. Replication Data Ping is not displayed as internet RTT. `Watermark.luau` retains its draggable position and uses the shared wallpaper/accent.

Build the entire transferred standalone revision with `python tools/build_transfer.py`. Verify it with `python tools/verify.py --luau-dir /path/to/official-luau-tools`. The real bundled window/control code runs in the UI harness. These are modeled API checks, not a live Roblox screenshot or a live executor test.
