# Astral reference GUI

v4.72 follows the supplied reference with one continuous rounded surface.
The 44 px header, icon-only 52 px sidebar and body share the same outer frame;
there are no detached panels or gaps. Astral's original icon atlas and Fun icon
are retained. Search appears beside the brand. Flat section headings, 40 px
outlined rows and right-aligned square controls preserve the requested styling.

`UIMotion.luau` maintains a single render listener for pending drags and opacity
transitions. It sleeps when idle, accepts interrupted fades and cancels stale
moves when an external layout restore writes a position. A single CanvasGroup
opacity drives the menu; no per-descendant fade pass runs when it opens.
The watermark follows the header color and uses muted rich-text separators,
measured from its plain string so markup cannot inflate its width.

`Library.luau` contains the native renderer. `UIStyle` in the bundle is the
shared palette; `Watermark.luau` retains free dragging and once-per-second
telemetry. Popup gears move the original control holders, preserving option
IDs, callbacks, photos, values and dependency conditions. Opening a settings
panel never invokes the owning action. The owning toggle's visibility condition
is lifted only for its configuration; nested conditions are preserved.

Bindings and color swatches reserve a separate area beside the caption.
Button bindings share the original 40 px row. Panel owners restore shared
controls when destroyed, and panel listeners are disposed on owner destruction
and unload. Tab cleanup iterates the named tab dictionary and snapshots mutable
child collections; button addons are explicitly destroyed.

Build and verify:

```sh
python ui/build.py
python tools/verify.py --luau-dir /path/to/official-luau-tools --analysis-dir /tmp/astral-analysis
```

The native UI harness checks the real bundled rows, palette, integrated icon sidebar,
header, gears, control identity, binding layout, visibility and service-listener
cleanup. Extracted native slider tests cover geometry, mouse, touch and manual
numeric entry. Existing gameplay and startup checks remain unchanged. Browser
component previews help inspect the layout but do not replace a Roblox run.

The old vendor files and their MIT notice remain as source history. Build.py
removes the executable TheWorstUIV2 and Presentation modules; no alternate or
hidden GUI starts. The native renderer's upstream provenance and notices remain
in the standalone bundle. No GUI library is downloaded at runtime.
