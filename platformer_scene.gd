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
	# Handle TAB key for inventory
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_TAB:
			main_inventory.toggle_inventory()
			inventory_is_open = main_inventory.is_visible_flag
			get_viewport().set_input_as_handled()
