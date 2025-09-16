extends Node2D

# Main game scene controller
# Handles coordination between game systems and UI

@onready var ui_layer: CanvasLayer = $UI
@onready var hotbar: Control = $UI/Hotbar
@onready var main_inventory: Control = $UI/MainInventory
@onready var inventory_system: Node = $UI/InventorySystem
@onready var player: CharacterBody2D = $Player

var inventory_is_open: bool = false

func _ready():
	# Set up inventory system references
	inventory_system.setup_ui_references(hotbar, main_inventory)
	
	# Connect inventory system signals
	inventory_system.inventory_toggled.connect(_on_inventory_toggled)
	
	print("Game scene initialized with inventory system")

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
				# TAB toggles inventory open/closed
				main_inventory.toggle_inventory()
				inventory_is_open = main_inventory.is_visible_flag
				
				# Notify player script about inventory state change
				if player.has_signal("inventory_state_changed"):
					player.inventory_state_changed.emit(inventory_is_open)
				
				get_viewport().set_input_as_handled()
			
			elif key_event.keycode == KEY_ESCAPE and inventory_is_open:
				# ESC only closes inventory when it's open
				main_inventory.hide_inventory()
				inventory_is_open = false
				
				# Notify player script about inventory state change
				if player.has_signal("inventory_state_changed"):
					player.inventory_state_changed.emit(inventory_is_open)
				
				get_viewport().set_input_as_handled()
