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
	craft_requirements = {"Gold Coin": 1}
	is_cookable = true
	cook_time = 2.0
	cooked_result_item_name = "cooked_raspberry"
	use_animation = "consume"

func is_consumable() -> bool:
	return true

# This needs changed so some of this only happens ONCE upon the initial use, and the actual 'moment' that needs
# timed up with a frame happens here. We may need to add a 'use setup' function that happens once, when the initial use function is triggered
func handle_use_frame(player, _anim, _frame):
	if player and player.player_stats:
		player_stats = player.player_stats
		if player_stats.is_eating:
			print("Already eating")
			return false
		print("raspberry eating")
		player_stats.is_eating = true
		player_stats.set_hunger_regen_modifier(5)
		player_stats.start_eating(5)
		player_stats.start_drinking(5)
		player.is_trigger_action = true
		player.get_node("AnimatedSprite2D").play("consume")
	else:
		print("no player stats")
		return false

#func action(player):	
	#if player and player.player_stats:
		#player_stats = player.player_stats
		#if player_stats.is_eating:
			#print("Already eating")
			#return false
		#player_stats.is_eating = true
		#player_stats.set_hunger_regen_modifier(5)
		#player_stats.start_eating(5)
		#player_stats.start_drinking(5)
		#player.is_trigger_action = true
		#player.get_node("AnimatedSprite2D").play("consume")
	#else:
		#print("no player stats")
		#return false
	#
	#cleanup_connections(player) # Defined in base class
	#
	#return true
