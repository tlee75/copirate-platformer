extends GameObject

@export var stick_scene: PackedScene
#@export var coconut_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	# Setup harvest
	category = "terrain"
	regeneration_time = 5.0
	is_harvestable = true
	is_destructible = true
	max_harvests = 10
	loot_table = {
		"chop": [
			{ "item": "coconut", "type": "harvest", "weight": 2.0 },
			{ "item": "stick", "type": "harvest", "weight": 1.0 },
			{ "item": stick_scene, "type": "drop", "min": 1, "max": 3 }
		],
		"melee": [
			{ "item": "coconut", "type": "harvest", "weight": 1.0 },
			{ "item": "stick", "type": "harvest", "weight": 2.0 }
		]
	}

	# Start with normal idle animation
	if animated_sprite:
		animated_sprite.play("idle_full")

	# Call parent _ready() to setup hover detection
	super._ready()
