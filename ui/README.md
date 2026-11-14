The standalone bundle is authoritative. These files mirror its UI/frame controllers and vendored codecs.

GameShopStyle lays out only native inventory pages. Shared menu geometry is restored when leaving the inventory; Settings/HSV descendants are never traversed. Native button paths, callbacks and image assets are retained.

FrameImageFiles decodes local PNG/JPEG data, encodes a rounded RGBA frame as PNG, registers a normal custom asset and owns file lifetime. GUIAppearance accepts file URIs as well as native image content. Native EditableImage is only a fallback. PNGDecode/Inflate/CRC/Types are adapted Picguin sources with their full MIT notices. JPEGDecode retains the lua-img-ascii MIT notice and records Astral modifications.

The integration harness denies EditableImage; Pillow independently checks decoded pixels and encoded PNG output. Native GUI/game-shop behavior is exercised in an engine mock, not a live Roblox renderer.

Codec checks use the exact Bootstrap module loader, including its table-return contract. The PNG exports are wrapped as tables for this loader; decoding algorithms retain their upstream license notices.
