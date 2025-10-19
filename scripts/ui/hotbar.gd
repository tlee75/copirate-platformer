extends Control
class_name Hotbar

@onready var h_box_container: HBoxContainer = $HBoxContainer

var hotbar_slot_buttons: Array[Button] = []
var selected_slot: int = 0
const HOTBAR_SIZE = 8

func _ready():
	_create_dynamic_hotbar_slots()
	# Connect to the new inventory system
	InventoryManager.hotbar_changed.connect(_update_hotbar_display)
	_update_hotbar_display()

func scroll_previous():
	_select_previous_slot()

func scroll_next():
	_select_next_slot()

func _create_dynamic_hotbar_slots():
	# Clear any existing children
	for child in h_box_container.get_children():
		child.queue_free()
	
	hotbar_slot_buttons.clear()
	
	# Create 8 dynamic slots
	for i in range(HOTBAR_SIZE):
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(64, 64)
		slot_button.flat = true
		slot_button.name = "HotbarSlot" + str(i)
		slot_button.toggle_mode = false
		
		# Connect click to select slot
		slot_button.pressed.connect(_on_hotbar_slot_pressed.bind(i))
		
		h_box_container.add_child(slot_button)
		hotbar_slot_buttons.append(slot_button)
	
	# Select the first slot by default
	_update_slot_selection()

func _update_hotbar_display():
	for i in range(HOTBAR_SIZE):
		var stack = InventoryManager.get_hotbar_stack(i)
		var button = hotbar_slot_buttons[i]
		
		if stack and stack.item:
			button.text = stack.item.name + "\nx" + str(stack.quantity)
		else:
			button.text = ""
	
	_update_slot_selection()

func _update_slot_selection():
	# Update visual selection indicator
	for i in range(HOTBAR_SIZE):
		var button = hotbar_slot_buttons[i]
		if i == selected_slot:
			button.modulate = Color.YELLOW  # Highlight selected slot
		else:
			button.modulate = Color.WHITE

func _on_hotbar_slot_pressed(slot_index: int):
	# Select the clicked slot
	selected_slot = slot_index
	_update_slot_selection()
	print("Selected hotbar slot: ", slot_index)

func _select_next_slot():
	selected_slot = (selected_slot + 1) % HOTBAR_SIZE
	_update_slot_selection()
	print("Selected hotbar slot: ", selected_slot)

func _select_previous_slot():
	selected_slot = (selected_slot - 1 + HOTBAR_SIZE) % HOTBAR_SIZE
	_update_slot_selection()
	print("Selected hotbar slot: ", selected_slot)

func get_selected_slot() -> int:
	return selected_slot

func get_selected_stack():
	return InventoryManager.get_hotbar_stack(selected_slot)
