extends GameItem

class_name Stick

@export var fuel_value: float = 10.0 # Seconds of burn time

func _init():
	name = "Stick"
	description = "A small wooden branch. Burns well as fuel and useful for basic crafting."
	stack_size = 99
	category = "fuel"
	craftable = false
	icon = load("res://assets/resources/stick_01_48x64.png")
	fuel_value = 5
	underwater_compatible = false
	land_compatible = false
	craft_requirements = {"Gold Coin": 1}
