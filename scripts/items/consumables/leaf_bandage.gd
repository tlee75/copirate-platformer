extends GameItem
class_name LeafBandage

# Animation hit frame definition
var hit_frames = {
	"consumed": [4], # List is required for single frames
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

func is_consumable() -> bool:
	return true

func action(player):	
	if player and player.player_stats:
		player_stats = player.player_stats
		if player_stats.is_healing:
			print("Already healing")
			return false
		player_stats.is_healing = true
		player_stats.set_health_regen_modifier(5)
		player_stats.start_healing(10)
		player.is_trigger_action = true
		player.get_node("AnimatedSprite2D").play("consume")
	else:
		print("no player stats")
		return false
	
	cleanup_connections(player) # Defined in base class
	
	return true
