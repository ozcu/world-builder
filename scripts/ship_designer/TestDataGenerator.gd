# res://scripts/ship_designer/TestDataGenerator.gd
# Generates test tiles and parts for development
class_name TestDataGenerator extends Node

static func create_test_tiles() -> Dictionary:
	var tiles = {}

	# Corridor - Straight Horizontal
	var corridor_h = ShipTile.new()
	corridor_h.tile_id = "corridor_straight_h"
	corridor_h.tile_name = "Corridor (Horizontal)"
	corridor_h.tile_type = PartCategory.TileType.CORRIDOR
	corridor_h.connections = [Vector2i(-1, 0), Vector2i(1, 0)]  # Left and right
	corridor_h.sprite = MockupGenerator.create_corridor_mockup(corridor_h.connections)
	tiles["corridor_straight_h"] = corridor_h

	# Corridor - Straight Vertical
	var corridor_v = ShipTile.new()
	corridor_v.tile_id = "corridor_straight_v"
	corridor_v.tile_name = "Corridor (Vertical)"
	corridor_v.tile_type = PartCategory.TileType.CORRIDOR
	corridor_v.connections = [Vector2i(0, -1), Vector2i(0, 1)]  # Up and down
	corridor_v.sprite = MockupGenerator.create_corridor_mockup(corridor_v.connections)
	tiles["corridor_straight_v"] = corridor_v

	# Corridor - L Corner
	var corridor_l = ShipTile.new()
	corridor_l.tile_id = "corridor_corner_l"
	corridor_l.tile_name = "Corridor (L-Corner)"
	corridor_l.tile_type = PartCategory.TileType.CORRIDOR
	corridor_l.connections = [Vector2i(1, 0), Vector2i(0, 1)]  # Right and down
	corridor_l.sprite = MockupGenerator.create_corridor_mockup(corridor_l.connections)
	tiles["corridor_corner_l"] = corridor_l

	# Corridor - T Junction
	var corridor_t = ShipTile.new()
	corridor_t.tile_id = "corridor_t"
	corridor_t.tile_name = "Corridor (T-Junction)"
	corridor_t.tile_type = PartCategory.TileType.CORRIDOR
	corridor_t.connections = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]  # 3-way
	corridor_t.sprite = MockupGenerator.create_corridor_mockup(corridor_t.connections)
	tiles["corridor_t"] = corridor_t

	# Corridor - X Junction
	var corridor_x = ShipTile.new()
	corridor_x.tile_id = "corridor_x"
	corridor_x.tile_name = "Corridor (X-Junction)"
	corridor_x.tile_type = PartCategory.TileType.CORRIDOR
	corridor_x.connections = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]  # 4-way
	corridor_x.sprite = MockupGenerator.create_corridor_mockup(corridor_x.connections)
	tiles["corridor_x"] = corridor_x

	# Door
	var door = ShipTile.new()
	door.tile_id = "door_standard"
	door.tile_name = "Standard Door"
	door.tile_type = PartCategory.TileType.DOOR
	door.connections = [Vector2i(-1, 0), Vector2i(1, 0)]  # Horizontal
	door.sprite = MockupGenerator.create_door_mockup()
	tiles["door_standard"] = door

	# Airlock
	var airlock = ShipTile.new()
	airlock.tile_id = "airlock"
	airlock.tile_name = "Airlock"
	airlock.tile_type = PartCategory.TileType.AIRLOCK
	airlock.connections = [Vector2i(0, -1)]  # Only connects inward
	airlock.sprite = MockupGenerator.create_airlock_mockup()
	tiles["airlock"] = airlock

	return tiles

static func create_test_parts() -> Dictionary:
	var parts = {}

	# Small Thruster (1x2)
	var thruster_small = ShipPart.new()
	thruster_small.part_id = "thruster_small"
	thruster_small.part_name = "Small Thruster"
	thruster_small.category = PartCategory.Type.PROPULSION
	thruster_small.size = Vector2i(1, 2)
	thruster_small.mass = 50.0
	thruster_small.door_positions = [Vector2i(0, 0)]  # Top
	thruster_small.door_directions = [Vector2i(0, -1)]  # Facing up
	thruster_small.special_properties = {"thrust_power": 100.0, "direction": Vector2(0, -1)}
	thruster_small.sprite = MockupGenerator.create_part_mockup(
		thruster_small.size,
		Color(0.8, 0.3, 0.1),  # Orange
		thruster_small.door_positions
	)
	parts["thruster_small"] = thruster_small

	# Medium Thruster (2x2)
	var thruster_medium = ShipPart.new()
	thruster_medium.part_id = "thruster_medium"
	thruster_medium.part_name = "Medium Thruster"
	thruster_medium.category = PartCategory.Type.PROPULSION
	thruster_medium.size = Vector2i(2, 2)
	thruster_medium.mass = 150.0
	thruster_medium.door_positions = [Vector2i(1, 0)]  # Top center
	thruster_medium.door_directions = [Vector2i(0, -1)]
	thruster_medium.special_properties = {"thrust_power": 300.0, "direction": Vector2(0, -1)}
	thruster_medium.sprite = MockupGenerator.create_part_mockup(
		thruster_medium.size,
		Color(0.9, 0.4, 0.1),
		thruster_medium.door_positions
	)
	parts["thruster_medium"] = thruster_medium

	# Nuclear Reactor (4x4)
	var reactor = ShipPart.new()
	reactor.part_id = "reactor_nuclear"
	reactor.part_name = "Nuclear Reactor"
	reactor.category = PartCategory.Type.ENERGY
	reactor.size = Vector2i(4, 4)
	reactor.mass = 500.0
	reactor.door_positions = [Vector2i(0, 2)]  # Left side, middle
	reactor.door_directions = [Vector2i(-1, 0)]
	reactor.special_properties = {"energy_output": 1000.0}
	reactor.sprite = MockupGenerator.create_part_mockup(
		reactor.size,
		Color(0.2, 0.8, 0.2),  # Green
		reactor.door_positions
	)
	parts["reactor_nuclear"] = reactor

	# Energy Storage (2x3)
	var battery = ShipPart.new()
	battery.part_id = "energy_storage"
	battery.part_name = "Energy Storage"
	battery.category = PartCategory.Type.ENERGY
	battery.size = Vector2i(2, 3)
	battery.mass = 100.0
	battery.door_positions = [Vector2i(1, 0)]  # Top
	battery.door_directions = [Vector2i(0, -1)]
	battery.special_properties = {"energy_capacity": 5000.0}
	battery.sprite = MockupGenerator.create_part_mockup(
		battery.size,
		Color(0.3, 0.9, 0.3),
		battery.door_positions
	)
	parts["energy_storage"] = battery

	# Bunk Beds (2x2) - REQUIRED
	var bunks = ShipPart.new()
	bunks.part_id = "crew_bunks"
	bunks.part_name = "Bunk Beds"
	bunks.category = PartCategory.Type.CREW
	bunks.size = Vector2i(2, 2)
	bunks.mass = 80.0
	bunks.door_positions = [Vector2i(0, 1)]  # Left side, bottom
	bunks.door_directions = [Vector2i(-1, 0)]
	bunks.special_properties = {"crew_capacity": 4}
	bunks.sprite = MockupGenerator.create_part_mockup(
		bunks.size,
		Color(0.4, 0.4, 0.8),  # Blue
		bunks.door_positions
	)
	parts["crew_bunks"] = bunks

	# Crew Quarters (3x3)
	var quarters = ShipPart.new()
	quarters.part_id = "crew_quarters"
	quarters.part_name = "Crew Quarters"
	quarters.category = PartCategory.Type.CREW
	quarters.size = Vector2i(3, 3)
	quarters.mass = 150.0
	quarters.door_positions = [Vector2i(1, 0)]  # Top center
	quarters.door_directions = [Vector2i(0, -1)]
	quarters.special_properties = {"crew_capacity": 8, "morale_bonus": 10}
	quarters.sprite = MockupGenerator.create_part_mockup(
		quarters.size,
		Color(0.5, 0.5, 0.9),
		quarters.door_positions
	)
	parts["crew_quarters"] = quarters

	# Bridge (4x4)
	var bridge = ShipPart.new()
	bridge.part_id = "bridge"
	bridge.part_name = "Bridge"
	bridge.category = PartCategory.Type.CREW
	bridge.size = Vector2i(4, 4)
	bridge.mass = 200.0
	bridge.door_positions = [Vector2i(2, 0)]  # Top center
	bridge.door_directions = [Vector2i(0, -1)]
	bridge.special_properties = {"command_center": true}
	bridge.sprite = MockupGenerator.create_part_mockup(
		bridge.size,
		Color(0.3, 0.3, 0.9),
		bridge.door_positions
	)
	parts["bridge"] = bridge

	# Sensor Array (2x2)
	var sensor = ShipPart.new()
	sensor.part_id = "sensor_basic"
	sensor.part_name = "Basic Sensor"
	sensor.category = PartCategory.Type.SENSORS
	sensor.size = Vector2i(2, 2)
	sensor.mass = 40.0
	sensor.door_positions = [Vector2i(1, 1)]  # Bottom center
	sensor.door_directions = [Vector2i(0, 1)]
	sensor.special_properties = {"scan_range": 500.0}
	sensor.sprite = MockupGenerator.create_part_mockup(
		sensor.size,
		Color(0.8, 0.8, 0.2),  # Yellow
		sensor.door_positions
	)
	parts["sensor_basic"] = sensor

	# Tractor Beam (2x2)
	var tractor = ShipPart.new()
	tractor.part_id = "tractor_beam"
	tractor.part_name = "Tractor Beam"
	tractor.category = PartCategory.Type.UTILITY
	tractor.size = Vector2i(2, 2)
	tractor.mass = 70.0
	tractor.door_positions = [Vector2i(1, 1)]  # Bottom
	tractor.door_directions = [Vector2i(0, 1)]
	tractor.special_properties = {"pull_force": 500.0, "range": 200.0}
	tractor.sprite = MockupGenerator.create_part_mockup(
		tractor.size,
		Color(0.6, 0.2, 0.8),  # Purple
		tractor.door_positions
	)
	parts["tractor_beam"] = tractor

	# Cargo Hold Small (3x3)
	var cargo_small = ShipPart.new()
	cargo_small.part_id = "cargo_small"
	cargo_small.part_name = "Small Cargo Hold"
	cargo_small.category = PartCategory.Type.UTILITY
	cargo_small.size = Vector2i(3, 3)
	cargo_small.mass = 100.0
	cargo_small.door_positions = [Vector2i(0, 1)]  # Left side
	cargo_small.door_directions = [Vector2i(-1, 0)]
	cargo_small.special_properties = {"cargo_capacity": 100}
	cargo_small.sprite = MockupGenerator.create_part_mockup(
		cargo_small.size,
		Color(0.7, 0.5, 0.2),  # Brown
		cargo_small.door_positions
	)
	parts["cargo_small"] = cargo_small

	# Armor Plate (1x1)
	var armor = ShipPart.new()
	armor.part_id = "armor_plate"
	armor.part_name = "Armor Plate"
	armor.category = PartCategory.Type.DEFENSE
	armor.size = Vector2i(1, 1)
	armor.mass = 30.0
	armor.is_external = true  # No doors needed
	armor.special_properties = {"armor_value": 10}
	armor.sprite = MockupGenerator.create_part_mockup(
		armor.size,
		Color(0.6, 0.6, 0.6),  # Gray
		[]  # No doors
	)
	parts["armor_plate"] = armor

	return parts
