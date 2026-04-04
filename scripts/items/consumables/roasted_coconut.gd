extends GameItem
class_name RoastedCoconut

var player_stats: PlayerStats

func _init():
	name = "Roasted Coconut"
	icon = load("res://assets/consumables/roasted_coconut_1.png")
	stack_size = 10
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	is_cookable = false
	cook_time = 8.0
	secondary_animation = "consume"

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		player_stats.add_consumption_effect(2.0, 0.0, 0.0, 10)
		player_stats.add_consumption_effect(0.0, 1.0, 0.0, 10)
	else:
		print("no player stats")
