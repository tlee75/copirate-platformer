extends Resource

class_name GameItem

@export var name: String
@export var icon: Texture2D
@export var stack_size: int = 1
@export var craftable: bool = false
@export var category: String = ""

func action(user):
	pass
