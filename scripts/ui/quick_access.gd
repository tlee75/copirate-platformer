extends Control
class_name QuickAccessDisplay

# UI References
@onready var item_container: HBoxContainer
@onready var background: ColorRect
@onready var container: HBoxContainer

# State
var selected_slot: int = 0
var quick_access_items: Array[InventoryManager.ItemStack] = []
var slot_buttons: Array[Button] = []

# Signals
signal slot_selected(slot_index: int)
signal item_used(stack: InventoryManager.ItemStack)

func _ready():
	"""Setup UI references and connect signals"""
	# Get UI references
	background = get_node_or_null("Background")
	container = get_node_or_null("Container")
	item_container = get_node_or_null("Container/ItemContainer")
	
	if not item_container:
		print("ERROR: ItemContainer not found in QuickAccessDisplay scene")
		return
	
	# Connect to inventory signals
	if InventoryManager:
		InventoryManager.quick_access_changed.connect(_on_quick_access_changed)
		InventoryManager.inventory_changed.connect(_on_inventory_changed)
	
	# Connect to PlayerInputHandler signals
	if PlayerInputHandler:
		PlayerInputHandler.connect("action_executed", _on_action_executed)
	
	# Initial setup
	refresh_display()
	_update_selection_visual()

func refresh_display():
	"""Update display based on current quick access assignments"""
	# Clear existing buttons
	for button in slot_buttons:
		if button:
			button.queue_free()
	slot_buttons.clear()
	
	# Get current quick access items
	quick_access_items.clear()
	quick_access_items.resize(8)
	
	for i in range(8):
		quick_access_items[i] = InventoryManager.get_quick_access_stack(i)
	
	# Create buttons for all 8 slots
	for i in range(8):
		var button = _create_slot_button(i)
		slot_buttons.append(button)
		item_container.add_child(button)
		_update_slot_button(button, quick_access_items[i], i)

func _create_slot_button(slot_index: int) -> Button:
	"""Create individual slot button following dynamic paradigm"""
	var button = Button.new()
	
	# Set button properties
	button.custom_minimum_size = Vector2(60, 60)
	button.flat = true
	button.toggle_mode = false
	
	# Connect button signal
	button.pressed.connect(_on_slot_button_pressed.bind(slot_index))
	
	# Add hover effects
	button.mouse_entered.connect(_on_slot_button_hover_enter.bind(slot_index))
	button.mouse_exited.connect(_on_slot_button_hover_exit.bind(slot_index))
	
	return button

func _update_slot_button(button: Button, stack: InventoryManager.ItemStack, slot_index: int):
	"""Update button appearance and content"""
	if not button:
		return
	
	if stack and stack.item:
		# Show item
		button.text = stack.item.name
		button.tooltip_text = stack.item.name + " x" + str(stack.quantity)
		
		# TODO: Set item icon when available
		# button.icon = stack.item.icon
		
		button.modulate = Color.WHITE
	else:
		# Empty slot
		button.text = str(slot_index + 1)  # Show slot number
		button.tooltip_text = "Quick Access Slot " + str(slot_index + 1)
		button.modulate = Color(0.5, 0.5, 0.5, 0.7)  # Dimmed

func set_selected_slot(slot_index: int):
	"""Update visual selection indicator"""
	if slot_index >= 0 and slot_index < 8:
		selected_slot = slot_index
		_update_selection_visual()
		slot_selected.emit(slot_index)

func _on_slot_button_pressed(slot_index: int):
	"""Handle slot selection"""
	set_selected_slot(slot_index)
	
	# Use item if present
	var stack = quick_access_items[slot_index] if slot_index < quick_access_items.size() else null
	if stack:
		item_used.emit(stack)
		# Let PlayerInputHandler handle the actual usage
		PlayerInputHandler._execute_primary_action(stack)

func _on_slot_button_hover_enter(slot_index: int):
	"""Handle button hover"""
	if slot_index < slot_buttons.size() and slot_buttons[slot_index]:
		slot_buttons[slot_index].modulate = Color(1.2, 1.2, 1.2, 1.0)  # Slightly brighter

func _on_slot_button_hover_exit(slot_index: int):
	"""Handle button hover exit"""
	if slot_index < slot_buttons.size() and slot_buttons[slot_index]:
		var stack = quick_access_items[slot_index] if slot_index < quick_access_items.size() else null
		if stack:
			slot_buttons[slot_index].modulate = Color.WHITE
		else:
			slot_buttons[slot_index].modulate = Color(0.5, 0.5, 0.5, 0.7)

func _update_selection_visual():
	"""Update visual indicators for current selection"""
	for i in range(slot_buttons.size()):
		var button = slot_buttons[i]
		if button:
			if i == selected_slot:
				# Selected appearance
				button.add_theme_color_override("font_color", Color.YELLOW)
				# TODO: Add border or background highlight
			else:
				# Normal appearance
				button.remove_theme_color_override("font_color")

func get_selected_stack() -> InventoryManager.ItemStack:
	"""Return currently selected ItemStack"""
	if selected_slot >= 0 and selected_slot < quick_access_items.size():
		return quick_access_items[selected_slot]
	return null

func _on_quick_access_changed():
	"""Handle quick access inventory changes"""
	refresh_display()

func _on_inventory_changed():
	"""Handle general inventory changes that might affect quick access"""
	refresh_display()

func _on_action_executed(action_type: InventoryActionResolver.ActionType, stack: InventoryManager.ItemStack, success: bool):
	"""Handle action execution feedback"""
	if success:
		refresh_display()

# Input handling for direct interaction
func _input(event):
	if not visible:
		return
	
	# Handle mouse wheel scrolling over quick access
	if event is InputEventMouseButton and get_global_rect().has_point(get_global_mouse_position()):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cycle_selection(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cycle_selection(1)
			get_viewport().set_input_as_handled()

func _cycle_selection(direction: int):
	"""Cycle selection to next/previous non-empty slot"""
	var start_slot = selected_slot
	
	for i in range(8):
		selected_slot = (selected_slot + direction) % 8
		if selected_slot < 0:
			selected_slot = 7
		
		if quick_access_items[selected_slot] != null:
			_update_selection_visual()
			return
		
		if selected_slot == start_slot:
			break

# Sync with PlayerInputHandler selection
func sync_with_input_handler():
	"""Sync selection with PlayerInputHandler"""
	if PlayerInputHandler:
		set_selected_slot(PlayerInputHandler.selected_quick_access_slot)
