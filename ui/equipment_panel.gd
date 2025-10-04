extends Control
class_name EquipmentPanel

# Equipment slot references
@onready var head_slot: Control = $HeadSlot
@onready var chest_slot: Control = $ChestSlot
@onready var legs_slot: Control = $LegsSlot
@onready var hands_slot: Control = $HandsSlot
@onready var main_hand: Control = $MainHand
@onready var off_hand: Control = $OffHand
@onready var arms_slot: Control = $ArmsSlot
@onready var feet_slot: Control = $FeetSlot
@onready var accessory_slot_1: Control = $AccessorySlot1
@onready var accessory_slot_2: Control = $AccessorySlot2

var equipment_slots: Array[Control] = []

# Equipment slot types enum
enum EquipmentType {
	HEAD = 0,
	CHEST = 1,
	LEGS = 2,
	HANDS = 3,
	MAIN_HAND = 4,
	OFF_HAND = 5,
	ARMS = 6,
	FEET = 7,
	ACCESSORY1 = 8,
	ACCESSORY2 = 9
}

func _ready():
	# Initialize equipment slots array
	equipment_slots = [
		head_slot, chest_slot, legs_slot, hands_slot, main_hand, off_hand,
		arms_slot, feet_slot, accessory_slot_1, accessory_slot_2
	]
	
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
			equipment_slots[i].equipment_type = i
			
			print("DEBUG: Configured equipment slot ", i, " (", EquipmentType.keys()[i], ") - is_equipment_slot: ", equipment_slots[i].is_equipment_slot)

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

func can_equip_item(item_data, equipment_type: EquipmentType) -> bool:
	if not item_data:
		return false
	
	# Define what item categories can go in each equipment slot
	match equipment_type:
		EquipmentType.HEAD:
			return item_data.category == "head"
		EquipmentType.CHEST:
			return item_data.category == "chest"
		EquipmentType.LEGS:
			return item_data.category == "legs"
		EquipmentType.HANDS:
			return item_data.category == "hands"
		EquipmentType.MAIN_HAND:
			return item_data.category == "weapon" or item_data.category == "tool"
		EquipmentType.OFF_HAND:
			return item_data.category == "shield" or item_data.category == "sidearm"
		EquipmentType.ARMS:
			return item_data.category == "bracers"
		EquipmentType.ACCESSORY1, EquipmentType.ACCESSORY2:
			return item_data.category == "accessory"
	return false


func get_equipment_slot_index_by_node_name(node_name: String) -> int:
	for i in equipment_slots.size():
		if equipment_slots[i].name == node_name:
			return i
	return -1
