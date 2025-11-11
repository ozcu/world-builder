# res://scripts/ship_designer/MockupGenerator.gd
# Utility script to generate simple mockup sprites for testing
class_name MockupGenerator extends Node

# Generate a simple colored rectangle texture
static func create_mockup_texture(size: Vector2i, color: Color, border_color: Color = Color.WHITE, border_width: int = 2) -> ImageTexture:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)

	# Fill with color
	for x in size.x:
		for y in size.y:
			# Draw border
			if x < border_width or x >= size.x - border_width or y < border_width or y >= size.y - border_width:
				image.set_pixel(x, y, border_color)
			else:
				image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)

# Generate a corridor tile
static func create_corridor_mockup(connections: Array) -> ImageTexture:
	var size = Vector2i(32, 32)
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var floor_color = Color(0.3, 0.3, 0.35)  # Dark gray
	var wall_color = Color(0.5, 0.5, 0.5)    # Light gray

	# Fill with floor color
	image.fill(floor_color)

	# Draw walls on sides that don't connect
	var up = Vector2i(0, -1)
	var down = Vector2i(0, 1)
	var left = Vector2i(-1, 0)
	var right = Vector2i(1, 0)

	# Draw walls
	if up not in connections:
		for x in size.x:
			for y in 4:
				image.set_pixel(x, y, wall_color)

	if down not in connections:
		for x in size.x:
			for y in 4:
				image.set_pixel(x, size.y - 1 - y, wall_color)

	if left not in connections:
		for y in size.y:
			for x in 4:
				image.set_pixel(x, y, wall_color)

	if right not in connections:
		for y in size.y:
			for x in 4:
				image.set_pixel(size.x - 1 - x, y, wall_color)

	return ImageTexture.create_from_image(image)

# Generate a door tile
static func create_door_mockup() -> ImageTexture:
	var size = Vector2i(32, 32)
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var floor_color = Color(0.3, 0.3, 0.35)
	var door_color = Color(0.7, 0.5, 0.2)  # Brown/orange

	image.fill(floor_color)

	# Draw door in center
	for x in range(8, 24):
		for y in range(4, 28):
			image.set_pixel(x, y, door_color)

	# Door frame
	var frame_color = Color(0.8, 0.6, 0.3)
	for x in range(8, 24):
		image.set_pixel(x, 4, frame_color)
		image.set_pixel(x, 27, frame_color)
	for y in range(4, 28):
		image.set_pixel(8, y, frame_color)
		image.set_pixel(23, y, frame_color)

	return ImageTexture.create_from_image(image)

# Generate an airlock tile
static func create_airlock_mockup() -> ImageTexture:
	var size = Vector2i(32, 32)
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var bg_color = Color(0.2, 0.2, 0.25)
	var airlock_color = Color(0.8, 0.8, 0.2)  # Yellow

	image.fill(bg_color)

	# Draw airlock indicator (circle)
	var center = Vector2i(16, 16)
	var radius = 10
	for x in size.x:
		for y in size.y:
			var dist = Vector2(x, y).distance_to(Vector2(center.x, center.y))
			if dist <= radius:
				image.set_pixel(x, y, airlock_color)
			elif dist <= radius + 2:
				image.set_pixel(x, y, Color.WHITE)

	return ImageTexture.create_from_image(image)

# Generate part mockup with door indicators
static func create_part_mockup(size_cells: Vector2i, color: Color, door_positions: Array) -> ImageTexture:
	var pixel_size = Vector2i(size_cells.x * 32, size_cells.y * 32)
	var image = Image.create(pixel_size.x, pixel_size.y, false, Image.FORMAT_RGBA8)

	# Fill with color
	image.fill(color)

	# Draw border
	var border_color = Color.WHITE
	for x in pixel_size.x:
		for y in pixel_size.y:
			if x < 2 or x >= pixel_size.x - 2 or y < 2 or y >= pixel_size.y - 2:
				image.set_pixel(x, y, border_color)

	# Draw door indicators (small circles)
	var door_color = Color.GREEN
	for door_pos in door_positions:
		var door_px = Vector2i(door_pos.x * 32 + 16, door_pos.y * 32 + 16)
		for x in range(-4, 5):
			for y in range(-4, 5):
				if x * x + y * y <= 16:  # Circle
					var px = door_px.x + x
					var py = door_px.y + y
					if px >= 0 and px < pixel_size.x and py >= 0 and py < pixel_size.y:
						image.set_pixel(px, py, door_color)

	return ImageTexture.create_from_image(image)
