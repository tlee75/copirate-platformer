extends GameItem
class_name CookedRaspberry

# Animation hit frame definition
var hit_frames = {
	"consume": [4], # List is required for single frames
}
var player_stats: PlayerStats

func _init():
	name = "Cooked Raspberry"
	icon = load("res://assets/consumables/cooked_raspberry_icon_01.png")
	stack_size = 99
	craftable = false
	category = "food"
	underwater_compatible = false
	land_compatible = true
	craft_requirements = {"Gold Coin": 1}
	use_animation = "consume"

func is_consumable() -> bool:
	return true

func extra_use_startup(player, slot_data):
	if player and player.player_stats:
		player_stats = player.player_stats
		if player_stats.is_eating:
			print("Already eating")
			return false
		player_stats.is_eating = true
		player_stats.set_hunger_regen_modifier(5)
		player_stats.start_eating(10)
		player_stats.start_drinking(1)
		
		# Store slot data for removal after animation finishes
		pending_slot_data = slot_data
	else:
		print("no player stats")

func extra_use_cleanup(_player):
	# Remove the item after the animation has finished to prevent breaking signals
	if pending_slot_data and not pending_slot_data.is_empty() and pending_slot_data.item.name == self.name:
		pending_slot_data.remove_item(1)
		InventoryManager.hotbar_changed.emit()
	pending_slot_data = null
