extends Node

# Singleton inventory manager that handles all inventory logic
# Visual components are handled by UI scenes, this only manages data

signal inventory_changed
signal hotbar_changed
signal weapon_changed
signal equipment_changed


enum SlotType { INVENTORY, HOTBAR, WEAPON, EQUIPMENT }

# Inventory data
var hotbar_slots: Array[InventorySlotData] = []
var inventory_slots: Array[InventorySlotData] = []
var item_totals: Dictionary = {}
var weapon_slots: Array[InventorySlotData] = []
var equipment_slots: Array[InventorySlotData] = []

@onready var slot_container: HBoxContainer = $HBoxContainer

# GameItem database - you can add more items here
var item_database: Dictionary = {}

@export var hotbar_container_path: NodePath
@export var inventory_container_path: NodePath
@export var weaponbar_container_path: NodePath
@export var equipment_container_path: NodePath

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

func _ready():	
	# Initialize item database with gold coin	
	var gold_coin_item = GoldCoinItem.new()
	gold_coin_item.name = "Gold Coin"
	gold_coin_item.icon = load("res://assets/Pirate Treasure/Sprites/Gold Coin/01.png")
	gold_coin_item.stack_size = 10
	gold_coin_item.craftable = false
	gold_coin_item.category = "currency"
	gold_coin_item.underwater_compatible = false
	gold_coin_item.land_compatible = true
	item_database["gold_coin"] = gold_coin_item
	
	# Initialize item database with sword
	var sword_item = SwordItem.new()
	sword_item.name = "Sword"
	sword_item.icon = load("res://assets/Captain Clown Nose/Sprites/Captain Clown Nose/Sword/21-Sword Idle/Sword Idle 01.png")
	sword_item.stack_size = 1
	sword_item.craftable = true
	sword_item.category = "weapon"
	sword_item.underwater_compatible = false
	sword_item.land_compatible = true
	item_database["sword"] = sword_item
	sword_item.craft_requirements = {"Gold Coin": 2}
	
	# Initialize item database with pick Axe
	var pickaxe_item = PickAxeItem.new()
	pickaxe_item.name = "Pick Axe"
	pickaxe_item.icon = load("res://assets/sprite-man/pick_axe_icon_01.png")
	pickaxe_item.stack_size = 1
	pickaxe_item.craftable = true
	pickaxe_item.category = "tool"
	pickaxe_item.underwater_compatible = false
	pickaxe_item.land_compatible = true
	item_database["pickaxe"] = pickaxe_item
	pickaxe_item.craft_requirements = {"Gold Coin": 3}

	# Initialize item database with Wood Axe
	var woodaxe_item = WoodAxeItem.new()
	woodaxe_item.name = "Wood Axe"
	woodaxe_item.icon = load("res://assets/sprite-man/wood_axe_icon_01.png")
	woodaxe_item.stack_size = 1
	woodaxe_item.craftable = true
	woodaxe_item.category = "tool"
	woodaxe_item.underwater_compatible = false
	woodaxe_item.land_compatible = true
	item_database["woodaxe"] = woodaxe_item
	woodaxe_item.craft_requirements = {"Gold Coin": 3}

	# Initialize item database with Wood Axe
	var shovel_item = ShovelItem.new()
	shovel_item.name = "Shovel"
	shovel_item.icon = load("res://assets/sprite-man/shovel_icon_01.png")
	shovel_item.stack_size = 1
	shovel_item.craftable = true
	shovel_item.category = "tool"
	shovel_item.underwater_compatible = false
	shovel_item.land_compatible = true
	item_database["shovel"] = shovel_item
	shovel_item.craft_requirements = {"Gold Coin": 2}

	# Initialize item database with Berry
	var raspberry_item = RaspberryItem.new()
	raspberry_item.name = "Raspberry"
	raspberry_item.icon = load("res://assets/tropical/raspberry_icon_01.png")
	raspberry_item.stack_size = 99
	raspberry_item.craftable = true
	raspberry_item.category = "consumable"
	raspberry_item.underwater_compatible = false
	raspberry_item.land_compatible = false
	raspberry_item.craft_requirements = {"Gold Coin": 1}
	item_database["raspberry"] = raspberry_item

	print("InventoryManager initialized with ", hotbar_slots.size(), " hotbar slots and ", inventory_slots.size(), " inventory slots")

func initialize_hotbar_slots(count: int):
	hotbar_slots.clear()
	for i in count:
		hotbar_slots.append(InventorySlotData.new())

func initialize_inventory_slots(count: int):
	inventory_slots.clear()
	for i in count:
		inventory_slots.append(InventorySlotData.new())

func initialize_weaponbar_slots(count: int):
	weapon_slots.clear()
	for i in count:
		weapon_slots.append(InventorySlotData.new())

func initialize_equipment_slots(count: int):
	equipment_slots.clear()
	for i in count:
		equipment_slots.append(InventorySlotData.new())

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

func move_item_extended(from_type: SlotType, from_index: int, to_type: SlotType, to_index: int) -> bool:
	var from_slot = get_slot_by_type(from_type, from_index)
	var to_slot = get_slot_by_type(to_type, to_index)
	if not from_slot or not to_slot:
		return false
	
	# Swap items
	var temp_item = from_slot.item
	var temp_quantity = from_slot.quantity
	from_slot.item = to_slot.item
	from_slot.quantity = to_slot.quantity
	to_slot.item = temp_item
	to_slot.quantity = temp_quantity
	# Emit signals
	if from_type == SlotType.HOTBAR or to_type == SlotType.HOTBAR:
		hotbar_changed.emit()
	if from_type == SlotType.INVENTORY or to_type == SlotType.INVENTORY:
		inventory_changed.emit()
	if from_type == SlotType.WEAPON or to_type == SlotType.WEAPON:
		weapon_changed.emit()
	if from_type == SlotType.EQUIPMENT or to_type == SlotType.EQUIPMENT:
		equipment_changed.emit()
	return true

func get_slot_by_type(slot_type: SlotType, index: int) -> InventorySlotData:
	match slot_type:
		SlotType.HOTBAR:
			return get_hotbar_slot(index)
		SlotType.INVENTORY:
			return get_inventory_slot(index)
		SlotType.WEAPON:
			return get_weaponbar_slot(index)
		SlotType.EQUIPMENT:
			return get_equipment_slot(index)
	return null

# Get slot data for UI
func get_hotbar_slot(index: int) -> InventorySlotData:
	if index >= 0 and index < hotbar_slots.size():
		return hotbar_slots[index]
	return null

func get_inventory_slot(index: int) -> InventorySlotData:
	if index >= 0 and index < inventory_slots.size():
		return inventory_slots[index]
	return null

func get_weaponbar_slot(index: int) -> InventorySlotData:
	if index >= 0 and index < weapon_slots.size():
		return weapon_slots[index]
	return null

func get_equipment_slot(index: int) -> InventorySlotData:
	if index >= 0 and index < equipment_slots.size():
		return equipment_slots[index]
	return null

func add_item_to_total(item_name: String, quantity: int):
	if item_name in item_totals:
		item_totals[item_name] += quantity
	else:
		item_totals[item_name] = quantity

func remove_item_from_total(item_name: String, quantity: int):
	if item_name in item_totals:
		item_totals[item_name] -= quantity
		if item_totals[item_name] <= 0:
			item_totals.erase(item_name)

func get_total_item_count(item_name: String) -> int:
	return item_totals.get(item_name, 0)

func remove_items_by_name(item_name: String, quantity: int) -> bool:
	var remaining = quantity
	
	# Remove from hotbarslots first
	for slot in hotbar_slots:
		if not slot.is_empty() and slot.item.name == item_name:
			var removed = slot.remove_item(remaining)
			remaining -= removed
			if remaining <= 0:
				hotbar_changed.emit()
				break
	
	# Remove from inventory slots if still needed
	if remaining > 0:
		for slot in inventory_slots:
			if not slot.is_empty() and slot.item.name == item_name:
				var removed = slot.remove_item(remaining)
				remaining -= removed
				if remaining <= 0:
					inventory_changed.emit()
					break
	
	# Emit signals for UI updates
	if remaining < quantity:
		hotbar_changed.emit()
		inventory_changed.emit()
	
	return remaining == 0 # Return true if all items were removed

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
