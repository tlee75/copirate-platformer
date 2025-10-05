extends GameItem
class_name SwordItem

# Animation hit frame definition
var hit_frames = {
	"attack": [8], # List is required for single frames
}

func action(user):
	print("Sword attack by %s" % user.name)
	user.is_trigger_action = true
	user.get_node("AnimatedSprite2D").play("attack")
	
	# Clean up any existing connections first
	var anim_sprite = user.get_node("AnimatedSprite2D")
	if anim_sprite.frame_changed.is_connected(user._on_attack_frame_changed):
		anim_sprite.frame_changed.disconnect(user._on_attack_frame_changed)
	if anim_sprite.animation_finished.is_connected(user._on_attack_animation_finished):
		anim_sprite.animation_finished.disconnect(user._on_attack_animation_finished)

	# Not sure if we need this
	if anim_sprite.animation_finished.is_connected(user._on_ground_animation_finished):
		anim_sprite.animation_finished.disconnect(user._on_ground_animation_finished)

	# Connect the frame changed to trigger the action on the correct frame
	anim_sprite.frame_changed.connect(user._on_attack_frame_changed)
	
	# Connect the animation_finished animation to end the animation state after the animation is done
	anim_sprite.animation_finished.connect(user._on_attack_animation_finished)
