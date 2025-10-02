extends Node2D

@export var full_texture: Texture2D
@export var empty_texture: Texture2D
var has_berries: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if full_texture:
		$Sprite2D.texture = full_texture


func interact(player):
	if has_berries:
		has_berries = false
		

func give_player_berries():
	print("Player harvested berries")
