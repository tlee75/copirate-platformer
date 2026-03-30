extends Node2D
class_name CrosshairDisplay

var radius: float = 28.0

const CROSSHAIR_COLOR   := Color(1.0, 0.15, 0.15, 1.0)   # Bright red
const FILL_COLOR        := Color(0.12, 0.0, 0.0, 0.35)   # Dark red, semi-transparent
const LINE_WIDTH        := 1.5

func set_radius(new_radius: float) -> void:
	if radius != new_radius:
		radius = new_radius
		queue_redraw()

func _draw() -> void:
	# Semi-transparent filled circle
	draw_circle(Vector2.ZERO, radius, FILL_COLOR)
	# Red circle rim
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, CROSSHAIR_COLOR, LINE_WIDTH)
	# Gapped crosshair lines: starts at 15% of radius, ends at 130%
	var inner := radius * 0.15
	var outer := radius * 1.3
	draw_line(Vector2(-outer,  0),    Vector2(-inner, 0),    CROSSHAIR_COLOR, LINE_WIDTH)
	draw_line(Vector2( inner,  0),    Vector2( outer, 0),    CROSSHAIR_COLOR, LINE_WIDTH)
	draw_line(Vector2(0,      -outer), Vector2(0,    -inner), CROSSHAIR_COLOR, LINE_WIDTH)
	draw_line(Vector2(0,       inner), Vector2(0,     outer), CROSSHAIR_COLOR, LINE_WIDTH)
