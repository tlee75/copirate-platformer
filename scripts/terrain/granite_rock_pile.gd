extends GameObject

# Called when the node enters the scene tree for the first time.
func _ready():
	# Setup harvest
	category = "terrain"
	regeneration_time = 5.0 
	is_harvestable = true
	is_destructible = false
	max_harvests = 2
	loot_table = {
		"interact": [
			{ "item": "simple_rock", "type": "harvest", "weight": 1.0 },
			{ "item": "stick", "type": "harvest", "weight": 1.0 }
		]
	}
	# Start with normal idle animation
	if animated_sprite:
		animated_sprite.play("idle_full")

	# Call parent _ready() which will setup hover detection
	super._ready()

func is_interactable() -> bool:
	return is_harvestable == true
