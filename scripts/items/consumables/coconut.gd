extends GameItem
class_name Coconut

func _init():
	name = "Coconut"
	icon = load("res://assets/resources/coconut_icon_01.png")
	stack_size = 10
	craftable = false
	category = "resource"
	underwater_compatible = false
	land_compatible = false
