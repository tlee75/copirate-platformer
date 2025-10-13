extends Control
class_name EquipmentPanel

# Equipment slot references
@onready var equipment_slots_container: Control = $EquipmentSlotsContainer

var equipment_slots: Array[Control] = []

func _ready():
	# Initialize equipment slots array
	equipment_slots = []
	for child in equipment_slots_container.get_children():
		if child is Control:
			equipment_slots.append(child)
			
	
	print("DEBUG: EquipmentPanel _ready() called with ", equipment_slots.size(), " slots")
	
	var slot_count = equipment_slots.size()
	InventoryManager.initialize_equipment_slots(slot_count)
	
	# Configure each slot
	for i in slot_count:
		if equipment_slots[i]:
			equipment_slots[i].slot_index = i
			equipment_slots[i].is_hotbar_slot = false
			equipment_slots[i].is_weapon_slot = false
			equipment_slots[i].is_equipment_slot = true
			
			print("DEBUG: Configured equipment slot ", i, " (", equipment_slots[i].name, ") - is_equipment_slot: ", equipment_slots[i].is_equipment_slot)

		else:
			print("DEBUG: Equipment slot ", i, " is null!")
	
	# Connect to inventory manager
	if InventoryManager.has_signal("equipment_changed"):
		InventoryManager.equipment_changed.connect(_update_display)
	
	_update_display()

func _update_display():
	for i in equipment_slots.size():
		if equipment_slots[i]:
			var slot_data = InventoryManager.get_equipment_slot(i)
			if slot_data:
				equipment_slots[i].update_display(slot_data)

func can_equip_item(item_data, slot_node_name: String) -> bool:
	if not item_data:
		return false
	
	# Define what item categories can go in each equipment slot, by scene node name
	match slot_node_name:
		"HeadSlot":
			return item_data.category == "head"
		"ChestSlot":
			return item_data.category == "chest"
		"LegsSlot":
			return item_data.category == "legs"
		"HandsSlot":
			return item_data.category == "hands"
		"MainHand":
			return item_data.category == "weapon"
		"OffHand":
			return item_data.category == "shield" or item_data.category == "sidearm"
		"ArmsSlot":
			return item_data.category == "bracers"
		"AccessorySlot1", "AccessorySlot2":
			return item_data.category == "accessory"
	return false


func get_equipment_slot_index_by_node_name(node_name: String) -> int:
	for i in equipment_slots.size():
		if equipment_slots[i].name == node_name:
			return i
	return -1
