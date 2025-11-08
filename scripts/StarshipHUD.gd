# res://scripts/StarshipHUD.gd
extends CanvasLayer

@onready var speed_label: Label = $MarginContainer/VBoxContainer/SpeedLabel

var starship: RigidBody2D = null

func _ready() -> void:
	# Find the starship in the scene
	call_deferred("_find_starship")

func _find_starship() -> void:
	var root = get_tree().root
	starship = _find_node_by_type(root, "Starship")
	if starship == null:
		push_warning("Starship not found in scene")

func _find_node_by_type(node: Node, type_name: String) -> Node:
	if node.name == type_name:
		return node
	for child in node.get_children():
		var result = _find_node_by_type(child, type_name)
		if result != null:
			return result
	return null

func _process(_delta: float) -> void:
	if starship == null or !is_instance_valid(starship):
		return

	if starship.has_method("get_speed"):
		var speed: float = starship.get_speed()
		speed_label.text = "Speed: %.1f m/s" % speed
