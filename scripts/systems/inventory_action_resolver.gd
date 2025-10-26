extends Node
class_name InventoryActionResolver

# Context-aware action system for inventory items
# Determines available actions based on item type, state, and input method

enum InputMethod {
	MOUSE_KEYBOARD,
	CONTROLLER,
	TOUCH
}

enum ActionType {
	USE,           # Context-dependent primary activar hotbar_actions = _get_hotbar_actions(stack, input_method)n
	EQUIP,         # Force equip/unequip
	QUICK_ACCESS,  # Add to quick access
	DROP,          # Drop item in world
	LOCK           # Lock/unlock item
}

# Action metadata for UI display
class ActionData:
	var type: ActionType
	var label: String
	var icon: Texture2D
	var input_hint: String
	var is_primary: bool = false
	
	func _init(action_type: ActionType, action_label: String, hint: String = "", primary: bool = false):
		type = action_type
		label = action_label
		input_hint = hint
		is_primary = primary

# Get available actions for an ItemStack
func get_available_actions(stack: InventoryManager.ItemStack) -> Array[ActionData]:
	var actions: Array[ActionData] = []
	if not stack or not stack.item:
		return actions
	var item = stack.item

	# Use/Consume
	if item.category in ["consumable", "food"]:
		actions.append(ActionData.new(ActionType.USE, "Consume", "E/A", true))

	# Equip/Unequip
	if item.category in ["weapon", "armor", "helmet", "chest", "legs", "hands", "feet", "shield", "accessory"]:
		if stack.is_equipped():
			actions.append(ActionData.new(ActionType.EQUIP, "Unequip", "R/X"))
		else:
			actions.append(ActionData.new(ActionType.EQUIP, "Equip", "R/X"))

	# Quick Access
	if stack.is_in_quick_access():
		actions.append(ActionData.new(ActionType.QUICK_ACCESS, "Remove from Quick Access", "Q/L3"))
	else:
		actions.append(ActionData.new(ActionType.QUICK_ACCESS, "Add to Quick Access", "Q/L3"))

	# Drop
	if not stack.is_locked:
		actions.append(ActionData.new(ActionType.DROP, "Drop", "X/Y"))

	# Lock/Unlock
	if stack.is_locked:
		actions.append(ActionData.new(ActionType.LOCK, "Unlock", "L/R3"))
	else:
		actions.append(ActionData.new(ActionType.LOCK, "Lock", "L/R3"))

	return actions
	
# Execute an action on an ItemStack
func execute_action(action_type: ActionType, stack: InventoryManager.ItemStack, data = null) -> bool:
	print("DEBUG: execute_action called")
	print("  action_type:", action_type)
	print("  stack:", stack)
	print("  data:", data)
	if typeof(data) == TYPE_DICTIONARY and data.has("tree"):
		print("  data.tree:", data["tree"])
	else:
		print("  data.tree: (missing or null)")
	if not stack:
		return false
	
	match action_type:
		ActionType.USE:
			return _execute_use_action(stack)
		
		ActionType.EQUIP:
			return _execute_equip_action(stack)
		
		ActionType.QUICK_ACCESS:
			return _execute_quick_access_action(stack)
		
		ActionType.DROP:
			return _execute_drop_action(stack)
		
		ActionType.LOCK:
			return _execute_lock_action(stack)
		
		_:
			print("Unknown action type: ", action_type)
			return false

# Execute the context-dependent use action
func _execute_use_action(stack: InventoryManager.ItemStack) -> bool:
	print("DEBUG: _execute_use_action called")
	print("  stack:", stack)
	# Handle object interaction first
	#var scene_tree = get_tree()
	#if scene_tree == null:
		## Scene tree not available, skip object interaction
		#var item = stack.item
		## Skip to the item logic below
	#else:
		#var main_scene = scene_tree.current_scene
		#if main_scene:
			#var player_menu = main_scene.get_node("UI/PlayerMenu")  
			#if player_menu and player_menu.has_meta("interacting_with_object"):
				#var object_menu = scene_tree.get_first_node_in_group("object_menu")
				#if object_menu and object_menu.can_object_accept_item(stack.item):
					#var object_title = player_menu.get_meta("object_title", "Object")
					#print("Adding ", stack.item.name, " to ", object_title)
					## Remove one item from inventory
					#InventoryManager.remove_items_by_name(stack.item.name, 1)
					#return true

	var item = stack.item
	
	match item.category:
		"consumable", "food":
			return InventoryManager.use_item_stack(stack)
		
		"weapon", "armor", "helmet", "chest", "legs", "hands", "feet", "shield", "accessory":
			return InventoryManager.toggle_equip_item_stack(stack)
		
		"tool":
			# Tools just move to quick access
			return InventoryManager.assign_to_next_quick_access_slot(stack)
		
		"fuel":
			# Try to add to nearby firepit first
			if _try_add_to_firepit(stack):
				return true
			else:
				return InventoryManager.assign_to_next_quick_access_slot(stack)
		
		"material", "resource":
			return InventoryManager.assign_to_next_quick_access_slot(stack)
		
		_:
			# Default: try to use as consumable, otherwise move to hotbar
			if item.is_consumable():
				return InventoryManager.use_item_stack(stack)
			else:
				return InventoryManager.assign_to_next_quick_access_slot(stack)

func _execute_equip_action(stack: InventoryManager.ItemStack) -> bool:
	return InventoryManager.toggle_equip_item_stack(stack)

func _execute_quick_access_action(stack: InventoryManager.ItemStack) -> bool:
	if stack.is_in_quick_access():
		return InventoryManager.remove_from_quick_access(stack.quick_access_slot)
	else:
		return InventoryManager.assign_to_next_quick_access_slot(stack)

func _execute_drop_action(stack: InventoryManager.ItemStack) -> bool:
	return InventoryManager.drop_item_stack(stack, 1)

func _execute_lock_action(stack: InventoryManager.ItemStack) -> bool:
	return InventoryManager.toggle_lock_item_stack(stack)

# Helper functions
func _is_equipable_item(item: GameItem) -> bool:
	var equipable_categories = [
		"weapon", "armor", "helmet", "chest", "legs", 
		"hands", "feet", "shield", "accessory"
	]
	return item.category in equipable_categories

func _has_quick_access_space() -> bool:
	for i in range(InventoryManager.quick_access_assignments.size()):
		if InventoryManager.quick_access_assignments[i] == null:
			return true
	return false

func _is_firepit_nearby() -> bool:
	# TODO: Check for nearby firepit objects
	# For now, return false - this would be implemented when we have world interaction
	return false

func _is_crafting_available() -> bool:
	# TODO: Check if crafting interface is open
	# For now, return false - this would be implemented with crafting UI
	return false

func _try_add_to_firepit(stack: InventoryManager.ItemStack) -> bool:
	# TODO: Implement firepit interaction
	# For now, return false - this would find nearby firepit and add fuel
	return false

# Get action by input action name (for input mapping)
func get_action_for_input(input_action: String, stack: InventoryManager.ItemStack) -> ActionData:
	if not stack:
		return null
	
	var actions = get_available_actions(stack)
	
	match input_action:
		"inventory_use":
			for action in actions:
				if action.is_primary:
					return action
		
		"inventory_equip":
			for action in actions:
				if action.type == ActionType.EQUIP:
					return action
		
		"inventory_quick_move":
			for action in actions:
				if action.type == ActionType.QUICK_ACCESS:
					return action
		
		"inventory_drop":
			for action in actions:
				if action.type == ActionType.DROP:
					return action
		
		"inventory_lock":
			for action in actions:
				if action.type == ActionType.LOCK:
					return action
	
	return null

# Execute action by input action name
func execute_input_action(input_action: String, stack: InventoryManager.ItemStack) -> bool:
	var action_data = get_action_for_input(input_action, stack)
	if not action_data:
		print("No action available for input: ", input_action)
		return false
	
	print("Executing ", action_data.label, " on ", stack.item.name)
	return execute_action(action_data.type, stack)
