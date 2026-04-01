extends Node

signal building_started(structure: GameObject)
signal building_completed(structure: GameObject)

func get_buildable_structures() -> Array[GameObject]:
	var buildable_structures: Array[GameObject] = []
	for item_key in GameObjectsDatabase.game_objects_database:
		var item = GameObjectsDatabase.game_objects_database[item_key]
		if item is GameObject and item.craftable:
			if DiscoveryManager.are_prerequisites_met(item_key):
				buildable_structures.append(item)
	return buildable_structures

func get_buildable_structures_by_category(category: String) -> Array[GameObject]:
	var buildable_structures: Array[GameObject] = []
	for item_key in GameObjectsDatabase.game_objects_database:
		var item = GameObjectsDatabase.game_objects_database[item_key]
		if item is GameObject and item.craftable:
			if category == "all" or item.category == category:
				if DiscoveryManager.are_prerequisites_met(item_key):
					buildable_structures.append(item)
	return buildable_structures

func has_build_materials(structure: GameObject) -> bool:
	for material_key in structure.material_requirements:
		var required_amount = structure.material_requirements[material_key]
		var available_amount = InventoryManager.get_total_item_count_by_key(material_key)
		if available_amount < required_amount:
			return false
	return true

func start_building(structure: GameObject) -> bool:
	if not has_build_materials(structure):
		print("Cannot build ", structure.name, " - insufficient materials")
		return false
	
	# Start placement mode
	if PlacementManager:
		PlacementManager.start_structure_placement(structure)
		building_started.emit(structure)
		return true
	return false

func complete_building(structure: GameObject) -> bool:
	# Consume materials
	for material_key in structure.material_requirements:
		var required_amount = structure.material_requirements[material_key]
		InventoryManager.remove_items_by_key(material_key, required_amount)
	
	building_completed.emit(structure)
	print("Built ", structure.name, " - materials consumed")
	return true
