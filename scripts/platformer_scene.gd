extends Node2D

# Main game scene controller
# Handles coordination between game systems and UI

@onready var ui_layer: CanvasLayer = $UI
@onready var hotbar = $UI/Hotbar
@onready var weaponbar = $UI/WeaponBar
@onready var player_menu: Control = $UI/PlayerMenu
@onready var main_inventory: Control =  $UI/PlayerMenu/TabBar/InventoryTab/MainInventory
@onready var inventory_system: Node = $UI/InventorySystem
@onready var player: CharacterBody2D = $Player
@onready var pause_menu = $UI/PauseMenu
@onready var player_stats: PlayerStats
@onready var equipment_panel: Control = $UI/PlayerMenu/TabBar/EquipmentTab/HBoxContainer/EquipmentPanel
@onready var equipment_inventory: Control = $UI/PlayerMenu/TabBar/EquipmentTab/HBoxContainer/InventoryPanel/EquipmentInventory

var inventory_is_open: bool = false
var respawn_position: Vector2

func _ready():
	# Set up inventory system references
	inventory_system.setup_ui_references(hotbar, main_inventory, weaponbar, equipment_panel, equipment_inventory)
	
	# Connect inventory system signals
	inventory_system.inventory_toggled.connect(_on_inventory_toggled)
	
	# Ensure crafting menu is properly initialized
	await get_tree().process_frame
	
	print("Game scene initialized with inventory system")
	
	pause_menu.resume_requested.connect(_on_resume)
	pause_menu.restart_requested.connect(_on_restart)
	pause_menu.respawn_requested.connect(_on_respawn)

	# Get reference to player stats
	player_stats = player.player_stats
	
	if player_stats:
		var stats_timer = $UI/StatsUpdateTimer
		player_stats.setup_timer(stats_timer)
		player_stats.stat_depleted.connect(_close_menus_on_death)

	respawn_position = player.global_position # Initial position
	
	# Create and add Resource Manager
	var resource_manager = preload("res://scripts/resource_manager.gd").new()
	add_child(resource_manager)
	
	# Connect ResourceManager to the StatusUpdateTimer
	var resource_timer = $Resources/TwoSecondTimer
	resource_manager.setup_timer(resource_timer)

	var water_flow_manager = $WaterFlowManager
	if water_flow_manager:
		water_flow_manager.tile_flooded.connect(_on_tile_flooded)
		water_flow_manager.flow_completed.connect(_on_water_flow_completed)


	# Create UI manager group
	add_to_group("ui_manager")

func _on_tile_flooded(_tile_pos: Vector2i, _water_type: int):
	# You could add particle effects, sounds, etc. here
	pass

func _on_water_flow_completed():
	print("Water flow animation completed")

func _on_inventory_toggled(is_open: bool):
	inventory_is_open = is_open
	print("Inventory is now ", "open" if is_open else "closed")
	
	# Notify player script about inventory state
	if player.has_signal("inventory_state_changed"):
		player.inventory_state_changed.emit(is_open)

func _input(event):
	if player.is_dead:
		return
	# Handle TAB and ESC keys for inventory
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed:
			if key_event.keycode == KEY_TAB or key_event.keycode == KEY_ESCAPE:
				if event.keycode == KEY_ESCAPE and PlacementManager.placement_active:
					PlacementManager.cancel_structure_placement()
					get_viewport().set_input_as_handled()
				else:
					# Check if object menu is open first (priority over player menu)
					var object_menus = get_tree().get_nodes_in_group("object_menu")
					var object_menu_closed = false
					
					for obj_menu in object_menus:
						if obj_menu.visible:
							obj_menu.close_inventory()
							object_menu_closed = true
							break
					
					# If no object inventory was closed, handle normal Tab/Escape behavior
					if not object_menu_closed:
						if key_event.keycode == KEY_TAB:
							# TAB toggles the combined menu open/closed if they are not in the air
							if player.is_on_floor() or player.is_underwater:
								player_menu.visible = not player_menu.visible
								inventory_system.emit_inventory_toggled(player_menu.visible)
							else:
								print("Cannot open menus while airborne")
						elif key_event.keycode == KEY_ESCAPE:
							if player_menu.visible:
								player_menu.visible = false
								inventory_system.inventory_toggled.emit(false)
							else:
								pause_menu.show()
								get_tree().paused = true
					get_viewport().set_input_as_handled()
				
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			hotbar.select_slot(hotbar.selected_slot - 1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			hotbar.select_slot(hotbar.selected_slot + 1)
			get_viewport().set_input_as_handled()
	
	# Debug keys to test stats system
	if event.is_action_pressed("ui_up"):
		# Test damage
		if player_stats:
			player_stats.modify_health(-10)
			print("Debug: Took 10 damage")
	
	if event.is_action_pressed("ui_down"):  # Escape key  
		# Test oxygen depletion
		if player_stats:
			player_stats.modify_oxygen(-20)
			print("Debug: Lost 20 oxygen")

	if event.is_action_pressed("ui_left"):  # Escape key  
		# Test thirst depletion
		if player_stats:
			player_stats.modify_thirst(-20)
			print("Debug: Lost 20 thirst")

	if event.is_action_pressed("ui_right"):  # Escape key  
		# Test hunger depletion
		if player_stats:
			player_stats.modify_hunger(-20)
			print("Debug: Lost 20 hunger")

func _on_resume():
	pause_menu.hide()
	get_tree().paused = false

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_respawn():
	player.player_stats.reset_stats()
	player.is_dead = false
	player.get_node("AnimatedSprite2D").play("idle")
	player.global_position = respawn_position
	pause_menu.hide()
	get_tree().paused = false
	pause_menu.set_resume_enabled(true)

func _close_menus_on_death(stat_name: String):
	if stat_name == "health":
		$UI/PlayerMenu.visible = false
		inventory_system.inventory_toggled.emit(false)
		if $UI.has_node("ObjectMenu"):
			$UI/ObjectMenu.visible = false

func open_object_menu(object: Node2D, title: String, slot_count: int):
	# Create or show object inventory UI
	var object_menu_ui = get_node_or_null("UI/ObjectMenu")
	
	if not object_menu_ui:
		# Create the UI if it doesn't exist
		object_menu_ui = preload("res://scenes/ui/object_menu.tscn").instantiate()
		$UI.add_child(object_menu_ui)
	
	object_menu_ui.open_object_menu(object, title, slot_count)
