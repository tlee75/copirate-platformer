extends GameItem
class_name Sword

# Animation hit frame definition
var hit_frames = {
	"sword_attack": [8], # List is required for single frames
}

func _init():
	description = "A sharp steel blade. Effective in close combat with decent damage output."
	icon = load("res://assets/sprite-man/short_sword_icon_64x18.png")
	stack_size = 1
	craftable = true
	category = "weapon"
	underwater_compatible = false
	land_compatible = true
	material_requirements = {"gold_coin": 2}
	is_weapon = true
	target_range = 60.0
	target_spread = 12.0
	use_animation = "sword_attack"
	harvest_efficiency = 0.5
	target_action = "slice"
