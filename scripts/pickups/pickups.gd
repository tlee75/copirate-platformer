extends RigidBody2D
class_name Pickup
@export var quantity: int = 1
@export var idle_animation: String = ""
@export var item_id: String # Must match the script name in scripts/items/**

func _ready():
	# Freeze after landing to stop physics processing
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_landed)
	
	# wood_axe.tscn -> wood_axe
	item_id = get_scene_file_path().get_file().get_basename()
	
	# Setup pickup detection area
	var pickup_area = $PickupArea as Area2D
	if pickup_area:
		pickup_area.body_entered.connect(_on_player_entered)
	
	if idle_animation != "" and has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play(idle_animation)

func _on_landed(_body):
	# Once it hits terrain, freeze in place
	set_deferred("freeze", true)

func _on_player_entered(body):
	if body.is_in_group("player"):
		if body.add_loot(item_id, quantity):
			queue_free()
