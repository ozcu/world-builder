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

		# Check if we collided with another ship
		if collider is CharacterBody2D and (collider.name.begins_with("NPCShip") or collider.name.begins_with("Starship")):
			# Get the other ship's mass and velocity
			var other_mass = collider.get("mass")
			if other_mass == null:
				other_mass = 500.0  # Default mass if not set

			var other_velocity = Vector2.ZERO
			if collider.has_method("get_ship_velocity"):
				other_velocity = collider.get_ship_velocity()
			elif collider.get("ship_velocity") != null:
				other_velocity = collider.get("ship_velocity")

			# Calculate collision normal and relative velocity
			var collision_normal = collision.get_normal()
			var relative_velocity = ship_velocity - other_velocity

			# Only apply force if ships are moving toward each other
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
