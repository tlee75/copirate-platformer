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
	use_animation = "consume"

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		if player_stats.is_eating:
			print("Already eating")
			return false
		player_stats.is_eating = true
		player_stats.set_hunger_regen_modifier(5)
		player_stats.start_eating(10)
		player_stats.start_drinking(1)
		
		# Store slot data for removal after animation finishes
		#pending_slot_data = slot_data
	else:
		print("no player stats")
		
