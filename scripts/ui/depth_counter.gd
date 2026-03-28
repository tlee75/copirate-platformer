extends Label

var player: Player

func _ready():
	# Find the player node
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("DepthCounter: Could not find Player node!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if player:
		var water_depth = player.get_water_depth()

		if not player.is_underwater:
			visible = false
		elif water_depth <= 0:
			text = "Depth: Sea level"
			visible = true
		else:
			text = "Depth: %d tiles" % water_depth
			visible = true
