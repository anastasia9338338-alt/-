The standalone bundle contains the actual runtime modules. These files mirror the GUI artwork, style, native shop and teleport controllers for review.

FrameArtwork handles client-side RGBA checker detection, transparency preservation and rounded external frame rasterization. GUIAppearance owns requests, previews, editable-image lifetime and sibling artwork for detached panels. GUIStyle exposes persisted font/text, function icons, dividers, slider and alpha controls. GameShopStyle reskins the existing MenuGui/Menu without replacing inventory logic or layout. TeleportMenu retains its travel/loop/respawn behavior and uses the current charcoal style.

EditableImage access is required for pixel processing. An unavailable API yields a rounded outline and status instead of drawing a checkerboard. Automated checks use Luau CLI and a mocked engine; no live Roblox visual validation is claimed.
