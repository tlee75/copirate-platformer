extends Node

signal item_crafted(item: GameItem, quantity: int)
signal craft_failed(item: GameItem, reason: String)

func can_craft_item(item: GameItem) -> bool:
	if not item.craftable:
		return false
	
	# Check if player has required materials
	for material_key in item.material_requirements:
		var required = item.material_requirements[material_key]
		var available = InventoryManager.get_total_item_count_by_key(material_key)
		if available < required:
			return false
	return true

func craft_item(item: GameItem) -> bool:
	if not can_craft_item(item):
		craft_failed.emit(item, "Insufficient materials")
		return false
	
	# Consume materials
	for material_key in item.material_requirements:
		var required = item.material_requirements[material_key]
		InventoryManager.remove_items_by_key(material_key, required)
	
	# Add crafted item to inventory
	InventoryManager.add_item(item, 1)
	item_crafted.emit(item, 1)
	print("Crafted: ", item.name)
	return true
