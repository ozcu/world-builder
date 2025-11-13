extends RigidBody2D

@export var acceleration: float = 500.0
@export var max_speed: float = 400.0
@export var rotation_speed: float = 2.5
@export var drag: float = 0.98  # inertia stabilization
@export var reverse_factor: float = 0.5

var thrust_input := 0.0
var current_speed: float = 0.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Ship design system
var ship_definition: ShipDefinition = null
var ship_renderer: ShipRenderer = null

func _process(delta: float) -> void:
	# Handle rotation
	if Input.is_action_pressed("ui_left"):
		rotation -= rotation_speed * delta
	if Input.is_action_pressed("ui_right"):
		rotation += rotation_speed * delta

	# Update current speed for HUD
	current_speed = linear_velocity.length()

func _physics_process(delta: float) -> void:
	# Get thrust input
	thrust_input = 0.0
	if Input.is_action_pressed("ui_up"):
		thrust_input = 1.0
	elif Input.is_action_pressed("ui_down"):
		thrust_input = -reverse_factor

	# Apply thrust force
	if thrust_input != 0.0:
		var forward := -transform.y  # ship faces +Y
		var thrust_force = forward * acceleration * thrust_input * mass
		apply_central_force(thrust_force)

	# Apply drag
	var drag_force = -linear_velocity * (1.0 - drag) * mass / delta
	apply_central_force(drag_force)

	# Speed limit
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func get_speed() -> float:
	"""Return current speed for HUD display"""
	return current_speed

func apply_ship_design(design: ShipDefinition) -> void:
	"""Apply a ship design from the ship designer to this starship"""
	ship_definition = design

	# Hide the original ship sprite - we're replacing it with the design
	if sprite:
		sprite.visible = false

	# Remove old renderer if exists
	if ship_renderer:
		ship_renderer.queue_free()

	# Create new renderer
	ship_renderer = ShipRenderer.new()
	ship_renderer.ship_definition = design
	ship_renderer.cell_size = 32  # Same scale as designer for clarity (1:1 scale)
	ship_renderer.auto_center = false  # We'll center manually on Starship origin
	ship_renderer.z_index = -1  # Behind everything

	# Calculate the center of the ship design in grid coordinates
	var bounds = design.get_bounds()
	var design_center_grid = Vector2(
		bounds.position.x + bounds.size.x / 2.0,
		bounds.position.y + bounds.size.y / 2.0
	)

	# Convert to pixel coordinates
	var design_center_pixels = design_center_grid * ship_renderer.cell_size

	# Position renderer so design center is at Starship origin (0, 0)
	# This ensures the ship rotates around its visual center
	ship_renderer.position = -design_center_pixels

	add_child(ship_renderer)

	# Explicitly call render_ship after it's added to scene tree
	# (In case _ready() didn't trigger yet)
	ship_renderer.call_deferred("render_ship")

	# Update collision shape to match ship design bounds
	update_collision_shape(bounds, design_center_grid)

	print("Starship: Applied ship design '", design.ship_name, "'")
	print("  Tiles: ", design.tile_positions.size())
	print("  Parts: ", design.parts.size())
	print("  Bounds: ", bounds)
	print("  Design center (grid): ", design_center_grid)
	print("  Design center (pixels): ", design_center_pixels)
	print("  Renderer position offset: ", ship_renderer.position)
	print("  Cell size: ", ship_renderer.cell_size)

func update_collision_shape(bounds: Rect2i, design_center_grid: Vector2) -> void:
	"""Update the collision shape to match the ship design bounds"""
	if !collision_shape:
		print("Starship: No collision shape found!")
		return

	var cell_size = 32  # Must match ship_renderer.cell_size

	# Calculate the size in pixels
	var size_pixels = Vector2(bounds.size) * cell_size

	# Calculate the offset from center
	# Since we positioned the renderer so design center is at (0, 0),
	# we need to position the collision shape relative to that center
	var bounds_center_grid = Vector2(
		bounds.position.x + bounds.size.x / 2.0,
		bounds.position.y + bounds.size.y / 2.0
	)
	var offset_from_design_center = (bounds_center_grid - design_center_grid) * cell_size

	# Update the shape
	var rect_shape = collision_shape.shape as RectangleShape2D
	if rect_shape:
		rect_shape.size = size_pixels
		collision_shape.position = offset_from_design_center

		print("Starship: Updated collision shape:")
		print("  Bounds in grid: ", bounds)
		print("  Size (pixels): ", size_pixels)
		print("  Offset from center: ", offset_from_design_center)
