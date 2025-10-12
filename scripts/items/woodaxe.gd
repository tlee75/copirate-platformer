extends GameItem
class_name WoodAxe

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
	attack_animation = "woodaxe_attack"
	use_animation = "woodaxe_attack"
	damage = 1
	is_tool = true
