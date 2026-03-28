extends GameObject

func _ready():
	is_harvestable = true
	harvest_loot = "scallop_shell"
	harvest_remaining = 1
	max_harvest = 1
	target_actions = ["harvest"]
	super._ready()

func use_finished_callback():
	queue_free()

func get_hover_color() -> Color:
	return Color(1.8, 1.8, 0.4, 1.0)  # Bright yellow glow — hard to miss

func get_hover_scale_multiplier() -> float:
	return 1.5  # 50% bigger on hover — very obvious on tiny sprites
