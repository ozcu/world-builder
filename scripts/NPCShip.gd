# res://scripts/NPCShip.gd
extends CharacterBody2D

@export var cruise_speed: float = 80.0
@export var acceleration: float = 100.0
@export var rotation_speed: float = 1.5
@export var arrival_distance: float = 50.0
@export var separation_distance: float = 200.0
@export var separation_force: float = 150.0
@export var mass: float = 500.0  # Ship mass for collision physics

var current_target: Vector2 = Vector2.ZERO
var ship_velocity: Vector2 = Vector2.ZERO
var hubs: Array[Node2D] = []
var current_hub_index: int = 0
var nearby_ships: Array[Node2D] = []

@onready var thruster_left: Sprite2D = $ThrusterLeft
@onready var thruster_right: Sprite2D = $ThrusterRight

func _ready() -> void:
	# Find all starhubs in the scene
	call_deferred("_find_hubs")

func _find_hubs() -> void:
	var root = get_tree().root
	_collect_hubs(root)
	_find_nearby_ships(root)

	if hubs.size() > 0:
		# Start by heading to first hub
		current_hub_index = randi() % hubs.size()
		current_target = hubs[current_hub_index].global_position
	else:
		# No hubs, just cruise around
		_pick_random_target()

func _find_nearby_ships(node: Node) -> void:
	if node != self and node is CharacterBody2D and node.name.begins_with("NPCShip"):
		nearby_ships.append(node)
	for child in node.get_children():
		_find_nearby_ships(child)

func _collect_hubs(node: Node) -> void:
	if node.name.begins_with("SpaceStation"):
		hubs.append(node)
	for child in node.get_children():
		_collect_hubs(child)

func _pick_random_target() -> void:
	# Pick a random position in space
	current_target = global_position + Vector2(
		randf_range(-500, 500),
		randf_range(-500, 500)
	)

func _physics_process(delta: float) -> void:
	# Calculate direction to target
	var to_target = current_target - global_position
	var distance = to_target.length()

	# Check if arrived at target
	if distance < arrival_distance:
		_next_destination()
		return

	# Slow down near target
	var desired_speed = cruise_speed
	if distance < 200.0:
		desired_speed = cruise_speed * (distance / 200.0)
		desired_speed = max(desired_speed, cruise_speed * 0.3)

	# Calculate desired velocity
	var desired_velocity = to_target.normalized() * desired_speed

	# Apply separation force from nearby ships
	var separation_vector = _calculate_separation()
	desired_velocity += separation_vector

	# Smoothly adjust current velocity
	ship_velocity = ship_velocity.lerp(desired_velocity, acceleration * delta / cruise_speed)

	# Rotate to face movement direction
	if ship_velocity.length() > 5.0:
		var target_rotation = ship_velocity.angle() + PI / 2
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

	# Apply movement
	velocity = ship_velocity
	move_and_slide()

	# Handle collisions with other ships
	_handle_collisions()

	# Update thruster effects
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

func get_ship_velocity() -> Vector2:
	return ship_velocity

func _calculate_separation() -> Vector2:
	var separation = Vector2.ZERO
	var count = 0

	for other_ship in nearby_ships:
		if !is_instance_valid(other_ship):
			continue

		var distance = global_position.distance_to(other_ship.global_position)

		if distance < separation_distance and distance > 0:
			# Calculate repulsion force (stronger when closer)
			var away_vector = (global_position - other_ship.global_position).normalized()
			var strength = (separation_distance - distance) / separation_distance
			separation += away_vector * strength * separation_force
			count += 1

	if count > 0:
		separation /= count

	return separation

func _next_destination() -> void:
	if hubs.size() > 0:
		# Go to next hub
		current_hub_index = (current_hub_index + 1) % hubs.size()
		current_target = hubs[current_hub_index].global_position
	else:
		_pick_random_target()

func _update_thrusters() -> void:
	var speed_ratio = ship_velocity.length() / cruise_speed
	var base_alpha = speed_ratio * 0.6
	var flicker = 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.15

	if thruster_left:
		thruster_left.modulate.a = base_alpha * flicker
	if thruster_right:
		thruster_right.modulate.a = base_alpha * flicker
