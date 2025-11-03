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
	
	# Complete the crafting
	print("Crafting completed: ", current_craft_item.name)
	CraftingManager.craft_item(current_craft_item)
	
	# Reset UI state
	is_crafting = false
	if progress_bar:
		progress_bar.value = 100
		progress_bar.visible = false
	
	# Re-enable the craft button
	if craft_button:
		craft_button.disabled = false
		craft_button.text = "Craft " + current_craft_item.name
	
	current_craft_item = null

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
	
	# Check if can craft
	var can_craft = CraftingManager.can_craft_item(stack.item)
	craft_button.disabled = not can_craft
	
	# Connect to start_crafting method
	craft_button.pressed.connect(func(): start_crafting(stack.item))
	
	# Add to container
	button_container.add_child(craft_button)
	
	print("Created craft button for: ", stack.item.name)
