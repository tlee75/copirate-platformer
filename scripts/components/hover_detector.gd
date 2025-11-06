extends Area2D
class_name HoverDetector

signal hover_started
signal hover_ended

var parent_object
var is_hovering: bool = false

func _ready():
	parent_object = get_parent()
	
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Ensure detection is enabled
	monitoring = true
	monitorable = false  # We don't need other objects to detect this

func _on_mouse_entered():
	# Check if parent object is interactable
	if parent_object.has_method("is_interactable") and parent_object.is_interactable():
		if not is_hovering:  # Prevent duplicate calls
			is_hovering = true
			hover_started.emit()
			
			# Call parent's hover method if it exists
			if parent_object.has_method("_on_hover_enter"):
				parent_object._on_hover_enter()

func _on_mouse_exited():
	if is_hovering:
		is_hovering = false
		hover_ended.emit()
		
		# Call parent's exit method if it exists
		if parent_object.has_method("_on_hover_exit"):
			parent_object._on_hover_exit()

func setup_collision_from_existing(source_area: Area2D):
	"""Copy collision shape from existing Area2D"""
	for child in source_area.get_children():
		if child is CollisionShape2D:
			var new_collision = child.duplicate()
			add_child(new_collision)
			break
