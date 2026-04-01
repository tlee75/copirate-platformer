extends Control
class_name PlayerMenu

# Crafting tab components
var crafting_category_filter
var crafting_item_list
var crafting_item_detail
var crafting_action_panel

# Building tab components
var building_tab
var building_category_filter
var building_item_list
var building_item_detail
var building_action_panel

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
	print("DEBUG: PlayerMenu._ready() completed")

	# Add some test equipment items for testing
	#if InventoryManager:
		#InventoryManager.debug_add_test_items()


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
	elif tab == "crafting":
		_on_crafting_category_selected("all")
	elif tab == "building":
		_on_building_category_selected("all")

func _setup_ui_references():
	tab_container = $TabContainer
	inventory_tab = $TabContainer/Inventory

	equipment_tab = $TabContainer/Equipment
	
	# Set up inventory tab components
	category_filter = $TabContainer/Inventory/HeaderSection/InventoryCategoryFilter
	item_list = $TabContainer/Inventory/ContentSection/InventoryItemList
	item_detail = $TabContainer/Inventory/ContentSection/InventoryItemDetail
	action_panel = $TabContainer/Inventory/FooterSection/InventoryActionPanel
	
	# Crafting tab components
	crafting_category_filter = $TabContainer/Crafting/HeaderSection/CraftingCategoryFilter
	crafting_item_list = $TabContainer/Crafting/ContentSection/CraftingItemList
	crafting_item_detail = $TabContainer/Crafting/ContentSection/CraftingItemDetail
	crafting_action_panel = $TabContainer/Crafting/FooterSection/CraftingActionPanel
	
	# Building tab components - Add these lines
	building_category_filter = $TabContainer/Building/HeaderSection/BuildingCategoryFilter
	building_item_list = $TabContainer/Building/ContentSection/BuildingItemList
	building_item_detail = $TabContainer/Building/ContentSection/BuildingItemDetail
	building_action_panel = $TabContainer/Building/FooterSection/BuildingActionPanel
	
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

	# Crafting tab signals
	if crafting_category_filter:
		crafting_category_filter.category_selected.connect(_on_crafting_category_selected)
	if crafting_item_list:
		crafting_item_list.item_selected.connect(_on_crafting_item_selected)
		
	# Equipment tab signals
	if equipment_category_filter:
		equipment_category_filter.category_selected.connect(_on_equipment_category_selected)
	
	if equipment_body_display:
		equipment_body_display.equipment_slot_selected.connect(_on_equipment_slot_selected)
	
	if equipment_item_list:
		equipment_item_list.item_selected.connect(_on_equipment_item_selected)
	
	if equipment_action_panel:
		equipment_action_panel.action_requested.connect(_on_equipment_action_requested)

	# Building tab signals
	if building_category_filter:
		building_category_filter.category_selected.connect(_on_building_category_selected)
	if building_item_list:
		building_item_list.item_selected.connect(_on_building_item_selected)
	if building_action_panel:
		building_action_panel.action_requested.connect(_on_building_action_requested)

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
	print("DEBUG: PlayerMenu._initialize_ui() called")
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

func open_menu():
	if is_open:
		return
	
	is_open = true
	visible = true

	# Refresh inventory categories
	if category_filter and category_filter.has_method("refresh_categories"):
		category_filter.refresh_categories()
	
	# Update input handler
	input_handler.set_player_menu_open(true)
	
	_on_tab_changed(tab_container.current_tab)

	print("Player Menu opened - Default tab: ", get_current_tab())

func close_menu():
	if not is_open:
		return
	
	is_open = false
	visible = false
	
	# Update input handler
	input_handler.set_player_menu_open(false)
	
	print("Player Menu closed")

func toggle_player_menu():
	if is_open:
		close_menu()
	else:
		open_menu()

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
	print("DEBUG: PlayerMenu._on_item_selected called for: ", stack.item.name)
	
	# Mark item as viewed
	DiscoveryManager.mark_viewed(stack.item.registry_key)
	
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
	if get_current_tab() == "equipment":
		_on_equipment_category_selected("all")

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

func get_current_tab() -> String:
	if not tab_container:
		return "inventory"
	
	match tab_container.current_tab:
		0:
			return "inventory"
		1:
			return "equipment"
		2:
			return "crafting"
		3:
			return "building"
		_:
			return "inventory"
	
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
	
	DiscoveryManager.mark_viewed(stack.item.registry_key)
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

func _on_equipment_changed():
	if get_current_tab() == "equipment":
		_on_equipment_category_selected("all")

func get_craftable_items_by_category(category: String) -> Array[InventoryManager.ItemStack]:
	var craftable_items: Array[InventoryManager.ItemStack] = []
	for item_key in GameObjectsDatabase.game_objects_database:
		var item = GameObjectsDatabase.game_objects_database[item_key]
		# Only include GameItems, exclude GameObjects
		if item is GameItem and item.craftable:
			if category == "all" or item.category == category:
				if DiscoveryManager.are_prerequisites_met(item_key):
					var temp_stack = InventoryManager.ItemStack.new(item, 1)
					craftable_items.append(temp_stack)
	return craftable_items

func _on_crafting_category_selected(category: String):
	print("Crafting category selected: ", category)
	
	# Get filtered craftable items
	var craftable_items = get_craftable_items_by_category(category)
	
	# Update crafting item list
	crafting_item_list = $TabContainer/Crafting/ContentSection/CraftingItemList
	if crafting_item_list and crafting_item_list.has_method("refresh_items"):
		crafting_item_list.refresh_items(craftable_items)
		print("Updated crafting list with ", craftable_items.size(), " items")
	
	# Auto-select first craftable item
	await get_tree().process_frame
	if craftable_items.size() > 0:
		var first_item = craftable_items[0]
		if crafting_item_list and crafting_item_list.has_method("set_selected_index"):
			crafting_item_list.set_selected_index(0)
		_on_crafting_item_selected(first_item)

func _on_crafting_item_selected(stack: InventoryManager.ItemStack):
	print("Crafting item selected: ", stack.item.name)
	
	# Ensure item is marked as viewed
	DiscoveryManager.mark_viewed(stack.item.registry_key)
	
	# Update crafting item detail panel
	crafting_item_detail = $TabContainer/Crafting/ContentSection/CraftingItemDetail
	if crafting_item_detail:
		crafting_item_detail.display_item(stack)
	
	# Update crafting action panel (if you want craft buttons)
	crafting_action_panel = $TabContainer/Crafting/FooterSection/CraftingActionPanel
	if crafting_action_panel:
		crafting_action_panel.display_actions_for_item(stack, {"crafting_mode": true})

func _on_building_category_selected(category: String):
	print("Building category selected: ", category)
	
	var buildable_structures = BuildingManager.get_buildable_structures_by_category(category)
	
	if building_item_list and building_item_list.has_method("refresh_structures"):
		building_item_list.refresh_structures(buildable_structures)
		print("Updated building list with ", buildable_structures.size(), " structures")
	
	# Auto-select first structure
	await get_tree().process_frame
	if buildable_structures.size() > 0:
		var first_structure = buildable_structures[0]
		if building_item_list and building_item_list.has_method("set_selected_index"):
			building_item_list.set_selected_index(0)
		_on_building_item_selected(first_structure)

func _on_building_item_selected(structure: GameObject):
	print("Building item selected: ", structure.name)
	
	# Ensure building is marked as viewed
	DiscoveryManager.mark_viewed(structure.registry_key)
	
	if building_item_detail:
		building_item_detail.display_structure(structure)
	
	if building_action_panel:
		building_action_panel.display_build_action(structure)

func _on_building_action_requested(structure):
	BuildingManager.start_building(structure)
	close_menu()
