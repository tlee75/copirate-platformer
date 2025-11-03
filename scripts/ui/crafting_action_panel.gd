extends Control
class_name CraftingActionPanel

signal action_requested(action_type: InventoryActionResolver.ActionType)

var button_container: HBoxContainer
var action_buttons: Array[Button] = []
var current_stack: InventoryManager.ItemStack
var input_handler: PlayerInputHandler

# Crafting progress state
var is_crafting: bool = false
var crafting_timer: Timer
var update_timer: Timer
var current_craft_item: GameItem
var progress_bar: ProgressBar
var craft_button: Button

func _ready():
	_setup_ui_references()

func _setup_ui_references():
	button_container = $ButtonContainer

func _setup_progress_bar():
	"""Create progress bar for crafting display"""
	if progress_bar:
		return  # Already created
	
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(200, 30)
	progress_bar.show_percentage = true
	progress_bar.visible = false
	
	# Add to the same container as buttons
	if button_container:
		button_container.add_child(progress_bar)
	
	# Create crafting timer
	if not crafting_timer:
		crafting_timer = Timer.new()
		crafting_timer.wait_time = 1.0  # Default, will be overridden
		crafting_timer.one_shot = true
		crafting_timer.timeout.connect(_on_crafting_complete)
		add_child(crafting_timer)
	
	# Create update timer for smooth progress
	if not update_timer:
		update_timer = Timer.new()
		update_timer.wait_time = 0.1  # Update every 100ms
		update_timer.timeout.connect(_on_crafting_tick)
		add_child(update_timer)
		update_timer.start()  # Keep running for progress updates

func _on_crafting_tick():
	"""Update crafting progress"""
	if not is_crafting or not current_craft_item or not crafting_timer:
		return
	
	if not progress_bar or not progress_bar.visible:
		return
		
	var elapsed_time = current_craft_item.craft_time - crafting_timer.time_left
	var progress = elapsed_time / current_craft_item.craft_time
	progress_bar.value = progress * 100
	
	# Update craft button text with time remaining
	if craft_button:
		var remaining = int(crafting_timer.time_left)
		craft_button.text = "Crafting... (" + str(remaining) + "s)"

func _on_crafting_complete():
	"""Called when crafting timer completes"""
	if not is_crafting or not current_craft_item:
		return
	
	# Store item reference before clearing
	var completed_item = current_craft_item
	
	# Complete the crafting
	print("Crafting completed: ", completed_item.name)
	CraftingManager.craft_item(completed_item)
	
	# Reset crafting state
	is_crafting = false
	current_craft_item = null
	
	# Hide progress bar
	if progress_bar:
		progress_bar.value = 100
		progress_bar.visible = false
	
	# Refresh UI after materials have been consumed
	_refresh_ui_after_crafting(completed_item)

func _refresh_ui_after_crafting(completed_item: GameItem):
	"""Refresh UI components after crafting completes"""
	
	# Update craft button state based on new material availability
	if craft_button and current_stack:
		var can_craft = CraftingManager.can_craft_item(current_stack.item)
		craft_button.disabled = not can_craft
		craft_button.text = "Craft " + current_stack.item.name
		print("Updated craft button state: ", "enabled" if can_craft else "disabled")
	
	# Find and refresh the item details panel
	_refresh_item_details_panel()
	
	print("UI refreshed after crafting: ", completed_item.name)

func _refresh_item_details_panel():
	"""Find and refresh the crafting item details panel to show updated material counts"""
	
	# Navigate up the scene tree to find the crafting details panel
	# Path: CraftingActionPanel -> FooterSection -> Crafting -> TabContainer -> PlayerMenu -> UI
	
	var current_node = self
	var attempts = 0
	
	# Go up the tree to find PlayerMenu
	while current_node and attempts < 10:
		attempts += 1
		print("DEBUG: Checking node: ", current_node.name, " (type: ", current_node.get_class(), ")")
		
		# Look for TabContainer (which is a child of PlayerMenu)
		var tab_containers = current_node.find_children("TabContainer", "TabContainer", false, false)
		if tab_containers.size() > 0:
			var tab_container = tab_containers[0]
			print("DEBUG: Found TabContainer: ", tab_container.name)
			
			# Look for the Crafting tab
			for tab_child in tab_container.get_children():
				if tab_child.name == "Crafting":
					print("DEBUG: Found Crafting tab: ", tab_child.name)
					
					# Look for CraftingItemDetail
					var detail_nodes = tab_child.find_children("CraftingItemDetail", "CraftingItemDetail", true, false)
					if detail_nodes.size() > 0:
						var detail_panel = detail_nodes[0]
						print("DEBUG: Found CraftingItemDetail: ", detail_panel.name)
						
						if detail_panel.has_method("refresh_display"):
							detail_panel.refresh_display()
							print("SUCCESS: Refreshed crafting item details panel")
							return
						else:
							print("ERROR: CraftingItemDetail missing refresh_display method")
							return
					else:
						print("DEBUG: CraftingItemDetail not found in Crafting tab")
		
		current_node = current_node.get_parent()
	
	print("WARNING: Could not find crafting item details panel after ", attempts, " attempts")

func start_crafting(item: GameItem):
	"""Start the crafting process with progress bar"""
	if is_crafting:
		print("Already crafting something!")
		return
	
	if not "craft_time" in item or not item.craft_time or item.craft_time <= 0:
		print("Item has no craft time, crafting instantly")
		CraftingManager.craft_item(item)
		return
	
	# Setup crafting state
	print("Starting crafting: ", item.name, " (", item.craft_time, " seconds)")
	is_crafting = true
	current_craft_item = item
	
	# Show and reset progress bar
	if progress_bar:
		progress_bar.value = 0
		progress_bar.visible = true
	
	# Disable craft button and update text
	if craft_button:
		craft_button.disabled = true
		craft_button.text = "Crafting..."
	
	# Start the crafting timer
	if crafting_timer:
		print("DEBUG: Setting timer wait_time to: ", item.craft_time)
		crafting_timer.wait_time = item.craft_time
		print("DEBUG: Timer wait_time after setting: ", crafting_timer.wait_time)
		print("DEBUG: Starting timer...")
		crafting_timer.start()
		print("DEBUG: Timer started. Is running: ", not crafting_timer.is_stopped())
		print("DEBUG: Timer time_left: ", crafting_timer.time_left)
	else:
		print("ERROR: crafting_timer is null!")

func set_input_handler(handler: PlayerInputHandler):
	input_handler = handler

func _clear_all_buttons():
	"""Clear all buttons but preserve progress bar"""
	if button_container:
		for child in button_container.get_children():
			# Don't destroy the progress bar, just hide it
			if child != progress_bar:
				child.queue_free()
	
	action_buttons.clear()
	craft_button = null
	
	# Hide progress bar if it exists
	if progress_bar:
		progress_bar.visible = false

func _create_action_buttons(actions: Array[InventoryActionResolver.ActionData]):
	for action in actions:
		var button = _create_action_button(action)
		button_container.add_child(button)
		action_buttons.append(button)

func _create_action_button(action: InventoryActionResolver.ActionData) -> Button:
	var button = Button.new()
	button.text = action.label
	button.custom_minimum_size = Vector2(120, 40)
	
	# Style primary action differently
	if action.is_primary:
		button.add_theme_stylebox_override("normal", _create_primary_button_style())
		button.add_theme_stylebox_override("hover", _create_primary_button_style(true))
	else:
		button.add_theme_stylebox_override("normal", _create_secondary_button_style())
		button.add_theme_stylebox_override("hover", _create_secondary_button_style(true))
	
	# Add input hint as tooltip
	if action.input_hint != "": 
		button.tooltip_text = "Press " + action.input_hint
	
	# Connect signal
	button.pressed.connect(_on_action_button_pressed.bind(action.type))
	
	return button

func _create_primary_button_style(hover: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.5, 1.0, 0.8) if not hover else Color(0.3, 0.6, 1.0, 0.9)
	style.border_color = Color(0.4, 0.7, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _create_secondary_button_style(hover: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3, 0.6) if not hover else Color(0.4, 0.4, 0.4, 0.7)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _on_action_button_pressed(action_type: InventoryActionResolver.ActionType):
	action_requested.emit(action_type)

func refresh_actions():
	if current_stack:
		display_actions_for_item(current_stack)

func display_build_action(structure):
	_clear_all_buttons()
	
	var build_button = Button.new()
	build_button.text = "Build " + structure.name
	build_button.pressed.connect(emit_signal.bind("action_requested", structure))
	button_container.add_child(build_button)

func display_actions_for_item(stack, context = {}):
	# Store the current stack
	current_stack = stack
	
	# Clear all existing buttons and UI
	_clear_all_buttons()
	
	# Setup progress bar
	_setup_progress_bar()
	
	# Create the craft button
	craft_button = Button.new()
	craft_button.text = "Craft " + stack.item.name
	craft_button.custom_minimum_size = Vector2(150, 40)
	
	# Check if can craft with detailed logging
	var can_craft = CraftingManager.can_craft_item(stack.item)
	craft_button.disabled = not can_craft
	
	# Debug craft requirements
	print("Craft button state for ", stack.item.name, ": ", "enabled" if can_craft else "disabled")
	if not can_craft and stack.item.craft_requirements:
		for material_name in stack.item.craft_requirements:
			var required = stack.item.craft_requirements[material_name]
			var available = InventoryManager.get_total_item_count(material_name)
			print("  - Need ", required, "x ", material_name, ", have ", available)
	
	# Connect to start_crafting method
	craft_button.pressed.connect(func(): start_crafting(stack.item))
	
	# Add to container
	button_container.add_child(craft_button)
	
	print("Created craft button for: ", stack.item.name)
