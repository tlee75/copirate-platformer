extends Control
class_name InventoryItemDetail

var item_icon: TextureRect
var item_name: Label
var item_category: Label
var quantity_label: Label
var stack_size_label: Label
var status_label: Label
var description_text: Label
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

func _setup_empty_state():
	_clear_display()

func set_input_handler(handler: PlayerInputHandler):
	input_handler = handler

func display_item(stack: InventoryManager.ItemStack):
	if not stack or not stack.item:
		clear_display()
		return
	
	display_item_or_structure(stack)

func display_item_or_structure(object):
	clear_display()
	
	var display_obj = object
	if object is InventoryManager.ItemStack:
		display_obj = object.item
		current_stack = object  # Store the stack reference
	
	# Basic info
	$MainContainer/ItemHeader/IconNameContainer/ItemIcon.texture = display_obj.icon
	$MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemName.text = display_obj.name
	$MainContainer/ItemHeader/IconNameContainer/NameContainer/ItemCategory.text = display_obj.category
	

	display_item_stats(object)
	_set_item_description(display_obj)
	
	visible = true

func _set_item_description(item: GameItem):
	description_text.text = item.description if item.description != "" else "A " + item.category + " item."

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
	visible = false

func display_item_stats(object):
	# Implement your item stats display logic here
	pass
