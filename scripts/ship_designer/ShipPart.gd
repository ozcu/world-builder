# res://scripts/ship_designer/ShipPart.gd
class_name ShipPart extends Resource

@export var part_id: String = ""
@export var part_name: String = ""
@export var category: PartCategory.Type = PartCategory.Type.PROPULSION
@export var sprite: Texture2D
@export var size: Vector2i = Vector2i(1, 1)  # Grid cells occupied (width, height)

# Physical properties
@export var mass: float = 50.0  # kg
@export var power_consumption: float = 0.0  # Watts
@export var integrity: int = 100  # HP

# Door system - relative positions within part bounds
# Example: For a 2x2 part, door at (1, 0) means top-center
@export var door_positions: Array[Vector2i] = []
# Direction each door faces (must match door_positions length)
# (0, -1) = up, (0, 1) = down, (-1, 0) = left, (1, 0) = right
@export var door_directions: Array[Vector2i] = []

# External parts (like armor) don't need doors
@export var is_external: bool = false

# Placement constraints
@export var orientation: PartCategory.Orientation = PartCategory.Orientation.BOTH

# Special properties (category-specific)
@export var special_properties: Dictionary = {}
# Examples:
#   {"thrust_power": 300.0, "direction": Vector2(0, -1)}  # Thruster
#   {"energy_output": 1000.0}  # Reactor
#   {"crew_capacity": 4}  # Bunk beds
#   {"cargo_capacity": 100}  # Cargo hold

func _init() -> void:
	resource_local_to_scene = true

func has_doors() -> bool:
	return !is_external and door_positions.size() > 0

func get_door_count() -> int:
	return door_positions.size()

# Get world position of a door
func get_door_world_pos(placement_pos: Vector2i, door_index: int) -> Vector2i:
	if door_index < 0 or door_index >= door_positions.size():
		return placement_pos
	return placement_pos + door_positions[door_index]

# Get the cell that the door connects to
func get_door_connection_cell(placement_pos: Vector2i, door_index: int) -> Vector2i:
	if door_index < 0 or door_index >= door_directions.size():
		return placement_pos
	var door_world = get_door_world_pos(placement_pos, door_index)
	return door_world + door_directions[door_index]
