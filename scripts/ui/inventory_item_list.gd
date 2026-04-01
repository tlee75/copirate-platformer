extends Control
class_name InventoryItemList

signal item_selected(stack: InventoryManager.ItemStack)
signal item_action_requested(stack: InventoryManager.ItemStack, action_type: InventoryActionResolver.ActionType)
signal item_buttons_created

signal structure_selected(structure: GameObject)

var scroll_container: ScrollContainer
var item_container: VBoxContainer
var empty_label: Label
var item_buttons: Array[Control] = []
var current_items: Array[InventoryManager.ItemStack] = []
var selected_index: int = -1
var input_handler: PlayerInputHandler

func _ready():
	_setup_ui_references()
	_setup_empty_state()
	
	# FIX: ScrollContainer consumes mouse events by default, set to PASS
	if scroll_container:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP

func _setup_ui_references():
	scroll_container = $ScrollContainer
	item_container = $ScrollContainer/ItemContainer  
	empty_label = $ScrollContainer/ItemContainer/EmptyLabel
	
	# CRITICAL: Ensure item_container has proper layout settings
	if item_container:
		item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _setup_empty_state():
	empty_label.text = "No items in this category"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.anchors_preset = Control.PRESET_FULL_RECT

func set_input_handler(handler: PlayerInputHandler):
	input_handler = handler

func refresh_items(items: Array[InventoryManager.ItemStack]):
	print("DEBUG: refresh_items called with items: ", items.size())
	current_items = items
	_clear_item_list()
	
	if items.size() == 0:
		_show_empty_state()
		return
	
	_hide_empty_state()
	_create_item_buttons()

func refresh_structures(structures: Array[GameObject]):
	print("DEBUG: refresh_structures called with structures: ", structures.size())
	
	# Clear existing display
	_clear_item_list()
	
	if structures.size() == 0:
		_show_empty_state()
		return
	
	_hide_empty_state()
	
	# Create buttons for structures
	for i in range(structures.size()):
		var structure = structures[i]
		if structure != null:
			var structure_button = _create_structure_button(structure, i)
			item_container.add_child(structure_button)
			item_buttons.append(structure_button)
	
	await get_tree().process_frame
	item_container.queue_redraw()
	emit_signal("item_buttons_created")

func _create_structure_button(structure: GameObject, index: int) -> Control:
	var button = Button.new()
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.text = structure.name
	button.custom_minimum_size = Vector2(0, 64)
	if structure.icon:
		button.icon = structure.icon
	
	# Highlight unviewed structures with a left border
	if not DiscoveryManager.is_viewed(structure.registry_key):
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
		style.border_color = Color(1.0, 0.85, 0.0, 1.0)  # Gold/yellow
		style.border_width_left = 3
		style.border_width_right = 0
		style.border_width_top = 0
		style.border_width_bottom = 0
		style.content_margin_left = 8
		button.add_theme_stylebox_override("normal", style)
	
	button.pressed.connect(func():
		print("DEBUG: Structure button pressed for ", structure.name, " at index ", index)
		selected_index = index
		button.remove_theme_stylebox_override("normal")
		structure_selected.emit(structure)
	)
	return button

func _clear_item_list():
	for button in item_buttons:
		if is_instance_valid(button):
			button.queue_free()
	item_buttons.clear()

func _show_empty_state():
	scroll_container.visible = false
	empty_label.visible = true

func _hide_empty_state():
	scroll_container.visible = true
	empty_label.visible = false

func _create_item_buttons():
	for i in range(current_items.size()):
		var stack = current_items[i]
		if stack != null:  # Only create buttons for non-null stacks
			var item_button = _create_item_button(stack, i)
			item_container.add_child(item_button)
			item_buttons.append(item_button)
	
	# Ensure the container layout is updated
	await get_tree().process_frame
	item_container.queue_redraw()
	
	emit_signal("item_buttons_created")

func _create_item_button(stack: InventoryManager.ItemStack, index: int) -> Control:
	# Add null check at the start
	if stack == null:
		push_error("_create_item_button called with null stack")
		return Button.new()  # Return empty button as fallback
	
	var button = Button.new()
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.text = stack.get_display_name() + " (x" + str(stack.quantity) + ")"
	button.custom_minimum_size = Vector2(0, 64)
	if stack.item and stack.item.icon:
		button.icon = stack.item.icon

	# Highlight unviewed items with a left border
	if stack.item and not DiscoveryManager.is_viewed(stack.item.registry_key):
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
		style.border_color = Color(1.0, 0.85, 0.0, 1.0)  # Gold/yellow
		style.border_width_left = 3
		style.border_width_right = 0
		style.border_width_top = 0
		style.border_width_bottom = 0
		style.content_margin_left = 8
		button.add_theme_stylebox_override("normal", style)
	
	# Add comprehensive mouse event tracking
	button.pressed.connect(func():
		print("DEBUG: Button.pressed signal fired for ", stack.item.name, " at index ", index)
		_on_item_selected(index)
	)
	return button

func set_selected_index(index: int):
	print("DEBUG: set_selected_index called with index: ", index)
	if index >= -1 and index < current_items.size():
		selected_index = index
		
		if index >= 0:
			item_selected.emit(current_items[index])
			_scroll_to_item(index)

func _scroll_to_item(index: int):
	if index >= 0 and index < item_buttons.size():
		var button = item_buttons[index]
		var button_pos = button.position.y
		var button_height = button.size.y
		var scroll_height = scroll_container.size.y
		
		var target_scroll = button_pos - (scroll_height / 2) + (button_height / 2)
		scroll_container.scroll_vertical = max(0, target_scroll)

func _on_item_selected(index: int):
	print("DEBUG: _on_item_selected called with index: ", index)
	if index >= 0 and index < current_items.size():
		selected_index = index
		# Clear unviewed indicator on the clicked button
		if index < item_buttons.size() and is_instance_valid(item_buttons[index]):
			item_buttons[index].remove_theme_stylebox_override("normal")
		print("DEBUG: Emitting item_selected signal for: ", current_items[index].item.name)
		item_selected.emit(current_items[index])
	else:
		print("DEBUG: Invalid index in _on_item_selected: ", index, " (max: ", current_items.size() - 1, ")")

func scroll_up():
	scroll_container.scroll_vertical = max(0, scroll_container.scroll_vertical - 50)

func scroll_down():
	scroll_container.scroll_vertical += 50

func navigate_items(direction: int):
	var new_index = clamp(selected_index + direction, 0, current_items.size() - 1)
	set_selected_index(new_index)

func _execute_primary_action():
	if selected_index >= 0 and selected_index < current_items.size():
		var stack = current_items[selected_index]
		if input_handler:
			item_action_requested.emit(stack, InventoryActionResolver.ActionType.USE)

func get_selected_stack() -> InventoryManager.ItemStack:
	if selected_index >= 0 and selected_index < current_items.size():
		return current_items[selected_index]
	return null


func debug_button_info():
	for i in range(item_buttons.size()):
		if i < item_buttons.size() and is_instance_valid(item_buttons[i]):
			var btn = item_buttons[i]
			print("Button ", i, ":")
			print("  Text: ", btn.text)
			print("  Size: ", btn.size)
			print("  Position: ", btn.position)
			print("  Visible: ", btn.visible)
			print("  Disabled: ", btn.disabled)

func get_items():
	return current_items
