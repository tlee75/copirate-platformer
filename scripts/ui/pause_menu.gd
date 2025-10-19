extends Control

signal resume_requested
signal restart_requested
signal respawn_requested

var allow_resume := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()
	$VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$VBoxContainer/RespawnButton.pressed.connect(_on_respawn_pressed)


func _on_resume_pressed():
	emit_signal("resume_requested")

func _on_restart_pressed():
	emit_signal("restart_requested")

func _on_respawn_pressed():
	emit_signal("respawn_requested")

func set_resume_enabled(enabled: bool):
	$VBoxContainer/ResumeButton.disabled = not enabled
	allow_resume = enabled

func _on_visibility_changed():
	if visible:
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
