extends GameItem

class_name MetalScrap

@export var fuel_value: float = 0.0 # Seconds of burn time

func _init():
	stack_size = 99
	category = "resource"
	craftable = false
	icon = load("res://assets/resources/metal_scrap_128x128_1.png")
	fuel_value = 0
	underwater_compatible = false
	land_compatible = false
