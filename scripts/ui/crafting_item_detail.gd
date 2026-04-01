extends Control
class_name CraftingItemDetail

var item_icon: TextureRect
var item_name: Label
var item_category: Label
var quantity_label: Label
var stack_size_label: Label
var status_label: Label
var description_text: Label
var materials_section: VBoxContainer
var materials_grid: HFlowContainer
var current_stack: InventoryManager.ItemStack
var input_handler: PlayerInputHandler

func _ready():
	_setup_ui_references()
	_setup_empty_state()

func _setup_ui_references():
	item_icon = $MainContainer/ItemHeader/IconNameContainer/ItemIcon
	item_name = $MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemName
	item_category = $MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemCategory
	quantity_label = $MainContainer/StatsContainer/QuantityLabel
	stack_size_label = $MainContainer/StatsContainer/StackSizeLabel
	status_label = $MainContainer/StatsContainer/StatusLabel
	description_text = $MainContainer/DescriptionContainer/DescriptionScroll/DescriptionText
	materials_section = $MainContainer/DescriptionContainer/MaterialsSection
	materials_grid = $MainContainer/DescriptionContainer/MaterialsSection/MaterialsScrollContainer/MaterialsGrid

func _setup_empty_state():
	_clear_display()

func set_input_handler(handler: PlayerInputHandler):
	input_handler = handler

func display_item(stack: InventoryManager.ItemStack):
	if not stack or not stack.item:
		clear_display()
		return
	
	display_item_or_structure(stack, false)

func display_structure(structure):
	# Use the existing display_item method but adapt for structures
	# Create a temporary wrapper to make structure compatible
	var temp_wrapper = StructureWrapper.new(structure)
	display_item_or_structure(temp_wrapper, true)

func display_item_or_structure(object, is_structure: bool = false):
	clear_display()
	
	var display_obj = object
	if object is InventoryManager.ItemStack:
		display_obj = object.item
		current_stack = object
	
	# Basic info
	$MainContainer/ItemHeader/IconNameContainer/ItemIcon.texture = display_obj.icon
	$MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemName.text = display_obj.name
	$MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemCategory.text = display_obj.category
	
	if is_structure:
		display_structure_stats(display_obj)
	else:
		display_item_stats(object)
	
	# Description goes in the top RichTextLabel
	_set_description_text(display_obj, is_structure)
	
	# Materials go in the bottom icon grid
	if display_obj.craft_requirements.size() > 0:
		_display_material_icons(display_obj)
		materials_section.visible = true
	else:
		materials_section.visible = false
	
	visible = true

func display_structure_stats(structure):
	# If structure is a wrapper, get the real structure
	var real_structure = structure
	if structure is StructureWrapper:
		real_structure = structure.structure

	var can_build = BuildingManager.has_build_materials(real_structure) if BuildingManager else false
	var status_text = "Ready to Build" if can_build else "Missing Materials"
	$MainContainer/StatsContainer/StatusLabel.text = status_text
	$MainContainer/StatsContainer/StatusLabel.visible = true

func _set_description_text(display_obj, is_structure: bool):
	if is_structure:
		if "description" in display_obj and display_obj.description != "":
			description_text.text = display_obj.description
		elif display_obj.has_method("get_description"):
			description_text.text = display_obj.get_description()
		else:
			description_text.text = "A buildable structure."
	elif display_obj is GameItem:
		if display_obj.description != "":
			description_text.text = display_obj.description
		elif display_obj.has_method("get_description"):
			description_text.text = display_obj.get_description()
		else:
			description_text.text = "A " + display_obj.category + " item."

func _display_material_icons(item_or_structure):
	# Clear previous material cards
	for child in materials_grid.get_children():
		child.queue_free()
	
	for material_name in item_or_structure.craft_requirements:
		var required = item_or_structure.craft_requirements[material_name]
		var available = InventoryManager.get_total_item_count(material_name)
		var has_enough = available >= required
		
		# Build a material card
		var card = VBoxContainer.new()
		card.custom_minimum_size = Vector2(64, 88)
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Icon with green/red modulate
		var icon_container = CenterContainer.new()
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(32, 32)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Look up the item icon from the pre-built dictionary
		var material_item = GameObjectsDatabase.get_item_by_name(material_name)
		if material_item and material_item.icon:
			icon_rect.texture = material_item.icon
		
		icon_container.add_child(icon_rect)
		card.add_child(icon_container)
		
		# Material name label
		var name_label = Label.new()
		name_label.text = material_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 10)
		card.add_child(name_label)
		
		# Count label: "needed / available"
		var count_label = Label.new()
		count_label.text = str(required) + " / " + str(available)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 10)
		if not has_enough:
			count_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			count_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		card.add_child(count_label)
		
		materials_grid.add_child(card)

# Helper wrapper class to make structures compatible with existing display logic
class StructureWrapper:
	var structure
	
	func _init(s):
		structure = s
	
	var icon:
		get: return structure.icon
	var name:
		get: return structure.name  
	var description:
		get: return structure.description
	var category:
		get: return structure.category
	var craft_requirements:
		get: return structure.craft_requirements

func _clear_display():
	item_name.text = "No Item Selected"
	item_category.text = ""
	quantity_label.text = ""
	stack_size_label.visible = false
	status_label.visible = false
	description_text.text = "Select an item to view its details."
	current_stack = null
	
	# Clear icon
	item_icon.texture = null
	
	# Clear material cards
	if materials_grid:
		for child in materials_grid.get_children():
			child.queue_free()
	if materials_section:
		materials_section.visible = false

func refresh_display():
	if current_stack:
		display_item(current_stack)
	else:
		_clear_display()

func clear_display():
	# Reset all UI fields to blank/default
	$MainContainer/ItemHeader/IconNameContainer/ItemIcon.texture = null
	$MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemName.text = ""
	$MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemCategory.text = ""
	$MainContainer/StatsContainer/QuantityLabel.text = ""
	$MainContainer/StatsContainer/StackSizeLabel.text = ""
	$MainContainer/StatsContainer/StatusLabel.text = ""
	description_text.text = ""

	# Clear material cards
	if materials_grid:
		for child in materials_grid.get_children():
			child.queue_free()
	if materials_section:
		materials_section.visible = false
	visible = false

func display_item_stats(object):
	# Implement your item stats display logic here
	pass
