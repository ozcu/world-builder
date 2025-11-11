# res://scripts/ship_designer/ShipTile.gd
class_name ShipTile extends Resource

@export var tile_id: String = ""
@export var tile_name: String = ""
@export var tile_type: PartCategory.TileType = PartCategory.TileType.CORRIDOR
@export var sprite: Texture2D
@export var mass: float = 10.0  # kg per tile
@export var integrity: int = 100  # HP

# Which sides can connect (for corridor routing)
# Array of Vector2i: [(1,0), (-1,0), (0,1), (0,-1)] for 4-way junction
@export var connections: Array[Vector2i] = []

# Visual variant (for same type but different look)
@export var variant: int = 0

func _init() -> void:
	resource_local_to_scene = true

func can_connect_to(direction: Vector2i) -> bool:
	return direction in connections
