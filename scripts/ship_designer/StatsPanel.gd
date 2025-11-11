# res://scripts/ship_designer/StatsPanel.gd
# Bottom panel showing ship statistics
class_name StatsPanel extends HBoxContainer

var label_mass: Label
var label_thrust: Label
var label_energy: Label
var label_crew: Label
var label_cargo: Label
var label_validation: Label

func _ready() -> void:
	# Create labels
	label_mass = create_stat_label("Mass: 0 kg")
	label_thrust = create_stat_label("Thrust: 0 N")
	label_energy = create_stat_label("Energy: 0 kW")
	label_crew = create_stat_label("Crew: 0")
	label_cargo = create_stat_label("Cargo: 0")

	add_child(VSeparator.new())

	label_validation = create_stat_label("Status: Invalid")
	label_validation.add_theme_color_override("font_color", Color.RED)

func create_stat_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(120, 0)
	add_child(label)
	return label

func update_stats(metadata: Dictionary, validation: Dictionary) -> void:
	# Update stats
	label_mass.text = "Mass: %.0f kg" % metadata.total_mass
	label_thrust.text = "Thrust: %.0f N" % metadata.thrust_power
	label_energy.text = "Energy: %.0f kW" % (metadata.energy_capacity / 1000.0)
	label_crew.text = "Crew: %d" % metadata.crew_capacity
	label_cargo.text = "Cargo: %d" % metadata.cargo_capacity

	# Update validation status
	if validation.valid:
		label_validation.text = "Status: Valid ✓"
		label_validation.add_theme_color_override("font_color", Color.GREEN)
	else:
		label_validation.text = "Status: Invalid ✗"
		label_validation.add_theme_color_override("font_color", Color.RED)

		# Show errors
		if validation.errors.size() > 0:
			var error_text = "\nErrors:\n"
			for error in validation.errors:
				error_text += "  - " + error + "\n"
			label_validation.tooltip_text = error_text
