extends GameItem
class_name Sword

# Animation hit frame definition
var hit_frames = {
	"sword_attack": [8], # List is required for single frames
}

func _init():
	name = "Sword"
	description = "A sharp steel blade. Effective in close combat with decent damage output."
	icon = load("res://assets/sprite-man/short_sword_icon_64x18.png")
	stack_size = 1
	craftable = true
	category = "weapon"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 2}
	attack_animation = "sword_attack"
	damage = 1
	is_weapon = true
	target_range = 60.0
	target_spread = 12.0
	
