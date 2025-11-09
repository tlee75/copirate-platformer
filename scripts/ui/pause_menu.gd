extends Control

signal resume_requested
signal restart_requested
signal respawn_requested

var allow_resume := true
var ui_manager: UIManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()
	$VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$VBoxContainer/RespawnButton.pressed.connect(_on_respawn_pressed)
	
	# Get reference to UIManager
	call_deferred("_setup_ui_manager_reference")

func _setup_ui_manager_reference():
	"""Get reference to UIManager for proper state management"""
	ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if not ui_manager:
		print("WARNING: UIManager not found for pause menu")

func show_pause_menu():
	"""Show the pause menu and notify UIManager"""
	visible = true
	get_tree().paused = true
	
	# Notify UIManager that pause menu is open
	if ui_manager:
		ui_manager._set_current_menu(UIManager.MenuType.PAUSE)
	
	print("Pause menu opened")

func hide_pause_menu():
	"""Hide the pause menu and notify UIManager"""
	visible = false
	get_tree().paused = false
	
	# Notify UIManager that pause menu is closed
	if ui_manager:
		ui_manager._set_current_menu(UIManager.MenuType.NONE)
	
	print("Pause menu closed")

func _on_resume_pressed():
	hide_pause_menu()
	emit_signal("resume_requested")

func _on_restart_pressed():
	hide_pause_menu()
	emit_signal("restart_requested")

func _on_respawn_pressed():
	hide_pause_menu()
	emit_signal("respawn_requested")

func set_resume_enabled(enabled: bool):
	$VBoxContainer/ResumeButton.disabled = not enabled
	allow_resume = enabled

func _on_visibility_changed():
	if visible:
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
