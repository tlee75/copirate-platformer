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
	LOCK,          # Lock/unlock item
	INSPECT        # Show item details
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
func get_available_actions(
	stack: InventoryManager.ItemStack, 
	input_method: InputMethod = InputMethod.MOUSE_KEYBOARD,
	context: Dictionary = {}  # ADD THIS - context passed from UI
) -> Array[ActionData]:
	if not stack or not stack.item:
		return []
	
	var actions: Array[ActionData] = []
	var item = stack.item
	
	# Primary context action (USE) - pass context
	var use_action = _get_context_use_action(stack, context)
	if use_action:
		actions.append(use_action)
	
	# Equipment actions
	var equip_actions = _get_equipment_actions(stack, input_method)
	actions.append_array(equip_actions)
	
	# Quick access actions
	var quick_access_actions = _get_quick_access_actions(stack, input_method)
	actions.append_array(quick_access_actions)
	
	# Item management actions
	var management_actions = _get_management_actions(stack, input_method)
	actions.append_array(management_actions)
	
	return actions

# Determine the primary "use" action based on item type and context
func _get_context_use_action(stack: InventoryManager.ItemStack, context: Dictionary = {}) -> ActionData:
	var item = stack.item
	
	# Check for object interaction context (no scene tree access!)
	if context.has("object_interaction") and context.object_interaction:
		var object_name = context.get("object_name", "Object")
		var object_target = context.get("object_target", null)
		
		if object_target and object_target.has_method("can_object_accept_item"):
			if object_target.can_object_accept_item(item):
				return ActionData.new(ActionType.USE, "Add to " + object_name, "E/A", true)
	
	# Check for other contexts
	if context.has("firepit_nearby") and context.firepit_nearby and item.category == "fuel":
		return ActionData.new(ActionType.USE, "Add to Fire", "E/A", true)
	
	if context.has("crafting_available") and context.crafting_available and item.category in ["material", "resource"]:
		return ActionData.new(ActionType.USE, "Use for Crafting", "E/A", true)
	
	# Default item actions based on category
	match item.category:
		"consumable", "food":
			return ActionData.new(ActionType.USE, "Consume", "E/A", true)
			
		"weapon":
			if stack.is_equipped():
				return ActionData.new(ActionType.USE, "Unequip", "E/A", true)
			else:
				return ActionData.new(ActionType.USE, "Equip", "E/A", true)
				
		"tool":
			return ActionData.new(ActionType.USE, "Add to Quick Access", "E/A", true)
		
		"armor", "helmet", "chest", "legs", "hands", "feet", "shield", "accessory":
			if stack.is_equipped():
				return ActionData.new(ActionType.USE, "Unequip", "E/A", true)
			else:
				return ActionData.new(ActionType.USE, "Equip", "E/A", true)
		
		"fuel":
			return ActionData.new(ActionType.USE, "Add to Quick Access", "E/A", true)
		
		"material", "resource":
			return ActionData.new(ActionType.USE, "Add to Quick Access", "E/A", true)
		
		_:
			return ActionData.new(ActionType.USE, "Use", "E/A", true)

# Get equipment-related actions
func _get_equipment_actions(stack: InventoryManager.ItemStack, input_method: InputMethod) -> Array[ActionData]:
	var actions: Array[ActionData] = []
	var item = stack.item
	
	# Only show equip actions for equipable items
	if not _is_equipable_item(item):
		return actions
	
	if stack.is_equipped():
		actions.append(ActionData.new(ActionType.EQUIP, "Unequip", "R/X"))
	else:
		actions.append(ActionData.new(ActionType.EQUIP, "Equip", "R/X"))
		
	return actions

# Get quick access related actions  
func _get_quick_access_actions(stack: InventoryManager.ItemStack, input_method: InputMethod) -> Array[ActionData]:
	var actions: Array[ActionData] = []
	
	if stack.is_in_quick_access():
		actions.append(ActionData.new(ActionType.QUICK_ACCESS, "Remove from Quick Access", "Q/L3"))
	else:
		# Check if quick access has space
		if _has_quick_access_space():
			actions.append(ActionData.new(ActionType.QUICK_ACCESS, "Add to Quick Access", "Q/L3"))
		else:
			actions.append(ActionData.new(ActionType.QUICK_ACCESS, "Replace Quick Access Item", "Q/L3"))
	return actions

# Get item management actions
func _get_management_actions(stack: InventoryManager.ItemStack, input_method: InputMethod) -> Array[ActionData]:
	var actions: Array[ActionData] = []
	
	# Drop action (if not locked)
	if not stack.is_locked:
		actions.append(ActionData.new(ActionType.DROP, "Drop", "X/Y"))
	
	# Lock/unlock action
	if stack.is_locked:
		actions.append(ActionData.new(ActionType.LOCK, "Unlock", "L/R3"))
	else:
		actions.append(ActionData.new(ActionType.LOCK, "Lock", "L/R3"))
	
	# Inspect action (always available)
	actions.append(ActionData.new(ActionType.INSPECT, "Inspect", "Hold"))
	
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
		
		ActionType.INSPECT:
			return _execute_inspect_action(stack)
		
		_:
			print("Unknown action type: ", action_type)
			return false

# Execute the context-dependent use action
func _execute_use_action(stack: InventoryManager.ItemStack) -> bool:
	print("DEBUG: _execute_use_action called")
	print("  stack:", stack)
	# Handle object interaction first
	var scene_tree = get_tree()
	if scene_tree == null:
		# Scene tree not available, skip object interaction
		var item = stack.item
		# Skip to the item logic below
	else:
		var main_scene = scene_tree.current_scene
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

func _execute_inspect_action(stack: InventoryManager.ItemStack) -> bool:
	# TODO: Show item details panel
	print("Inspecting: ", stack.item.name)
	print("  Category: ", stack.item.category)
	print("  Quantity: ", stack.quantity)
	print("  Stack Size: ", stack.item.stack_size)
	print("  Equipped: ", stack.is_equipped())
	print("  In Quick Access: ", stack.is_in_quick_access())
	print("  Locked: ", stack.is_locked)
	return true

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


func _get_default_item_action(item: GameItem) -> ActionData:
	match item.category:
		"consumable", "food":
			return ActionData.new(ActionType.USE, "Consume", "E/A", true)
		"weapon", "armor", "helmet", "chest", "legs", "hands", "feet", "shield", "accessory":
			return ActionData.new(ActionType.USE, "Equip", "E/A", true)
		"tool":
			return ActionData.new(ActionType.USE, "Add to Quick Access", "E/A", true)
		"fuel", "material", "resource":
			return ActionData.new(ActionType.USE, "Add to Quick Access", "E/A", true)
		_:
			return ActionData.new(ActionType.USE, "Use", "E/A", true)
