extends Resource

class_name GameItem

@export var name: String
@export var icon: Texture2D
@export var stack_size: int = 1
@export var craftable: bool = false
@export var category: String = ""
@export var craft_requirements: Dictionary = {}
@export var underwater_compatible: bool = false
@export var land_compatible: bool = true
@export var is_cookable: bool = false
@export var cook_time: float = 0.0  # Time in seconds to cook
@export var cooked_result_item_name: String = ""  # What this item becomes when cooked
@export var is_digging_tool = false

func is_consumable() -> bool:
	return false

func cleanup_connections(user):
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
