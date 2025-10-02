extends Resource

class_name GameItem

@export var name: String
@export var icon: Texture2D
@export var stack_size: int = 1
@export var craftable: bool = false
@export var category: String = ""
@export var craft_requirements: Dictionary = {}
@export var underwater_compatible: bool = false
@export var land_compatible: bool = true
