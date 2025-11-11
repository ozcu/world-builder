# res://scripts/ship_designer/GridEditor.gd
# Interactive grid editor for placing tiles and parts
class_name GridEditor extends Node2D

signal ship_modified()

@export var ship_definition: ShipDefinition
@export var cell_size: int = 32
@export var grid_size: Vector2i = Vector2i(64, 64)
@export var show_grid: bool = true
@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)

# Editor state
var current_tool: String = "tile"  # "tile", "part", "erase"
var current_tile: ShipTile = null
var current_part: ShipPart = null
var current_orientation: bool = true  # true = horizontal

# Visual elements
var renderer: ShipRenderer
var hover_preview: Sprite2D
var hover_position: Vector2i = Vector2i(-1, -1)
var background_sprite: Sprite2D

func _ready() -> void:
	if !ship_definition:
		ship_definition = ShipDefinition.new()

	# Load and create tiled background
	create_background()

	# Create renderer
	renderer = ShipRenderer.new()
	renderer.ship_definition = ship_definition
	renderer.auto_center = false
	add_child(renderer)

	# Create hover preview
	hover_preview = Sprite2D.new()
	hover_preview.centered = false
	hover_preview.modulate = Color(1, 1, 1, 0.6)
	hover_preview.visible = false
	add_child(hover_preview)

	print("GridEditor: Ready complete, background and renderer added")

func create_background() -> void:
	# Load star background texture
	var star_texture = load("res://assets/textures/star-background.jpg")
	if star_texture:
		print("GridEditor: Star background loaded successfully")
		background_sprite = Sprite2D.new()
		background_sprite.texture = star_texture
		background_sprite.centered = false
		background_sprite.z_index = -100  # Behind everything

		# Tile the background to cover the grid area
		var grid_pixel_size = Vector2(grid_size.x * cell_size, grid_size.y * cell_size)
		var texture_size = star_texture.get_size()

		# Scale to fit - make it repeat by using region
		var scale_x = grid_pixel_size.x / texture_size.x
		var scale_y = grid_pixel_size.y / texture_size.y

		print("GridEditor: Grid size = ", grid_pixel_size, ", Texture size = ", texture_size)

		# Use region to tile the texture
		background_sprite.region_enabled = true
		background_sprite.region_rect = Rect2(0, 0, texture_size.x * ceil(scale_x), texture_size.y * ceil(scale_y))
		background_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

		add_child(background_sprite)
		move_child(background_sprite, 0)  # Ensure it's the first child (bottom layer)
		print("GridEditor: Background sprite added as child")
	else:
		print("ERROR: Could not load star-background.jpg from res://assets/textures/")

func _draw() -> void:
	if show_grid:
		draw_grid()

func draw_grid() -> void:
	# Draw grid lines
	for x in range(grid_size.x + 1):
		var x_pos = x * cell_size
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, grid_size.y * cell_size), grid_color)

	for y in range(grid_size.y + 1):
		var y_pos = y * cell_size
		draw_line(Vector2(0, y_pos), Vector2(grid_size.x * cell_size, y_pos), grid_color)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update_hover(event.position)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			handle_click(event.position)

func update_hover(mouse_pos: Vector2) -> void:
	# Convert mouse position to grid coordinates
	var local_pos = to_local(mouse_pos)
	var grid_pos = Vector2i(
		int(local_pos.x / cell_size),
		int(local_pos.y / cell_size)
	)

	# Check bounds
	if grid_pos.x < 0 or grid_pos.x >= grid_size.x or grid_pos.y < 0 or grid_pos.y >= grid_size.y:
		hover_preview.visible = false
		hover_position = Vector2i(-1, -1)
		return

	# Update preview
	if grid_pos != hover_position:
		hover_position = grid_pos
		update_preview()

func update_preview() -> void:
	if hover_position.x < 0 or hover_position.y < 0:
		hover_preview.visible = false
		return

	hover_preview.position = Vector2(hover_position.x * cell_size, hover_position.y * cell_size)

	if current_tool == "tile" and current_tile:
		# For corridors, show auto-tiled preview
		if current_tile.tile_type == PartCategory.TileType.CORRIDOR:
			# Create a temporary ship definition to calculate what the corridor would look like
			var preview_sprite = get_corridor_preview_sprite(hover_position)
			hover_preview.texture = preview_sprite
		else:
			hover_preview.texture = current_tile.sprite

		hover_preview.visible = true
		hover_preview.rotation = 0
		hover_preview.modulate = Color(1, 1, 1, 0.6)

	elif current_tool == "part" and current_part:
		hover_preview.texture = current_part.sprite
		hover_preview.visible = can_place_current_part()

		# Set color based on valid placement
		if can_place_current_part():
			hover_preview.modulate = Color(0, 1, 0, 0.6)  # Green = valid
		else:
			hover_preview.modulate = Color(1, 0, 0, 0.6)  # Red = invalid

		# Handle rotation
		if !current_orientation:
			hover_preview.rotation = deg_to_rad(90)
			var size = current_part.size
			hover_preview.position += Vector2(0, size.x * cell_size)
		else:
			hover_preview.rotation = 0

	elif current_tool == "erase":
		hover_preview.visible = false

	else:
		hover_preview.visible = false

func get_corridor_preview_sprite(pos: Vector2i) -> Texture2D:
	# Simulate what the corridor would look like if placed here
	# Check what's currently at this position and neighboring cells
	var connections = AutoTiler.get_connections(ship_definition, pos)
	return AutoTiler.get_sprite_from_connections(connections)

func can_place_current_part() -> bool:
	if !current_part:
		return false

	var placement = PartPlacement.new()
	placement.part = current_part
	placement.grid_position = hover_position
	placement.horizontal = current_orientation

	return ship_definition.can_place_part(placement)

func handle_click(mouse_pos: Vector2) -> void:
	if hover_position.x < 0 or hover_position.y < 0:
		return

	if current_tool == "tile" and current_tile:
		place_tile(hover_position, current_tile)

	elif current_tool == "part" and current_part:
		place_part(hover_position, current_part)

	elif current_tool == "erase":
		erase_at(hover_position)

func place_tile(pos: Vector2i, tile: ShipTile) -> void:
	ship_definition.set_tile(pos, tile)
	print("GridEditor: Placed ", tile.tile_name, " at ", pos)

	# Auto-tile corridors
	if tile.tile_type == PartCategory.TileType.CORRIDOR:
		print("GridEditor: Auto-tiling corridor at ", pos)
		var updated_positions = AutoTiler.update_corridor_and_neighbors(ship_definition, pos)
		print("GridEditor: Updated ", updated_positions.size(), " corridor tiles")

	refresh()
	ship_modified.emit()

func place_part(pos: Vector2i, part: ShipPart) -> void:
	var placement = PartPlacement.new()
	placement.part = part
	placement.grid_position = pos
	placement.horizontal = current_orientation

	if ship_definition.add_part(placement):
		refresh()
		ship_modified.emit()
	else:
		print("Cannot place part - door connection requirements not met")

func erase_at(pos: Vector2i) -> void:
	# Check if tile exists at position
	if ship_definition.has_tile(pos):
		var tile = ship_definition.get_tile(pos)
		var was_corridor = (tile != null and tile.tile_type == PartCategory.TileType.CORRIDOR)

		ship_definition.remove_tile(pos)

		# Update neighboring corridors if we removed a corridor
		if was_corridor:
			var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
			for dir in directions:
				var neighbor_pos = pos + dir
				var neighbor_tile = ship_definition.get_tile(neighbor_pos)
				if neighbor_tile and neighbor_tile.tile_type == PartCategory.TileType.CORRIDOR:
					AutoTiler.update_corridor_and_neighbors(ship_definition, neighbor_pos)

		refresh()
		ship_modified.emit()
		return

	# Check if part occupies this position
	for placement in ship_definition.parts:
		if pos in placement.get_occupied_cells():
			ship_definition.remove_part(placement)
			refresh()
			ship_modified.emit()
			return

func set_tool(tool: String, item = null) -> void:
	current_tool = tool
	if tool == "tile":
		current_tile = item
		current_part = null
	elif tool == "part":
		current_part = item
		current_tile = null
	else:  # erase
		current_tile = null
		current_part = null

	update_preview()

func set_orientation(horizontal: bool) -> void:
	current_orientation = horizontal
	update_preview()

func refresh() -> void:
	if renderer:
		renderer.set_ship(ship_definition)
	update_preview()
	queue_redraw()
