extends Control
class_name PlayerMenu

# Equipment tab components
var equipment_category_filter
var equipment_body_display  
var equipment_item_list
var equipment_item_detail: InventoryItemDetail
var equipment_action_panel

var tab_container
var inventory_tab
var crafting_tab
var equipment_tab
var category_filter: InventoryCategoryFilter
var item_list: InventoryItemList
var item_detail
var action_panel
var input_handler: PlayerInputHandler

var current_category: String = "all"
var is_open: bool = false

func _ready():
	add_to_group("player_menu")  # Add to group so it can be found
	_setup_ui_references()
	_setup_input_handler()
	_connect_signals()
	_initialize_ui()
	print("DEBUG: InventoryUI._ready() completed")

	# Add some test equipment items for testing
	if InventoryManager:
		InventoryManager.debug_add_test_items()


func _on_tab_changed(tab_index: int):
	print("Tab changed to index: ", tab_index)
	var tab = get_current_tab()
	if tab == "inventory":
		if category_filter and category_filter.has_method("refresh_categories"):
			category_filter.refresh_categories()
		_refresh_current_view()
		await get_tree().process_frame
		_auto_select_first_item()
	elif tab == "equipment":
		_on_equipment_category_selected("all")
		# Optionally, auto-select first equipment item here if needed
	elif tab == "crafting":
		# Add crafting refresh logic here if needed
		pass

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

func _setup_ui_references():
	tab_container = $TabContainer
	inventory_tab = $TabContainer/Inventory
	crafting_tab = $TabContainer/Crafting
	equipment_tab = $TabContainer/Equipment
	
	# Set up inventory tab components
	category_filter = $TabContainer/Inventory/HeaderSection/InventoryCategoryFilter
	item_list = $TabContainer/Inventory/ContentSection/InventoryItemList
	item_detail = $TabContainer/Inventory/ContentSection/InventoryItemDetail
	action_panel = $TabContainer/Inventory/FooterSection/InventoryActionPanel
	
	# Set up equipment tab components - ADD THESE LINES
	equipment_category_filter = $TabContainer/Equipment/HeaderSection/EquipmentCategoryFilter
	equipment_body_display = $TabContainer/Equipment/ContentSection/EquipmentBodyDisplay
	equipment_item_list = $TabContainer/Equipment/ContentSection/RightPanelSplit/EquipmentItemList
	equipment_item_detail = $TabContainer/Equipment/ContentSection/RightPanelSplit/EquipmentItemDetail
	equipment_action_panel = $TabContainer/Equipment/FooterSection/EquipmentActionPanel

func _setup_input_handler():
	# Reference the singleton autoload instead of creating a new instance
	input_handler = PlayerInputHandler
	
	# Pass input handler to all components (with null checks)
	if item_list and item_list.has_method("set_input_handler"):
		item_list.set_input_handler(input_handler)
	if item_detail and item_detail.has_method("set_input_handler"):
		item_detail.set_input_handler(input_handler)
	if action_panel and action_panel.has_method("set_input_handler"):
		action_panel.set_input_handler(input_handler)
	
	# Set input handler for equipment components
	if equipment_item_list and equipment_item_list.has_method("set_input_handler"):
		equipment_item_list.set_input_handler(input_handler)
	if equipment_item_detail and equipment_item_detail.has_method("set_input_handler"):
		equipment_item_detail.set_input_handler(input_handler)
	if equipment_action_panel and equipment_action_panel.has_method("set_input_handler"):
		equipment_action_panel.set_input_handler(input_handler)

func _connect_signals():
	# Category filter signals
	if category_filter and category_filter.has_signal("category_selected"):
		category_filter.category_selected.connect(_on_category_selected)
	
	# Item list signals
	if item_list and item_list.has_signal("item_selected"):
		item_list.item_selected.connect(_on_item_selected)
	if item_list and item_list.has_signal("item_action_requested"):
		item_list.item_action_requested.connect(_on_item_action_requested)
	if item_list and item_list.has_signal("item_buttons_created"):
		item_list.item_buttons_created.connect(_auto_select_first_item)

	# Equipment tab signals
	if equipment_category_filter:
		equipment_category_filter.category_selected.connect(_on_equipment_category_selected)
	
	if equipment_body_display:
		equipment_body_display.equipment_slot_selected.connect(_on_equipment_slot_selected)
	
	if equipment_item_list:
		equipment_item_list.item_selected.connect(_on_equipment_item_selected)
	
	if equipment_action_panel:
		equipment_action_panel.action_requested.connect(_on_equipment_action_requested)	

	# Action panel signals
	if action_panel and action_panel.has_signal("action_requested"):
		action_panel.action_requested.connect(_on_action_requested)
	
	# Input handler signals
	input_handler.action_executed.connect(_on_action_executed)
	input_handler.input_mode_changed.connect(_on_input_mode_changed)
	
	# Inventory manager signals
	InventoryManager.inventory_changed.connect(_refresh_current_view)
	InventoryManager.equipment_changed.connect(_refresh_current_view)
	InventoryManager.quick_access_changed.connect(_refresh_current_view)

	# Watch for tab changes
	tab_container.tab_changed.connect(_on_tab_changed)

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

func open_player_menu():
	if is_open:
		return
	
	is_open = true
	visible = true
	
	## Notify player correctly (TRUE when opening)
	#var player = get_tree().get_first_node_in_group("player")
	#if player and player.has_method("_on_inventory_state_changed"):
		#player._on_inventory_state_changed(true)

	## Refresh inventory categories
	if category_filter and category_filter.has_method("refresh_categories"):
		category_filter.refresh_categories()
	
	# Update input handler
	input_handler.set_player_menu_open(true)
	
	tab_container.current_tab = tab_container.current_tab

	print("Player Menu opened - Default tab: ", get_current_tab())

func close_player_menu():
	if not is_open:
		return
	
	is_open = false
	visible = false
	
	# Notify player that player menu closed
	#var player = get_tree().get_first_node_in_group("player")
	#if player and player.has_method("_on_inventory_state_changed"):
		#player._on_inventory_state_changed(false)  # FALSE when closing
	
	# Update input handler
	input_handler.set_player_menu_open(false)
	
	print("Player Menu closed")

func toggle_player_menu():
	if is_open:
		close_player_menu()
	else:
		open_player_menu()

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

func get_equipment_items_by_category(category: String) -> Array:
	"""Get equipment items filtered by equipment category"""
	var all_items = InventoryManager.inventory_items
	var equipment_items: Array[InventoryManager.ItemStack] = []
	
	for stack in all_items:
		var item_category = stack.item.category
		var is_equipment = _is_equipment_item(item_category)
		
		if is_equipment:
			if category == "all":
				equipment_items.append(stack)
			elif category == "weapons" and _is_weapon_category(item_category):
				equipment_items.append(stack)
			elif category == "armor" and _is_armor_category(item_category):
				equipment_items.append(stack)
			elif category == "accessories" and _is_accessory_category(item_category):
				equipment_items.append(stack)
	
	return equipment_items

func _is_equipment_item(item_category: String) -> bool:
	"""Check if an item category represents equipment"""
	var equipment_categories = [
		"weapon", "helmet", "chest", "armor", "legs", "hands", "feet", "arms", 
		"shield", "accessory"
	]
	return item_category in equipment_categories

func _is_weapon_category(item_category: String) -> bool:
	return item_category in ["weapon", "tool"]

func _is_armor_category(item_category: String) -> bool:
	return item_category in ["helmet", "chest", "armor", "legs", "hands", "feet", "arms", "shield"]

func _is_accessory_category(item_category: String) -> bool:
	return item_category in ["accessory"]

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
	if item_list and item_list.has_method("get_selected_item"):
		return item_list.get_selected_item()
	return null

func _auto_select_first_item():
	print("DEBUG: _auto_select_first_item() called for category: ", current_category)
	if item_list and item_list.has_method("get_items"):
		var items = item_list.get_items()
		print("DEBUG: Items in item_list: ", items.size())
		if items.size() > 0:
			# Only select if nothing is currently selected
			if item_list.get_selected_stack() == null: 
				var first_item = items[0]
				print("DEBUG: Auto-selecting first item: ", first_item.item.name)
				item_list.set_selected_index(0)
				_on_item_selected(first_item)
		else:
			print("DEBUG: No items to auto-select in category: ", current_category)
			if item_detail:
				item_detail.display_item(null)
	else:
		print("DEBUG: item_list does not have get_items()")

## Tab management methods
#func switch_to_tab(tab_name: String):
	#if not tab_container:
		#return
	#
	#match tab_name.to_lower():
		#"inventory":
			#tab_container.current_tab = 0
		#"crafting":
			#tab_container.current_tab = 1
		#"equipment":
			#tab_container.current_tab = 2
		#_:
			#print("Unknown tab: ", tab_name)

func get_current_tab() -> String:
	if not tab_container:
		return "inventory"
	
	match tab_container.current_tab:
		0:
			return "inventory"
		1:
			return "crafting"
		2:
			return "equipment"
		_:
			return "inventory"

#func get_current_tab_index() -> int:
	#if not tab_container:
		#return 0
	#return tab_container.current_tab
	
# Equipment tab event handlers
func _on_equipment_category_selected(category: String):
	print("Equipment category selected: ", category)
	
	# Get filtered equipment items
	var equipment_items = get_equipment_items_by_category(category)
	
	# Update equipment item list
	if equipment_item_list and equipment_item_list.has_method("refresh_items"):
		equipment_item_list.refresh_items(equipment_items)
		print("Updated equipment list with ", equipment_items.size(), " items")
	
	# Auto-select first equipment item
	await get_tree().process_frame
	if equipment_items.size() > 0:
		var first_item = equipment_items[0]
		if equipment_item_list and equipment_item_list.has_method("set_selected_index"):
			equipment_item_list.set_selected_index(0)
		_on_equipment_item_selected(first_item)

func _on_equipment_slot_selected(slot_type: String, item_stack):
	print("Equipment slot selected: ", slot_type, " with item: ", item_stack.item.name if item_stack else "empty")
	# TODO: Select corresponding item in equipment item list

func _on_equipment_item_selected(stack: InventoryManager.ItemStack):
	print("Equipment item selected: ", stack.item.name)
	# Update equipment item detail panel
	if equipment_item_detail:
		equipment_item_detail.display_item(stack)
	
	# Update equipment action panel
	if equipment_action_panel:
		print("DEBUG: Calling equipment_action_panel.display_actions_for_item()")
		equipment_action_panel.display_actions_for_item(stack, {})
	else:
		print("DEBUG: ERROR - equipment_action_panel is null!")

func _on_equipment_action_requested(action_type: InventoryActionResolver.ActionType):
	var selected_stack = equipment_item_list.get_selected_stack() if equipment_item_list else null
	if selected_stack:
		_execute_action(action_type, selected_stack)
