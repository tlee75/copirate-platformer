extends Node

# Inventory System Controller - handles drag and drop between UI components
# This will be added to the main scene to coordinate between hotbar and inventory UI

signal inventory_toggled(is_open: bool)

var hotbar_ui: Control
var main_inventory_ui: Control

var drag_source_slot: int = -1
var drag_source_is_hotbar: bool = false
var is_dragging: bool = false
var drag_preview: Control

func _ready():
	# This will be connected when added to the main scene
	pass

func setup_ui_references(hotbar: Control, inventory: Control):
	hotbar_ui = hotbar
	main_inventory_ui = inventory
	
	# Connect all slot signals through the UI managers
	_connect_hotbar_signals()
	_connect_inventory_signals()

func _connect_hotbar_signals():
	if not hotbar_ui:
		return
	
	# Hotbar slots are already connected in hotbar.gd script
	# We'll override their drag functions

func _connect_inventory_signals():
	if not main_inventory_ui:
		return
	
	# Inventory slots are already connected in main_inventory.gd script
	# We'll override their drag functions

func start_drag(slot_index: int, is_hotbar: bool):
	if is_dragging:
		return
	
	var slot_data
	if is_hotbar:
		slot_data = InventoryManager.get_hotbar_slot(slot_index)
	else:
		slot_data = InventoryManager.get_inventory_slot(slot_index)
	
	if not slot_data or slot_data.is_empty():
		return
	
	is_dragging = true
	drag_source_slot = slot_index
	drag_source_is_hotbar = is_hotbar
	
	# Create drag preview (simplified for now)
	create_drag_preview(slot_data)
	print("Started dragging from ", "hotbar" if is_hotbar else "inventory", " slot ", slot_index)

func end_drag(target_slot: int, target_is_hotbar: bool):
	if not is_dragging:
		return
	
	# Perform the move
	var success = InventoryManager.move_item(
		drag_source_is_hotbar, drag_source_slot,
		target_is_hotbar, target_slot
	)
	
	if success:
		print("Moved item from ", "hotbar" if drag_source_is_hotbar else "inventory", " slot ", drag_source_slot,
			  " to ", "hotbar" if target_is_hotbar else "inventory", " slot ", target_slot)
	else:
		print("Failed to move item")
	
	# Clean up drag state
	cleanup_drag()

func cancel_drag():
	print("Drag cancelled")
	cleanup_drag()

func cleanup_drag():
	is_dragging = false
	drag_source_slot = -1
	drag_source_is_hotbar = false
	
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

func create_drag_preview(slot_data: InventoryManager.InventorySlotData):
	# Create a simple preview that follows the mouse
	drag_preview = Control.new()
	drag_preview.name = "DragPreview"
	
	var icon = TextureRect.new()
	icon.texture = slot_data.item.texture
	icon.size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	
	drag_preview.add_child(icon)
	get_tree().current_scene.add_child(drag_preview)
	
	# Update preview position
	drag_preview.global_position = get_viewport().get_mouse_position() - Vector2(24, 24)

func _process(_delta):
	if is_dragging and drag_preview:
		drag_preview.global_position = get_viewport().get_mouse_position() - Vector2(24, 24)

func toggle_inventory():
	print("InventorySystem: toggle_inventory called")
	if main_inventory_ui:
		print("InventorySystem: main_inventory_ui found, calling toggle")
		main_inventory_ui.toggle_inventory()
		inventory_toggled.emit(main_inventory_ui.is_visible_flag)
	else:
		print("InventorySystem: main_inventory_ui is null!")
