extends Control
class_name EquipmentCategoryFilter

signal category_selected(category: String)

var current_category: String = "all"
var category_buttons: Dictionary = {}
var category_container: HBoxContainer

func _ready():
	_setup_ui_references()
	_create_category_buttons()
	_update_button_states()

func _setup_ui_references():
	category_container = $CategoryContainer

func _create_category_buttons():
	var categories = ["all", "weapons", "armor", "accessories"]
	
	for category in categories:
		var button = Button.new()
		button.text = _get_category_display_name(category)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(120, 40)
		
		# Connect signal
		button.pressed.connect(_on_category_button_pressed.bind(category))
		
		# Add to container and track
		category_container.add_child(button)
		category_buttons[category] = button

func _get_category_display_name(category: String) -> String:
	var display_names = {
		"all": "All Equipment",
		"weapons": "Weapons", 
		"armor": "Armor",
		"accessories": "Accessories"
	}
	return display_names.get(category, category.capitalize())

func _on_category_button_pressed(category: String):
	if category != current_category:
		current_category = category
		_update_button_states()
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
