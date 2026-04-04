extends GameItem
class_name CocoshellSeawater

var player_stats: PlayerStats

func _init():
	icon = load("res://assets/consumables/coconut_shell_seawater_64x64_1.png")
	stack_size = 10
	craftable = false
	category = "resource"
	underwater_compatible = false
	land_compatible = true
	is_cookable = true
	cook_time = 8.0
	cooked_result_item_name = "cooked_cocoshell_water"
	target_action = "pour"
	target_range = 50.0
	transform_result_item = "coconut_bowl"
