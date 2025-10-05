extends GameItem
class_name RaspberryItem

# Animation hit frame definition
var hit_frames = {
	"consumed": [4], # List is required for single frames
}
var player_stats: PlayerStats

func is_consumable() -> bool:
	return true

func action(player):
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("consume")
	
	if player and player.player_stats:
		player_stats = player.player_stats
		player_stats.modify_health(10)
	else:
		print("no player stats")
	
	cleanup_connections(player) # Defined in base class
