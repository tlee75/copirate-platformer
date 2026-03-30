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

	var coconut_loot = { "item": "coconut", "type": "harvest", "chance": 1.0, "min": 1, "max": 1 }
	var stick_loot = { "item": "stick", "type": "harvest", "chance": 1.0, "min": 1, "max": 1 }
	loot_table = {
		"chop": [
			coconut_loot,
			stick_loot,
			{ "item": stick_scene, "type": "drop", "chance": 1.0, "min": 1, "max": 3 }
		],
		"melee": [
			coconut_loot,
			stick_loot
			]
	}

	# Start with normal idle animation
	if animated_sprite:
		animated_sprite.play("idle_full")

	# Call parent _ready() to setup hover detection
	super._ready()
