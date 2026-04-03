extends GameItem
class_name Coconut

var player_stats: PlayerStats

func _init():
	name = "Coconut"
	icon = load("res://assets/consumables/raw_coconut_1.png")
	stack_size = 10
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	is_cookable = true
	cook_time = 8.0
	cooked_result_item_name = "roasted_coconut"
	use_animation = "consume"

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		player_stats.add_consumption_effect(10.0, 0.0, 0.0, 1)
		player_stats.add_consumption_effect(0.0, 2.0, 0.0, 5)
	else:
		print("no player stats")
