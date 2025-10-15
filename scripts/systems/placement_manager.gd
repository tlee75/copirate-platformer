extends Node

@export	var GROUND_TILE_ID = 3	

var preview_instance: Node2D = null
var preview_structure_data: Node = null
var placement_active: bool = false


func start_structure_placement(object):
	var structure_scene = load(object.scene_path)
	preview_instance = structure_scene.instantiate()
	preview_instance.modulate = Color(1, 1, 1, 0.5)
	get_tree().current_scene.add_child(preview_instance)
	preview_structure_data = object
	placement_active = true

	# Use global mouse position (world coordinates)
	preview_instance.position = get_tree().current_scene.get_global_mouse_position()


func get_snapped_position(mouse_pos: Vector2) -> Vector2:
	var tilemap = get_tree().current_scene.get_node("TileMap")
	var cell = tilemap.local_to_map(mouse_pos)
	var tile_pos = tilemap.map_to_local(cell)
	var tile_size = tilemap.tile_set.tile_size
	
	# Get placement padding from item data (default to 0 if not specified)
	var placement_padding = preview_structure_data.get("placement_bottom_padding")
	
	# Get sprite height
	var sprite_height = tile_size.y  # fallback
	if preview_instance and preview_instance.has_node("AnimatedSprite2D"):
		var sprite = preview_instance.get_node("AnimatedSprite2D")
		var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if texture:
			sprite_height = texture.get_height() * preview_instance.scale.y
	
	# Calculate bottom of tile (tile center + half tile height)
	var tile_bottom_y = tile_pos.y + (tile_size.y / 2)
	
	# Position sprite so its bottom aligns with tile bottom + padding
	var sprite_y = tile_bottom_y - (sprite_height / 2) - placement_padding
	
	# Center horizontally on tile
	var final_pos = Vector2(tile_pos.x, sprite_y)
	
	return final_pos

func confirm_structure_placement():
	if preview_instance and placement_active:
		for resource_name in preview_structure_data.craft_requirements.keys():
			var required = preview_structure_data.craft_requirements[resource_name]
			InventoryManager.remove_items_by_name(resource_name, required)
		preview_instance.modulate = Color(1, 1, 1, 1) # make fully visible
		preview_instance = null
		preview_structure_data = null
		placement_active = false

func cancel_structure_placement():
	if preview_instance and placement_active:
		preview_instance.queue_free()
		preview_instance = null
		preview_structure_data = null
		placement_active = false

func _input(event):
	if placement_active and preview_instance:
		if event is InputEventMouseMotion:
			var mouse_pos = get_tree().current_scene.get_global_mouse_position()
			var snapped_pos = get_snapped_position(mouse_pos)
			preview_instance.position = snapped_pos

			# Check placement validity and set tint
			if is_placement_valid(preview_instance):
				preview_instance.modulate = Color(1, 1, 1, 0.5)  # normal preview
			else:
				preview_instance.modulate = Color(1, 0.3, 0.3, 0.7)  # reddish tint

		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_placement_valid(preview_instance):
				confirm_structure_placement()
			else:
				print("Invalid placement: overlaps another object.")
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_structure_placement()

func is_placement_valid(instance) -> bool:
	if not instance.has_node("Area2D"):
		return false
	var area = instance.get_node("Area2D")
	var overlapping = area.get_overlapping_areas() + area.get_overlapping_bodies()
	for obj in overlapping:
		if obj != instance:
			var cat = get_category(obj)
			print("Checking object:", obj, "Category:", cat)
			if cat == "structure" or cat == "terrain":
				return false
			if obj is PhysicsBody2D and not obj.is_in_group("player"):
				return false

	# Ground tile check - there must be ground below the structure
	var tilemap = get_tree().current_scene.get_node("TileMap")
	# Check the tile where the structure center is positioned
	var structure_cell = tilemap.local_to_map(instance.position)
	
	# Check if there's ground in the tile below the structure
	var ground_check_cell = Vector2i(structure_cell.x, structure_cell.y + 1)
	var ground_tile_id = tilemap.get_cell_source_id(0, ground_check_cell)
	
	if ground_tile_id != GROUND_TILE_ID:
		return false
	return true

func get_category(obj):
	if "category" in obj:
		return obj.category
	elif obj.get_parent() and "category" in obj.get_parent():
		return obj.get_parent().category
	return null
