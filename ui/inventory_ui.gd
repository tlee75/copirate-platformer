extends Control

@onready var inventory_grid: GridContainer = $"BackgroundPanel/InventoryGrid"

var inventory: Inventory
var inventory_slot_scene: PackedScene = preload("res://ui/inventory_slot.tscn")

func _ready():
	hide() # Inventory starts hidden

func setup_inventory_ui(inv: Inventory):
	inventory = inv
	inventory.inventory_changed.connect(update_inventory_display)
	update_inventory_display()

func update_inventory_display():
	for child in inventory_grid.get_children():
		child.queue_free()

	for i in range(inventory.capacity):
		var inventory_slot_instance = inventory_slot_scene.instantiate()
		inventory_grid.add_child(inventory_slot_instance)
		inventory_slot_instance.slot_index = i
		inventory_slot_instance.set_inventory_slot_data(inventory.get_slot(i))
		inventory_slot_instance.slot_gui_input.connect(_on_slot_gui_input)
		inventory_slot_instance.item_dropped_on_slot.connect(_on_item_dropped_on_slot)

func _on_slot_gui_input(event: InputEvent, slot_index: int):
	# This is where drag will start
	pass # Handled by _get_drag_data in InventorySlot

func _on_item_dropped_on_slot(source_slot_index: int, target_slot_index: int):
	inventory.swap_slots(source_slot_index, target_slot_index)
