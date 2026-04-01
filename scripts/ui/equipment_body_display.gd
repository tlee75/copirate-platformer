extends Control
class_name EquipmentBodyDisplay

signal equipment_slot_selected(slot_type: String, item_stack: InventoryManager.ItemStack)

var equipment_slots: Dictionary = {}
var slot_buttons: Dictionary = {}

func _ready():
	_setup_equipment_slots()
	_create_slot_buttons()
	_connect_signals()
	_update_equipment_display()

func _setup_equipment_slots():
	# Define equipment slot positions in a human body layout
	equipment_slots = {
		"helmet": {"position": Vector2(0.5, 0.1), "size": Vector2(80, 80)},
		"chest": {"position": Vector2(0.5, 0.35), "size": Vector2(100, 120)},
		"legs": {"position": Vector2(0.5, 0.65), "size": Vector2(90, 100)},
		"feet": {"position": Vector2(0.5, 0.85), "size": Vector2(80, 60)},
		"main_hand": {"position": Vector2(0.15, 0.45), "size": Vector2(70, 100)},
		"off_hand": {"position": Vector2(0.85, 0.45), "size": Vector2(70, 100)},
		"hands": {"position": Vector2(0.5, 0.5), "size": Vector2(80, 60)},
		"accessory_1": {"position": Vector2(0.85, 0.15), "size": Vector2(60, 60)}
	}

func _create_slot_buttons():
	for slot_type in equipment_slots.keys():
		var slot_data = equipment_slots[slot_type]
		var button = Button.new()
		
		# Set up button properties
		button.custom_minimum_size = slot_data.size
		button.flat = true
		button.text = ""
		
		# Position the button (will be set in _on_resized)
		add_child(button)
		slot_buttons[slot_type] = button
		
		# Connect button signal
		button.pressed.connect(_on_equipment_slot_pressed.bind(slot_type))
	
	# Connect resize signal to update positions
	resized.connect(_on_resized)

func _on_resized():
	# Update button positions based on current container size
	var container_size = size
	
	for slot_type in slot_buttons.keys():
		var button = slot_buttons[slot_type]
		var slot_data = equipment_slots[slot_type]
		
		# Calculate position based on relative coordinates
		var pos = Vector2(
			container_size.x * slot_data.position.x - slot_data.size.x * 0.5,
			container_size.y * slot_data.position.y - slot_data.size.y * 0.5
		)
		
		button.position = pos
		button.size = slot_data.size

func _connect_signals():
	if InventoryManager:
		InventoryManager.equipment_changed.connect(_on_equipment_changed)

func _on_equipment_changed():
	_update_equipment_display()

func _update_equipment_display():
	if not InventoryManager:
		return
		
	for slot_type in slot_buttons.keys():
		var button = slot_buttons[slot_type]
		var equipped_item = InventoryManager.get_equipped_stack(slot_type)
		
		if equipped_item and equipped_item.item:
			# Show equipped item
			button.text = ""
			button.icon = equipped_item.item.icon
			button.tooltip_text = equipped_item.item.name + " (Equipped)"
			_set_button_style(button, true)
		else:
			# Show empty slot
			button.text = _get_slot_display_name(slot_type)
			button.icon = null
			button.tooltip_text = "Empty " + _get_slot_display_name(slot_type) + " slot"
			_set_button_style(button, false)

func _set_button_style(button: Button, has_equipment: bool):
	if has_equipment:
		# Style for equipped items
		button.modulate = Color.WHITE
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.2, 0.8, 0.2, 0.3)  # Green tint
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color(0.2, 0.8, 0.2, 0.8)
		button.add_theme_stylebox_override("normal", style_box)
	else:
		# Style for empty slots
		button.modulate = Color(0.7, 0.7, 0.7, 1.0)
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.3, 0.3, 0.3, 0.3)  # Gray background
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color(0.5, 0.5, 0.5, 0.6)
		button.add_theme_stylebox_override("normal", style_box)

func _get_slot_display_name(slot_type: String) -> String:
	var display_names = {
		"helmet": "Head",
		"chest": "Chest",
		"legs": "Legs", 
		"feet": "Boots",
		"main_hand": "Weapon",
		"off_hand": "Shield",
		"hands": "Gloves",
		"accessory_1": "Accessory"
	}
	return display_names.get(slot_type, slot_type.capitalize())

func _on_equipment_slot_pressed(slot_type: String):
	if not InventoryManager:
		return
		
	var equipped_item = InventoryManager.get_equipped_stack(slot_type)
	equipment_slot_selected.emit(slot_type, equipped_item)

func highlight_slot(slot_type: String, highlight: bool):
	if not slot_buttons.has(slot_type):
		return
		
	var button = slot_buttons[slot_type]
	if highlight:
		button.modulate = Color(1.2, 1.2, 1.0, 1.0)  # Bright yellow tint
	else:
		button.modulate = Color.WHITE
