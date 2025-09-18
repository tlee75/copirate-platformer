extends Area2D

func _ready():
	$AnimatedSprite2D.play("sword_idle")

	# Connect area entered signal for collection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# If player touches coin, add to inventory
	if body is Player:
		if InventoryManager.add_item("sword", 1):
			print("Sword added to inventory!")
			queue_free()
		else:
			print("Inventory full! Cannot pick up sword.")
