extends Node

class_name PlayerStats

signal health_changed(current: float, max_value: float)
signal oxygen_changed(current: float, max_value: float)
signal hunger_changed(current: float, max_value: float)
signal thirst_changed(current: float, max_value: float)
signal stat_depleted(stat_name: String)
signal effects_changed

# Base stats
@export  var max_health: float = 100.0
@export var max_oxygen: float = 100.0
@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0

# Damage rates (per second)
@export var oxygen_damage_rate: float = 5.0
@export var hunger_damage_rate: float = 2.0
@export var thirst_damage_rate: float = 2.0

# Regeneration rates (per second)
@export var health_regen_rate: float = 0.2 # Well fed healing
@export var oxygen_regen_rate: float = 20.0 # When on surface
@export var hunger_regen_rate: float = 2.0 # When consuming standard food
@export var thirst_regen_rate: float = 2.0 # When consuming standard drinks

# Usage rates (per second)
@export var oxygen_usage_rate: float = 10.0 # When underwater
@export var hunger_usage_rate: float = 0.0278
@export var thirst_usage_rate: float = 0.0556

# Interval
@export var health_drain_interval: float = 1.0 # seconds between health loss

# Current values
var current_health: float
var current_oxygen: float
var current_hunger: float
var current_thirst: float

# Modifiers (multipliers applied to rates)
var oxygen_usage_modifier: float = 1.0
var oxygen_regen_modifier: float = 1.0

var hunger_usage_modifier: float = 1.0
var thirst_usage_modifier: float = 1.0

# Status tracking
var is_underwater: bool = false
var is_oxygen_depleted: bool = false
var is_hunger_depleted: bool = false
var is_thirst_depleted: bool = false

var active_effects: Array = []
var stats_timer: Timer

func _ready():
	# Initialize stats to full
	current_health = max_health
	current_oxygen = max_oxygen
	current_hunger = max_hunger
	current_thirst = max_thirst

	
func _process(delta):
	update_oxygen(delta)

func update_oxygen(delta: float):
	if is_underwater:
		# Deplete oxygen when underwater
		var depletion = oxygen_usage_rate * oxygen_usage_modifier * delta
		modify_oxygen(-depletion)
	elif current_oxygen < max_oxygen:
		# Regenerate oxygen when on surface
		var regen = oxygen_regen_rate * oxygen_regen_modifier * delta
		modify_oxygen(regen)

# Core modification functions
func modify_health(amount: float):
	var old_health = current_health
	current_health = clamp(current_health + amount, 0.0, max_health)
	
	if current_health != old_health:
		health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0:
		stat_depleted.emit("health")

func modify_oxygen(amount: float):
	var old_oxygen = current_oxygen
	current_oxygen = clamp(current_oxygen + amount, 0.0, max_oxygen)

	if current_oxygen != old_oxygen:
		oxygen_changed.emit(current_oxygen, max_oxygen)

	# Only emit stat_depleted once when hunger hits zero
	if current_oxygen <= 0.0 and not is_oxygen_depleted:
		stat_depleted.emit("oxygen")
		is_oxygen_depleted = true
	elif current_oxygen > 0.0:
		is_oxygen_depleted = false

func modify_hunger(amount: float):
	var old_hunger = current_hunger
	current_hunger = clamp(current_hunger + amount, 0.0, max_hunger)

	if current_hunger != old_hunger:
		hunger_changed.emit(current_hunger, max_hunger)
	
	# Only emit stat_depleted once when hunger hits zero
	if current_hunger <= 0.0 and not is_hunger_depleted:
		stat_depleted.emit("hunger")
		is_hunger_depleted = true
	elif current_hunger > 0.0:
		is_hunger_depleted = false

func modify_thirst(amount: float):
	var old_thirst = current_thirst
	current_thirst = clamp(current_thirst + amount, 0.0, max_hunger)

	if current_thirst != old_thirst:
		thirst_changed.emit(current_thirst, max_thirst)
	
	# Only emit stat_depleted once when thirst hits zero
	if current_thirst <= 0.0 and not is_thirst_depleted:
		stat_depleted.emit("thirst")
		is_thirst_depleted = true
	elif current_thirst > 0.0:
		is_thirst_depleted = false

# Modifier functions for items/effects
func set_oxygen_depletion_modifier(modifier: float):
	oxygen_usage_modifier = modifier

func set_oxygen_regen_modifier(modifier: float):
	oxygen_regen_modifier = modifier

func set_hunger_usage_modifier(modifier: float):
	hunger_usage_modifier = modifier

func set_thirst_usage_modifier(modifier: float):
	thirst_usage_modifier = modifier

# Status update functions (called by player)
func set_underwater_status(underwater: bool):
	is_underwater = underwater

# Getter functions
func get_health_percentage() -> float:
	return current_health / max_health

func get_oxygen_percentage() -> float:
	return current_oxygen / max_oxygen

func get_hunger_percentage() -> float:
	return current_hunger / max_hunger

func get_thirst_percentage() -> float:
	return current_thirst / max_thirst

func reset_stats():
	current_health = max_health
	current_oxygen = max_oxygen
	current_hunger = max_hunger
	current_thirst = max_thirst
	
	# Emit signals to update the UI
	health_changed.emit(current_health, max_health)
	oxygen_changed.emit(current_oxygen, max_oxygen)
	hunger_changed.emit(current_hunger, max_hunger)
	thirst_changed.emit(current_thirst, max_thirst)
	
	active_effects.clear()

func setup_timer(timer: Timer):
	stats_timer = timer
	if stats_timer:
		stats_timer.timeout.connect(_on_stats_timer_timeout)
		print("Timer setup complete")

func _on_stats_timer_timeout():
	handle_consumption_update()
	handle_health_update()

func handle_health_update():
	# Well fed passive healing
	if current_health < max_health and current_hunger >= 80 and current_thirst >= 80:
		modify_health(health_regen_rate)
	
	# Drain health if resource is depleted
	if current_oxygen <= 0.0:
		modify_health(-oxygen_damage_rate)
	if current_hunger <= 0.0:
		modify_health(-hunger_damage_rate)
	if current_thirst <= 0.0:
		modify_health(-thirst_damage_rate)

func get_net_rates() -> Dictionary:
	var wait = stats_timer.wait_time if stats_timer else 1.0

	var hunger_regen = 0.0
	var thirst_regen = 0.0
	var health_regen = 0.0
	for effect in active_effects:
		hunger_regen += effect["hunger_per_tick"]
		thirst_regen += effect["thirst_per_tick"]
		health_regen += effect["health_per_tick"]

	var net_hunger = (hunger_regen - hunger_usage_rate * hunger_usage_modifier) / wait
	var net_thirst = (thirst_regen - thirst_usage_rate * thirst_usage_modifier) / wait

	var health_drain = 0.0
	if current_oxygen <= 0.0: health_drain += oxygen_damage_rate
	if current_hunger <= 0.0: health_drain += hunger_damage_rate
	if current_thirst <= 0.0: health_drain += thirst_damage_rate
	var well_fed = health_regen_rate if (current_health < max_health and current_hunger >= 80.0 and current_thirst >= 80.0) else 0.0
	var net_health = (health_regen + well_fed - health_drain) / wait

	var net_oxygen = 0.0
	if is_underwater:
		net_oxygen = -(oxygen_usage_rate * oxygen_usage_modifier)
	elif current_oxygen < max_oxygen:
		net_oxygen = oxygen_regen_rate * oxygen_regen_modifier

	return {
		"health": net_health,
		"health_regen": health_regen / wait,
		"oxygen": net_oxygen,
		"hunger": net_hunger,
		"hunger_regen": hunger_regen / wait,
		"thirst": net_thirst,
		"thirst_regen": thirst_regen / wait,
	}

func add_consumption_effect(hunger_per_tick: float, thirst_per_tick: float, health_per_tick: float, ticks: int):
	active_effects.append({
		"hunger_per_tick": hunger_per_tick,
		"thirst_per_tick": thirst_per_tick,
		"health_per_tick": health_per_tick,
		"ticks_remaining": ticks
	})
	effects_changed.emit()

func handle_consumption_update():
	var total_hunger_regen = 0.0
	var total_thirst_regen = 0.0
	var total_health_regen = 0.0

	var i = active_effects.size() - 1
	while i >= 0:
		var effect = active_effects[i]
		total_hunger_regen += effect["hunger_per_tick"]
		total_thirst_regen += effect["thirst_per_tick"]
		total_health_regen += effect["health_per_tick"]
		effect["ticks_remaining"] -= 1
		if effect["ticks_remaining"] <= 0:
			active_effects.remove_at(i)
		i -= 1

	# Usage always applies
	modify_hunger(-hunger_usage_rate * hunger_usage_modifier)
	modify_thirst(-thirst_usage_rate * thirst_usage_modifier)

	# Regen from active effects stacks on top
	if total_hunger_regen != 0.0:
		modify_hunger(total_hunger_regen)
	if total_thirst_regen != 0.0:
		modify_thirst(total_thirst_regen)
	if total_health_regen != 0.0:
		modify_health(total_health_regen)

func debug_modify_health(amount: float = 10.0):
	"""Debug: Modify health (positive amount heals, negative damages)"""
	modify_health(amount)
	print("DEBUG: Health changed by ", amount, " - Now: ", current_health, "/", max_health)

func debug_modify_thirst(amount: float = 10.0):
	"""Debug: Modify thirst (positive amount adds, negative removes)"""
	modify_thirst(amount)
	print("DEBUG: Thirst changed by ", amount, " - Now: ", current_thirst, "/", max_thirst)

func debug_modify_hunger(amount: float = 10.0):
	"""Debug: Modify hunger (positive amount adds, negative removes)"""
	modify_hunger(amount)
	print("DEBUG: Hunger changed by ", amount, " - Now: ", current_hunger, "/", max_hunger)

func debug_kill_player():
	"""Debug: Set health to 0 to test death"""
	current_health = 0.0
	health_changed.emit(current_health, max_health)
	stat_depleted.emit("health")
	print("DEBUG: Player killed for testing")
