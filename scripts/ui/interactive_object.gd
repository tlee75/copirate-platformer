extends Node

class_name InteractiveObject


# Base interface for objects that can be interacted with and have inventories

@export var object_name: String = "Object"
@export var inventory_slots: int = 6
@export var accepted_categories: Array[String] = [] # What item categories this object accepts

var object_inventory: Array[InventoryManager.InventorySlotData] = []
var ui_manager: Node

signal inventory_changed

func _ready():
	initialize_inventory()
	
	await get_tree().process_frame
	await get_tree().process_frame

	# Find UI manager
	ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if not ui_manager:
		print("Warning: UI Manager still not found after waiting")

func initialize_inventory():
	object_inventory.clear()
	for i in inventory_slots:
		object_inventory.append(InventoryManager.InventorySlotData.new())

func interact():
	if ui_manager and ui_manager.has_method("open_object_inventory"):
		ui_manager.open_object_inventory(get_parent(), object_name, inventory_slots)
	else:
		print("UI Manager not found!")

func can_accept_item(item: GameItem) -> bool:
	if accepted_categories.is_empty():
		return true  # Accept all items
	
	return item.category in accepted_categories

func add_item_to_object(item: GameItem, quantity: int = 1) -> int:
	var remaining = quantity
	
	if not can_accept_item(item):
		print("This object cannot accept ", item.name)
		return remaining
	
	# Try to add to existing stacks
	for slot in object_inventory:
		if not slot.is_empty() and slot.item.name == item.name:
			remaining = slot.add_item(item, remaining)
			if remaining <= 0:
				inventory_changed.emit()
				return 0
	
	# Try to add to empty slots
	for slot in object_inventory:
		if slot.is_empty():
			remaining = slot.add_item(item, remaining)
			if remaining <= 0:
				inventory_changed.emit()
				return 0
	
	inventory_changed.emit()
	return remaining

func get_object_slot(index: int) -> InventoryManager.InventorySlotData:
	if index >= 0 and index < object_inventory.size():
		return object_inventory[index]
	return null

func on_inventory_closed():
	# Called when the inventory UI is closed
	print(object_name, " inventory closed")
