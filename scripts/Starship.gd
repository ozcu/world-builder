# res://scripts/Starship.gd
extends RigidBody2D

@export var acceleration: float = 500.0
@export var max_speed: float = 400.0
@export var rotation_speed: float = 3.0
@export var drag: float = 0.98  # Friction in space

var velocity: Vector2 = Vector2.ZERO
var thrust_input: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Set up RigidBody2D properties
	gravity_scale = 0.0  # No gravity in space
	linear_damp = 0.5
	angular_damp = 2.0

func _process(_delta: float) -> void:
	# Get input from arrow keys
	thrust_input = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		thrust_input.y -= 1
	if Input.is_action_pressed("ui_down"):
		thrust_input.y += 1
	if Input.is_action_pressed("ui_left"):
		thrust_input.x -= 1
	if Input.is_action_pressed("ui_right"):
		thrust_input.x += 1

	# Normalize to prevent faster diagonal movement
	if thrust_input.length() > 0:
		thrust_input = thrust_input.normalized()

func _physics_process(delta: float) -> void:
	# Apply acceleration based on input
	if thrust_input.length() > 0:
		velocity += thrust_input * acceleration * delta

	# Apply drag
	velocity *= drag

	# Limit max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	# Apply velocity to RigidBody2D
	linear_velocity = velocity

	# Rotate ship to face movement direction
	if velocity.length() > 10.0:  # Only rotate when moving
		var target_rotation = velocity.angle() + PI / 2  # +90 degrees because ship points up
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

func get_velocity() -> Vector2:
	return velocity

func get_speed() -> float:
	return velocity.length()
