# res://scripts/ship_designer/PartPlacement.gd
class_name PartPlacement extends Resource

@export var part: ShipPart
@export var grid_position: Vector2i = Vector2i(0, 0)
@export var horizontal: bool = true  # True = horizontal, False = vertical
@export var enabled: bool = true  # Can disable parts without removing

func _init() -> void:
	resource_local_to_scene = true

func get_occupied_cells() -> Array:
	var cells: Array = []
	if part == null:
		return cells

	var size = part.size
	if !horizontal:
		# Swap width and height for vertical placement
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
		if !horizontal:
			# Rotate door position for vertical placement
			door_pos = Vector2i(door_pos.y, door_pos.x)
		doors.append(grid_position + door_pos)

	return doors

func get_actual_door_directions() -> Array:
	var directions: Array = []
	if part == null or !part.has_doors():
		return directions

	for direction in part.door_directions:
		if !horizontal:
			# Rotate direction for vertical placement
			# (0, -1) up -> (-1, 0) left
			# (0, 1) down -> (1, 0) right
			# (-1, 0) left -> (0, 1) down
			# (1, 0) right -> (0, -1) up
			direction = Vector2i(-direction.y, direction.x)
		directions.append(direction)

	return directions
