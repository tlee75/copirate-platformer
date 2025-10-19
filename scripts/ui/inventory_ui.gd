@tool
extends Control
class_name InventoryUI

signal inventory_closed

var category_filter
var item_list
var item_detail
var action_panel
var input_handler

var current_category: String = "all"
var is_open: bool = false

func _ready():
	print("DEBUG: InventoryUI mouse_filter = ", mouse_filter)
	print("DEBUG: InventoryUI focus_mode = ", focus_mode)
	print("DEBUG: InventoryUI._ready() called")
	add_to_group("inventory_ui")  # Add to group so it can be found
	_setup_ui_references()
	_setup_input_handler()
	_connect_signals()
	_initialize_ui()
	print("DEBUG: InventoryUI._ready() completed")

func _gui_input(event):
	if event is InputEventMouseButton:
		print("DEBUG: InventoryUI._gui_input - Mouse button event: button=", event.button_index, " pressed=", event.pressed, " is_open=", is_open)
		print("DEBUG: Event position: ", event.position, " global: ", event.global_position)
		
		if is_open and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var ui_rect = Rect2(Vector2.ZERO, size)
			print("DEBUG: InventoryUI rect: ", ui_rect)
			print("DEBUG: Click in bounds: ", ui_rect.has_point(event.position))
			print("DEBUG: InventoryUI mouse_filter: ", mouse_filter)
			print("DEBUG: InventoryUI received click in _gui_input")

#func _input(event):
	#print("DEBUG: InventoryUI._input called, event: ", event.get_class(), ", is_open: ", is_open)
	#
	#if not is_open:
		## Handle TAB to open
		#if event.is_action_pressed("inventory_toggle"):
			#print("DEBUG: TAB detected, opening inventory")
			#var player = get_tree().get_first_node_in_group("player")
			#if player:
				#print("DEBUG: Player found, on_floor: ", player.is_on_floor())
				#if player.is_on_floor() or player.is_underwater():
					#print("DEBUG: Calling open_inventory()")
					#open_inventory()
				#else:
					#print("DEBUG: Player not on floor or underwater")
			#else:
				#print("DEBUG: No player found")
			#get_viewport().set_input_as_handled()
		#return
	#else:
		#print("is_open: ", is_open)
	#
	## Inventory is open - handle close and scrolling
	#if event.is_action_pressed("inventory_toggle"):
		#print("DEBUG: TAB detected, closing inventory")
		#close_inventory()
		#get_viewport().set_input_as_handled()
		#return
	#
	## Mouse wheel scrolling
	#if event is InputEventMouseButton and event.pressed:
		#if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			#if item_list and item_list.has_method("scroll_up"):
				#item_list.scroll_up()
			#get_viewport().set_input_as_handled()
		#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			#if item_list and item_list.has_method("scroll_down"):
				#item_list.scroll_down()
			#get_viewport().set_input_as_handled()

#func _unhandled_input(event):
	#print("DEBUG: InventoryUI._unhandled_input called, event: ", event.get_class())
	#if event.is_action_pressed("inventory_toggle"):
		#print("DEBUG: Tab detected in _unhandled_input")

func _setup_ui_references():
	category_filter = $MainLayout/HeaderSection/InventoryCategoryFilter
	item_list = $MainLayout/ContentSection/InventoryItemList
	item_detail = $MainLayout/ContentSection/InventoryItemDetail
	action_panel = $MainLayout/FooterSection/InventoryActionPanel

func _setup_input_handler():
	# Reference the singleton autoload instead of creating a new instance
	input_handler = InventoryInputHandler
	
	# Pass input handler to all components (with null checks)
	if item_list and item_list.has_method("set_input_handler"):
		item_list.set_input_handler(input_handler)
	if item_detail and item_detail.has_method("set_input_handler"):
		item_detail.set_input_handler(input_handler)
	if action_panel and action_panel.has_method("set_input_handler"):
		action_panel.set_input_handler(input_handler)

func _connect_signals():
	# Category filter signals
	if category_filter and category_filter.has_signal("category_selected"):
		category_filter.category_selected.connect(_on_category_selected)
	
	# Item list signals
	if item_list and item_list.has_signal("item_selected"):
		item_list.item_selected.connect(_on_item_selected)
	if item_list and item_list.has_signal("item_action_requested"):
		item_list.item_action_requested.connect(_on_item_action_requested)
	
	# Action panel signals
	if action_panel and action_panel.has_signal("action_requested"):
		action_panel.action_requested.connect(_on_action_requested)
	
	# Input handler signals
	input_handler.action_executed.connect(_on_action_executed)
	input_handler.input_mode_changed.connect(_on_input_mode_changed)
	
	# Inventory manager signals
	InventoryManager.inventory_changed.connect(_refresh_current_view)
	InventoryManager.equipment_changed.connect(_refresh_current_view)
	InventoryManager.hotbar_changed.connect(_refresh_current_view)

func _initialize_ui():
	print("DEBUG: InventoryUI._initialize_ui() called")
	visible = false
	
	# Ensure all components have proper default states
	if category_filter:
		category_filter.visible = true
	if item_list:
		item_list.visible = true  
	if item_detail:
		item_detail.visible = true
	if action_panel:
		action_panel.visible = true

func open_inventory():
	if is_open:
		return
	
	is_open = true
	visible = true
	
	# Remove this entire test button section:
	# var test_btn = Button.new()
	# test_btn.text = "TEST BUTTON - CLICK ME"
	# ... (delete all test button code)
	
	# Notify player correctly (TRUE when opening)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_on_inventory_state_changed"):
		player._on_inventory_state_changed(true)
	
	# Update input handler
	input_handler.set_inventory_open(true)
	
	# Add debug output
	print("DEBUG: Inventory opened, is_open = ", is_open)
	
	# Refresh all content
	if category_filter and category_filter.has_method("refresh_categories"):
		category_filter.refresh_categories()
	_refresh_current_view()

	# Auto-select first item after refreshing
	await get_tree().process_frame  # Wait for UI to update
	_auto_select_first_item()

	if item_list and item_list.has_method("debug_button_info"):
		await get_tree().process_frame
		item_list.debug_button_info()
		
	print("Inventory UI opened")

func close_inventory():
	if not is_open:
		return
	
	is_open = false
	visible = false
	
	# Notify player that inventory closed
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_on_inventory_state_changed"):
		player._on_inventory_state_changed(false)  # FALSE when closing
	
	# Update input handler
	input_handler.set_inventory_open(false)
	
	# Add debug output
	print("DEBUG: Inventory closed, is_open = ", is_open)
	
	inventory_closed.emit()
	print("Inventory UI closed")

func toggle_inventory():
	if is_open:
		close_inventory()
	else:
		open_inventory()

# More robust ScrollContainer access
func _scroll_item_list(delta: int):
	if not item_list:
		return
		
	# Try to find the ScrollContainer in the item list
	var scroll_container = item_list.get_node_or_null("ScrollContainer")
	if scroll_container and scroll_container is ScrollContainer:
		var new_scroll = scroll_container.scroll_vertical + delta
		var v_scrollbar = scroll_container.get_v_scroll_bar()
		if v_scrollbar:
			new_scroll = clamp(new_scroll, 0, v_scrollbar.max_value)
		scroll_container.scroll_vertical = new_scroll
		print("DEBUG: Scrolled to ", scroll_container.scroll_vertical)  # Debug output
	else:
		print("DEBUG: Could not find ScrollContainer in item list")

func _navigate_item_list(direction: int):
	if item_list and item_list.has_method("navigate_items"):
		item_list.navigate_items(direction)

func _on_category_selected(category: String):
	current_category = category
	_refresh_item_list()
	
	# Auto-select first item in new category
	await get_tree().process_frame  # Wait for item list to refresh
	_auto_select_first_item()
	
	print("Category selected: ", category)

func _on_item_selected(stack: InventoryManager.ItemStack):
	print("DEBUG: InventoryUI._on_item_selected called for: ", stack.item.name)
	
	# Update detail panel
	if item_detail:
		print("DEBUG: Calling item_detail.display_item()")
		item_detail.display_item(stack)
	else:
		print("DEBUG: ERROR - item_detail is null!")
	
	# Create context for action resolution
	var context = {}
	if has_meta("interacting_with_object"):
		context["object_interaction"] = true
		context["object_name"] = get_meta("object_title", "Object")
		context["object_target"] = get_meta("interacting_with_object")
	
	# Update action panel with context
	if action_panel:
		print("DEBUG: Calling action_panel.display_actions_for_item()")
		action_panel.display_actions_for_item(stack, context)
	else:
		print("DEBUG: ERROR - action_panel is null!")
	
	# Update input handler selection
	if input_handler:
		input_handler.set_selected_stack(stack)
	
	print("Item selected: ", stack.item.name)

func _on_item_action_requested(stack: InventoryManager.ItemStack, action_type: InventoryActionResolver.ActionType):
	_execute_action(action_type, stack)

func _on_action_requested(action_type: InventoryActionResolver.ActionType):
	var selected_stack = item_list.get_selected_stack()
	if selected_stack:
		_execute_action(action_type, selected_stack)

func _execute_action(action_type: InventoryActionResolver.ActionType, stack: InventoryManager.ItemStack):
	if input_handler:
		input_handler.execute_action_on_stack(action_type, stack)

func _on_action_executed(action_type: InventoryActionResolver.ActionType, stack: InventoryManager.ItemStack, success: bool):
	print("Action executed: ", action_type, " on ", stack.item.name, " - Success: ", success)
	
	if success:
		# Refresh UI to reflect changes
		_refresh_current_view()

func _on_input_mode_changed(new_mode: InventoryActionResolver.InputMethod):
	print("Input mode changed to: ", new_mode)
	# Could update UI hints based on input mode here

func _refresh_current_view():
	_refresh_item_list()
	_refresh_detail_panel()
	_refresh_action_panel()

func _refresh_item_list():
	var items = InventoryManager.get_items_by_category(current_category)
	if item_list and item_list.has_method("refresh_items"):
		item_list.refresh_items(items)

func _refresh_detail_panel():
	if item_detail and item_detail.has_method("refresh_display"):
		item_detail.refresh_display()

func _refresh_action_panel():
	if action_panel and action_panel.has_method("refresh_actions"):
		action_panel.refresh_actions()

# Public API for external integration
func set_selected_category(category: String):
	if category_filter:
		category_filter.set_selected_category(category)

func get_current_category() -> String:
	return current_category

func get_selected_item() -> InventoryManager.ItemStack:
	return item_list.get_selected_stack() if item_list else null

func handle_object_interaction() -> bool:
	if not has_meta("interacting_with_object"):
		return false
	
	var object = get_meta("interacting_with_object")
	var selected_item = get_currently_selected_item()
	
	if selected_item and object:
		# Check if the object can accept this item
		var object_menu = get_tree().get_first_node_in_group("object_menu")
		if object_menu and object_menu.can_object_accept_item(selected_item.item):
			print("Adding ", selected_item.item.name, " to ", get_meta("object_title", "object"))
			# TODO: Actually transfer the item to the object
			return true
		else:
			print("This object cannot accept ", selected_item.item.name)
	
	return false

func get_currently_selected_item():
	# Get the currently selected item from the item list
	var item_list = $MainLayout/ContentSection/InventoryItemList
	if item_list and item_list.has_method("get_selected_item"):
		return item_list.get_selected_item()
	return null

func _auto_select_first_item():
	"""Automatically select the first item in the current category"""
	print("DEBUG: _auto_select_first_item() called for category: ", current_category)
	var items = InventoryManager.get_items_by_category(current_category)
	
	if items.size() > 0:
		var first_item = items[0]
		print("DEBUG: Auto-selecting first item: ", first_item.item.name)
		
		# Set the selection in the item list
		if item_list and item_list.has_method("set_selected_index"):
			item_list.set_selected_index(0)
		
		# Directly update the details (bypass signal system)
		_on_item_selected(first_item)
	else:
		print("DEBUG: No items to auto-select in category: ", current_category)
		# Clear details when no items
		if item_detail:
			item_detail.display_item(null)
