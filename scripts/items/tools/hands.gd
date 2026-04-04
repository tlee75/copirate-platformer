# Bare handed tool
extends GameItem
class_name Hands

# Animation hit frame definition
var hit_frames = {
	"interact": [4], # List is required for single frames
}

func _init():
	category = "unarmed"
	is_tool = true
	is_weapon = false
	target_action = "interact"
	primary_animation = "interact"
	land_compatible = true
	underwater_compatible = true
	harvest_efficiency = 1.0
	droppable = false

func handle_use_hit_frame(player, _anim, _frame):
	var target = player.attack_target
	if not target or typeof(target) != TYPE_OBJECT or not is_instance_valid(target):
		return
	if target is GameObject and target.has_method("interact") and target.is_interactable():
		target.interact()
	elif _is_target_compatible(target):
		target.activate_use(target_action, harvest_efficiency)
