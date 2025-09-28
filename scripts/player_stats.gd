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
aa
