extends MarginContainer

var _items: Dictionary = {}  # key -> PanelContainer
var _vbox: VBoxContainer

const TYPE_COLORS: Dictionary = {
	0: Color.WHITE,              # ITEM_PICKUP
	1: Color(1.0, 0.65, 0.0),   # ITEM_COOKED (orange)
	2: Color(1.0, 0.84, 0.0),   # RECIPE_DISCOVERED (gold)
	3: Color(1.0, 1.0, 0.0),    # STAT_WARNING (yellow)
	4: Color(1.0, 0.3, 0.3),    # STAT_DEPLETED (red)
	5: Color(0.6, 0.9, 1.0),    # ENVIRONMENT (light cyan)
}

const BG_COLORS: Dictionary = {
	0: Color(0.0, 0.0, 0.0, 0.5),
	1: Color(0.15, 0.08, 0.0, 0.5),
	2: Color(0.15, 0.12, 0.0, 0.5),
	3: Color(0.15, 0.12, 0.0, 0.6),
	4: Color(0.2, 0.0, 0.0, 0.6),
	5: Color(0.0, 0.05, 0.12, 0.5),
}

func _ready():
	_vbox = $VBoxContainer
	NotificationManager.notification_added.connect(_on_added)
	NotificationManager.notification_updated.connect(_on_updated)
	NotificationManager.notification_removed.connect(_on_removed)

func _on_added(key: String, type: NotificationManager.NotificationType, message: String, count: int) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = BG_COLORS.get(type, Color(0, 0, 0, 0.5))
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.name = "MessageLabel"
	var display_text = message if count <= 1 else message + " x" + str(count)
	label.text = display_text
	label.add_theme_color_override("font_color", TYPE_COLORS.get(type, Color.WHITE))
	label.add_theme_font_size_override("font_size", 14)
	panel.add_child(label)

	_vbox.add_child(panel)
	_items[key] = panel

	# Slide-in animation
	panel.modulate = Color(1, 1, 1, 0)
	panel.position.x = 40
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.tween_property(panel, "position:x", 0.0, 0.2).set_ease(Tween.EASE_OUT)

func _on_updated(key: String, count: int) -> void:
	if not _items.has(key):
		return
	var panel = _items[key]
	var label = panel.get_node("MessageLabel") as Label
	if label:
		# Find the base message (strip old " xN" suffix if present)
		var text = label.text
		var x_pos = text.rfind(" x")
		if x_pos != -1:
			text = text.substr(0, x_pos)
		label.text = text + " x" + str(count)

	# Brief scale pulse to draw attention
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.08)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.08)

func _on_removed(key: String) -> void:
	if not _items.has(key):
		return
	var panel = _items[key]
	_items.erase(key)

	# Fade-out animation, then free
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_property(panel, "position:x", 40.0, 0.3)
	tween.chain().tween_callback(panel.queue_free)
