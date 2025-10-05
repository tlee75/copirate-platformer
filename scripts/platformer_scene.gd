extends Node2D

# Main game scene controller
# Handles coordination between game systems and UI

@onready var ui_layer: CanvasLayer = $UI
@onready var hotbar = $UI/Hotbar
@onready var weaponbar = $UI/WeaponBar
@onready var crafting_menu: Control = $UI/CraftingMenu
@onready var main_inventory: Control =  $UI/CraftingMenu/TabBar/InventoryTab/MainInventory
@onready var inventory_system: Node = $UI/InventorySystem
@onready var player: CharacterBody2D = $Player
@onready var pause_menu = $UI/PauseMenu
@onready var player_stats: PlayerStats
@onready var equipment_panel: Control = $UI/CraftingMenu/TabBar/EquipmentTab/HBoxContainer/EquipmentPanel
@onready var equipment_inventory: Control = $UI/CraftingMenu/TabBar/EquipmentTab/HBoxContainer/InventoryPanel/EquipmentInventory

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
		player_stats.stat_depleted.connect(_close_menus_on_death)

	respawn_position = player.global_position # Initial position
	

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
			if key_event.keycode == KEY_TAB:
				# TAB toggles the combined menu open/closed
				crafting_menu.visible = not crafting_menu.visible

				get_viewport().set_input_as_handled()
			
			elif key_event.keycode == KEY_ESCAPE:
				if crafting_menu.visible:
					crafting_menu.visible = false
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
	if event.is_action_pressed("ui_accept"):  # Enter key
		# Test damage
		if player_stats:
			player_stats.modify_health(-10)
			print("Debug: Took 10 damage")
	
	if event.is_action_pressed("ui_cancel"):  # Escape key  
		# Test oxygen depletion
		if player_stats:
			player_stats.modify_oxygen(-20)
			print("Debug: Lost 20 oxygen")


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
		$UI/CraftingMenu.visible = false
