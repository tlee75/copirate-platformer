extends GameItem
class_name ShovelItem

# Animation hit frame definition
var hit_frames = {
	"shovel_attack": [16, 35,58], # List is required for single frames
}

func action(player):
	print("Shovel attack by %s" % player.name)
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("shovel_attack")
	
	cleanup_connections(player) # Defined in base class
