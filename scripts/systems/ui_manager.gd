extends Node
class_name UIManager

# References to UI elements
var player_menu: PlayerMenu
var object_inventory_menu: Control
var current_object: Node2D

signal object_menu_opened(object: Node2D)
signal object_menu_closed

func _ready():
	add_to_group("ui_manager")
	print("UIManager initialized")
	call_deferred("initialize")

func initialize():
	# Find UI references - we are already under the UI layer
	var ui_layer = get_parent()
	
	player_menu = ui_layer.get_node_or_null("PlayerMenu")
	object_inventory_menu = ui_layer.get_node_or_null("ObjectInventoryMenu")
	
	if not player_menu:
		print("ERROR: Could not find PlayerMenu")
	else:
		print("Found PlayerMenu successfully")
	if not object_inventory_menu:
		print("ERROR: Could not find ObjectInventoryMenu")
	else:
		print("Found ObjectInventoryMenu successfully")

func open_object_menu(object: Node2D, object_name: String, _slot_count: int):
	print("Opening object menu for: ", object_name)
	
	# Close player menu if it's open
	if player_menu and player_menu.is_open:
		player_menu.close_player_menu()
	
	# Store reference to current object
	current_object = object
	
	# Show the object inventory menu
	if object_inventory_menu:
		if object_inventory_menu.has_method("open_for_object"):
			object_inventory_menu.open_for_object(object, object_name, _slot_count)
		else:
			print("ERROR: ObjectInventoryMenu missing open_for_object method")
			# Fallback - just show it
			object_inventory_menu.visible = true
	
	object_menu_opened.emit(object)

func close_object_menu():
	print("Closing object menu")
	
	# Hide object inventory menu
	if object_inventory_menu:
		if object_inventory_menu.has_method("close_menu"):
			object_inventory_menu.close_menu()
		else:
			# Fallback - just hide it
			object_inventory_menu.visible = false
	
	current_object = null
	object_menu_closed.emit()

func is_object_menu_open() -> bool:
	return object_inventory_menu and object_inventory_menu.visible

func get_current_object() -> Node2D:
	return current_object
