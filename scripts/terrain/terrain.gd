extends Node2D
class_name GameTerrain

# Hover effect properties
var hover_detector: HoverDetector
var original_modulate: Color
var hover_tween: Tween
var sprite_node: Sprite2D  # Reference to the sprite node

# Terrain properties
var category: String = "terrain"

func _ready():
	# Wait one frame to ensure all @onready variables are initialized
	await get_tree().process_frame
	
	# Find the sprite node automatically
	_find_sprite_node()
	
	# Setup hover detection
	setup_hover_detection()

func _find_sprite_node():
	"""Automatically find the Sprite2D node in children"""
	for child in get_children():
		if child is Sprite2D:
			sprite_node = child
			break
	
	if not sprite_node:
		print("Warning: No Sprite2D found in ", name, " - hover effects disabled")

func setup_hover_detection():
	"""Setup hover detection for terrain objects"""
	if not sprite_node:
		print("Warning: No Sprite2D found in ", name, " - hover effects disabled")
		return
		
	original_modulate = sprite_node.modulate
	
	# Create hover detector
	hover_detector = HoverDetector.new()
	add_child(hover_detector)
	
	# IMPORTANT: Connect the signals to our methods
	hover_detector.hover_started.connect(_on_hover_enter)
	hover_detector.hover_ended.connect(_on_hover_exit)
	
	# Find Area2D and copy collision shape
	var area_node = _find_area2d()
	if area_node:
		hover_detector.setup_collision_from_existing(area_node)
		print("Hover detection setup for ", name, " with existing Area2D")
	else:
		print("Warning: No Area2D found for hover detection in ", name)

func _find_area2d() -> Area2D:
	"""Find Area2D node in children"""
	for child in get_children():
		if child is Area2D:
			return child
	return null

func _on_hover_enter():
	"""Called when mouse enters the terrain object"""
	if not is_interactable():
		return
	
	# Kill any existing tween
	if hover_tween:
		hover_tween.kill()
	
	# Create smooth transition to hover state
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	
	# Get hover color (can be overridden by subclasses)
	var hover_color = get_hover_color()
	hover_tween.tween_property(sprite_node, "modulate", hover_color, 0.15)
	
	# Subtle scale increase
	hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)
	
	# Change cursor
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_hover_exit():
	"""Called when mouse exits the terrain object"""
	if not sprite_node:
		return
		
	# Kill any existing tween
	if hover_tween:
		hover_tween.kill()
	
	# Create smooth transition back to normal
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	
	# Return to original colors and scale
	hover_tween.tween_property(sprite_node, "modulate", original_modulate, 0.15)
	hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Reset cursor
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func get_hover_color() -> Color:
	"""Override this in subclasses for custom hover colors"""
	return Color(1.1, 1.3, 1.1, 1.0)  # Default: slightly brighter with green tint

func is_interactable() -> bool:
	"""Override this in subclasses"""
	return true
