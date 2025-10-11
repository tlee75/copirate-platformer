extends GameItem

class_name Stick

@export var fuel_value: float = 10.0 # Seconds of burn time

func _init():
	name = "Stick"
	stack_size = 99
	category = "fuel"
	craftable = false
	icon = load("res://assets/terrain/stick_01_48x64.png")
	fuel_value = 5
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 1}

func action(user):
	# Sticks can't be used directly, only added to firepits
	print(user, "looks at the stick...Perhaps there is something we can do with it?")
