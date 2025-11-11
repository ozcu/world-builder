# res://scripts/ship_designer/PartPlacement.gd
class_name PartPlacement extends Resource

@export var part: ShipPart
@export var grid_position: Vector2i = Vector2i(0, 0)
@export var rotation: int = 0  # Rotation in degrees: 0, 90, 180, 270
@export var enabled: bool = true  # Can disable parts without removing

# Legacy support for old horizontal bool
@export var horizontal: bool = true

func _init() -> void:
	resource_local_to_scene = true

func get_occupied_cells() -> Array:
	var cells: Array = []
	if part == null:
		return cells

	var size = part.size
	# Swap width and height for 90° and 270° rotations
	if rotation == 90 or rotation == 270:
		size = Vector2i(size.y, size.x)

	for x in size.x:
		for y in size.y:
			cells.append(grid_position + Vector2i(x, y))

	return cells

func get_actual_door_positions() -> Array:
	var doors: Array = []
	if part == null or !part.has_doors():
		return doors

	for i in part.door_positions.size():
		var door_pos = part.door_positions[i]
		door_pos = rotate_vector(door_pos, rotation)
		doors.append(grid_position + door_pos)

	return doors

func get_actual_door_directions() -> Array:
	var directions: Array = []
	if part == null or !part.has_doors():
		return directions

	for direction in part.door_directions:
		direction = rotate_vector(direction, rotation)
		directions.append(direction)

	return directions

func rotate_vector(vec: Vector2i, degrees: int) -> Vector2i:
	# Rotate a Vector2i by the given degrees (0, 90, 180, 270)
	match degrees:
		90:
			# Clockwise 90°: (x, y) -> (y, -x)
			# But for grid coordinates: (x, y) -> (-y, x)
			return Vector2i(-vec.y, vec.x)
		180:
			# 180°: (x, y) -> (-x, -y)
			return Vector2i(-vec.x, -vec.y)
		270:
			# Clockwise 270° (or counter-clockwise 90°): (x, y) -> (-y, x)
			# But for grid coordinates: (x, y) -> (y, -x)
			return Vector2i(vec.y, -vec.x)
		_:
			# 0° or default
			return vec
