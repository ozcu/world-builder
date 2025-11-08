# res://scripts/SpaceStation.gd
extends StaticBody2D

@export var rotation_speed: float = 0.1  # Radians per second
@export var mass: float = 25000.0  # Station mass for collision physics (very heavy)

func _process(delta: float) -> void:
	rotation += rotation_speed * delta
