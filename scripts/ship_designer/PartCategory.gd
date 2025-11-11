# res://scripts/ship_designer/PartCategory.gd
class_name PartCategory

enum Type {
	PROPULSION,
	ENERGY,
	CREW,
	SENSORS,
	UTILITY,
	DEFENSE
}

enum TileType {
	CORRIDOR,
	DOOR,
	AIRLOCK,
	FLOOR
}

enum Orientation {
	HORIZONTAL,
	VERTICAL,
	BOTH
}

# Helper function to get category name
static func get_category_name(category: Type) -> String:
	match category:
		Type.PROPULSION: return "Propulsion"
		Type.ENERGY: return "Energy"
		Type.CREW: return "Crew"
		Type.SENSORS: return "Sensors"
		Type.UTILITY: return "Utility"
		Type.DEFENSE: return "Defense"
		_: return "Unknown"

# Helper function to get tile type name
static func get_tile_type_name(tile_type: TileType) -> String:
	match tile_type:
		TileType.CORRIDOR: return "Corridor"
		TileType.DOOR: return "Door"
		TileType.AIRLOCK: return "Airlock"
		TileType.FLOOR: return "Floor"
		_: return "Unknown"
