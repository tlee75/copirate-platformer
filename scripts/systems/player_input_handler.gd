extends Node

# Unified input handler for inventory and quick access across all device types
# Processes mouse/keyboard, controller, and touch input uniformly  
# Handles both menu navigation and quick access cycling

signal action_executed(action_type: InventoryActionResolver.ActionType, stack: InventoryManager.ItemStack, success: bool)
signal input_mode_changed(new_mode: InventoryActionResolver.InputMethod)

var action_resolver: InventoryActionResolver
var current_input_mode: InventoryActionResolver.InputMethod = InventoryActionResolver.InputMethod.MOUSE_KEYBOARD
var selected_stack: InventoryManager.ItemStack = null
var is_player_menu_open: bool = false

# Quick access state
var selected_quick_access_slot: int = 0
var quick_access_items: Array[InventoryManager.ItemStack] = []

# Touch/controller navigation state
var selected_category: String = "all"
var selected_item_index: int = 0
var available_items: Array[InventoryManager.ItemStack] = []

func _ready():
	action_resolver = InventoryActionResolver.new()
	_detect_initial_input_mode()
	set_process_unhandled_input(true)
	print("DEBUG: PlayerInputHandler singleton initialized")

func _input(event):
	if event.is_action_pressed("player_menu_toggle"):
		var inventory_ui = get_tree().get_first_node_in_group("player_menu")
		if inventory_ui and inventory_ui.has_method("toggle_player_menu"):
			inventory_ui.toggle_player_menu()
			get_viewport().set_input_as_handled()
	
	if is_player_menu_open:
		_handle_menu_input(event)  # Existing functionality
	else:
		_handle_quick_access_input(event)  # New functionality
	
	## Handle mouse wheel scrolling when inventory is open
	#if event is InputEventMouseButton and event.pressed:
		#if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			#var player_menu = get_tree().get_first_node_in_group("player_menu")
			#if player_menu:
				#var item_list = player_menu.item_list
				#if item_list:
					#if event.button_index == MOUSE_BUTTON_WHEEL_UP:
						#if item_list.has_method("scroll_up"):
							#item_list.scroll_up()
					#else:
						#if item_list.has_method("scroll_down"):
							#item_list.scroll_down()
			#get_viewport().set_input_as_handled()
			#return

#func _unhandled_input(event):
	## Only detect input mode changes for controller/keyboard input
	#if event is InputEventJoypadButton and event.pvar inventory_ui = get_tree().get_first_node_in_group("inventory_ui")ressed:
		#set_input_mode(InventoryActionResolver.InputMethod.CONTROLLER)
	#elif event is InputEventKey and event.pressed:
		## Don't switch to keyboard mode, stay in mouse mode for UI interaction
		#pass
	#
	## Handle input based on current mode (controller only)
	#if current_input_mode == InventoryActionResolver.InputMethod.CONTROLLER:
		#_handle_controller_input(event)

func _detect_initial_input_mode():
	# Check for connected controllers
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		set_input_mode(InventoryActionResolver.InputMethod.CONTROLLER)
	else:
		set_input_mode(InventoryActionResolver.InputMethod.MOUSE_KEYBOARD)

func _update_input_mode(event):
	var new_mode = current_input_mode
	
	# Only allow controller input to switch modes when inventory is open
	if is_player_menu_open:
		if event is InputEventJoypadButton and event.pressed:
			new_mode = InventoryActionResolver.InputMethod.CONTROLLER
		# Don't change modes for mouse/keyboard when inventory is open
		return
	
	# Normal mode detection when inventory is closed
	if event is InputEventMouseButton:
		new_mode = InventoryActionResolver.InputMethod.MOUSE_KEYBOARD
	elif event is InputEventJoypadButton and event.pressed:
		new_mode = InventoryActionResolver.InputMethod.CONTROLLER
	elif event is InputEventScreenTouch:
		new_mode = InventoryActionResolver.InputMethod.TOUCH
	
	if new_mode != current_input_mode:
		set_input_mode(new_mode)

func set_input_mode(mode: InventoryActionResolver.InputMethod):
	if mode == current_input_mode:
		return
	
	var old_mode = current_input_mode
	current_input_mode = mode
	
	print("Input mode changed: ", _input_mode_to_string(old_mode), " -> ", _input_mode_to_string(mode))
	
	# Reset navigation state when switching modes
	_reset_navigation_state()
	
	input_mode_changed.emit(current_input_mode)

func _handle_mouse_keyboard_input(event):
	# Handle direct action inputs
	if event.is_action_pressed("inventory_use"):
		if selected_stack:
			_execute_primary_action(selected_stack)
	
	elif event.is_action_pressed("inventory_equip"):
		if selected_stack:
			_execute_action_by_input("inventory_equip", selected_stack)
	
	elif event.is_action_pressed("inventory_quick_move"):
		if selected_stack:
			_execute_action_by_input("inventory_quick_move", selected_stack)
	
	elif event.is_action_pressed("inventory_drop"):
		if selected_stack:
			_execute_action_by_input("inventory_drop", selected_stack)
	
	elif event.is_action_pressed("inventory_lock"):
		if selected_stack:
			_execute_action_by_input("inventory_lock", selected_stack)

func _handle_controller_input(event):
	if not event.is_pressed():
		return
	
	# Handle navigation inputs
	if event.is_action_pressed("ui_up"):
		_navigate_items(-1)
	elif event.is_action_pressed("ui_down"):
		_navigate_items(1)
	elif event.is_action_pressed("ui_left"):
		_navigate_categories(-1)
	elif event.is_action_pressed("ui_right"):
		_navigate_categories(1)
	
	# Handle action inputs
	elif event.is_action_pressed("inventory_use"):
		var current_stack = _get_current_selected_stack()
		if current_stack:
			_execute_primary_action(current_stack)
	
	elif event.is_action_pressed("inventory_equip"):
		var current_stack = _get_current_selected_stack()
		if current_stack:
			_execute_action_by_input("inventory_equip", current_stack)
	
	elif event.is_action_pressed("inventory_quick_move"):
		var current_stack = _get_current_selected_stack()
		if current_stack:
			_execute_action_by_input("inventory_quick_move", current_stack)
	
	elif event.is_action_pressed("inventory_drop"):
		var current_stack = _get_current_selected_stack()
		if current_stack:
			_execute_action_by_input("inventory_drop", current_stack)
	
	elif event.is_action_pressed("inventory_lock"):
		var current_stack = _get_current_selected_stack()
		if current_stack:
			_execute_action_by_input("inventory_lock", current_stack)

func _handle_touch_input(event):
	# Touch input will be handled by UI elements directly
	# This method processes gesture-based actions
	
	if event is InputEventScreenTouch:
		if event.pressed:
			# Touch down - select item at position
			# TODO: Implement touch selection based on screen coordinates
			pass
		else:
			# Touch release - execute primary action on selected item
			if selected_stack:
				_execute_primary_action(selected_stack)

func _handle_menu_input(event):
	# Handle mouse wheel scrolling when inventory is open
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var player_menu = get_tree().get_first_node_in_group("player_menu")
			if player_menu:
				var item_list = player_menu.item_list
				if item_list:
					if event.button_index == MOUSE_BUTTON_WHEEL_UP:
						if item_list.has_method("scroll_up"):
							item_list.scroll_up()
					else:
						if item_list.has_method("scroll_down"):
							item_list.scroll_down()
			get_viewport().set_input_as_handled()
			return

func _handle_quick_access_input(event):
	"""Handle input when PlayerMenu is closed"""
	if event.is_action_pressed("quick_access_next"):
		_cycle_quick_access_next()
	elif event.is_action_pressed("quick_access_previous"):
		_cycle_quick_access_previous()
	elif event.is_action_pressed("quick_access_select_1"):
		_select_quick_access_slot(0)
	elif event.is_action_pressed("quick_access_select_2"):
		_select_quick_access_slot(1)
	elif event.is_action_pressed("quick_access_select_3"):
		_select_quick_access_slot(2)
	elif event.is_action_pressed("quick_access_select_4"):
		_select_quick_access_slot(3)
	elif event.is_action_pressed("quick_access_select_5"):
		_select_quick_access_slot(4)
	elif event.is_action_pressed("quick_access_select_6"):
		_select_quick_access_slot(5)
	elif event.is_action_pressed("quick_access_select_7"):
		_select_quick_access_slot(6)
	elif event.is_action_pressed("quick_access_select_8"):
		_select_quick_access_slot(7)
	elif event.is_action_pressed("interact"):
		_use_selected_quick_access_item()

func _cycle_quick_access_next():
	"""Cycle to next non-empty quick access slot"""
	_refresh_quick_access_items()
	var start_slot = selected_quick_access_slot
	
	for i in range(8):
		selected_quick_access_slot = (selected_quick_access_slot + 1) % 8
		if quick_access_items[selected_quick_access_slot] != null:
			print("Cycled to quick access slot ", selected_quick_access_slot)
			return
		if selected_quick_access_slot == start_slot:
			break
	
	print("No quick access items to cycle through")

func _cycle_quick_access_previous():
	"""Cycle to previous non-empty quick access slot"""
	_refresh_quick_access_items()
	var start_slot = selected_quick_access_slot
	
	for i in range(8):
		selected_quick_access_slot = (selected_quick_access_slot - 1 + 8) % 8
		if quick_access_items[selected_quick_access_slot] != null:
			print("Cycled to quick access slot ", selected_quick_access_slot)
			return
		if selected_quick_access_slot == start_slot:
			break
	
	print("No quick access items to cycle through")

func _select_quick_access_slot(slot: int):
	"""Directly select specific quick access slot"""
	if slot >= 0 and slot < 8:
		selected_quick_access_slot = slot
		print("Selected quick access slot ", slot)

func _use_selected_quick_access_item():
	"""Use item in currently selected quick access slot"""
	_refresh_quick_access_items()
	var stack = quick_access_items[selected_quick_access_slot]
	if stack:
		_execute_primary_action(stack)
	else:
		print("No item in quick access slot ", selected_quick_access_slot)

func _refresh_quick_access_items():
	"""Update cached quick access items array"""
	quick_access_items.clear()
	quick_access_items.resize(8)
	
	for i in range(8):
		quick_access_items[i] = InventoryManager.get_quick_access_stack(i)

func _navigate_items(direction: int):
	if available_items.size() == 0:
		_refresh_available_items()
		return
	
	selected_item_index = clamp(selected_item_index + direction, 0, available_items.size() - 1)
	print("Selected item: ", selected_item_index, "/", available_items.size() - 1, " - ", _get_current_selected_stack().item.name if _get_current_selected_stack() else "None")

func _navigate_categories(direction: int):
	var categories = InventoryManager.get_available_categories()
	var current_index = categories.find(selected_category)
	
	if current_index == -1:
		current_index = 0
	
	current_index = clamp(current_index + direction, 0, categories.size() - 1)
	selected_category = categories[current_index]
	selected_item_index = 0  # Reset item selection when changing categories
	
	_refresh_available_items()
	print("Selected category: ", selected_category, " (", available_items.size(), " items)")

func _refresh_available_items():
	available_items = InventoryManager.get_items_by_category(selected_category)
	selected_item_index = clamp(selected_item_index, 0, max(0, available_items.size() - 1))

func _get_current_selected_stack() -> InventoryManager.ItemStack:
	if available_items.size() == 0:
		_refresh_available_items()
	
	if selected_item_index >= 0 and selected_item_index < available_items.size():
		return available_items[selected_item_index]
	
	return null

func _reset_navigation_state():
	selected_item_index = 0
	selected_category = "all"
	_refresh_available_items()

func _execute_primary_action(stack: InventoryManager.ItemStack):
	var action = action_resolver.get_action_for_input("inventory_use", stack)
	if action:
		var success = action_resolver.execute_action(action.type, stack)
		print("Executed primary action '", action.label, "' on ", stack.item.name, " - Success: ", success)
		action_executed.emit(action.type, stack, success)
		
		# Refresh navigation if items changed
		if success:
			_refresh_available_items()
	else:
		print("No primary action available for ", stack.item.name)

func _execute_action_by_input(input_action: String, stack: InventoryManager.ItemStack):
	var action = action_resolver.get_action_for_input(input_action, stack)
	if action:
		var success = action_resolver.execute_action(action.type, stack)
		print("Executed ", input_action, " action '", action.label, "' on ", stack.item.name, " - Success: ", success)
		action_executed.emit(action.type, stack, success)
		
		# Refresh navigation if items changed
		if success:
			_refresh_available_items()
	else:
		print("No action available for ", input_action, " on ", stack.item.name)

func execute_action_on_stack(action_type: InventoryActionResolver.ActionType, stack: InventoryManager.ItemStack) -> bool:
	if not stack:
		return false
	
	var success = action_resolver.execute_action(action_type, stack)
	action_executed.emit(action_type, stack, success)
	
	if success:
		_refresh_available_items()
	
	return success

func set_player_menu_open(open: bool):
	is_player_menu_open = open
	if open:
		_refresh_available_items()
	else:
		_reset_navigation_state()

func set_selected_stack(stack: InventoryManager.ItemStack):
	selected_stack = stack

func get_available_actions_for_stack(stack: InventoryManager.ItemStack, context: Dictionary = {}) -> Array[InventoryActionResolver.ActionData]:
	return action_resolver.get_available_actions(stack)

func get_current_input_mode() -> InventoryActionResolver.InputMethod:
	return current_input_mode

func get_selected_category() -> String:
	return selected_category

func get_selected_item_index() -> int:
	return selected_item_index

func get_available_items() -> Array[InventoryManager.ItemStack]:
	return available_items

func _input_mode_to_string(mode: InventoryActionResolver.InputMethod) -> String:
	match mode:
		InventoryActionResolver.InputMethod.MOUSE_KEYBOARD:
			return "Mouse/Keyboard"
		InventoryActionResolver.InputMethod.CONTROLLER:
			return "Controller"
		InventoryActionResolver.InputMethod.TOUCH:
			return "Touch"
		_:
			return "Unknown"
