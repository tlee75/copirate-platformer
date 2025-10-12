extends Node
class_name WaterFlowManager

# Signals for other systems to connect to
signal tile_flooded(tile_pos: Vector2i, water_type: int)
signal flow_completed()

# Tile source IDs and atlas coordinates (same as current shovel)
const SURFACE_WATER_SOURCE_ID = 11
const SURFACE_WATER_ATLAS = Vector2i(0, 0)
const UNDERWATER_SOURCE_ID = 12  
const UNDERWATER_ATLAS = Vector2i(0, 0)
const DIRT_HOLE_SOURCE_ID = 1
const DIRT_HOLE_ATLAS = Vector2i(0, 0)

# Flow timing
const FLOW_INTERVAL = 0.5

# State tracking
var _is_flowing: bool = false
var _tilemap: TileMap
var _processed_tiles: Array[Vector2i] = []

func _ready():
	_find_tilemap()

func _find_tilemap():
	var scene_root = get_tree().current_scene
	_tilemap = scene_root.get_node_or_null("TileMap")
	if not _tilemap:
		push_error("WaterFlowManager: Could not find TileMap node")

# Public API - called by tools like shovel
func register_dug_tile(tile_pos: Vector2i) -> void:
	if not _tilemap:
		push_error("WaterFlowManager: TileMap not available")
		return
	
	# Check if this tile should become water
	var water_type = _determine_water_type(tile_pos)
	if water_type == DIRT_HOLE_SOURCE_ID:
		return  # No water flow needed
	
	# Start flow if not already flowing
	if not _is_flowing:
		_start_water_flow(tile_pos)

# Public API - check if system is currently processing
func is_flow_active() -> bool:
	return _is_flowing

# Public API - stop current flow (useful for cleanup)
func stop_current_flow() -> void:
	_is_flowing = false

# Start the water flow coroutine
func _start_water_flow(initial_tile: Vector2i):
	_is_flowing = true
	_processed_tiles.clear()
	
	# Start the coroutine
	_process_water_flow_coroutine(initial_tile)

# Main coroutine that handles the entire flow process
func _process_water_flow_coroutine(start_tile: Vector2i):
	var current_wave: Array[Vector2i] = [start_tile]
	
	while not current_wave.is_empty() and _is_flowing:
		var next_wave: Array[Vector2i] = []
		
		# Process all tiles in current wave simultaneously
		for tile_pos in current_wave:
			_flood_single_tile(tile_pos)
			_processed_tiles.append(tile_pos)
			
			# Find adjacent dug tiles for next wave
			var adjacent_tiles = _find_adjacent_dug_tiles(tile_pos)
			for adj_tile in adjacent_tiles:
				if adj_tile not in _processed_tiles and adj_tile not in next_wave:
					next_wave.append(adj_tile)
		
		# Set up next wave
		current_wave = next_wave
		
		# Wait for next interval if there are more tiles
		if not current_wave.is_empty():
			await get_tree().create_timer(FLOW_INTERVAL).timeout
	
	# Flow completed
	_is_flowing = false
	flow_completed.emit()
	print("WaterFlowManager: Flow completed, processed ", _processed_tiles.size(), " tiles")

# Replace a single tile with appropriate water type
func _flood_single_tile(tile_pos: Vector2i):
	var water_type = _determine_water_type(tile_pos)
	var atlas_coords: Vector2i
	
	match water_type:
		SURFACE_WATER_SOURCE_ID:
			atlas_coords = SURFACE_WATER_ATLAS
		UNDERWATER_SOURCE_ID:
			atlas_coords = UNDERWATER_ATLAS
		_:
			return  # Shouldn't happen, but safety check
	
	_tilemap.set_cell(0, tile_pos, water_type, atlas_coords)
	tile_flooded.emit(tile_pos, water_type)
	print("WaterFlowManager: Flooded tile at ", tile_pos)

# Find adjacent dug tiles (left, right, below only)
func _find_adjacent_dug_tiles(tile_pos: Vector2i) -> Array[Vector2i]:
	var adjacent_tiles: Array[Vector2i] = []
	var directions = [
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0),   # Right  
		Vector2i(0, 1)    # Below
	]
	
	for direction in directions:
		var check_pos = tile_pos + direction
		
		# Check if this position has a dirt hole
		var source_id = _tilemap.get_cell_source_id(0, check_pos)
		var atlas_coords = _tilemap.get_cell_atlas_coords(0, check_pos)
		
		if source_id == DIRT_HOLE_SOURCE_ID and atlas_coords == DIRT_HOLE_ATLAS:
			# Check if this dirt hole should become water
			var water_type = _determine_water_type(check_pos)
			if water_type != DIRT_HOLE_SOURCE_ID:
				adjacent_tiles.append(check_pos)
	
	return adjacent_tiles

# Determine what water type a tile should become (same logic as shovel)
func _determine_water_type(tile_pos: Vector2i) -> int:
	var above_pos = tile_pos + Vector2i(0, -1)
	var left_pos = tile_pos + Vector2i(-1, 0)
	var right_pos = tile_pos + Vector2i(1, 0)
	
	var above_data = _tilemap.get_cell_tile_data(0, above_pos)
	var left_data = _tilemap.get_cell_tile_data(0, left_pos)
	var right_data = _tilemap.get_cell_tile_data(0, right_pos)
	
	# Check above for water
	if above_data and above_data.has_custom_data("is_water") and above_data.get_custom_data("is_water"):
		return UNDERWATER_SOURCE_ID
	
	# Check left/right for water
	for adj_data in [left_data, right_data]:
		if adj_data and adj_data.has_custom_data("is_water") and adj_data.get_custom_data("is_water"):
			if adj_data.has_custom_data("water_type") and adj_data.get_custom_data("water_type") == "surface":
				return SURFACE_WATER_SOURCE_ID
			else:
				return UNDERWATER_SOURCE_ID
	
	# Default to dirt_hole if no water found
	return DIRT_HOLE_SOURCE_ID

func get_flow_status() -> Dictionary:
	return {
		"is_flowing": _is_flowing,
		"processed_count": _processed_tiles.size(),
		"processed_tiles": _processed_tiles
	}

# Debug function - force stop flow
func debug_stop_flow():
	stop_current_flow()
	print("Flow manually stopped")
