extends GameItem
class_name WoodAxe

# Animation hit frame definition
var hit_frames = {
	"woodaxe_attack": [4], # List is required for single frames
}

func _init():
	icon = load("res://assets/sprite-man/wood_axe_idle_02-64x64.png")
	stack_size = 1
	craftable = true
	category = "tool"
	underwater_compatible = false
	land_compatible = true
	material_requirements = {"simple_rock": 1, "stick": 1, "fiber": 1}
	craft_time = 5.0  # seconds to craft
	use_animation = "woodaxe_attack"
	is_tool = true
	is_weapon = true
	target_action = "chop"
	harvest_efficiency = 0.6
