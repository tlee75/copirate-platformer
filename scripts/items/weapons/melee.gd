# Bare handed weapon
extends GameItem
class_name Melee


# Animation hit frame definition
var hit_frames = {
	"punch": [4], # List is required for single frames
	"swim_punch": [2]
}

func _init():
	use_animation = "punch"
	target_action = "melee"
	icon = load("res://assets/sprite-man/unarmed_icon_01.png")
	stack_size = 1
	craftable = false
	category = "unarmed"
	underwater_compatible = true
	land_compatible = true
	is_tool = true
	is_weapon = true
	harvest_efficiency = 0.3
	target_range = 40.0
	target_spread = 15.0
	droppable = false
	blocks_movement = false

func get_use_animation(player) -> String:
	if player.is_underwater:
		return "swim_punch"
	return "punch"
