# res://SolarSystem.gd
extends Node2D

@export var sun_position: Vector2 = Vector2(576, 324)
@export var camera_margin: float = 150.0
@export var num_planets: int = 3
@export var camera_speed: float = 300.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.1
@export var max_zoom: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var starship: Node2D = $Starship

var sun: Node2D = null
var orbital_bodies: Array[Node2D] = []
var camera_velocity: Vector2 = Vector2.ZERO
var camera_follow_starship: bool = true  # Auto-follow by default

func _ready() -> void:
	# Find sun in Planets node
	var planets_node = get_node_or_null("Planets")
	if planets_node:
		sun = planets_node.get_node_or_null("Sun2D")
		if sun:
			sun_position = sun.position

	# Collect orbital bodies
	for child in get_children():
		if child.has_method("get_orbit_bounds"):
			orbital_bodies.append(child)

	# Don't adjust camera - use fixed position/zoom set in scene
	# call_deferred("_adjust_camera")

func _process(delta: float) -> void:
	# Make camera follow starship if enabled
	if camera_follow_starship and starship and is_instance_valid(starship):
		camera.position = starship.global_position

	# Always handle camera input
	_handle_camera_input(delta)

	# Update planet lighting only if we have orbital bodies
	if !orbital_bodies.is_empty():
		_update_planet_lighting()

func _update_planet_lighting() -> void:
	for orbital in orbital_bodies:
		if !is_instance_valid(orbital):
			continue
		if orbital.has_node("Planet2D"):
			var planet = orbital.get_node("Planet2D")
			if !is_instance_valid(planet):
				continue
			var planet_pos := orbital.global_position
			var to_sun := sun_position - planet_pos
			var angle := atan2(to_sun.y, to_sun.x)
			planet.light_angle = angle

func _adjust_camera() -> void:
	if camera == null:
		push_error("Camera2D not found")
		return

	if orbital_bodies.is_empty():
		push_warning("No orbital bodies found")
		return

	# Calculate bounding box for all orbits
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)

	for orbital in orbital_bodies:
		var bounds: Rect2 = orbital.get_orbit_bounds()
		min_pos.x = min(min_pos.x, bounds.position.x)
		min_pos.y = min(min_pos.y, bounds.position.y)
		max_pos.x = max(max_pos.x, bounds.end.x)
		max_pos.y = max(max_pos.y, bounds.end.y)

	# Include sun
	min_pos.x = min(min_pos.x, sun_position.x - 100)
	min_pos.y = min(min_pos.y, sun_position.y - 100)
	max_pos.x = max(max_pos.x, sun_position.x + 100)
	max_pos.y = max(max_pos.y, sun_position.y + 100)

	# Add margin
	min_pos -= Vector2(camera_margin, camera_margin)
	max_pos += Vector2(camera_margin, camera_margin)

	# Calculate required zoom
	var bounds_size := max_pos - min_pos
	var viewport_size := get_viewport_rect().size
	var zoom_x := viewport_size.x / bounds_size.x
	var zoom_y := viewport_size.y / bounds_size.y
	var zoom_value: float = min(zoom_x, zoom_y) * 0.9  # 90% to ensure everything fits

	# Zoom out by 2x (divide zoom by 2)
	camera.zoom = Vector2(zoom_value, zoom_value) * 0.5
	camera.position = (min_pos + max_pos) / 2.0

func _handle_camera_input(delta: float) -> void:
	# WASD camera movement (disables auto-follow)
	camera_velocity = Vector2.ZERO

	if Input.is_action_pressed("ui_text_indent"):  # D key
		camera_velocity.x += 1
	if Input.is_action_pressed("ui_text_dedent"):  # A key (not standard, will use direct key check)
		camera_velocity.x -= 1

	# Check WASD keys directly
	if Input.is_key_pressed(KEY_W):
		camera_velocity.y -= 1
	if Input.is_key_pressed(KEY_S):
		camera_velocity.y += 1
	if Input.is_key_pressed(KEY_A):
		camera_velocity.x -= 1
	if Input.is_key_pressed(KEY_D):
		camera_velocity.x += 1

	# Normalize and apply camera speed
	if camera_velocity.length() > 0:
		camera_follow_starship = false  # Disable auto-follow when manually controlling
		camera_velocity = camera_velocity.normalized() * camera_speed
		# Adjust for zoom level (move faster when zoomed out)
		camera.position += camera_velocity * delta / camera.zoom.x

func _input(event: InputEvent) -> void:
	# Mouse wheel zoom and middle button camera centering
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var new_zoom = camera.zoom.x + zoom_speed
			new_zoom = clamp(new_zoom, min_zoom, max_zoom)
			camera.zoom = Vector2(new_zoom, new_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var new_zoom = camera.zoom.x - zoom_speed
			new_zoom = clamp(new_zoom, min_zoom, max_zoom)
			camera.zoom = Vector2(new_zoom, new_zoom)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			# Center camera on player ship
			if starship:
				camera.position = starship.global_position
