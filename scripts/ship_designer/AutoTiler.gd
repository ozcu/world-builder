# res://scripts/ship_designer/AutoTiler.gd
# Auto-tiling logic for corridors - determines sprite based on neighbors
class_name AutoTiler extends RefCounted

# Connection directions (bitflags)
const UP = 1    # 0001
const DOWN = 2  # 0010
const LEFT = 4  # 0100
const RIGHT = 8 # 1000

# Store all corridor sprite variants
static var corridor_sprites: Dictionary = {}

# Initialize corridor sprites (call once at startup)
static func initialize_sprites() -> void:
	if corridor_sprites.size() > 0:
		return  # Already initialized

	# Generate all corridor variants
	corridor_sprites["isolated"] = MockupGenerator.create_corridor_mockup([])
	corridor_sprites["horizontal"] = MockupGenerator.create_corridor_mockup([Vector2i(-1, 0), Vector2i(1, 0)])
	corridor_sprites["vertical"] = MockupGenerator.create_corridor_mockup([Vector2i(0, -1), Vector2i(0, 1)])
	corridor_sprites["corner_ul"] = MockupGenerator.create_corridor_mockup([Vector2i(0, -1), Vector2i(-1, 0)])
	corridor_sprites["corner_ur"] = MockupGenerator.create_corridor_mockup([Vector2i(0, -1), Vector2i(1, 0)])
	corridor_sprites["corner_dl"] = MockupGenerator.create_corridor_mockup([Vector2i(0, 1), Vector2i(-1, 0)])
	corridor_sprites["corner_dr"] = MockupGenerator.create_corridor_mockup([Vector2i(0, 1), Vector2i(1, 0)])
	corridor_sprites["t_up"] = MockupGenerator.create_corridor_mockup([Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)])
	corridor_sprites["t_down"] = MockupGenerator.create_corridor_mockup([Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)])
	corridor_sprites["t_left"] = MockupGenerator.create_corridor_mockup([Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)])
	corridor_sprites["t_right"] = MockupGenerator.create_corridor_mockup([Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0)])
	corridor_sprites["cross"] = MockupGenerator.create_corridor_mockup([Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)])

# Determine which corridor sprite to use based on neighbors
static func get_corridor_sprite(ship: ShipDefinition, pos: Vector2i) -> Texture2D:
	initialize_sprites()

	var connections = get_connections(ship, pos)
	var sprite_key = get_sprite_key_from_connections(connections)

	return corridor_sprites.get(sprite_key, corridor_sprites["isolated"])

# Get connection mask for a corridor at given position
static func get_connections(ship: ShipDefinition, pos: Vector2i) -> int:
	var mask = 0

	# Check all 4 directions
	if should_connect(ship, pos, Vector2i(0, -1)):  # Up
		mask |= UP
	if should_connect(ship, pos, Vector2i(0, 1)):   # Down
		mask |= DOWN
	if should_connect(ship, pos, Vector2i(-1, 0)):  # Left
		mask |= LEFT
	if should_connect(ship, pos, Vector2i(1, 0)):   # Right
		mask |= RIGHT

	return mask

# Check if corridor should connect in given direction
static func should_connect(ship: ShipDefinition, pos: Vector2i, direction: Vector2i) -> bool:
	var neighbor_pos = pos + direction
	var neighbor_tile = ship.get_tile(neighbor_pos)

	if neighbor_tile == null:
		return false

	# Connect to other corridors
	if neighbor_tile.tile_type == PartCategory.TileType.CORRIDOR:
		return true

	# Connect to doors
	if neighbor_tile.tile_type == PartCategory.TileType.DOOR:
		return true

	# Connect to airlocks
	if neighbor_tile.tile_type == PartCategory.TileType.AIRLOCK:
		return true

	return false

# Convert connection mask to sprite key
static func get_sprite_key_from_connections(mask: int) -> String:
	match mask:
		0:  # No connections
			return "isolated"

		# Straight corridors
		LEFT, RIGHT, LEFT | RIGHT:
			return "horizontal"
		UP, DOWN, UP | DOWN:
			return "vertical"

		# Corners
		UP | LEFT:
			return "corner_ul"
		UP | RIGHT:
			return "corner_ur"
		DOWN | LEFT:
			return "corner_dl"
		DOWN | RIGHT:
			return "corner_dr"

		# T-junctions
		LEFT | RIGHT | UP:
			return "t_up"
		LEFT | RIGHT | DOWN:
			return "t_down"
		UP | DOWN | LEFT:
			return "t_left"
		UP | DOWN | RIGHT:
			return "t_right"

		# Cross
		UP | DOWN | LEFT | RIGHT:
			return "cross"

		_:
			return "isolated"

# Update corridor tile at position and all neighbors
static func update_corridor_and_neighbors(ship: ShipDefinition, pos: Vector2i) -> Array:
	var updated_positions: Array = []

	# Update the corridor at this position
	var tile = ship.get_tile(pos)
	if tile and tile.tile_type == PartCategory.TileType.CORRIDOR:
		tile.sprite = get_corridor_sprite(ship, pos)
		updated_positions.append(pos)

	# Update all 4 neighboring corridors
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]

	for dir in directions:
		var neighbor_pos = pos + dir
		var neighbor_tile = ship.get_tile(neighbor_pos)

		if neighbor_tile and neighbor_tile.tile_type == PartCategory.TileType.CORRIDOR:
			neighbor_tile.sprite = get_corridor_sprite(ship, neighbor_pos)
			updated_positions.append(neighbor_pos)

	return updated_positions
