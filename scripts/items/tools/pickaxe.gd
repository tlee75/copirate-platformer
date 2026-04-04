extends GameItem
class_name PickAxe

var hit_frames = {
	"pickaxe_attack": [26, 45]
}

func _init():
	description = "A mining tool with a heavy metal head. Perfect for breaking stone and extracting minerals."
	icon = load("res://assets/sprite-man/pick_axe_icon_01.png")
	stack_size = 1
	craftable = true
	category = "tool"
	underwater_compatible = false
	land_compatible = true
	material_requirements = {"gold_coin": 3}
	craft_time = 5.0  # seconds to craft
	primary_animation = "pickaxe_attack"
	is_tool = true
	harvest_efficiency = 0.5
	target_action = "mine"
	
