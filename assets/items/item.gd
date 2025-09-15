class_name Item
extends Resource

@export var item_name: String = "New Item"
@export var texture: Texture2D
@export var stackable: bool = true
@export var max_stack_size: int = 1
@export var weight: float = 1.0
@export var description: String = ""
@export var category: String = "Misc"
@export var value: int = 0
@export var consumable: bool = false
@export var equippable: bool = false
@export_category("Visual")
@export var tint: Color = Color(1, 1, 1, 1)
@export var scale: float = 1.0
