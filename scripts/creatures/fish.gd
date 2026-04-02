extends Creature
class_name Fish

# Movement
@export var swim_speed: float = 40.0
@export var flee_speed: float = 120.0
@export var flee_duration: float = 1.5
@export var patrol_change_interval: float = 3.0

# Contact capture
@export var capture_item_key: String = "fish"  # Live fish added to inventory

# Death drop
@export var death_item_key: String = "raw_fish"  # Dropped when killed

# Proximity flee range
@export var flee_proximity_radius: float = 50.0

# Allow contact capture
@export var is_capturable: bool = false

# Patrol state
var patrol_direction: Vector2 = Vector2.RIGHT
var patrol_timer: float = 0.0

# Flee state
var flee_timer: float = 0.0
var flee_direction: Vector2 = Vector2.ZERO

# Reference
var tilemap: TileMap

func _ready():
	super._ready()
	max_health = 2.0
	health = max_health
	category = "fauna"
	
	# Targetable by sword and melee (for killing), and by interact (for contact capture)
	loot_table = {
		"slice": [],
		"melee": [],
		"interact": []
	}
	
	# Randomize initial direction
	patrol_direction = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
	patrol_timer = randf() * patrol_change_interval
	
	# Get tilemap reference
	await get_tree().process_frame
	tilemap = get_tree().current_scene.get_node_or_null("TileMap")
	
	# Connect capture area
	var capture_area = get_node_or_null("CaptureArea")
	if capture_area:
		capture_area.body_entered.connect(_on_capture_body_entered)

func _update_ai(delta: float):
	if state != State.FLEE and state != State.DEAD:
		_check_player_proximity()
	match state:
		State.PATROL:
			_patrol(delta)
		State.FLEE:
			_flee(delta)

func _check_player_proximity():
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) < flee_proximity_radius:
		state = State.FLEE
		flee_timer = flee_duration
		flee_direction = (global_position - player.global_position).normalized()

func _patrol(delta: float):
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		# Change direction randomly
		patrol_direction = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
		patrol_timer = patrol_change_interval + randf() * 2.0
	
	# Check if next position is still water
	var next_pos = global_position + patrol_direction * swim_speed * delta
	if not _is_water_at(next_pos):
		patrol_direction = -patrol_direction
		patrol_timer = patrol_change_interval
	
	global_position += patrol_direction * swim_speed * delta
	
	# Flip sprite to face movement direction
	if animated_sprite:
		animated_sprite.flip_h = patrol_direction.x < 0

func _flee(delta: float):
	flee_timer -= delta
	if flee_timer <= 0.0:
		if player and global_position.distance_to(player.global_position) < flee_proximity_radius:
			flee_timer = flee_duration
			flee_direction = (global_position - player.global_position).normalized()
		else:
			state = State.PATROL
			return
	
	var next_pos = global_position + flee_direction * flee_speed * delta
	if not _is_water_at(next_pos):
		flee_direction = _find_best_flee_direction()
	
	global_position += flee_direction * flee_speed * delta
	
	if animated_sprite:
		animated_sprite.flip_h = flee_direction.x < 0

func take_damage(amount: float, attacker: Node2D = null):
	if state == State.DEAD:
		return
	health -= amount
	last_attacker = attacker
	if health <= 0:
		die()
	else:
		# Start fleeing away from attacker
		state = State.FLEE
		flee_timer = flee_duration
		if attacker:
			flee_direction = (global_position - attacker.global_position).normalized()
		else:
			flee_direction = -patrol_direction

func _on_death():
	"""When killed by a weapon, give raw_fish to the player."""
	if last_attacker and last_attacker.has_method("add_loot"):
		last_attacker.add_loot(death_item_key, 1)
	queue_free()

func _on_capture_body_entered(body: Node2D):
	"""Contact capture — player touches fish, gets live fish item."""
	if state == State.DEAD or not is_capturable:
		return
	if body.is_in_group("player"):
		if body.add_loot(capture_item_key, 1):
			queue_free()

func _find_best_flee_direction() -> Vector2:
	var away_from_player := Vector2.ZERO
	if player:
		away_from_player = (global_position - player.global_position).normalized()
	
	var best_dir := flee_direction
	var best_score := -INF
	for i in range(8):
		var angle := i * (PI / 4.0)
		var candidate := Vector2(cos(angle), sin(angle))
		if not _is_water_at(global_position + candidate * 20.0):
			continue
		var score := candidate.dot(away_from_player)
		if score > best_score:
			best_score = score
			best_dir = candidate
	
	return best_dir

func _is_water_at(pos: Vector2) -> bool:
	if not tilemap:
		return true  # Assume water if no tilemap
	var tile_pos = tilemap.local_to_map(tilemap.to_local(pos))
	var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
	if tile_data and tile_data.has_custom_data("is_water") and tile_data.get_custom_data("is_water"):
		return true
	return false

func get_hover_color() -> Color:
	return Color(1.0, 1.3, 1.0, 1.0)  # Slight green for fauna

func get_hover_scale_multiplier() -> float:
	return 1.08
