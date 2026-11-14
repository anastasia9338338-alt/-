The standalone bundle is authoritative. These files mirror its GUI, frame and avatar PCLD controllers.

ShopLayout stores measurements from the compact 364x272 reference. GameShopStyle supports Folder/Frame page containers and streamed inventory controls, preserves the native collection and callbacks, and places decoration outside Contents. TextScaled and native layout overwrites cannot expand the compact header. White icon projections remain aligned with native button hit rectangles. Settings is outside the styled page. View replacement and unload remove decorations and observers.

PCLDAvatarESP copies source sizes 1:1 without ScaleTo or a detector-height multiplier. The visual Humanoid has simulation/scaling disabled, all geometry has guarded non-collision properties, and active cloned controllers are removed. The Main integration renders from the same frame as Box PCLD; no extra avatar render-step/filter is installed. Tests feed the actual Main motion handler and cover fake roots, changing detector dimensions, collision re-enabling, appearance, respawn and unload.

Frame codecs and controllers retain their v4.83 behavior. Codec tests use the exact Bootstrap table-return loader with EditableImage denied and independently compare PNG/JPEG data with Pillow. No live Roblox visual/physics validation is claimed.
