extends Area2D

func _ready():
	$AnimatedSprite2D.play("spin")

	# Connect area entered signal for collection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# If player touches coin, add to inventory
	if body is Player:
		var gold_coin_item = InventoryManager.item_database["gold_coin"]
		if InventoryManager.add_item(gold_coin_item, 1):
			print("Gold coin added to inventory!")
			queue_free()
		else:
			print("Inventory full! Cannot pick up gold coin.")
