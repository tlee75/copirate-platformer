extends Node

# Singleton inventory manager that handles all inventory logic
# Visual components are handled by UI scenes, this only manages data

signal inventory_changed
signal hotbar_changed

# Item data structure
class InventoryItem:
	var id: String = ""
	var name: String = ""
	var texture: Texture2D = null
	var stack_size: int = 1
	var description: String = ""
	
	func _init(item_id: String = "", item_name: String = "", item_texture: Texture2D = null, max_stack: int = 1, item_desc: String = ""):
		id = item_id
		name = item_name
		texture = item_texture
		stack_size = max_stack
		description = item_desc

class InventorySlotData:
	var item: InventoryItem = null
	var quantity: int = 0
	
	func is_empty() -> bool:
		return item == null or quantity <= 0
	
	func can_add_item(new_item: InventoryItem, amount: int = 1) -> bool:
		if is_empty():
			return true
		return item.id == new_item.id and quantity + amount <= item.stack_size
	
	func add_item(new_item: InventoryItem, amount: int = 1) -> int:
		if is_empty():
			item = new_item
			quantity = min(amount, new_item.stack_size)
			return amount - quantity
		elif item.id == new_item.id:
			var can_add = min(amount, item.stack_size - quantity)
			quantity += can_add
			return amount - can_add
		return amount
	
	func remove_item(amount: int = 1) -> int:
		var removed = min(amount, quantity)
		quantity -= removed
		if quantity <= 0:
			item = null
			quantity = 0
		return removed
	
	func clear():
		item = null
		quantity = 0

# Inventory data
var hotbar_slots: Array[InventorySlotData] = []
var inventory_slots: Array[InventorySlotData] = []

# Item database - you can add more items here
var item_database: Dictionary = {}

func _ready():
	# Initialize slots
	for i in 8:  # 8 hotbar slots
		hotbar_slots.append(InventorySlotData.new())
	
	for i in 16:  # 16 inventory slots
		inventory_slots.append(InventorySlotData.new())
	
	# Initialize item database with gold coin
	register_item("gold_coin", "Gold Coin", load("res://assets/Pirate Treasure/Sprites/Gold Coin/01.png"), 9, "Shiny gold coins!")
	
	# Initialize item database with sword
	register_item("sword", "Sword", load("res://assets/Captain Clown Nose/Sprites/Captain Clown Nose/Sword/21-Sword Idle/Sword Idle 01.png"), 1, "Cool Sword!")

	print("InventoryManager initialized with ", hotbar_slots.size(), " hotbar slots and ", inventory_slots.size(), " inventory slots")

func register_item(id: String, item_name: String, texture: Texture2D, max_stack: int = 1, description: String = ""):
	item_database[id] = InventoryItem.new(id, item_name, texture, max_stack, description)

#func add_test_items():
	## Add some gold coins to test drag and drop
	#if item_database.has("gold_coin"):
		#var gold_coin = item_database["gold_coin"]
		#
		## Add coins to hotbar slots
		#hotbar_slots[0].item = gold_coin
		#hotbar_slots[0].quantity = 3
		#
		#hotbar_slots[2].item = gold_coin
		#hotbar_slots[2].quantity = 5
		#
		## Add coins to inventory slots
		#inventory_slots[0].item = gold_coin
		#inventory_slots[0].quantity = 7
		#
		#inventory_slots[4].item = gold_coin
		#inventory_slots[4].quantity = 2
		#
		#print("Added test items to inventory and hotbar")
		#
		## Emit signals to update UI
		#hotbar_changed.emit()
		#inventory_changed.emit()

func get_item_data(id: String) -> InventoryItem:
	return item_database.get(id, null)

# Add item to inventory (tries hotbar first, then main inventory)
func add_item(item_id: String, amount: int = 1) -> bool:
	var item_data = get_item_data(item_id)
	if not item_data:
		print("Item not found in database: ", item_id)
		return false
	
	var remaining = amount
	
	# Try to add to existing stacks in hotbar first
	for slot in hotbar_slots:
		if not slot.is_empty() and slot.item.id == item_id:
			remaining = slot.add_item(item_data, remaining)
			if remaining <= 0:
				hotbar_changed.emit()
				return true
	
	# Try to add to existing stacks in main inventory
	for slot in inventory_slots:
		if not slot.is_empty() and slot.item.id == item_id:
			remaining = slot.add_item(item_data, remaining)
			if remaining <= 0:
				inventory_changed.emit()
				return true
	
	# Try to add to empty slots in hotbar
	for slot in hotbar_slots:
		if slot.is_empty():
			remaining = slot.add_item(item_data, remaining)
			if remaining <= 0:
				hotbar_changed.emit()
				return true
	
	# Try to add to empty slots in main inventory
	for slot in inventory_slots:
		if slot.is_empty():
			remaining = slot.add_item(item_data, remaining)
			if remaining <= 0:
				inventory_changed.emit()
				return true
	
	# If we couldn't add everything, emit signals anyway for partial adds
	if remaining < amount:
		hotbar_changed.emit()
		inventory_changed.emit()
		print("Added ", amount - remaining, " of ", amount, " ", item_data.name, "(s). ", remaining, " couldn't fit.")
		return true
	
	print("Inventory full! Couldn't add ", item_data.name)
	return false

# Move item between slots (for drag and drop)
func move_item(from_hotbar: bool, from_index: int, to_hotbar: bool, to_index: int) -> bool:
	var from_slots = hotbar_slots if from_hotbar else inventory_slots
	var to_slots = hotbar_slots if to_hotbar else inventory_slots
	
	if from_index < 0 or from_index >= from_slots.size():
		return false
	if to_index < 0 or to_index >= to_slots.size():
		return false
	
	var from_slot = from_slots[from_index]
	var to_slot = to_slots[to_index]
	
	# Simple swap for now - can be enhanced for partial moves later
	var temp_item = from_slot.item
	var temp_quantity = from_slot.quantity
	
	from_slot.item = to_slot.item
	from_slot.quantity = to_slot.quantity
	
	to_slot.item = temp_item
	to_slot.quantity = temp_quantity
	
	# Emit appropriate signals
	if from_hotbar:
		hotbar_changed.emit()
	else:
		inventory_changed.emit()
	
	if to_hotbar and to_hotbar != from_hotbar:
		hotbar_changed.emit()
	elif not to_hotbar and to_hotbar != from_hotbar:
		inventory_changed.emit()
	
	return true

# Get slot data for UI
func get_hotbar_slot(index: int) -> InventorySlotData:
	if index >= 0 and index < hotbar_slots.size():
		return hotbar_slots[index]
	return null

func get_inventory_slot(index: int) -> InventorySlotData:
	if index >= 0 and index < inventory_slots.size():
		return inventory_slots[index]
	return null

# Debug functions
func print_inventory():
	print("=== HOTBAR ===")
	for i in hotbar_slots.size():
		var slot = hotbar_slots[i]
		if not slot.is_empty():
			print("Slot ", i, ": ", slot.item.name, " x", slot.quantity)
		else:
			print("Slot ", i, ": Empty")
	
	print("=== INVENTORY ===")
	for i in inventory_slots.size():
		var slot = inventory_slots[i]
		if not slot.is_empty():
			print("Slot ", i, ": ", slot.item.name, " x", slot.quantity)
		else:
			print("Slot ", i, ": Empty")
