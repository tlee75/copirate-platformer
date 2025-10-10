extends Node2D

@export var max_fuel: float = 300.0 # Max fuel storage

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactive_object: InteractiveObject

enum ObjectState { UNLIT, BURNING }
var state: int = ObjectState.UNLIT
var current_burn_time: float = 0.0  # Time left for current burning item
var resource_manager: ResourceManager

# Called when the node enters the scene tree for the first time.
func _ready():
	if animated_sprite:
		animated_sprite.play("unlit")
	
	state = ObjectState.UNLIT

	# Add interactive object component
	interactive_object = InteractiveObject.new()
	interactive_object.object_name = "Firepit"
	interactive_object.inventory_slots = 6
	interactive_object.accepted_categories = ["fuel"] # Only accept fuel items
	add_child(interactive_object)

	# Connect to ResourceManager for fuel consumption
	# Connect to ResourceManager for fuel consumption (with retry)
	await get_tree().process_frame
	_connect_to_resource_manager()

func _connect_to_resource_manager():
	resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if resource_manager and resource_manager.resource_timer:
		resource_manager.resource_timer.timeout.connect(_on_fuel_tick)
		print("DEBUG: Successfully connected firepit to ResourceManager timer")
	else:
		print("DEBUG: ResourceManager not ready, retrying in 0.1 seconds...")
		await get_tree().create_timer(0.1).timeout
		_connect_to_resource_manager()

func is_interactable() -> bool:
	return true

# Interact action handler (for future use)
func interact():
	# Open the firepit inventory UI
	interactive_object.interact()

func _on_firepit_inventory_changed():
	# If fire is burning but no current burn time, try to start burning something
	if state == ObjectState.BURNING and current_burn_time <= 0:
		if not start_burning_next_item():
			extinguish()

func start_burning_next_item():
	# Find the first available fuel item and start burning it
	for slot in interactive_object.object_menu:
		if not slot.is_empty() and slot.item.category == "fuel":
			var fuel_per_item = 10.0 # Default
			if slot.item.has_method("get_fuel_value"):
				fuel_per_item = slot.item.get_fuel_value()
			elif slot.item.get("fuel_value"):
				fuel_per_item = slot.item.fuel_value
			
			# Start burning this item
			current_burn_time = fuel_per_item
			slot.quantity -= 1
			if slot.quantity <= 0:
				slot.clear()
			
			print("Consumed ", slot.item.name if slot.item else "fuel item", " - burning for ", fuel_per_item, " seconds")
			return true
	
	# No fuel found
	current_burn_time = 0.0
	return false

func light_fire():
	if not start_burning_next_item():
		print("Cannot light fire - no fuel!")
		return
	
	state = ObjectState.BURNING
	if animated_sprite:
		animated_sprite.play("burning")
	
	print("Fire lit!")

func _on_fuel_tick():
	if state == ObjectState.BURNING and current_burn_time > 0:
		var time_elapsed = resource_manager.resource_timer.wait_time
		consume_fuel_time(time_elapsed)

func consume_fuel_time(amount: float):
	current_burn_time -= amount
	
	# If current item burned out, try to start burning next item
	if current_burn_time <= 0:
		if not start_burning_next_item():
			# No more fuel - extinguish fire
			extinguish()
		# If there was remaining time to consume, apply it to new item
		elif current_burn_time < 0:
			consume_fuel_time(abs(current_burn_time))
			
func set_cooldown():
	pass

func extinguish():
	if state == ObjectState.BURNING:
		print("Firepit has burned out!")
		state = ObjectState.UNLIT
		if animated_sprite:
			animated_sprite.play("unlit")
