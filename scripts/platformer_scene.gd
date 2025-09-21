extends Node2D

# Main game scene controller
# Handles coordination between game systems and UI

@onready var ui_layer: CanvasLayer = $UI
@onready var hotbar = $UI/Hotbar
@onready var crafting_menu: Control = $UI/CraftingMenu
@onready var main_inventory: Control = $UI/CraftingMenu/TabBar/InventoryTab/MainInventory
@onready var inventory_system: Node = $UI/InventorySystem
@onready var player: CharacterBody2D = $Player
@onready var pause_menu = $UI/PauseMenu

var inventory_is_open: bool = false

func _ready():	

	print("PauseMenu found: ", pause_menu != null)
	print("PauseMenu visible: ", pause_menu.visible)
	print("PauseMenu size: ", pause_menu.size)
	print("PauseMenu position: ", pause_menu.position)


	# Set up inventory system references
	inventory_system.setup_ui_references(hotbar, main_inventory)
	
	# Connect inventory system signals
	inventory_system.inventory_toggled.connect(_on_inventory_toggled)
	
	print("Game scene initialized with inventory system")
	
	pause_menu.resume_requested.connect(_on_resume)
	pause_menu.restart_requested.connect(_on_restart)

func _on_inventory_toggled(is_open: bool):
	inventory_is_open = is_open
	print("Inventory is now ", "open" if is_open else "closed")
	
	# Notify player script about inventory state
	if player.has_signal("inventory_state_changed"):
		player.inventory_state_changed.emit(is_open)

func _input(event):
	# Handle TAB and ESC keys for inventory
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed:
			if key_event.keycode == KEY_TAB:
				# TAB toggles the combined menu open/closed
				crafting_menu.visible = not crafting_menu.visible
				#main_inventory.toggle_inventory()
				#inventory_is_open = main_inventory.is_visible_flag
				#
				## Notify player script about inventory state change
				#if player.has_signal("inventory_state_changed"):
					#player.inventory_state_changed.emit(inventory_is_open)
				#
				get_viewport().set_input_as_handled()
			
			elif key_event.keycode == KEY_ESCAPE:
				if crafting_menu.visible:
					crafting_menu.visible = false
				else:
					pause_menu.show()
					get_tree().paused = true
					
				#if inventory_is_open:
					## ESC only closes inventory when it's open
					#main_inventory.hide_inventory()
					#inventory_is_open = false
				#
					## Notify player script about inventory state change
					#if player.has_signal("inventory_state_changed"):
						#player.inventory_state_changed.emit(inventory_is_open)
				#else:
					## Escape opens pause menu
					#pause_menu.show()
					#get_tree().paused = true
				#
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			hotbar.select_slot(hotbar.selected_slot - 1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			hotbar.select_slot(hotbar.selected_slot + 1)
			get_viewport().set_input_as_handled()

func _on_resume():
	pause_menu.hide()
	get_tree().paused = false

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()
