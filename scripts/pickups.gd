extends RigidBody2D
class_name Pickup
@export var quantity: int = 1
@export var idle_animation: String = ""
@export var item_id: String

var _nudge_cooldown: float = 0.0

func _ready():
	add_to_group("pickups")
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_landed)
	
	item_id = get_scene_file_path().get_file().get_basename()
	
	var pickup_area = $PickupArea as Area2D
	if pickup_area:
		pickup_area.body_entered.connect(_on_player_entered)
	
	if idle_animation != "" and has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play(idle_animation)

func _physics_process(delta):
	if _nudge_cooldown > 0.0:
		_nudge_cooldown -= delta

func _on_landed(_body):
	if _nudge_cooldown > 0.0:
		return
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
