extends GameObject

# Called when the node enters the scene tree for the first time.
func _ready():
	# Setup harvest
	category = "terrain"
	max_harvest = 3
	harvest_remaining = max_harvest
	regeneration_time = 30.0 
	is_harvestable = true
	is_destructible = false
	harvest_loot = "raspberry"
	
	target_actions = ["harvest"]
	
	# Start with normal idle animation
	if animated_sprite:
		animated_sprite.play("idle")

	# Call parent _ready() which will setup hover detection
	super._ready()

func is_interactable() -> bool:
	return is_harvestable == true
