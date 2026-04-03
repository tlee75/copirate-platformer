extends Node

# LootDropper: Autoload for spawning loot item pickups into the world.
# Loot table format: { "action_type": [{ "item": PackedScene, "type": "drop", "chance": 1.0, "min": 1, "max": 4 }, ...] }

func drop_loot(action_table: Dictionary, origin: Node2D, target_action: String = "") -> void:
	var action_keys: Array = []
	if target_action != "" and action_table.has(target_action):
		action_keys = [target_action]
	else:
		action_keys = action_table.keys()
	
	for action_key in action_keys:
		var entries = action_table[action_key]
		for entry in entries:
			if entry.get("type") != "drop":
				continue
			var item_scene: PackedScene = entry["item"]
			var drop_chance: float = entry.get("chance", 1.0)
			var min_qty: int = entry.get("min", 1)
			var max_qty: int = entry.get("max", 1)
			if randf() <= drop_chance:
				var quantity = randi_range(min_qty, max_qty)
				for i in quantity:
					_spawn_item(item_scene, i, origin)

func _spawn_item(item_scene: PackedScene, offset_index: int, origin: Node2D) -> void:
	if not item_scene:
		print("LootDropper: PackedScene is null, cannot spawn loot")
		return
	var instance = item_scene.instantiate()
	instance.global_position = _find_spawn_position(origin.global_position, offset_index, origin)
	origin.get_parent().add_child(instance)

func _find_spawn_position(base_pos: Vector2, offset_index: int, origin: Node2D, spread: float = 8.0, avoid_pos: Vector2 = Vector2.INF, min_distance: float = 0.0) -> Vector2:
	for _attempt in range(20):
		var offset = Vector2(randf_range(-spread, spread) + (offset_index * 4), randf_range(-spread, spread))
		var test_pos = base_pos + offset
		if _is_position_clear(test_pos, origin):
			if avoid_pos != Vector2.INF and test_pos.distance_to(avoid_pos) < min_distance:
				continue
			return test_pos
	print("LootDropper: No clear spawn position found, using origin")
	return base_pos

func _is_position_clear(pos: Vector2, origin: Node2D) -> bool:
	var space_state = origin.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for collision in space_state.intersect_point(query):
		var collider = collision.collider
		if collider is TileMap or (collider is StaticBody2D and collider != origin):
			return false
	return true

func drop_single_item(item: GameItem, quantity: int = 1) -> bool:
	var item_scene = GameObjectsDatabase.get_pickup_scene(item.registry_key)
	if not item_scene:
		print("LootDropper: No pickup scene registered for '", item.registry_key, "'")
		return false
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("LootDropper: No player found to determine drop position")
		return false
	
	var instance = item_scene.instantiate()
	instance.global_position = _find_spawn_position(player.global_position + Vector2(0, 4), 0, player, 60.0, player.global_position, 40.0)
	if instance is Pickup:
		instance.quantity = quantity
	player.get_parent().add_child(instance)
	return true
	
