extends Control

# Hotbar UI - displays the 8 hotbar slots at the bottom of the screen
# Connects to InventoryManager for data

var selected_slot: int = 0

@onready var slot_container: HBoxContainer = $HBoxContainer
var slot_nodes: Array[Control] = []

func _ready():
	# Get references to all slot nodes
	for i in 8:
		var slot_node = slot_container.get_child(i)
		slot_nodes.append(slot_node)
		
		# Configure each slot
		slot_node.slot_index = i
		slot_node.is_hotbar_slot = true
		
		# Connect slot signals
		slot_node.slot_clicked.connect(_on_slot_clicked)
	
	# Start the game with slot 0 selected
	print("selecting slot")
	select_slot(0)
	
	# Connect to inventory manager signals
	InventoryManager.hotbar_changed.connect(_update_display)
	
	# Initial display update
	_update_display()

func _update_display():
	for i in 8:
		var slot_data = InventoryManager.get_hotbar_slot(i)
		if slot_data:
			slot_nodes[i].update_display(slot_data)

func _on_slot_clicked(slot_index: int, _is_hotbar: bool):
	print("Hotbar slot ", slot_index, " clicked")

func _on_drag_started(slot_index: int, _is_hotbar: bool):
	print("Drag started from hotbar slot ", slot_index)
	# TODO: Implement drag and drop logic

func _on_drag_ended(slot_index: int, _is_hotbar: bool):
	print("Drag ended on hotbar slot ", slot_index)
	# TODO: Implement drag and drop logic

func select_slot(index: int):
	selected_slot = clamp(index, 0, get_slot_count() -1)
	print("selected_slot: ", selected_slot)
	update_slot_highlight()

func update_slot_highlight():
	for i in slot_nodes.size():
		if i == selected_slot:
			slot_nodes[i].modulate = Color(1, 1, 0.5) # Highlighted yellowish
		else:
			slot_nodes[i].modulate = Color(1, 1, 1) # Normal

func get_slot_count():
	return slot_nodes.size()

func get_selected_item():
	if selected_slot >= 0 and selected_slot < slot_nodes.size():
		return slot_nodes[selected_slot].slot_data.item
	return null
