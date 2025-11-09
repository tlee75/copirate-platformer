extends Node

signal item_crafted(item: GameItem, quantity: int)
signal craft_failed(item: GameItem, reason: String)

func can_craft_item(item: GameItem) -> bool:
	if not item.craftable:
		return false
	
	# Check if player has required materials
	for material_name in item.craft_requirements:
		var required = item.craft_requirements[material_name]
		var available = InventoryManager.get_total_item_count(material_name)
		if available < required:
			return false
	return true

func craft_item(item: GameItem) -> bool:
	if not can_craft_item(item):
		craft_failed.emit(item, "Insufficient materials")
		return false
	
	# Consume materials
	for material_name in item.craft_requirements:
		var required = item.craft_requirements[material_name]
		InventoryManager.remove_items_by_name(material_name, required)
	
	# Add crafted item to inventory
	InventoryManager.add_item(item, 1)
	item_crafted.emit(item, 1)
	print("Crafted: ", item.name)
	return true
