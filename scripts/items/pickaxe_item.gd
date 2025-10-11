extends GameItem
class_name PickAxeItem

var hit_frames = {
	"pickaxe_attack": [26, 45]
}

func _init():
	name = "Pick Axe"
	icon = load("res://assets/sprite-man/pick_axe_icon_01.png")
	stack_size = 1
	craftable = true
	category = "tool"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 3}

func action(player):
	print("Pick Axe attack by %s" % player.name)
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("pickaxe_attack")
	
	cleanup_connections(player) # Defined in base class
