extends Node2D
class_name CrosshairDisplay

var radius: float = 28.0

const BORDER_COLOR := Color(1.0, 1.0, 1.0, 1.0)      # White border
const FILL_COLOR   := Color(1.0, 0.85, 0.0, 0.25)    # Semi-transparent yellow fill
const LINE_WIDTH   := 1.5

func set_radius(new_radius: float) -> void:
	if radius != new_radius:
		radius = new_radius
		queue_redraw()

func _draw() -> void:
	var box := Rect2(-radius, -radius, radius * 2.0, radius * 2.0)
	draw_rect(box, FILL_COLOR)
	draw_rect(box, BORDER_COLOR, false, LINE_WIDTH)
