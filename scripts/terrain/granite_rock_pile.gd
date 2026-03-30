extends GameObject

# Called when the node enters the scene tree for the first time.
func _ready():
	# Setup harvest
	category = "terrain"
	max_harvest = 3
	harvest_remaining = max_harvest
	regeneration_time = 5.0 
	is_harvestable = true
	is_destructible = false
	loot_table = {
		"interact": [
			{ "item": "simple_rock", "type": "harvest", "chance": 1.0, "min": 1, "max": 1 },
			{ "item": "stick", "type": "harvest", "chance": 1.0, "min": 1, "max": 1 }
		]
	}
	# Start with normal idle animation
	if animated_sprite:
		animated_sprite.play("idle_full")

	# Call parent _ready() which will setup hover detection
	super._ready()

func is_interactable() -> bool:
	return is_harvestable == true
