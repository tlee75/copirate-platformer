extends Control

signal resume_requested
signal restart_requested
signal respawn_requested

var allow_resume := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$VBoxContainer/RespawnButton.pressed.connect(_on_respawn_pressed)


func _on_resume_pressed():
	emit_signal("resume_requested")

func _on_restart_pressed():
	emit_signal("restart_requested")

func _on_respawn_pressed():
	emit_signal("respawn_requested")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and allow_resume:
			emit_signal("resume_requested")
			get_viewport().set_input_as_handled()

func set_resume_enabled(enabled: bool):
	$VBoxContainer/ResumeButton.disabled = not enabled
	allow_resume = enabled
