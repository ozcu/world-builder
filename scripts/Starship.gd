# res://scripts/Starship.gd
extends CharacterBody2D

@export var acceleration: float = 500.0
@export var max_speed: float = 400.0
@export var rotation_speed: float = 2.5
@export var drag: float = 0.98  # Friction in space
@export var mass: float = 1000.0  # Ship mass for collision physics

var ship_velocity: Vector2 = Vector2.ZERO
var thrust_amount: float = 0.0

@onready var thruster_left: Sprite2D = $ThrusterLeft
@onready var thruster_center: Sprite2D = $ThrusterCenter
@onready var thruster_right: Sprite2D = $ThrusterRight

func _ready() -> void:
	# CharacterBody2D doesn't need physics setup
	pass

func _process(delta: float) -> void:
	# Get rotation input from left/right arrows
	var rotation_input: float = 0.0
	if Input.is_action_pressed("ui_left"):
		rotation_input -= 1.0
	if Input.is_action_pressed("ui_right"):
		rotation_input += 1.0

	# Get thrust input from up/down arrows
	thrust_amount = 0.0
	if Input.is_action_pressed("ui_up"):
		thrust_amount = 1.0
	elif Input.is_action_pressed("ui_down"):
		thrust_amount = -0.5  # Reverse thrust is weaker

	# Apply rotation directly - no physics interference!
	if rotation_input != 0.0:
		rotation += rotation_input * rotation_speed * delta

func _physics_process(delta: float) -> void:
	# Apply thrust in the direction the ship is facing
	if thrust_amount != 0.0:
		var thrust_direction = Vector2(0, -1).rotated(rotation)  # Ship points up
		ship_velocity += thrust_direction * thrust_amount * acceleration * delta

	# Apply drag
	ship_velocity *= drag

	# Limit max speed
	if ship_velocity.length() > max_speed:
		ship_velocity = ship_velocity.normalized() * max_speed

	# Set velocity and move - CharacterBody2D way
	velocity = ship_velocity
	move_and_slide()

	# Handle collisions with other ships
	_handle_collisions()

	# Update thruster visibility based on thrust and speed
	_update_thrusters()

func _handle_collisions() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		# Check if we collided with another ship or space station
		var is_ship = collider is CharacterBody2D and (collider.name.begins_with("NPCShip") or collider.name.begins_with("Starship"))
		var is_station = collider is StaticBody2D and collider.name.begins_with("SpaceStation")

		if is_ship or is_station:
			# Get the other object's mass and velocity
			var other_mass = collider.get("mass")
			if other_mass == null:
				other_mass = 500.0  # Default mass if not set

			var other_velocity = Vector2.ZERO
			# Static bodies don't move
			if is_ship:
				if collider.has_method("get_ship_velocity"):
					other_velocity = collider.get_ship_velocity()
				elif collider.get("ship_velocity") != null:
					other_velocity = collider.get("ship_velocity")

			# Calculate collision normal and relative velocity
			var collision_normal = collision.get_normal()
			var relative_velocity = ship_velocity - other_velocity

			# Only apply force if moving toward the object
			var closing_speed = relative_velocity.dot(collision_normal)
			if closing_speed < 0:
				# Apply momentum-based collision response
				# Using coefficient of restitution (bounciness) of 0.5
				var restitution = 0.5
				var impulse_magnitude = -(1 + restitution) * closing_speed / (1.0/mass + 1.0/other_mass)

				# Apply impulse to this ship
				var impulse = collision_normal * impulse_magnitude / mass
				ship_velocity += impulse

func _update_thrusters() -> void:
	var speed_ratio = ship_velocity.length() / max_speed
	var base_alpha = 0.0

	# Show thrusters when thrusting forward
	if thrust_amount > 0.0:
		base_alpha = 0.7 + thrust_amount * 0.3
	elif ship_velocity.length() > 10.0:
		# Dim glow when coasting
		base_alpha = speed_ratio * 0.4

	# Add flicker effect
	var flicker = 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.15

	# Apply to all thrusters
	if thruster_left:
		thruster_left.modulate.a = base_alpha * flicker
		thruster_left.scale.y = 0.6 + thrust_amount * 0.4
	if thruster_center:
		thruster_center.modulate.a = base_alpha * flicker * 1.1
		thruster_center.scale.y = 0.6 + thrust_amount * 0.5
	if thruster_right:
		thruster_right.modulate.a = base_alpha * flicker
		thruster_right.scale.y = 0.6 + thrust_amount * 0.4

func get_ship_velocity() -> Vector2:
	return ship_velocity

func get_speed() -> float:
	return ship_velocity.length()

# Ship design system
var ship_definition: ShipDefinition = null
var ship_renderer: ShipRenderer = null

func apply_ship_design(design: ShipDefinition) -> void:
	"""Apply a ship design from the ship designer to this starship"""
	ship_definition = design

	# Hide the original ship sprite - we're replacing it with the design
	var original_sprite = get_node_or_null("Sprite2D")
	if original_sprite:
		original_sprite.visible = false

	# Hide thruster sprites - design replaces them
	if thruster_left:
		thruster_left.visible = false
	if thruster_center:
		thruster_center.visible = false
	if thruster_right:
		thruster_right.visible = false

	# Remove old renderer if exists
	if ship_renderer:
		ship_renderer.queue_free()

	# Create new renderer
	ship_renderer = ShipRenderer.new()
	ship_renderer.ship_definition = design
	ship_renderer.cell_size = 8  # Scale down from designer (32 -> 8) for reasonable ship size
	ship_renderer.auto_center = false  # We'll center manually
	ship_renderer.z_index = -1  # Behind everything

	# Calculate center offset manually to center the ship on the Starship's origin
	var bounds = design.get_bounds()
	var ship_pixel_size = Vector2(bounds.size.x * 8, bounds.size.y * 8)  # cell_size = 8
	var center_offset = -ship_pixel_size / 2.0 - Vector2(bounds.position.x * 8, bounds.position.y * 8)
	ship_renderer.position = center_offset

	add_child(ship_renderer)

	# Explicitly call render_ship after it's added to scene tree
	# (In case _ready() didn't trigger yet)
	ship_renderer.call_deferred("render_ship")

	print("Starship: Applied ship design '", design.ship_name, "'")
	print("  Tiles: ", design.tile_positions.size())
	print("  Parts: ", design.parts.size())
	print("  Bounds: ", bounds)
	print("  Center offset: ", center_offset)
	print("  Ship renderer cell_size: ", ship_renderer.cell_size)

	# Debug: print first few tile positions
	for i in min(3, design.tile_positions.size()):
		var pos = design.tile_positions[i]
		var pixel_pos = Vector2(pos.x * 8, pos.y * 8)  # cell_size = 8
		print("  Tile ", i, " at grid ", pos, " -> pixel ", pixel_pos)

	# Debug: print all part placements
	print("  Part placements:")
	for i in design.parts.size():
		var placement = design.parts[i]
		var cells = placement.get_occupied_cells()
		print("    Part ", i, ": ", placement.part.part_name, " at ", placement.grid_position,
		      " rotation ", placement.rotation, "° occupies ", cells.size(), " cells: ", cells)
