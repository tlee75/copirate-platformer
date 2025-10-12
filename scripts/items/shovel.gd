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
	attack_animation = "shovel_attack"
	use_animation = "shovel_attack"
	name = "Shovel"
	icon = load("res://assets/sprite-man/shovel_icon_01.png")
	stack_size = 1
	craftable = true
	category = "tool"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 2}
	is_tool = true
	damage = 1

func handle_use_frame(player, anim, frame):
	handle_attack_frame(player, anim, frame)

func handle_attack_frame(player, anim, frame):
	var target = player.attack_target
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	elif typeof(target) == TYPE_VECTOR2I:
		var hit_frame_list = self.hit_frames.get(anim, [])
		if hit_frame_list.size() > 0 and frame == hit_frame_list[-1]:
			var tilemap = player.tilemap
			var tile_pos = target
			var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
			if tile_data and tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable"):
				# Always replace with dirt hole immediately (instant feedback)
				tilemap.set_cell(0, tile_pos, DIRT_HOLE_SOURCE_ID, Vector2i(DIRT_HOLE_X, DIRT_HOLE_Y))
				
				# Get loot
				var dig_item_key = "dirt"
				if tile_data.has_custom_data("dig_item"):
					dig_item_key = tile_data.get_custom_data("dig_item")
				player.add_loot(dig_item_key, 1)
				print("Dug up ", dig_item_key, " at: ", tile_pos)
				
				# Register with water flow system
				var water_flow_manager = player.get_tree().current_scene.get_node_or_null("WaterFlowManager")
				if water_flow_manager:
					water_flow_manager.register_dug_tile(tile_pos)
				else:
					push_error("Shovel: Could not find WaterFlowManager in scene")
			#if tile_data and tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable"):
				#var replacement = get_replacement_tile_for_dig(tilemap, tile_pos)
				#tilemap.set_cell(0, tile_pos, replacement["source_id"], replacement["atlas_coords"])
				#var dig_item_key = "dirt"
				#if tile_data.has_custom_data("dig_item"):
					#dig_item_key = tile_data.get_custom_data("dig_item")
				#player.add_loot(dig_item_key, 1)
				#print("Dug up ", dig_item_key, " at: ", tile_pos)
			else:
				print("Tile is not diggable: ", tile_pos)


## Helper function for tile replacement logic
#func get_replacement_tile_for_dig(tilemap, tile_pos: Vector2i) -> Dictionary:
	#var above_pos = tile_pos + Vector2i(0, -1)
	#var left_pos = tile_pos + Vector2i(-1, 0)
	#var right_pos = tile_pos + Vector2i(1, 0)
	#
	#var above_data = tilemap.get_cell_tile_data(0, above_pos)
	#var left_data = tilemap.get_cell_tile_data(0, left_pos)
	#var right_data = tilemap.get_cell_tile_data(0, right_pos)
	#
	## Check above for water
	#if above_data and above_data.has_custom_data("is_water") and above_data.get_custom_data("is_water"):
		#return {"source_id": UNDERWATER_SOURCE_ID, "atlas_coords": Vector2i(UNDERWATER_X, UNDERWATER_Y)}
	#
	## Check left/right for water
	#for adj_data in [left_data, right_data]:
		#if adj_data and adj_data.has_custom_data("is_water") and adj_data.get_custom_data("is_water"):
			#if adj_data.has_custom_data("water_type") and adj_data.get_custom_data("water_type") == "surface":
				#return {"source_id": SURFACE_WATER_SOURCE_ID, "atlas_coords": Vector2i(SURFACE_WATER_X, SURFACE_WATER_Y)}
			#else:
				#return {"source_id": UNDERWATER_SOURCE_ID, "atlas_coords": Vector2i(UNDERWATER_X, UNDERWATER_Y)}
	#
	## Default to dirt_hole if no water found
	#return {"source_id": DIRT_HOLE_SOURCE_ID, "atlas_coords": Vector2i(DIRT_HOLE_X, DIRT_HOLE_Y)}
