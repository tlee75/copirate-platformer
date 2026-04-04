extends GameItem
class_name CookedRaspberry

# Animation hit frame definition
var hit_frames = {
	"consume": [4], # List is required for single frames
}
var player_stats: PlayerStats

func _init():
	name = "Cooked Raspberry"
	icon = load("res://assets/consumables/cooked_raspberry_icon_01.png")
	stack_size = 99
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	primary_animation = "consume"

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		player_stats.add_consumption_effect(1.0, 1.0, 0.0, 5)
	else:
		print("no player stats")
