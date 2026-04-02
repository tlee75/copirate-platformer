extends GameItem
class_name GoldCoin

func _init():
	icon = load("res://assets/Pirate Treasure/Sprites/Gold Coin/01.png")
	stack_size = 10
	craftable = false
	category = "currency"
	underwater_compatible = false
	land_compatible = true
