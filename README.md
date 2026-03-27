How update_crosshair_targeting() works
The function runs every frame (called from update_cursor_position()). It's a priority cascade — each check returns early if a target is found, so higher priorities always win.

Priority flow (in order):
Priority	What it finds	Detection method	Function called
1.1	Attackable targets	Point query at cursor	get_attackable_at_position()
1.2	Interactable GameObjects	Point query at cursor	get_interactable_at_position() — needs is_interactable() == true
1.3	Tool targets (quick-access item)	Point query at cursor	get_tool_target_at_position() — needs tool_action in target_actions
2.1–2.3	Same three categories, but via spread raycasts from player	generic_raycast_targeting() with fan of angles	
Fallback	Nothing found	—	cursor_area follows mouse, all effects cleared
Three visual feedback paths:
1. Glow/hover effect (all GameObject targets)
Triggered by snap_crosshair_to_target() → set_hover_target(target) → calls target._on_hover_enter().
In object.gd, that tweens sprite_node.modulate to a colored tint (green for terrain, neutral for structures) and optionally scales up. When targeting changes, the previous target gets _on_hover_exit() to tween back to normal.

2. Crosshair + symbol (attack targets only)
set_crosshair_visibility(true/false) controls the Crosshair child of cursor_area. Shown only when target.is_attack_target() returns true. Hidden for all peaceful interactions (harvesting, interacting with structures, etc.).

3. Tile highlight (tile targets only)
When a Vector2i tile is targeted (e.g., shovel on diggable ground), snap_crosshair_to_tile() is called → update_tile_highlights_for_target() → create_tile_highlight_optimized() draws a colored overlay rectangle directly on the tilemap cell. Crosshair symbol is hidden; glow is not triggered.