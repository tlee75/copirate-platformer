extends GameItem
class_name RawFish

var hit_frames = {
	"consume": [4],
}
var player_stats: PlayerStats

func _init():
	name = "Raw Fish"
	icon = load("res://assets/consumables/raw_fish_filet_1.png")
	stack_size = 10
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	is_cookable = true
	cook_time = 12.0
	cooked_result_item_name = "cooked_fish"
	secondary_animation = "consume"
	description = "A raw fish. Cook it for a better meal."

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		player_stats.add_consumption_effect(1.0, 0.0, 0.0, 5)
	else:
		return false
