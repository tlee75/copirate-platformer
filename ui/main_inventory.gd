extends Control

# Main Inventory UI - the overlay that appears when pressing TAB
# Contains 16 inventory slots in a 4x4 grid

@onready var background: ColorRect = $Background
@onready var inventory_panel: NinePatchRect = $InventoryPanel
@onready var grid_container: GridContainer = $InventoryPanel/GridContainer

var slot_nodes: Array[Control] = []
var is_visible_flag: bool = false

func _ready():
	# Initially hidden
	visible = false
	is_visible_flag = false
	
	# Create 16 inventory slots
	var inventory_slot_scene = preload("res://ui/inventory_slot.tscn")
	
	# Clear any existing slots first
	for child in grid_container.get_children():
		child.queue_free()
	
	# Create all 16 slots
	for i in 16:
		var slot_instance = inventory_slot_scene.instantiate()
		slot_instance.name = "Slot" + str(i)
		slot_instance.slot_index = i
		slot_instance.is_hotbar_slot = false
		
		# Connect signals
		slot_instance.slot_clicked.connect(_on_slot_clicked)
		slot_instance.drag_started.connect(_on_drag_started)
		slot_instance.drag_ended.connect(_on_drag_ended)
		
		grid_container.add_child(slot_instance)
		slot_nodes.append(slot_instance)
	
	# Connect to inventory manager
	InventoryManager.inventory_changed.connect(_update_display)
	
	# Initial display update
	_update_display()

func show_inventory():
	is_visible_flag = true
	visible = true
	# Disable background game input when inventory is open
	get_tree().paused = false  # Don't actually pause, just block input in player script

func hide_inventory():
	is_visible_flag = false
	visible = false

func toggle_inventory():
	if is_visible_flag:
		hide_inventory()
	else:
		show_inventory()

func _update_display():
	for i in 16:
		if i < slot_nodes.size():
			var slot_data = InventoryManager.get_inventory_slot(i)
			if slot_data:
				slot_nodes[i].update_display(slot_data)

func _on_slot_clicked(slot_index: int, _is_hotbar: bool):
	print("Inventory slot ", slot_index, " clicked")

func _on_drag_started(slot_index: int, _is_hotbar: bool):
	print("Drag started from inventory slot ", slot_index)

func _on_drag_ended(slot_index: int, _is_hotbar: bool):
	print("Drag ended on inventory slot ", slot_index)
