extends GameItem

class_name StickItem

@export var fuel_value: float = 10.0 # Seconds of burn time

func _init():
	name = "Stick"
	stack_size = 99
	category = "fuel"
	craftable = false

func action(user):
	# Sticks can't be used directly, only added to firepits
	print(user, "looks at the stick...Perhaps there is something we can do with it?")
