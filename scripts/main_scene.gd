extends Node2D

# Main game scene controller
# Handles coordination between game systems and UI

@onready var ui_layer: CanvasLayer = $UI
#@onready var hotbar = $UI/Hotbar
@onready var player_menu = $UI/PlayerMenu
@onready var player: CharacterBody2D = $Player
@onready var pause_menu = $UI/PauseMenu
@onready var player_stats: PlayerStats

var respawn_position: Vector2

func _ready():	
	# Ensure crafting menu is properly initialized
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("Game scene initialized with inventory system")
	
	pause_menu.resume_requested.connect(_on_resume)
	pause_menu.restart_requested.connect(_on_restart)
	pause_menu.respawn_requested.connect(_on_respawn)

	# Get reference to player stats
	player_stats = player.player_stats
	
	if player_stats:
		var stats_timer = $UI/StatsUpdateTimer
		player_stats.setup_timer(stats_timer)
		player_stats.stat_depleted.connect(_close_menus_on_death)

	respawn_position = player.global_position # Initial position
	
	# Connect ResourceManager to the StatusUpdateTimer
	var resource_timer = $Resources/TwoSecondTimer
	ResourceManager.setup_timer(resource_timer)

	var water_flow_manager = $WaterFlowManager
	if water_flow_manager:
		water_flow_manager.tile_flooded.connect(_on_tile_flooded)
		water_flow_manager.flow_completed.connect(_on_water_flow_completed)

	# Create UI manager group
	add_to_group("ui_manager")

func _on_tile_flooded(_tile_pos: Vector2i, _water_type: int):
	# You could add particle effects, sounds, etc. here
	pass

func _on_water_flow_completed():
	print("Water flow animation completed")

func _on_resume():
	pause_menu.hide()
	get_tree().paused = false

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_respawn():
	player.player_stats.reset_stats()
	player.is_dead = false
	player.get_node("AnimatedSprite2D").play("idle")
	player.global_position = respawn_position
	pause_menu.hide()
	get_tree().paused = false
	pause_menu.set_resume_enabled(true)

func _close_menus_on_death(stat_name: String):
	if stat_name == "health":
		#$UI/PlayerMenu.visible = false
		#inventory_system.inventory_toggled.emit(false)
		if $UI.has_node("ObjectMenu"):
			$UI/ObjectMenu.visible = false

func open_object_menu(object: Node2D, title: String, slot_count: int):
	# Create or show object inventory UI
	var object_menu_ui = get_node_or_null("UI/ObjectMenu")
	
	if not object_menu_ui:
		# Create the UI if it doesn't exist
		object_menu_ui = preload("res://scenes/ui/object_menu.tscn").instantiate()
		$UI.add_child(object_menu_ui)
	
	object_menu_ui.open_object_menu(object, title, slot_count)
