# res://scripts/ship_designer/TilePalette.gd
# UI palette for selecting tile types
class_name TilePalette extends VBoxContainer

signal tile_selected(tile: ShipTile)

var tiles: Dictionary = {}
var tile_buttons: Array = []
var selected_button: Control = null

func _ready() -> void:
	# Add bright debug background to confirm palette is visible
	var debug_bg = ColorRect.new()
	debug_bg.color = Color(0.1, 0.3, 0.1, 1.0)  # Dark green background
	debug_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	debug_bg.z_index = -1
	add_child(debug_bg)
	move_child(debug_bg, 0)  # Behind everything

	# Add label
	var label = Label.new()
	label.text = "TILES"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)

	# Add separator
	var separator = HSeparator.new()
	add_child(separator)

func set_tiles(tile_dict: Dictionary) -> void:
	tiles = tile_dict

	print("=== TilePalette.set_tiles() called ===")
	print("TilePalette container - Size: ", size, ", Visible: ", visible, ", In tree: ", is_inside_tree())

	# Clear existing buttons
	for button in tile_buttons:
		button.queue_free()
	tile_buttons.clear()

	# Create buttons for each tile type
	# Group by type
	var corridor_tiles = []
	var door_tiles = []
	var airlock_tiles = []

	for tile_id in tiles.keys():
		var tile = tiles[tile_id]
		match tile.tile_type:
			PartCategory.TileType.CORRIDOR:
				corridor_tiles.append({
					"id": tile_id,
					"tile": tile
				})
			PartCategory.TileType.DOOR:
				door_tiles.append({
					"id": tile_id,
					"tile": tile
				})
			PartCategory.TileType.AIRLOCK:
				airlock_tiles.append({
					"id": tile_id,
					"tile": tile
				})

	# Add category labels and buttons
	if corridor_tiles.size() > 0:
		add_category_label("Corridors")
		for item in corridor_tiles:
			add_tile_button(item.id, item.tile)

	if door_tiles.size() > 0:
		add_category_label("Doors")
		for item in door_tiles:
			add_tile_button(item.id, item.tile)

	if airlock_tiles.size() > 0:
		add_category_label("Airlocks")
		for item in airlock_tiles:
			add_tile_button(item.id, item.tile)

func add_category_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 9)  # Smaller: 12 -> 9
	label.modulate = Color(0.7, 0.7, 0.7)
	add_child(label)

func add_tile_button(_tile_id: String, tile: ShipTile) -> void:
	# Create a panel container for the entire button
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 50)  # Smaller: 180x70 -> 160x50
	panel.size_flags_horizontal = Control.SIZE_FILL

	# Add visible background style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.5, 1.0)
	panel.add_theme_stylebox_override("panel", style)

	# Create margin for padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	# Create horizontal container for icon + text
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	# Create and add icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)  # Smaller: 56 -> 40
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if tile.sprite:
		if tile.tile_type == PartCategory.TileType.CORRIDOR:
			# Show cross corridor to indicate auto-tiling
			icon.texture = MockupGenerator.create_corridor_mockup([
				Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)
			])
		else:
			icon.texture = tile.sprite
	hbox.add_child(icon)

	# Create and add label
	var text_label = Label.new()
	text_label.text = tile.tile_name
	text_label.add_theme_font_size_override("font_size", 10)  # Smaller font
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_label)

	# Make panel clickable
	panel.gui_input.connect(_on_panel_input.bind(tile, panel))
	panel.mouse_entered.connect(_on_panel_hover.bind(panel, true))
	panel.mouse_exited.connect(_on_panel_hover.bind(panel, false))

	add_child(panel)
	tile_buttons.append(panel)

	print("TilePalette: Added tile panel for ", tile.tile_name)
	print("  Panel - Size: ", panel.size, ", MinSize: ", panel.custom_minimum_size, ", Visible: ", panel.visible)
	print("  Icon - Size: ", icon.size, ", MinSize: ", icon.custom_minimum_size, ", Texture: ", icon.texture != null)
	print("  Style - BgColor: ", style.bg_color, ", BorderWidth: 2px")

func _on_panel_input(event: InputEvent, tile: ShipTile, panel: Control) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_tile_button_pressed(tile, panel)
			# Consume the event to prevent it from reaching the GridEditor
			get_viewport().set_input_as_handled()
			panel.accept_event()

func _on_panel_hover(panel: Control, entered: bool) -> void:
	if selected_button == panel:
		return

	if entered:
		panel.modulate = Color(1.2, 1.2, 1.2)
	else:
		panel.modulate = Color(1, 1, 1)

func _on_tile_button_pressed(tile: ShipTile, panel: Control) -> void:
	# Unhighlight previous
	if selected_button:
		selected_button.modulate = Color(1, 1, 1)

	# Highlight selected
	selected_button = panel
	panel.modulate = Color(0.7, 1, 0.7)

	tile_selected.emit(tile)
	print("TilePalette: Selected ", tile.tile_name)
