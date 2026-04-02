extends GameItem

class_name ScallopShell

@export var fuel_value: float = 0.0 # Seconds of burn time

func _init():
	stack_size = 99
	category = "resource"
	craftable = false
	icon = load("res://assets/resources/scallop_shell_1.png")
