extends Control
class_name EquipmentInventory

# Filtered inventory that shows only equipment items from main inventory
# Dynamically creates slots based on equipment items found

@onready var inventory_panel: NinePatchRect = $InventoryPanel
@onready var grid_container: GridContainer = $InventoryPanel/GridContainer

var slot_nodes: Array[Control] = []
var equipment_categories: Array[String] = ["weapon", "tool", "armor", "helmet", "chest", "legs", "hands", "feet", "shield", "accessory"]
var equipment_mapping: Array = []  # Maps display slots to original inventory indices

func _ready():
	# Set up grid container
	if grid_container:
		grid_container.columns = 4  # 4 columns like main inventory

	# Connect to inventory changes
	InventoryManager.inventory_changed.connect(_update_filtered_display)

	# Initial display update
	_update_filtered_display()

func _update_filtered_display():
	# Clear current display
	_clear_current_slots()

	# Find all equipment items in main inventory
	var equipment_items = []
	for i in range(InventoryManager.inventory_slots.size()):
		var slot_data = InventoryManager.inventory_slots[i]
		if not slot_data.is_empty() and _is_equipment_item(slot_data.item):
			equipment_items.append({
				"slot_data": slot_data,
				"original_index": i
			})

	# Create slots for found equipment items
	_create_filtered_slots(equipment_items)

func _is_equipment_item(item: GameItem) -> bool:
	return item.category in equipment_categories

func _clear_current_slots():
	# Remove all current slot nodes
	for slot_node in slot_nodes:
		if is_instance_valid(slot_node):
			slot_node.queue_free()
	slot_nodes.clear()
	equipment_mapping.clear()

func _create_filtered_slots(equipment_items: Array):
	# Create new slots for each equipment item
	for i in range(equipment_items.size()):
		var equipment_data = equipment_items[i]

		# Create new slot from scene
		var slot_scene = preload("res://ui/inventory_slot.tscn")
		var slot_node = slot_scene.instantiate()

		# Configure the slot
		slot_node.slot_index = i  # Display index
		slot_node.is_equipment_slot = false  # This is inventory, not equipment slot
		slot_node.is_hotbar_slot = false
		slot_node.is_weapon_slot = false
		
		# Connect signals
		if slot_node.has_signal("slot_clicked"):
			slot_node.slot_clicked.connect(_on_filtered_slot_clicked)

		# Add to grid and track
		grid_container.add_child(slot_node)
		slot_nodes.append(slot_node)
		equipment_mapping.append(equipment_data.original_index)

		# Update display with the equipment data
		slot_node.update_display(equipment_data.slot_data)

func _on_filtered_slot_clicked(display_slot_index: int, _is_hotbar: bool):
	# Convert display index to original inventory index
	if display_slot_index < equipment_mapping.size():
		var original_index = equipment_mapping[display_slot_index]
		print("Filtered equipment slot ", display_slot_index, " (original inventory slot ", original_index, ") clicked")
		
		# Start drag using original inventory index
		var inventory_system = _get_inventory_system()
		if inventory_system:
			var slot_data = InventoryManager.get_inventory_slot(original_index)
			if slot_data and not slot_data.is_empty():
				inventory_system.start_drag(original_index, false, false, false)

func get_original_slot_index(display_index: int) -> int:
	# Convert filtered display index to original inventory slot index
	if display_index < equipment_mapping.size():
		return equipment_mapping[display_index]
	return -1

func _get_inventory_system() -> Node:
	# Navigate to find the inventory system
	var ui_layer = get_node("/root/Platformer/UI")
	if ui_layer:
		return ui_layer.get_node_or_null("InventorySystem")
	return null
