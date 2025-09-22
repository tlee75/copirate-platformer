extends Node

# Singleton inventory manager that handles all inventory logic
# Visual components are handled by UI scenes, this only manages data

signal inventory_changed
signal hotbar_changed

# GameItem data structure

class InventorySlotData:
	var item: GameItem = null
	var quantity: int = 0
	
	func is_empty() -> bool:
		return item == null or quantity <= 0
	
	func can_add_item(new_item: GameItem, amount: int = 1) -> bool:
		if is_empty():
			return true
		return item.name == new_item.name and quantity + amount <= item.stack_size
	
	func add_item(new_item: GameItem, amount: int = 1) -> int:
		if is_empty():
			item = new_item
			quantity = min(amount, new_item.stack_size)
			return amount - quantity
		elif item.name == new_item.name:
			var can_add = min(amount, item.stack_size - quantity)
			quantity += can_add
			return amount - can_add
		return amount
	
	func remove_item(amount: int = 1) -> int:
		var removed = min(amount, quantity)
		quantity -= removed
		if quantity <= 0:
			if item:
				InventoryManager.remove_item_from_total(item.name, removed)
			item = null
			quantity = 0
		else:
			if item:
				InventoryManager.remove_item_from_total(item.name, removed)
		return removed
	
	func clear():
		item = null
		quantity = 0

# Inventory data
var hotbar_slots: Array[InventorySlotData] = []
var inventory_slots: Array[InventorySlotData] = []
var item_totals: Dictionary = {}

# GameItem database - you can add more items here
var item_database: Dictionary = {}

func _ready():
	# Initialize slots
	for i in 8:  # 8 hotbar slots
		hotbar_slots.append(InventorySlotData.new())
	
	for i in 16:  # 16 inventory slots
		inventory_slots.append(InventorySlotData.new())
	
	# Initialize item database with gold coin	
	var gold_coin_item = GoldCoinItem.new()
	gold_coin_item.name = "Gold Coin"
	gold_coin_item.icon = load("res://assets/Pirate Treasure/Sprites/Gold Coin/01.png")
	gold_coin_item.stack_size = 10
	gold_coin_item.craftable = false
	gold_coin_item.category = "currency"
	item_database["gold_coin"] = gold_coin_item
	
	# Initialize item database with sword
	var sword_item = SwordItem.new()
	sword_item.name = "Sword"
	sword_item.icon = load("res://assets/Captain Clown Nose/Sprites/Captain Clown Nose/Sword/21-Sword Idle/Sword Idle 01.png")
	sword_item.stack_size = 1
	sword_item.craftable = true
	sword_item.category = "weapon"
	item_database["sword"] = sword_item
	sword_item.craft_requirements = {"Gold Coin": 2}
	print("InventoryManager initialized with ", hotbar_slots.size(), " hotbar slots and ", inventory_slots.size(), " inventory slots")

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


# Add item to inventory (tries hotbar first, then main inventory)
func add_item(item: GameItem, amount: int = 1) -> bool:	
	var remaining = amount
	var original_remaining = remaining
	
	# Try to add to existing stacks in hotbar first
	for slot in hotbar_slots:
		if not slot.is_empty() and slot.item.name == item.name:
			var before_remaining = remaining
			remaining = slot.add_item(item, remaining)
			var added = before_remaining - remaining
			if added > 0:
				add_item_to_total(item.name, added)
			if remaining <= 0:
				hotbar_changed.emit()
				return true
	
	# Try to add to existing stacks in main inventory
	for slot in inventory_slots:
		if not slot.is_empty() and slot.item.name == item.name:
			var before_remaining = remaining
			remaining = slot.add_item(item, remaining)
			var added = before_remaining - remaining
			if added > 0:
				add_item_to_total(item.name, added)
			if remaining <= 0:
				inventory_changed.emit()
				return true
	
	# Try to add to empty slots in hotbar
	for slot in hotbar_slots:
		if slot.is_empty():
			var before_remaining = remaining
			remaining = slot.add_item(item, remaining)
			var added = before_remaining - remaining
			if added > 0:
				add_item_to_total(item.name, added)
			if remaining <= 0:
				hotbar_changed.emit()
				return true
	
	# Try to add to empty slots in main inventory
	for slot in inventory_slots:
		if slot.is_empty():
			var before_remaining = remaining
			remaining = slot.add_item(item, remaining)
			var added = before_remaining - remaining
			if added > 0:
				add_item_to_total(item.name, added)
			if remaining <= 0:
				inventory_changed.emit()
				return true
	
	# If we couldn't add everything, emit signals anyway for partial adds
	if remaining < amount:
		add_item_to_total(item.name, amount - remaining)
		hotbar_changed.emit()
		inventory_changed.emit()
		print("Added ", amount - remaining, " of ", amount, " ", item.name, "(s). ", remaining, " couldn't fit.")
		return true
	
	print("Inventory full! Couldn't add ", item.name)
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

func add_item_to_total(item_name: String, quantity: int):
	if item_name in item_totals:
		item_totals[item_name] += quantity
	else:
		item_totals[item_name] = quantity
	print("Total for ", item_name, " is now: ", item_totals[item_name])

func remove_item_from_total(item_name: String, quantity: int):
	if item_name in item_totals:
		item_totals[item_name] -= quantity
		if item_totals[item_name] <= 0:
			item_totals.erase(item_name)

func get_total_item_count(item_name: String) -> int:
	return item_totals.get(item_name, 0)

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
