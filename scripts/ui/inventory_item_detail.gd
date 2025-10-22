@tool
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
var input_handler: PlayerMenuInputHandler

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

func set_input_handler(handler: PlayerMenuInputHandler):
	input_handler = handler

func display_item(stack: InventoryManager.ItemStack):
	print("DEBUG: InventoryItemDetail.display_item called for: ", stack.item.name if stack else "null")
	current_stack = stack
	
	if not stack:
		_clear_display()
		return
	
	if not stack or not stack.item:
		_clear_display()
		return
	
	var item = stack.item
	
	# Set item name and category
	item_name.text = item.name
	item_category.text = item.category.capitalize()
	
	# Set item icon (placeholder for now)
	# TODO: item_icon.texture = item.icon when icons are available
	
	# Set quantity and stack info
	quantity_label.text = "Quantity: " + str(stack.quantity)
	if item.stack_size > 1:
		stack_size_label.text = "Stack Size: " + str(stack.quantity) + "/" + str(item.stack_size)
		stack_size_label.visible = true
	else:
		stack_size_label.visible = false
	
	# Set status information
	var status_parts = []
	if stack.is_equipped():
		status_parts.append("Equipped (" + stack.equipped_as.replace("_", " ").capitalize() + ")")
	if stack.is_on_hotbar():
		status_parts.append("Hotbar Slot " + str(stack.hotbar_slot + 1))
	if stack.is_locked:
		status_parts.append("🔒 Locked")
	
	if status_parts.size() > 0:
		status_label.text = "Status: " + ", ".join(status_parts)
		status_label.visible = true
	else:
		status_label.text = "Status: Available"
		status_label.visible = true
	
	# Set description
	_set_item_description(item)

func _set_item_description(item: GameItem):
	var description = ""
	
	# Add basic item info
	description += "[b]Category:[/b] " + item.category.capitalize() + "\n"
	
	# Add item-specific properties
	if item.has_method("get_description"):
		description += "\n" + item.get_description()
	else:
		description += "\n[i]A " + item.category + " item.[/i]"
	
	# Add technical details
	description += "\n\n[b]Technical Details:[/b]\n"
	description += "• Stack Size: " + str(item.stack_size) + "\n"
	
	# ✅ FIXED: Use safe property access instead of has_property()
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
