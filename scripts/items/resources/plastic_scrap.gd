extends GameItem

class_name PlasticScrap

@export var fuel_value: float = 0.0 # Seconds of burn time

func _init():
	stack_size = 99
	category = "resource"
	craftable = false
	icon = load("res://assets/resources/plastic_scrap_64x64_1.png")
	fuel_value = 0
	underwater_compatible = false
	land_compatible = false
