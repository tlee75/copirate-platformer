extends Control

# Main Inventory UI - the overlay that appears when pressing TAB
# Contains 16 inventory slots in a 4x4 grid

@onready var background: ColorRect = $Background
@onready var inventory_panel: NinePatchRect = $InventoryPanel
@onready var grid_container: GridContainer = $InventoryPanel/GridContainer

# Get all slot references from the scene tree
@onready var slot_nodes: Array[Control] = [
	$InventoryPanel/GridContainer/Slot0,
	$InventoryPanel/GridContainer/Slot1,
	$InventoryPanel/GridContainer/Slot2, 
	$InventoryPanel/GridContainer/Slot3, 
	$InventoryPanel/GridContainer/Slot4, 
	$InventoryPanel/GridContainer/Slot5, 
	$InventoryPanel/GridContainer/Slot6, 
	$InventoryPanel/GridContainer/Slot7, 
	$InventoryPanel/GridContainer/Slot8, 
	$InventoryPanel/GridContainer/Slot9, 
	$InventoryPanel/GridContainer/Slot10, 
	$InventoryPanel/GridContainer/Slot11, 
	$InventoryPanel/GridContainer/Slot12, 
	$InventoryPanel/GridContainer/Slot13, 
	$InventoryPanel/GridContainer/Slot14, 
	$InventoryPanel/GridContainer/Slot15
]
var is_visible_flag: bool = false

func _ready():
	# Always visible because we're in a tab
	visible = true
	is_visible_flag = true
	
	# Setup slot properties and connections
	for i in slot_nodes.size():
		if slot_nodes[i]:
			slot_nodes[i].slot_index = i
			slot_nodes[i].is_hotbar_slot = false
			
			# Connect signals
			if slot_nodes[i].has_signal("slot_clicked"):
				slot_nodes[i].slot_clicked.connect(_on_slot_clicked)
	
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
