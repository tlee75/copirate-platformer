extends Node2D
class_name CrosshairDisplay

var radius: float = 28.0
var base_radius: float = 28.0
var anim_progress: float = 0.0

const BORDER_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const FILL_COLOR   := Color(0.972, 0.441, 0.666, 0.25)
const LINE_WIDTH   := 1.5
const SHRINK_SPEED := 1.5      # Full cycle per second
const SHRINK_MIN   := 0.5      # Shrinks to 50% of base radius

func set_radius(new_radius: float) -> void:
	base_radius = new_radius

func _process(delta: float) -> void:
	if not visible:
		return
	anim_progress += delta * SHRINK_SPEED
	if anim_progress >= 1.0:
		anim_progress -= 1.0
	# Ease-out shrink: pops to full size, smoothly shrinks down
	var t = anim_progress
	var scale_factor = lerp(1.0, SHRINK_MIN, t * t)
	radius = base_radius * scale_factor
	queue_redraw()

func _draw() -> void:
	var box := Rect2(-radius, -radius, radius * 2.0, radius * 2.0)
	draw_rect(box, FILL_COLOR)
	draw_rect(box, BORDER_COLOR, false, LINE_WIDTH)
