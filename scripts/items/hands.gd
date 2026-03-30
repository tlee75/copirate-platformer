extends GameItem
class_name Hands

# Animation hit frame definition
var hit_frames = {
	"interact": [4], # List is required for single frames
}

func _init():
	name = "Hands"
	category = "unarmed"
	is_tool = true
	is_weapon = false
	target_action = "interact"
	use_animation = "interact"
	land_compatible = true
	underwater_compatible = true
	used_amount = 1
