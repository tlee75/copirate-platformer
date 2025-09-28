extends Node

class_name PlayerStats

signal health_changed(current: float, max_value: float)
signal oxygen_changed(current: float, max_value: float)
signal stamina_changed(current: float, max_value: float)
signal stat_depleted(stat_name: String)

# Base stats
@export  var max_health: float = 100.0
@export var max_oxygen: float = 100.0
@export var max_stamina: float = 100.0

# Current values
var current_health: float
var current_oxygen: float
var current_stamina: float

# Regeneration rates (per second)
@export var oxygen_regen_rate: float = 20.0 # When on surface
@export var oxygen_depletion_rate: float = 10.0 # When underwater
@export var stamina_regen_rate: float = 25.0 # When not sprinting

# Modifiers (multipliers applied to rates)
var oxygen_depletion_modifier: float = 1.0
var oxygen_regen_modifier: float = 1.0
var stamina_usage_modifier: float = 1.0

# Status tracking
var is_underwater: bool = false
var is_sprinting: bool = false
var stamina_depleted: bool = false

func _ready():
	# Initialize stats to full
	current_health = max_health
	current_oxygen = max_oxygen
	current_stamina = max_stamina
	
func _process(delta):
	update_oxygen(delta)
	update_stamina(delta)
	
func update_oxygen(delta: float):
	if is_underwater:
		# Deplete oxygen when underwater
		var depletion = oxygen_depletion_rate * oxygen_depletion_modifier * delta
		modify_oxygen(-depletion)
	else:
		# Regenerate oxygen when on surface
		var regen = oxygen_regen_rate * oxygen_regen_modifier * delta
		modify_oxygen(regen)
		
func update_stamina(delta: float):
	if is_sprinting:
		# Deplete stamina when sprinting
		var usage = 20.0 * stamina_usage_modifier * delta
		modify_stamina(-usage)
	else:
		# Regenerate stamina when not sprinting
		modify_stamina(stamina_regen_rate * delta)

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

	if current_oxygen <= 0.0:
		stat_depleted.emit("oxygen")

func modify_stamina(amount: float):
	var old_stamina = current_stamina
	current_stamina = clamp(current_stamina + amount, 0.0, max_stamina)

	if current_stamina != old_stamina:
		stamina_changed.emit(current_stamina, max_stamina)
	
	# Only emit stat_depleted once when stamina hits zero
	if current_stamina <= 0.0 and not stamina_depleted:
		stat_depleted.emit("stamina")
		stamina_depleted = true
	elif current_stamina > 0.0:
		stamina_depleted = false

# Modifier functions for items/effects
func set_oxygen_depletion_modifier(modifier: float):
	oxygen_depletion_modifier = modifier

func set_oxygen_regen_modifier(modifier: float):
	oxygen_regen_modifier = modifier

func set_stamina_usage_modifier(modifier: float):
	stamina_usage_modifier = modifier

# Status update functions (called by player)
func set_underwater_status(underwater: bool):
	is_underwater = underwater

func set_sprinting_status(sprinting: bool):
	is_sprinting = sprinting

# Getter functions
func get_health_percentage() -> float:
	return current_health / max_health

func get_oxygen_percentage() -> float:
	return current_oxygen / max_oxygen

func get_stamina_percentage() -> float:
	return current_stamina / max_stamina
