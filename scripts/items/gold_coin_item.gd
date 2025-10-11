extends GameItem
class_name GoldCoinItem

func _init():
	name = "Gold Coin"
	icon = load("res://assets/Pirate Treasure/Sprites/Gold Coin/01.png")
	stack_size = 10
	craftable = false
	category = "currency"
	underwater_compatible = false
	land_compatible = true
