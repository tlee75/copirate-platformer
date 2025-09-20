extends CharacterBody2D

class_name Player

signal inventory_state_changed(is_open: bool)

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

var was_airborne: bool = false
var w_key_was_pressed: bool = false
var is_trigger_action: bool = false
var sword_area: Area2D
var tilemap: TileMap
var highlighted_tiles: Array[Vector2i] = []
var tile_highlights: Array[Node2D] = []
var highlight_texture: ImageTexture
var current_highlighted_tile: Vector2i = Vector2i(-999, -999)  # Invalid position to force initial update

# Inventory state
var inventory_is_open: bool = false


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
	tilemap = get_parent().get_node("TileMap")
	
	# Create reusable highlight texture
	create_highlight_texture()
	# Enable input processing so _input can capture key presses
	set_process_input(true)
	
	# Ensure player receives input
	# (No pause handling needed)
	
	# We'll check for aadddddatiles manually during attacks instead of using signals
	
	# Connect to inventory state changes
	inventory_state_changed.connect(_on_inventory_state_changed)

func _physics_process(delta):
	var vel: Vector2 = velocity
	
	# Skip input handling if inventory is open
	if inventory_is_open:
		# Still apply gravity when inventory is open
		if not is_on_floor():
			vel.y += gravity * delta
		# Stop horizontal movement gradually
		vel.x = move_toward(vel.x, 0, SPEED * 2)  # Stop faster when inventory opens
		velocity = vel
		move_and_slide()
		# Don't update sword position, mouse UI detection, or highlights when inventory is open
		return
	
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

	# Update sword area position based on mouse position
	update_sword_position()
	
	# Update tile highlights
	update_tile_highlights()
	
	# Attack input - left mouse button (but not when clicking on hotbar)
	if Input.is_action_just_pressed("mouse_left") and not is_mouse_over_hotbar():
		# Only perform an action if one is not already in progress
		if not is_trigger_action:
			var selected_item = get_selected_hotbar_item()
			if selected_item and selected_item.has_method("action"):
				selected_item.action(self)
			else:
				# Fallback to hook attack, e.g. melee
				is_trigger_action = true
				print("Hook used by %s" % self.name)
				$AnimatedSprite2D.play("hook")
				
				# Destroy tiles in sword area
				#destroy_tiles_in_sword_area()
				
				# Connect to animation finished signal to end attack
				if not $AnimatedSprite2D.animation_finished.is_connected(_on_attack_animation_finished):
					$AnimatedSprite2D.animation_finished.connect(_on_attack_animation_finished)

	# Update physics first
	velocity = vel
	move_and_slide()

	# Handle animations after physics update
	handle_animations()
	
	

func handle_animations():
	# Don't change animations while in the middle of an action
	if is_trigger_action:
		return
		
	var on_floor = is_on_floor()
	
	if not on_floor:
		# Airborne
		was_airborne = true
		if velocity.y < -10:  # Add threshold to prevent false positives at apex
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
	is_trigger_action = false
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

func update_sword_position():
	# Get mouse position in world coordinates
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	
	# Calculate direction from player to mouse
	var direction = (mouse_pos - player_pos).normalized()
	
	# Set sword area position at fixed distance from player
	var sword_distance = 30.0  # Fixed distance to prevent infinite range
	sword_area.position = direction * sword_distance
	
	# Update sprite flipping based on mouse direction
	$AnimatedSprite2D.flip_h = direction.x < 0
	
	# Ensure crosshair position is not affected by sprite flipping
	# Reset any transform that might be affected by parent flipping
	if sword_area.has_node("Crosshair"):
		var crosshair = sword_area.get_node("Crosshair")
		crosshair.position = Vector2.ZERO  # Keep crosshair centered on sword area

func create_highlight_texture():
	# Create the highlight texture once and reuse it
	var tile_size = tilemap.tile_set.tile_size
	var image = Image.create(tile_size.x, tile_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 0, 0, 0.3))  # Red with transparency
	
	# Draw white outline
	for x in range(tile_size.x):
		image.set_pixel(x, 0, Color.WHITE)  # Top edge
		image.set_pixel(x, tile_size.y - 1, Color.WHITE)  # Bottom edge
	for y in range(tile_size.y):
		image.set_pixel(0, y, Color.WHITE)  # Left edge
		image.set_pixel(tile_size.x - 1, y, Color.WHITE)  # Right edge
	
	highlight_texture = ImageTexture.new()
	highlight_texture.set_image(image)

func update_tile_highlights():
	# Don't show tile highlights when inventory is open
	if inventory_is_open:
		clear_tile_highlights()
		return
		
	# Get tiles that would be affected by sword
	var affected_tiles = get_tiles_in_sword_area()
	
	# Check if we need to update (only if target tile changed)
	var new_target = affected_tiles[0] if affected_tiles.size() > 0 else Vector2i(-999, -999)
	if new_target == current_highlighted_tile:
		return  # No change needed
	
	# Clear previous highlights
	clear_tile_highlights()
	current_highlighted_tile = new_target
	
	# Create highlight for new tile if it exists
	if affected_tiles.size() > 0:
		create_tile_highlight_optimized(affected_tiles[0])


# Removed unneeded unhandled input handling for inventory toggle

func clear_tile_highlights():
	# Remove all existing highlight sprites
	for highlight in tile_highlights:
		if highlight and is_instance_valid(highlight):
			highlight.queue_free()
	tile_highlights.clear()
	highlighted_tiles.clear()

func get_tiles_in_sword_area() -> Array[Vector2i]:
	var affected_tiles: Array[Vector2i] = []
	
	# Get crosshair position (same as sword collision center)
	var sword_collision = sword_area.get_node("SwordCollision")
	var crosshair_pos = sword_collision.global_position
	
	# Use Godot's built-in coordinate conversion to handle negative coordinates correctly
	var target_tile = tilemap.local_to_map(tilemap.to_local(crosshair_pos))
	
	# Check if this tile exists
	var source_id = tilemap.get_cell_source_id(0, target_tile)
	if source_id != -1:  # Only include if tile exists
		affected_tiles.append(target_tile)
	
	return affected_tiles

func create_tile_highlight_optimized(tile_pos: Vector2i):
	# Create a highlight sprite using the pre-created texture
	var highlight = Sprite2D.new()
	var tile_size = tilemap.tile_set.tile_size
	
	# Position the highlight at the tile's world position
	var world_pos = Vector2(tile_pos.x * tile_size.x + tile_size.x/2, tile_pos.y * tile_size.y + tile_size.y/2)
	highlight.global_position = world_pos
	
	# Use the pre-created texture (much faster!)
	highlight.texture = highlight_texture
	
	# Add to scene and track it
	get_parent().add_child(highlight)
	tile_highlights.append(highlight)
	highlighted_tiles.append(tile_pos)

func destroy_tiles_in_sword_area():
	# Get the single tile that would be affected (same logic as highlighting)
	var affected_tiles = get_tiles_in_sword_area()
	
	# Destroy only the single targeted tile
	for tile_pos in affected_tiles:
		tilemap.set_cell(0, tile_pos, -1)
		print("Destroyed tile at: ", tile_pos)

func _on_inventory_state_changed(is_open: bool):
	inventory_is_open = is_open
	print("Player: Inventory is now ", "open" if is_open else "closed")

func is_mouse_over_hotbar() -> bool:
	# Check if mouse is over the hotbar
	var ui_layer = get_parent().get_node_or_null("UI")
	if not ui_layer:
		return false
	
	var hotbar = ui_layer.get_node_or_null("Hotbar")
	if not hotbar or not hotbar.visible:
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()
	var hotbar_rect = Rect2(hotbar.global_position, hotbar.size)
	return hotbar_rect.has_point(mouse_pos)

func get_selected_hotbar_item():
	var ui_layer = get_parent().get_node_or_null("UI")
	if not ui_layer:
		return null
	var hotbar = ui_layer.get_node_or_null("Hotbar")
	if not hotbar:
		return null
	return hotbar.get_selected_item()
