extends Control
class_name ObjectInventoryMenu

# Node references
var object_item_list: Control
var player_item_list: Control
var title_label: Label
var object_label: Label
var status_label: Label
var take_button: Button
var move_button: Button
var close_button: Button
var player_label: Label

# Action buttons (will be created dynamically)
var action_container: HBoxContainer
var action_buttons: Array[Button] = []

# Current object data
var current_object: Node2D
var current_object_name: String
var interactive_obj: InteractiveObjectComponent

# Selection state
var selected_object_item: InventoryManager.ItemStack
var selected_player_item: InventoryManager.ItemStack
var active_panel: String = "object"

func _ready():
	add_to_group("object_menu")
	_setup_references()
	_connect_signals()
	hide()

func _setup_references():
	title_label = $MainContainer/Header/TitleLabel
	object_label = $MainContainer/ContentContainer/RightPanel/ObjectLabel
	status_label = $MainContainer/ContentContainer/RightPanel/StatusLabel
	object_item_list = $MainContainer/ContentContainer/RightPanel/ObjectItemList
	player_item_list = $MainContainer/ContentContainer/LeftPanel/PlayerItemList
	player_label = $MainContainer/ContentContainer/LeftPanel/PlayerLabel

	take_button = $MainContainer/Footer/ActionContainer/TakeButton
	move_button = $MainContainer/Footer/ActionContainer/MoveButton  
	close_button = $MainContainer/Footer/ActionContainer/CloseButton
	action_container = $MainContainer/Footer/ActionContainer

func _connect_signals():
	if take_button:
		take_button.pressed.connect(_on_take_button_pressed)
	if move_button:
		move_button.pressed.connect(_on_move_button_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	if object_item_list and object_item_list.has_signal("item_selected"):
		object_item_list.item_selected.connect(_on_object_item_selected)
	if player_item_list and player_item_list.has_signal("item_selected"):
		player_item_list.item_selected.connect(_on_player_item_selected)

func open_for_object(object: Node2D, object_name: String, _slot_count: int):
	current_object = object
	current_object_name = object_name
	interactive_obj = _get_interactive_object()
	
	if not interactive_obj:
		print("Error: No InteractiveObjectComponent found on ", object_name)
		return
	
	# Connect to object signals if available
	_connect_object_signals()
	
	title_label.text = object_name + " Inventory"
	object_label.text = object_name + " Items"
	player_label.text = "Player Items"
	
	_setup_action_buttons()
	_update_status_display()
	_refresh_displays()
	visible = true
	
	print("Opened object inventory for: ", object_name)

func close_menu():
	selected_object_item = null
	selected_player_item = null
	current_object = null
	interactive_obj = null
	_clear_action_buttons()
	visible = false
	print("Closed object inventory")

func _refresh_displays():
	"""Refresh both inventory displays"""
	_load_object_inventory()
	_load_player_inventory()
	_update_status_display()
	_update_action_buttons()

func _load_object_inventory():
	if not interactive_obj:
		return
	
	var object_items = interactive_obj.inventory
	print("DEBUG: Object inventory has ", object_items.size(), " stacks")
	
	if object_item_list and object_item_list.has_method("refresh_items"):
		object_item_list.refresh_items(object_items)

func _load_player_inventory():
	var player_items = InventoryManager.inventory_items
	print("DEBUG: Player inventory has ", player_items.size(), " items")
	
	if player_item_list and player_item_list.has_method("refresh_items"):
		player_item_list.refresh_items(player_items)

func _get_interactive_object() -> InteractiveObjectComponent:
	if not current_object:
		return null
	
	for child in current_object.get_children():
		if child is InteractiveObjectComponent:
			return child
	return null

# ============================================================================
# ACTION SYSTEM INTEGRATION
# ============================================================================

func _setup_action_buttons():
	"""Create action buttons based on object's available actions"""
	_clear_action_buttons()
	
	if not current_object or not current_object.has_method("get_available_actions"):
		return
	
	var actions = current_object.get_available_actions()
	print("DEBUG: Object has actions: ", actions)
	
	for action_name in actions:
		var button = Button.new()
		button.text = action_name
		button.custom_minimum_size = Vector2(100, 40)
		button.pressed.connect(_on_action_button_pressed.bind(action_name))
		
		# Insert before the close button
		var close_button_index = action_container.get_child_count() - 1
		action_container.add_child(button)
		action_container.move_child(button, close_button_index)
		
		action_buttons.append(button)

func _clear_action_buttons():
	"""Remove all dynamically created action buttons"""
	for button in action_buttons:
		if is_instance_valid(button):
			button.queue_free()
	action_buttons.clear()

func _update_action_buttons():
	"""Update action buttons based on current object state"""
	if not current_object or not current_object.has_method("get_available_actions"):
		return
	
	var current_actions = current_object.get_available_actions()
	
	# Check if actions have changed
	var button_actions = []
	for button in action_buttons:
		if is_instance_valid(button):
			button_actions.append(button.text)
	
	# If actions changed, recreate buttons
	if button_actions != current_actions:
		print("DEBUG: Actions changed, updating buttons")
		_setup_action_buttons()

func _update_status_display():
	"""Update the status label with object's current state"""
	if not status_label or not current_object:
		return
	
	var status_text = ""
	
	# Get object state description if available
	if current_object.has_method("get_current_state_description"):
		status_text = current_object.get_current_state_description()
	
	# Add fuel/inventory info
	if interactive_obj:
		var fuel_count = interactive_obj.get_item_count("Stick")  # Example fuel item
	
	status_label.text = status_text

func _on_action_button_pressed(action_name: String):
	"""Handle action button presses"""
	print("DEBUG: Action button pressed: ", action_name)
	
	if not current_object or not current_object.has_method("perform_action"):
		print("Error: Object cannot perform actions")
		return
	
	# Perform the action
	current_object.perform_action(action_name)
	
	# Refresh displays to reflect any changes
	_refresh_displays()
	
	print("Performed action: ", action_name, " on ", current_object_name)

# ============================================================================
# BUTTON HANDLERS
# ============================================================================

func _on_take_button_pressed():
	if selected_object_item:
		_transfer_from_object_to_player(selected_object_item)

func _on_move_button_pressed():
	if selected_player_item:
		_transfer_from_player_to_object(selected_player_item)

func _on_close_button_pressed():
	close_menu()

# ============================================================================
# ITEM SELECTION HANDLERS
# ============================================================================

func _on_object_item_selected(stack: InventoryManager.ItemStack):
	selected_object_item = stack
	selected_player_item = null
	active_panel = "object"
	_update_button_states()

func _on_player_item_selected(stack: InventoryManager.ItemStack):
	selected_player_item = stack
	selected_object_item = null
	active_panel = "player"
	_update_button_states()

func _update_button_states():
	if take_button:
		take_button.disabled = (selected_object_item == null or selected_object_item.quantity <= 0)
	if move_button:
		move_button.disabled = (selected_player_item == null or selected_player_item.quantity <= 0)

# ============================================================================
# TRANSFER SYSTEM
# ============================================================================

func _transfer_from_player_to_object(player_stack: InventoryManager.ItemStack):
	"""Transfer 1 item from player to object using centralized validation"""
	if not player_stack or not interactive_obj:
		return
	
	if player_stack.quantity <= 0:
		print("Cannot transfer - player stack is empty")
		return
	
	print("DEBUG: Attempting to transfer 1x ", player_stack.item.name, " from player to object")
	
	if not interactive_obj.can_accept_item(player_stack.item, 1):
		print(interactive_obj.get_rejection_reason(player_stack.item, 1))
		return
	
	if interactive_obj.add_item(player_stack.item, 1):
		InventoryManager.remove_items_by_name(player_stack.item.name, 1)
		_refresh_displays()
		print("Successfully transferred 1x ", player_stack.item.name, " to ", current_object_name)
	else:
		print("Transfer failed - object could not accept item")

func _transfer_from_object_to_player(object_stack: InventoryManager.ItemStack):
	"""Transfer 1 item from object to player"""
	if not object_stack or not interactive_obj:
		return
	
	if object_stack.quantity <= 0:
		print("Cannot transfer - object stack is empty")
		return
	
	print("DEBUG: Transferring 1x ", object_stack.item.name, " from object to player")
	
	if InventoryManager.add_item(object_stack.item, 1):
		interactive_obj.remove_item(object_stack.item.name, 1)
		_refresh_displays()
		print("Successfully transferred 1x ", object_stack.item.name, " to player")
	else:
		print("Failed to add item to player inventory")

func _connect_object_signals():
	"""Connect to object-specific signals for real-time updates"""
	if not current_object:
		return
	
	# Connect to firepit signals if this is a firepit
	if current_object.has_signal("state_changed"):
		if not current_object.state_changed.is_connected(_on_object_state_changed):
			current_object.state_changed.connect(_on_object_state_changed)
	
	if current_object.has_signal("fuel_consumed"):
		if not current_object.fuel_consumed.is_connected(_on_fuel_consumed):
			current_object.fuel_consumed.connect(_on_fuel_consumed)

func _on_object_state_changed(new_state: int, description: String):
	"""Handle object state changes"""
	_update_status_display()
	_update_action_buttons()

func _on_fuel_consumed(remaining_time: float):
	"""Handle fuel consumption updates"""
	_update_status_display()
