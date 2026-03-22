extends CharacterBody2D

class_name Player

const WALK_SPEED := 100.0
const RUN_SPEED := 250.0
const JUMP_VELOCITY := -400.0

@export var max_cursor_distance: float = 80.0  # Adjustable in editor
@export var default_interact_range: float = 80.0   # Default interaction range
@export var default_interact_spread: float = 20.0  # Default interaction spread

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
var tile_size: float = 32.0
var is_dead: bool = false
var attack_target = null 
var tool_target = null
var interact_target = null
var current_hover_target: GameObject = null
var current_targeted_object: Variant = null

# UI Manager reference for centralized state checking
var ui_manager: UIManager

# Player stats system
var player_stats: PlayerStats

# Water movement effects
var swim_speed: float = 150.0
var is_underwater: bool = false
var water_surface_y: int = -1
var water_depth: int = -1

# Animation hit frame definition for animations without an item script
var default_hit_frames = {
	"punch": [7]
}


# Remove old procedural Visual node if present
func _ready():
	var frames = load("res://resources/player_sprites.tres")
	$AnimatedSprite2D.sprite_frames = frames

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
	
	# Initialize crosshair as hidden
	set_crosshair_visibility(false)
	
	# Create reusable highlight texture
	create_highlight_texture()
	# Enable input processing so _input can capture key presses
	set_process_input(true)
	
	# Add player to group so other scripts can find it easily
	add_to_group("player")

	# Setup player stats
	player_stats = PlayerStats.new()
	add_child(player_stats)
	player_stats.stat_depleted.connect(_on_stat_depleted)

	# Connect to PlayerMenu's input handler once the scene is ready
	call_deferred("_connect_to_inventory_ui")

	# Get reference to UIManager for centralized menu state checking
	call_deferred("_setup_ui_manager_reference")

func _input(event):
	"""Handle debug input for stat manipulation"""
	# Only process debug input in debug builds or when explicitly enabled
	if not OS.is_debug_build():
		return

   # Numpad debug controls for stats
	if event is InputEventKey and event.pressed:
		match event.keycode:
			# Numpad 1 - Health controls
			KEY_KP_1:
				player_stats.debug_add_health(-10.0)   # Heal

			# Numpad Period - Empty all stats (but keep alive)
			KEY_KP_PERIOD:
				player_stats.debug_kill_player()     # Actually kill for death testing

func _setup_ui_manager_reference():
	"""Set up reference to UIManager for centralized menu state checking"""
	var ui_layer = get_parent().get_node_or_null("UI")
	if ui_layer:
		ui_manager = ui_layer.get_node_or_null("UIManager")
		if ui_manager:
			print("Player: Connected to UIManager for menu state checking")
		else:
			print("WARNING: UIManager not found - menu blocking may not work correctly")
	else:
		print("WARNING: UI layer not found")

func _physics_process(delta):	
	if is_dead:
		return

	# Do not allow movement while in the middle of an animation
	if is_trigger_action or is_interacting:
		return

	var vel: Vector2 = velocity
	var tile_pos = tilemap.local_to_map(global_position)
	
	# Skip input handling if any menu is open (centralized check through UIManager)
	var any_menu_open = false
	if ui_manager:
		any_menu_open = ui_manager.is_any_menu_open()
	else:
		# Fallback to old method if UIManager not available
		any_menu_open = PlayerInputHandler.is_player_menu_open

	if any_menu_open:
		# Still apply gravity when inventory is open
		if not is_on_floor() and not is_underwater:
			vel.y += gravity * delta
		# Stop horizontal movement gradually
		vel.x = move_toward(vel.x, 0, WALK_SPEED * 2)
		velocity = vel
		move_and_slide()
		
		# Set appropriate idle animation
		var target_animation = "swim_idle" if is_underwater else "idle"
		if $AnimatedSprite2D.animation != target_animation:
			$AnimatedSprite2D.play(target_animation)
		
		# Don't process any other input when menus are open
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
	var any_menu_open = ui_manager.is_any_menu_open() if ui_manager else PlayerInputHandler.is_player_menu_open
	if Input.is_action_just_pressed("interact") and not any_menu_open:
		if not is_interacting:
			if is_interact_target():
				is_interacting = true
				print("Interact used by %s" % self.name)
				if is_underwater:
					$AnimatedSprite2D.play("swim_gather")
				else:
					$AnimatedSprite2D.play("interact")
				# Disconnect any existing connections first, then connect
				if $AnimatedSprite2D.animation_finished.is_connected(_on_interact_animation_finished):
					$AnimatedSprite2D.frame_changed.disconnect(_on_interact_animation_finished)
				$AnimatedSprite2D.animation_finished.connect(_on_interact_animation_finished)
			elif not is_trigger_action:
				print("Using quick access item")
				var selected_stack = get_selected_quick_access_item()
				if selected_stack and selected_stack.item:
					if not can_use_item_in_current_environment(selected_stack.item):
						var item_name = selected_stack.item.name if selected_stack.item.has_method("get_name") else str(selected_stack.item)
						var environment_msg = "underwater" if is_underwater else "on land"
						print("Cannot use ", item_name, " ", environment_msg, "!")
						return
					# Use the currently targeted object/tile from our targeting system
					if current_targeted_object != null:
						# Check if current target is valid for this tool
						var tool_item = selected_stack.item
						if is_valid_tool_target(current_targeted_object, tool_item):
							tool_target = current_targeted_object
							handle_quick_access_action(selected_stack, tool_target)
						else:
							print("Cannot use ", tool_item.name, " on this target")
					else:
						print("No target selected for tool use")
				else:
					print("Cannot interact or use an item")

func is_valid_tool_target(target: Variant, tool_item) -> bool:
	"""Check if the target is valid for this tool"""
	if not tool_item or not tool_item.is_tool or tool_item.tool_action == "":
		return false
	
	# Handle tile targets (Vector2i)
	if typeof(target) == TYPE_VECTOR2I:
		var tile_pos = target as Vector2i
		var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
		if tile_data:
			match tool_item.tool_action:
				"dig":
					return tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable")
				# Add other tile tool actions here as needed
		return false
	
	# Handle object targets (Node2D)
	elif target is GameObject:
		return check_object_tool_compatibility(target, tool_item.tool_action)
	
	return false

func handle_attack_action():
	if PlacementManager.placement_active:
		return # Placement manager handles input
	
	# Main Hand Action - left mouse button (but not when clicking on UI)
	if Input.is_action_just_pressed("mouse_left") and not is_mouse_over_quick_access() and not is_mouse_over_inventory():
		print("left click")
		# Only perform an action if one is not already in progress
		if not is_trigger_action:
			print("not trigger action")

			var main_hand_item = InventoryManager.get_equipped_item("main_hand")
			if main_hand_item:
				if not can_use_item_in_current_environment(main_hand_item):
					var environment_msg = "underwater" if is_underwater else "on land"
					print("Cannot use ", main_hand_item.name, " ", environment_msg, "!")
					return
				# Detect targets
				attack_target = get_attack_target()
				handle_mainhand_action(main_hand_item, attack_target)
			else:
				# Fallback to melee item attack
				var melee_item = GameObjectsDatabase.game_objects_database["melee"]
				attack_target = get_attack_target()
				melee_item.attack(self, attack_target)
				
func handle_mainhand_action(item, target):
	if not item.has_method("attack"):
		print("WARNING: Item ", item.name, " is missing attack methods!")
	if not item.damage or item.damage <= 0:
		print("WARNING: Item ", item.name, " is missing damage attribute or damage is zero!")
	if typeof(target) == TYPE_OBJECT:
		item.attack(self, target)
	else:
		item.attack(self, null)

func handle_quick_access_action(selected_stack, target):
	var item = selected_stack.item
	item.use(self, target, selected_stack)

func handle_animations():
	# Don't change animations while in the middle of an action or dead
	if is_trigger_action or is_interacting or is_dead:
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
					print("Playing: ", $AnimatedSprite2D.animation)
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
			#else:
				#if is_underwater:
					## Swimming idle when not moving underwater
					#if $AnimatedSprite2D.animation != "swim_idle":
						#$AnimatedSprite2D.play("swim_idle")
					#else:
						#print("Playing: %", $AnimatedSprite2D.animation)
				#else:
					## Normal idle on land
					#$AnimatedSprite2D.play("idle")

func _on_ground_animation_finished():
	# Only transition if we're still on the ground
	if is_on_floor():
		if abs(velocity.x) > 1.0:
			var is_running = Input.is_key_pressed(KEY_SHIFT)
			var target_anim = "run" if is_running else "walk"
			$AnimatedSprite2D.play(target_anim)
		else:
			$AnimatedSprite2D.play("idle")

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
	# Only check mouse bounds occasionally to prevent rapid warping
	if Engine.get_physics_frames() % 3 == 0:
		keep_mouse_in_screen()
	
	# New smart targeting system
	update_crosshair_targeting()
	
	# Face the direction of movement when moving; otherwise, face the crosshair direction when idle
	if abs(velocity.x) > 1.0:
		$AnimatedSprite2D.flip_h = last_move_dir < 0
	else:
		# Use the actual crosshair position for facing direction
		var crosshair_direction = cursor_area.position.normalized()
		$AnimatedSprite2D.flip_h = crosshair_direction.x < 0
	
	# Ensure crosshair position is not affected by sprite flipping
	if cursor_area.has_node("Crosshair"):
		var crosshair = cursor_area.get_node("Crosshair")
		crosshair.position = Vector2.ZERO  # Keep crosshair centered on cursor area

func keep_mouse_in_screen():
	"""Prevent mouse from leaving the screen bounds with buffer"""
	# Get current screen size (updates dynamically with window resize)
	var screen_size = DisplayServer.window_get_size()
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Add buffer to prevent cursor from going slightly outside
	var buffer = 5.0
	var clamped_pos = Vector2(
		clamp(mouse_pos.x, buffer, screen_size.x - buffer),
		clamp(mouse_pos.y, buffer, screen_size.y - buffer)
	)
	
	# Only warp if the position actually changed
	if mouse_pos.distance_to(clamped_pos) > 1.0:
		Input.warp_mouse(clamped_pos)

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

func clear_tile_highlights():
	# Remove all existing highlight sprites
	for highlight in tile_highlights:
		if highlight and is_instance_valid(highlight):
			highlight.queue_free()
	tile_highlights.clear()
	highlighted_tiles.clear()

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
	
func _on_inventory_action_executed(action_type: InventoryActionResolver.ActionType, stack: InventoryManager.ItemStack, success: bool):
	print("Player: Inventory action executed - ", action_type, " on ", stack.item.name, " - Success: ", success)
	
	# Handle any player-specific responses to inventory actions
	if success:
		match action_type:
			InventoryActionResolver.ActionType.EQUIP:
				print("Item equipped: ", stack.item.name)
			InventoryActionResolver.ActionType.USE:
				print("Item used: ", stack.item.name)
			InventoryActionResolver.ActionType.QUICK_ACCESS:
				print("Item moved to quick access: ", stack.item.name)

func _on_inventory_input_mode_changed(new_mode: InventoryActionResolver.InputMethod):
	var mode_name = ""
	match new_mode:
		InventoryActionResolver.InputMethod.MOUSE_KEYBOARD:
			mode_name = "Mouse/Keyboard"
		InventoryActionResolver.InputMethod.CONTROLLER:
			mode_name = "Controller"
		InventoryActionResolver.InputMethod.TOUCH:
			mode_name = "Touch"
	
	print("Player: Input mode changed to ", mode_name)
	
	# Could trigger UI changes here based on input mode
	# For example, show/hide controller button hints

func is_mouse_over_quick_access() -> bool:
	# Check if mouse is over the quick access display
	var ui_layer = get_parent().get_node_or_null("UI")
	if not ui_layer:
		return false
	
	var quick_access = ui_layer.get_node_or_null("QuickAccess")
	if not quick_access or not quick_access.visible:
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()
	var quick_access_rect = Rect2(quick_access.global_position, quick_access.size)
	return quick_access_rect.has_point(mouse_pos)

func get_selected_quick_access_item():
	var ui_layer = get_parent().get_node_or_null("UI")
	if not ui_layer:
		return null
	var quick_access = ui_layer.get_node_or_null("QuickAccess")
	if not quick_access:
		return null
	return quick_access.get_selected_stack()

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
		return item.underwater_compatible
	else:
		return item.land_compatible
		

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
				if $AnimatedSprite2D.animation_finished.is_connected(_on_death_animation_finished):
					$AnimatedSprite2D.animation_finished.disconnect(_on_death_animation_finished)
				$AnimatedSprite2D.animation_finished.connect(_on_death_animation_finished)
		"oxygen":
			print("Player is suffocating!")
		"stamina":
			print("Player is exhausted!")
			# Could reduce movement speed or prevent sprinting
		"hunger":
			print("Player is starving!")
		"thirst":
			print("Player is dehydrated!")

func is_interact_target():
	"""Check if current targeted object is interactable"""
	# Only allow interaction with the currently targeted object
	if not current_targeted_object:
		return false
	
	# Handle tile targets (Vector2i) - not interactable
	if typeof(current_targeted_object) == TYPE_VECTOR2I:
		return false
	
	# Handle object targets (Node2D)
	if current_targeted_object is Node2D:
		if current_targeted_object.has_method("is_interactable") and current_targeted_object.is_interactable():
			interact_target = current_targeted_object
			current_targeted_object.set_cooldown()
			return true
	
	return false

func is_attack_target(target):
	return target and target.has_method("is_attack_target") and target.is_attack_target()

func is_tile_target(tile_pos: Vector2i):
	var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
	return tile_data and tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable")

func get_attack_target():
	var targets = []
	for body in cursor_area.get_overlapping_bodies():
		if body != self and body.has_method("is_attack_target") and body.is_attack_target(body):
			print("Attackable object found: ", body)
			targets.append(body)
	for area in cursor_area.get_overlapping_areas():
		var parent = area.get_parent()
		if parent != self and parent.has_method("is_attack_target") and parent.is_attack_target(parent):
			targets.append(parent)
	return targets[0] if targets.size() > 0 else null

func add_loot(item_name: String, amount: int):
	# Implement inventory logic
	var game_item = GameObjectsDatabase.game_objects_database[item_name]
	if InventoryManager.add_item(game_item, amount):
		# Find the stack for this item
		var stack = InventoryManager.find_item_stack(game_item.name)
		if stack and not stack.is_in_quick_access():
			InventoryManager.assign_to_next_quick_access_slot(stack)
		return true
	else:
		return false

func _connect_to_inventory_ui():
	# Connect to the singleton PlayerInputHandler
	PlayerInputHandler.action_executed.connect(_on_inventory_action_executed)
	PlayerInputHandler.input_mode_changed.connect(_on_inventory_input_mode_changed)
	print("Player connected to PlayerInputHandler singleton")

func is_mouse_over_inventory() -> bool:
	# Check if mouse is over any UI elements
	var ui_layer = get_parent().get_node_or_null("UI")
	if not ui_layer:
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Check PlayerMenu
	var player_menu = ui_layer.get_node_or_null("PlayerMenu")
	if player_menu and player_menu.visible:
		if Rect2(player_menu.global_position, player_menu.size).has_point(mouse_pos):
			return true
	
	# Check ObjectInventoryMenu
	var object_menu = ui_layer.get_node_or_null("ObjectInventoryMenu")
	if object_menu and object_menu.visible:
		if Rect2(object_menu.global_position, object_menu.size).has_point(mouse_pos):
			return true
	
	return false

func update_crosshair_targeting():
	"""Main targeting logic with priority system"""
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	var direction = (mouse_pos - player_pos).normalized()
	
	# PRIORITY 1: Direct cursor position checks
	
	# 1.1 Direct attackable target (mainhand weapon OR melee default)
	var mainhand_item = InventoryManager.get_equipped_item("main_hand")
	var attack_item = mainhand_item
	
	if not mainhand_item or not mainhand_item.is_weapon:
		# Use melee as default when no weapon equipped
		attack_item = GameObjectsDatabase.game_objects_database["melee"]
	
	if attack_item:
		var target = get_attackable_at_position(mouse_pos, attack_item.target_range)
		if target:
			snap_crosshair_to_target(target)
			return

	# 1.2 Direct interactable object  
	var interactable = get_interactable_at_position(mouse_pos, default_interact_range)
	if interactable:
		snap_crosshair_to_target(interactable)
		return
	
	# 1.3 Direct tool targeting
	var quick_stack = get_selected_quick_access_item()
	if quick_stack and quick_stack.item and quick_stack.item.is_tool and quick_stack.item.tool_action != "":
		var tool_target = get_tool_target_at_position(mouse_pos, quick_stack.item)
		if tool_target != null:
			if typeof(tool_target) == TYPE_VECTOR2I:
				snap_crosshair_to_tile(tool_target)
			else:
				snap_crosshair_to_target(tool_target)
			return
	
	# PRIORITY 2: Raycast path targeting
	
	# 2.1 Raycast attackable targets (weapon spread)
	if attack_item:
		var raycast_target = raycast_attackable_targets(player_pos, direction, attack_item)
		if raycast_target:
			snap_crosshair_to_target(raycast_target)
			return
	
	# 2.2 Raycast interactable objects (default spread)  
	var obj_target = raycast_interactable_objects(player_pos, direction, default_interact_range, default_interact_spread)
	if obj_target:
		snap_crosshair_to_target(obj_target)
		return
	
	# 2.3 Raycast tool targets
	if quick_stack and quick_stack.item and quick_stack.item.is_tool:
		var tool_target = raycast_tool_targets(player_pos, direction, quick_stack.item)
		if tool_target != null:
			if typeof(tool_target) == TYPE_VECTOR2I:
				snap_crosshair_to_tile(tool_target)
			else:
				snap_crosshair_to_target(tool_target)
			return
	
	# FALLBACK: Position at mouse location (no range limit)
	cursor_area.position = mouse_pos - player_pos
	
	# Clear all targeting effects when no specific target is found
	current_targeted_object = null
	clear_hover_target()
	set_crosshair_visibility(false)
	clear_tile_highlights()
	current_highlighted_tile = Vector2i(-999, -999)

func get_attackable_at_position(world_pos: Vector2, max_range: float):
	"""Check for attackable targets directly at cursor position"""
	var player_pos = global_position
	if world_pos.distance_to(player_pos) > max_range:
		return null
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 0xFFFFFFFF  # Check all collision layers
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	
	for result in results:
		var collider = result.collider
		
		# Check StaticBody2D objects (like WoodCrates)
		if collider is StaticBody2D and collider != self:
			if collider.has_method("is_attack_target") and collider.is_attack_target(collider):
				return collider
		
		# Check Area2D objects and their parents
		elif collider is Area2D:
			var parent = collider.get_parent()
			if parent != self and parent.has_method("is_attack_target"):
				if parent.is_attack_target(parent):
					return parent
			elif collider != self and collider.has_method("is_attack_target"):
				if collider.is_attack_target(collider):
					return collider
	
	return null

func get_interactable_at_position(world_pos: Vector2, max_range: float):
	"""Check for interactable GameObjects directly at cursor position"""
	var player_pos = global_position
	var distance = world_pos.distance_to(player_pos)
		
	if distance > max_range:
		return null
	
	var space_state = get_world_2d().direct_space_state
	
	# First try point query for Area2D objects
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 0xFFFFFFFF  # Check all collision layers
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	for result in results:
		var collider = result.collider
		
		# Check if collider is an Area2D whose parent is a GameObject
		if collider is Area2D and collider.get_parent() is GameObject:
			var target_object = collider.get_parent()
			if target_object != self and target_object.has_method("is_interactable"):
				if target_object.is_interactable():
					return target_object
		
		# Check if collider is directly a GameObject (unlikely but possible)
		elif collider is GameObject:
			if collider != self and collider.has_method("is_interactable"):
				if collider.is_interactable():
					return collider
	
	return null

func get_tool_target_at_position(world_pos: Vector2, tool_item) -> Variant:
	"""Check for valid tool targets (objects or tiles) at cursor position"""
	var player_pos = global_position
	if world_pos.distance_to(player_pos) > tool_item.target_range:
		return null
	
	# First check for GameObject targets
	var object_target = check_tool_object_at_position(world_pos, tool_item.tool_action)
	if object_target:
		return object_target
	
	# Then check for tile targets
	var tile_target = check_tool_tile_at_position(world_pos, tool_item.tool_action)
	if tile_target != Vector2i(-999, -999):
		return tile_target
	
	return null

func check_tool_object_at_position(world_pos: Vector2, tool_action: String):
	"""Check for GameObjects that can be targeted by this tool"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 0xFFFFFFFF  # Check all collision layers
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	for result in results:
		var collider = result.collider
		
		# Check if collider is an Area2D whose parent is a GameObject
		if collider is Area2D and collider.get_parent() is GameObject:
			var target_object = collider.get_parent()
			if target_object != self and check_object_tool_compatibility(target_object, tool_action):
				return target_object
		
		# Check if collider is directly a GameObject
		elif collider is GameObject:
			if collider != self and check_object_tool_compatibility(collider, tool_action):
				return collider
	
	return null

func check_tool_tile_at_position(world_pos: Vector2, tool_action: String) -> Vector2i:
	"""Check for tiles that can be targeted by this tool"""
	var tile_pos = tilemap.local_to_map(tilemap.to_local(world_pos))
	var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
	
	if not tile_data:
		return Vector2i(-999, -999)
	
	# Match tool action to tile properties
	match tool_action:
		"dig":
			if tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable"):
				return tile_pos
	
	return Vector2i(-999, -999)

func check_object_tool_compatibility(obj: GameObject, tool_action: String) -> bool:
	"""Check if an object can be targeted by this tool action"""
	match tool_action:
		"chop":
			return obj.category == "terrain" and ("tree" in obj.name.to_lower() or "coconut" in obj.name.to_lower())
		"harvest":
			return obj.category == "terrain" and obj.has_method("is_interactable") and obj.is_interactable()
		"dig":
			return false  # Dig targets tiles, not objects
	
	return false

func snap_crosshair_to_target(target: Node2D):
	"""Position crosshair at target's location and manage hover effects"""
	cursor_area.global_position = target.global_position
	
	# Store current target for interaction system
	current_targeted_object = target
	
	# Handle hover effects for GameObjects
	if target is GameObject:
		set_hover_target(target)
	else:
		clear_hover_target()
	
	# Show crosshair for attackable targets, hide for peaceful interactions
	var show_crosshair = false
	if target.has_method("is_attack_target") and target.is_attack_target(target):
		show_crosshair = true
	elif target.has_method("is_attackable") and target.is_attackable():
		show_crosshair = true
	
	# Update crosshair visibility
	set_crosshair_visibility(show_crosshair)
	
	# Clear tile highlights when targeting objects (not tiles)
	clear_tile_highlights()
	current_highlighted_tile = Vector2i(-999, -999)

func snap_crosshair_to_tile(tile_pos: Vector2i):
	"""Position crosshair at tile's center, highlight it, and hide crosshair symbol"""
	var world_pos = tilemap.map_to_local(tile_pos)
	cursor_area.global_position = world_pos
	
	# Store tile as current target
	current_targeted_object = tile_pos  # Store the tile position as target
	
	# Hide crosshair for tile targets (digging is peaceful)
	set_crosshair_visibility(false)
	
	# Update tile highlighting for this targeted tile
	update_tile_highlights_for_target(tile_pos)

func raycast_attackable_targets(origin: Vector2, direction: Vector2, weapon) -> Node2D:
	return generic_raycast_targeting(
		origin, direction, weapon.target_range, weapon.target_spread,
		single_raycast_for_attackables
	)

func raycast_interactable_objects(origin: Vector2, direction: Vector2, max_range: float, spread_width: float) -> GameObject:
	return generic_raycast_targeting(
		origin, direction, max_range, spread_width,
		single_raycast_for_interactables
	)

func raycast_tool_targets(origin: Vector2, direction: Vector2, tool) -> Variant:
	return generic_raycast_targeting(
		origin, direction, tool.target_range, tool.target_spread,
		func(o, d, r): return check_tool_targets_at_ray(o, d, r, tool.tool_action)
	)

func generic_raycast_targeting(origin: Vector2, direction: Vector2, max_range: float, spread_width: float, raycast_callback: Callable) -> Variant:
	"""Generic raycast with spread pattern - uses callback for specific target detection"""
	
	# Center raycast first
	var center_target = raycast_callback.call(origin, direction, max_range)
	if center_target != null:
		return center_target
	
	# Spread raycasts
	var spread_hits: Array = []
	var spread_angles = generate_spread_angles(spread_width)
	
	for angle in spread_angles:
		var spread_direction = direction.rotated(deg_to_rad(angle))
		var hit = raycast_callback.call(origin, spread_direction, max_range)
		if hit != null:
			var distance = calculate_distance_to_target(origin, hit)
			spread_hits.append({
				"target": hit,
				"distance": distance,
				"angle_from_center": abs(angle)
			})
	
	if spread_hits.size() > 0:
		spread_hits.sort_custom(func(a, b):
			if abs(a.distance - b.distance) < 5.0:
				return a.angle_from_center < b.angle_from_center
			return a.distance < b.distance
		)
		return spread_hits[0].target
	
	return null

func calculate_distance_to_target(origin: Vector2, target: Variant) -> float:
	"""Handle distance calculation for both objects and tiles"""
	if typeof(target) == TYPE_VECTOR2I:
		var tile_world_pos = tilemap.map_to_local(target)
		return origin.distance_to(tile_world_pos)
	else:
		return origin.distance_to(target.global_position)

func single_raycast_for_attackables(origin: Vector2, direction: Vector2, max_range: float) -> Node2D:
	"""Single raycast to find attackable targets"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin, origin + direction * max_range)
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		var hit_object = result.collider
		
		# Check StaticBody2D (like crates)
		if hit_object is StaticBody2D and hit_object != self:
			if hit_object.has_method("is_attack_target") and hit_object.is_attack_target(hit_object):
				return hit_object
		
		# Check Area2D and parents
		elif hit_object is Area2D:
			var parent = hit_object.get_parent()
			if parent != self and parent.has_method("is_attack_target"):
				if parent.is_attack_target(parent):
					return parent
			elif hit_object != self and hit_object.has_method("is_attack_target"):
				if hit_object.is_attack_target(hit_object):
					return hit_object
	
	return null

func single_raycast_for_interactables(origin: Vector2, direction: Vector2, max_range: float) -> GameObject:
	"""Single raycast to find interactable GameObjects"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin, origin + direction * max_range)
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		var hit_object = result.collider
		
		# Check if collider is an Area2D whose parent is a GameObject
		if hit_object is Area2D and hit_object.get_parent() is GameObject:
			var target_object = hit_object.get_parent()
			if target_object != self and target_object.has_method("is_interactable"):
				if target_object.is_interactable():
					return target_object
		
		# Check if collider is directly a GameObject
		elif hit_object is GameObject:
			if hit_object != self and hit_object.has_method("is_interactable"):
				if hit_object.is_interactable():
					return hit_object
	
	return null

func check_tool_targets_at_ray(origin: Vector2, direction: Vector2, max_range: float, tool_action: String) -> Variant:
	"""Check for tool targets along a ray"""
	# First check for GameObject targets that match tool action
	var object_target = raycast_for_tool_objects(origin, direction, max_range, tool_action)
	if object_target:
		return object_target
	
	# Then check for tile targets that match tool action  
	var tile_target = raycast_for_tool_tiles(origin, direction, max_range, tool_action)
	if tile_target != Vector2i(-999, -999):
		return tile_target
	
	return null

func raycast_for_tool_objects(origin: Vector2, direction: Vector2, max_range: float, tool_action: String) -> GameObject:
	"""Raycast for GameObjects that can be targeted by this tool action"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin, origin + direction * max_range)
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		var hit_object = result.collider
		if hit_object is Area2D and hit_object.get_parent() is GameObject:
			var target = hit_object.get_parent()
			if target != self and check_object_tool_compatibility(target, tool_action):
				return target
		elif hit_object is GameObject:
			if hit_object != self and check_object_tool_compatibility(hit_object, tool_action):
				return hit_object
	
	return null

func raycast_for_tool_tiles(origin: Vector2, direction: Vector2, max_range: float, tool_action: String) -> Vector2i:
	"""Raycast for tiles that can be targeted by this tool action"""
	# Sample points along the ray to check for tiles
	var step_size = 16.0  # Check every 16 pixels
	var steps = int(max_range / step_size)
	
	for i in range(1, steps + 1):
		var test_pos = origin + direction * (i * step_size)
		var tile_pos = tilemap.local_to_map(tilemap.to_local(test_pos))
		var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
		
		if tile_data:
			match tool_action:
				"dig":
					if tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable"):
						return tile_pos
	
	return Vector2i(-999, -999)

func generate_spread_angles(spread_width: float) -> Array[float]:
	"""Generate angles from center outward for spread targeting"""
	var angles: Array[float] = []
	var step = 5.0  # 5-degree increments
	var half_spread = spread_width / 2.0
	
	for i in range(1, int(half_spread / step) + 1):
		var angle = i * step
		angles.append(-angle)  # Left side
		angles.append(angle)   # Right side
	
	return angles

func update_tile_highlights_for_target(target_tile: Vector2i):
	"""Update tile highlights only for the targeted tile"""
	# Check if we need to update (only if target tile changed)
	if target_tile == current_highlighted_tile:
		return  # No change needed
	
	# Clear previous highlights
	clear_tile_highlights()
	current_highlighted_tile = target_tile
	
	# Create highlight for the targeted tile
	if target_tile != Vector2i(-999, -999):
		create_tile_highlight_optimized(target_tile)

func set_crosshair_visibility(visible: bool):
	"""Show or hide the crosshair + symbol"""
	if cursor_area.has_node("Crosshair"):
		var crosshair = cursor_area.get_node("Crosshair")
		crosshair.visible = visible

func set_hover_target(target: GameObject):
	"""Set a new hover target and manage hover effects"""
	# Clear previous hover if different target
	if current_hover_target and current_hover_target != target:
		if is_instance_valid(current_hover_target):
			current_hover_target._on_hover_exit()
	
	# Set new hover target
	current_hover_target = target
	if target and target.has_method("_on_hover_enter"):
		target._on_hover_enter()

func clear_hover_target():
	"""Clear current hover target and effects"""
	if current_hover_target:
		if is_instance_valid(current_hover_target):
			current_hover_target._on_hover_exit()
		current_hover_target = null
