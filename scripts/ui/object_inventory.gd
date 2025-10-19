extends Control

class_name ObjectMenu

var current_object: Node2D
signal inventory_closed

func _ready():
	add_to_group("object_menu")
	hide()

func open_object_menu(object: Node2D, title: String, slot_count: int):
	current_object = object
	
	# Get the main InventoryUI
	var main_scene = get_tree().current_scene
	var inventory_ui = main_scene.get_node("UI/InventoryUI")
	
	if inventory_ui:
		# Set object interaction context
		inventory_ui.set_meta("interacting_with_object", object)
		inventory_ui.set_meta("object_title", title)
		
		# Open the inventory if it's not already open
		if not inventory_ui.visible:
			inventory_ui.toggle_inventory()
		
		print("Opened main inventory for interacting with ", title)
	
	# Signal player that object interaction started
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("object_menu_state_changed"):
		player.object_menu_state_changed.emit(true)

func close_inventory():
	# Clear object interaction context
	var main_scene = get_tree().current_scene
	var inventory_ui = main_scene.get_node("UI/InventoryUI")
	
	if inventory_ui:
		inventory_ui.remove_meta("interacting_with_object")
		inventory_ui.remove_meta("object_title")
	
	hide()
	inventory_closed.emit()
	
	# Signal player that object interaction ended
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("object_menu_state_changed"):
		player.object_menu_state_changed.emit(false)
	
	current_object = null

func can_object_accept_item(item: GameItem) -> bool:
	if not current_object:
		return true
	
	var interactive_object = null
	for child in current_object.get_children():
		if child is InteractiveObject:
			interactive_object = child
			break
	
	if not interactive_object or interactive_object.accepted_categories.is_empty():
		return true
	
	return item.category in interactive_object.accepted_categories

# Compatibility methods for existing code
func get_object_slot(index: int) -> Dictionary:
	return {"item": null, "quantity": 0}

func update_object_slot_display(slot_index: int):
	pass
