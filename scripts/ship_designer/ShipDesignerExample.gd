# res://scripts/ship_designer/ShipDesignerExample.gd
# Example demonstrating how to use the ship designer system
extends Node

func _ready() -> void:
	# Example: Create a simple ship programmatically
	create_example_ship()

func create_example_ship() -> ShipDefinition:
	print("=== Creating Example Ship ===")

	# Create ship definition
	var ship = ShipDefinition.new()
	ship.ship_name = "Test Vessel"

	# Get test data
	var tiles = TestDataGenerator.create_test_tiles()
	var parts = TestDataGenerator.create_test_parts()

	# Build a simple ship layout
	# Corridor spine (vertical): (10, 10) to (10, 15)
	for y in range(10, 16):
		ship.set_tile(Vector2i(10, y), tiles["corridor_straight_v"])

	# Add horizontal corridor branch at (10, 12)
	ship.set_tile(Vector2i(10, 12), tiles["corridor_t"])
	for x in range(11, 14):
		ship.set_tile(Vector2i(x, 12), tiles["corridor_straight_h"])

	# Add airlock at bottom (10, 16)
	ship.set_tile(Vector2i(10, 16), tiles["airlock"])

	# Add door to bunk room
	ship.set_tile(Vector2i(9, 11), tiles["door_standard"])

	# Place parts
	# Thruster at top - connects to (10, 10) corridor
	var thruster_placement = PartPlacement.new()
	thruster_placement.part = parts["thruster_medium"]
	thruster_placement.grid_position = Vector2i(9, 8)  # Door at (10, 8) connects to corridor at (10, 9)... wait
	# Actually door at (10, 8) facing up would need corridor at (10, 7)
	# Let me fix: thruster at (9, 11), door at top-center (10, 11) faces up to (10, 10) which is corridor
	thruster_placement.grid_position = Vector2i(9, 11)
	thruster_placement.horizontal = true

	if ship.can_place_part(thruster_placement):
		ship.add_part(thruster_placement)
		print("✓ Placed thruster")
	else:
		print("✗ Could not place thruster - door not on corridor")

	# Bunk beds - door on left at (0, 1) = world (8, 12) faces left to (7, 12) - need corridor there
	# Better: place at (11, 11), door at (11, 12) faces left to (10, 12) which is corridor
	var bunk_placement = PartPlacement.new()
	bunk_placement.part = parts["crew_bunks"]
	bunk_placement.grid_position = Vector2i(11, 11)
	bunk_placement.horizontal = true

	if ship.can_place_part(bunk_placement):
		ship.add_part(bunk_placement)
		print("✓ Placed bunks")
	else:
		print("✗ Could not place bunks")

	# Validate ship
	var validation = ship.validate()
	print("\n=== Validation Results ===")
	print("Valid: ", validation.valid)
	if !validation.valid:
		print("Errors:")
		for error in validation.errors:
			print("  - ", error)

	print("\n=== Ship Stats ===")
	print("Mass: ", ship.metadata.total_mass, " kg")
	print("Thrust: ", ship.metadata.thrust_power, " N")
	print("Crew Capacity: ", ship.metadata.crew_capacity)
	print("Bounds: ", ship.get_bounds())

	# Export to JSON
	var json = ship.to_json()
	print("\n=== JSON Export ===")
	print(JSON.stringify(json, "  "))

	return ship
