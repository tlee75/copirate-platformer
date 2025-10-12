extends GameItem

class_name ClayDirt

@export var fuel_value: float = 0.0 # Seconds of burn time

func _init():
	name = "Clay Dirt"
	stack_size = 99
	category = "resource"
	craftable = true
	icon = load("res://assets/terrain/clay_dirt_icon_01.png")
	fuel_value = 0
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 1}
