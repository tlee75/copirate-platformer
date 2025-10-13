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
			else:
				print("Tile is not diggable: ", tile_pos)
