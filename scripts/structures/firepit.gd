extends GameObject

class_name Firepit

signal state_changed(new_state: int, description: String)
signal fuel_consumed(remaining_time: float)

@export var max_fuel: float = 300.0 # Max fuel storage

@onready var interactive_object: InteractiveObjectComponent

enum ObjectState { UNLIT, BURNING }
var state: int = ObjectState.UNLIT
var current_burn_time: float = 0.0  # Time left for current burning item
var cooking_slots: Array[Dictionary] = []  # Track what's cooking in each slot


func _init():
	name = "Firepit"
	description = "Simple stone firepit"
	category = "structure"
	craftable = true
	icon = load("res://assets/structures/firepit_unlit_01_64x64.png")
	craft_requirements = {"Simple Rock": 1}
	scene_path = "res://scenes/structures/firepit.tscn"
	placement_bottom_padding = -4.0  # Pixels to adjust bottom alignment


# Called when the node enters the scene tree for the first time.
func _ready():
	if animated_sprite:
		animated_sprite.play("unlit")
	
	state = ObjectState.UNLIT

	target_actions = ["harvest"]

	# Add interactive object component
	interactive_object = InteractiveObjectComponent.new()
	interactive_object.object_name = "Firepit"
	interactive_object.inventory_slots = 6
	interactive_object.accepted_categories = ["fuel", "food"]
	add_child(interactive_object)

	# Connect to ResourceManager for fuel consumption
	await get_tree().process_frame
	_connect_to_resource_manager()

	# Call parent _ready() which sets up hover detection
	super._ready()

func _connect_to_resource_manager():
	if ResourceManager.resource_timer:
		ResourceManager.resource_timer.timeout.connect(_on_fuel_tick)
		print("DEBUG: Successfully connected firepit to ResourceManager timer")
	else:
		print("DEBUG: ResourceManager not ready, retrying in 0.1 seconds...")
		await get_tree().create_timer(0.1).timeout
		_connect_to_resource_manager()


func get_hover_color() -> Color:
	if state == ObjectState.BURNING:
		return Color(1.3, 1.1, 0.9, 1.0)  # Orange/red tint for burning
	else:
		return Color(1.2, 1.2, 1.2, 1.0)  # Neutral bright tint for unlit

func is_interactable() -> bool:
	return true

# Interact action handler (for future use)
func interact():
	# Open the firepit inventory UI
	interactive_object.interact()

func start_burning_next_item():
	# Find the first available fuel item and start burning it
	# USE MODERN INVENTORY SYSTEM instead of legacy object_menu
	for i in range(interactive_object.inventory.size() - 1, -1, -1):
		var stack = interactive_object.inventory[i]
		if stack.item.category == "fuel":
			var fuel_per_item = 10.0 # Default
			if stack.item.has_method("get_fuel_value"):
				fuel_per_item = stack.item.get_fuel_value()
			elif stack.item.get("fuel_value"):
				fuel_per_item = stack.item.fuel_value
			else:
				print("Item is missing a fuel value, using default: ", fuel_per_item)
			
			var fuel_item_name = stack.item.name
			
			# Start burning this item
			current_burn_time = fuel_per_item
			
			# Remove one item from the stack using modern system
			interactive_object.remove_item(stack.item.name, 1)
			
			# Update UI if object menu is open
			var object_menus = get_tree().get_nodes_in_group("object_menu")
			for obj_menu in object_menus:
				if obj_menu.visible and obj_menu.current_object == self:
					obj_menu._refresh_displays()
					break
			
			print("Consumed ", fuel_item_name, " - burning for ", fuel_per_item, " seconds")
			return true
	
	# No fuel found
	current_burn_time = 0.0
	return false

#func start_burning_next_item():
	## Find the first available fuel item and start burning it
	#for slot in interactive_object.object_menu:
		#if not slot.is_empty() and slot.item.category == "fuel":
			#var fuel_per_item = 10.0 # Default
			#if slot.item.has_method("get_fuel_value"):
				#fuel_per_item = slot.item.get_fuel_value()
			#elif slot.item.get("fuel_value"):
				#fuel_per_item = slot.item.fuel_value
			#else:
				#print("Item is missing a fuel value, using default: ", fuel_per_item)
			#
			## Store item name in case case it gets removed
			#var fuel_item_name = slot.item.name
			#
			## Start burning this item
			#current_burn_time = fuel_per_item
			#slot.quantity -= 1
			#if slot.quantity <= 0:
				#slot.clear()
				#
			## Update UI if object menu is open
			#var object_menus = get_tree().get_nodes_in_group("object_menu")
			#for obj_menu in object_menus:
				#if obj_menu.visible and obj_menu.current_object == self:
					## Find which slot index we just modified
					#var slot_index = interactive_object.object_menu.find(slot)
					#if slot_index >= 0:
						#obj_menu.update_object_slot_display(slot_index)
					#break
					#
			#print("Consumed ", fuel_item_name, " - burning for ", fuel_per_item, " seconds")
			#return true
	#
	## No fuel found
	#current_burn_time = 0.0
	#return false

func light_fire():
	if not start_burning_next_item():
		print("Cannot light fire - no fuel!")
		return
	
	state = ObjectState.BURNING
	if animated_sprite:
		animated_sprite.play("burning")
	
	# Emit state change signal
	state_changed.emit(state, get_current_state_description())
	print("Fire lit!")

func _on_fuel_tick():
	if state == ObjectState.BURNING and current_burn_time > 0:
		var time_elapsed = ResourceManager.resource_timer.wait_time
		consume_fuel_time(time_elapsed)
		# Process cooking for all items
		process_cooking(time_elapsed)

func consume_fuel_time(amount: float):
	current_burn_time -= amount
	
	# Emit signal for UI updates
	fuel_consumed.emit(current_burn_time)
	
	# If current item burned out, try to start burning next item
	if current_burn_time <= 0:
		if not start_burning_next_item():
			# No more fuel - extinguish fire
			extinguish()
		# If there was remaining time to consume, apply it to new item
		elif current_burn_time < 0:
			consume_fuel_time(abs(current_burn_time))

func process_cooking(delta_time: float):
	# Go through each stack in the modern inventory system
	for i in range(interactive_object.inventory.size()):
		if i >= interactive_object.inventory.size():
			continue
			
		var stack = interactive_object.inventory[i]
		
		# Skip empty slots or non-cookable items
		if not stack or not stack.item.is_cookable:
			continue
		
		# Initialize cooking data for this slot if needed
		if cooking_slots.size() <= i:
			cooking_slots.resize(i + 1)
		
		if cooking_slots[i] == null:
			cooking_slots[i] = {}
		
		# Start cooking if not already cooking
		if not cooking_slots[i].has("cook_progress"):
			cooking_slots[i]["cook_progress"] = 0.0
			cooking_slots[i]["total_cook_time"] = stack.item.cook_time
			print("Started cooking ", stack.item.name, " (", stack.item.cook_time, "s)")
		
		# Update cooking progress
		cooking_slots[i]["cook_progress"] += delta_time
		
		# Check if item is done cooking
		if cooking_slots[i]["cook_progress"] >= cooking_slots[i]["total_cook_time"]:
			cook_item_complete(i)

## Add this new function for cooking logic:
#func process_cooking(delta_time: float):
	## Go through each slot in the firepit inventory
	#for i in range(interactive_object.object_menu.size()):
		#var slot = interactive_object.object_menu[i]
		#
		## Skip empty slots or non-cookable items
		#if slot.is_empty() or not slot.item.is_cookable:
			#continue
		#
		## Initialize cooking data for this slot if needed
		#if cooking_slots.size() <= i:
			#cooking_slots.resize(i + 1)
		#
		#if cooking_slots[i] == null:
			#cooking_slots[i] = {}
		#
		## Start cooking if not already cooking
		#if not cooking_slots[i].has("cook_progress"):
			#cooking_slots[i]["cook_progress"] = 0.0
			#cooking_slots[i]["total_cook_time"] = slot.item.cook_time
			#print("Started cooking ", slot.item.name, " (", slot.item.cook_time, "s)")
		#
		## Update cooking progress
		#cooking_slots[i]["cook_progress"] += delta_time
		#
		## Check if item is done cooking
		#if cooking_slots[i]["cook_progress"] >= cooking_slots[i]["total_cook_time"]:
			#cook_item_complete(i)

# Add this function to handle completed cooking:
#func cook_item_complete(slot_index: int):
	#var slot = interactive_object.object_menu[slot_index]
	#if slot.is_empty():
		#return
	#
	#var raw_item = slot.item
	#var cooked_item_name = raw_item.cooked_result_item_name
	#
	#if cooked_item_name == "":
		#print("Warning: ", raw_item.name, " has no cooked result defined!")
		#return
	#
	## Get the cooked item from inventory manager
	#if GameObjectsDatabase.game_objects_database.has(cooked_item_name):
		#var cooked_item = GameObjectsDatabase.game_objects_database[cooked_item_name]
		#
		## Replace the raw item with cooked item
		#slot.item = cooked_item
		#print("Finished cooking ", raw_item.name, " -> ", cooked_item.name)
		#
		## Clear cooking progress
		#if cooking_slots.size() > slot_index:
			#cooking_slots[slot_index] = {}
		#
		## Update UI if object menu is open
		#var object_menus = get_tree().get_nodes_in_group("object_menu")
		#for obj_menu in object_menus:
			#if obj_menu.visible and obj_menu.current_object == self:
				#obj_menu.update_object_slot_display(slot_index)
				#break
	#else:
		#print("Error: Cooked item '", cooked_item_name, "' not found in item database!")

func cook_item_complete(slot_index: int):
	if slot_index >= interactive_object.inventory.size():
		return
		
	var stack = interactive_object.inventory[slot_index]
	if not stack:
		return
	
	var raw_item = stack.item
	var cooked_item_name = raw_item.cooked_result_item_name
	
	if cooked_item_name == "":
		print("Warning: ", raw_item.name, " has no cooked result defined!")
		return
	
	# Get the cooked item from database
	if GameObjectsDatabase.game_objects_database.has(cooked_item_name):
		var cooked_item = GameObjectsDatabase.game_objects_database[cooked_item_name]
		
		# Replace the raw item with cooked item in the modern inventory
		stack.item = cooked_item
		print("Finished cooking ", raw_item.name, " -> ", cooked_item.name)
		
		# Clear cooking progress
		if cooking_slots.size() > slot_index:
			cooking_slots[slot_index] = {}
		
		# Update UI if object menu is open
		var object_menus = get_tree().get_nodes_in_group("object_menu")
		for obj_menu in object_menus:
			if obj_menu.visible and obj_menu.current_object == self:
				obj_menu._refresh_displays()
				break
	else:
		print("Error: Cooked item '", cooked_item_name, "' not found in item database!")

func set_cooldown():
	pass

func extinguish():
	if state == ObjectState.BURNING:
		print("Firepit has burned out!")
		state = ObjectState.UNLIT
		if animated_sprite:
			animated_sprite.play("unlit")
		
		# Emit state change signal
		state_changed.emit(state, get_current_state_description())

# Action system implementation
func get_available_actions() -> Array[String]:
	if state == ObjectState.BURNING:
		return ["Extinguish"]
	else:
		return ["Light Fire"]

func perform_action(action_name: String):
	match action_name:
		"Light Fire":
			light_fire()
		"Extinguish":
			extinguish()
		_:
			print("Unknown action: ", action_name, " for firepit")

func get_current_state_description() -> String:
	match state:
		ObjectState.BURNING:
			var total_time = get_total_fuel_time()
			return "Burning (" + str(int(total_time)) + "s total remaining)"
		ObjectState.UNLIT:
			return "Unlit"
		_:
			return "Unknown"

func get_total_fuel_time() -> float:
	"""Calculate total remaining fuel time including current burn + queued items"""
	var total_time = current_burn_time
	
	# Add fuel from items in inventory
	for i in range(interactive_object.inventory.size()):
		var stack = interactive_object.inventory[i]
		if stack and stack.item.category == "fuel":
			var fuel_per_item = 10.0 # Default
			if stack.item.has_method("get_fuel_value"):
				fuel_per_item = stack.item.get_fuel_value()
			elif stack.item.get("fuel_value"):
				fuel_per_item = stack.item.fuel_value
			
			total_time += fuel_per_item * stack.quantity
	
	return total_time
