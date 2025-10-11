extends GameItem
class_name Shovel

# Animation hit frame definition
var hit_frames = {
	"shovel_attack": [16, 35,58], # List is required for single frames
}

func _init():
	name = "Shovel"
	icon = load("res://assets/sprite-man/shovel_icon_01.png")
	stack_size = 1
	craftable = true
	category = "tool"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 2}

func action(player):
	print("Shovel attack by %s" % player.name)
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("shovel_attack")
	
	cleanup_connections(player) # Defined in base class
