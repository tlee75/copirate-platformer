extends GameObject

# Breakable object that can be destroyed by player attacks
var object_name = "Wood Crate"

@export var gold_coin_scene: PackedScene

# Cooldown to prevent multiple hits from same attack
@export var hit_cooldown_time: float = 0.5
var hit_cooldown: float = 0.0

func _ready():
	category = "obstacle"
	is_harvestable = true
	is_destructible = true
	regeneration_time = 0.0  # Crates don't regenerate

	var default_loot = [{ "item": gold_coin_scene, "type": "drop", "chance": 1.0, "min": 1, "max": 3 }]

	var all_attacks = {
			"melee": default_loot, 
			"dig": default_loot, 
			"chop": default_loot,
			"slice": default_loot,
			"mine": default_loot
		}

	loot_table = all_attacks

	if animated_sprite:
		animated_sprite.play("idle")

	super._ready()

func _process(delta):
	if hit_cooldown > 0.0:
		hit_cooldown -= delta

func is_interactable() -> bool:
	return is_harvestable and hit_cooldown <= 0.0

func set_cooldown():
	hit_cooldown = hit_cooldown_time
