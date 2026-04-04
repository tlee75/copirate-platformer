extends GameItem
class_name OrangeFish

var hit_frames = {
	"consume": [4],
}
var player_stats: PlayerStats

func _init():
	name = "Orange Fish"
	icon = null  # TODO: load("res://assets/creatures/fish/fish_icon.png")
	stack_size = 10
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	is_cookable = true
	cook_time = 10.0
	cooked_result_item_name = "cooked_fish"
	primary_animation = "consume"
	description = "A live fish. Can be cooked for a meal."

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		player_stats.add_consumption_effect(1.0, 1.0, 0.0, 1)
	else:
		print("no player stats")
