extends GameStructure

class_name Firepit

@export var max_fuel: float = 300.0 # Max fuel storage

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactive_object: InteractiveObject

enum ObjectState { UNLIT, BURNING }
var state: int = ObjectState.UNLIT
var current_burn_time: float = 0.0  # Time left for current burning item
var cooking_slots: Array[Dictionary] = []  # Track what's cooking in each slot



func _init():
	name = "Firepit"
	category = "structure"
	craftable = true
	icon = load("res://assets/structures/firepit_unlit_01.png")
	craft_requirements = {"Simple Rock": 1}
	scene_path = "res://scenes/structures/firepit.tscn"
	placement_bottom_padding = -4.0  # Pixels to adjust bottom alignment


# Called when the node enters the scene tree for the first time.
func _ready():
	if animated_sprite:
		animated_sprite.play("unlit")
	
	state = ObjectState.UNLIT

	# Add interactive object component
	interactive_object = InteractiveObject.new()
	interactive_object.object_name = "Firepit"
	interactive_object.inventory_slots = 6
	interactive_object.accepted_categories = ["fuel", "food"]
	add_child(interactive_object)

	# Connect to ResourceManager for fuel consumption
	# Connect to ResourceManager for fuel consumption (with retry)
	await get_tree().process_frame
	_connect_to_resource_manager()

func _connect_to_resource_manager():
	if ResourceManager.resource_timer:
		ResourceManager.resource_timer.timeout.connect(_on_fuel_tick)
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

func start_burning_next_item():
	# Find the first available fuel item and start burning it
	for slot in interactive_object.object_menu:
		if not slot.is_empty() and slot.item.category == "fuel":
			var fuel_per_item = 10.0 # Default
			if slot.item.has_method("get_fuel_value"):
				fuel_per_item = slot.item.get_fuel_value()
			elif slot.item.get("fuel_value"):
				fuel_per_item = slot.item.fuel_value
			else:
				print("Item is missing a fuel value, using default: ", fuel_per_item)
			
			# Store item name in case case it gets removed
			var fuel_item_name = slot.item.name
			
			# Start burning this item
			current_burn_time = fuel_per_item
			slot.quantity -= 1
			if slot.quantity <= 0:
				slot.clear()
				
			# Update UI if object menu is open
			var object_menus = get_tree().get_nodes_in_group("object_menu")
			for obj_menu in object_menus:
				if obj_menu.visible and obj_menu.current_object == self:
					# Find which slot index we just modified
					var slot_index = interactive_object.object_menu.find(slot)
					if slot_index >= 0:
						obj_menu.update_object_slot_display(slot_index)
					break
					
			print("Consumed ", fuel_item_name, " - burning for ", fuel_per_item, " seconds")
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
		var time_elapsed = ResourceManager.resource_timer.wait_time
		consume_fuel_time(time_elapsed)
		# Process cooking for all items
		process_cooking(time_elapsed)

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

# Add this new function for cooking logic:
func process_cooking(delta_time: float):
	# Go through each slot in the firepit inventory
	for i in range(interactive_object.object_menu.size()):
		var slot = interactive_object.object_menu[i]
		
		# Skip empty slots or non-cookable items
		if slot.is_empty() or not slot.item.is_cookable:
			continue
		
		# Initialize cooking data for this slot if needed
		if cooking_slots.size() <= i:
			cooking_slots.resize(i + 1)
		
		if cooking_slots[i] == null:
			cooking_slots[i] = {}
		
		# Start cooking if not already cooking
		if not cooking_slots[i].has("cook_progress"):
			cooking_slots[i]["cook_progress"] = 0.0
			cooking_slots[i]["total_cook_time"] = slot.item.cook_time
			print("Started cooking ", slot.item.name, " (", slot.item.cook_time, "s)")
		
		# Update cooking progress
		cooking_slots[i]["cook_progress"] += delta_time
		
		# Check if item is done cooking
		if cooking_slots[i]["cook_progress"] >= cooking_slots[i]["total_cook_time"]:
			cook_item_complete(i)

# Add this function to handle completed cooking:
func cook_item_complete(slot_index: int):
	var slot = interactive_object.object_menu[slot_index]
	if slot.is_empty():
		return
	
	var raw_item = slot.item
	var cooked_item_name = raw_item.cooked_result_item_name
	
	if cooked_item_name == "":
		print("Warning: ", raw_item.name, " has no cooked result defined!")
		return
	
	# Get the cooked item from inventory manager
	if GameObjectsDatabase.game_objects_database.has(cooked_item_name):
		var cooked_item = GameObjectsDatabase.game_objects_database[cooked_item_name]
		
		# Replace the raw item with cooked item
		slot.item = cooked_item
		print("Finished cooking ", raw_item.name, " -> ", cooked_item.name)
		
		# Clear cooking progress
		if cooking_slots.size() > slot_index:
			cooking_slots[slot_index] = {}
		
		# Update UI if object menu is open
		var object_menus = get_tree().get_nodes_in_group("object_menu")
		for obj_menu in object_menus:
			if obj_menu.visible and obj_menu.current_object == self:
				obj_menu.update_object_slot_display(slot_index)
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
			return "Burning (" + str(int(current_burn_time)) + "s remaining)"
		ObjectState.UNLIT:
			return "Unlit"
		_:
			return "Unknown"
