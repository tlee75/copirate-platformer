extends Node2D

@export var extinguish_time: float = 30.0 
@export var max_fuel: float = 300.0 # Max fuel storage

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactive_object: InteractiveObject

enum ObjectState { UNLIT, BURNING }
var state: int = ObjectState.UNLIT
var fuel_remaining: float = 0.0
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
	await get_tree().process_frame
	resource_manager = get_tree().get_first_node_in_group("resource_manager")
	if resource_manager:
		resource_manager.resource_timer.timeout.connect(_on_fuel_tick)
	
	# Connect to inventory changes
	interactive_object.inventory_changed.connect(_on_firepit_inventory_changed)
		
	print("Firepit ready - Fuel: ", fuel_remaining, "/", max_fuel)

func is_interactable() -> bool:
	return true

# Interact action handler (for future use)
func interact():
	# Open the firepit inventory UI
	interactive_object.interact()

func _on_firepit_inventory_changed():
	# Recalculate fuel when inventory changes
	calculate_fuel_from_inventory()

func calculate_fuel_from_inventory():
	var total_fuel = 0.0
	
	for slot in interactive_object.object_inventory:
		if not slot.is_empty() and slot.item.category == "fuel":
			var fuel_per_item = 10.0 # Default
			if slot.item.has_method("get_fuel_value"):
				fuel_per_item = slot.item.get_fuel_value()
			elif slot.item.get("fuel_value"):
				fuel_per_item = slot.item.fuel_value
			
			total_fuel += fuel_per_item * slot.quantity
	fuel_remaining = min(total_fuel, max_fuel)
	print("Firepit fuel updated: ", fuel_remaining, "/", max_fuel, " seconds")

func light_fire():
	if fuel_remaining <= 0:
		print("Cannot light fire - no fuel!")
		return
	
	state = ObjectState.BURNING
	if animated_sprite:
		animated_sprite.play("burning")
	
	print("Fire lit!")

func _on_fuel_tick():
	if state == ObjectState.BURNING and fuel_remaining > 0:
		var fuel_consumed = resource_manager.resource_timer.wait_time
		consume_fuel_from_inventory(fuel_consumed)

func consume_fuel_from_inventory(amount: float):
	var remaining_to_consume = amount
	
	# Consume fuel from inventory slots
	for slot in interactive_object.object_inventory:
		if slot.is_empty() or slot.item.category != "fuel":
			continue
		
		var fuel_per_item = 10
		if slot.item.get("fuel_value"):
			fuel_per_item = slot.item.fuel_value
		
		var fuel_from_this_slot = fuel_per_item * slot.quantity
		
		if fuel_from_this_slot <= remaining_to_consume:
			# Consume entire stack
			remaining_to_consume -= fuel_from_this_slot
			slot.clear()
		else:
			# Consume partial stack
			var items_to_consume = remaining_to_consume / fuel_per_item
			slot.quantity -= ceil(items_to_consume)
			remaining_to_consume = 0
		
		if remaining_to_consume <=0:
			break
	# Update fuel display
	calculate_fuel_from_inventory()
	
	# Check if fire should go out
	if fuel_remaining <=0:
		extinguish()
			
func set_cooldown():
	pass

func extinguish():
	if state == ObjectState.BURNING:
		print("Firepit has burned out!")
		state = ObjectState.UNLIT
		if animated_sprite:
			animated_sprite.play("unlit")
