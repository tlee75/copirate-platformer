extends Control

@onready var health_bar: ProgressBar = $VBoxContainer/HealthContainer/HealthBar
@onready var oxygen_bar: ProgressBar = $VBoxContainer/OxygenContainer/OxygenBar
@onready var stamina_bar: ProgressBar = $VBoxContainer/StaminaContainer/StaminaBar
@onready var hunger_bar: ProgressBar = $VBoxContainer/HungerContainer/HungerBar
@onready var thirst_bar: ProgressBar = $VBoxContainer/ThirstContainer/ThirstBar

@onready var health_label: Label = $VBoxContainer/HealthContainer/HealthLabel
@onready var oxygen_label: Label = $VBoxContainer/OxygenContainer/OxygenLabel
@onready var stamina_label: Label = $VBoxContainer/StaminaContainer/StaminaLabel
@onready var hunger_label: Label = $VBoxContainer/HungerContainer/HungerLabel
@onready var thirst_label: Label = $VBoxContainer/ThirstContainer/ThirstLabel

var player_stats: PlayerStats

func _ready():		
	# Find the player stats
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.player_stats:
			player_stats = player.player_stats
			connect_to_stats()



func connect_to_stats():
	if not player_stats:
		return

	# Connect to stat change signals
	player_stats.health_changed.connect(_on_health_changed)
	player_stats.oxygen_changed.connect(_on_oxygen_changed)
	player_stats.stamina_changed.connect(_on_stamina_changed)
	player_stats.hunger_changed.connect(_on_hunger_changed)
	player_stats.thirst_changed.connect(_on_thirst_changed)
	
	# Update initial values
	_on_health_changed(player_stats.current_health, player_stats.max_health)
	_on_oxygen_changed(player_stats.current_oxygen, player_stats.max_oxygen)
	_on_stamina_changed(player_stats.current_stamina, player_stats.max_stamina)
	_on_hunger_changed(player_stats.current_hunger, player_stats.max_hunger)
	_on_thirst_changed(player_stats.current_thirst, player_stats.max_thirst)

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

func _on_stamina_changed(current: float, max_value: float):
	if stamina_bar and stamina_label:
		stamina_bar.max_value = max_value
		stamina_bar.value = current
		stamina_label.text = "Stamina: %.0f/%.0f" % [current, max_value]

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
