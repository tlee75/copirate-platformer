extends Node

# Inventory System Controller - handles drag and drop between UI components
# This will be added to the main scene to coordinate between hotbar, weaponbar and inventory UI

signal inventory_toggled(is_open: bool)

var hotbar_ui: Control
var main_inventory_ui: Control
var equipment_inventory_ui: Control
var weaponbar_ui: Control
var equipment_ui: Control

# Public drag state variables for slots to check
var drag_source_slot: int = -1
var drag_source_is_hotbar: bool = false
var drag_source_is_weaponbar: bool = false
var drag_source_is_equipment: bool = false
var is_dragging: bool = false
var drag_preview: Control

func _ready():
	# This will be connected when added to the main scene
	# Set process input to handle global mouse releases
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if not mouse_event.pressed and is_dragging:
				print("Mouse button released while dragging - processing drop")
				# Mouse released - check what's under the mouse cursor
				var drop_target = find_slot_under_mouse()
				if drop_target:
					var slot_type_name = "inventory"
					if drop_target.is_hotbar_slot:
						slot_type_name = "hotbar"
					elif drop_target.is_weapon_slot:
						slot_type_name = "weapon"
					elif drop_target.has_method("get") and drop_target.get("is_equipment_slot"):
						slot_type_name = "equipment"
					print("Drop target found: slot ", drop_target.slot_index, " (", slot_type_name, ")")
					end_drag(drop_target.slot_index, drop_target.is_hotbar_slot, drop_target.is_weapon_slot, drop_target.is_equipment_slot if drop_target.has_method("get") and drop_target.get("is_equipment_slot") else false)
				else:
					print("Drag cancelled - mouse released outside any slot")
					cancel_drag()
				get_viewport().set_input_as_handled()
			elif mouse_event.pressed and is_dragging:
				print("Mouse button pressed while already dragging - ignoring")

func find_source_slot_node():
	var containers = []
	if hotbar_ui:
		containers.append(hotbar_ui)
	if main_inventory_ui:
		containers.append(main_inventory_ui)
	if weaponbar_ui:
		containers.append(weaponbar_ui)
	if equipment_ui: # The equipment slots
		containers.append(equipment_ui)
	if equipment_inventory_ui: # The filtered equipment next to the equipment slots
		containers.append(equipment_inventory_ui)

	for container in containers:
		var slots = get_all_slots_from_container(container)
		for slot in slots:
			if slot.has_method("get") and slot.get("slot_index") == drag_source_slot:
				return slot
	return null

func find_slot_under_mouse():
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Check hotbar slots
	if hotbar_ui:
		var hotbar_slots = get_all_slots_from_container(hotbar_ui)
		for slot in hotbar_slots:
			if slot.get_global_rect().has_point(mouse_pos):
				return slot

	# Check for equpiment slotsefore (higher priority)
	if equipment_ui and equipment_ui.visible:
		print("DEBUG: Checking equipment slots. equipment_ui exists and visible")
		var equipment_slots = get_all_slots_from_container(equipment_ui)
		print("DEBUG: Found ", equipment_slots.size(), " equipment slots")
		for slot in equipment_slots:
			print("DEBUG: Equipment slot ", slot.slot_index, " rect: ", slot.get_global_rect(), " mouse: ", mouse_pos)
			if slot.get_global_rect().has_point(mouse_pos):
				print("DEBUG: MATCH! Found equipment slot: ", slot.slot_index, " is_equipment: ", slot.is_equipment_slot)
				return slot	
		
	# Check weapon bar slots
	if weaponbar_ui:
		var weaponbar_slots = get_all_slots_from_container(weaponbar_ui)
		for slot in weaponbar_slots:
			if slot.get_global_rect().has_point(mouse_pos):
				return slot

	# Check for filtered equipment inventory slots
	if equipment_inventory_ui and equipment_inventory_ui.visible:
		var filtered_inventory_slots = get_all_slots_from_container(equipment_inventory_ui)
		for slot in filtered_inventory_slots:
			if slot.get_global_rect().has_point(mouse_pos):
				return slot

	# Check inventory slots
	if main_inventory_ui and main_inventory_ui.visible:
		print("Checking inventory slots, found ", get_all_slots_from_container(main_inventory_ui).size(), " slots")
		var inventory_slots = get_all_slots_from_container(main_inventory_ui)
		for slot in inventory_slots:
			if slot.get_global_rect().has_point(mouse_pos):
				print("Found matching inventory slot: ", slot.slot_index)
				return slot
	else:
		if main_inventory_ui:
			print("Main inventory UI not visible or null: visible=", main_inventory_ui.visible)
		else:
			print("Main inventory UI not visible or null: visible=null")

	return null

func get_all_slots_from_container(container: Control) -> Array:
	var slots = []
	
	# Recursively find all inventory slot nodes
	var stack = [container]
	while stack.size() > 0:
		var current = stack.pop_back()
		for child in current.get_children():
			if child.has_method("update_display") and child.has_method("get_script") and child.get_script() and child.get_script().resource_path.ends_with("inventory_slot.gd"):
				slots.append(child)
			else:
				stack.push_back(child)
	
	return slots

func setup_ui_references(hotbar: Control, inventory: Control, weaponbar: Control, equipment: Control = null, equipment_inventory: Control = null):
	hotbar_ui = hotbar
	main_inventory_ui = inventory
	weaponbar_ui = weaponbar
	equipment_ui = equipment
	equipment_inventory_ui = equipment_inventory

func _connect_weaponbar_signals():
	if not weaponbar_ui:
		return

func start_drag(slot_index: int, is_hotbar: bool, is_weaponbar: bool, is_equipment: bool = false):
	if is_dragging:
		return
	
	var slot_data
	if is_hotbar:
		slot_data = InventoryManager.get_hotbar_slot(slot_index)
	elif is_weaponbar:
		slot_data = InventoryManager.get_weaponbar_slot(slot_index)
	elif is_equipment:
		slot_data = InventoryManager.get_equipment_slot(slot_index)
	else:
		slot_data = InventoryManager.get_inventory_slot(slot_index)
	
	if not slot_data or slot_data.is_empty():
		return
	
	is_dragging = true
	drag_source_slot = slot_index
	drag_source_is_hotbar = is_hotbar
	drag_source_is_weaponbar = is_weaponbar
	drag_source_is_equipment = is_equipment
	
	# Create drag preview (simplified for now)
	create_drag_preview(slot_data)
	print("Started dragging from ", "hotbar" if is_hotbar else ("weapon" if is_weaponbar else "inventory"), " slot ", slot_index)

func end_drag(target_slot: int, target_is_hotbar: bool, target_is_weaponbar: bool = false, target_is_equipment: bool = false):
	if not is_dragging:
		return

	var source_slot_node = find_source_slot_node()
	var target_slot_node = find_slot_under_mouse()

	var source_type = InventoryManager.SlotType.HOTBAR if drag_source_is_hotbar else (InventoryManager.SlotType.WEAPON if drag_source_is_weaponbar else (InventoryManager.SlotType.EQUIPMENT if drag_source_is_equipment else InventoryManager.SlotType.INVENTORY))
	if source_slot_node and source_slot_node.is_weapon_slot:
		source_type = InventoryManager.SlotType.WEAPON
	elif source_slot_node and source_slot_node.has_method("get") and source_slot_node.get("is_equipment_slot"):
		source_type = InventoryManager.SlotType.EQUIPMENT
		
	var target_type = InventoryManager.SlotType.HOTBAR if target_is_hotbar else (InventoryManager.SlotType.WEAPON if target_is_weaponbar else (InventoryManager.SlotType.EQUIPMENT if target_is_equipment else InventoryManager.SlotType.INVENTORY))
	if target_slot_node and target_slot_node.is_weapon_slot:
		target_type = InventoryManager.SlotType.WEAPON
	elif target_slot_node and target_slot_node.has_method("get") and target_slot_node.get("is_equipment_slot"):
		target_type = InventoryManager.SlotType.EQUIPMENT

	var source_slot_data = InventoryManager.get_slot_by_type(source_type, drag_source_slot)
	
	# Centralized validation for all slot types
	if not _can_place_item_in_slot(source_slot_data.item, target_type, target_slot_node):
		cleanup_drag()
		return
			
	var success = InventoryManager.move_item_extended(
		source_type, drag_source_slot,
		target_type, target_slot
	)

	if success:
		print("Moved item")
	else:
		print("Failed to move item")

	cleanup_drag()

func cancel_drag():
	print("Drag cancelled")
	cleanup_drag()

func cleanup_drag():
	is_dragging = false
	drag_source_slot = -1
	drag_source_is_hotbar = false
	drag_source_is_weaponbar = false
	drag_source_is_equipment = false
	
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

func create_drag_preview(slot_data: InventoryManager.InventorySlotData):
	# Create a simple preview that follows the mouse
	drag_preview = Control.new()
	drag_preview.name = "DragPreview"
	drag_preview.z_index = 1000  # Make sure it appears on top
	
	var icon = TextureRect.new()
	icon.texture = slot_data.item.icon
	icon.size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.modulate = Color(1, 1, 1, 0.8)  # Semi-transparent
	
	drag_preview.add_child(icon)
	
	# Add to the main scene's UI layer for proper layering
	var ui_layer = get_node("/root/Platformer/UI")
	if ui_layer:
		ui_layer.add_child(drag_preview)
	else:
		get_tree().current_scene.add_child(drag_preview)
	
	# Update preview position
	drag_preview.global_position = get_viewport().get_mouse_position() - Vector2(24, 24)
	
	print("Created drag preview with texture: ", slot_data.item.icon)

func _process(_delta):
	if is_dragging and drag_preview:
		# Update drag preview position to follow mouse
		drag_preview.global_position = get_viewport().get_mouse_position() - Vector2(24, 24)
		
		# Check if mouse button is still held down
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Mouse button no longer pressed - ending drag via process check")
			var drop_target = find_slot_under_mouse()
			if drop_target:
				var target_type = "inventory"
				if drop_target.is_hotbar_slot:
					target_type = "hotbar"
				elif drop_target.is_weapon_slot:
					target_type = "weapon"
				elif drop_target.has_method("get") and drop_target.get("is_equipment_slot"):
					target_type = "equipment"
				print("Drop target found: slot ", drop_target.slot_index, " (", target_type, ")")
				end_drag(drop_target.slot_index, drop_target.is_hotbar_slot, drop_target.is_weapon_slot, drop_target.is_equipment_slot if drop_target.has_method("get") and drop_target.get("is_equipment_slot") else false)
			else:
				print("Drag cancelled via process - mouse outside any slot")
				cancel_drag()

# Centralized slot validation dispatcher
func _can_place_item_in_slot(item: GameItem, target_type: int, target_slot_node: Control) -> bool:
	match target_type:
		InventoryManager.SlotType.WEAPON:
			return _can_place_in_weapon_bar(item)
		InventoryManager.SlotType.EQUIPMENT:
			return _can_place_in_equipment_slot(item, target_slot_node)
		InventoryManager.SlotType.HOTBAR, InventoryManager.SlotType.INVENTORY:
			return true # No restrictions on these
	return false

func _can_place_in_weapon_bar(item: GameItem) -> bool:
	if item.category != "weapon" and item.category != "tool":
		print("Only weapons or tools can be placed in teh weapon bar")
		return false
	return true

func _can_place_in_equipment_slot(item: GameItem, target_slot_node: Control) -> bool:
	if not equipment_ui or not equipment_ui.has_method("can_equip_item"):
		print("Equipment UI validation not available")
		return false
	var equipment_slot_type = target_slot_node.equipment_type if target_slot_node.has_method("get") and target_slot_node.get("equipment_type") != null else 0
	if not equipment_ui.can_equip_item(item, equipment_slot_type):
		print("Item category '", item.category, "' cannot be equipped in this slot")
		return false
	return true

func toggle_inventory():
	print("InventorySystem: toggle_inventory called")
	if main_inventory_ui:
		print("InventorySystem: main_inventory_ui found, calling toggle")
		main_inventory_ui.toggle_inventory()
		inventory_toggled.emit(main_inventory_ui.is_visible_flag)
	else:
		print("InventorySystem: main_inventory_ui is null!")
