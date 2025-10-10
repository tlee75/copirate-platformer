extends Node

class_name InteractiveObject


# Base interface for objects that can be interacted with and have inventories

@export var object_name: String = "Object"
@export var inventory_slots: int = 1
@export var accepted_categories: Array[String] = [] # What item categories this object accepts

var object_menu: Array[InventoryManager.InventorySlotData] = []
var ui_manager: Node

func _ready():
	initialize_inventory()
	
	await get_tree().process_frame
	await get_tree().process_frame

	# Find UI manager
	ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if not ui_manager:
		print("Warning: UI Manager still not found after waiting")

func initialize_inventory():
	object_menu.clear()
	for i in inventory_slots:
		object_menu.append(InventoryManager.InventorySlotData.new())

func interact():
	if ui_manager and ui_manager.has_method("open_object_menu"):
		ui_manager.open_object_menu(get_parent(), object_name, inventory_slots)
	else:
		print("UI Manager not found!")
