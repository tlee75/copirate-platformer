class_name Inventory
extends Resource

signal inventory_changed

@export var capacity: int = 10
var slots: Array[InventorySlot] = []

func _init():
	slots.resize(capacity)
	for i in range(capacity):
		slots[i] = InventorySlot.new()

func add_item(item: Item, quantity: int = 1) -> int:
	var remaining_quantity = quantity

	# Try to stack with existing items
	for slot in slots:
		if slot.item == item and item.stackable and slot.quantity < item.max_stack_size:
			var can_add = min(remaining_quantity, item.max_stack_size - slot.quantity)
			slot.quantity += can_add
			remaining_quantity -= can_add
			if remaining_quantity == 0:
				inventory_changed.emit()
				return 0

	# Add to empty slots
	for slot in slots:
		if slot.item == null:
			slot.item = item
			var can_add = min(remaining_quantity, item.max_stack_size)
			slot.quantity = can_add
			remaining_quantity -= can_add
			if remaining_quantity == 0:
				inventory_changed.emit()
				return 0
	inventory_changed.emit()
	return remaining_quantity

func remove_item(item: Item, quantity: int = 1) -> int:
	var remaining_quantity = quantity
	for slot in slots:
		if slot.item == item:
			var can_remove = min(remaining_quantity, slot.quantity)
			slot.quantity -= can_remove
			remaining_quantity -= can_remove
			if slot.quantity == 0:
				slot.item = null
			if remaining_quantity == 0:
				inventory_changed.emit()
				return 0
		inventory_changed.emit()
	return remaining_quantity

func get_item_count(item: Item) -> int:
	var count = 0
	for slot in slots:
		if slot.item == item:
			count += slot.quantity
	return count

func get_slot(index: int) -> InventorySlot:
	if index >= 0 and index < capacity:
		return slots[index]
	return null

func swap_slots(index1: int, index2: int):
	if index1 >= 0 and index1 < capacity and index2 >= 0 and index2 < capacity:
		var temp_item = slots[index1].item
		var temp_quantity = slots[index1].quantity

		slots[index1].item = slots[index2].item
		slots[index1].quantity = slots[index2].quantity

		slots[index2].item = temp_item
		slots[index2].quantity = temp_quantity
		inventory_changed.emit()
