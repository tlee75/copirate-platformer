extends Control

func _ready():
	$TabBar/CraftTab/HBoxContainer/VBoxContainer/ToolsButton.pressed.connect(func(): show_craftable_items("tool"))
	$TabBar/CraftTab/HBoxContainer/VBoxContainer/WeaponsButton.pressed.connect(func(): show_craftable_items("weapon"))
	$TabBar/CraftTab/HBoxContainer/VBoxContainer/StructuresButton.pressed.connect(func(): show_craftable_items("structure"))
	$TabBar/CraftTab/HBoxContainer/VBoxContainer/ConsumablesButton.pressed.connect(func(): show_craftable_items("consumable"))
	show_craftable_items("tool")

func show_craftable_items(category):
	print("Crafting menu Ready")
	var list_container = $TabBar/CraftTab/HBoxContainer/ScrollContainer/VBoxContainer
	
	# Remove all children immediately
	for child in list_container.get_children():
		list_container.remove_child(child)
		child.queue_free()
	
	var item_db = InventoryManager.item_database
	for key in item_db.keys():
		print(key)
		var item = item_db[key]
		print("Item: ", item.name, " craftable: ", item.craftable, " category: ", item.category)
		if item.craftable and item.category == category:
			print("Adding: ", item.name)
			var btn = Button.new()
			btn.text = item.name
			if item.icon:
				btn.icon = item.icon
			list_container.add_child(btn)
			print("Button added successfully")
