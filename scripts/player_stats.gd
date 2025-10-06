extends Node

class_name PlayerStats

signal health_changed(current: float, max_value: float)
signal oxygen_changed(current: float, max_value: float)
signal stamina_changed(current: float, max_value: float)
signal hunger_changed(current: float, max_value: float)
signal thirst_changed(current: float, max_value: float)
signal stat_depleted(stat_name: String)

# Base stats
@export  var max_health: float = 100.0
@export var max_oxygen: float = 100.0
@export var max_stamina: float = 100.0
@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0

# Current values
var current_health: float
var current_oxygen: float
var current_stamina: float
var current_hunger: float
var current_thirst: float

# Damage rates (per second)
@export var oxygen_damage_rate: float = 5.0
@export var hunger_damage_rate: float = 2.0
@export var thirst_damage_rate: float = 2.0

# Regeneration rates (per second)
@export var health_regen_rate: float = 0.2 # Well fed healing
@export var oxygen_regen_rate: float = 20.0 # When on surface
@export var stamina_regen_rate: float = 20.0 # When not sprinting
@export var hunger_regen_rate: float = 2.0 # When consuming standard food
@export var thirst_regen_rate: float = 2.0 # When consuming standard drinks

# Usage rates (per second)
@export var oxygen_usage_rate: float = 10.0 # When underwater
@export var stamina_usage_rate: float = 20.0
@export var hunger_usage_rate: float = 0.05
@export var thirst_usage_rate: float = 0.1

# Interval
@export var health_drain_interval: float = 1.0 # seconds between health loss

# Modifiers (multipliers applied to rates)
var health_regen_modifier: float = 1.0
var oxygen_usage_modifier: float = 1.0
var oxygen_regen_modifier: float = 1.0
var stamina_usage_modifier: float = 1.0
var hunger_regen_modifier: float = 1.0
var hunger_usage_modifier: float = 1.0
var thirst_regen_modifier: float = 1.0
var thirst_usage_modifier: float = 1.0

# Status tracking
var is_underwater: bool = false
var is_sprinting: bool = false
var is_stamina_depleted: bool = false
var is_oxygen_depleted: bool = false
var is_hunger_depleted: bool = false
var is_thirst_depleted: bool = false
var is_eating: bool = false
var is_drinking: bool = false
var is_healing: bool = false

# Timer
var health_drain_timer: float = 0.0

var eating_time_remaining: float = 0.0
var drinking_time_remaining: float = 0.0
var healing_time_remaining: float = 0.0
var stats_timer: Timer

func _ready():
	# Initialize stats to full
	current_health = max_health
	current_oxygen = max_oxygen
	current_stamina = max_stamina
	current_hunger = max_hunger
	current_thirst = max_thirst

	
func _process(delta):
	update_oxygen(delta)
	update_stamina(delta)


func update_oxygen(delta: float):
	if is_underwater:
		# Deplete oxygen when underwater
		var depletion = oxygen_usage_rate * oxygen_usage_modifier * delta
		modify_oxygen(-depletion)
	elif current_oxygen < max_oxygen:
		# Regenerate oxygen when on surface
		var regen = oxygen_regen_rate * oxygen_regen_modifier * delta
		modify_oxygen(regen)
		
func update_stamina(delta: float):
	if is_sprinting:
		# Deplete stamina when sprinting
		var usage = stamina_usage_rate * stamina_usage_modifier * delta
		modify_stamina(-usage)
	elif current_stamina < max_stamina:
		# Regenerate stamina when not sprinting
		modify_stamina(stamina_regen_rate * delta)

func update_hunger(delta: float):
	if is_eating:
		# Regenerate hunger when eating
		modify_hunger(hunger_regen_rate * hunger_regen_modifier * delta)
	elif current_hunger <= max_hunger:
		# Deplete hunger
		var usage = hunger_usage_rate * hunger_usage_modifier * delta
		modify_hunger(-usage)

func update_thirst(delta: float):
	if is_drinking:
		# Regenerate thirst when drinking
		modify_thirst(thirst_regen_rate * hunger_regen_modifier * delta)
	elif current_thirst <= max_thirst:
		# Deplete hunger
		var usage = thirst_usage_rate * hunger_usage_modifier * delta
		modify_thirst(-usage)

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


func modify_stamina(amount: float):
	var old_stamina = current_stamina
	current_stamina = clamp(current_stamina + amount, 0.0, max_stamina)

	if current_stamina != old_stamina:
		stamina_changed.emit(current_stamina, max_stamina)
	
	# Only emit stat_depleted once when stamina hits zero
	if current_stamina <= 0.0 and not is_stamina_depleted:
		stat_depleted.emit("stamina")
		is_stamina_depleted = true
	elif current_stamina > 0.0:
		is_stamina_depleted = false

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

func set_stamina_usage_modifier(modifier: float):
	stamina_usage_modifier = modifier

func set_hunger_usage_modifier(modifier: float):
	hunger_usage_modifier = modifier

func set_hunger_regen_modifier(modifier: float):
	hunger_regen_modifier = modifier

func set_thirst_usage_modifier(modifier: float):
	thirst_usage_modifier = modifier

func set_health_regen_modifier(modifier: float):
	health_regen_modifier = modifier

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

func get_hunger_percentage() -> float:
	return current_hunger / max_hunger

func get_thirst_percentage() -> float:
	return current_thirst / max_thirst

func reset_stats():
	current_health = max_health
	current_oxygen = max_oxygen
	current_stamina = max_stamina
	current_hunger = max_hunger
	current_thirst = max_thirst
	
	# Emit signals to update the UI
	health_changed.emit(current_health, max_health)
	oxygen_changed.emit(current_oxygen, max_oxygen)
	stamina_changed.emit(current_stamina, max_stamina)
	hunger_changed.emit(current_hunger, max_hunger)
	thirst_changed.emit(current_thirst, max_thirst)

func setup_timer(timer: Timer):
	stats_timer = timer
	if stats_timer:
		stats_timer.timeout.connect(_on_stats_timer_timeout)
		print("Timer setup complete")

func _on_stats_timer_timeout():
	handle_hunger_update()
	handle_thirst_update()
	handle_health_update()


# Eat food
func start_eating(duration: float):
	# Add to existing time
	is_eating = true
	eating_time_remaining += duration
	print("Added ", duration, " seconds of eating time. Total remaining: ", eating_time_remaining)

# Drink
func start_drinking(duration: float):
	# Add to existing time
	is_drinking = true
	drinking_time_remaining += duration
	print("Added ", duration, " seconds of drinking time. Total remaining: ", drinking_time_remaining)

func start_healing(duration: float):
	is_healing = true
	healing_time_remaining += duration
	print("Added ", duration, " seconds of healing time. Total remaining: ", healing_time_remaining)

func handle_health_update():
	# Handle bandage, medkit etc
	if current_health < max_health:
		if is_healing and healing_time_remaining > 0:
			modify_health(health_regen_rate * health_regen_modifier)
			healing_time_remaining -= stats_timer.wait_time
			if healing_time_remaining <= 0:
				is_healing = false
				healing_time_remaining = 0
				set_health_regen_modifier(1.0)
				print("Healing finished")
				
		# Handle well fed healing
		if current_hunger >= 80 and current_thirst >= 80:
			modify_health(health_regen_rate * health_regen_modifier)
		
	# Drain health if resource is depleted
	if current_oxygen <= 0.0:
		modify_health(-oxygen_damage_rate)
	if current_hunger <= 0.0:
		modify_health(-hunger_damage_rate)
	if current_thirst <= 0.0:
		modify_health(-thirst_damage_rate)
	
	

func handle_thirst_update():
	# Handle thirst and duration
	if is_drinking and drinking_time_remaining > 0:
		modify_thirst(thirst_regen_rate * thirst_regen_modifier)
		drinking_time_remaining -= stats_timer.wait_time
		if drinking_time_remaining <= 0:
			is_eating = false
			drinking_time_remaining = 0.0
			set_health_regen_modifier(1.0)
			print("Finished drinking")
	else:
		# Deplete thirst - fixed amount per timer tick
		modify_thirst(-thirst_usage_rate * thirst_usage_modifier)

func handle_hunger_update():
	# Handle eating and duration
	if is_eating and eating_time_remaining > 0:
		modify_hunger(hunger_regen_rate * hunger_regen_modifier)
		eating_time_remaining -= stats_timer.wait_time
		if eating_time_remaining <= 0:
			is_eating = false
			eating_time_remaining = 0.0
			set_hunger_regen_modifier(1.0)
			print("Finished eating")
	else:
		# Deplete hunger - fixed amount per timer tick
		modify_hunger(-hunger_usage_rate * hunger_usage_modifier)
