extends CharacterBody2D

class_name Player

signal inventory_state_changed(is_open: bool)

const WALK_SPEED := 100.0
const RUN_SPEED := 250.0
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
var last_move_dir: int = 1  # 1 for right, -1 for left
var was_running_when_jumped: bool = false
var jump_speed: float = 0.0
var inventory_is_open: bool = false
var water_depth: int = 0
var sea_level_y: float = 0.0 # Y=0 represents Sea Level
var is_in_water: bool = false
var previous_water_depth: int = 0
var tile_size: float = 32.0

# Water movement effects
var water_slow_factor: float = 0.7
var swim_speed: float = 80.0

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
	
	# Add player to group so other scripts can find it easily
	add_to_group("player")

func _physics_process(delta):
	var vel: Vector2 = velocity
	
	# Skip input handling if inventory is open
	if inventory_is_open:
		# Still apply gravity when inventory is open
		if not is_on_floor():
			vel.y += gravity * delta
		# Stop horizontal movement gradually
		vel.x = move_toward(vel.x, 0, WALK_SPEED * 2)  # Stop faster when inventory opens
		velocity = vel
		move_and_slide()
		# Don't update sword position, mouse UI detection, or highlights when inventory is open
		return

	# Calculate current water depth (Y=0 is sea level)
	calculate_water_depth()

	if not is_on_floor():
		vel.y += gravity * delta

	#  WASD + Arrow key input
	var left_pressed = Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var right_pressed = Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	
	var dir = 0
	if left_pressed:
		dir -= 1
	if right_pressed:
		dir += 1
	
	if dir != 0:
		var current_speed: float
		if not is_on_floor():
			# Use locked jump speed when airborne
			current_speed = jump_speed
		else:
			# Use normal speed logic when on ground
			var is_running = Input.is_key_pressed(KEY_SHIFT)
			current_speed = RUN_SPEED if is_running else WALK_SPEED

		vel.x = dir * current_speed
		last_move_dir = dir
	else:
		vel.x = move_toward(vel.x, 0, WALK_SPEED)

	# Jump input - detect just pressed for W key
	var jump_pressed = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")
	if Input.is_key_pressed(KEY_W):
		if not w_key_was_pressed:
			jump_pressed = true
	w_key_was_pressed = Input.is_key_pressed(KEY_W)

	if jump_pressed and is_on_floor():
		vel.y = JUMP_VELOCITY
		was_running_when_jumped = Input.is_key_pressed(KEY_SHIFT)
		jump_speed = RUN_SPEED if was_running_when_jumped else WALK_SPEED

	# Update sword area position based on mouse position
	update_sword_position()
	
	# Update tile highlights
	update_tile_highlights()
	
	# Attack input - left mouse button (but not when clicking on hotbar)
	if Input.is_action_just_pressed("mouse_left") and not is_mouse_over_hotbar() and not is_mouse_over_combined_menu():
		# Only perform an action if one is not already in progress
		if not is_trigger_action:
			var selected_item = get_selected_hotbar_item()
			if selected_item and selected_item.has_method("action"):
				selected_item.action(self)
			else:
				# Fallback to punch attack, e.g. melee
				is_trigger_action = true
				print("Hook used by %s" % self.name)
				$AnimatedSprite2D.play("punch")
				
				# Destroy tiles in sword area
				#destroy_tiles_in_sword_area()
				
				# Disconnect any existing connections first, then connect
				if $AnimatedSprite2D.animation_finished.is_connected(_on_attack_animation_finished):
					$AnimatedSprite2D.animation_finished.disconnect(_on_attack_animation_finished)
				if $AnimatedSprite2D.animation_finished.is_connected(_on_ground_animation_finished):
					$AnimatedSprite2D.animation_finished.disconnect(_on_ground_animation_finished)

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
		
		var use_running_anims = was_running_when_jumped

		if velocity.y < -5:  # Going up
			var target_anim = "run_jump" if use_running_anims else "jump"
			if $AnimatedSprite2D.animation != target_anim:
				$AnimatedSprite2D.play(target_anim)
		elif velocity.y > 5:  # Going down  
			var target_anim = "run_fall" if use_running_anims else "fall"
			if $AnimatedSprite2D.animation != target_anim:
				$AnimatedSprite2D.play(target_anim)
		# At apex (-5 to 5), maintain current animation
	else:
		# On ground
		if was_airborne:
			# Just landed - play appropriate ground animation
			was_airborne = false
			var ground_anim = "run_ground" if was_running_when_jumped else "ground"
			$AnimatedSprite2D.play(ground_anim)
			# Connect to animation finished signal to transition to idle
			if not $AnimatedSprite2D.animation_finished.is_connected(_on_ground_animation_finished):
				$AnimatedSprite2D.animation_finished.connect(_on_ground_animation_finished)
		elif $AnimatedSprite2D.animation != "ground":
			# Only change animation if not currently playing ground animation
			if abs(velocity.x) > 1.0:
				var is_running = Input.is_key_pressed(KEY_SHIFT)
				var target_anim = "run" if is_running else "walk"
				# Only change animation if it's different from current
				if $AnimatedSprite2D.animation != target_anim:
					$AnimatedSprite2D.play(target_anim)
			else:
				$AnimatedSprite2D.play("idle")

func _on_ground_animation_finished():
	# Only transition if we're still on the ground
	if is_on_floor():
		if abs(velocity.x) > 1.0:
			var is_running = Input.is_key_pressed(KEY_SHIFT)
			var target_anim = "run" if is_running else "walk"
			$AnimatedSprite2D.play(target_anim)
		else:
			$AnimatedSprite2D.play("idle")

func _on_attack_animation_finished():
	# Disconnect the signal immediately to prevent interference
	if $AnimatedSprite2D.animation_finished.is_connected(_on_attack_animation_finished):
		$AnimatedSprite2D.animation_finished.disconnect(_on_attack_animation_finished)

	# When attack animation finishes, end attack state
	is_trigger_action = false

	# Don't force animation change here - let handle_animations() handle it
	# This prevents interference with jump/fall animations

func update_sword_position():
	# Get mouse position in world coordinates
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	
	# Calculate direction from player to mouse
	var direction = (mouse_pos - player_pos).normalized()
	
	# Set sword area position at fixed distance from player
	var sword_distance = 30.0  # Fixed distance to prevent infinite range
	sword_area.position = direction * sword_distance
	
	# Face the direction of movement when moving; otherwise, face the mouse direction when idle
	if abs(velocity.x) > 1.0:
		$AnimatedSprite2D.flip_h = last_move_dir < 0
	else:
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

func is_mouse_over_combined_menu() -> bool:
	var ui_layer = get_parent().get_node_or_null("UI")
	if not ui_layer:
		return false
	var combined_menu = ui_layer.get_node_or_null("CraftingMenu")
	if not combined_menu or not combined_menu.visible:
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Check if mouse is over the main CraftingMenu control
	if combined_menu.get_global_rect().has_point(mouse_pos):
		return true
	
	# Also check the TabContainer specifically since it extends beyond the parent
	var tab_container = combined_menu.get_node_or_null("TabBar")
	if tab_container and tab_container.get_global_rect().has_point(mouse_pos):
		return true

	return false

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

func calculate_water_depth():
	# Y=0 is sea level, positive Y values are underwater
	if global_position.y > sea_level_y:
		# Player is underwater - calculate depth in tiles
		var depth_pixels = global_position.y - sea_level_y
		var new_depth = int(depth_pixels / tile_size) + 1
		
		# Store previous depth for comparison
		previous_water_depth = water_depth
		water_depth = max(0, new_depth) # Ensure depth is never negative
		is_in_water = true
		
		# Emit signal if depth changed significantly
		if abs(water_depth - previous_water_depth) >= 1:
			_on_depth_changed()
	else:
		# Player is above sea level (on land or air)
		previous_water_depth = water_depth
		water_depth = 0
		is_in_water = false
		
		if previous_water_depth > 0:
			_on_depth_changed()
	
	return water_depth
	
func _on_depth_changed():
	print("Depth changed from ", previous_water_depth, " to ", water_depth, " tiles below sea level")
