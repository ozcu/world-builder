# res://SolarSystem.gd
extends Node2D

@export var sun_position: Vector2 = Vector2(576, 324)
@export var camera_margin: float = 150.0
@export var num_planets: int = 3

@onready var camera: Camera2D = $Camera2D
@onready var sun: Node2D = $Sun2D

var orbital_bodies: Array[Node2D] = []

func _ready() -> void:
	if sun:
		sun_position = sun.position

	# Collect orbital bodies
	for child in get_children():
		if child.has_method("get_orbit_bounds"):
			orbital_bodies.append(child)

	call_deferred("_adjust_camera")

func _process(_delta: float) -> void:
	if orbital_bodies.is_empty():
		return
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
