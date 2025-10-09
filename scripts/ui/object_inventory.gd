extends Control

class_name ObjectInventory

@onready var object_slots_container: GridContainer
@onready var main_inventory_container: GridContainer
@onready var object_title_label: Label
@onready var close_button: Button

var current_object: Node2D
var object_slots: Array[InventoryManager.InventorySlotData] = []
var slot_scenes: Array[Control] = []

signal inventory_closed

func _ready():
	# Find UI components (adjust paths based on your scene structure)
	object_slots_container = $HBoxContainer/ObjectPanel/VBoxContainer/SlotsGrid
	main_inventory_container = $HBoxContainer/PlayerPanel/VBoxContainer/SlotsGrid
	object_title_label = $HBoxContainer/ObjectPanel/VBoxContainer/TitleLabel
	close_button = $HBoxContainer/ObjectPanel/VBoxContainer/CloseButton
	
	add_to_group("object_inventory")
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Connect to inventory changes to update main inventory display
	InventoryManager.inventory_changed.connect(_on_main_inventory_changed)
	
	# Enable input processing for drag and drop
	set_process_input(true)
	
	hide()

func _input(event):
	if not visible:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# Handle mouse release for drag and drop
		var inventory_system = get_inventory_system()
		if inventory_system and inventory_system.is_dragging:
			var mouse_pos = get_viewport().get_mouse_position()
			var drop_target = find_inventory_slot_under_mouse(mouse_pos)
			if drop_target:
				# Check if dropping on object slot
				if drop_target.has_meta("is_object_slot"):
					handle_object_drop(inventory_system, drop_target)
				else:
					# Check if dragging from object to inventory
					if inventory_system.has_meta("dragging_from_object"):
						handle_object_to_inventory_drop(inventory_system, drop_target)
					else:
						# Regular inventory drop
						inventory_system.end_drag(drop_target.slot_index, drop_target.is_hotbar_slot, drop_target.is_weapon_slot, false)
						
				
				
				get_viewport().set_input_as_handled()

func handle_object_drop(inventory_system, drop_target: Control):
	var object_slot_index = drop_target.get_meta("object_slot_index")
	
	# Check if dragging FROM object slot or TO object slot
	if inventory_system.has_meta("dragging_from_object"):
		# Dragging FROM object slot TO object slot (swap)
		var source_index = inventory_system.drag_source_slot
		var source_slot_data = get_object_slot(source_index)
		var target_slot_data = get_object_slot(object_slot_index)
		
		if source_slot_data and target_slot_data:
			# Swap items
			var temp_item = target_slot_data.item
			var temp_quantity = target_slot_data.quantity
			
			target_slot_data.item = source_slot_data.item
			target_slot_data.quantity = source_slot_data.quantity
			
			source_slot_data.item = temp_item
			source_slot_data.quantity = temp_quantity
			
			# Update both displays
			update_object_slot_display(source_index)
			update_object_slot_display(object_slot_index)
			
			print("Swapped object slots ", source_index, " and ", object_slot_index)
		
		inventory_system.remove_meta("dragging_from_object")
		inventory_system.remove_meta("object_inventory")
	else:
		# Dragging FROM inventory/hotbar TO object slot
		var source_slot_data
		if inventory_system.drag_source_is_hotbar:
			source_slot_data = InventoryManager.get_hotbar_slot(inventory_system.drag_source_slot)
		else:
			source_slot_data = InventoryManager.get_inventory_slot(inventory_system.drag_source_slot)
		var target_slot_data = get_object_slot(object_slot_index)
		
		if source_slot_data and target_slot_data:
			# Check if the item is accepted by this object
			if not can_object_accept_item(source_slot_data.item):
				print("This object cannot accept ", source_slot_data.item.name, " (category: ", source_slot_data.item.category, ")")
				inventory_system.cancel_drag()
				return
			
			if not target_slot_data.is_empty():
				# Target object slot has an item - need to swap
				# Check if target item can go back to source location
				if inventory_system.drag_source_is_hotbar:
					# When swapping with hotbar, validate that the item from hotbar can go to object
					if not can_object_accept_item(target_slot_data.item):
						print("Cannot swap: ", target_slot_data.item.name, " cannot be placed in ", current_object.name)
						inventory_system.cancel_drag()
						return
				else:
					# When swapping with main inventory, validate that the item from inventory can go to object
					if not can_object_accept_item(target_slot_data.item):
						print("Cannot swap: ", target_slot_data.item.name, " cannot be placed in ", current_object.name)
						inventory_system.cancel_drag()
						return
				
				# Perform the swap
				var temp_item = target_slot_data.item
				var temp_quantity = target_slot_data.quantity
				
				target_slot_data.item = source_slot_data.item
				target_slot_data.quantity = source_slot_data.quantity
				
				source_slot_data.item = temp_item
				source_slot_data.quantity = temp_quantity
				
				print("Swapped items between ", "hotbar" if inventory_system.drag_source_is_hotbar else "inventory", " slot ", inventory_system.drag_source_slot, " and object slot ", object_slot_index)
			else:
				# Target object slot is empty - simple move
				target_slot_data.item = source_slot_data.item
				target_slot_data.quantity = source_slot_data.quantity
				source_slot_data.clear()
				
				print("Moved item to object slot ", object_slot_index)
			
			# Update displays
			update_object_slot_display(object_slot_index)
			
			# Emit appropriate signal based on source type
			if inventory_system.drag_source_is_hotbar:
				InventoryManager.hotbar_changed.emit()
			else:
				InventoryManager.inventory_changed.emit()
					
	inventory_system.cleanup_drag()

func update_object_slot_display(slot_index: int):
	if slot_index >= 0 and slot_index < slot_scenes.size():
		var slot_scene = slot_scenes[slot_index]
		var slot_data = object_slots[slot_index]
		if slot_scene and slot_scene.has_method("update_display"):
			slot_scene.update_display(slot_data)

func handle_object_to_inventory_drop(inventory_system, drop_target: Control):
	var source_index = inventory_system.drag_source_slot
	var source_slot_data = get_object_slot(source_index)
	var target_slot_data = InventoryManager.get_inventory_slot(drop_target.slot_index)
	
	if source_slot_data and target_slot_data:
		if not target_slot_data.is_empty():
			# Target slot has an item - check if we can swap
			if not can_object_accept_item(target_slot_data.item):
				print("Cannot swap: ", target_slot_data.item.name, " cannot be placed in ", current_object.name)
				inventory_system.cancel_drag()
				return
		
			# Swap items
			var temp_item = target_slot_data.item
			var temp_quantity = target_slot_data.quantity
			
			# Move item from object to inventory
			target_slot_data.item = source_slot_data.item
			target_slot_data.quantity = source_slot_data.quantity
			
			source_slot_data.item = temp_item
			source_slot_data.quantity = temp_quantity
			
			print("Swapped items between object slot ", source_index, " and inventory slot ", drop_target.slot_index)
		else:
			# Target slot is empty - simple move
			target_slot_data.item = source_slot_data.item
			target_slot_data.quantity = source_slot_data.quantity
			source_slot_data.clear()
			
			print("Moved item from object slot ", source_index, " to inventory slot ", drop_target.slot_index)
		
		# Update displays
		update_object_slot_display(source_index)
		InventoryManager.inventory_changed.emit()

	
	inventory_system.remove_meta("dragging_from_object")
	inventory_system.remove_meta("object_inventory")
	inventory_system.cleanup_drag()

func find_inventory_slot_under_mouse(mouse_pos: Vector2) -> Control:
	# Check our main inventory slots
	for child in main_inventory_container.get_children():
		if child.get_global_rect().has_point(mouse_pos):
			return child
	
	# Check object slots too
	for child in object_slots_container.get_children():
		if child.get_global_rect().has_point(mouse_pos):
			return child
	
	return null

func get_inventory_system():
	var systems = get_tree().get_nodes_in_group("inventory_system")
	return systems[0] if systems.size() > 0 else null

func open_object_inventory(object: Node2D, title: String, slot_count: int):
	current_object = object
	object_title_label.text = title

	
	# Get reference to the object's actual inventory data
	var interactive_object = null
	for child in object.get_children():
		if child is InteractiveObject:
			interactive_object = child
			break
			
	if interactive_object:
		object_slots = interactive_object.object_inventory
		print("DEBUG: Connected to InteractiveObject inventory")
		print("  - object_inventory size: ", interactive_object.object_inventory.size())
		for i in range(interactive_object.object_inventory.size()):
			var slot = interactive_object.object_inventory[i]
			print("  - slot[", i, "]: ", "empty" if slot.is_empty() else slot.item.name + " x" + str(slot.quantity))
	else:
		print("DEBUG: No InteractiveObject found, creating local slots")
		object_slots.clear()
		for i in slot_count:
			object_slots.append(InventoryManager.InventorySlotData.new())
			
	# Initialize object slots
	setup_object_slots(slot_count)
	setup_main_inventory()

	
	show()
	#is_visible_flag = true
	print("Opened ", title, " inventory")

func setup_object_slots(slot_count: int):
	# Clean existing slots
	for slot_scene in slot_scenes:
		if is_instance_valid(slot_scene):
			slot_scene.queue_free()
	
	# Create new slots
	for i in slot_count:
		
		# Create slot UI (reuse your existing inventory slot scene)
		var slot_scene = preload("res://scenes/ui/inventory_slot.tscn").instantiate()
		slot_scene.slot_index = i
		slot_scene.is_hotbar_slot = false
		slot_scene.set_meta("is_object_slot", true)
		slot_scene.set_meta("object_slot_index", i)
		
		slot_scenes.append(slot_scene)
		object_slots_container.add_child(slot_scene)
			
		# Connect slot signals for drag/drop
		if slot_scene.has_signal("slot_clicked"):
			slot_scene.slot_clicked.connect(_on_object_slot_clicked.bind(i))
		
		# Update slot display with object inventory data
		slot_scene.update_display(object_slots[i])

		# Ensure the slot knows about its data
		slot_scene.slot_data = object_slots[i]

func setup_main_inventory():
	# Clear existing display
	for child in main_inventory_container.get_children():
		child.queue_free()
	
	# Create inventory slots that connect directly to InventoryManager
	for i in InventoryManager.inventory_slots.size():
		var slot_scene = preload("res://scenes/ui/inventory_slot.tscn").instantiate()
		
		# Configure the slot to connect to InventoryManager
		slot_scene.slot_index = i
		slot_scene.is_hotbar_slot = false
		slot_scene.is_weapon_slot = false
		slot_scene.is_equipment_slot = false
		
		# Add to our container
		main_inventory_container.add_child(slot_scene)
		
		# Update display with current InventoryManager data
		var slot_data = InventoryManager.get_inventory_slot(i)
		if slot_data:
			slot_scene.update_display(slot_data)
	
	print("Created inventory display connected to InventoryManager")

func _on_object_slot_clicked(slot_index: int, _is_hotbar: bool, _extra_param = null):
	print("DEBUG: Object slot ", slot_index, " clicked!")
	print("  - Object slot has data: ", get_object_slot(slot_index) != null)
	var slot_data = get_object_slot(slot_index)
	if slot_data:
		print("  - Object slot is_empty: ", slot_data.is_empty())
		if not slot_data.is_empty():
			print("  - Object slot item: ", slot_data.item.name, " x", slot_data.quantity)
	
	# Handle clicking on object inventory slots
	print("Object slot ", slot_index, " clicked")

func _on_main_slot_clicked(slot_index: int, _is_hotbar: bool):
	# Handle clicking on main inventory slots
	print("Main inventory slot ", slot_index, " clicked")

func _on_close_pressed():
	close_inventory()


func close_inventory():
	# Cleanup cloned inventory display
	for child in main_inventory_container.get_children():
		child.queue_free()
	
	if current_object and current_object.has_method("on_inventory_closed"):
		current_object.on_inventory_closed()
	
	hide()
	#is_visible_flag = false
	inventory_closed.emit()
	current_object = null

func get_object_slot(index: int) -> InventoryManager.InventorySlotData:
	if index >= 0 and index < object_slots.size():
		return object_slots[index]
	
	return null

func _on_main_inventory_changed():
	# Update main inventory display when inventory changes
	if main_inventory_container:
		var children = main_inventory_container.get_children()
		for i in range(children.size()):
			var slot_scene = children[i]
			var slot_data = InventoryManager.get_inventory_slot(i)
			if slot_data and slot_scene.has_method("update_display"):
				slot_scene.update_display(slot_data)

func can_object_accept_item(item: GameItem) -> bool:
	if not current_object:
		return true  # No restrictions if no object
	
	# Find the InteractiveObject component
	var interactive_object = null
	for child in current_object.get_children():
		if child is InteractiveObject:
			interactive_object = child
			break
	
	if not interactive_object:
		return true  # No restrictions if no InteractiveObject
	
	# Check if item category is accepted
	if interactive_object.accepted_categories.is_empty():
		return true  # Accept all items if no restrictions
	
	var item_accepted = item.category in interactive_object.accepted_categories
	print("DEBUG: Item validation - ", item.name, " (", item.category, ") -> ", "accepted" if item_accepted else "rejected")
	print("  - Accepted categories: ", interactive_object.accepted_categories)
	
	return item_accepted
