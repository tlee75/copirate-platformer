extends Control
class_name InventoryCategoryFilter

signal category_selected(category: String)

@export var button_scene: PackedScene
var current_category: String = "all"
var category_buttons: Dictionary = {}
var scroll_container: ScrollContainer
var category_container: HBoxContainer
var left_arrow: Button
var right_arrow: Button

func _ready():
	_setup_ui_references()
	_setup_navigation_arrows()
	refresh_categories()

func _setup_ui_references():
	scroll_container = $ScrollContainer
	category_container = $ScrollContainer/CategoryContainer
	left_arrow = $LeftArrow
	right_arrow = $RightArrow

func _setup_navigation_arrows():
	left_arrow.text = "◀"
	right_arrow.text = "▶"
	left_arrow.pressed.connect(_scroll_left)
	right_arrow.pressed.connect(_scroll_right)

func refresh_categories():
	# Clear existing buttons
	for button in category_buttons.values():
		if is_instance_valid(button):
			button.queue_free()
	category_buttons.clear()
	
	# Get available categories from inventory
	var categories = InventoryManager.get_available_categories()
	
	# Create buttons for each category
	for category in categories:
		_create_category_button(category)
	
	# Select current category
	_update_button_states()

func _create_category_button(category: String):
	var button = Button.new()
	button.text = _get_category_display_name(category)
	button.toggle_mode = true
	button.button_group = _get_or_create_button_group()
	button.custom_minimum_size = Vector2(120, 40)
	
	# Style the button
	button.add_theme_stylebox_override("normal", _create_category_button_style(false))
	button.add_theme_stylebox_override("pressed", _create_category_button_style(true))
	button.add_theme_stylebox_override("hover", _create_category_button_style(false, true))
	
	# Connect signals
	button.pressed.connect(_on_category_button_pressed.bind(category))
	
	# Add to container and track
	category_container.add_child(button)
	category_buttons[category] = button

func _get_category_display_name(category: String) -> String:
	var display_names = {
		"all": "All Items",
		"tool": "Tools", 
		"weapon": "Weapons",
		"consumable": "Consumables",
		"material": "Materials",
		"equipment": "Equipment",
		"armor": "Armor",
		"fuel": "Fuel",
		"food": "Food"
	}
	return display_names.get(category, category.capitalize())

func _create_category_button_style(selected: bool, hover: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	
	if selected:
		style.bg_color = Color(0.4, 0.6, 1.0, 0.8)  # Blue selected
		style.border_color = Color(0.6, 0.8, 1.0, 1.0)
	elif hover:
		style.bg_color = Color(0.3, 0.3, 0.3, 0.6)  # Gray hover
		style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	else:
		style.bg_color = Color(0.2, 0.2, 0.2, 0.5)  # Dark normal
		style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	return style

var button_group: ButtonGroup
func _get_or_create_button_group() -> ButtonGroup:
	if not button_group:
		button_group = ButtonGroup.new()
	return button_group

func _on_category_button_pressed(category: String):
	print("DEBUG: Category button pressed: ", category)
	if category != current_category:
		current_category = category
		_update_button_states()
		print("DEBUG: Emitting category_selected signal: ", category)
		category_selected.emit(category)

func _update_button_states():
	for cat in category_buttons.keys():
		var button = category_buttons[cat]
		if button and is_instance_valid(button):
			button.button_pressed = (cat == current_category)

func set_selected_category(category: String):
	if category != current_category and category_buttons.has(category):
		current_category = category
		_update_button_states()
		category_selected.emit(category)

func _scroll_left():
	var current_scroll = scroll_container.scroll_horizontal
	scroll_container.scroll_horizontal = max(0, current_scroll - 150)

func _scroll_right():
	var current_scroll = scroll_container.scroll_horizontal
	var max_scroll = category_container.size.x - scroll_container.size.x
	scroll_container.scroll_horizontal = min(max_scroll, current_scroll + 150)

func navigate_left():
	_navigate_category(-1)

func navigate_right():
	_navigate_category(1)

func _navigate_category(direction: int):
	var categories = InventoryManager.get_available_categories()
	var current_index = categories.find(current_category)
	
	if current_index != -1:
		var new_index = clamp(current_index + direction, 0, categories.size() - 1)
		var new_category = categories[new_index]
		
		if new_category != current_category:
			set_selected_category(new_category)
			_scroll_to_category(new_category)

func _scroll_to_category(category: String):
	if category_buttons.has(category):
		var button = category_buttons[category]
		var button_pos = button.position.x
		var container_width = scroll_container.size.x
		var target_scroll = button_pos - (container_width / 2) + (button.size.x / 2)
		
		scroll_container.scroll_horizontal = max(0, target_scroll)
