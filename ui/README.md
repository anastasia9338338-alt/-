# Astral / TheWorstUIV2

Astral v4.70 uses the actual TheWorstUIV2 renderer, embedded in the standalone
Lua. It does not start or hide a second Obsidian window.

Source: [m1kp0/libraries, a7ddb2ea](https://github.com/m1kp0/libraries/tree/a7ddb2ea8184bb5cc97b7f02c3270396e9b6e9cb/TheWorstUIV2).
The untouched upstream file is `vendor/TheWorstUIV2.upstream.lua`.
Its MIT license is preserved in `vendor/LICENSE` and in the bundled module.
The documented root download URL returns 404; the actual source is
`TheWorstUIV2/LibraryV2.lua`.

`prepare_vendor.py` applies reproducible integration patches: isolated GUI and
state, bundled icons, widget frame references, a readable horizontal tab strip,
independent section groups, search navigation, notification handles, native key
assignment with one Astral action dispatcher, and cancellation of UI work on
unload. It also repairs invalid enum accesses and malformed numeric input.
`Library.luau` adapts Astral's existing control API to these native widgets. `Presentation.luau` supplies white-glass surfaces, deterministic tab icons, compact sizing and shared popup styling. `Watermark.luau` displays the centered player/FPS/ping capsule.
Existing callbacks and setting IDs stay with Astral, including the embedded
features; old config and theme managers are retained.

Top-level tabs remain **Home, Player, Combat, Defense, Target, Blobman, Visual,
Aim, Fun, Settings**. The title/version bar is hidden. The tab strip is the drag handle; Settings → Menu → Hide Menu closes the visible window. Right Shift and the taskbar reopen it. Resizing is retained. Sections use the native grouped section UI with compact spacing and shared white-glass presentation.
Click a standalone section heading to collapse or expand it. Right-click a
binding field to cycle its mode; typing in an input does not activate gameplay
binds. Infinite Yield remains available under Home → Tools.

The old sidebar-width setting has no equivalent in a horizontal tab strip.
Stored active-function settings and key bindings retain their IDs and format;
cosmetic positions may need adjustment for the new window dimensions.

Build and verify:

```sh
python ui/prepare_vendor.py
python ui/build.py
python tools/verify.py --luau-dir /path/to/official-luau-tools --analysis-dir /tmp/astral-analysis
```

The GUI harness executes the actual embedded native library, adapter, existing
save manager and theme manager in a GUI-shaped mock engine. It checks callbacks,
multi-select/player values, nullable inputs, numeric bounds, key modes/modifiers,
dependencies, refreshes, notification updates, config round trips and unload.
This does not validate live Roblox rendering, input routing in a particular
executor, or gameplay/server effects.

Startup is deliberately manual. The old startup profile file is retained but
its active actions are not applied until the user selects Load. UI construction
suppresses action callbacks and input binds; repeated toggle values are
idempotent. Auto Reset/Leave/Anti Lag, Anti AFK and Disable Void start off, and
loading the script leaves the world's fallen-part threshold unchanged.
