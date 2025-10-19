@tool
extends Control
class_name InventoryItemList

signal item_selected(stack: InventoryManager.ItemStack)
signal item_action_requested(stack: InventoryManager.ItemStack, action_type: InventoryActionResolver.ActionType)

var scroll_container: ScrollContainer
var item_container: VBoxContainer
var empty_label: Label
var item_buttons: Array[Control] = []
var current_items: Array[InventoryManager.ItemStack] = []
var selected_index: int = -1
var input_handler: InventoryInputHandler

func _ready():
	_setup_ui_references()
	_setup_empty_state()
	
	# FIX: ScrollContainer consumes mouse events by default, set to PASS
	if scroll_container:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	print("DEBUG: InventoryItemList._ready() - mouse_filter=", mouse_filter)
	print("DEBUG: ScrollContainer mouse_filter=", scroll_container.mouse_filter if scroll_container else "null")
	print("DEBUG: ItemContainer mouse_filter=", item_container.mouse_filter if item_container else "null")

func _gui_input(event):
	if event is InputEventMouseButton:
		print("DEBUG: InventoryItemList._gui_input - button=", event.button_index, " pressed=", event.pressed)
		print("DEBUG: Mouse position: ", event.position, " global: ", event.global_position)

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

func set_input_handler(handler: InventoryInputHandler):
	input_handler = handler

func refresh_items(items: Array[InventoryManager.ItemStack]):
	current_items = items
	_clear_item_list()
	
	if items.size() == 0:
		_show_empty_state()
		return
	
	_hide_empty_state()
	_create_item_buttons()

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
		var item_button = _create_item_button(stack, i)
		item_container.add_child(item_button)
		item_buttons.append(item_button)
	
	# CRITICAL: Ensure the container layout is updated
	await get_tree().process_frame
	item_container.queue_redraw()


func _create_item_button(stack: InventoryManager.ItemStack, index: int) -> Control:
	var button = Button.new()
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS  # ADD THIS LINE
	button.text = stack.get_display_name() + " (x" + str(stack.quantity) + ")"
	button.text = stack.get_display_name() + " (x" + str(stack.quantity) + ")"
	if stack.item.icon:
		button.icon = stack.item.icon
	
	# CRITICAL: Set proper button sizing
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2(200, 40)
	button.mouse_force_pass_scroll_events = false
	
	# CRITICAL: Set button alignment and text properties
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = false
	
	# Add comprehensive mouse event tracking
	button.pressed.connect(func():
		print("DEBUG: Button.pressed signal fired for ", stack.item.name, " at index ", index)
		_on_item_selected(index)
	)
	
	button.button_down.connect(func():
		print("DEBUG: Button.button_down signal fired for ", stack.item.name)
	)
	
	button.button_up.connect(func():
		print("DEBUG: Button.button_up signal fired for ", stack.item.name)
	)
	
	button.mouse_entered.connect(func():
		print("DEBUG: Mouse entered button for ", stack.item.name)
	)
	
	button.mouse_exited.connect(func():
		print("DEBUG: Mouse exited button for ", stack.item.name)
	)
	
	# Add gui_input handler for even more detailed tracking
	button.gui_input.connect(func(event):
		if event is InputEventMouseButton:
			print("DEBUG: *** BUTTON.GUI_INPUT *** received for ", stack.item.name, " button=", event.button_index, " pressed=", event.pressed)
	)
	print("DEBUG: Created button for ", stack.item.name, " at index ", index)
	print("DEBUG:   - custom_minimum_size: ", button.custom_minimum_size)
	print("DEBUG:   - mouse_filter will be: ", Control.MOUSE_FILTER_STOP)
	print("DEBUG:   - focus_mode will be: ", Control.FOCUS_ALL)	
	print("DEBUG: Created button for ", stack.item.name, " at index ", index, " with size: ", button.custom_minimum_size)
	# Force the button to be on top and explicitly set mouse filter
	button.set_mouse_filter(Control.MOUSE_FILTER_STOP)
	print("DEBUG:   - Explicitly set mouse_filter to: ", button.mouse_filter)
	print("DEBUG:   - mouse_force_pass_scroll_events: ", button.mouse_force_pass_scroll_events)
	return button


func set_selected_index(index: int):
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
			var action = input_handler.action_resolver.get_action_for_input("inventory_use", stack)
			if action:
				item_action_requested.emit(stack, action.type)

func get_selected_stack() -> InventoryManager.ItemStack:
	if selected_index >= 0 and selected_index < current_items.size():
		return current_items[selected_index]
	return null


func debug_button_info():
	print("=== BUTTON DEBUG INFO ===")
	print("Item buttons count: ", item_buttons.size())
	print("Current items count: ", current_items.size())
	print("Selected index: ", selected_index)
	for i in range(item_buttons.size()):
		if i < item_buttons.size() and is_instance_valid(item_buttons[i]):
			var btn = item_buttons[i]
			print("Button ", i, ":")
			print("  Text: ", btn.text)
			print("  Size: ", btn.size)
			print("  Position: ", btn.position)
			print("  Visible: ", btn.visible)
			print("  Disabled: ", btn.disabled)
