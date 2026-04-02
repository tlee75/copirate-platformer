extends Node

signal item_discovered(registry_key: String)
signal item_viewed(registry_key: String)
signal blueprint_unlocked(registry_key: String)

# Runtime state: tracks which items/structures the player has discovered and viewed
var discovered_items: Dictionary = {}
var viewed_items: Dictionary = {}
var _reverse_deps: Dictionary = {} # material_key -> Array of registry_keys that need it
var unlocked_blueprints: Dictionary = {} # registry_key -> true for already-unlocked blueprints

func discover(registry_key: String) -> void:
	if registry_key == "":
		return
	if not discovered_items.get(registry_key, false):
		discovered_items[registry_key] = true
		item_discovered.emit(registry_key)
		print("Discovered: ", registry_key)
		_check_newly_unlocked(registry_key)

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
	if not "material_requirements" in game_object:
		return true
	var requirements = game_object.material_requirements
	if requirements.is_empty():
		return true
	for material_key in requirements:
		if not is_discovered(material_key):
			return false
	return true

func build_dependency_map():
	_reverse_deps.clear()
	for key in GameObjectsDatabase.game_objects_database:
		var obj = GameObjectsDatabase.game_objects_database[key]
		if "material_requirements" in obj:
			for material_key in obj.material_requirements:
				if not _reverse_deps.has(material_key):
					_reverse_deps[material_key] = []
				_reverse_deps[material_key].append(key)
	print("DiscoveryManager: Built reverse deps for ", _reverse_deps.size(), " materials")
	
func _check_newly_unlocked(discovered_key: String):
	var dependents = _reverse_deps.get(discovered_key, [])
	for candidate_key in dependents:
		if unlocked_blueprints.get(candidate_key, false):
			continue  # already unlocked previously
		if are_prerequisites_met(candidate_key):
			unlocked_blueprints[candidate_key] = true
			var obj = GameObjectsDatabase.game_objects_database.get(candidate_key)
			var obj_name = obj.name if obj else candidate_key
			blueprint_unlocked.emit(candidate_key)
			print("Blueprint unlocked: ", obj_name)
			NotificationManager.notify(NotificationManager.NotificationType.BLUEPRINT_DISCOVERED, "unlocked_" + obj_name, "Unlocked " + obj_name)
			
