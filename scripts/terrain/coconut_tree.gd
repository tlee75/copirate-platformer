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
	is_harvestable = true
	is_destructible = true

	loot_table = {
		"chop": [
			{ "item": "coconut", "type": "harvest", "chance": 1.0, "min": 1, "max": 1 },
			{ "item": "stick", "type": "harvest", "chance": 1.0, "min": 1, "max": 1 },
			{ "item": stick_scene, "type": "drop", "chance": 1.0, "min": 2, "max": 4 }
		],
		"punch": [{"item": "coconut", "type": "harvest", "chance": 1.0, "min": 1, "max": 1}]
	}

	# Start with normal idle animation
	if animated_sprite:
		animated_sprite.play("idle_full")

	# Call parent _ready() to setup hover detection
	super._ready()
