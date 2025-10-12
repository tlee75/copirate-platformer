extends GameItem
class_name Sword

# Animation hit frame definition
var hit_frames = {
	"sword_attack": [8], # List is required for single frames
}

func _init():
	name = "Sword"
	icon = load("res://assets/Captain Clown Nose/Sprites/Captain Clown Nose/Sword/21-Sword Idle/Sword Idle 01.png")
	stack_size = 1
	craftable = true
	category = "weapon"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 2}
	attack_animation = "sword_attack"
	damage = 1
	is_weapon = true
