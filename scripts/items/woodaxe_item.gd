extends GameItem
class_name WoodAxeItem

# Animation hit frame definition
var hit_frames = {
	"woodaxe_attack": [32, 55], # List is required for single frames
}

func action(player):
	print("Wood Axe attack by %s" % player.name)
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("woodaxe_attack")
	
	cleanup_connections(player) # Defined in base class
