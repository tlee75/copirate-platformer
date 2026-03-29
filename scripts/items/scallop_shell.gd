extends GameItem

class_name ScallopShell

@export var fuel_value: float = 0.0 # Seconds of burn time

func _init():
	name = "Scallop Shell"
	stack_size = 99
	category = "resource"
	craftable = false
	icon = load("res://assets/terrain/scallop_shell_1.png")
