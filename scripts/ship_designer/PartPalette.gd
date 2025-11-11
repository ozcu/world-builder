# res://scripts/ship_designer/PartPalette.gd
# UI palette for selecting ship parts
class_name PartPalette extends VBoxContainer

signal part_selected(part: ShipPart)

var parts: Dictionary = {}
var part_buttons: Array = []
var selected_button: Button = null

func _ready() -> void:
	# Add label
	var label = Label.new()
	label.text = "PARTS"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

	# Add separator
	var separator = HSeparator.new()
	add_child(separator)

func set_parts(parts_dict: Dictionary) -> void:
	parts = parts_dict

	# Clear existing buttons
	for button in part_buttons:
		button.queue_free()
	part_buttons.clear()

	# Group by category
	var by_category = {
		PartCategory.Type.PROPULSION: [],
		PartCategory.Type.ENERGY: [],
		PartCategory.Type.CREW: [],
		PartCategory.Type.SENSORS: [],
		PartCategory.Type.UTILITY: [],
		PartCategory.Type.DEFENSE: []
	}

	for part_id in parts.keys():
		var part = parts[part_id]
		by_category[part.category].append({
			"id": part_id,
			"part": part
		})

	# Add each category
	var category_names = {
		PartCategory.Type.PROPULSION: "Propulsion",
		PartCategory.Type.ENERGY: "Energy",
		PartCategory.Type.CREW: "Crew",
		PartCategory.Type.SENSORS: "Sensors",
		PartCategory.Type.UTILITY: "Utility",
		PartCategory.Type.DEFENSE: "Defense"
	}

	for category in by_category.keys():
		var items = by_category[category]
		if items.size() > 0:
			add_category_label(category_names[category])
			for item in items:
				add_part_button(item.id, item.part)

func add_category_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = Color(0.7, 0.7, 0.7)
	add_child(label)

func add_part_button(part_id: String, part: ShipPart) -> void:
	var button = Button.new()
	button.text = part.part_name
	button.custom_minimum_size = Vector2(150, 40)

	# Add icon if sprite exists
	if part.sprite:
		var icon = TextureRect.new()
		icon.texture = part.sprite
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.custom_minimum_size = Vector2(32, 32)
		button.add_child(icon)

	button.pressed.connect(_on_part_button_pressed.bind(part, button))
	add_child(button)
	part_buttons.append(button)

func _on_part_button_pressed(part: ShipPart, button: Button) -> void:
	# Highlight selected button
	if selected_button:
		selected_button.modulate = Color(1, 1, 1)

	selected_button = button
	button.modulate = Color(0.7, 1, 0.7)

	part_selected.emit(part)
