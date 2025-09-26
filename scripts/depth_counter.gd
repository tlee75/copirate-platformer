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
		var current_y = player.global_position.y
		var tile_size = 32.0  # Define tile size here

		if current_y > 0:
			# Underwater - calculate depth
			var depth_tiles = int(current_y / tile_size) + 1
			text = "Depth: %d tiles below sea level" % depth_tiles
			visible = true
		elif current_y < -tile_size:  # Only show altitude if significantly above sea level
			# Above sea level
			var altitude_tiles = int(abs(current_y) / tile_size)
			text = "Altitude: %d tiles above sea level" % altitude_tiles
			visible = true
		else:
			# Near sea level
			text = "At sea level"
			visible = true
