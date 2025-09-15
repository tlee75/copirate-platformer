extends Label

func _ready():
	# Set initial text
	text = "FPS: 6d0"

func _process(_delta):
	# Update FPS display every frame
	var fps = Engine.get_frames_per_second()
	text = "FPS: " + str(fps)
