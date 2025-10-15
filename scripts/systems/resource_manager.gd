extends Node

var regenerating_resources: Array[Dictionary] = []
var resource_timer: Timer

signal resource_regenerated(resource: Node2D)

func setup_timer(timer: Timer):
	resource_timer = timer
	if resource_timer:
		resource_timer.timeout.connect(_on_timer_tick)
		print("ResourceManager connected to timer")

func register_resource_regeneration(resource: Node2D, duration: float):
	if not is_instance_valid(resource):
		return
	
	# Check if resource is already regenerating
	for entry in regenerating_resources:
		if entry.resource == resource:
			print("Resource already regenerating: ", resource.name)
			return
	
	var regen_data = {
		"resource": resource,
		"time_remaining": duration,
		"original_duration": duration
	}
	
	regenerating_resources.append(regen_data)
	print("Registered ", resource.name, " for regeneration in ", duration, " seconds")

func _on_timer_tick():
	# Process regeneration for all registered resources
	for i in range(regenerating_resources.size() - 1, -1, -1): # Reverse iteration for safe removal
		var entry = regenerating_resources[i]
		var resource = entry.resource
		# Check if resource still exists
		if not is_instance_valid(resource):
			regenerating_resources.remove_at(i)
			continue
		
		# Countdown timer
		entry.time_remaining -= resource_timer.wait_time
		
		if entry.time_remaining <= 0:
			# Regeneration complete
			if resource.has_method("regenerate"):
				resource.regenerate()
				resource_regenerated.emit(resource)
				print("Regenerated: ", resource.name)
			else:
				print("Warning: ", resource.name, " doesn't have regenerate() method")
			
			# Remove from regenerating list
			regenerating_resources.remove_at(i)

func get_regeneration_progress(resource: Node2D) -> float:
	# Returns progress from 0.0 (just started) to 1.0 (complete)
	for entry in regenerating_resources:
		if entry.resource == resource:
			return 1.0 - (entry.time_remaining / entry.original_duration)
	return 1.0 # Not regenerating = complete

func is_regenerating(resource: Node2D) -> bool:
	for entry in regenerating_resources:
		if entry.resource == resource:
			return true
	return false

func cancel_regeneration(resource: Node2D):
	for i in range(regenerating_resources.size() -1, -1, -1):
		if regenerating_resources[i].resource == resource:
			regenerating_resources.remove_at(i)
			print("Cancelled regeneration for: ", resource.name)
			break
