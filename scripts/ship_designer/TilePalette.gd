# res://scripts/ship_designer/TilePalette.gd
# UI palette for selecting tile types
class_name TilePalette extends VBoxContainer

signal tile_selected(tile: ShipTile)

var tiles: Dictionary = {}
var tile_buttons: Array = []
var selected_button: Button = null

func _ready() -> void:
	# Ensure palette expands to fill available space
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Add label
	var label = Label.new()
	label.text = "TILES"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	# Add separator
	var separator = HSeparator.new()
	add_child(separator)

func set_tiles(tile_dict: Dictionary) -> void:
	tiles = tile_dict

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
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = Color(0.7, 0.7, 0.7)
	add_child(label)

func add_tile_button(tile_id: String, tile: ShipTile) -> void:
	# Create HBoxContainer for icon + text layout
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(150, 60)

	# Create icon display
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Set icon - for corridor, use a cross sprite to show it auto-tiles
	if tile.sprite:
		if tile.tile_type == PartCategory.TileType.CORRIDOR:
			# Show cross corridor as icon to indicate auto-tiling
			icon_rect.texture = MockupGenerator.create_corridor_mockup([
				Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)
			])
		else:
			icon_rect.texture = tile.sprite

	# Create button
	var button = Button.new()
	button.text = tile.tile_name
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Add icon and button to container
	container.add_child(icon_rect)
	container.add_child(button)

	button.pressed.connect(_on_tile_button_pressed.bind(tile, button))
	add_child(container)
	tile_buttons.append(button)

	print("TilePalette: Added tile button for ", tile.tile_name)

func _on_tile_button_pressed(tile: ShipTile, button: Button) -> void:
	# Highlight selected button
	if selected_button:
		selected_button.modulate = Color(1, 1, 1)

	selected_button = button
	button.modulate = Color(0.7, 1, 0.7)

	tile_selected.emit(tile)
