# res://OrbitalBody.gd
@tool
extends Node2D

# Orbital parameters
@export var orbit_center: Vector2 = Vector2.ZERO:
	set(value):
		orbit_center = value
		_update_position()

@export var semi_major_axis: float = 300.0:
	set(value):
		semi_major_axis = value
		_update_position()

@export var semi_minor_axis: float = 250.0:
	set(value):
		semi_minor_axis = value
		_update_position()

@export var orbital_period: float = 10.0:
	set(value):
		orbital_period = value
		_calculate_velocity()

@export var start_angle: float = 0.0:
	set(value):
		start_angle = value
		current_angle = value
		_update_position()

@export var clockwise: bool = true:
	set(value):
		clockwise = value
		_calculate_velocity()

var current_angle: float = 0.0
var angular_velocity: float = 0.0
var _is_ready: bool = false

func _ready() -> void:
	_is_ready = true
	current_angle = start_angle
	_calculate_velocity()
	_update_position()

func _process(delta: float) -> void:
	if !Engine.is_editor_hint():
		current_angle += angular_velocity * delta
		_update_position()

func _calculate_velocity() -> void:
	# Calculate angular velocity: 2π / period
	if orbital_period > 0:
		angular_velocity = (TAU / orbital_period) * (-1.0 if clockwise else 1.0)

func _update_position() -> void:
	if !_is_ready:
		return
	# Elliptical orbit equation
	var x := orbit_center.x + semi_major_axis * cos(current_angle)
	var y := orbit_center.y + semi_minor_axis * sin(current_angle)
	position = Vector2(x, y)

# Helper to get orbit bounds for camera
func get_orbit_bounds() -> Rect2:
	return Rect2(
		orbit_center.x - semi_major_axis,
		orbit_center.y - semi_minor_axis,
		semi_major_axis * 2.0,
		semi_minor_axis * 2.0
	)
