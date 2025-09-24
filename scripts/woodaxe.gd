extends Area2D

func _ready():
	$AnimatedSprite2D.play("woodaxe_idle")

	# Connect area entered signal for collection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# If player touches coin, add to inventory
	if body is Player:
		var woodaxe_item = InventoryManager.item_database["woodaxe"]
		if InventoryManager.add_item(woodaxe_item, 1):
			print("Wood Axe added to inventory!")
			queue_free()
		else:
			print("Inventory full! Cannot pick up pickaxe.")
