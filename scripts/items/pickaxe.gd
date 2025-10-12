extends GameItem
class_name PickAxe

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
	attack_animation = "pickaxe_attack"
	use_animation = "pickaxe_attack"
	damage = 1
	is_tool = true
