extends CharacterBody2D

class_name Player

const WALK_SPEED := 100.0
const RUN_SPEED := 250.0
const JUMP_VELOCITY := -400.0
const STEP_HEIGHT: float = 10.0  # Max height in pixels to auto-step over

@export var max_cursor_distance: float = 80.0  # Adjustable in editor
@export var default_interact_range: float = 80.0   # Default interaction range
@export var default_interact_spread: float = 20.0  # Default interaction spread

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float
var _step_cooldown: float = 0.0
var was_airborne: bool = false
var is_trigger_action: bool = false
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
var last_frame_on_floor: bool = true
var _water_jump_active: bool = false
var current_hover_target: GameObject = null
var current_targeted_object: Variant = null

# UI Manager reference for centralized state checking
var ui_manager: UIManager

# Player stats system
var player_stats: PlayerStats

# Water movement effects
var swim_speed: float = 150.0
var is_underwater: bool = false
var is_at_breathable_surface: bool = false
var water_depth: int = 0
@export var sea_level_y: int = 68  # Set in editor to the y tile coordinate of sea level

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

	# Connect to Player input handler once the scene is ready
	call_deferred("_connect_to_player_input_handler_ui")

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
	if is_trigger_action:
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
		water_depth = tile_pos.y - sea_level_y
		# Check if the tile above is breathable (open air or breathable tile)
		var above_data = tilemap.get_cell_tile_data(0, tile_pos + Vector2i(0, -1))
		is_at_breathable_surface = not above_data or (above_data.has_custom_data("breathable") and above_data.get_custom_data("breathable"))
		if is_at_breathable_surface:
			player_stats.set_underwater_status(false)
			var tile_below = tile_pos + Vector2i(0, 1)
			var tile_data_below = tilemap.get_cell_tile_data(0, tile_below)
			var is_water_below = tile_data_below and tile_data_below.has_custom_data("is_water") and tile_data_below.get_custom_data("is_water")
			if is_water_below:
				is_underwater = true
			else:
				is_underwater = false
		else:
			is_underwater = true
			player_stats.set_underwater_status(is_underwater)
	else:
		water_depth = 0
		is_at_breathable_surface = false
		is_underwater = false
		_water_jump_active = false
		player_stats.set_underwater_status(is_underwater)

	# Detect walking off a ledge (became airborne without pressing jump)
	var on_floor_now = is_on_floor()
	if not on_floor_now and last_frame_on_floor and not Input.is_action_just_pressed("jump"):
		var is_running = Input.is_key_pressed(KEY_SHIFT)
		was_running_when_jumped = is_running
		jump_speed = RUN_SPEED if is_running else WALK_SPEED
	last_frame_on_floor = on_floor_now

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

	# Jump — runs before vertical swim so the flag prevents swim from overriding it
	if Input.is_action_just_pressed("jump") and (is_on_floor() and not is_underwater or (is_underwater and is_at_breathable_surface)):
		vel.y = JUMP_VELOCITY
		was_running_when_jumped = Input.is_key_pressed(KEY_SHIFT)
		jump_speed = RUN_SPEED if was_running_when_jumped else WALK_SPEED
		if is_underwater:
			_water_jump_active = true

	# Clear water jump flag once the upward arc is over
	if _water_jump_active and vel.y >= 0:
		_water_jump_active = false

	if vertical_dir != 0:
		if is_underwater and not _water_jump_active:
			var tile_pixel_y = tile_pos.y * tile_size
			var offset_in_tile = global_position.y - tile_pixel_y # 0 = top of tile, tile_size = bottom
			var near_top = offset_in_tile < 5.0 # Threshold to adjust in pixels
	
	# Swimming up/down when underwater
			var is_sprint_swimming = Input.is_key_pressed(KEY_SHIFT)
			var current_swim_speed = swim_speed * 1.5 if is_sprint_swimming else swim_speed
	
	# Stop at water surface when swimming up
			if vertical_dir < 0 and is_at_breathable_surface and near_top:
				vel.y = 0
			else:
				vel.y = vertical_dir * current_swim_speed
	
	# Normalize diagonal movement
			if dir != 0 and vertical_dir != 0:
				var movement_vector = Vector2(vel.x, vel.y)
				movement_vector = movement_vector.normalized() * current_swim_speed
				vel.x = movement_vector.x
				vel.y = movement_vector.y
		elif not is_underwater:
	# Climbing placeholder for on land
			if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
				print("Trying to climb ", "up" if vertical_dir < 0 else "down", " - no climable serface found")

	# Update cursor area position based on mouse position
	update_cursor_position()
	
	handle_use_action()

	# Update physics first
	move_and_slide()
	velocity = vel
	_step_cooldown = max(0.0, _step_cooldown - get_physics_process_delta_time())
	try_step_up()
	
	# Update collision shape orientation for swimming
	update_collision_orientation()

	# Handle animations after physics update
	handle_animations()

func handle_use_action():
	var any_menu_open = ui_manager.is_any_menu_open() if ui_manager else PlayerInputHandler.is_player_menu_open
	if any_menu_open or is_trigger_action:
		return

	if PlacementManager.placement_active:
		return

	var selected_stack = get_selected_quick_access_item()
	var item = selected_stack.item if selected_stack else null
	var target = current_targeted_object
	var melee = GameObjectsDatabase.game_objects_database.get("melee")
	var hands = GameObjectsDatabase.game_objects_database.get("hands")

	# LEFT CLICK — use selected item, melee fallback, or swing at air
	if Input.is_action_just_pressed("mouse_left") and not is_mouse_over_quick_access() and not is_mouse_over_inventory():
		# Priority 1: Selected item on target
		if item and can_use_item_in_current_environment(item) and target != null and is_valid_target(target, item):
			item.use(self, target, selected_stack)
			return
		# Priority 2: Melee fallback on target
		if target != null and melee and is_valid_target(target, melee):
			melee.use(self, target, null)
			return
		# Priority 3: No target — swing at air
		# Use selected item by itself if possible; otherwise always punch
		var solo_item = null
		if item and can_use_item_in_current_environment(item) and item.use_animation != "":
			solo_item = item
		else:
			solo_item = GameObjectsDatabase.game_objects_database.get("melee")
			selected_stack = null
		if solo_item and can_use_item_in_current_environment(solo_item):
			solo_item.use(self, null, selected_stack)
		return

	# E KEY — interact using hands
	if Input.is_action_just_pressed("interact"):
		if target != null and hands and is_valid_target(target, hands):
			hands.use(self, target, null)
			return
		# Fallback: call interact() directly on the target
		if target != null and typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target.has_method("interact"):
			target.interact()
		return

func try_use_item(stack: InventoryManager.ItemStack) -> bool:
	"""Used by inventory UI to consume/use an item with player state validation."""
	if is_dead or is_trigger_action:
		print("Cannot use item: player is busy or dead")
		return false
	if not can_use_item_in_current_environment(stack.item):
		print("Cannot use ", stack.item.name, " in current environment!")
		return false
	stack.item.use(self, null, stack)
	return true

func is_valid_target(target: Variant, item: GameItem) -> bool:
	"""Check if this item can be used on the target (tool action match, damage, or both)"""
	if target == null:
		return false
	# Tile targets — need a matching target_action
	if typeof(target) == TYPE_VECTOR2I:
		if item.target_action == "":
			return false
		var tile_data = tilemap.get_cell_tile_data(0, target as Vector2i)
		if not tile_data:
			return false
		match item.target_action:
			"dig":
				return tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable")
		return false
	# Object targets
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target):
		# Tool compatible?
		if item.target_action != "" and target is GameObject and check_object_tool_compatibility(target, item.target_action):
			return true
	return false

func _can_any_action_handle(target, selected_item) -> bool:
	"""Check if left-click can do anything with this target (selected item or melee)"""
	if selected_item and is_valid_target(target, selected_item):
		return true
	var melee = GameObjectsDatabase.game_objects_database.get("melee")
	if melee and is_valid_target(target, melee):
		return true
	return false

func handle_animations():
	# Don't change animations while in the middle of an action or dead
	if is_trigger_action or is_dead:
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
	# Keep cursor area at mouse position always (for facing direction)
	cursor_area.position = get_global_mouse_position() - global_position

	# New smart targeting system
	update_crosshair_targeting()

	# Face the direction of movement when moving; otherwise, face the crosshair direction when idle
	if abs(velocity.x) > 1.0:
		$AnimatedSprite2D.flip_h = last_move_dir < 0
	else:
		var crosshair_direction = cursor_area.position.normalized()
		$AnimatedSprite2D.flip_h = crosshair_direction.x < 0

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
	# I believe we should trigger animations here when appropriate
	if success:
		match action_type:
			InventoryActionResolver.ActionType.EQUIP:
				print("Item equipped: ", stack.item.name)
			InventoryActionResolver.ActionType.USE:
				print("Item used: ", stack.item.name)
				print("Perform animation?")
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
	var quick_access: QuickAccessDisplay = ui_layer.get_node_or_null("QuickAccess")
	if not quick_access:
		return null
	return quick_access.get_selected_stack()

func is_on_water_tile() -> bool:
	var tile_pos = tilemap.local_to_map(global_position)
	var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
	if tile_data and tile_data.has_custom_data("is_water"):
		return tile_data.get_custom_data("is_water")
	return false

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

func is_attack_target(target):
	return target and target.has_method("is_attack_target") and target.is_attack_target()

func is_tile_target(tile_pos: Vector2i):
	var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
	return tile_data and tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable")

func try_step_up() -> void:
	"""Automatically snap up over short ledges when walking into them"""
	if not is_on_floor() or velocity.x == 0 or is_underwater:
		return

	var move_dir = sign(velocity.x)

	# Is there a wall blocking us at current height?
	if not test_move(global_transform, Vector2(move_dir * 2, 0)):
		return

	# Is the space above us clear?
	if test_move(global_transform, Vector2(0, -STEP_HEIGHT)):
		return

	# Is the space ahead of us clear at the elevated height?
	var raised_transform = global_transform
	raised_transform.origin.y -= STEP_HEIGHT
	if test_move(raised_transform, Vector2(move_dir * 2, 0)):
		return

	# All checks passed — step up
	global_position.y -= STEP_HEIGHT
	_step_cooldown = 0.1

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

func _connect_to_player_input_handler_ui():
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
	"""Main targeting logic — two pipelines, one per input key"""
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	var direction = (mouse_pos - player_pos).normalized()

	var quick_stack = get_selected_quick_access_item()
	var selected_item = quick_stack.item if quick_stack else null
	var hands = GameObjectsDatabase.game_objects_database.get("hands")
	var melee = GameObjectsDatabase.game_objects_database.get("melee")

	# ---------------------------------------------------------------
	# USE PIPELINE (left-click): selected item -> melee fallback
	# Range is determined by the item itself
	# ---------------------------------------------------------------

	# Direct cursor check (use)
	var use_target = find_use_target_at_position(mouse_pos, selected_item, melee)
	if use_target != null:
		if typeof(use_target) == TYPE_VECTOR2I:
			snap_crosshair_to_tile(use_target)
		else:
			snap_crosshair_to_target(use_target, true)
		return

	# Raycast check (use)
	var use_raycast = raycast_use_targets(player_pos, direction, selected_item, melee)
	if use_raycast != null:
		if typeof(use_raycast) == TYPE_VECTOR2I:
			snap_crosshair_to_tile(use_raycast)
		else:
			snap_crosshair_to_target(use_raycast, true)
		return

	# ---------------------------------------------------------------
	# INTERACT PIPELINE (E key): hands item only
	# Range is hands.target_range
	# ---------------------------------------------------------------

	if hands:
		# Direct cursor check (interact)
		var interact_target = find_interact_target_at_position(mouse_pos, hands)
		if interact_target != null:
			snap_crosshair_to_target(interact_target, false)
			return

		# Raycast check (interact)
		var interact_raycast = raycast_interact_targets(player_pos, direction, hands)
		if interact_raycast != null:
			snap_crosshair_to_target(interact_raycast, false)
			return

	# FALLBACK: no target found
	current_targeted_object = null
	clear_hover_target()
	set_crosshair_visibility(false)
	clear_tile_highlights()
	current_highlighted_tile = Vector2i(-999, -999)

func find_use_target_at_position(world_pos: Vector2, selected_item: GameItem, melee: GameItem) -> Variant:
	"""Find the best use target (left-click) at the cursor position.
	Checks selected item first, then melee fallback. Returns object or tile Vector2i."""
	# Try selected item
	if selected_item and can_use_item_in_current_environment(selected_item):
		if world_pos.distance_to(global_position) <= selected_item.target_range:
			var obj = _find_valid_object_at(world_pos, selected_item)
			if obj:
				return obj
			if selected_item.target_action != "":
				var tile = _find_valid_tile_at(world_pos, selected_item.target_action)
				if tile != Vector2i(-999, -999):
					return tile
	# Try melee fallback
	if melee and world_pos.distance_to(global_position) <= melee.target_range:
		var obj = _find_valid_object_at(world_pos, melee)
		if obj:
			return obj
	return null

func find_interact_target_at_position(world_pos: Vector2, hands: GameItem) -> GameObject:
	"""Find the best interact target (E key / hands) at the cursor position."""
	if world_pos.distance_to(global_position) > hands.target_range:
		return null
	return _find_valid_object_at(world_pos, hands)

func _find_valid_object_at(world_pos: Vector2, item: GameItem) -> Variant:
	"""Physics query at world_pos, return first object is_valid_target for item."""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = true
	query.collide_with_bodies = true
	for result in space_state.intersect_point(query):
		var collider = result.collider
		var obj = collider
		if collider is Area2D:
			obj = collider.get_parent()
		if obj != self and is_valid_target(obj, item):
			return obj
	return null

func _find_valid_tile_at(world_pos: Vector2, target_action: String) -> Vector2i:
	"""Check if the tile at world_pos is valid for this target_action."""
	var tile_pos = tilemap.local_to_map(tilemap.to_local(world_pos))
	var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
	if not tile_data:
		return Vector2i(-999, -999)
	match target_action:
		"dig":
			if tile_data.has_custom_data("is_diggable") and tile_data.get_custom_data("is_diggable"):
				return tile_pos
	return Vector2i(-999, -999)

func check_object_tool_compatibility(obj: GameObject, target_action: String) -> bool:
	"""Check if an object can be targeted by this tool action"""
	return target_action in obj.loot_table

func snap_crosshair_to_target(target: Node2D, show_crosshair: bool = true):
	"""Position crosshair at target's location and manage hover effects"""
	current_targeted_object = target

	var crosshair: Node2D = get_node_or_null("Crosshair")
	if crosshair:
		crosshair.global_position = target.global_position
		if crosshair.has_method("set_radius"):
			var radius: float = target.get_crosshair_radius() if target is GameObject else 28.0
			crosshair.set_radius(radius)

	if target is GameObject:
		set_hover_target(target)
	else:
		clear_hover_target()

	set_crosshair_visibility(show_crosshair)
	clear_tile_highlights()
	current_highlighted_tile = Vector2i(-999, -999)

func snap_crosshair_to_tile(tile_pos: Vector2i):
	"""Position crosshair at tile's center, highlight it, and hide crosshair symbol"""
	current_targeted_object = tile_pos

	# Hide crosshair for tile targets (digging uses the highlight overlay instead)
	set_crosshair_visibility(false)

	# Update tile highlighting for this targeted tile
	update_tile_highlights_for_target(tile_pos)

func raycast_use_targets(origin: Vector2, direction: Vector2, selected_item: GameItem, melee: GameItem) -> Variant:
	"""Raycast to find best use target (left-click). Selected item first, melee fallback."""
	# Try selected item
	if selected_item and can_use_item_in_current_environment(selected_item):
		var hit = generic_raycast_targeting(
			origin, direction, selected_item.target_range, selected_item.target_spread,
			func(o, d, r): return _raycast_for_item(o, d, r, selected_item)
		)
		if hit != null:
			return hit
	# Try melee fallback
	if melee:
		var hit = generic_raycast_targeting(
			origin, direction, melee.target_range, melee.target_spread,
			func(o, d, r): return _raycast_for_item(o, d, r, melee)
		)
		if hit != null:
			return hit
	return null

func raycast_interact_targets(origin: Vector2, direction: Vector2, hands: GameItem) -> GameObject:
	"""Raycast to find best interact target (E key / hands)."""
	return generic_raycast_targeting(
		origin, direction, hands.target_range, hands.target_spread,
		func(o, d, r): return _raycast_for_item(o, d, r, hands)
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

func _raycast_for_item(origin: Vector2, direction: Vector2, max_range: float, item: GameItem) -> Variant:
	"""Single raycast returning the first valid target for this item (object or tile)."""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin, origin + direction * max_range)
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		var hit = result.collider
		var obj = hit
		if hit is Area2D:
			obj = hit.get_parent()
		if obj != self and is_valid_target(obj, item):
			return obj
	# If item has a target_action, also check tiles along the ray
	if item.target_action != "":
		var step_size = 16.0
		var steps = int(max_range / step_size)
		for i in range(1, steps + 1):
			var test_pos = origin + direction * (i * step_size)
			var tile = _find_valid_tile_at(test_pos, item.target_action)
			if tile != Vector2i(-999, -999):
				return tile
	return null



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
	if has_node("Crosshair"):
		var crosshair = get_node("Crosshair")
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
