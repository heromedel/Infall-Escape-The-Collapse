## The animated backdrop: drifting stars, faint nebulae and the collapse, a black hole with a glowing ring
## that slowly turns. Optional strength sets how big and bright the collapse is.
class_name Starfield
extends Control

var collapse_center := Vector2(0.82, 0.18)
var collapse_size := 1.0
var _stars: Array = []
var _time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 260:
		_stars.append({"position": Vector2(rng.randf(), rng.randf()), "depth": rng.randf_range(0.2, 1.0),
			"twinkle": rng.randf() * TAU, "warm": rng.randf() < 0.2})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var area := size
	draw_rect(Rect2(Vector2.ZERO, area), UiKit.BACKGROUND)
	# Nebulae: big soft blobs of colour.
	_soft_blob(area * Vector2(0.15, 0.75), area.x * 0.35, Color("#2a1450"), 0.22)
	_soft_blob(area * Vector2(0.55, 0.55), area.x * 0.3, Color("#0f2c4a"), 0.18)
	_soft_blob(area * collapse_center, area.x * 0.28 * collapse_size, Color("#4a2208"), 0.25)
	# Stars drift toward the collapse, faster when nearer the viewer.
	var pull := area * collapse_center
	for star in _stars:
		var base: Vector2 = star.position * area
		var drift: Vector2 = (pull - base).normalized() * fmod(_time * 6.0 * star.depth, 40.0)
		var point := base + drift
		var brightness: float = (0.35 + 0.65 * star.depth) * (0.75 + 0.25 * sin(_time * 2.0 + star.twinkle))
		var color := Color("#ffd9a8") if star.warm else Color("#cfe2ff")
		draw_circle(point, 0.6 + star.depth * 1.1, Color(color, brightness))
	_draw_collapse(pull, area.x * 0.07 * collapse_size)


func _draw_collapse(center: Vector2, radius: float) -> void:
	for i in 10:
		draw_circle(center, radius * (2.6 - i * 0.14), Color(Color("#ff9b3d"), 0.012 + i * 0.006))
	# Accretion ring: tilted ellipse of arcs turning slowly.
	for ring in 4:
		var points := PackedVector2Array()
		var ring_radius := radius * (1.25 + ring * 0.22)
		for step in 65:
			var angle := step * TAU / 64.0 + _time * (0.25 - ring * 0.04)
			points.append(center + Vector2(cos(angle) * ring_radius * 1.6, sin(angle) * ring_radius * 0.42).rotated(-0.35))
		draw_polyline(points, Color(Color("#ffb347").lerp(Color("#ff5a2a"), ring / 4.0), 0.55 - ring * 0.1), 3.0 - ring * 0.5, true)
	draw_circle(center, radius * 1.08, Color("#ffcf7a", 0.35))
	draw_circle(center, radius, Color("#020205"))


func _soft_blob(center: Vector2, radius: float, color: Color, strength: float) -> void:
	for i in 8:
		draw_circle(center, radius * (1.0 - i * 0.11), Color(color, strength * 0.12))
