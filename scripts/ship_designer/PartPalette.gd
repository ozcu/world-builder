# res://scripts/ship_designer/PartPalette.gd
# UI palette for selecting ship parts
class_name PartPalette extends VBoxContainer

signal part_selected(part: ShipPart)

var parts: Dictionary = {}
var part_buttons: Array = []
var selected_button: Control = null

func _ready() -> void:
	# Add bright debug background to confirm palette is visible
	var debug_bg = ColorRect.new()
	debug_bg.color = Color(0.3, 0.1, 0.3, 1.0)  # Dark purple background
	debug_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	debug_bg.z_index = -1
	add_child(debug_bg)
	move_child(debug_bg, 0)  # Behind everything

	# Add label
	var label = Label.new()
	label.text = "PARTS"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)

	# Add separator
	var separator = HSeparator.new()
	add_child(separator)

func set_parts(parts_dict: Dictionary) -> void:
	parts = parts_dict

	print("=== PartPalette.set_parts() called ===")
	print("PartPalette container - Size: ", size, ", Visible: ", visible, ", In tree: ", is_inside_tree())

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

func add_part_button(_part_id: String, part: ShipPart) -> void:
	# Create a panel container for the entire button
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 70)
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
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if part.sprite:
		icon.texture = part.sprite
	hbox.add_child(icon)

	# Create and add label
	var text_label = Label.new()
	text_label.text = part.part_name
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_label)

	# Make panel clickable
	panel.gui_input.connect(_on_panel_input.bind(part, panel))
	panel.mouse_entered.connect(_on_panel_hover.bind(panel, true))
	panel.mouse_exited.connect(_on_panel_hover.bind(panel, false))

	add_child(panel)
	part_buttons.append(panel)

	print("PartPalette: Added part panel for ", part.part_name)
	print("  Panel - Size: ", panel.size, ", MinSize: ", panel.custom_minimum_size, ", Visible: ", panel.visible)
	print("  Icon - Size: ", icon.size, ", MinSize: ", icon.custom_minimum_size, ", Texture: ", icon.texture != null)
	print("  Style - BgColor: ", style.bg_color, ", BorderWidth: 2px")

func _on_panel_input(event: InputEvent, part: ShipPart, panel: Control) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_part_button_pressed(part, panel)

func _on_panel_hover(panel: Control, entered: bool) -> void:
	if selected_button == panel:
		return

	if entered:
		panel.modulate = Color(1.2, 1.2, 1.2)
	else:
		panel.modulate = Color(1, 1, 1)

func _on_part_button_pressed(part: ShipPart, panel: Control) -> void:
	# Unhighlight previous
	if selected_button:
		selected_button.modulate = Color(1, 1, 1)

	# Highlight selected
	selected_button = panel
	panel.modulate = Color(0.7, 1, 0.7)

	part_selected.emit(part)
	print("PartPalette: Selected ", part.part_name)
