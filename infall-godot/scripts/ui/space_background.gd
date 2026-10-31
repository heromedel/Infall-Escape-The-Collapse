class_name SpaceBackground
extends CanvasLayer
## The space behind the battle world, drawn by shaders/space.gdshader. Each cluster sets its own look.

var _rect := ColorRect.new()
var _material := ShaderMaterial.new()
var _time := 0.0


func _ready() -> void:
	layer = -10
	_material.shader = load("res://shaders/space.gdshader")
	_rect.material = _material
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func _process(delta: float) -> void:
	_time += delta
	_material.set_shader_parameter("time", _time)
	_material.set_shader_parameter("screen_size", _rect.size)


func follow_camera(camera_position: Vector2, zoom: float) -> void:
	_material.set_shader_parameter("camera_offset", camera_position)
	_material.set_shader_parameter("zoom", zoom)


## Gives the backdrop a cluster's look, picked from its seed: nebula colours, a planet or a star, the collapse.
func set_cluster_look(look_seed: int, collapse_near: float, hazard: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = look_seed
	_material.set_shader_parameter("seed", float(look_seed % 997) * 0.37)
	var palettes := [
		[Color(0.22, 0.07, 0.32), Color(0.05, 0.16, 0.34)],
		[Color(0.04, 0.2, 0.28), Color(0.1, 0.06, 0.25)],
		[Color(0.3, 0.1, 0.12), Color(0.12, 0.05, 0.22)],
		[Color(0.06, 0.12, 0.3), Color(0.02, 0.22, 0.2)],
		[Color(0.25, 0.16, 0.06), Color(0.08, 0.06, 0.2)],
	]
	var palette: Array = palettes[rng.randi_range(0, palettes.size() - 1)]
	var amount := rng.randf_range(0.35, 0.8)
	if hazard == "nebula":
		palette = [Color(0.35, 0.12, 0.45), Color(0.15, 0.25, 0.5)]
		amount = 1.4
	elif hazard == "ion_storm":
		palette = [Color(0.15, 0.35, 0.6), Color(0.3, 0.6, 0.8)]
		amount = 1.2
	_material.set_shader_parameter("nebula_a", palette[0])
	_material.set_shader_parameter("nebula_b", palette[1])
	_material.set_shader_parameter("nebula_amount", amount)
	var kind := 1.0 if rng.randf() < 0.7 else 0.0
	if hazard == "sun":
		kind = 2.0
	_material.set_shader_parameter("planet_kind", kind)
	# Big and partly past a screen edge, as far planets look in the genre; a star sits further off
	var left_side := rng.randf() < 0.5
	_material.set_shader_parameter("planet_position", Vector2(rng.randf_range(-0.06, 0.1) if left_side else rng.randf_range(0.9, 1.06), rng.randf_range(0.15, 0.85)))
	_material.set_shader_parameter("planet_radius", rng.randf_range(0.28, 0.42) if kind < 1.5 else 0.3)
	_material.set_shader_parameter("light_direction", Vector2(1.0 if left_side else -1.0, rng.randf_range(-0.7, 0.3)))   # lit on the side facing the battle
	var planet_colours := [Color(0.75, 0.45, 0.35), Color(0.35, 0.6, 0.8), Color(0.55, 0.7, 0.45), Color(0.8, 0.7, 0.5), Color(0.6, 0.45, 0.75)]
	var planet: Color = planet_colours[rng.randi_range(0, planet_colours.size() - 1)]
	if kind > 1.5:
		planet = Color(1.0, 0.75, 0.4)
	_material.set_shader_parameter("planet_colour", planet)
	_material.set_shader_parameter("planet_shadow", planet.darkened(0.88))
	_material.set_shader_parameter("collapse_glow", clampf(collapse_near, 0.0, 1.0))
	_material.set_shader_parameter("collapse_direction", Vector2(rng.randf_range(-1, 1), rng.randf_range(0.2, 1)).normalized())
