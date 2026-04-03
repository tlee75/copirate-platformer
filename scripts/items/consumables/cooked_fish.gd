extends GameItem
class_name CookedFish

var hit_frames = {
	"consume": [4],
}
var player_stats: PlayerStats

func _init():
	icon = load("res://assets/consumables/cooked_fish_filet_1.png")
	stack_size = 10
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	use_animation = "consume"
	description = "A nicely cooked fish. Restores hunger and some thirst."

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		player_stats.add_consumption_effect(3.0, 0.0, 0.0, 10)
	else:
		return false
		
