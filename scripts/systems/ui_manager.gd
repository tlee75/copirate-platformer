extends Node
class_name UIManager

# UI State Management
enum MenuType { NONE, PLAYER, OBJECT, PAUSE, SETTINGS }
var current_menu: MenuType = MenuType.NONE
var previous_menu: MenuType = MenuType.NONE

# UI References
var player_menu: PlayerMenu
var object_inventory_menu: Control
var current_object: Node2D

# Menu State Tracking
var menu_stack: Array[MenuType] = []

# Signals for UI coordination
signal menu_opened(menu_type: MenuType)
signal menu_closed(menu_type: MenuType)
signal menu_switched(from_menu: MenuType, to_menu: MenuType)
signal ui_state_changed(has_menu_open: bool)

func _ready():
	add_to_group("ui_manager")
	print("UIManager initialized")
	call_deferred("initialize")

func _input(event):
	# Handle ESC key to close any open menu
	if event.is_action_pressed("ui_cancel"):
		if is_any_menu_open():
			print("UIManager: ESC pressed - closing current menu")
			close_all_menus()
			get_viewport().set_input_as_handled()
		# If no menus open, let ESC pass through to main scene for pause menu

func initialize():
	# Find UI references
	var ui_layer = get_parent()
	
	player_menu = ui_layer.get_node_or_null("PlayerMenu")
	object_inventory_menu = ui_layer.get_node_or_null("ObjectInventoryMenu")
	
	if not player_menu:
		print("ERROR: Could not find PlayerMenu")
	else:
		print("Found PlayerMenu successfully")
		_connect_player_menu_signals()
	
	if not object_inventory_menu:
		print("ERROR: Could not find ObjectInventoryMenu")
	else:
		print("Found ObjectInventoryMenu successfully")

	# Connect to player input handler
	var player_input_handler = get_tree().get_first_node_in_group("player_input_handler")
	if player_input_handler:
		ui_state_changed.connect(player_input_handler._on_ui_state_changed)
		print("Connected UIManager to PlayerInputHandler")
	else:
		print("WARNING: PlayerInputHandler not found")


func _connect_player_menu_signals():
	"""Connect to player menu signals for state tracking"""
	print("Skipping PlayerMenu signal connections - UIManager directly controls menus")
	# Note: We don't need signals since UIManager directly controls the menus
	# This prevents double state changes and redundant updates

# ============================================================================
# CENTRAL MENU CONTROL METHODS
# ============================================================================

func toggle_player_menu():
	"""Toggle player menu with proper state management"""
	if current_menu == MenuType.PLAYER:
		close_player_menu()
	else:
		open_player_menu()

func open_player_menu():
	"""Open player menu, closing other menus if necessary"""
	# Only open if not already open
	if current_menu == MenuType.PLAYER:
		return
	
	# Close any other open menu first
	if current_menu == MenuType.OBJECT:
		close_object_menu()
	elif current_menu != MenuType.NONE:
		_close_current_menu()
	
	# Open player menu
	if player_menu and player_menu.has_method("open_menu"):
		player_menu.open_menu()
		_set_current_menu(MenuType.PLAYER)

func close_player_menu():
	"""Close player menu"""
	if player_menu and player_menu.has_method("close_menu"):
		player_menu.close_menu()
		_set_current_menu(MenuType.NONE)

func open_object_menu(object: Node2D, object_name: String, slot_count: int):
	"""Open object menu, closing other menus if necessary"""
	print("UIManager: Opening object menu for: ", object_name)
	
	# Close any other open menu first
	if current_menu != MenuType.NONE and current_menu != MenuType.OBJECT:
		_close_current_menu()
	
	# Store reference to current object
	current_object = object
	
	# Open object inventory menu
	if object_inventory_menu and object_inventory_menu.has_method("open_for_object"):
		object_inventory_menu.open_for_object(object, object_name, slot_count)
		_set_current_menu(MenuType.OBJECT)
	else:
		print("ERROR: Cannot open object menu - missing method or reference")

func close_object_menu():
	"""Close object menu"""
	print("UIManager: close_object_menu() START")
	
	if object_inventory_menu and object_inventory_menu.has_method("close_menu"):
		object_inventory_menu.close_menu()
	
	current_object = null
	_set_current_menu(MenuType.NONE)
	print("UIManager: close_object_menu() END")

func close_all_menus():
	"""Close all open menus"""
	print("UIManager: Closing all menus")
	_close_current_menu()

# ============================================================================
# STATE MANAGEMENT HELPERS
# ============================================================================

func _set_current_menu(menu_type: MenuType):
	"""Internal method to update current menu state"""
	var old_menu = current_menu
	previous_menu = old_menu
	current_menu = menu_type
	
	print("UIManager: Menu state changed from ", _menu_type_to_string(old_menu), " to ", _menu_type_to_string(menu_type))
	
	# Emit appropriate signals
	if old_menu != MenuType.NONE:
		menu_closed.emit(old_menu)
	
	if menu_type != MenuType.NONE:
		menu_opened.emit(menu_type)
	
	if old_menu != menu_type:
		menu_switched.emit(old_menu, menu_type)
	
	# Emit UI state change
	ui_state_changed.emit(menu_type != MenuType.NONE)

func _close_current_menu():
	"""Internal method to close whatever menu is currently open"""
	match current_menu:
		MenuType.PLAYER:
			close_player_menu()
		MenuType.OBJECT:
			close_object_menu()
		MenuType.NONE:
			pass  # Nothing to close
		_:
			print("WARNING: Unknown menu type to close: ", current_menu)

func _menu_type_to_string(menu_type: MenuType) -> String:
	"""Convert menu type enum to readable string"""
	match menu_type:
		MenuType.NONE: return "NONE"
		MenuType.PLAYER: return "PLAYER"
		MenuType.OBJECT: return "OBJECT"
		MenuType.PAUSE: return "PAUSE"
		MenuType.SETTINGS: return "SETTINGS"
		_: return "UNKNOWN"

# ============================================================================
# PUBLIC STATE QUERY METHODS
# ============================================================================

func is_any_menu_open() -> bool:
	"""Check if any menu is currently open"""
	return current_menu != MenuType.NONE

func is_player_menu_open() -> bool:
	"""Check if player menu is open"""
	return current_menu == MenuType.PLAYER

func is_object_menu_open() -> bool:
	"""Check if object menu is open"""
	return current_menu == MenuType.OBJECT

func get_current_menu() -> MenuType:
	"""Get currently open menu type"""
	return current_menu

func get_current_object() -> Node2D:
	"""Get current object for object menu"""
	return current_object

func can_open_menu(menu_type: MenuType) -> bool:
	"""Check if a specific menu can be opened (for validation)"""
	match menu_type:
		MenuType.PLAYER:
			return player_menu != null
		MenuType.OBJECT:
			return object_inventory_menu != null
		_:
			return false
