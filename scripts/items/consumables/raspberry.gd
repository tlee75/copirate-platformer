extends GameItem
class_name Raspberry

# Animation hit frame definition
var hit_frames = {
	"consumed": [4], # List is required for single frames
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
	craft_requirements = {"Gold Coin": 1}
	is_cookable = true
	cook_time = 2.0
	cooked_result_item_name = "cooked_raspberry"

func is_consumable() -> bool:
	return true

func action(player):	
	if player and player.player_stats:
		player_stats = player.player_stats
		if player_stats.is_eating:
			print("Already eating")
			return false
		player_stats.is_eating = true
		player_stats.set_hunger_regen_modifier(5)
		player_stats.start_eating(5)
		player_stats.start_drinking(5)
		player.is_trigger_action = true
		player.get_node("AnimatedSprite2D").play("consume")
	else:
		print("no player stats")
		return false
	
	cleanup_connections(player) # Defined in base class
	
	return true
