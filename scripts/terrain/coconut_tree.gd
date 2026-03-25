extends GameObject

@export var full_texture: Texture2D
@export var empty_texture: Texture2D
@export var max_harvest: int = 3
@export var regeneration_time: float = 30.0 
@export var stick_scene: PackedScene
#@export var coconut_scene: PackedScene

@onready var harvest_remaining: int = max_harvest
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

enum CoconutTreeState { FULL, EMPTY }
var state: int = CoconutTreeState.FULL

var loot_table = [
	[stick_scene, 1.0, 2, 4],
	#[coconut_scene, 1.0, 2, 4]
]

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set category for GameObject base class
	category = "terrain"
	
	harvest_remaining = max_harvest
	
	target_actions = ["chop"]
	
	if animated_sprite:
		animated_sprite.play("idle")

	# Call parent _ready() to setup hover detection
	super._ready()

func is_interactable() -> bool:
	return state == CoconutTreeState.FULL

# Interact action handler (for future use)
func interact():
	if state == CoconutTreeState.EMPTY:
		return
	state = CoconutTreeState.EMPTY
	if animated_sprite:
		animated_sprite.play("idle_empty")
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_loot"):
		player.add_loot("coconut", 1)
	
	print("Harvesting coconuts - will regrow in ", regeneration_time, " seconds")
	
	# Register with ResourceManager for regeneration
	ResourceManager.register_resource_regeneration(self, regeneration_time)

func set_cooldown():
	pass

func regenerate():
	state = CoconutTreeState.FULL
	if animated_sprite:
		animated_sprite.play("idle")
	print("Coconut Tree has regrown!")

func harvest(amount: int):
	harvest_remaining -= amount
	if animated_sprite and harvest_remaining >= 0:
		animated_sprite.play("hit_empty")
	print("Coconut Tree harvest: ", harvest_remaining, "/", max_harvest)

func on_harvest_complete():
	if harvest_remaining <= 0:
		LootDropper.drop_loot(loot_table, self)
		print("Coconut Tree chopped down!")
		
		# Play destruction animation if available
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("break"):
			animated_sprite.play("break")
			# Wait for animation to finish, then remove object
			await animated_sprite.animation_finished
		else:
			print("WARN: Unable to find break animation")
		queue_free()
