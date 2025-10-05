extends CharacterBody2D

class_name Player

signal inventory_state_changed(is_open: bool)

const WALK_SPEED := 100.0
const RUN_SPEED := 250.0
const JUMP_VELOCITY := -400.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

var was_airborne: bool = false
var is_trigger_action: bool = false
var is_interacting: bool = false
var cursor_area: Area2D
var tilemap: TileMap
var highlighted_tiles: Array[Vector2i] = []
var tile_highlights: Array[Node2D] = []
var highlight_texture: ImageTexture
var current_highlighted_tile: Vector2i = Vector2i(-999, -999)  # Invalid position to force initial update
var last_move_dir: int = 1  # 1 for right, -1 for left
var was_running_when_jumped: bool = false
var jump_speed: float = 0.0
var inventory_is_open: bool = false
var is_in_water: bool = false
var tile_size: float = 32.0
var is_dead: bool = false
var attack_target = null 
var interact_target = null

# Player stats system
var player_stats: PlayerStats

# Water movement effects
var water_slow_factor: float = 0.7
var swim_speed: float = 150.0
var is_underwater: bool = false
var water_surface_y: int = -1
var water_depth: int = -1

# UI
var equipment_panel: Node = null

# Animation hit frame definition for animations without an item script
var default_hit_frames = {
	"punch": [7]
}


# Remove old procedural Visual node if present
func _ready():
	var ui_layer = get_parent().get_node_or_null("UI")
	if ui_layer:
		equipment_panel = ui_layer.get_node_or_null("CraftingMenu/TabBar/EquipmentTab/HBoxContainer/EquipmentPanel")
		
	var frames = load("res://resources/player_sprites.tres")
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
	
	# Set initial animation
	anim.play("idle")
	
	# Get references to cursor area and tilemap
	cursor_area = $CursorArea
	tilemap = get_parent().get_node("TileMap")
	
	# Create reusable highlight texture
	create_highlight_texture()
	# Enable input processing so _input can capture key presses
	set_process_input(true)

	# Connect to inventory state changes
	inventory_state_changed.connect(_on_inventory_state_changed)
	
	# Add player to group so other scripts can find it easily
	add_to_group("player")

	# Setup player stats
	player_stats = PlayerStats.new()
	add_child(player_stats)
	player_stats.stat_depleted.connect(_on_stat_depleted)


func _physics_process(delta):	
	if is_dead:
		return
	
	var vel: Vector2 = velocity
	var tile_pos = tilemap.local_to_map(global_position)
	
	# Skip input handling if inventory is open
	if inventory_is_open:
		# Still apply gravity when inventory is open
		if not is_on_floor():
			vel.y += gravity * delta
		# Stop horizontal movement gradually
		vel.x = move_toward(vel.x, 0, WALK_SPEED * 2)  # Stop faster when inventory opens
		velocity = vel
		move_and_slide()
		# Don't update cursor position, mouse UI detection, or highlights when inventory is open
		return

	if is_on_water_tile():
		if water_surface_y == -1:
			water_surface_y = find_water_surface_y()
		water_depth = tile_pos.y - water_surface_y
		if water_depth == 0:
			player_stats.set_underwater_status(false)
			var tile_below = tile_pos + Vector2i(0, 1)
			var tile_data_below = tilemap.get_cell_tile_data(0, tile_below)
			var is_water_below = tile_data_below and tile_data_below.has_custom_data("is_water") and tile_data_below.get_custom_data("is_water")
			if is_water_below: # Determine if we're underwater or standing in surface water
				is_underwater = true
			else:
				is_underwater = false # Surface water
		else:
			is_underwater = true
			player_stats.set_underwater_status(is_underwater)
	else:
		water_surface_y = -1
		is_underwater = false
		player_stats.set_underwater_status(is_underwater)

	if not is_on_floor():
		if is_underwater:
			# In water: dampen vertical movement to simulate water resistance
			vel.y = move_toward(vel.y, 0, gravity *2 * delta)
		else:
			# Normal land gravity
			vel.y += gravity * delta

	#  WASD + Arrow key input
	var left_pressed = Input.is_action_pressed("move_left") 
	var right_pressed = Input.is_action_pressed("move_right")
	var up_pressed = Input.is_action_pressed("move_up")
	var down_pressed = Input.is_action_pressed("move_down")
	
	var dir = 0
	if left_pressed:
		dir -= 1
	if right_pressed:
		dir += 1
	
	if dir != 0:
		var current_speed: float
		
		if is_underwater:
			# Always use swim speed when underwater, regardless of floor contact
			var is_sprint_swimming = Input.is_key_pressed(KEY_SHIFT)
			current_speed = swim_speed * 1.5 if is_sprint_swimming else swim_speed
			
			# Update stats for sprint swimming
			player_stats.set_sprinting_status(is_sprint_swimming)
		elif not is_on_floor():
			# Use locked jump speed when airborne
			current_speed = jump_speed
			player_stats.set_sprinting_status(false)
		else:
			# Use normal speed logic when on ground
			var is_running = Input.is_key_pressed(KEY_SHIFT)
			var base_speed = RUN_SPEED if is_running else WALK_SPEED
			current_speed = base_speed
			
			# Update stats for land sprinting
			player_stats.set_sprinting_status(is_running)
		
		vel.x = dir * current_speed
		last_move_dir = dir
	else:
		vel.x = move_toward(vel.x, 0, WALK_SPEED)
		player_stats.set_sprinting_status(false)
	
	# Vertical movement
	var vertical_dir = 0
	if up_pressed:
		vertical_dir -= 1
	if down_pressed:
		vertical_dir += 1
	
	if vertical_dir != 0:
		if is_underwater:
			var tile_pixel_y = tile_pos.y * tile_size
			var offset_in_tile = global_position.y - tile_pixel_y # 0 = top of tile, tile_size = bottom
			var near_top = offset_in_tile < 5.0 # Threshold to adjust in pixels
			
			# Swimming up/down when underwater
			var is_sprint_swimming = Input.is_key_pressed(KEY_SHIFT)
			var current_swim_speed = swim_speed * 1.5 if is_sprint_swimming else swim_speed
			
			# Prevent swimming above water surface
			if vertical_dir < 0 and water_depth == 0 and near_top and not Input.is_action_just_pressed("jump"):
				vel.y = 0 # Stop upward movement at surface
			else:
				vel.y = vertical_dir * current_swim_speed
			
			# Normalize diagonal movement
			if dir != 0 and vertical_dir !=0:
				var movement_vector = Vector2(vel.x, vel.y)
				movement_vector = movement_vector.normalized() * current_swim_speed
				vel.x = movement_vector.x
				vel.y = movement_vector.y
		else:
			# Climbing placeholder for on land
			if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
				print("Trying to climb ", "up" if vertical_dir < 0 else "down", " - no climable serface found")

	# Jump input - detect just pressed for the jump action
	if Input.is_action_just_pressed("jump") and (is_on_floor() and not is_underwater or (is_underwater and water_depth == 0)):
		vel.y = JUMP_VELOCITY
		was_running_when_jumped = Input.is_key_pressed(KEY_SHIFT)
		jump_speed = RUN_SPEED if was_running_when_jumped else WALK_SPEED

	# Update cursor area position based on mouse position
	update_cursor_position()
	
	# Update tile highlights
	update_tile_highlights()
	
	handle_interact_or_use_action()
	
	handle_attack_action()

	# Update physics first
	velocity = vel
	move_and_slide()

	# Update collision shape orientation for swimming
	update_collision_orientation()

	# Handle animations after physics update
	handle_animations()

func handle_interact_or_use_action():
	# Interact/Use Action
	if Input.is_action_just_pressed("interact") and not inventory_is_open:
		if not is_interacting:
			if is_interactable_objects():
				is_interacting = true
				if is_underwater:
					print("Gather used by %s" % self.name)
					$AnimatedSprite2D.play("swim_gather")
				else:
					print("Interact used by %s" % self.name)
					$AnimatedSprite2D.play("interact")
				# Disconnect any existing connections first, then connect
				if $AnimatedSprite2D.animation_finished.is_connected(_on_interact_animation_finished):
					$AnimatedSprite2D.animation_finished.disconnect(_on_interact_animation_finished)
				if $AnimatedSprite2D.animation_finished.is_connected(_on_ground_animation_finished):
					$AnimatedSprite2D.animation_finished.disconnect(_on_ground_animation_finished)

				$AnimatedSprite2D.animation_finished.connect(_on_interact_animation_finished)
			else:
				print("Using item")
				var selected_result = get_selected_hotbar_slot_and_item()
				var slot_data = selected_result[0]
				var selected_item = selected_result[1]
				if selected_item and selected_item.has_method("action"):
					# Check if this item can be used in current environment
					if not can_use_item_in_current_environment(selected_item):
						var item_name = selected_item.name if selected_item.has_method("get_name") else str(selected_item)
						var environment_msg = "underwater" if is_underwater else "on land"
						print("Cannot use ", item_name, " ", environment_msg, "!")
						return
					selected_item.action(self)
					# Remove item if it's consumable
					if selected_item.is_consumable():
						slot_data.remove_item(1)
						InventoryManager.hotbar_changed.emit()
				else:
					print("Cannot interact or use an item")

func handle_attack_action():
	# Main Hand Action - left mouse button (but not when clicking on hotbar)
	if Input.is_action_just_pressed("mouse_left") and not is_mouse_over_hotbar() and not is_mouse_over_combined_menu():
		# Only perform an action if one is not already in progress
		if not is_trigger_action:
			is_attackable_objects() # Allow attack even when there is no attackble object
			if equipment_panel:
				var main_hand_slot_index = equipment_panel.get_equipment_slot_index_by_node_name("MainHand")
				if main_hand_slot_index != -1:
					var main_hand_slot = InventoryManager.get_equipment_slot(main_hand_slot_index)
					if main_hand_slot and not main_hand_slot.is_empty() and main_hand_slot.item and main_hand_slot.item.has_method("action"):
						# Check if this item can be used in the current environment
						if not can_use_item_in_current_environment(main_hand_slot.item):
							var item_name = main_hand_slot.item.name if main_hand_slot.item.has_method("get_name") else str(main_hand_slot.item)
							var environment_msg = "underwater" if is_underwater else "on land"
							print("Cannot use ", item_name, " ", environment_msg, "!")
							return
						main_hand_slot.item.action(self)
					else:
						# Fallback to unarmed attack
						is_trigger_action = true
										
						if is_underwater:
							print("Gather used by %s" % self.name)
							$AnimatedSprite2D.play("swim_gather") # Replace this with swim attack
						else:
							print("Melee used by %s" % self.name)
							$AnimatedSprite2D.play("punch")
							
						# Disconnect any existing connections first, then connect
						if $AnimatedSprite2D.frame_changed.is_connected(_on_attack_frame_changed):
							$AnimatedSprite2D.frame_changed.disconnect(_on_attack_frame_changed)
						if $AnimatedSprite2D.animation_finished.is_connected(_on_ground_animation_finished):
							$AnimatedSprite2D.animation_finished.disconnect(_on_ground_animation_finished)
						if $AnimatedSprite2D.animation_finished.is_connected(_on_interact_animation_finished):
							$AnimatedSprite2D.animation_finished.disconnect(_on_interact_animation_finished)
						
						$AnimatedSprite2D.frame_changed.connect(_on_attack_frame_changed)
						$AnimatedSprite2D.animation_finished.connect(_on_attack_animation_finished)

func handle_animations():
	# Don't change animations while in the middle of an action
	if is_trigger_action or is_interacting:
		return
	
	# Don't change animations while dead
	if is_dead:
		return
	
	var on_floor = is_on_floor()
	
	if not on_floor:
		# Airborne
		was_airborne = true
		
		if is_underwater:
			# When airborne but underwater, use swimming animations
			if abs(velocity.x) > 1.0:
				# Swimming while moving
				if $AnimatedSprite2D.animation != "swim":
					$AnimatedSprite2D.play("swim")
			else:
				# Swim while stationary
				if $AnimatedSprite2D.animation != "swim_idle":
					$AnimatedSprite2D.play("swim_idle")
		else:
			# Normal airborne animations when not underwater
			var use_running_anims = was_running_when_jumped

			if velocity.y < -5:  # Going up
				var target_anim = "run_jump" if use_running_anims else "jump"
				if $AnimatedSprite2D.animation != target_anim:
					$AnimatedSprite2D.play(target_anim)
			elif velocity.y > 5:  # Going down  
				var target_anim = "run_fall" if use_running_anims else "fall"
				if $AnimatedSprite2D.animation != target_anim:
					$AnimatedSprite2D.play(target_anim)
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
				if is_underwater:
					# Swimming animation when moving underwater
					if $AnimatedSprite2D.animation != "swim":
						$AnimatedSprite2D.play("swim")
				else:
					# Normal land animations
					var is_running = Input.is_key_pressed(KEY_SHIFT)
					var target_anim = "run" if is_running else "walk"
					# Only change animation if it's different from current
					if $AnimatedSprite2D.animation != target_anim:
						$AnimatedSprite2D.play(target_anim)
			else:
				if is_underwater:
					# Swimming idle when not moving underwater
					if $AnimatedSprite2D.animation != "swim_idle":
						$AnimatedSprite2D.play("swim_idle")
				else:
					# Normal idle on land
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

	# Do stuff here when animation is finished

	# When animation finishes, end actiond state
	is_trigger_action = false
	
	# Remove target which was needed for any multi hit frame animations
	attack_target = null

func _on_attack_frame_changed():
	var anim_sprite = $AnimatedSprite2D
	var anim = anim_sprite.animation
	var frame = anim_sprite.frame
	
	# Get the equipped item from the main hand slot
	var item = null
	if equipment_panel:
		var main_hand_slot_index = equipment_panel.get_equipment_slot_index_by_node_name("MainHand")
		if main_hand_slot_index != -1:
			var main_hand_slot = InventoryManager.get_equipment_slot(main_hand_slot_index)
			if main_hand_slot and not main_hand_slot.is_empty() and main_hand_slot.item:
				item = main_hand_slot.item
	
	# Use the item's hit_frames if available
	var item_hit_frames = item.hit_frames if item and "hit_frames" in item else default_hit_frames
	
	if anim in item_hit_frames and frame in item_hit_frames[anim]:
		# Apply hit frame synchronized damage to stored target
		if attack_target and is_instance_valid(attack_target):
			attack_target.take_damage(1)  # Damage happens here


func _on_interact_animation_finished():
	# Disconnect the signal immediately to prevent interference
	if $AnimatedSprite2D.animation_finished.is_connected(_on_interact_animation_finished):
		$AnimatedSprite2D.animation_finished.disconnect(_on_interact_animation_finished)

	if interact_target and is_instance_valid(interact_target):
		interact_target.interact()

	# When attack animation finishes, end attack state
	is_interacting = false

func _on_death_animation_finished():
	# Prevent subsequent cycles from re-pausing the game
	if not is_dead:
		return
	var ui_layer = get_parent().get_node_or_null("UI")
	if ui_layer:
		var pause_menu = ui_layer.get_node_or_null("PauseMenu")
		if pause_menu:
			pause_menu.show()
			pause_menu.set_resume_enabled(false)
			get_tree().paused = true

func update_cursor_position():
	# Get mouse position in world coordinates
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	
	# Calculate direction from player to mouse
	var direction = (mouse_pos - player_pos).normalized()
	
	# Set cursor area position at fixed distance from player
	var cursor_distance = 30.0  # Fixed distance to prevent infinite range
	cursor_area.position = direction * cursor_distance
	
	# Face the direction of movement when moving; otherwise, face the mouse direction when idle
	if abs(velocity.x) > 1.0:
		$AnimatedSprite2D.flip_h = last_move_dir < 0
	else:
		$AnimatedSprite2D.flip_h = direction.x < 0
	
	# Ensure crosshair position is not affected by sprite flipping
	# Reset any transform that might be affected by parent flipping
	if cursor_area.has_node("Crosshair"):
		var crosshair = cursor_area.get_node("Crosshair")
		crosshair.position = Vector2.ZERO  # Keep crosshair centered on cursor area

func create_highlight_texture():
	# Create the highlight texture once and reuse it
	var map_tile_size = tilemap.tile_set.tile_size
	var image = Image.create(map_tile_size.x, map_tile_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 0, 0, 0.3))  # Red with transparency
	
	# Draw white outline
	for x in range(map_tile_size.x):
		image.set_pixel(x, 0, Color.WHITE)  # Top edge
		image.set_pixel(x, map_tile_size.y - 1, Color.WHITE)  # Bottom edge
	for y in range(map_tile_size.y):
		image.set_pixel(0, y, Color.WHITE)  # Left edge
		image.set_pixel(map_tile_size.x - 1, y, Color.WHITE)  # Right edge
	
	highlight_texture = ImageTexture.new()
	highlight_texture.set_image(image)

func update_tile_highlights():
	# Don't show tile highlights when inventory is open
	if inventory_is_open:
		clear_tile_highlights()
		return
		
	# Get tiles that would be affected by cursor
	var affected_tiles = get_tiles_in_cursor_area()
	
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

func get_tiles_in_cursor_area() -> Array[Vector2i]:
	var affected_tiles: Array[Vector2i] = []
	
	# Get crosshair position (same as cursor collision center)
	var cursor_collision = cursor_area.get_node("CursorCollision")
	var crosshair_pos = cursor_collision.global_position
	
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
	var map_tile_size = tilemap.tile_set.tile_size
	
	# Position the highlight at the tile's world position
	var world_pos = Vector2(tile_pos.x * map_tile_size.x + map_tile_size.x/2, tile_pos.y * map_tile_size.y + map_tile_size.y/2)
	highlight.global_position = world_pos
	
	# Use the pre-created texture (much faster!)
	highlight.texture = highlight_texture
	
	# Add to scene and track it
	get_parent().add_child(highlight)
	tile_highlights.append(highlight)
	highlighted_tiles.append(tile_pos)

func destroy_tiles_in_cursor_area():
	# Get the single tile that would be affected (same logic as highlighting)
	var affected_tiles = get_tiles_in_cursor_area()
	
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

#func get_selected_hotbar_item():
	#var ui_layer = get_parent().get_node_or_null("UI")
	#if not ui_layer:
		#return null
	#var hotbar = ui_layer.get_node_or_null("Hotbar")
	#if not hotbar:
		#return null
	#return hotbar.get_selected_item()

func get_selected_hotbar_slot_and_item():
	var ui_layer = get_parent().get_node_or_null("UI")
	if not ui_layer:
		return [null, null]
	var hotbar = ui_layer.get_node_or_null("Hotbar")
	if not hotbar:
		return [null, null]
	var slot_index = hotbar.selected_slot
	var slot_data = InventoryManager.get_hotbar_slot(slot_index)
	if slot_data and not slot_data.is_empty():
		return [slot_data, slot_data.item]
	return [null, null]

func is_on_water_tile() -> bool:
	var tile_pos = tilemap.local_to_map(global_position)
	var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
	if tile_data and tile_data.has_custom_data("is_water"):
		return tile_data.get_custom_data("is_water")
	return false

func find_water_surface_y() -> int:
	var tile_pos = tilemap.local_to_map(global_position)
	var check_pos = tile_pos
	while true:
		check_pos.y -= 1
		var tile_data = tilemap.get_cell_tile_data(0, check_pos)
		if not tile_data or not tile_data.has_custom_data("is_water") or not tile_data.get_custom_data("is_water"):
			return check_pos.y + 1 # The tile just below the first non-water tile
	return tile_pos.y

func get_water_depth() -> int:
	return water_depth

func can_use_item_in_current_environment(item) -> bool:
	if not item:
		return false
		
	# Check if item has environment compatibility properties
	if is_underwater:
		# Check if item works underwater
		return item.underwater_compatible if item.has_method("action") else false
	else:
		return item.land_compatible if item.has_method("action") else true
		

func update_collision_orientation():
	var collision_shape = $CollisionShape2D

	if is_underwater:
		# Always use a consistent swimming angle when underwater
		var base_angle = 45.0  # Base swimming angle in degrees

		# Flip collision shape to match sprite direction
		if $AnimatedSprite2D.flip_h:
			base_angle = -base_angle  # Flip the angle
		
		var target_rotation = deg_to_rad(base_angle)
		collision_shape.rotation = lerp(collision_shape.rotation, target_rotation, 0.1)
	else:
		# On land or in air - always vertical collision
		collision_shape.rotation = lerp(collision_shape.rotation, 0.0, 0.2)

func _on_stat_depleted(stat_name: String):
	if is_dead:
		return
	match stat_name:
		"health":
			print("Player has died!!")
			is_dead = true
			if $AnimatedSprite2D.animation != "land_death":
				print("play land death")
				$AnimatedSprite2D.play("land_death")
				# Disconnect previous handlers
				if $AnimatedSprite2D.animation_finished.is_connected(_on_attack_animation_finished):
					$AnimatedSprite2D.animation_finished.disconnect(_on_attack_animation_finished)
				if $AnimatedSprite2D.animation_finished.is_connected(_on_ground_animation_finished):
					$AnimatedSprite2D.animation_finished.disconnect(_on_ground_animation_finished)
				if $AnimatedSprite2D.animation_finished.is_connected(_on_death_animation_finished):
					$AnimatedSprite2D.animation_finished.disconnect(_on_death_animation_finished)
				# Connect death animation finished h andler
				$AnimatedSprite2D.animation_finished.connect(_on_death_animation_finished)
		"oxygen":
			print("Player is suffocating!")
			# Take damage from drowning
			player_stats.modify_health(-0.2)
		"stamina":
			print("Player is exhausted!")
			# Could reduce movement speed or prevent sprinting
		"hunger":
			print("Player is starving!")
			player_stats.modify_health(-5.0)
		"thirst":
			print("Player is dehydrated!")
			player_stats.modify_health(-5.0)

func is_interactable_objects():
	var all_targets = get_potential_targets()
	
	# Find first interactable target
	for target in all_targets:
		if target != self and target.has_method("is_interactable") and target.is_interactable():
			interact_target = target
			target.set_cooldown()
			return true
		
	print("No interactable objects in range")

func is_attackable_objects():
	var all_targets = get_potential_targets()
		
	# Find first attackable target
	for target in all_targets:
		if target != self and target.has_method("is_attackable") and target.is_attackable():
			attack_target = target
			target.set_cooldown()
			return true

func get_potential_targets() -> Array:
	var overlapping_areas = cursor_area.get_overlapping_areas()
	var overlapping_bodies = cursor_area.get_overlapping_bodies()
	var all_targets: Array = []
	for body in overlapping_bodies:
		all_targets.append(body)
	for area in overlapping_areas:
		var parent = area.get_parent()
		if parent != self:
			all_targets.append(parent)
	return all_targets

func add_loot(item_name: String, amount: int):
	# Implement inventory logic
	var game_item = InventoryManager.item_database[item_name]
	if InventoryManager.add_item(game_item, amount):
		return true
	else:
		return false
