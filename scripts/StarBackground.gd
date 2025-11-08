# res://scripts/StarBackground.gd
extends Sprite2D

@onready var camera: Camera2D = get_node("../Camera2D")

func _process(_delta: float) -> void:
	if camera:
		# Make background follow camera position
		global_position = camera.global_position
