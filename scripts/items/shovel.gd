extends GameItem
class_name Shovel

# Tile source IDs and atlas coordinates for replacement tiles
const SURFACE_WATER_SOURCE_ID = 11
const SURFACE_WATER_X = 0
const SURFACE_WATER_Y = 0

const UNDERWATER_SOURCE_ID = 12
const UNDERWATER_X = 0
const UNDERWATER_Y = 0

const DIRT_HOLE_SOURCE_ID = 1
const DIRT_HOLE_X = 0
const DIRT_HOLE_Y = 0

# Animation hit frame definition
var hit_frames = {
	"shovel_attack": [16, 35,58], # List is required for single frames
}

func _init():
	name = "Shovel"
	icon = load("res://assets/sprite-man/shovel_icon_01.png")
	stack_size = 1
	craftable = true
	category = "tool"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 2}
	is_digging_tool = true


# shovel.gd

func action(player):
	# Get the tile under the cursor
	var tile_pos = player.get_tiles_in_cursor_area()[0]
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("shovel_attack")
	
	# Disconnect previous connections to avoid duplicates
	player.cleanup_player_connections()
	
	# Store the tile position for use in the frame handler
	player.attack_target = tile_pos
	
	# Connect to frame_changed to handle dig on hit frame
	player.get_node("AnimatedSprite2D").frame_changed.connect(_on_shovel_attack_frame_changed.bind(player))
	player.get_node("AnimatedSprite2D").animation_finished.connect(_on_shovel_attack_animation_finished.bind(player))

func _on_shovel_attack_frame_changed(player):
	var anim_sprite = player.get_node("AnimatedSprite2D")
	var anim = anim_sprite.animation
	var frame = anim_sprite.frame
	
	if anim in self.hit_frames and frame in self.hit_frames[anim]:
		var tilemap = player.tilemap
		var tile_pos = player.attack_target
		var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
		if tile_data and tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable"):
			var replacement = get_replacement_tile_for_dig(tilemap, tile_pos)
			tilemap.set_cell(0, tile_pos, replacement["source_id"], replacement["atlas_coords"])
			var dig_item_key = "dirt"
			if tile_data.has_custom_data("dig_item"):
				dig_item_key = tile_data.get_custom_data("dig_item")
			player.add_loot(dig_item_key, 1)
			print("Dug up ", dig_item_key, " at: ", tile_pos)
		# Disconnect after performing the action
		if anim_sprite.frame_changed.is_connected(_on_shovel_attack_frame_changed):
			anim_sprite.frame_changed.disconnect(_on_shovel_attack_frame_changed)

func _on_shovel_attack_animation_finished(player):
	player.is_trigger_action = false
	player.attack_target = null
	if player.get_node("AnimatedSprite2D").animation_finished.is_connected(_on_shovel_attack_animation_finished):
		player.get_node("AnimatedSprite2D").animation_finished.disconnect(_on_shovel_attack_animation_finished)

#func action(player):
	#print("Shovel attack by %s" % player.name)
	#player.is_trigger_action = true
	#player.get_node("AnimatedSprite2D").play("shovel_attack")
	#
	#cleanup_connections(player) # Defined in base class


#func action(player):
	## Get the tilemap and cursor position from the player
	#var tilemap = player.tilemap
	#var cursor_area = player.cursor_area
	#var tile_pos = tilemap.local_to_map(cursor_area.global_position)
	#
	## Determine which item to drop and which tile to place
	#var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
	#if tile_data and tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable"):
		## Determine replacement tile
		#var replacement = get_replacement_tile_for_dig(tilemap, tile_pos)
		#tilemap.set_cell(0, tile_pos, replacement["source_id"], replacement["atlas_coords"])
		#
		## Determine item to drop
		#var dig_item_key = "dirt"  # Default fallback
		#if tile_data.has_custom_data("dig_item"):
			#dig_item_key = tile_data.get_custom_data("dig_item")
		#InventoryManager.add_item(InventoryManager.item_database[dig_item_key], 1)
		#print("Dug up ", dig_item_key, " at: ", tile_pos)
		#return true
	#
	## If not diggable, fallback to shovel attack animation
	#player.is_trigger_action = true
	#player.get_node("AnimatedSprite2D").play("shovel_attack")
	#cleanup_connections(player)
	#return false

# Helper function for tile replacement logic
func get_replacement_tile_for_dig(tilemap, tile_pos: Vector2i) -> Dictionary:
	var above_pos = tile_pos + Vector2i(0, -1)
	var left_pos = tile_pos + Vector2i(-1, 0)
	var right_pos = tile_pos + Vector2i(1, 0)
	
	var above_data = tilemap.get_cell_tile_data(0, above_pos)
	var left_data = tilemap.get_cell_tile_data(0, left_pos)
	var right_data = tilemap.get_cell_tile_data(0, right_pos)
	
	# Check above for water
	if above_data and above_data.has_custom_data("is_water") and above_data.get_custom_data("is_water"):
		return {"source_id": UNDERWATER_SOURCE_ID, "atlas_coords": Vector2i(UNDERWATER_X, UNDERWATER_Y)}
	
	# Check left/right for water
	for adj_data in [left_data, right_data]:
		if adj_data and adj_data.has_custom_data("is_water") and adj_data.get_custom_data("is_water"):
			if adj_data.has_custom_data("water_type") and adj_data.get_custom_data("water_type") == "surface":
				return {"source_id": SURFACE_WATER_SOURCE_ID, "atlas_coords": Vector2i(SURFACE_WATER_X, SURFACE_WATER_Y)}
			else:
				return {"source_id": UNDERWATER_SOURCE_ID, "atlas_coords": Vector2i(UNDERWATER_X, UNDERWATER_Y)}
	
	# Default to dirt_hole if no water found
	return {"source_id": DIRT_HOLE_SOURCE_ID, "atlas_coords": Vector2i(DIRT_HOLE_X, DIRT_HOLE_Y)}
