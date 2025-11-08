# res://scripts/SpaceStation.gd
extends StaticBody2D

@export var rotation_speed: float = 0.1  # Radians per second

func _process(delta: float) -> void:
	rotation += rotation_speed * delta
