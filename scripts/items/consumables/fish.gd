extends GameItem
class_name FishItem

var hit_frames = {
	"consume": [4],
}
var player_stats: PlayerStats

func _init():
	name = "Fish"
	icon = null  # TODO: load("res://assets/creatures/fish/fish_icon.png")
	stack_size = 10
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	is_cookable = true
	cook_time = 10.0
	cooked_result_item_name = "cooked_fish"
	use_animation = "consume"
	description = "A live fish. Can be cooked for a meal."

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		if player_stats.is_eating:
			return false
		player_stats.is_eating = true
		player_stats.set_hunger_regen_modifier(3)
		player_stats.start_eating(3)
