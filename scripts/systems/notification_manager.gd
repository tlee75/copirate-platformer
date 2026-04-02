extends Node

enum NotificationType {
	ITEM_PICKUP,
	ITEM_COOKED,
	BLUEPRINT_DISCOVERED,
	STAT_WARNING,
	STAT_DEPLETED,
	ENVIRONMENT,
}

signal notification_added(key: String, type: NotificationType, message: String, count: int)
signal notification_updated(key: String, count: int)
signal notification_removed(key: String)

var _active: Dictionary = {}  # key -> { type, message, count, timer }

const DISMISS_TIME: float = 5.0
const MAX_NOTIFICATIONS: int = 6

func notify(type: NotificationType, key: String, message: String) -> void:
	if _active.has(key):
		_active[key].count += 1
		_active[key].timer = DISMISS_TIME
		notification_updated.emit(key, _active[key].count)
	else:
		# If at max, remove the oldest
		if _active.size() >= MAX_NOTIFICATIONS:
			_remove_oldest()
		_active[key] = { "type": type, "message": message, "count": 1, "timer": DISMISS_TIME }
		notification_added.emit(key, type, message, 1)

func _process(delta: float) -> void:
	var to_remove: Array[String] = []
	for key in _active.keys():
		_active[key].timer -= delta
		if _active[key].timer <= 0.0:
			to_remove.append(key)
	for key in to_remove:
		_active.erase(key)
		notification_removed.emit(key)

func _remove_oldest() -> void:
	var oldest_key: String = ""
	var lowest_timer: float = INF
	for key in _active.keys():
		if _active[key].timer < lowest_timer:
			lowest_timer = _active[key].timer
			oldest_key = key
	if oldest_key != "":
		_active.erase(oldest_key)
		notification_removed.emit(oldest_key)
