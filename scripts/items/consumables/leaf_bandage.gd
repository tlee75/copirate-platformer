extends GameItem
class_name LeafBandage

# Animation hit frame definition
var hit_frames = {
	"consume": [4], # List is required for single frames
}
var player_stats: PlayerStats

func _init():
	name = "Leaf Bandage"
	icon = load("res://assets/consumables/leaf_bandage_01_16x18.png")
	stack_size = 99
	craftable = true
	category = "consumable"
	underwater_compatible = false
	land_compatible = true
	material_requirements = {"gold_coin": 1}
	use_animation = "consume"
	craft_time = 5

func is_consumable() -> bool:
	return true

func extra_use_startup(player, _slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		player_stats.add_consumption_effect(0.0, 0.0, 2.0, 10)
	else:
		print("no player stats")
