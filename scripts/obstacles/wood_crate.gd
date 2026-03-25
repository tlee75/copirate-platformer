extends StaticBody2D

# Breakable object that can be destroyed by player attacks
var object_name = "Wood Crate"

# Object states
enum ObjectState { INTACT, DAMAGED, DESTROYED }
var state: int = ObjectState.INTACT

@export var max_health: int = 3
var health: int = max_health

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Cooldown to prevent multiple hits from same attack
@export var hit_cooldown_time: float = 0.5  # Longer than attack animation duration
var hit_cooldown: float = 0.0

@export var gold_coin_scene: PackedScene

# Loot table structure: [item_scene_path, drop_chance, min_quantity, max_quantity]
var loot_table: Array

func _ready():
	# Setup loot table after exported variables are set
	loot_table = [
		[gold_coin_scene, 1.0, 1, 3]  # 100% chance to drop 1-3 gold coins
	]
	
	# Set up animations if available
	if animated_sprite.sprite_frames:
		animated_sprite.play("idle")

func _process(delta):
	# Reduce hit cooldown
	if hit_cooldown > 0.0:
		hit_cooldown -= delta

func _on_area_exited(_area: Area2D):
	# Could be used for effects in the future
	pass

func is_attackable() -> bool:
	var result = state != ObjectState.DESTROYED and hit_cooldown <= 0.0
	return result

func is_attack_target(_target):
	return true # or custom logic

func is_tool_target():
	return false # or custom logic

func is_interactable() -> bool:
	var result = state != ObjectState.DESTROYED and hit_cooldown <= 0.0
	return result

func set_cooldown():
	hit_cooldown = hit_cooldown_time

# Interact action handler (for future use)
func interact():
	if state == ObjectState.DESTROYED:
		return
	print("The ", object_name, " doesn't seem to do anything.")
	# Could be used for examining, picking up, etc.

# Use item action handler (for future use)  
func handle_use_item_action(_player):
	if state == ObjectState.DESTROYED:
		return
	print("Player used item on ", object_name)
	# Could be used for tools, keys, etc.

# Damage system
func take_damage(amount: int):
	health -= amount

	# Check if object should be destroyed
	if health <= 0:
		break_object()
		return
	
	# Update state to damaged if not already
	if state == ObjectState.INTACT:
		state = ObjectState.DAMAGED
		
	# Play damaged animation or sprite
	if animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("damaged"):
			animated_sprite.play("damaged")

		elif animated_sprite.sprite_frames.has_animation("hit"):
			animated_sprite.play("hit")
		else:
			animated_sprite.play("idle")

func break_object():
	if state == ObjectState.DESTROYED:
		return
		
	state = ObjectState.DESTROYED
	print(object_name, " destroyed!")
	
	# Drop loot before destruction
	LootDropper.drop_loot(loot_table, self)
	
	# Disable solid collision so player can walk through
	#solid_collision.disabled = false
	
	# Play destruction animation if available
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("break"):
		animated_sprite.play("break")
		# Wait for animation to finish, then remove object
		await animated_sprite.animation_finished
		queue_free()
	else:
		# No break animation, just hide and remove
		animated_sprite.visible = false
		# Small delay before removal
		await get_tree().create_timer(0.1).timeout
		queue_free()
