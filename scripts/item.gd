extends Resource

class_name GameItem

@export var name: String
@export var stack_size: int = 1
@export var craftable: bool = false
@export var underwater_compatible: bool = false
@export var land_compatible: bool = true
@export var is_cookable: bool = false
@export var cook_time: float = 0.0  # Time in seconds to cook
@export var is_tool = false
@export var is_weapon: bool = false
@export var used_amount: int = 0
@export var description: String = ""  # Item description - set by individual item scripts
@export var craft_time: float = 3.0  # Time in seconds to craft this item
@export var target_range: float = 50.0      # Maximum targeting range
@export var target_spread: float = 10.0     # Targeting spread width  
@export var target_action: String = ""        # "dig", "chop", "mine", etc.

var category: String = ""
var icon: Texture2D
var craft_requirements: Dictionary = {}
var cooked_result_item_name: String = ""  # What this item becomes when cooked
var use_animation = ""
var pending_item_stack: InventoryManager.ItemStack = null

func is_consumable() -> bool:
	return false

func use(player, target, item_stack = null):
	if use_animation == "" or use_animation == null:
		print("WARNING: Item '%s' has no use_animation set!" % self.name)
		return
	if target:
		player.attack_target = target
	player.is_trigger_action = true
	print("trigger action true")
	var anim_sprite = player.get_node("AnimatedSprite2D")
	extra_use_startup(player, item_stack)
	cleanup_connections(player)
	anim_sprite.frame_changed.connect(_on_use_frame_changed.bind(player))
	anim_sprite.animation_finished.connect(_on_use_animation_finished.bind(player))
	anim_sprite.play(use_animation)
	
	# For consumables, store the item stack so it can be cleaned up later
	if is_consumable() and item_stack:
		pending_item_stack = item_stack
	else:
		pending_item_stack = null

func _on_use_frame_changed(player):
	var anim_sprite = player.get_node("AnimatedSprite2D")
	var anim = anim_sprite.animation
	var frame = anim_sprite.frame
	if "hit_frames" in self and anim in self.hit_frames and frame in self.hit_frames[anim]:
		handle_use_hit_frame(player, anim, frame)

func handle_use_hit_frame(player, _anim, _frame):
	var target = player.attack_target
	if not target:
		return
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target):
		# Priority 1: Tool action on compatible targets
		if _is_target_compatible(target):
			target.activate_use(target_action, used_amount)
			return

func _is_target_compatible(target) -> bool:
	"""Check if this item's target_action matches a key in the target's loot_table"""
	if target_action == "":
		return false
	if "loot_table" in target and target.loot_table is Dictionary:
		return target.loot_table.has(target_action)
	return false

func _on_use_animation_finished(player):
	print("_on_use_animation_finished")
	player.is_trigger_action = false
	if typeof(player.attack_target) == TYPE_OBJECT and is_instance_valid(player.attack_target) and player.attack_target.has_method("use_finished_callback"):
		player.attack_target.use_finished_callback()
	extra_use_cleanup(player)
	player.attack_target = null
	
	# Remove the consumable that was stored previously
	if is_consumable() and pending_item_stack and pending_item_stack.quantity > 0 and pending_item_stack.item.name == self.name:
		InventoryManager.use_item_stack(pending_item_stack)
		InventoryManager.quick_access_changed.emit()
		pending_item_stack = null
	cleanup_connections(player)

func extra_use_startup(_player, _slot_data):
	pass

func extra_use_cleanup(_player):
	print("item extra_use_cleanup")


func cleanup_connections(user):
	var anim_sprite = user.get_node("AnimatedSprite2D")
	if anim_sprite.frame_changed.is_connected(Callable(self, "_on_use_frame_changed")):
		anim_sprite.frame_changed.disconnect(Callable(self, "_on_use_frame_changed"))
	if anim_sprite.animation_finished.is_connected(Callable(self, "_on_use_animation_finished")):
		anim_sprite.animation_finished.disconnect(Callable(self, "_on_use_animation_finished"))
