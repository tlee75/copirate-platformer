extends Control

@onready var health_bar: ProgressBar = $VBoxContainer/HealthContainer/HealthBar
@onready var oxygen_bar: ProgressBar = $VBoxContainer/OxygenContainer/OxygenBar
@onready var hunger_bar: ProgressBar = $VBoxContainer/HungerContainer/HungerBar
@onready var thirst_bar: ProgressBar = $VBoxContainer/ThirstContainer/ThirstBar

@onready var health_label: Label = $VBoxContainer/HealthContainer/HealthLabel
@onready var oxygen_label: Label = $VBoxContainer/OxygenContainer/OxygenLabel
@onready var hunger_label: Label = $VBoxContainer/HungerContainer/HungerLabel
@onready var thirst_label: Label = $VBoxContainer/ThirstContainer/ThirstLabel

var player_stats: PlayerStats

var health_rate_label: Label
var oxygen_rate_label: Label
var hunger_rate_label: Label
var thirst_rate_label: Label

func _ready():
	_create_rate_labels()
	
	# Find the player stats
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.player_stats:
			player_stats = player.player_stats
			connect_to_stats()

func _create_rate_labels():
	health_rate_label = _make_rate_label($VBoxContainer/HealthContainer)
	oxygen_rate_label = _make_rate_label($VBoxContainer/OxygenContainer)
	hunger_rate_label = _make_rate_label($VBoxContainer/HungerContainer)
	thirst_rate_label = _make_rate_label($VBoxContainer/ThirstContainer)

func _make_rate_label(container: HBoxContainer) -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 12)
	label.custom_minimum_size = Vector2(72, 0)
	label.modulate = Color(1, 1, 1, 0)
	container.add_child(label)
	return label

func connect_to_stats():
	if not player_stats:
		return

	# Connect to stat change signals
	player_stats.health_changed.connect(_on_health_changed)
	player_stats.oxygen_changed.connect(_on_oxygen_changed)
	player_stats.hunger_changed.connect(_on_hunger_changed)
	player_stats.thirst_changed.connect(_on_thirst_changed)
	
	player_stats.effects_changed.connect(_update_rate_labels)
	var timer = get_parent() as Timer
	if timer:
		timer.timeout.connect(_update_rate_labels)
	
	# Update initial values
	_on_health_changed(player_stats.current_health, player_stats.max_health)
	_on_oxygen_changed(player_stats.current_oxygen, player_stats.max_oxygen)
	_on_hunger_changed(player_stats.current_hunger, player_stats.max_hunger)
	_on_thirst_changed(player_stats.current_thirst, player_stats.max_thirst)

	_update_rate_labels()

func _on_health_changed(current: float, max_value: float):
	if health_bar and health_label:
		health_bar.max_value = max_value
		health_bar.value = current
		health_label.text = "Health: %.0f/%.0f" % [current, max_value]

func _on_oxygen_changed(current: float, max_value: float):
	if oxygen_bar and oxygen_label:
		oxygen_bar.max_value = max_value
		oxygen_bar.value = current
		oxygen_label.text = "Oxygen: %.0f/%.0f" % [current, max_value]
	_update_rate_labels()
	
func _on_hunger_changed(current: float, max_value: float):
	if hunger_bar and hunger_label:
		hunger_bar.max_value = max_value
		hunger_bar.value = current
		hunger_label.text = "Hunger: %.0f/%.0f" % [current, max_value]

func _on_thirst_changed(current: float, max_value: float):
	if thirst_bar and thirst_label:
		thirst_bar.max_value = max_value
		thirst_bar.value = current
		thirst_label.text = "Thirst: %.0f/%.0f" % [current, max_value]

func _update_rate_labels():
	if not player_stats:
		return
	var rates = player_stats.get_net_rates()
	var h  = rates["health_regen"] if rates["health_regen"] > 0.0 else rates["health"]
	var hu = rates["hunger_regen"] if rates["hunger_regen"] > 0.0 else rates["hunger"]
	var th = rates["thirst_regen"] if rates["thirst_regen"] > 0.0 else rates["thirst"]
	_apply_rate_label(health_rate_label, h,  player_stats.current_health >= player_stats.max_health)
	_apply_rate_label(oxygen_rate_label, rates["oxygen"], player_stats.current_oxygen >= player_stats.max_oxygen)
	_apply_rate_label(hunger_rate_label, hu, player_stats.current_hunger >= player_stats.max_hunger)
	_apply_rate_label(thirst_rate_label, th, player_stats.current_thirst >= player_stats.max_thirst)
	
func _apply_rate_label(label: Label, rate: float, at_max: bool):
	if abs(rate) < 0.01 or (rate > 0.0 and at_max):
		label.modulate = Color(1, 1, 1, 0)
		return
	label.modulate = Color(1, 1, 1, 1)
	label.text = "%s%.2f/s" % ["+" if rate > 0.0 else "", rate]
	label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4) if rate > 0.0 else Color(1.0, 0.5, 0.5))
