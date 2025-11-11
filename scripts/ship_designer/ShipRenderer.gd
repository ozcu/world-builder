# res://scripts/ship_designer/ShipRenderer.gd
# Simple renderer for visualizing ShipDefinition
class_name ShipRenderer extends Node2D

@export var ship_definition: ShipDefinition
@export var cell_size: int = 32  # Pixels per grid cell
@export var auto_center: bool = true

var tile_sprites: Dictionary = {}
var part_sprites: Dictionary = {}

func _ready() -> void:
	if ship_definition:
		render_ship()

func render_ship() -> void:
	if ship_definition == null:
		print("ShipRenderer: Cannot render - ship_definition is null")
		return

	print("ShipRenderer: Starting render with cell_size=", cell_size, ", auto_center=", auto_center)

	# Clear existing sprites
	clear_sprites()

	# Get ship bounds for centering
	var bounds = ship_definition.get_bounds()
	var offset = Vector2.ZERO

	if auto_center:
		# Center the ship in the viewport
		var viewport_size = get_viewport_rect().size
		var ship_pixel_size = Vector2(bounds.size.x * cell_size, bounds.size.y * cell_size)
		offset = (viewport_size - ship_pixel_size) / 2.0
		offset -= Vector2(bounds.position.x * cell_size, bounds.position.y * cell_size)
		print("ShipRenderer: Auto-center offset = ", offset)
	else:
		print("ShipRenderer: No auto-center, offset = ", offset)

	# Render tiles
	for i in ship_definition.tile_positions.size():
		var pos = ship_definition.tile_positions[i]
		var tile = ship_definition.tile_data[i]

		var sprite = Sprite2D.new()
		sprite.texture = tile.sprite
		sprite.position = offset + Vector2(pos.x * cell_size, pos.y * cell_size)
		sprite.centered = false
		add_child(sprite)

		tile_sprites[pos] = sprite

	# Render parts
	for placement in ship_definition.parts:
		if !placement.enabled or placement.part == null:
			continue

		var sprite = Sprite2D.new()
		sprite.texture = placement.part.sprite
		sprite.position = offset + Vector2(
			placement.grid_position.x * cell_size,
			placement.grid_position.y * cell_size
		)
		sprite.centered = false

		# Apply rotation (0, 90, 180, 270)
		# Use rotation property, with fallback to horizontal for legacy compatibility
		var rotation_angle = placement.rotation
		sprite.rotation = deg_to_rad(rotation_angle)

		# Adjust position based on rotation to maintain correct grid alignment
		# Rotation happens around top-left corner (0,0) since centered = false
		var size = placement.part.size
		match rotation_angle:
			90:
				# Rotated 90° clockwise: need to shift by width
				sprite.position += Vector2(0, size.x * cell_size)
			180:
				# Rotated 180°: need to shift by width and height
				sprite.position += Vector2(size.x * cell_size, size.y * cell_size)
			270:
				# Rotated 270° clockwise (90° counter-clockwise): need to shift by height
				sprite.position += Vector2(size.y * cell_size, 0)

		add_child(sprite)
		part_sprites[placement] = sprite

	print("ShipRenderer: Rendered ", tile_sprites.size(), " tiles and ", part_sprites.size(), " parts")
	print("ShipRenderer: Total child sprites: ", get_child_count())

func clear_sprites() -> void:
	for sprite in tile_sprites.values():
		if sprite:
			sprite.queue_free()
	for sprite in part_sprites.values():
		if sprite:
			sprite.queue_free()

	tile_sprites.clear()
	part_sprites.clear()

func set_ship(new_definition: ShipDefinition) -> void:
	ship_definition = new_definition
	render_ship()
