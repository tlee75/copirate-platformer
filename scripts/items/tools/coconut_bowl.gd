extends GameItem
class_name CoconutBowl

# Animation hit frame definition
var hit_frames = {
	"interact": [4], # List is required for single frames
}

func _init():
	name = "Coconut Bowl"
	icon = load("res://assets/tools/coconut_bowl_64x64_1.png")
	stack_size = 10
	craftable = true
	category = "tool"
	underwater_compatible = false
	land_compatible = true
	material_requirements = {"coconut": 1}
	craft_time = 5.0  # seconds to craft
	primary_animation = "interact"
	is_tool = true
	is_weapon = false
	harvest_efficiency = 1.0
	target_action = "fill"
	target_range = 50.0
	transform_result_item = "cocoshell_seawater"
