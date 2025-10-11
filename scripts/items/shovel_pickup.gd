extends Area2D

func _ready():
	$AnimatedSprite2D.play("idle")

	# Connect area entered signal for collection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# If player touches item, add to inventory
	if body.is_in_group("player"):
		if body.add_loot("shovel", 1):
			print("item added to inventory!")
			queue_free()
		else:
			print("Inventory full! Cannot pick up item.")
