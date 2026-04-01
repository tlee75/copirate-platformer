extends Node
class_name InteractiveObjectComponent

@export var object_name: String = "Object"
@export var inventory_slots: int = 6
@export var accepted_categories: Array[String] = []

var inventory: Array[InventoryManager.ItemStack] = []
var ui_manager: Node

func _ready():
	inventory.clear()
	await get_tree().process_frame
	await get_tree().process_frame
	ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if not ui_manager:
		print("Warning: UI Manager not found")

func interact():
	if ui_manager and ui_manager.has_method("open_object_menu"):
		ui_manager.open_object_menu(get_parent(), object_name, inventory_slots)
	else:
		print("UI Manager not found or missing open_object_menu method!")

# ============================================================================
# CENTRALIZED VALIDATION SYSTEM
# ============================================================================

func can_accept_item(item: GameItem, amount: int = 1) -> bool:
	"""Item acceptance validation"""
	if not item:
		return false
	
	# Check category acceptance
	if not _is_category_accepted(item.category):
		return false
	
	# Check inventory space
	return _has_space_for_item(item, amount)

func get_rejection_reason(item: GameItem, amount: int = 1) -> String:
	"""Get human-readable reason why item cannot be accepted"""
	if not item:
		return "Invalid item"
	
	if not _is_category_accepted(item.category):
		return "Object does not accept " + item.category + " items"
	
	if not _has_space_for_item(item, amount):
		return "Object inventory is full"
	
	return ""

func _is_category_accepted(category: String) -> bool:
	"""Check if item category is accepted by this object"""
	return accepted_categories.size() == 0 or category in accepted_categories

func _has_space_for_item(item: GameItem, amount: int = 1) -> bool:
	"""Check if object has space for the given item/amount"""
	var remaining = amount
	
	# Check existing stacks for available space
	for stack in inventory:
		if stack.item.name == item.name and stack.quantity < item.stack_size:
			var can_add = item.stack_size - stack.quantity
			remaining -= can_add
			if remaining <= 0:
				return true
	
	# Check if we have empty slots for new stacks
	var empty_slots = inventory_slots - inventory.size()
	var stacks_needed = (remaining + item.stack_size - 1.0) / item.stack_size
	
	return empty_slots >= stacks_needed

# ============================================================================
# INVENTORY OPERATIONS (using centralized validation)
# ============================================================================

func add_item(item: GameItem, amount: int = 1) -> bool:
	"""Add item to this object's inventory with validation"""
	if not can_accept_item(item, amount):
		var reason = get_rejection_reason(item, amount)
		if reason != "":
			print("Cannot add item: ", reason)
		return false
	
	var remaining = amount
	
	# Try to add to existing stacks first
	for stack in inventory:
		if stack.item.name == item.name and stack.quantity < item.stack_size:
			var can_add = min(remaining, item.stack_size - stack.quantity)
			stack.quantity += can_add
			remaining -= can_add
			if remaining <= 0:
				print("Added ", amount, "x ", item.name, " to existing object stack")
				return true
	
	# Create new stacks as needed
	while remaining > 0 and inventory.size() < inventory_slots:
		var stack_size = min(remaining, item.stack_size)
		var new_stack = InventoryManager.ItemStack.new(item, stack_size)
		inventory.append(new_stack)
		remaining -= stack_size
		print("Created new object stack: ", stack_size, "x ", item.name)
	
	return remaining == 0

func remove_item(item_name: String, amount: int = 1) -> bool:
	"""Remove item from this object's inventory"""
	var remaining = amount
	
	# Remove from stacks, starting from the end to safely remove empty stacks
	for i in range(inventory.size() - 1, -1, -1):
		var stack = inventory[i]
		if stack.item.name == item_name:
			var to_remove = min(remaining, stack.quantity)
			stack.quantity -= to_remove
			remaining -= to_remove
			
			# Clean up empty stack
			if stack.quantity <= 0:
				inventory.remove_at(i)
			
			if remaining <= 0:
				print("Removed ", amount, "x ", item_name, " from object inventory")
				return true
	
	if remaining > 0:
		print("Could not remove all requested ", item_name, " from object (", remaining, " not found)")
	return remaining == 0

func get_item_count(item_name: String) -> int:
	"""Get total count of specific item in this object's inventory"""
	var total = 0
	for stack in inventory:
		if stack.item.name == item_name:
			total += stack.quantity
	return total

func has_item(item_name: String, amount: int = 1) -> bool:
	"""Check if object has at least the specified amount of an item"""
	return get_item_count(item_name) >= amount

# ============================================================================
# LEGACY COMPATIBILITY
# ============================================================================

# For backward compatibility with old firepit code
var object_menu: Array[InventoryManager.InventorySlotData]:
	get:
		var legacy_slots: Array[InventoryManager.InventorySlotData] = []
		for stack in inventory:
			var slot = InventoryManager.InventorySlotData.new(stack.item, stack.quantity)
			legacy_slots.append(slot)
		while legacy_slots.size() < inventory_slots:
			legacy_slots.append(InventoryManager.InventorySlotData.new())
		return legacy_slots
	set(value):
		inventory.clear()
		for slot in value:
			if not slot.is_empty():
				var stack = InventoryManager.ItemStack.new(slot.item, slot.quantity)
				inventory.append(stack)

# Action system - override in child objects
func get_available_actions() -> Array[String]:
	return []

func perform_action(action_name: String):
	print("No action implementation for: ", action_name, " in ", object_name)

func get_current_state_description() -> String:
	return "Ready"
