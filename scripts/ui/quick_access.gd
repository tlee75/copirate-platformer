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
	
	# Declare in a group for discovery
	add_to_group("quick_access")
	
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

# Input handling for direct interaction
func _input(event):
	if not visible:
		return
		
	# Check if any menu is open - use UIManager for centralized check
	var ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if ui_manager and ui_manager.is_any_menu_open():
		return
	
	# Fallback check for PlayerMenu if UIManager not available
	var player_menu = get_tree().get_root().get_node("Platformer/UI/PlayerMenu")
	if player_menu and player_menu.is_open:
		return
	
	# Handle mouse wheel scrolling over quick access
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cycle_selection(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cycle_selection(1)
			get_viewport().set_input_as_handled()

func refresh_display():
	# Clear existing buttons and separators
	for child in item_container.get_children():
		child.queue_free()
	slot_buttons.clear()

	# Get current quick access items
	quick_access_items.clear()
	quick_access_items.resize(8)

	for i in range(8):
		quick_access_items[i] = InventoryManager.get_quick_access_stack(i)

	# Create buttons and separators
	for i in range(8):
		var button = _create_slot_button(i)
		slot_buttons.append(button)
		item_container.add_child(button)
		_update_slot_button(button, quick_access_items[i], i)

		# Add separator after each button except the last
		if i < 7:
			var sep = ColorRect.new()
			sep.color = Color(0.5, 0.5, 0.5, 0.5) # semi-transparent gray
			sep.custom_minimum_size = Vector2(2, 60) # 2px wide, match button height
			item_container.add_child(sep)

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
	
	var quantity_label = Label.new()
	quantity_label.name = "QuantityLabel"
	quantity_label.anchor_right = 1.0
	quantity_label.anchor_bottom = 1.0
	quantity_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	quantity_label.offset_left = -20 # Negative to move left from the right edge
	quantity_label.offset_bottom = 0
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	button.add_child(quantity_label)
	
	return button

func _update_slot_button(button: Button, stack: InventoryManager.ItemStack, slot_index: int):
	if not button:
		return

	if stack and stack.item:
		if "icon" in stack.item and stack.item.icon:
			var icon_texture = stack.item.icon
			if icon_texture is Texture2D:
				var img = icon_texture.get_image()
				var max_dim = 48
				var w = img.get_width()
				var h = img.get_height()
				# Resize icon if too big, retain aspect ratio
				if w > max_dim or h > max_dim:
					var img_scale = min(max_dim / float(w), max_dim / float(h))
					var new_w = int(w * img_scale)
					var new_h = int(h * img_scale)
					img.resize(new_w, new_h, Image.INTERPOLATE_LANCZOS)
					icon_texture = ImageTexture.create_from_image(img)
			button.icon = icon_texture
			button.text = "" 
		else:
			button.text = ""
	else:
		# Empty slot
		button.text = str(slot_index + 1)
		button.icon = null
		button.tooltip_text = "Quick Access Slot " + str(slot_index + 1)
		button.modulate = Color(0.5, 0.5, 0.5, 0.7)

	var quantity_label = button.get_node_or_null("QuantityLabel")
	if quantity_label:
		if stack and stack.item and stack.quantity > 1:
			quantity_label.text = str(stack.quantity)
			quantity_label.visible = true
		else:
			quantity_label.text = ""
			quantity_label.visible = false

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
				button.grab_focus()  
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

func _cycle_selection(direction: int):
	var slot = selected_slot + direction

	# Clamp to bounds
	if slot < 0:
		slot = 0
	elif slot > 7:
		slot = 7

	set_selected_slot(slot)
