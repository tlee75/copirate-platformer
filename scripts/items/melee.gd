extends GameItem
class_name Melee


# Animation hit frame definition
var hit_frames = {
	"punch": [7], # List is required for single frames
}

func _init():
	attack_animation = "punch"
	use_animation = "punch"
	name = "Melee"
	icon = load("res://assets/sprite-man/unarmed_icon_01.png")
	stack_size = 1
	craftable = false
	category = "unarmed"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 2}
	is_tool = false
	is_weapon = true
	damage = 1
