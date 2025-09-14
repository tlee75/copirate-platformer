extends PanelContainer

signal slot_clicked(slot_index)
signal slot_gui_input(event, slot_index)
signal item_dropped_on_slot(source_slot_index, target_slot_index)

var item_texture: TextureRect
var quantity_label: Label
var highlight: ColorRect

var inventory_slot_data: InventorySlot = null
var slot_index: int = -1

func _ready():
	item_texture = get_node("ItemTexture")
	quantity_label = get_node("QuantityLabel")
	highlight = get_node("Highlight")
	
	# Ensure child controls do not block drag‑and‑drop input
	if item_texture:
		item_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if quantity_label:
		quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if highlight:
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	update_display()
	# Ensure the slot receives drop events reliably
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect signals for hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event: InputEvent):
	# Only start a drag if this slot actually contains an item
	if inventory_slot_data and inventory_slot_data.item:
		if event.is_action_pressed("left_click"):
			slot_clicked.emit(slot_index)
		slot_gui_input.emit(event, slot_index)

func _get_drag_data(at_position: Vector2) -> Variant:
	if inventory_slot_data and inventory_slot_data.item:
		var drag_preview = TextureRect.new()
		drag_preview.texture = inventory_slot_data.item.texture
		drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		drag_preview.custom_minimum_size = size
		
		var data = {
			"source_slot_index": slot_index,
			"item": inventory_slot_data.item,
			"quantity": inventory_slot_data.quantity
		}
		
		set_drag_preview(drag_preview)
		return data
	return null

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Simple validation: accept any valid drag data as long as it's not the same slot
	if not (data is Dictionary and data.has("source_slot_index")):
		return false
	return data["source_slot_index"] != slot_index

func _drop_data(at_position: Vector2, data: Variant):
	# Emit drop signal for any valid non‑self drop
	if not (data is Dictionary and data.has("source_slot_index")):
		return
	var source_slot_index = data["source_slot_index"]
	if source_slot_index != slot_index:
		item_dropped_on_slot.emit(source_slot_index, slot_index)

func update_display():
	if inventory_slot_data and inventory_slot_data.item:
		item_texture.texture = inventory_slot_data.item.texture
		if inventory_slot_data.quantity > 1:
			quantity_label.text = str(inventory_slot_data.quantity)
		else:
			quantity_label.text = ""
	else:
		item_texture.texture = null
		quantity_label.text = ""

func set_inventory_slot_data(data: InventorySlot):
	inventory_slot_data = data
	update_display()

func _on_mouse_entered():
	highlight.visible = true

func _on_mouse_exited():
	highlight.visible = false
