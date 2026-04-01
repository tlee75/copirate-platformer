extends GameItem
class_name Melee


# Animation hit frame definition
var hit_frames = {
	"punch": [4], # List is required for single frames
}

func _init():
	use_animation = "punch"
	target_action = "melee"
	name = "Melee"
	icon = load("res://assets/sprite-man/unarmed_icon_01.png")
	stack_size = 1
	craftable = false
	category = "unarmed"
	underwater_compatible = false
	land_compatible = true
	is_tool = true
	is_weapon = true
	harvest_efficiency = 0.3
	target_range = 40.0
	target_spread = 15.0
	droppable = false
