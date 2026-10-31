class_name HazardAmbience
extends CanvasLayer
## What a hazard looks like around the squad: drifting rocks in an asteroid field, lightning in an ion storm,
## the glare of a star close by, the murk of a nebula, the warped light at the collapse's edge. Drawn behind
## the ships; the hazard's effects are the encounter's.

var hazard := ""
var _time := 0.0
var _rocks: Array = []
var _bolt_timer := 0.0
var _bolt: Array = []
var _canvas := Control.new()


func _ready() -> void:
	layer = -5
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_hazard)
	add_child(_canvas)


func set_hazard(kind: String, seed_value: int) -> void:
	hazard = kind
	_rocks.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	if kind == "asteroids":
		for index in 26:
			var points := PackedVector2Array()
			var radius := rng.randf_range(8.0, 34.0)
			for step in 9:
				points.append(Vector2.from_angle(step * TAU / 9.0) * radius * rng.randf_range(0.7, 1.15))
			_rocks.append({"position": Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1080)), "velocity": Vector2(rng.randf_range(-40, -12), rng.randf_range(4, 16)), "spin": rng.randf_range(-0.6, 0.6), "angle": rng.randf() * TAU, "points": points, "shade": rng.randf_range(0.18, 0.4)})


func _process(delta: float) -> void:
	_time += delta
	for rock in _rocks:
		rock.position += rock.velocity * delta
		rock.angle += rock.spin * delta
		if rock.position.x < -60:
			rock.position.x = 1980
		if rock.position.y > 1140:
			rock.position.y = -60
	if hazard == "ion_storm":
		_bolt_timer -= delta
		if _bolt_timer <= 0.0:
			_bolt_timer = randf_range(1.5, 4.0)
			_bolt.clear()
			var at := Vector2(randf_range(100, 1820), -20)
			for step in 12:
				_bolt.append(at)
				at += Vector2(randf_range(-60, 60), randf_range(50, 110))
			Sfx.play("hit_soft", -14.0)
	_canvas.queue_redraw()


func _draw_hazard() -> void:
	var size := _canvas.size
	match hazard:
		"asteroids":
			for rock in _rocks:
				var transformed := PackedVector2Array()
				for point in rock.points:
					transformed.append(rock.position + point.rotated(rock.angle))
				var shade: float = rock.shade
				_canvas.draw_colored_polygon(transformed, Color(shade, shade * 0.92, shade * 0.85))
				transformed.append(transformed[0])
				_canvas.draw_polyline(transformed, Color(shade * 0.5, shade * 0.45, shade * 0.4), 1.5, true)
		"ion_storm":
			var age := clampf(1.0 - (_bolt_timer - 1.2), 0.0, 1.0)
			if _bolt.size() > 1 and _bolt_timer > 1.0:
				var strength := clampf((_bolt_timer - 1.0) * 3.0, 0.0, 1.0)
				_canvas.draw_polyline(PackedVector2Array(_bolt), Color(0.6, 0.85, 1.0, 0.5 * strength), 6.0, true)
				_canvas.draw_polyline(PackedVector2Array(_bolt), Color(0.95, 1.0, 1.0, 0.9 * strength), 2.0, true)
				_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.75, 1.0, 0.06 * strength))
		"sun":
			var pulse := 0.5 + 0.5 * sin(_time * 0.7)
			for ring in 8:
				_canvas.draw_circle(Vector2(size.x * 0.06, size.y * 0.12), 260.0 + ring * 70.0, Color(1.0, 0.6, 0.25, 0.025 + 0.01 * pulse))
		"nebula":
			for band in 5:
				var y := fmod(_time * 6.0 + band * 230.0, size.y + 400.0) - 200.0
				_canvas.draw_rect(Rect2(0, y, size.x, 160), Color(0.55, 0.3, 0.7, 0.035))
		"collapse_edge":
			var warp := 0.5 + 0.5 * sin(_time * 1.3)
			_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.05, 0.25, 0.05 + 0.04 * warp))
