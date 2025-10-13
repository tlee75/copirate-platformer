extends GameItem

class_name SimpleRock

@export var fuel_value: float = 0.0 # Seconds of burn time

func _init():
	name = "Simple Rock"
	stack_size = 99
	category = "resource"
	craftable = false
	icon = load("res://assets/terrain/simple_rock_icon_01.png")
	fuel_value = 0
	underwater_compatible = false
	land_compatible = false
	craft_requirements = {"Gold Coin": 1}
