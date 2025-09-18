extends StaticBody2D

# Breakable barrel that can be destroyed by player attacks

# Barrel states
enum BarrelState { INTACT, DAMAGED, DESTROYED }
var state: int = BarrelState.INTACT

@export var max_health: int = 3
var health: int = max_health

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_detection: Area2D = $HitDetection
@onready var solid_collision: CollisionShape2D = $CollisionShape2D
@onready var hit_collision: CollisionShape2D = $HitDetection/HitCollisionShape2D

# Cooldown to prevent multiple hits from same attack
@export var hit_cooldown_time: float = 0.6  # Longer than attack animation duration
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
		
	# Check for player actions if barrel isn't destroyed
	if state != BarrelState.DESTROYED:
		check_for_player_actions()

# Modular action detection system
func check_for_player_actions():
	# Don't process if on cooldown
	if hit_cooldown > 0.0:
		return
		
	# Get all areas currently overlapping with hit detection
	var overlapping_areas = hit_detection.get_overlapping_areas()
	
	for area in overlapping_areas:
		if area.name == "SwordArea":
			var player = area.get_parent()
			if player and player.is_using_item:
				handle_action("attack", player)
				return

func _on_area_exited(_area: Area2D):
	# Could be used for effects in the future
	pass

# REMOVED: Signal-based detection to prevent duplicate hits
# func _on_hit_by_attack(area: Area2D):
#	# This was causing double-hits with the process-based system

# Modular action handler system
func handle_action(action_type: String, actor):
	match action_type:
		"attack":
			handle_attack_action(actor)
		"interact":
			handle_interact_action(actor)
		"use_item":
			handle_use_item_action(actor)
		_:
			print("Unknown action type: ", action_type)

# Attack action handler
func handle_attack_action(_player):
	# Prevent multiple hits in quick succession
	if state == BarrelState.DESTROYED or hit_cooldown > 0.0:
		return
		
	# Set cooldown
	hit_cooldown = hit_cooldown_time
	
	# Apply attack damage
	take_damage(1)

# Interact action handler (for future use)
func handle_interact_action(_player):
	if state == BarrelState.DESTROYED:
		return
	print("Player interacted with barrel")
	# Could be used for examining, picking up, etc.

# Use item action handler (for future use)  
func handle_use_item_action(_player):
	if state == BarrelState.DESTROYED:
		return
	print("Player used item on barrel")
	# Could be used for tools, keys, etc.

# Damage system (separated from action handling)
func take_damage(amount: int):
	health -= amount
	print("Barrel damaged! Health: ", health, "/", max_health, " - State: ", state)
	
	# Check if barrel should be destroyed
	if health <= 0:
		break_barrel()
		return
	
	# Update state to damaged if not already
	if state == BarrelState.INTACT:
		state = BarrelState.DAMAGED
		
	# Play damaged animation or sprite
	if animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("damaged"):
			animated_sprite.play("damaged")

# REMOVED: Old monolithic hit function - replaced by modular action system
# func on_barrel_hit(): ...
		elif animated_sprite.sprite_frames.has_animation("hit"):
			animated_sprite.play("hit")
		else:
			animated_sprite.play("idle")

func break_barrel():
	if state == BarrelState.DESTROYED:
		return
		
	state = BarrelState.DESTROYED
	print("Barrel destroyed!")
	
	# Drop loot before destruction
	drop_loot()
	
	# Disable solid collision so player can walk through
	solid_collision.disabled = true
	
	# Play destruction animation if available
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("break"):
		animated_sprite.play("break")
		# Wait for animation to finish, then remove barrel
		await animated_sprite.animation_finished
		queue_free()
	else:
		# No break animation, just hide and remove
		animated_sprite.visible = false
		# Small delay before removal
		await get_tree().create_timer(0.1).timeout
		queue_free()

# Loot dropping system
func drop_loot():
	for loot_entry in loot_table:
		var item_scene = loot_entry[0]
		var drop_chance = loot_entry[1]
		var min_quantity = loot_entry[2] 
		var max_quantity = loot_entry[3]
		
		# Roll for drop chance
		if randf() <= drop_chance:
			var quantity = randi_range(min_quantity, max_quantity)
			
			# Spawn the items
			for i in quantity:
				spawn_loot_item(item_scene, i)

func spawn_loot_item(item_scene: PackedScene, offset_index: int):
	if not item_scene:
		print("Failed to spawn loot: PackedScene is null")
		return
	
	# Instantiate the item
	var item_instance = item_scene.instantiate()
	
	# Find a valid spawn position
	var spawn_position = find_valid_spawn_position(offset_index)
	item_instance.global_position = spawn_position
	
	# Add to the scene
	get_parent().add_child(item_instance)
	
	print("Spawned loot item at position: ", item_instance.global_position)

func find_valid_spawn_position(offset_index: int) -> Vector2:
	var max_attempts = 20
	var attempt = 0
	
	while attempt < max_attempts:
		# Try different spawn positions with very small spread
		var spawn_offset = Vector2(
			randf_range(-8, 8) + (offset_index * 4), 
			randf_range(-8, 8)
		)
		var test_position = global_position + spawn_offset
		
		# Check if this position is valid
		if is_position_valid(test_position):
			return test_position
		
		attempt += 1
	
	# If no valid position found, spawn at barrel position (it's disappearing anyway)
	print("Warning: Could not find valid spawn position, using barrel location")
	return global_position

func is_position_valid(pos: Vector2) -> bool:
	# Get the world's space state for collision checking
	var space_state = get_world_2d().direct_space_state
	
	# Create a small query to check for collisions at this position
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1  # Check against collision layer 1 (adjust as needed)
	
	# Check for collisions with tiles/static bodies
	var result = space_state.intersect_point(query)
	
	# Position is valid if nothing solid is there
	for collision in result:
		var collider = collision.collider
		# Avoid spawning inside tiles (TileMap) or other StaticBody2D objects
		if collider is TileMap or (collider is StaticBody2D and collider != self):
			return false
	
	return true
