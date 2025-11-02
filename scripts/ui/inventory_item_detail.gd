extends Control
class_name InventoryItemDetail

var item_icon: TextureRect
var item_name: Label
var item_category: Label
var quantity_label: Label
var stack_size_label: Label
var status_label: Label
var description_text: RichTextLabel

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
	description_text = $MainContainer/DescriptionContainer/DescriptionText

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
		current_stack = object  # Store the stack reference
	
	# Basic info
	$MainContainer/ItemHeader/IconNameContainer/ItemIcon.texture = display_obj.icon
	$MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemName.text = display_obj.name
	$MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemCategory.text = display_obj.category
	
	if is_structure:
		display_structure_stats(display_obj)
		display_craft_requirements(display_obj)
	else:
		display_item_stats(object)
		# Check if item is craftable and show requirements
		if display_obj.craftable and display_obj.craft_requirements.size() > 0:
			display_craft_requirements(display_obj)
		else:
			# For non-craftable items, use the existing _set_item_description method
			_set_item_description(display_obj)
	
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

func display_craft_requirements(item_or_structure):
	var desc_text = ""
	
	# First, show the item's own description (only for GameItems, not structures)
	if item_or_structure is GameItem:
		if item_or_structure.description != "":
			desc_text += item_or_structure.description + "\n\n"
		elif item_or_structure.has_method("get_description"):
			desc_text += item_or_structure.get_description() + "\n\n"
		
		# Add technical details for GameItems
		desc_text += "[b]Technical Details:[/b]\n"
		desc_text += "• Stack Size: " + str(item_or_structure.stack_size) + "\n"
		
		if "damage" in item_or_structure and item_or_structure.damage > 0:
			desc_text += "• Damage: " + str(item_or_structure.damage) + "\n"
		
		if "underwater_compatible" in item_or_structure:
			desc_text += "• Underwater Use: " + ("Yes" if item_or_structure.underwater_compatible else "No") + "\n"
		
		if "land_compatible" in item_or_structure:
			desc_text += "• Land Use: " + ("Yes" if item_or_structure.land_compatible else "No") + "\n"
		
		desc_text += "\n"
	else:
		# For structures (StructureWrapper), show basic info
		if item_or_structure.has_method("get_description"):
			desc_text += item_or_structure.get_description() + "\n\n"
		elif "description" in item_or_structure and item_or_structure.description != "":
			desc_text += item_or_structure.description + "\n\n"
		else:
			desc_text += "A buildable structure.\n\n"
	
	# Add craft requirements (works for both GameItems and structures)
	desc_text += "[b]Required Materials:[/b]\n"
	for material_name in item_or_structure.craft_requirements:
		var required = item_or_structure.craft_requirements[material_name]
		var available = InventoryManager.get_total_item_count(material_name)
		var status_icon = "✓" if available >= required else "✗"
		desc_text += status_icon + " " + str(required) + "x " + material_name + " (" + str(available) + " available)\n"
	
	$MainContainer/DescriptionContainer/DescriptionText.text = desc_text

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

func _set_item_description(item: GameItem):
	var description = ""
	
	# Add the item's own description first
	if item.description != "":
		description += item.description + "\n\n"
	else:
		description += "[i]A " + item.category + " item.[/i]\n\n"
	
	# Add technical details
	description += "[b]Technical Details:[/b]\n"
	description += "• Stack Size: " + str(item.stack_size) + "\n"
	
	if "damage" in item and item.damage > 0:
		description += "• Damage: " + str(item.damage) + "\n"
	
	if "underwater_compatible" in item:
		description += "• Underwater Use: " + ("Yes" if item.underwater_compatible else "No") + "\n"
	
	if "land_compatible" in item:
		description += "• Land Use: " + ("Yes" if item.land_compatible else "No") + "\n"
	
	# Add action information if input handler available
	if input_handler and current_stack:
		description += "\n[b]Available Actions:[/b]\n"
		var actions = input_handler.get_available_actions_for_stack(current_stack)
		for action in actions:
			var action_text = "• " + action.label
			if action.is_primary:
				action_text += " [color=lightblue](Primary)[/color]"
			if action.input_hint != "":
				action_text += " [color=gray](" + action.input_hint + ")[/color]"
			description += action_text + "\n"
	
	description_text.text = description

func _clear_display():
	item_name.text = "No Item Selected"
	item_category.text = ""
	quantity_label.text = ""
	stack_size_label.visible = false
	status_label.visible = false
	description_text.text = "[i]Select an item to view its details.[/i]"
	current_stack = null
	
	# Clear icon
	item_icon.texture = null

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
	$MainContainer/DescriptionContainer/DescriptionText.text = ""
	visible = false

func display_item_stats(object):
	# Implement your item stats display logic here
	pass
