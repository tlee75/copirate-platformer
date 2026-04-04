extends GameItem
class_name Raspberry

# Animation hit frame definition
var hit_frames = {
	"consume": [4], # List is required for single frames
}
var player_stats: PlayerStats

func _init():
	name = "Raspberry"
	icon = load("res://assets/consumables/raspberry_icon_01.png")
	stack_size = 99
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	is_cookable = true
	cook_time = 8.0
	cooked_result_item_name = "cooked_raspberry"
	secondary_animation = "consume"

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		player_stats.add_consumption_effect(0.2, 0.4, 0.0, 10) # 0.2 hunger and 0.4 thirst per tick, over 5 seconds
	else:
		print("no player stats")
