extends Control

@onready var slot_container: HBoxContainer = $WeaponSlotContainer
var weapon_slots: Array[Control] = []

func _ready():
	# Gather all slot nodes (for now, just one, but scalable)
	for i in slot_container.get_child_count():
		var slot = slot_container.get_child(i)
		weapon_slots.append(slot)
		slot.slot_index = i
		slot.is_hotbar_slot = false
		slot.is_weapon_slot = true

	# Connect to inventory manager signals if needed
	if InventoryManager.has_signal("weapon_changed"):
		InventoryManager.weapon_changed.connect(_update_display)
	_update_display()

func _update_display():
	for i in weapon_slots.size():
		var slot_data = InventoryManager.get_weaponbar_slot(i)
		if slot_data:
			weapon_slots[i].update_display(slot_data)
