extends Control

var hotbar_container: HBoxContainer

var inventory: Inventory
var inventory_slot_scene: PackedScene = preload("res://ui/inventory_slot.tscn")

func _ready():
	hotbar_container = get_node("HotbarContainer")
	pass # Hotbar is always visible

func setup_hotbar_ui(inv: Inventory):
	inventory = inv
	inventory.inventory_changed.connect(update_hotbar_display)
	update_hotbar_display()

func update_hotbar_display():
	for child in hotbar_container.get_children():
		child.queue_free()

	for i in range(inventory.capacity): # Assuming hotbar uses first few slots of main inventory
		var inventory_slot_instance = inventory_slot_scene.instantiate()
		hotbar_container.add_child(inventory_slot_instance)
		inventory_slot_instance.slot_index = i
		inventory_slot_instance.set_inventory_slot_data(inventory.get_slot(i))
		inventory_slot_instance.slot_gui_input.connect(_on_slot_gui_input)
		inventory_slot_instance.item_dropped_on_slot.connect(_on_item_dropped_on_slot)

func _on_slot_gui_input(event: InputEvent, slot_index: int):
	# This is where drag will start
	pass # Handled by _get_drag_data in InventorySlot

func _on_item_dropped_on_slot(source_slot_index: int, target_slot_index: int):
	inventory.swap_slots(source_slot_index, target_slot_index)
