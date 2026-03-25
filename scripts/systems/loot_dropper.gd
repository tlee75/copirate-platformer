extends Node

# LootDropper: Autoload for spawning loot item pickups into the world.
# Loot table entry format: [PackedScene, drop_chance (0.0-1.0), min_qty, max_qty]

func drop_loot(loot_table: Array, origin: Node2D) -> void:
	for entry in loot_table:
		var item_scene: PackedScene = entry[0]
		var drop_chance: float = entry[1]
		var min_qty: int = entry[2]
		var max_qty: int = entry[3]
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

func _find_spawn_position(base_pos: Vector2, offset_index: int, origin: Node2D) -> Vector2:
	for _attempt in range(20):
		var offset = Vector2(randf_range(-8, 8) + (offset_index * 4), randf_range(-8, 8))
		var test_pos = base_pos + offset
		if _is_position_clear(test_pos, origin):
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
