extends Node2D

@export var full_texture: Texture2D
@export var empty_texture: Texture2D
@export var max_health: int = 1
@export var regeneration_time: float = 30.0 

enum CoconutTreeState { FULL, EMPTY }
var state: int = CoconutTreeState.FULL
var health: int = max_health
var category: String = "terrain"

# Called when the node enters the scene tree for the first time.
func _ready():
	if full_texture:
		$Sprite2D.texture = full_texture

func is_interactable() -> bool:
	return state == CoconutTreeState.FULL


# Interact action handler (for future use)
func interact():
	if state == CoconutTreeState.EMPTY:
		return
	state = CoconutTreeState.EMPTY
	if empty_texture:
		$Sprite2D.texture = empty_texture
	
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
	if full_texture:
		$Sprite2D.texture = full_texture
	print("Coconut Tree has regrown!")
