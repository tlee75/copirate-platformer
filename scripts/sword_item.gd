extends GameItem
class_name SwordItem

func action(user):
	print("Sword attack by %s" % user.name)
	user.is_trigger_action = true
	user.get_node("AnimatedSprite2D").play("attack")
	
	# Clean up any existing connections first
	var anim_sprite = user.get_node("AnimatedSprite2D")
	if anim_sprite.animation_finished.is_connected(user._on_attack_animation_finished):
		anim_sprite.animation_finished.disconnect(user._on_attack_animation_finished)
	if anim_sprite.animation_finished.is_connected(user._on_ground_animation_finished):
		anim_sprite.animation_finished.disconnect(user._on_ground_animation_finished)

	# Connect the attack finished signal
	anim_sprite.animation_finished.connect(user._on_attack_animation_finished)
