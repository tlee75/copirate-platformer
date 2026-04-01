extends Node

var game_objects_database: Dictionary = {}
var pickup_scenes: Dictionary = {}

func _ready():
	_register_items_from_dir("res://scripts/items")
	_register_structures_from_dir("res://scripts/structures")
	_register_pickup_scenes("res://scenes/items")
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
			game_objects_database[key] = structure_instance
	for subdir in dir.get_directories():
		_register_items_from_dir(path + "/" + subdir)

func _register_pickup_scenes(path: String):
	var dir = DirAccess.open(path)
	if dir == null:
		print("Could not open pickup scenes directory: ", path)
		return
	for file in dir.get_files():
		if file.ends_with(".tscn"):
			var key = file.get_basename()
			pickup_scenes[key] = load(path + "/" + file)

func get_pickup_scene(registry_key: String) -> PackedScene:
	return pickup_scenes.get(registry_key, null)
