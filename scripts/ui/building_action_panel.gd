extends Control
class_name BuildingActionPanel

signal action_requested(action_type: InventoryActionResolver.ActionType)

var button_container: HBoxContainer
var action_buttons: Array[Button] = []
var current_stack: InventoryManager.ItemStack
var input_handler: PlayerInputHandler

func _ready():
	_setup_ui_references()

func _setup_ui_references():
	button_container = $ButtonContainer

func set_input_handler(handler: PlayerInputHandler):
	input_handler = handler

func display_actions_for_item(stack: InventoryManager.ItemStack, _context: Dictionary = {}):
	current_stack = stack
	_clear_action_buttons()
	
	if not stack or not input_handler:
		return
	
	var actions = input_handler.get_available_actions_for_stack(stack)
	_create_action_buttons(actions)

func _clear_action_buttons():
	for button in action_buttons:
		if is_instance_valid(button):
			button.queue_free()
	action_buttons.clear()

func _create_action_buttons(actions: Array[InventoryActionResolver.ActionData]):
	for action in actions:
		var button = _create_action_button(action)
		button_container.add_child(button)
		action_buttons.append(button)

func _create_action_button(action: InventoryActionResolver.ActionData) -> Button:
	var button = Button.new()
	button.text = action.label
	button.custom_minimum_size = Vector2(120, 40)
	
	button.add_theme_stylebox_override("normal", _create_secondary_button_style())
	button.add_theme_stylebox_override("hover", _create_secondary_button_style(true))
	
	# Add input hint as tooltip
	if action.input_hint != "":
		button.tooltip_text = "Press " + action.input_hint
	
	# Connect signal
	button.pressed.connect(_on_action_button_pressed.bind(action.type))
	
	return button

func _create_secondary_button_style(hover: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3, 0.6) if not hover else Color(0.4, 0.4, 0.4, 0.7)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _on_action_button_pressed(action_type: InventoryActionResolver.ActionType):
	action_requested.emit(action_type)

func refresh_actions():
	if current_stack:
		display_actions_for_item(current_stack)

func display_build_action(structure):
	# Remove all existing children from ButtonContainer
	for child in $ButtonContainer.get_children():
		$ButtonContainer.remove_child(child)
		child.queue_free()
	
	var build_button = Button.new()
	build_button.text = "Build " + structure.name
	build_button.pressed.connect(emit_signal.bind("action_requested", structure))
	$ButtonContainer.add_child(build_button)
