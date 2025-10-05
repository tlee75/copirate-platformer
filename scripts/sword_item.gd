extends GameItem
class_name SwordItem

# Animation hit frame definition
var hit_frames = {
	"attack": [8], # List is required for single frames
}

func action(player):
	print("Sword attack by %s" % player.name)
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("attack")
	
	cleanup_connections(player) # Defined in base class
