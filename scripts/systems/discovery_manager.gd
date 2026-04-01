extends Node

signal item_discovered(registry_key: String)
signal item_viewed(registry_key: String)

# Runtime state: tracks which items/structures the player has discovered and viewed
var discovered_items: Dictionary = {}
var viewed_items: Dictionary = {}

func discover(registry_key: String) -> void:
	if registry_key == "":
		return
	if not discovered_items.get(registry_key, false):
		discovered_items[registry_key] = true
		item_discovered.emit(registry_key)
		print("Discovered: ", registry_key)

func mark_viewed(registry_key: String) -> void:
	if registry_key == "":
		return
	if not viewed_items.get(registry_key, false):
		viewed_items[registry_key] = true
		item_viewed.emit(registry_key)
		print("Viewed: ", registry_key)

func is_discovered(registry_key: String) -> bool:
	return discovered_items.get(registry_key, false)

func is_viewed(registry_key: String) -> bool:
	return viewed_items.get(registry_key, false)

func are_prerequisites_met(registry_key: String) -> bool:
	var game_object = GameObjectsDatabase.game_objects_database.get(registry_key, null)
	if not game_object:
		return true
	
	if not "discovery_prerequisites" in game_object:
		return true
	
	var prerequisites = game_object.discovery_prerequisites
	if prerequisites.is_empty():
		return true
	
	for prereq_key in prerequisites:
		if not is_discovered(prereq_key):
			return false
	return true
