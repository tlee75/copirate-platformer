extends GameItem
class_name PickAxeItem

var hit_frames = {
	"pickaxe_attack": [26, 45]
}

func action(player):
	print("Pick Axe attack by %s" % player.name)
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("pickaxe_attack")
	
	cleanup_connections(player) # Defined in base class
