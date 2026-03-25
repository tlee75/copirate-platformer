extends GameItem
class_name WoodAxe

# Animation hit frame definition
var hit_frames = {
	"woodaxe_attack": [4], # List is required for single frames
}

func _init():
	name = "Wood Axe"
	icon = load("res://assets/sprite-man/wood_axe_idle_02-64x64.png")
	stack_size = 1
	craftable = true
	category = "tool"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 3}
	craft_time = 5.0  # seconds to craft
	attack_animation = "woodaxe_attack"
	use_animation = "woodaxe_attack"
	damage = 1
	harvest_amount = 1
	is_tool = true
	tool_action = "chop"

func extra_use_cleanup(_player):
	var target = _player.attack_target
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target.has_method("on_harvest_complete"):
		target.on_harvest_complete()
