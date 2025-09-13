extends Area2D

func _ready():
	# Create SpriteFrames resource for gold coin animation
	var frames = SpriteFrames.new()
	
	# Load gold coin textures
	var coin_01 = load("res://assets/Pirate Treasure/Sprites/Gold Coin/01.png")
	var coin_02 = load("res://assets/Pirate Treasure/Sprites/Gold Coin/02.png")
	var coin_03 = load("res://assets/Pirate Treasure/Sprites/Gold Coin/03.png")
	var coin_04 = load("res://assets/Pirate Treasure/Sprites/Gold Coin/04.png")
	
	# Create animation
	frames.add_animation("spin")
	frames.add_frame("spin", coin_01)
	frames.add_frame("spin", coin_02)
	frames.add_frame("spin", coin_03)
	frames.add_frame("spin", coin_04)
	frames.set_animation_speed("spin", 8.0)
	frames.set_animation_loop("spin", true)
	
	# Apply to AnimatedSprite2D
	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("spin")
	
	# Connect area entered signal for collection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if player collected the coin
	if body.name == "Player":
		print("Coin collected!")
		# Remove the coin
		queue_free()
