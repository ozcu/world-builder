# res://Planet2DGenerator.gd
@tool
extends Node2D

# ---------- Nodes ----------
@export var planet: Sprite2D
@export var clouds: Sprite2D
@export var atmos: Sprite2D
@export var rings_front: Sprite2D
@export var rings_back: Sprite2D

# ---------- Archetypes ----------
const ARCHES := [
	"Earthlike","Desert/Mars","Ice","Ocean","Venus",
	"Gas/Uranus","Gas/Neptune","Gas/Saturn"
]
@export_enum("Earthlike","Desert/Mars","Ice","Ocean","Venus","Gas/Uranus","Gas/Neptune","Gas/Saturn")
var archetype := "Earthlike"

# ---------- Lighting ----------
@export var light_angle: float = 0.6:  # radians
	set(value):
		light_angle = value
		_set_all_light_angle(value)

@export var use_dynamic_sun_lighting := true  # Calculate light angle from Sun2D position

# ---------- Randomization / Editor ----------
@export var seed: int = -1
@export var REROLL_NOW: bool = false
@export var auto_randomize := true

# ---------- Master dials ----------
@export var planet_exposure := 1.0
@export var planet_light_strength := 1.0
@export var planet_ambient := 0.26
@export var planet_specular := 0.5
@export var clouds_brightness := 1.05
@export var atmos_intensity := 0.85

# ---------- Spin ----------
@export var spin_enabled := true
@export var spin_planet_deg_sec := Vector2(2.0, 20.0)        # random range °/s
@export var spin_clouds_extra_deg_sec := Vector2(3.0, 30.0)  # offset added to planet spin
@export var rings_follow_planet := true

var rng := RandomNumberGenerator.new()
var _last_seed := 0

# per-instance angular velocities (rad/s)
var _w_planet := 0.0
var _w_clouds := 0.0
var _w_rings  := 0.0

# current rotation angles (rad)
var _planet_rotation := 0.0

# sun reference for dynamic lighting
var _sun_node: Node2D = null

func _ready() -> void:
	if planet == null and has_node("Planet"): planet = $Planet
	if clouds == null and has_node("Clouds"): clouds = $Clouds
	if atmos  == null and has_node("Atmosphere"): atmos = $Atmosphere
	if rings_front == null and has_node("RingsFront"): rings_front = $RingsFront
	if rings_back  == null and has_node("RingsBack"):  rings_back  = $RingsBack

	_make_unique(planet); _make_unique(clouds); _make_unique(atmos)
	_make_unique(rings_front); _make_unique(rings_back)

	if Engine.is_editor_hint():
		_apply()
		set_process(true)
	elif auto_randomize:
		_apply()

	# Find sun for dynamic lighting (only at runtime)
	if !Engine.is_editor_hint() and use_dynamic_sun_lighting:
		call_deferred("_find_sun")

func _process(dt: float) -> void:
	# editor reroll
	if Engine.is_editor_hint() and (seed != _last_seed or REROLL_NOW):
		_apply()
		REROLL_NOW = false

	# Update dynamic sun lighting (only at runtime)
	if !Engine.is_editor_hint() and use_dynamic_sun_lighting and _sun_node:
		_update_sun_lighting()

	# continuous spin
	if spin_enabled:
		# Update planet rotation via shader parameter
		_planet_rotation += _w_planet * dt
		if planet and planet.material:
			planet.material.set_shader_parameter("rotation_y", _planet_rotation)

		# Atmosphere stays static (lighting is static)
		# Clouds rotate independently
		if clouds: clouds.rotation += _w_clouds * dt

		# Rings rotation
		if rings_follow_planet:
			if rings_front: rings_front.rotation += _w_planet * dt
			if rings_back:  rings_back.rotation  += _w_planet * dt
		else:
			if rings_front: rings_front.rotation += _w_rings * dt
			if rings_back:  rings_back.rotation  += _w_rings * dt

# ---------------- internals ----------------

func _apply() -> void:
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	_last_seed = seed

	_planet_rotation = 0.0  # Reset rotation when regenerating
	_randomize_planet()
	_randomize_spin()

	if Engine.is_editor_hint():
		notify_property_list_changed()

func _rand_sign() -> float:
	# Returns +1.0 or -1.0 with equal probability
	return 1.0 if ((rng.randi() & 1) == 0) else -1.0

func _randomize_spin() -> void:
	var w_base := deg_to_rad(rng.randf_range(spin_planet_deg_sec.x, spin_planet_deg_sec.y)) * _rand_sign()
	_w_planet = w_base
	# Clouds rotate with planet but at slightly different speed (usually faster)
	# 80% chance faster, 20% chance slower - always same direction
	var cloud_multiplier := rng.randf_range(1.05, 1.35) if rng.randf() < 0.8 else rng.randf_range(0.85, 0.95)
	_w_clouds = w_base * cloud_multiplier
	_w_rings  = deg_to_rad(rng.randf_range(0.2, 6.0)) * _rand_sign()


func _make_unique(s: Sprite2D) -> void:
	if s and s.material and !s.material.resource_local_to_scene:
		s.material = s.material.duplicate()
		s.material.resource_local_to_scene = true

func _rc(h0: float, h1: float, s: float, v: float) -> Color:
	return Color.from_hsv(rng.randf_range(h0, h1), s, v)

func _v3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)

# portable param check – look for uniform name in shader code
func _has_param_via_source(mat: ShaderMaterial, name: String) -> bool:
	if mat == null: return false
	var sh: Shader = mat.shader
	if sh == null: return false
	var src := sh.code
	if src == "": return false
	return src.findn("uniform ") != -1 and src.findn(name) != -1

func _set_all_light_angle(ang: float) -> void:
	if planet and planet.material: planet.material.set_shader_parameter("light_angle", ang)
	if clouds and clouds.material: clouds.material.set_shader_parameter("light_angle", ang)
	if atmos  and atmos.material:  atmos.material.set_shader_parameter("light_angle", ang)
	if rings_front and rings_front.material: rings_front.material.set_shader_parameter("light_angle", ang)
	if rings_back  and rings_back.material:  rings_back.material.set_shader_parameter("light_angle", ang)

func _randomize_planet() -> void:
	_set_all_light_angle(light_angle)

	# ---- Planet surface defaults ----
	if planet and planet.material:
		var pm := planet.material
		pm.set_shader_parameter("seed", rng.randi() % 10000)
		pm.set_shader_parameter("rotation_y", 0.0)  # Initialize rotation
		pm.set_shader_parameter("elevation_amp", rng.randf_range(0.06, 0.14))
		pm.set_shader_parameter("elevation_freq", rng.randf_range(1.4, 3.2))
		pm.set_shader_parameter("detail_amp", rng.randf_range(0.012, 0.035))
		pm.set_shader_parameter("detail_freq", rng.randf_range(4.0, 9.0))
		pm.set_shader_parameter("water_level", rng.randf_range(-0.02, 0.03))
		pm.set_shader_parameter("snow_height", rng.randf_range(0.45, 0.65))
		pm.set_shader_parameter("exposure", planet_exposure)
		pm.set_shader_parameter("light_strength", planet_light_strength)
		pm.set_shader_parameter("ambient_floor", planet_ambient)
		pm.set_shader_parameter("specular_strength", planet_specular)
		pm.set_shader_parameter("band_strength", 0.0) # off unless gas giant

		var shallow := _rc(0.52, 0.60, 0.65, 0.60)
		var land_lo := _rc(0.20, 0.38, 0.70, 0.35)
		var land_hi := _rc(0.08, 0.16, 0.45, 0.80)
		pm.set_shader_parameter("shallow_color", _v3(shallow))
		pm.set_shader_parameter("land_low", _v3(land_lo))
		pm.set_shader_parameter("land_high", _v3(land_hi))

	# ---- Clouds defaults ----
	if clouds and clouds.material:
		var cm := clouds.material
		cm.set_shader_parameter("seed", rng.randi() % 10000)
		cm.set_shader_parameter("coverage", rng.randf_range(0.35, 0.75))
		cm.set_shader_parameter("crisp", rng.randf_range(2.0, 4.0))
		cm.set_shader_parameter("freq", rng.randf_range(2.0, 5.0))
		cm.set_shader_parameter("density", rng.randf_range(0.55, 0.90))
		cm.set_shader_parameter("wind_speed", rng.randf_range(0.05, 0.35))
		if _has_param_via_source(cm, "brightness"):
			cm.set_shader_parameter("brightness", clouds_brightness)

	# ---- Atmos defaults ----
	if atmos and atmos.material:
		var am := atmos.material
		var hue := rng.randf_range(0.55, 0.68)
		var ray := Color.from_hsv(hue, 0.35, 1.0)
		var mie := Color.from_hsv(hue - 0.05, 0.10, 1.0)
		am.set_shader_parameter("color_rayleigh", _v3(ray))
		am.set_shader_parameter("color_mie", _v3(mie))
		am.set_shader_parameter("intensity", atmos_intensity)
		am.set_shader_parameter("mie_strength", rng.randf_range(0.18, 0.30))
		am.set_shader_parameter("rim_power", rng.randf_range(2.6, 3.4))
		am.set_shader_parameter("day_side_bias", rng.randf_range(0.35, 0.50))

	# hide rings by default; archetypes enable/configure them
	_set_rings_visible(false)

	# ---- Archetype overrides ----
	match archetype:
		"Earthlike":
			pass

		"Desert/Mars":
			if planet and planet.material:
				planet.material.set_shader_parameter("water_level", -0.15)
				planet.material.set_shader_parameter("specular_strength", 0.2)
				planet.material.set_shader_parameter("elevation_amp", rng.randf_range(0.06, 0.11))
				var sand_lo := Color(0.50, 0.30, 0.15)
				var sand_hi := Color(0.80, 0.65, 0.45)
				planet.material.set_shader_parameter("shallow_color", Vector3(0.18, 0.10, 0.08))
				planet.material.set_shader_parameter("land_low", _v3(sand_lo))
				planet.material.set_shader_parameter("land_high", _v3(sand_hi))
			if clouds and clouds.material:
				clouds.material.set_shader_parameter("density", 0.0)
			if atmos and atmos.material:
				atmos.material.set_shader_parameter("intensity", 0.35)
				atmos.material.set_shader_parameter("mie_strength", 0.15)
				atmos.material.set_shader_parameter("color_rayleigh", Vector3(0.90, 0.50, 0.30))
				atmos.material.set_shader_parameter("color_mie", Vector3(1.00, 0.80, 0.60))

		"Ice":
			if planet and planet.material:
				planet.material.set_shader_parameter("water_level", 0.02)
				planet.material.set_shader_parameter("snow_height", 0.35)
				planet.material.set_shader_parameter("specular_strength", 0.7)
				planet.material.set_shader_parameter("shallow_color", Vector3(0.25, 0.45, 0.65))
				planet.material.set_shader_parameter("land_low", Vector3(0.75, 0.80, 0.85))
				planet.material.set_shader_parameter("land_high", Vector3(0.92, 0.95, 1.00))
			if clouds and clouds.material:
				clouds.material.set_shader_parameter("coverage", 0.25)
				clouds.material.set_shader_parameter("density", 0.35)
			if atmos and atmos.material:
				atmos.material.set_shader_parameter("intensity", 1.0)
				atmos.material.set_shader_parameter("color_rayleigh", Vector3(0.70, 0.85, 1.00))

		"Ocean":
			if planet and planet.material:
				planet.material.set_shader_parameter("water_level", 0.04)
				planet.material.set_shader_parameter("specular_strength", 1.0)
				planet.material.set_shader_parameter("specular_gloss", 110.0)
				planet.material.set_shader_parameter("shallow_color", Vector3(0.04, 0.30, 0.70))
			if clouds and clouds.material:
				clouds.material.set_shader_parameter("coverage", 0.55)
				clouds.material.set_shader_parameter("density", 0.82)

		"Venus":
			if planet and planet.material:
				planet.material.set_shader_parameter("elevation_amp", 0.03)
				planet.material.set_shader_parameter("water_level", -0.20)
				planet.material.set_shader_parameter("specular_strength", 0.0)
				planet.material.set_shader_parameter("land_low", Vector3(0.60, 0.50, 0.35))
				planet.material.set_shader_parameter("land_high", Vector3(0.75, 0.65, 0.45))
			if clouds and clouds.material:
				clouds.material.set_shader_parameter("coverage", 0.92)
				clouds.material.set_shader_parameter("density", 0.95)
				if _has_param_via_source(clouds.material, "brightness"):
					clouds.material.set_shader_parameter("brightness", 1.22)
			if atmos and atmos.material:
				atmos.material.set_shader_parameter("intensity", 1.2)
				atmos.material.set_shader_parameter("mie_strength", 0.35)
				atmos.material.set_shader_parameter("color_rayleigh", Vector3(1.0, 0.95, 0.85))

		"Gas/Uranus":
			if planet and planet.material:
				planet.material.set_shader_parameter("band_strength", 1.0)
				planet.material.set_shader_parameter("band_freq", rng.randf_range(5.5, 7.5))
				planet.material.set_shader_parameter("band_contrast", 1.2)
				planet.material.set_shader_parameter("band_col_a", Vector3(0.70, 0.90, 0.96))
				planet.material.set_shader_parameter("band_col_b", Vector3(0.60, 0.85, 0.94))
				planet.material.set_shader_parameter("specular_strength", 0.0)
			_configure_rings(true, 0.95, 1.25, 30.0,
				Color(0.80,0.90,0.95), Color(0.70,0.85,0.92), 10.0, 1.2, 0.55)
			if atmos and atmos.material:
				atmos.material.set_shader_parameter("intensity", 0.9)
				atmos.material.set_shader_parameter("color_rayleigh", Vector3(0.75, 0.95, 1.0))

		"Gas/Neptune":
			if planet and planet.material:
				planet.material.set_shader_parameter("band_strength", 0.8)
				planet.material.set_shader_parameter("band_freq", rng.randf_range(6.5, 9.0))
				planet.material.set_shader_parameter("band_contrast", 1.8)
				planet.material.set_shader_parameter("band_col_a", Vector3(0.20, 0.35, 0.85))
				planet.material.set_shader_parameter("band_col_b", Vector3(0.12, 0.28, 0.70))
				planet.material.set_shader_parameter("specular_strength", 0.0)
			_set_rings_visible(false)
			if clouds and clouds.material:
				clouds.material.set_shader_parameter("coverage", 0.35)
				clouds.material.set_shader_parameter("density", 0.35)
				if _has_param_via_source(clouds.material, "brightness"):
					clouds.material.set_shader_parameter("brightness", 1.2)
			if atmos and atmos.material:
				atmos.material.set_shader_parameter("intensity", 0.85)
				atmos.material.set_shader_parameter("color_rayleigh", Vector3(0.55, 0.75, 1.0))

		"Gas/Saturn":
			if planet and planet.material:
				planet.material.set_shader_parameter("band_strength", 1.0)
				planet.material.set_shader_parameter("band_freq", rng.randf_range(7.0, 10.0))
				planet.material.set_shader_parameter("band_contrast", 2.2)
				planet.material.set_shader_parameter("band_col_a", Vector3(0.86, 0.79, 0.68))
				planet.material.set_shader_parameter("band_col_b", Vector3(0.92, 0.88, 0.80))
				planet.material.set_shader_parameter("specular_strength", 0.0)
			_configure_rings(true, 0.75, 1.45, 26.7,
				Color(0.86,0.79,0.68), Color(0.92,0.88,0.80), 12.0, 1.8, 1.0)

# ----- rings helpers -----

func _set_rings_visible(v: bool) -> void:
	if rings_back:  rings_back.visible  = v
	if rings_front: rings_front.visible = v

func _set_ring_uniforms(sm: ShaderMaterial, inner: float, outer: float, tilt: float,
		a: Color, b: Color, freq: float, contrast: float, bright: float, which_half: int) -> void:
	if sm == null: return
	sm.set_shader_parameter("inner_radius", inner)
	sm.set_shader_parameter("outer_radius", outer)
	sm.set_shader_parameter("tilt_deg", tilt)
	sm.set_shader_parameter("rotate_deg", 0.0)
	sm.set_shader_parameter("color_a", Vector3(a.r,a.g,a.b))
	sm.set_shader_parameter("color_b", Vector3(b.r,b.g,b.b))
	sm.set_shader_parameter("band_freq", freq)
	sm.set_shader_parameter("band_contrast", contrast)
	sm.set_shader_parameter("brightness", bright)
	sm.set_shader_parameter("day_contrast", 0.8)
	sm.set_shader_parameter("light_angle", light_angle)
	sm.set_shader_parameter("which_half", which_half)  # 1 front, 2 back

func _configure_rings(visible: bool, inner: float, outer: float, tilt: float,
		a: Color, b: Color, freq: float, contrast: float, bright: float) -> void:
	_set_rings_visible(visible)
	if !visible: return
	if rings_back and rings_back.material:
		_set_ring_uniforms(rings_back.material, inner, outer, tilt, a, b, freq, contrast, bright, 2)
	if rings_front and rings_front.material:
		_set_ring_uniforms(rings_front.material, inner, outer, tilt, a, b, freq, contrast, bright, 1)
	_autosize_rings_to_planet(outer, 1.6)

# pixel-aware autosize for 1×1 ring quads
func _autosize_rings_to_planet(outer_norm: float, outer_mult: float = 1.6) -> void:
	if planet == null or planet.texture == null: return
	var planet_radius_px := 0.5 * planet.texture.get_width() * planet.scale.x
	var ring_outer_px := planet_radius_px * outer_mult
	var quad_size_px: float = (2.0 * ring_outer_px) / max(outer_norm, 0.001)
	if rings_back:  rings_back.scale  = Vector2(quad_size_px, quad_size_px)
	if rings_front: rings_front.scale = Vector2(quad_size_px, quad_size_px)

# ----- dynamic sun lighting -----

func _find_sun() -> void:
	var root = get_tree().root
	_sun_node = _search_for_sun(root)
	if _sun_node:
		print("Planet ", name, " found sun at ", _sun_node.global_position)

func _search_for_sun(node: Node) -> Node2D:
	if node.name.begins_with("Sun2D"):
		return node as Node2D
	for child in node.get_children():
		var result = _search_for_sun(child)
		if result:
			return result
	return null

func _update_sun_lighting() -> void:
	# Calculate angle from planet to sun
	var to_sun = _sun_node.global_position - global_position
	var angle = to_sun.angle()
	# Convert to shader space (0 = right, PI/2 = down in Godot coords)
	# Shader expects light angle where 0 = from right
	_set_all_light_angle(angle)
