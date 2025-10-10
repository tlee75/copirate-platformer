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
	
	add_to_group("inventory_system")

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
	var inventory_slots = []
	if main_inventory_ui and main_inventory_ui.visible:
		# Regular MainInventory case
		inventory_slots = get_all_slots_from_container(main_inventory_ui)
		print("Checking main inventory slots, found ", inventory_slots.size(), " slots")
	
	for slot in inventory_slots:
		if slot.get_global_rect().has_point(mouse_pos):
			print("Found matching inventory slot: ", slot.slot_index)
			return slot

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
	
	var object_inventories = get_tree().get_nodes_in_group("object_inventory")
	for obj_inv in object_inventories:
		if obj_inv.visible:
			var obj_slot_data = obj_inv.get_object_slot(slot_index)
			if obj_slot_data and not obj_slot_data.is_empty():
				print("DEBUG: Found object slot data, starting object drag")
				is_dragging = true
				drag_source_slot = slot_index
				drag_source_is_hotbar = false
				drag_source_is_weaponbar = false
				drag_source_is_equipment = false
				
				set_meta("dragging_from_object", true)
				set_meta("object_inventory", obj_inv)
				
				create_drag_preview(obj_slot_data)
				print("Started dragging from object slot ", slot_index)
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

	# Handle dragging FROM object inventory
	if has_meta("dragging_from_object") and get_meta("dragging_from_object"):
		var object_inventory = get_meta("object_inventory")
		var source_slot_data = object_inventory.get_object_slot(drag_source_slot)
		
		var target_slot_data
		if target_is_hotbar:
			target_slot_data = InventoryManager.get_hotbar_slot(target_slot)
		elif target_is_weaponbar:
			target_slot_data = InventoryManager.get_weaponbar_slot(target_slot)
		else:
			target_slot_data = InventoryManager.get_inventory_slot(target_slot)
		
		if source_slot_data and target_slot_data:
			# Check if target slot is occupied for swapping
			if not target_slot_data.is_empty():
				# Before swapping, validate that the target item can go into the object inventory
				if not object_inventory.can_object_accept_item(target_slot_data.item):
					print("Cannot swap: ", target_slot_data.item.name, " (", target_slot_data.item.category, ") is not accepted by ", object_inventory.current_object.name)
					cleanup_drag()
					return
				
				# Swap items between object slot and target slot
				var temp_item = target_slot_data.item
				var temp_quantity = target_slot_data.quantity
				
				target_slot_data.item = source_slot_data.item
				target_slot_data.quantity = source_slot_data.quantity
				
				source_slot_data.item = temp_item
				source_slot_data.quantity = temp_quantity
				
				print("Swapped items between object slot ", drag_source_slot, " and ", "hotbar" if target_is_hotbar else "inventory", " slot ", target_slot)
			else:
				# Move item from object to target
				target_slot_data.item = source_slot_data.item
				target_slot_data.quantity = source_slot_data.quantity
				source_slot_data.clear()
				
				print("Moved item from object slot ", drag_source_slot, " to ", "hotbar" if target_is_hotbar else "inventory", " slot ", target_slot)
			
			# Update displays
			object_inventory.update_object_slot_display(drag_source_slot)
			if target_is_hotbar:
				InventoryManager.hotbar_changed.emit()
			elif target_is_weaponbar:
				InventoryManager.weapon_changed.emit()
			else:
				InventoryManager.inventory_changed.emit()
				# Also update the object inventory UI's main inventory display
				if object_inventory.has_method("_on_main_inventory_changed"):
					object_inventory._on_main_inventory_changed()
				
		# Clean up object metadata
		set_meta("dragging_from_object", false)
		set_meta("object_inventory", null)
		cleanup_drag()
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

	var regular_source_slot_data = InventoryManager.get_slot_by_type(source_type, drag_source_slot)
	
	# Centralized validation for all slot types
	if not _can_place_item_in_slot(regular_source_slot_data.item, target_type, target_slot_node):
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
	
	# Clean up any object inventory metadata
	if has_meta("dragging_from_object"):
		remove_meta("dragging_from_object")
	if has_meta("object_inventory"):
		remove_meta("object_inventory")
	
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
	var slot_node_name = target_slot_node.name
	if not equipment_ui.can_equip_item(item, slot_node_name):
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
