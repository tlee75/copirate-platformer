extends GameItem
class_name WoodAxeItem

# Animation hit frame definition
var hit_frames = {
	"woodaxe_attack": [32, 55], # List is required for single frames
}

func _init():
	name = "Wood Axe"
	icon = load("res://assets/sprite-man/wood_axe_icon_01.png")
	stack_size = 1
	craftable = true
	category = "tool"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 3}

func action(player):
	print("Wood Axe attack by %s" % player.name)
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("woodaxe_attack")
	
	cleanup_connections(player) # Defined in base class
