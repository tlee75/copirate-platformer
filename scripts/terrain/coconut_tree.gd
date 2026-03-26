extends GameObject

@export var stick_scene: PackedScene
#@export var coconut_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	# Setup harvest
	category = "terrain"
	max_harvest = 3
	harvest_remaining = max_harvest
	regeneration_time = 5.0 
	harvest_loot = "coconut"
	is_harvestable = true
	is_destructible = true
	
	# Setup loot table when the coconut tree is chopped down
	target_actions = ["chop", "harvest"]
	loot_table = [
		[stick_scene, 1.0, 2, 4]
	]

	# Start with normal idle animation
	if animated_sprite:
		animated_sprite.play("idle")

	# Call parent _ready() to setup hover detection
	super._ready()

func is_interactable() -> bool:
	return is_harvestable == true
