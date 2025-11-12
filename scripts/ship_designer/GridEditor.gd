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
var current_rotation: int = 0  # Rotation in degrees: 0, 90, 180, 270
var is_painting: bool = false  # Track if mouse button is held down
var last_painted_cell: Vector2i = Vector2i(-1, -1)  # Prevent painting same cell multiple times

# Zoom state
var zoom_level: float = 1.0
var min_zoom: float = 0.5
var max_zoom: float = 3.0
var zoom_step: float = 0.1

# Pan state
var is_panning: bool = false
var pan_start_pos: Vector2 = Vector2.ZERO
var camera_offset: Vector2 = Vector2.ZERO

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
	print("GridEditor children count: ", get_child_count())
	print("GridEditor - Position: ", position, ", Global position: ", global_position)
	if background_sprite:
		print("Background sprite - Position: ", background_sprite.position, ", Visible: ", background_sprite.visible, ", Z-index: ", background_sprite.z_index)
		print("  Texture: ", background_sprite.texture != null, ", Region: ", background_sprite.region_rect)
	if renderer:
		print("Renderer - Children: ", renderer.get_child_count(), ", Visible: ", renderer.visible)

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
	# Handle keyboard input globally
	if event is InputEventKey:
		if event.keycode == KEY_SPACE:
			if event.pressed and not is_panning:
				# Start pan mode
				is_panning = true
				Input.set_default_cursor_shape(Input.CURSOR_MOVE)
			elif not event.pressed and is_panning:
				# End pan mode
				is_panning = false
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		elif event.keycode == KEY_R and event.pressed:
			# Rotate part by 90 degrees clockwise
			current_rotation = (current_rotation + 90) % 360
			update_preview()
			print("GridEditor: Rotation set to ", current_rotation, "°")

func handle_input(event: InputEvent) -> void:
	# Handle mouse input forwarded from GridEditorControl's gui_input
	# This is only called for mouse events on the grid area, not on palettes
	if event is InputEventMouseMotion:
		if is_panning:
			# Pan the view
			var delta = event.relative
			position += delta
			camera_offset += delta
		else:
			update_hover(event.position)
			# Continuous painting while mouse button is held - ONLY for corridors
			if is_painting and current_tool == "tile" and current_tile and current_tile.tile_type == PartCategory.TileType.CORRIDOR:
				paint_at_hover()
			# Continuous painting for external parts (armor) while dragging
			elif is_painting and current_tool == "part" and current_part and current_part.is_external:
				paint_part_at_hover()
			# Continuous erasing while mouse button is held
			elif is_painting and current_tool == "erase":
				erase_at_hover()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_panning:  # Only paint when not panning
				if event.pressed:
					is_painting = true
					last_painted_cell = Vector2i(-1, -1)
					handle_click(event.position)
				else:
					is_painting = false
					last_painted_cell = Vector2i(-1, -1)
		# Handle scroll wheel zoom (without needing middle mouse button)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()

func update_hover(mouse_pos: Vector2) -> void:
	# Convert mouse position to grid coordinates
	# Mouse pos is in GridEditorControl's local space
	# Account for GridEditor's position (pan offset) and scale (zoom level)
	var local_pos = (mouse_pos - position) / scale.x
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

	# Base grid position (will be adjusted for parts with rotation offset)
	var base_position = Vector2(hover_position.x * cell_size, hover_position.y * cell_size)
	hover_preview.position = base_position

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
		hover_preview.visible = true  # Always show preview

		# Apply rotation FIRST
		hover_preview.rotation = deg_to_rad(current_rotation)

		# Calculate grid position to center the part at the cursor
		var adjusted_grid_pos = get_centered_grid_position(hover_position, current_part, current_rotation)
		var adjusted_base_pos = Vector2(adjusted_grid_pos.x * cell_size, adjusted_grid_pos.y * cell_size)

		# Calculate rotation offset for sprite rendering
		var size = current_part.size
		var rotation_offset = Vector2.ZERO
		match current_rotation:
			90:
				rotation_offset = Vector2(0, size.x * cell_size)
			180:
				rotation_offset = Vector2(size.x * cell_size, size.y * cell_size)
			270:
				rotation_offset = Vector2(size.y * cell_size, 0)

		# Set position with both adjustments
		hover_preview.position = adjusted_base_pos + rotation_offset

		if current_rotation != 0:
			print("  Preview debug: cursor_grid=", hover_position, " adjusted_grid=", adjusted_grid_pos,
			      " rot=", current_rotation, "°")

		# Set color based on valid placement (after position is set)
		if can_place_current_part():
			hover_preview.modulate = Color(0, 1, 0, 0.6)  # Green = valid
		else:
			hover_preview.modulate = Color(1, 0, 0, 0.5)  # Red transparent = invalid

	elif current_tool == "erase":
		hover_preview.visible = false

	else:
		hover_preview.visible = false

func get_centered_grid_position(cursor_pos: Vector2i, part: ShipPart, rotation: int) -> Vector2i:
	"""Calculate grid position to center a rotated part at the cursor position"""
	# Work in world (pixel) coordinates with floats to avoid precision loss
	var cursor_world = Vector2(cursor_pos.x * cell_size, cursor_pos.y * cell_size)

	var size = part.size
	var rotated_size = size

	# Get rotated dimensions
	if rotation == 90 or rotation == 270:
		rotated_size = Vector2i(size.y, size.x)  # Swap width and height

	# Calculate rotated size in pixels
	var rotated_size_pixels = Vector2(rotated_size.x * cell_size, rotated_size.y * cell_size)

	# Calculate top-left corner position to center the part at cursor
	# Subtract half the rotated size (in pixels) from cursor position
	var top_left_world = cursor_world - rotated_size_pixels / 2.0

	# Convert back to grid coordinates (floor to get integer grid position)
	return Vector2i(floor(top_left_world.x / cell_size), floor(top_left_world.y / cell_size))

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
	# Use centered grid position for rotated parts
	placement.grid_position = get_centered_grid_position(hover_position, current_part, current_rotation)
	placement.rotation = current_rotation

	return ship_definition.can_place_part(placement)

func paint_at_hover() -> void:
	"""Continuously paint tiles while dragging mouse"""
	if hover_position.x < 0 or hover_position.y < 0:
		return

	# Only paint if we've moved to a new cell
	if hover_position == last_painted_cell:
		return

	last_painted_cell = hover_position
	place_tile(hover_position, current_tile)

func paint_part_at_hover() -> void:
	"""Continuously paint external parts (like armor) while dragging mouse"""
	if hover_position.x < 0 or hover_position.y < 0:
		return

	# Use centered grid position for rotated parts
	var centered_pos = get_centered_grid_position(hover_position, current_part, current_rotation)

	# Only paint if we've moved to a new cell
	if centered_pos == last_painted_cell:
		return

	# Only paint if placement is valid
	if !can_place_current_part():
		return

	last_painted_cell = centered_pos
	place_part(centered_pos, current_part)

func erase_at_hover() -> void:
	"""Continuously erase tiles/parts while dragging mouse"""
	if hover_position.x < 0 or hover_position.y < 0:
		return

	# Only erase if we've moved to a new cell
	if hover_position == last_painted_cell:
		return

	last_painted_cell = hover_position
	erase_at(hover_position)

func handle_click(_mouse_pos: Vector2) -> void:
	if hover_position.x < 0 or hover_position.y < 0:
		return

	if current_tool == "tile" and current_tile:
		last_painted_cell = hover_position
		place_tile(hover_position, current_tile)

	elif current_tool == "part" and current_part:
		# Use centered grid position for rotated parts
		var centered_pos = get_centered_grid_position(hover_position, current_part, current_rotation)
		place_part(centered_pos, current_part)

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
	placement.rotation = current_rotation

	# Debug: show which cells this part will occupy
	var occupied = placement.get_occupied_cells()
	print("GridEditor: Attempting to place ", part.part_name, " at ", pos, " with rotation ", current_rotation, "°")
	print("  Will occupy cells: ", occupied)

	if ship_definition.add_part(placement):
		print("  SUCCESS: Placed ", part.part_name)
		refresh()
		ship_modified.emit()
	else:
		print("  FAILED: Cannot place part - space already occupied by another part")

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

func set_part_rotation(rotation_degrees: int) -> void:
	"""Set the current rotation angle for parts (0, 90, 180, 270)"""
	current_rotation = rotation_degrees % 360
	update_preview()

func zoom_in() -> void:
	zoom_level = clamp(zoom_level + zoom_step, min_zoom, max_zoom)
	scale = Vector2(zoom_level, zoom_level)
	print("GridEditor: Zoom in to ", zoom_level)

func zoom_out() -> void:
	zoom_level = clamp(zoom_level - zoom_step, min_zoom, max_zoom)
	scale = Vector2(zoom_level, zoom_level)
	print("GridEditor: Zoom out to ", zoom_level)

func refresh() -> void:
	if renderer:
		renderer.set_ship(ship_definition)
	update_preview()
	queue_redraw()
