extends StaticBody2D

# Breakable barrel that can be destroyed by player attacks

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_detection: Area2D = $HitDetection
@onready var solid_collision: CollisionShape2D = $CollisionShape2D
@onready var hit_collision: CollisionShape2D = $HitDetection/HitCollisionShape2D

var is_destroyed: bool = false

# Loot table structure: [item_scene_path, drop_chance, min_quantity, max_quantity]
var loot_table: Array = [
	["res://gold_coin.tscn", 1.0, 1, 3]  # 100% chance to drop 1-3 gold coins
]

func _ready():
	# Connect the area detection signal
	hit_detection.area_entered.connect(_on_hit_by_attack)
	hit_detection.area_exited.connect(_on_area_exited)
	
	# Set up animations if available
	if animated_sprite.sprite_frames:
		animated_sprite.play("default")

func _process(_delta):
	# Check if player is attacking and sword is overlapping
	if not is_destroyed:
		check_for_attack_overlap()

func check_for_attack_overlap():
	# Get all areas currently overlapping with hit detection
	var overlapping_areas = hit_detection.get_overlapping_areas()
	
	for area in overlapping_areas:
		if area.name == "SwordArea":
			var player = area.get_parent()
			if player and player.is_attacking:
				print("Destroying barrel via overlap check!")
				destroy_barrel()
				return

func _on_area_exited(area: Area2D):
	if area.name == "SwordArea":
		print("SwordArea exited barrel detection")

func _on_hit_by_attack(area: Area2D):
	print("Area entered: ", area.name, " from parent: ", area.get_parent().name if area.get_parent() else "no parent")
	# Check if the attacking area is the player's sword AND the player is attacking
	if area.name == "SwordArea" and not is_destroyed:
		var player = area.get_parent()
		print("Player attacking state: ", player.is_attacking if player else "no player")
		if player and player.is_attacking:
			print("Destroying barrel!")
			destroy_barrel()
		else:
			print("Player not attacking or no player found")

func destroy_barrel():
	if is_destroyed:
		return
	
	is_destroyed = true
	
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
		var item_scene_path = loot_entry[0]
		var drop_chance = loot_entry[1]
		var min_quantity = loot_entry[2] 
		var max_quantity = loot_entry[3]
		
		# Roll for drop chance
		if randf() <= drop_chance:
			var quantity = randi_range(min_quantity, max_quantity)
			
			# Spawn the items
			for i in quantity:
				spawn_loot_item(item_scene_path, i)

func spawn_loot_item(scene_path: String, offset_index: int):
	# Load the item scene
	var item_scene = load(scene_path)
	if not item_scene:
		print("Failed to load loot item scene: ", scene_path)
		return
	
	# Instantiate the item
	var item_instance = item_scene.instantiate()
	
	# Find a valid spawn position
	var spawn_position = find_valid_spawn_position(offset_index)
	item_instance.global_position = spawn_position
	
	# Add to the scene
	get_parent().add_child(item_instance)
	
	print("Spawned loot item: ", scene_path, " at position: ", item_instance.global_position)

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

func is_position_valid(position: Vector2) -> bool:
	# Get the world's space state for collision checking
	var space_state = get_world_2d().direct_space_state
	
	# Create a small query to check for collisions at this position
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
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
