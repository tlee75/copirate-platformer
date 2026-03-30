extends Node2D
class_name GameObject

@export var max_harvest: int
@export var regeneration_time: float

var animated_sprite: AnimatedSprite2D

# Harvesting specific properties for Raspberry bush, coconut trees, etc
var harvest_remaining: int
var is_harvestable: bool
var is_destructible: bool
var loot_table: Dictionary = {}
var player: Player
var _last_target_action: String = ""

# Core properties
var category: String = ""
var description: String = ""

# Crafting properties (only used by structures)
var craftable: bool = false
var icon: Texture2D
var craft_requirements: Dictionary = {}
var scene_path: String = ""
var placement_bottom_padding = 0

# Hover effect properties
var original_modulate: Color
var original_scale: Vector2
var hover_tween: Tween
var sprite_node  # Can be AnimatedSprite2D or Sprite2D

func _ready():
	# Wait one frame to ensure all @onready variables are initialized
	await get_tree().process_frame
	
	# Find the sprite node automatically
	_find_sprite_node()
	
	# Setup hover detection
	setup_hover_detection()

func _find_sprite_node():
	"""Automatically find the sprite node in children"""
	for child in get_children():
		if child is AnimatedSprite2D:
			sprite_node = child
			animated_sprite = child
			break
		elif child is Sprite2D:
			sprite_node = child
			break
	
	if not sprite_node:
		print("Warning: No Sprite2D/AnimatedSprite2D found in ", name, " - hover effects disabled")

func setup_hover_detection():
	"""Hover detection now handled by targeting system"""
	# Wait one frame to ensure scene is fully loaded
	await get_tree().process_frame
	
	if not sprite_node:
		return
		
	original_modulate = sprite_node.modulate
	original_scale = scale


func _on_area_entered(area: Area2D):
	"""No longer used - hover handled by targeting system"""
	pass

func _on_area_exited(area: Area2D):
	"""No longer used - hover handled by targeting system"""
	pass

func _is_player_cursor_area(area: Area2D) -> bool:
	"""No longer used - hover handled by targeting system"""
	return false

func _find_area2d() -> Area2D:
	"""No longer used - hover handled by targeting system"""
	return null

func _on_hover_enter():
	"""Called when crosshair enters the object"""
	if not is_interactable():
		return
	
	# Kill any existing tween
	if hover_tween:
		hover_tween.kill()
	
	# Create smooth transition to hover state
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	
	# Get hover color
	var hover_color = get_hover_color()
	hover_tween.tween_property(sprite_node, "modulate", hover_color, 0.15)
	
	# Scale up from the original scale
	var scale_multiplier = get_hover_scale_multiplier()
	var hover_scale = original_scale * scale_multiplier
	hover_tween.tween_property(self, "scale", hover_scale, 0.15)


func _on_hover_exit():
	"""Called when crosshair exits the object"""
	if not sprite_node:
		return
		
	# Kill any existing tween
	if hover_tween:
		hover_tween.kill()
	
	# Create smooth transition back to normal
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	
	# Return to original colors and scale
	hover_tween.tween_property(sprite_node, "modulate", original_modulate, 0.15)
	hover_tween.tween_property(self, "scale", original_scale, 0.15)

# Virtual methods - override in subclasses
func get_hover_color() -> Color:
	"""Override this in subclasses for custom hover colors"""
	if category == "terrain":
		return Color(1.1, 1.3, 1.1, 1.0)  # Green tint for terrain
	else:
		return Color(1.2, 1.2, 1.2, 1.0)  # Neutral for structures

func get_hover_scale_multiplier() -> float:
	"""Override this in subclasses for custom scale amounts"""
	if category == "terrain":
		return 1.05  # 5% larger for terrain
	else:
		return 1.03  # 3% larger for structures

func get_crosshair_radius() -> float:
	"""Return world-space radius for the targeting crosshair, derived from sprite size."""
	if sprite_node:
		var size: Vector2
		if sprite_node is AnimatedSprite2D:
			var frames = sprite_node.sprite_frames
			if frames:
				var texture = frames.get_frame_texture(sprite_node.animation, sprite_node.frame)
				if texture:
					size = texture.get_size()
				else:
					return 28.0
			else:
				return 28.0
		else:
			var rect: Rect2 = sprite_node.get_rect()
			size = rect.size
		var local_longest: float = max(abs(size.x), abs(size.y))
		var world_longest: float = local_longest * max(abs(scale.x), abs(scale.y))
		return clamp(world_longest * 0.10, 8.0, 20.0)
	return 28.0

func set_cooldown():
	pass

func is_interactable() -> bool:
	"""Override this in subclasses"""
	return false

func regenerate():
	is_harvestable = true
	harvest_remaining = max_harvest
	if animated_sprite:
		animated_sprite.play("idle_full")
	print(name, " has regrown!")

func activate_use(target_action: String, used_amount: int):
	if is_harvestable:
		if animated_sprite:
			if harvest_remaining == max_harvest:
				if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("hit_full"):
					animated_sprite.play("hit_full")
				else:
					print("WARN: Missing the hit_full animation for ", self.name)
			elif harvest_remaining > 0 and harvest_remaining < max_harvest:
				if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("hit_partial"):
					animated_sprite.play("hit_partial")
				else:
					print("WARN: Missing the hit_partial animation for ", self.name)
			else:
				print("harvest_remaining: ", harvest_remaining)
				print("max_harvest: ", max_harvest)
				if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("hit_empty"):
					animated_sprite.play("hit_empty")
				else:
					print("WARN: Missing the hit_empty animation for ", self.name)
				is_harvestable = false
		else:
			print("Animated sprite object not found for ", self.name)
					
		print(name, " harvest: ", harvest_remaining, "/", max_harvest)
		player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("add_loot"):
			if loot_table.has(target_action):
				for entry in loot_table[target_action]:
					if entry.get("type") == "harvest":
						var quantity = randi_range(entry.get("min", 1), entry.get("max", 1))
						if randf() <= entry.get("chance", 1.0):
							player.add_loot(entry["item"], quantity)
							
		harvest_remaining -= used_amount


# Handle destruction after the hit animation has completed
func use_finished_callback():
	print("use_finished_callback")
	
	if is_harvestable:
		
		# Let the hit animation finish before resetting to idle
		if animated_sprite and animated_sprite.is_playing():
			await animated_sprite.animation_finished
		
		# Reset animation after hit
		if harvest_remaining > 0:
			if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle_full"):
				animated_sprite.play("idle_full")
			else:
				print("WARN: Missing idle_full animation")
		else:
			if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle_empty"):
				animated_sprite.play("idle_empty")
			else:
				print("WARN: Missing idle_empty animation")
			is_harvestable = false
			ResourceManager.register_resource_regeneration(self, regeneration_time)
		
		# Break and drop loot
		if harvest_remaining <= 0 and is_destructible:
			# Play destruction animation if available
			if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("break"):
				animated_sprite.play("break")
				# Wait for animation to finish, then remove object
				await animated_sprite.animation_finished
			else:
				print("WARN: Unable to find break animation")
			
			LootDropper.drop_loot(loot_table, self, _last_target_action)
			print(name, " has been destroyed")
			
			queue_free()
	elif has_method("interact"):
		# Call method only in subclass
		call("interact")
