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

	# CRITICAL: Set process mode to always so it works when game is paused
	ship_designer_instance.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(ship_designer_instance)

	# CRITICAL: Reset ALL anchors to prevent auto-scaling
	ship_designer_instance.anchor_left = 0.0
	ship_designer_instance.anchor_top = 0.0
	ship_designer_instance.anchor_right = 0.0
	ship_designer_instance.anchor_bottom = 0.0
	ship_designer_instance.offset_left = 0.0
	ship_designer_instance.offset_top = 0.0
	ship_designer_instance.offset_right = 0.0
	ship_designer_instance.offset_bottom = 0.0
	ship_designer_instance.grow_horizontal = Control.GROW_DIRECTION_END
	ship_designer_instance.grow_vertical = Control.GROW_DIRECTION_END

	# Make it 1/4 of screen width, full height
	var viewport_size = get_viewport().get_visible_rect().size
	var designer_size = Vector2(viewport_size.x * 0.25, viewport_size.y)  # 1/4 width, full height

	# Position on LEFT side of screen
	ship_designer_instance.position = Vector2(0, 0)
	ship_designer_instance.size = designer_size

	# Make background semi-transparent and fix anchors
	var bg = ship_designer_instance.get_node("Background")
	if bg:
		bg.color = Color(0.15, 0.15, 0.17, 0.85)  # Semi-transparent
		# Reset background to fill designer
		bg.anchor_left = 0.0
		bg.anchor_top = 0.0
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		bg.offset_left = 0.0
		bg.offset_top = 0.0
		bg.offset_right = 0.0
		bg.offset_bottom = 0.0

	# Fix MainLayout to fill designer
	var main_layout = ship_designer_instance.get_node("MainLayout")
	if main_layout:
		main_layout.anchor_left = 0.0
		main_layout.anchor_top = 0.0
		main_layout.anchor_right = 1.0
		main_layout.anchor_bottom = 1.0
		main_layout.offset_left = 0.0
		main_layout.offset_top = 0.0
		main_layout.offset_right = 0.0
		main_layout.offset_bottom = 0.0

	is_open = true
	print("ShipDesignerManager: Designer opened at ", ship_designer_instance.position, " with size ", designer_size)
	print("  Viewport size: ", viewport_size)
	print("  Actual size after: ", ship_designer_instance.size)

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
