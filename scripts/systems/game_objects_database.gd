extends Node

var game_objects_database: Dictionary = {}

func _ready():
	_register_items_from_dir("res://scripts/items")
	_register_structures()
	print("Registered game objects: ", game_objects_database.keys())

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
			game_objects_database[key] = item_instance
	for subdir in dir.get_directories():
		_register_items_from_dir(path + "/" + subdir)

func _register_structures():
	game_objects_database["firepit"] = {
		name = "Firepit",
		category = "structure",
		craftable = true,
		icon = load("res://assets/structures/firepit_unlit_01.png"),
		craft_requirements = {"Simple Rock": 1},
		scene_path = "res://scenes/structures/firepit.tscn",
		placement_bottom_padding = -5.0  # Pixels to adjust bottom alignment
	}
	# Add more structures as needed with their own padding values
