extends RigidBody2D
class_name Pickup
@export var quantity: int = 1
@export var idle_animation: String = ""
@export var item_id: String

var _nudge_cooldown: float = 0.0
var _water_check_timer: float = 0.0

func _ready():
	add_to_group("pickups")
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_contact)
	
	item_id = get_scene_file_path().get_file().get_basename()
	
	var pickup_area = $PickupArea as Area2D
	if pickup_area:
		pickup_area.body_entered.connect(_on_player_entered)
	
	if idle_animation != "" and has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play(idle_animation)

func _physics_process(delta):
	if _nudge_cooldown > 0.0:
		_nudge_cooldown -= delta
	if not sleeping:
		_water_check_timer -= delta
		if _water_check_timer <= 0.0:
			_water_check_timer = 0.33  # check ~3 times per second, not 60
			_check_water_tile()

func _check_water_tile():
	var tilemap = get_tree().current_scene.get_node_or_null("TileMap")
	if tilemap:
		var tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
		var tile_data = tilemap.get_cell_tile_data(0, tile_pos)
		if tile_data and tile_data.has_custom_data("is_water") and tile_data.get_custom_data("is_water"):
			gravity_scale = 0.50
			linear_damp = 8.0
		else:
			gravity_scale = 1.0
			linear_damp = 0.0

func _on_body_contact(body):
	if _nudge_cooldown > 0.0:
		return
	if body is TileMap:
		var tile_pos = body.local_to_map(body.to_local(global_position))
		var tile_data = body.get_cell_tile_data(0, tile_pos)
		if tile_data and tile_data.has_custom_data("is_water") and tile_data.get_custom_data("is_water"):
			return
	gravity_scale = 1.0
	linear_damp = 0.0
	sleeping = true

func nudge():
	"""Called externally when the ground underneath may have changed."""
	_nudge_cooldown = 0.3
	sleeping = false
	linear_velocity = Vector2.ZERO

func _on_player_entered(body):
	if body.is_in_group("player"):
		if body.add_loot(item_id, quantity):
			queue_free()
