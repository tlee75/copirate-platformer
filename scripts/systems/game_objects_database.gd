extends Node

var game_objects_database: Dictionary = {}
var pickup_scenes: Dictionary = {}
var structure_scenes: Dictionary = {}  # registry_key -> full res:// path

func _ready():
	_register_items_from_dir("res://scripts/items")
	_register_structure_scene_paths("res://scenes/structures")
	_register_structures_from_dir("res://scripts/structures")
	_register_pickup_scenes("res://scenes/items")
	_validate_registrations()
	DiscoveryManager.build_dependency_map()
	print("Registered game objects: ", game_objects_database.keys())
	print("Registered pickup scenes: ", pickup_scenes.keys())

func _register_items_from_dir(path: String):
	var dir = DirAccess.open(path)
	if dir == null:
		print("Could not open directory: ", path)
		return
	for file in dir.get_files():
		if file.ends_with(".gd"):
			var item_script = load(path + "/" + file)
			var item_instance = item_script.new()
			var key = file.get_basename()
			if item_instance.name == "" or item_instance.name == item_instance.get_class():
				item_instance.name = key.capitalize()
			item_instance.registry_key = key
			game_objects_database[key] = item_instance
	for subdir in dir.get_directories():
		_register_items_from_dir(path + "/" + subdir)

func _register_structures_from_dir(path: String):
	var dir = DirAccess.open(path)
	if dir == null:
		print("Could not open directory: ", path)
		return
	for file in dir.get_files():
		if file.ends_with(".gd"):
			var structure_script = load(path + "/" + file)
			var structure_instance = structure_script.new()
			var key = file.get_basename()
			structure_instance.registry_key = key
			structure_instance.scene_path = structure_scenes.get(key, "")
			game_objects_database[key] = structure_instance
	for subdir in dir.get_directories():
		_register_structures_from_dir(path + "/" + subdir)

func _register_structure_scene_paths(path: String):
	var dir = DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		if file.ends_with(".tscn"):
			var full_path = path + "/" + file
			var key = full_path.get_file().get_basename()
			structure_scenes[key] = full_path
	for subdir in dir.get_directories():
		_register_structure_scene_paths(path + "/" + subdir)

func _register_pickup_scenes(path: String):
	var dir = DirAccess.open(path)
	if dir == null:
		print("Could not open pickup scenes directory: ", path)
		return
	for file in dir.get_files():
		if file.ends_with(".tscn"):
			var full_path = path + "/" + file
			var key = full_path.get_file().get_basename()
			pickup_scenes[key] = load(full_path)

func get_pickup_scene(registry_key: String) -> PackedScene:
	return pickup_scenes.get(registry_key, null)

func _validate_registrations():
	for key in game_objects_database:
		var obj = game_objects_database[key]
		
		if obj is GameItem:
			# Check pickup scene exists for craftable/droppable items
			# (skip non-droppable items like hands, melee if intentional)
			if not pickup_scenes.has(key) and obj.get("droppable") != false:
				push_warning("GameObjectsDatabase: No pickup scene for item '%s' (key='%s')" % [obj.name, key])
			
			# Check material_requirements reference valid item names
			for material_key in obj.material_requirements:
				if not game_objects_database.has(material_key):
					push_warning("GameObjectsDatabase: Item '%s' requires material key '%s' but no item with that registry key exists" % [obj.name, material_key])

		elif obj is GameObject:
			if obj.get("scene_path") == "":
				push_warning("GameObjectsDatabase: Structure '%s' has no scene file in scenes/structures/" % obj.name)

			# Check material_requirements reference valid item names
			for material_key in obj.material_requirements:
				if not game_objects_database.has(material_key):
					push_warning("GameObjectsDatabase: Structure '%s' requires material key '%s' but no item with that registry key exists" % [obj.name, material_key])
	
	# Check for orphan pickup scenes (scene with no matching item script)
	for pickup_key in pickup_scenes:
		if not game_objects_database.has(pickup_key):
			push_warning("GameObjectsDatabase: Pickup scene '%s.tscn' has no matching item script" % pickup_key)
