extends Control

@onready var craft_details_panel = $TabBar/CraftTab/HBoxContainer/CraftDetailsPanel
@onready var item_image = craft_details_panel.get_node("VBoxContainer/ItemImage")
@onready var item_name_label = craft_details_panel.get_node("VBoxContainer/ItemNameLabel")
@onready var requirements_list = craft_details_panel.get_node("VBoxContainer/RequirementsList")
@onready var craft_button = craft_details_panel.get_node("VBoxContainer/CraftButton")

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
		var item = item_db[key]
		if item.craftable and item.category == category:
			var btn = Button.new()
			btn.text = item.name
			if item.icon:
				btn.icon = item.icon
			btn.pressed.connect(func():
				show_craft_details(item)
			)
			list_container.add_child(btn)

func show_craft_details(item):
	pass
	craft_details_panel.visible = true
	item_image.texture = item.icon if item.icon else null
	item_name_label.text = item.name
	
	# Clear previous requirements
	for child in requirements_list.get_children():
		requirements_list.remove_child(child)
		child.queue_free()
	
	# Assume item has a property "craft_requirements" which is a directory: {resource_name: ammount}
	for resource_name in item.craft_requirements.keys():
		var amount = item.craft_requirements[resource_name]
		var req_label = Label.new()
		req_label.text = "%s x%d" % [resource_name, amount]
		requirements_list.add_child(req_label)
	
	# Connect Craft button
	for c in craft_button.pressed.get_connections():
		craft_button.pressed.disconnect(c.callable)
	craft_button.pressed.connect(func(): craft_item(item))
	
func craft_item(item):
	# TODO: Implement crafting logic (check resources, remove, add crafted item, etc)
	print("Crafting: ", item.name)
