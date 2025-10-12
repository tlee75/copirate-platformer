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
	craft_requirements = {"Gold Coin": 1}
	use_animation = "consume"

func is_consumable() -> bool:
	return true

func extra_use_startup(player, slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		if player_stats.is_healing:
			print("Already healing")
			return false
		player_stats.is_healing = true
		player_stats.set_health_regen_modifier(5)
		player_stats.start_healing(10)
		
		# Store slot data for removal after animation finishes
		pending_slot_data = slot_data
	else:
		print("no player stats")
