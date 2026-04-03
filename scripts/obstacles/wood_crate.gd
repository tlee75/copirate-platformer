extends GameObject

@export var gold_coin_scene: PackedScene

func _ready():
	category = "obstacle"
	is_harvestable = true
	is_destructible = true
	regeneration_time = 0.0  # Crates don't regenerate

	max_harvests = 3
	var default_loot = [{ "item": gold_coin_scene, "type": "drop", "min": 1, "max": 3 }]
	action_table = {
		"melee": default_loot,
		"dig": default_loot,
		"chop": default_loot,
		"slice": default_loot,
		"mine": default_loot
	}

	if animated_sprite:
		animated_sprite.play("idle")

	super._ready()
