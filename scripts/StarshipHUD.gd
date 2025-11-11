# res://scripts/StarshipHUD.gd
extends CanvasLayer

@onready var speed_label: Label = $MarginContainer/VBoxContainer/SpeedLabel

var starship: CharacterBody2D = null
var designer_manager: Node = null
var designer_button: Button = null

func _ready() -> void:
	# Create ship designer toggle button
	create_designer_button()

	# Find the starship in the scene
	call_deferred("_find_starship")
	call_deferred("_find_designer_manager")

func create_designer_button() -> void:
	designer_button = Button.new()
	designer_button.text = "Ship Designer"
	designer_button.custom_minimum_size = Vector2(120, 30)
	designer_button.add_theme_font_size_override("font_size", 11)

	# Position in top-right corner
	designer_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	designer_button.offset_left = -130
	designer_button.offset_top = 10
	designer_button.offset_right = -10
	designer_button.offset_bottom = 40

	designer_button.pressed.connect(_on_designer_button_pressed)
	add_child(designer_button)

func _find_designer_manager() -> void:
	var root = get_tree().root
	designer_manager = _find_node_by_type(root, "ShipDesignerManager")
	if designer_manager == null:
		push_warning("ShipDesignerManager not found in scene")

func _find_starship() -> void:
	var root = get_tree().root
	starship = _find_node_by_type(root, "Starship")
	if starship == null:
		push_warning("Starship not found in scene")

func _on_designer_button_pressed() -> void:
	if designer_manager and designer_manager.has_method("toggle_designer"):
		designer_manager.toggle_designer()
	else:
		print("Designer manager not available")

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
