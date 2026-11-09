# Astral sidebar UI

v4.71 restores Astral's direct Obsidian-based renderer and original icon/item
presentation. The separate 52 px icon rail has no tab labels; an 8 px gap
separates it from the compact 660×570 slate window. Tab names and setting IDs
remain unchanged. Groups and rows have outlines; slider tracks and handles
have matching thickness. The old title/version label, bottom strip and native
TheWorstUIV2 taskbar are absent. Right Shift reopens a hidden menu.

`Library.luau` contains the complete renderer, with startup input guards,
idempotent toggle setters, the bounded sidebar layout, outlined card rows,
shared floating-panel styling and explicit listener cleanup. It derives from
the previously shipped Astral library; upstream source and notices remain in
the standalone bundle. `Watermark.luau` updates telemetry once a second and
never overwrites dragged or restored positions after installation.

The old TheWorstUIV2 vendor files, integration script and MIT notice are retained
as source history. `build.py` explicitly removes the executable TheWorstUIV2 and
Presentation modules from the bundle: no hidden alternate window is started.
The standalone script does not download a GUI library at runtime.

Build and verify:

```sh
python ui/build.py
python tools/verify.py --luau-dir /path/to/official-luau-tools --analysis-dir /tmp/astral-analysis
```

The verification suite executes the exact bundled native renderer in a GUI-shaped
mock, including startup defaults, explicit toggles, unbound Alt input, item
images, detached icon rail, draggable watermark and unload. Separate extracted
native-control tests cover slider geometry/input and concurrent hold bindings.
Main spin and defensive worker tests cover repeated toggles, respawn, cancellation
and unload. Old automatic action loading remains disabled; deliberate config
Load/Import is preserved. CLI/mocked results do not validate live Roblox rendering
or network latency.
