# res://scripts/Starship.gd
extends CharacterBody2D

@export var acceleration: float = 500.0
@export var max_speed: float = 400.0
@export var rotation_speed: float = 2.5
@export var drag: float = 0.98  # Friction in space

var ship_velocity: Vector2 = Vector2.ZERO
var thrust_amount: float = 0.0

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

func get_ship_velocity() -> Vector2:
	return ship_velocity

func get_speed() -> float:
	return ship_velocity.length()
