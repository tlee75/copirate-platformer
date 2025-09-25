extends Area2D

func _ready():
	$AnimatedSprite2D.play("idle")

	# Connect area entered signal for collection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# If player touches item, add to inventory
	if body is Player:
		var shovel_item = InventoryManager.item_database["shovel"]
		if InventoryManager.add_item(shovel_item, 1):
			print("Shovel added to inventory!")
			queue_free()
		else:
			print("Inventory full! Cannot pick up shovel.")
