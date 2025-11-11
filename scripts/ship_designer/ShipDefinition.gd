# res://scripts/ship_designer/ShipDefinition.gd
class_name ShipDefinition extends Resource

@export var ship_name: String = "Custom Ship"
@export var grid_size: Vector2i = Vector2i(64, 64)

# Tiles stored as Dictionary: Vector2i -> ShipTile
# We store as Array for export, convert to Dictionary internally
@export var tile_positions: Array[Vector2i] = []
@export var tile_data: Array[ShipTile] = []

# Parts placement
@export var parts: Array[PartPlacement] = []

# Calculated metadata (updated on validate)
@export var metadata: Dictionary = {
	"total_mass": 0.0,
	"thrust_power": 0.0,
	"energy_capacity": 0.0,
	"crew_capacity": 0,
	"cargo_capacity": 0
}

func _init() -> void:
	resource_local_to_scene = true

# Get tile at position
func get_tile(pos: Vector2i) -> ShipTile:
	var index = tile_positions.find(pos)
	if index >= 0 and index < tile_data.size():
		return tile_data[index]
	return null

# Set tile at position
func set_tile(pos: Vector2i, tile: ShipTile) -> void:
	var index = tile_positions.find(pos)
	if index >= 0:
		tile_data[index] = tile
	else:
		tile_positions.append(pos)
		tile_data.append(tile)

# Remove tile at position
func remove_tile(pos: Vector2i) -> void:
	var index = tile_positions.find(pos)
	if index >= 0:
		tile_positions.remove_at(index)
		tile_data.remove_at(index)

# Check if position has a tile
func has_tile(pos: Vector2i) -> bool:
	return tile_positions.has(pos)

# Check if a part can be placed
func can_place_part(placement: PartPlacement) -> bool:
	if placement.part == null:
		return false

	# Check if cells are free
	var cells = placement.get_occupied_cells()
	for cell in cells:
		# Check if another part already occupies this cell
		for existing in parts:
			if cell in existing.get_occupied_cells():
				return false

	# Check door connections (if part has doors)
	if placement.part.has_doors():
		var door_positions = placement.get_actual_door_positions()
		var door_directions = placement.get_actual_door_directions()

		for i in door_positions.size():
			var door_pos = door_positions[i]
			var door_dir = door_directions[i]
			var corridor_cell = door_pos + door_dir

			# Must connect to a corridor tile
			var tile = get_tile(corridor_cell)
			if tile == null:
				return false
			if tile.tile_type != PartCategory.TileType.CORRIDOR:
				return false

	return true

# Add a part placement
func add_part(placement: PartPlacement) -> bool:
	if !can_place_part(placement):
		return false
	parts.append(placement)
	_recalculate_metadata()
	return true

# Remove a part
func remove_part(placement: PartPlacement) -> void:
	parts.erase(placement)
	_recalculate_metadata()

# Validation
func validate() -> Dictionary:
	var result = {
		"valid": true,
		"errors": []
	}

	# Check required components
	var has_corridor = false
	var has_airlock = false

	for tile in tile_data:
		if tile.tile_type == PartCategory.TileType.CORRIDOR:
			has_corridor = true
		elif tile.tile_type == PartCategory.TileType.AIRLOCK:
			has_airlock = true

	if !has_corridor:
		result.errors.append("Ship must have at least one corridor")
		result.valid = false

	if !has_airlock:
		result.errors.append("Ship must have at least one airlock")
		result.valid = false

	# Check for crew beds
	var has_crew_quarters = false
	for placement in parts:
		if placement.part.category == PartCategory.Type.CREW:
			if placement.part.special_properties.has("crew_capacity"):
				has_crew_quarters = true
				break

	if !has_crew_quarters:
		result.errors.append("Ship must have crew quarters (bunks/beds)")
		result.valid = false

	return result

# Calculate ship properties
func _recalculate_metadata() -> void:
	metadata.total_mass = 0.0
	metadata.thrust_power = 0.0
	metadata.energy_capacity = 0.0
	metadata.crew_capacity = 0
	metadata.cargo_capacity = 0

	# Add tile mass
	for tile in tile_data:
		metadata.total_mass += tile.mass

	# Add part contributions
	for placement in parts:
		if !placement.enabled or placement.part == null:
			continue

		var part = placement.part
		metadata.total_mass += part.mass

		# Category-specific properties
		if part.special_properties.has("thrust_power"):
			metadata.thrust_power += part.special_properties.thrust_power

		if part.special_properties.has("energy_capacity"):
			metadata.energy_capacity += part.special_properties.energy_capacity

		if part.special_properties.has("crew_capacity"):
			metadata.crew_capacity += part.special_properties.crew_capacity

		if part.special_properties.has("cargo_capacity"):
			metadata.cargo_capacity += part.special_properties.cargo_capacity

# Get ship bounds
func get_bounds() -> Rect2i:
	if tile_positions.size() == 0 and parts.size() == 0:
		return Rect2i(0, 0, 0, 0)

	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	# Check tiles
	for pos in tile_positions:
		min_x = min(min_x, pos.x)
		min_y = min(min_y, pos.y)
		max_x = max(max_x, pos.x)
		max_y = max(max_y, pos.y)

	# Check parts
	for placement in parts:
		for cell in placement.get_occupied_cells():
			min_x = min(min_x, cell.x)
			min_y = min(min_y, cell.y)
			max_x = max(max_x, cell.x)
			max_y = max(max_y, cell.y)

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

# Export to JSON
func to_json() -> Dictionary:
	var json = {
		"version": 1,
		"ship_name": ship_name,
		"grid_size": [grid_size.x, grid_size.y],
		"tiles": {},
		"parts": [],
		"metadata": metadata
	}

	# Export tiles
	for i in tile_positions.size():
		var pos = tile_positions[i]
		var tile = tile_data[i]
		json.tiles["%d,%d" % [pos.x, pos.y]] = {
			"type": tile.tile_id,
			"variant": tile.variant
		}

	# Export parts
	for placement in parts:
		json.parts.append({
			"part_id": placement.part.part_id,
			"position": [placement.grid_position.x, placement.grid_position.y],
			"horizontal": placement.horizontal,
			"enabled": placement.enabled
		})

	return json
