extends Control

var current_craft_item = null # Track the currently displayed item
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
	
	# Connect to inventory signals to refresh craft details when inventory changes
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	InventoryManager.hotbar_changed.connect(_on_inventory_changed)

func show_craftable_items(category):
	print("Crafting menu Ready")
	var list_container = $TabBar/CraftTab/HBoxContainer/ScrollContainer/VBoxContainer
	
	# Remove all children immediately
	for child in list_container.get_children():
		list_container.remove_child(child)
		child.queue_free()
	
	var item_db = GameObjectsDatabase.game_objects_database
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
	current_craft_item = item
	craft_details_panel.visible = true
	craft_details_panel.visible = true
	item_image.texture = item.icon if item.icon else null
	item_name_label.text = item.name
	
	# Clear previous requirements
	for child in requirements_list.get_children():
		requirements_list.remove_child(child)
		child.queue_free()
	
	var all_requirements_met = true
	
	# Build requirements list using totals	
	# Assume item has a property "craft_requirements" which is: {resource_name: ammount}
	for resource_name in item.craft_requirements.keys():
		var required = item.craft_requirements[resource_name]
		var owned = InventoryManager.get_total_item_count(resource_name)
		
		#var amount = item.craft_requirements[resource_name]
		var req_label = Label.new()
		req_label.text = "%s x%d (%d)" % [resource_name, required, owned]
		
		# Color red if insufficient resources
		if owned < required:
			req_label.add_theme_color_override("font_color", Color.RED)
			all_requirements_met = false
		else:
			req_label.add_theme_color_override("font_color", Color.GREEN)
		
		requirements_list.add_child(req_label)
	
	# Toggle craft button based on requirements
	craft_button.disabled = not all_requirements_met
	
	# Connect Craft button
	for c in craft_button.pressed.get_connections():
		craft_button.pressed.disconnect(c.callable)
	craft_button.pressed.connect(func(): craft_object(item))
	
func craft_object(item):
	if item.category == "structure":
		craft_structure(item)
		return
	else:
		craft_item(item)
		return
	
func craft_item(item):
	print("Crafting: ", item.name)
	
	# Double-check we have all required resources
	for resource_name in item.craft_requirements.keys():
		var required = item.craft_requirements[resource_name]
		var owned = InventoryManager.get_total_item_count(resource_name)
		if owned < required:
			print("Not enough ", resource_name, " to craft ", item.name)
			return

	# Add the crafted item to inventory first (we already checked if they have enough
	InventoryManager.add_item(item, 1)
	
	# Remove required resources from inventory
	for resource_name in item.craft_requirements.keys():
		var required = item.craft_requirements[resource_name]
		InventoryManager.remove_items_by_name(resource_name, required)

	
	print("Successfully crafted ", item.name)

func craft_structure(item: Dictionary):
	print("Calling PlacementManager for structure: ", item.name)
	self.visible = false
	
	# Update player inventory state
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.inventory_is_open = false
		player.inventory_state_changed.emit(false)
	
	# Start placement preview via PlacementManager
	PlacementManager.start_structure_placement(item)

func _on_inventory_changed():
	# Refresh craft details if something is currently displayed
	if current_craft_item != null and craft_details_panel.visible:
		show_craft_details(current_craft_item)
