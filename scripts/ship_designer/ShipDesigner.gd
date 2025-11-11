# res://scripts/ship_designer/ShipDesigner.gd
# Main ship designer UI controller
extends Control

# UI References
@onready var grid_editor: Node2D = $MainLayout/ContentArea/RightSplit/CenterContainer/GridEditorControl/GridEditor
@onready var tile_palette: Control = $MainLayout/ContentArea/LeftPanel/TilePalette
@onready var part_palette: Control = $MainLayout/ContentArea/RightSplit/RightPanel/PartPalette
@onready var stats_panel: Control = $MainLayout/BottomPanel/StatsPanel
@onready var toolbar: Control = $MainLayout/TopPanel/Toolbar
@onready var save_button: Button = $MainLayout/TopPanel/Toolbar/SaveButton
@onready var load_button: Button = $MainLayout/TopPanel/Toolbar/LoadButton
@onready var clear_button: Button = $MainLayout/TopPanel/Toolbar/ClearButton
@onready var orientation_button: Button = $MainLayout/TopPanel/Toolbar/OrientationButton
@onready var erase_button: Button = $MainLayout/TopPanel/Toolbar/EraseButton
@onready var apply_button: Button = $MainLayout/TopPanel/Toolbar/ApplyButton
@onready var close_button: Button = $MainLayout/TopPanel/Toolbar/CloseButton

# Current ship being edited
var current_ship: ShipDefinition

# Tile and part libraries for loading
var tiles_library: Dictionary = {}
var parts_library: Dictionary = {}

# Editor state
var selected_tool: String = "tile"  # "tile", "part", "erase"
var selected_tile: ShipTile = null
var selected_part: ShipPart = null
var part_orientation_horizontal: bool = true

func _ready() -> void:
	# Initialize new ship
	current_ship = ShipDefinition.new()
	current_ship.ship_name = "New Ship"

	# Setup UI
	setup_ui()

	# Connect signals
	connect_signals()

func setup_ui() -> void:
	# Initialize palettes with test data
	tiles_library = TestDataGenerator.create_test_tiles()
	parts_library = TestDataGenerator.create_test_parts()

	print("=== Ship Designer Initialized ===")
	print("Tiles loaded: ", tiles_library.keys())
	print("Parts loaded: ", parts_library.keys())

	# Debug UI hierarchy
	print("\n=== UI Hierarchy Debug ===")
	var grid_editor_control = $MainLayout/ContentArea/RightSplit/CenterContainer/GridEditorControl
	if grid_editor_control:
		print("GridEditorControl - Size: ", grid_editor_control.size, ", MinSize: ", grid_editor_control.custom_minimum_size, ", Visible: ", grid_editor_control.visible)
	var left_panel = $MainLayout/ContentArea/LeftPanel
	if left_panel:
		print("LeftPanel - Size: ", left_panel.size, ", MinSize: ", left_panel.custom_minimum_size, ", Visible: ", left_panel.visible)
	var right_panel = $MainLayout/ContentArea/RightSplit/RightPanel
	if right_panel:
		print("RightPanel - Size: ", right_panel.size, ", MinSize: ", right_panel.custom_minimum_size, ", Visible: ", right_panel.visible)
	print("=========================\n")

	if tile_palette:
		tile_palette.set_tiles(tiles_library)
		print("Tile palette set with ", tiles_library.size(), " tiles")
	else:
		print("WARNING: tile_palette is null!")

	if part_palette:
		part_palette.set_parts(parts_library)
		print("Part palette set with ", parts_library.size(), " parts")
	else:
		print("WARNING: part_palette is null!")

	if grid_editor:
		grid_editor.ship_definition = current_ship
		print("Grid editor initialized")
	else:
		print("WARNING: grid_editor is null!")

	update_stats()

func connect_signals() -> void:
	if tile_palette:
		tile_palette.tile_selected.connect(_on_tile_selected)

	if part_palette:
		part_palette.part_selected.connect(_on_part_selected)

	if grid_editor:
		grid_editor.ship_modified.connect(_on_ship_modified)

	# Toolbar buttons
	if save_button:
		save_button.pressed.connect(_on_save_pressed)

	if load_button:
		load_button.pressed.connect(_on_load_pressed)

	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)

	if orientation_button:
		orientation_button.toggled.connect(_on_orientation_toggled)

	if erase_button:
		erase_button.toggled.connect(_on_erase_toggled)

	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _on_tile_selected(tile: ShipTile) -> void:
	selected_tool = "tile"
	selected_tile = tile
	selected_part = null
	if grid_editor:
		grid_editor.set_tool("tile", tile)

func _on_part_selected(part: ShipPart) -> void:
	selected_tool = "part"
	selected_tile = null
	selected_part = part
	if grid_editor:
		grid_editor.set_tool("part", part)

func _on_ship_modified() -> void:
	update_stats()

func update_stats() -> void:
	if !stats_panel:
		return

	current_ship._recalculate_metadata()
	var validation = current_ship.validate()

	stats_panel.update_stats(current_ship.metadata, validation)

func toggle_orientation() -> void:
	part_orientation_horizontal = !part_orientation_horizontal
	if grid_editor:
		grid_editor.set_orientation(part_orientation_horizontal)

func save_ship(filepath: String) -> void:
	var json = current_ship.to_json()
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json, "  "))
		file.close()
		print("Ship saved to: ", filepath)

func load_ship(filepath: String) -> bool:
	if !FileAccess.file_exists(filepath):
		print("ERROR: File does not exist: ", filepath)
		return false

	var file = FileAccess.open(filepath, FileAccess.READ)
	if !file:
		print("ERROR: Could not open file: ", filepath)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.parse_string(json_string)
	if json == null:
		print("ERROR: Invalid JSON in file: ", filepath)
		return false

	# Load ship from JSON using libraries
	current_ship = ShipDefinition.from_json(json, tiles_library, parts_library)

	# Update grid editor
	if grid_editor:
		grid_editor.ship_definition = current_ship
		grid_editor.refresh()

	print("Ship loaded from: ", filepath)
	print("  Ship name: ", current_ship.ship_name)
	print("  Tiles: ", current_ship.tile_positions.size())
	print("  Parts: ", current_ship.parts.size())

	return true

func clear_ship() -> void:
	current_ship = ShipDefinition.new()
	current_ship.ship_name = "New Ship"
	if grid_editor:
		grid_editor.ship_definition = current_ship
		grid_editor.refresh()
	update_stats()

# Toolbar button handlers
func _on_save_pressed() -> void:
	# For now, save to a default location
	save_ship("user://test_ship.ship")

func _on_load_pressed() -> void:
	# For now, load from default location
	if load_ship("user://test_ship.ship"):
		update_stats()

func _on_clear_pressed() -> void:
	clear_ship()

func _on_orientation_toggled(pressed: bool) -> void:
	part_orientation_horizontal = !pressed
	if grid_editor:
		grid_editor.set_orientation(part_orientation_horizontal)

	# Update button text
	if orientation_button:
		if pressed:
			orientation_button.text = "Orientation: Vertical"
		else:
			orientation_button.text = "Orientation: Horizontal"

func _on_erase_toggled(pressed: bool) -> void:
	if pressed:
		selected_tool = "erase"
		if grid_editor:
			grid_editor.set_tool("erase", null)
	else:
		# Return to previous tool
		if selected_tile:
			_on_tile_selected(selected_tile)
		elif selected_part:
			_on_part_selected(selected_part)

func _on_apply_pressed() -> void:
	"""Apply the current ship design to the player's Starship"""
	# Find the ShipDesignerManager and tell it to apply
	var manager = _find_designer_manager()
	if manager and manager.has_method("apply_design_to_starship"):
		manager.apply_design_to_starship()
		print("ShipDesigner: Applied design to Starship")
	else:
		print("ShipDesigner: Could not find ShipDesignerManager")

func _on_close_pressed() -> void:
	"""Close the ship designer panel"""
	var manager = _find_designer_manager()
	if manager and manager.has_method("close_designer"):
		manager.close_designer()
	else:
		print("ShipDesigner: Could not find ShipDesignerManager")

func _find_designer_manager() -> Node:
	var root = get_tree().root
	return _find_node_by_name(root, "ShipDesignerManager")

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result != null:
			return result
	return null
