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
@export var is_tool = false
@export var is_weapon: bool = false
@export var damage: int = 0
@export var attack_animation = ""
@export var use_animation = ""


func is_consumable() -> bool:
	return false

# Need to add a extensible function here that individual item scripts can extend to do one time stuff
func attack(player, target):
	if attack_animation == "" or attack_animation == null:
		print("WARNING: Item '%s' has no attack_animation set!" % self.name)
		return
	# Store the target for use in the hit frame callback
	player.attack_target = target
	player.is_trigger_action = true
	var anim_sprite = player.get_node("AnimatedSprite2D")
	anim_sprite.play(attack_animation)
	extra_attack_startup(player)
	cleanup_connections(player)
	anim_sprite.frame_changed.connect(_on_attack_frame_changed.bind(player))
	anim_sprite.animation_finished.connect(_on_attack_animation_finished.bind(player))


# Need to add a extensible function here that individual item scripts can extend to do one time stuff
func use(player, target):
	if use_animation == "" or use_animation == null:
		print("WARNING: Item '%s' has no use_animation set!" % self.name)
		return
	if target:
		player.attack_target = target
	player.is_trigger_action = true
	var anim_sprite = player.get_node("AnimatedSprite2D")
	anim_sprite.play(use_animation)
	extra_use_startup(player)
	cleanup_connections(player)
	anim_sprite.frame_changed.connect(_on_use_frame_changed.bind(player))
	anim_sprite.animation_finished.connect(_on_use_animation_finished.bind(player))


func handle_attack_frame(player, anim, frame):
	print("%s attack by %s with animation %s on frame %s" % [self.name, player.name, anim, frame])
	var target = player.attack_target
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	else:
		# No target: play swing sound, animation, or feedback
		print("%s swing: no target hit" % self.name)

func _on_attack_frame_changed(player):
	var anim_sprite = player.get_node("AnimatedSprite2D")
	var anim = anim_sprite.animation
	var frame = anim_sprite.frame
	if anim in self.hit_frames and frame in self.hit_frames[anim]:
		handle_attack_frame(player, anim, frame)

func _on_attack_animation_finished(player):
	player.is_trigger_action = false
	player.attack_target = null
	extra_attack_cleanup(player)
	cleanup_connections(player)

func _on_use_frame_changed(player):
	var anim_sprite = player.get_node("AnimatedSprite2D")
	var anim = anim_sprite.animation
	if "hit_frames" in self and anim in self.hit_frames:
		handle_use_frame(player, anim, anim_sprite.frame)
	else:
		print("WARNING: animation ", anim, "not found in hit_frames keys: ", self.hit_frames.keys())
			

func handle_use_frame(player, _anim, _frame):
	print("%s used by %s" % [self.name, player.name])


func _on_use_animation_finished(player):
	player.is_trigger_action = false
	player.attack_target = null
	extra_use_cleanup(player)
	cleanup_connections(player)

func extra_attack_startup(_player):
	pass

func extra_use_startup(_player):
	pass

func extra_attack_cleanup(_player):
	pass

func extra_use_cleanup(_player):
	pass

func cleanup_connections(user):
	var anim_sprite = user.get_node("AnimatedSprite2D")
	if anim_sprite.frame_changed.is_connected(Callable(self, "_on_attack_frame_changed")):
		anim_sprite.frame_changed.disconnect(Callable(self, "_on_attack_frame_changed"))
	if anim_sprite.frame_changed.is_connected(Callable(self, "_on_use_frame_changed")):
		anim_sprite.frame_changed.disconnect(Callable(self, "_on_use_frame_changed"))
	if anim_sprite.animation_finished.is_connected(Callable(self, "_on_attack_animation_finished")):
		anim_sprite.animation_finished.disconnect(Callable(self, "_on_attack_animation_finished"))
	if anim_sprite.animation_finished.is_connected(Callable(self, "_on_use_animation_finished")):
		anim_sprite.animation_finished.disconnect(Callable(self, "_on_use_animation_finished"))
