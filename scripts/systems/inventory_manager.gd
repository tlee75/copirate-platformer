extends Node

# Slot-free inventory system with ItemStack-based storage

signal inventory_changed
signal quick_access_changed  
signal equipment_changed
signal item_equipped(item: GameItem, slot_type: String)
signal item_unequipped(item: GameItem, slot_type: String)

# Core item storage - item stacks
var inventory_items: Array[ItemStack] = []
var quick_access_assignments: Array[ItemStack] = []  # Fixed size array of ItemStack references


# Compatibility for old object inventory references
class InventorySlotData:
	var item: GameItem
	var quantity: int
	
	func _init(game_item: GameItem = null, amount: int = 0):
		item = game_item
		quantity = amount
	
	func is_empty() -> bool:
		return item == null or quantity <= 0
	
	func clear():
		item = null
		quantity = 0

# Equipment tracking - direct references to equipped ItemStacks
var equipped_items: Dictionary = {
	"helmet": null,
	"chest": null,
	"legs": null,
	"hands": null,
	"feet": null,
	"arms": null,
	"main_hand": null,
	"off_hand": null,
	"accessory_1": null,
	"accessory_2": null
}

# Category definitions for filtering
var item_categories: Dictionary = {
	"all": "All Items",
	"tool": "Tools",
	"weapon": "Weapons",
	"consumable": "Consumables", 
	"material": "Materials",
	"equipment": "Equipment",
	"armor": "Armor",
	"fuel": "Fuel",
	"food": "Food"
}

class ItemStack:
	var item: GameItem
	var quantity: int
	var equipped_as: String = ""           # Which equipment slot (empty = not equipped)
	var is_locked: bool = false            # Prevent accidental actions
	var quick_access_slot: int = -1       # Which quick access slot (-1 = not in quick access)
	var date_acquired: float = 0.0        # For sorting by recent
	
	func _init(game_item: GameItem, amount: int = 1):
		item = game_item
		quantity = amount
		date_acquired = Time.get_unix_time_from_system()
	
	func is_equipped() -> bool:
		return equipped_as != ""
	
	func is_in_quick_access() -> bool:
		return quick_access_slot != -1
	
	func get_display_name() -> String:
		var name = item.name
		if is_equipped():
			name += " [" + equipped_as.replace("_", " ").capitalize() + "]"
		if is_locked:
			name += " 🔒"
		return name

func _ready():
	print("New ItemStack-based InventoryManager initialized")
	
	# Initialize quick access with 8 empty slots
	quick_access_assignments.resize(8)
	for i in range(8):
		quick_access_assignments[i] = null

# ============================================================================
# CORE INVENTORY OPERATIONS
# ============================================================================

func add_item(item: GameItem, amount: int = 1) -> bool:
	if not item:
		print("ERROR: Attempted to add null item")
		return false
	
	var remaining = amount
	
	# Try to add to existing stacks first (same item, not at stack limit)
	for stack in inventory_items:
		if stack.item.name == item.name and stack.quantity < item.stack_size:
			var can_add = min(remaining, item.stack_size - stack.quantity)
			stack.quantity += can_add
			remaining -= can_add
			if remaining <= 0:
				print("Added ", amount, "x ", item.name, " to existing stack")
				inventory_changed.emit()
				return true
	
	# Create new stacks as needed
	while remaining > 0:
		var stack_size = min(remaining, item.stack_size)
		var new_stack = ItemStack.new(item, stack_size)
		inventory_items.append(new_stack)
		remaining -= stack_size
		print("Created new stack: ", stack_size, "x ", item.name)
	
	inventory_changed.emit()
	return true

func remove_items_by_name(item_name: String, amount: int = 1) -> bool:
	var remaining = amount
	
	# Remove from stacks, starting from the end to safely remove empty stacks
	for i in range(inventory_items.size() - 1, -1, -1):
		var stack = inventory_items[i]
		if stack.item.name == item_name:
			var to_remove = min(remaining, stack.quantity)
			stack.quantity -= to_remove
			remaining -= to_remove
			
			print("Removed ", to_remove, "x ", item_name, " (", remaining, " remaining to remove)")
			
			# Clean up empty stack
			if stack.quantity <= 0:
				_cleanup_depleted_stack(stack, i)
			
			if remaining <= 0:
				inventory_changed.emit()
				if stack.is_in_quick_access():
					quick_access_changed.emit()
				return true
	
	if remaining > 0:
		print("Could not remove all requested ", item_name, " (", remaining, " not found)")
	
	inventory_changed.emit()
	return remaining == 0

func _cleanup_depleted_stack(stack: ItemStack, index: int):
	print("Cleaning up depleted stack: ", stack.item.name)
	
	# Handle equipped items
	if stack.is_equipped():
		print("  Unequipping depleted item from ", stack.equipped_as)
		equipped_items[stack.equipped_as] = null
		equipment_changed.emit()
	
	# Handle quick access assignments
	if stack.is_in_quick_access():
		print("  Removing depleted item from quick access slot ", stack.quick_access_slot)
		quick_access_assignments[stack.quick_access_slot] = null
		quick_access_changed.emit()
	
	# Remove from inventory
	inventory_items.remove_at(index)

func remove_stack(stack: ItemStack, amount: int = -1) -> bool:
	if not stack:
		return false
	
	if amount == -1:
		amount = stack.quantity
	
	return remove_items_by_name(stack.item.name, amount)

# ============================================================================
# EQUIPMENT SYSTEM
# ============================================================================

func equip_item_stack(stack: ItemStack, equipment_slot: String = "") -> bool:
	if not stack or stack.quantity <= 0:
		print("Cannot equip: invalid stack")
		return false
	
	# Auto-determine equipment slot if not specified
	if equipment_slot == "":
		equipment_slot = _get_equipment_slot_for_item(stack.item)
	
	if equipment_slot == "":
		print("Cannot equip ", stack.item.name, ": no suitable equipment slot")
		return false
	
	if not _can_equip_to_slot(stack.item, equipment_slot):
		print("Cannot equip ", stack.item.name, " to slot ", equipment_slot)
		return false
	
	# Unequip current item if slot occupied
	if equipped_items[equipment_slot]:
		var current_equipped = equipped_items[equipment_slot]
		current_equipped.equipped_as = ""
		print("Unequipped ", current_equipped.item.name, " from ", equipment_slot)
	
	# Equip new item
	stack.equipped_as = equipment_slot
	equipped_items[equipment_slot] = stack
	
	print("Equipped ", stack.item.name, " as ", equipment_slot)
	item_equipped.emit(stack.item, equipment_slot)
	equipment_changed.emit()
	inventory_changed.emit()
	return true

func unequip_item(equipment_slot: String) -> bool:
	var stack = equipped_items[equipment_slot]
	if not stack:
		print("No item equipped in slot: ", equipment_slot)
		return false
	
	return _unequip_stack(stack)

func _unequip_stack(stack: ItemStack) -> bool:
	print("Unequipping stack:", stack.item.name, "from", stack.equipped_as)
	if not stack.is_equipped():
		print("Item not equipped: ", stack.item.name)
		return false
	
	var equipment_slot = stack.equipped_as
	stack.equipped_as = ""
	equipped_items[equipment_slot] = null
	
	print("Unequipped ", stack.item.name, " from ", equipment_slot)
	item_unequipped.emit(stack.item, equipment_slot)
	equipment_changed.emit()
	inventory_changed.emit()
	return true

func toggle_equip_item_stack(stack: ItemStack) -> bool:
	if stack.is_equipped():
		return _unequip_stack(stack)
	else:
		return equip_item_stack(stack)

func get_equipped_item(equipment_slot: String) -> GameItem:
	var stack = equipped_items[equipment_slot]
	return stack.item if stack else null

func get_equipped_stack(equipment_slot: String) -> ItemStack:
	return equipped_items[equipment_slot]

func is_item_equipped(item: GameItem) -> bool:
	for stack in equipped_items.values():
		if stack and stack.item == item:
			return true
	return false

# ============================================================================
# QUICK ACCESS SYSTEM  
# ============================================================================

func assign_to_quick_access(stack: ItemStack, slot: int) -> bool:
	if slot < 0 or slot >= quick_access_assignments.size():
		print("Invalid quick access slot: ", slot)
		return false
	
	# Remove from previous quick access slot if assigned
	if stack.is_in_quick_access():
		quick_access_assignments[stack.quick_access_slot] = null
		print("Removed ", stack.item.name, " from quick access slot ", stack.quick_access_slot)
	
	# Clear target slot if occupied
	if quick_access_assignments[slot]:
		quick_access_assignments[slot].quick_access_slot = -1
		print("Cleared quick access slot ", slot)
	
	# Assign to new slot
	quick_access_assignments[slot] = stack
	stack.quick_access_slot = slot
	
	print("Assigned ", stack.item.name, " to quick access slot ", slot)
	quick_access_changed.emit()
	return true

func remove_from_quick_access(slot: int) -> bool:
	if slot < 0 or slot >= quick_access_assignments.size():
		return false
	
	var stack = quick_access_assignments[slot]
	if stack:
		stack.quick_access_slot = -1
		quick_access_assignments[slot] = null
		print("Removed item from quick access slot ", slot)
		quick_access_changed.emit()
		return true
	
	return false

func get_quick_access_item(slot: int) -> GameItem:
	var stack = get_quick_access_stack(slot)
	return stack.item if stack else null

func get_quick_access_stack(slot: int) -> ItemStack:
	if slot >= 0 and slot < quick_access_assignments.size():
		return quick_access_assignments[slot]
	return null

func assign_to_next_quick_access_slot(stack: ItemStack) -> bool:
	# Find first empty quick access slot
	for i in range(quick_access_assignments.size()):
		if quick_access_assignments[i] == null:
			return assign_to_quick_access(stack, i)
	
	print("Quick access is full")
	return false

# ============================================================================
# CATEGORY FILTERING & SEARCH
# ============================================================================

func get_items_by_category(category: String) -> Array[ItemStack]:
	if category == "all":
		return inventory_items.duplicate()
	
	return inventory_items.filter(func(stack): return stack.item.category == category)

func get_available_categories() -> Array:
	var categories = ["all"]
	var found_categories = {}
	
	for stack in inventory_items:
		if not found_categories.has(stack.item.category):
			found_categories[stack.item.category] = true
			categories.append(stack.item.category)
	
	return categories

func search_items(search_text: String) -> Array[ItemStack]:
	if search_text.is_empty():
		return inventory_items.duplicate()
	
	var search_lower = search_text.to_lower()
	return inventory_items.filter(func(stack): 
		return stack.item.name.to_lower().contains(search_lower)
	)

# ============================================================================
# ITEM OPERATIONS
# ============================================================================

func use_item_stack(stack: ItemStack) -> bool:
	if not stack or not stack.item.is_consumable():
		print("Cannot use item: ", stack.item.name if stack else "null")
		return false
	
	print("Using consumable: ", stack.item.name)
	
	# TODO: Implement actual item use effects
	# For now, just consume one item
	return remove_stack(stack, 1)

func lock_item_stack(stack: ItemStack) -> bool:
	if not stack:
		return false
	
	stack.is_locked = true
	print("Locked item: ", stack.item.name)
	inventory_changed.emit()
	return true

func unlock_item_stack(stack: ItemStack) -> bool:
	if not stack:
		return false
	
	stack.is_locked = false
	print("Unlocked item: ", stack.item.name)
	inventory_changed.emit()
	return true

func toggle_lock_item_stack(stack: ItemStack) -> bool:
	if stack.is_locked:
		return unlock_item_stack(stack)
	else:
		return lock_item_stack(stack)

func can_drop_stack(stack: ItemStack) -> bool:
	return stack and not stack.is_locked

func drop_item_stack(stack: ItemStack, amount: int = -1) -> bool:
	if not can_drop_stack(stack):
		print("Cannot drop locked item: ", stack.item.name)
		return false
	
	if amount == -1:
		amount = stack.quantity
	
	# Spawn item in world near the player
	if not LootDropper.drop_single_item(stack.item, amount):
		print("Drop failed for ", stack.item.name, " - item kept in inventory")
		return false

	print("Dropping ", amount, "x ", stack.item.name)

	return remove_stack(stack, amount)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_total_item_count(item_name: String) -> int:
	var total = 0
	for stack in inventory_items:
		if stack.item.name == item_name:
			total += stack.quantity
	return total

func find_item_stack(item_name: String) -> ItemStack:
	for stack in inventory_items:
		if stack.item.name == item_name:
			return stack
	return null

func find_all_item_stacks(item_name: String) -> Array[ItemStack]:
	var stacks = []
	for stack in inventory_items:
		if stack.item.name == item_name:
			stacks.append(stack)
	return stacks

func _get_equipment_slot_for_item(item: GameItem) -> String:
	match item.category:
		"helmet":
			return "helmet"
		"chest", "armor":
			return "chest"
		"legs":
			return "legs"
		"hands":
			return "hands"
		"feet":
			return "feet"
		"arms":
			return "arms"
		"weapon":
			return "main_hand"
		"shield":
			return "off_hand"
		"accessory":
			# Find first available accessory slot
			if equipped_items["accessory_1"] == null:
				return "accessory_1"
			elif equipped_items["accessory_2"] == null:
				return "accessory_2"
			else:
				return "accessory_1"  # Replace first one
		_:
			return ""

func _can_equip_to_slot(item: GameItem, equipment_slot: String) -> bool:
	var expected_slot = _get_equipment_slot_for_item(item)
	return expected_slot == equipment_slot or (expected_slot == "accessory_1" and equipment_slot == "accessory_2")


# ============================================================================
# DEBUG FUNCTIONS
# ============================================================================

func print_inventory():
	print("=== NEW INVENTORY SYSTEM ===")
	print("Total items: ", inventory_items.size())
	
	for i in range(inventory_items.size()):
		var stack = inventory_items[i]
		var status = ""
		if stack.is_equipped():
			status += " [EQUIPPED:" + stack.equipped_as + "]"
		if stack.is_in_quick_access():
			status += " [QUICK ACCESS:" + str(stack.quick_access_slot) + "]"
		if stack.is_locked:
			status += " [LOCKED]"
		
		print("  ", i, ": ", stack.item.name, " x", stack.quantity, status)
	
	print("=== QUICK ACCESS ===")
	for i in range(quick_access_assignments.size()):
		var stack = quick_access_assignments[i]
		if stack:
			print("  ", i, ": ", stack.item.name, " x", stack.quantity)
		else:
			print("  ", i, ": Empty")
	
	print("=== EQUIPMENT ===")
	for slot_name in equipped_items.keys():
		var stack = equipped_items[slot_name]
		if stack:
			print("  ", slot_name, ": ", stack.item.name)
		else:
			print("  ", slot_name, ": Empty")

func debug_add_test_items():
	print("Adding test items...")
	
	# Add some test items if they exist in the database
	var db = GameObjectsDatabase.game_objects_database
	
	if "stick" in db:
		add_item(db["stick"], 10)
	if "simple_rock" in db:
		add_item(db["simple_rock"], 5)
	if "pickaxe" in db:
		add_item(db["pickaxe"], 1)
	if "woodaxe" in db:
		add_item(db["woodaxe"], 1)
	if "sword" in db:
		add_item(db["sword"], 1)
	print_inventory()
