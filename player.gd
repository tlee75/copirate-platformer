extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

var was_airborne: bool = false
var w_key_was_pressed: bool = false
var is_attacking: bool = false
var sword_area: Area2D
var tilemap: TileMap
# Remove old procedural Visual node if present
func _ready():
	var frames = load("res://player_sprites.tres")
	$AnimatedSprite2D.sprite_frames = frames
	# Remove procedural Visual if it exists
	if has_node("Visual"):
		get_node("Visual").queue_free()

	# Ensure an AnimatedSprite2D is present
	var anim: AnimatedSprite2D
	if has_node("AnimatedSprite2D"):
		anim = get_node("AnimatedSprite2D")
	else:
		anim = AnimatedSprite2D.new()
		anim.name = "AnimatedSprite2D"
		add_child(anim)

	# Scale is now set in the scene file
	
	# Set initial animation
	anim.play("idle")
	
	# Get references to sword area and tilemap
	sword_area = $SwordArea
	tilemap = get_node("../TileMap")
	
	# We'll check for tiles manually during attacks instead of using signals

func _physics_process(delta):
	var vel: Vector2 = velocity
	if not is_on_floor():
		vel.y += gravity * delta

	# WASD + Arrow key input
	var left_pressed = Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var right_pressed = Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	
	var dir = 0
	if left_pressed:
		dir -= 1
	if right_pressed:
		dir += 1
	
	if dir != 0:
		vel.x = dir * SPEED
		# Flip sprite when moving left
		$AnimatedSprite2D.flip_h = dir < 0
	else:
		vel.x = move_toward(vel.x, 0, SPEED)

	# Jump input - detect just pressed for W key
	var jump_pressed = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")
	if Input.is_key_pressed(KEY_W):
		if not w_key_was_pressed:
			jump_pressed = true
	w_key_was_pressed = Input.is_key_pressed(KEY_W)

	if jump_pressed and is_on_floor():
		vel.y = JUMP_VELOCITY

	# Attack input - left mouse button
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not is_attacking:
			is_attacking = true
			$AnimatedSprite2D.play("attack")
			# Position sword area based on facing direction
			if $AnimatedSprite2D.flip_h:
				sword_area.position.x = -20  # Left side when flipped
			else:
				sword_area.position.x = 20   # Right side when normal
			# Destroy tiles in sword area
			destroy_tiles_in_sword_area()
			# Connect to animation finished signal to end attack
			if not $AnimatedSprite2D.animation_finished.is_connected(_on_attack_animation_finished):
				$AnimatedSprite2D.animation_finished.connect(_on_attack_animation_finished)

	# Update physics first
	velocity = vel
	move_and_slide()

	# Handle animations after physics update
	handle_animations()

func handle_animations():
	# Don't change animations while attacking
	if is_attacking:
		return
		
	var on_floor = is_on_floor()
	
	if not on_floor:
		# Airborne
		was_airborne = true
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")
	else:
		# On ground
		if was_airborne:
			# Just landed - play ground animation
			was_airborne = false
			$AnimatedSprite2D.play("ground")
			# Connect to animation finished signal to transition to idle
			if not $AnimatedSprite2D.animation_finished.is_connected(_on_ground_animation_finished):
				$AnimatedSprite2D.animation_finished.connect(_on_ground_animation_finished)
		elif $AnimatedSprite2D.animation != "ground":
			# Only change animation if not currently playing ground animation
			if abs(velocity.x) > 1.0:
				$AnimatedSprite2D.play("run")
			else:
				$AnimatedSprite2D.play("idle")

func _on_ground_animation_finished():
	# When ground animation finishes, transition to appropriate animation
	if is_on_floor():
		if abs(velocity.x) > 1.0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")

func _on_attack_animation_finished():
	# When attack animation finishes, end attack state
	is_attacking = false
	# Transition to appropriate animation
	if is_on_floor():
		if abs(velocity.x) > 1.0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")
	else:
		if velocity.y < 0:
			$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")

func destroy_tiles_in_sword_area():
	# Use the ACTUAL collision shape position and size
	var sword_collision = sword_area.get_node("SwordCollision")
	var sword_shape = sword_collision.shape as RectangleShape2D
	
	# Get the actual global position of the collision shape
	var sword_global_pos = sword_collision.global_position
	var actual_shape_size = sword_shape.size
	
	# Create the rectangle representing the sword area in world space
	var sword_rect = Rect2(
		sword_global_pos - actual_shape_size / 2,
		actual_shape_size
	)
	
	print("SwordArea pos: ", sword_area.position)
	print("SwordCollision global pos: ", sword_global_pos)
	print("Shape size: ", actual_shape_size)
	print("Sword rect: ", sword_rect)
	print("Facing left: ", $AnimatedSprite2D.flip_h)
	
	# Convert world coordinates to tile coordinates
	var tile_size = tilemap.tile_set.tile_size
	var start_tile = Vector2i(
		int(sword_rect.position.x / tile_size.x),
		int(sword_rect.position.y / tile_size.y)
	)
	var end_tile = Vector2i(
		int((sword_rect.position.x + sword_rect.size.x) / tile_size.x),
		int((sword_rect.position.y + sword_rect.size.y) / tile_size.y)
	)
	
	print("Tile range: ", start_tile, " to ", end_tile)
	
	# Remove tiles in the sword area
	for x in range(start_tile.x, end_tile.x + 1):
		for y in range(start_tile.y, end_tile.y + 1):
			var tile_pos = Vector2i(x, y)
			# Check if there's a tile at this position
			var source_id = tilemap.get_cell_source_id(0, tile_pos)
			if source_id != -1:  # -1 means no tile
				# Remove the tile
				tilemap.set_cell(0, tile_pos, -1)
				print("Destroyed tile at: ", tile_pos, " (world pos: ", tile_pos * tile_size, ")")
