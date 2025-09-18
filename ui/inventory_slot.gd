extends Control

# InventorySlot UI component - handles display and interaction
# The actual data is managed by InventoryManager

signal slot_clicked(slot_index: int, is_hotbar: bool)

@export var slot_index: int = 0
@export var is_hotbar_slot: bool = false

@onready var background: Control = get_node_or_null("Background")
@onready var item_icon: TextureRect = get_node_or_null("ItemIcon")
@onready var quantity_label: Label = get_node_or_null("QuantityLabel")

var slot_data: InventoryManager.InventorySlotData
var is_dragging: bool = false

func _ready():
	# Connect mouse events
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Set up initial appearance
	if quantity_label:
		quantity_label.text = ""
	if item_icon:
		item_icon.texture = null
	
	# Style the quantity label
	if quantity_label:
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		quantity_label.add_theme_color_override("font_color", Color.WHITE)
		quantity_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		quantity_label.add_theme_constant_override("shadow_offset_x", 1)
		quantity_label.add_theme_constant_override("shadow_offset_y", 1)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				slot_clicked.emit(slot_index, is_hotbar_slot)
				if slot_data and not slot_data.is_empty():
					# Start drag through inventory system
					var inventory_system = get_inventory_system()
					if inventory_system:
						inventory_system.start_drag(slot_index, is_hotbar_slot)
			# Mouse release is now handled by the inventory system globally

func _on_mouse_entered():
	if not slot_data or slot_data.is_empty():
		return
	
	# Add hover effect - could show tooltip here
	modulate = Color(1.1, 1.1, 1.1, 1.0)

func _on_mouse_exited():
	modulate = Color.WHITE

func update_display(new_slot_data: InventoryManager.InventorySlotData):
	slot_data = new_slot_data
	
	if slot_data.is_empty():
		if item_icon:
			item_icon.texture = null
		if quantity_label:
			quantity_label.text = ""
	else:
		if item_icon:
			item_icon.texture = slot_data.item.texture
		if quantity_label:
			if slot_data.quantity > 1:
				quantity_label.text = str(slot_data.quantity)
			else:
				quantity_label.text = ""

func set_highlighted(highlighted: bool):
	if background:
		if highlighted:
			background.modulate = Color(1.2, 1.2, 0.8, 1.0)  # Yellow tint
		else:
			background.modulate = Color.WHITE

func can_accept_drop() -> bool:
	# This will be called by the drag and drop system
	return true

func get_inventory_system() -> Node:
	# Navigate up to find the inventory system
	# UI/InventorySystem from the slot's perspective
	var ui_layer = get_node("/root/Platformer/UI")
	if ui_layer:
		return ui_layer.get_node_or_null("InventorySystem")
	return null
