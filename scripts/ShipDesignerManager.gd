# res://scripts/ShipDesignerManager.gd
# Manages the ship designer popup overlay
class_name ShipDesignerManager extends CanvasLayer

var ship_designer_scene: PackedScene = preload("res://scenes/ShipDesigner.tscn")
var ship_designer_instance: Control = null
var is_open: bool = false

# Reference to Starship
var starship: Node = null

func _ready() -> void:
	# Set layer to be on top of game
	layer = 100

	# Find starship
	call_deferred("_find_starship")

func _find_starship() -> void:
	var root = get_tree().root
	starship = _find_node_by_name(root, "Starship")
	if starship == null:
		push_warning("ShipDesignerManager: Starship not found")

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result != null:
			return result
	return null

func toggle_designer() -> void:
	if is_open:
		close_designer()
	else:
		open_designer()

func open_designer() -> void:
	if ship_designer_instance:
		return  # Already open

	# Pause the game
	get_tree().paused = true

	# Create designer instance
	ship_designer_instance = ship_designer_scene.instantiate()

	# Reset anchors to not fill screen
	ship_designer_instance.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ship_designer_instance.grow_horizontal = Control.GROW_DIRECTION_END
	ship_designer_instance.grow_vertical = Control.GROW_DIRECTION_END

	# Make it 1/4 of screen size
	var viewport_size = get_viewport().get_visible_rect().size
	var designer_size = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5)  # Half width, half height = 1/4 area

	# Position in bottom-right corner
	ship_designer_instance.position = Vector2(viewport_size.x - designer_size.x, viewport_size.y - designer_size.y)
	ship_designer_instance.custom_minimum_size = designer_size
	ship_designer_instance.size = designer_size

	# Make background semi-transparent
	var bg = ship_designer_instance.get_node("Background")
	if bg:
		bg.color = Color(0.15, 0.15, 0.17, 0.85)  # Semi-transparent

	add_child(ship_designer_instance)

	is_open = true
	print("ShipDesignerManager: Designer opened at ", ship_designer_instance.position, " with size ", designer_size)

func close_designer() -> void:
	if !ship_designer_instance:
		return

	# Unpause the game
	get_tree().paused = false

	ship_designer_instance.queue_free()
	ship_designer_instance = null
	is_open = false
	print("ShipDesignerManager: Designer closed")

func apply_design_to_starship() -> void:
	if !ship_designer_instance or !starship:
		return

	# Get the current ship definition from designer
	var grid_editor = ship_designer_instance.get_node("MainLayout/ContentArea/RightSplit/CenterContainer/GridEditorControl/GridEditor")
	if !grid_editor:
		print("ShipDesignerManager: Could not find GridEditor")
		return

	var ship_def: ShipDefinition = grid_editor.ship_definition
	if !ship_def:
		print("ShipDesignerManager: No ship definition found")
		return

	# Apply the ship design to Starship
	if starship.has_method("apply_ship_design"):
		starship.apply_ship_design(ship_def)
		print("ShipDesignerManager: Applied ship design to Starship")
	else:
		push_warning("ShipDesignerManager: Starship doesn't have apply_ship_design() method")
