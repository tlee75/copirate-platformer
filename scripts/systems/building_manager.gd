extends Node

signal building_started(structure: GameStructure)
signal building_completed(structure: GameStructure)

func get_buildable_structures() -> Array[GameStructure]:
	var buildable_structures: Array[GameStructure] = []
	for item_key in GameObjectsDatabase.game_objects_database:
		var item = GameObjectsDatabase.game_objects_database[item_key]
		if item is GameStructure and item.craftable:
			buildable_structures.append(item)
	return buildable_structures

func get_buildable_structures_by_category(category: String) -> Array[GameStructure]:
	var buildable_structures: Array[GameStructure] = []
	for item_key in GameObjectsDatabase.game_objects_database:
		var item = GameObjectsDatabase.game_objects_database[item_key]
		if item is GameStructure and item.craftable:
			if category == "all" or item.category == category:
				buildable_structures.append(item)
	return buildable_structures

func has_build_materials(structure: GameStructure) -> bool:
	for material_name in structure.craft_requirements:
		var required_amount = structure.craft_requirements[material_name]
		var available_amount = InventoryManager.get_total_item_count(material_name)
		if available_amount < required_amount:
			return false
	return true

func start_building(structure: GameStructure) -> bool:
	if not has_build_materials(structure):
		print("Cannot build ", structure.name, " - insufficient materials")
		return false
	
	# Start placement mode
	if PlacementManager:
		PlacementManager.start_structure_placement(structure)
		building_started.emit(structure)
		return true
	return false

func complete_building(structure: GameStructure) -> bool:
	# Consume materials
	for material_name in structure.craft_requirements:
		var required_amount = structure.craft_requirements[material_name]
		InventoryManager.remove_items_by_name(material_name, required_amount)
	
	building_completed.emit(structure)
	print("Built ", structure.name, " - materials consumed")
	return true
