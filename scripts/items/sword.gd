extends GameItem
class_name Sword

# Animation hit frame definition
var hit_frames = {
	"attack": [8], # List is required for single frames
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

func action(player):
	print("Sword attack by %s" % player.name)
	player.is_trigger_action = true
	player.get_node("AnimatedSprite2D").play("attack")
	
	cleanup_connections(player) # Defined in base class
