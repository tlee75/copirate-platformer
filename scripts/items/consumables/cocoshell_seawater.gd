extends GameItem
class_name CocoshellSeawater

var player_stats: PlayerStats

var hit_frames = {
	"consume": [4],
}

func _init():
	icon = load("res://assets/consumables/coconut_shell_seawater_64x64_1.png")
	stack_size = 10
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	is_cookable = true
	cook_time = 8.0
	cooked_result_item_name = "cooked_cocoshell_water"
	secondary_animation = "consume"
	target_action = "pour"
	target_range = 50.0
	transform_result_item = "coconut_bowl"

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	# Only apply drinking debuff when consuming solo (no target = drinking)
	if player.attack_target == null and player.player_stats:
		player_stats = player.player_stats
		player_stats.add_consumption_effect(0.0, -5.0, 0.0, 5)
