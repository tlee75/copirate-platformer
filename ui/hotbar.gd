extends Control

# Hotbar UI - displays the 8 hotbar slots at the bottom of the screen
# Connects to InventoryManager for data

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
