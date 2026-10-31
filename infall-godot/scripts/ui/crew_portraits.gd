class_name CrewPortraits
extends RefCounted
## Crew portrait tokens: a round token with a small face for each race, so crew read at a glance without
## animated sprites. The GATOS are cats, drawn as the approved pixel-art cat head (CrewFace). A crew member's
## look comes from their name, so it stays the same all run.



static func draw_token(canvas: CanvasItem, race_id: String, seed_text: String, centre: Vector2, radius: float, ring: Color, rim_width: float = 2.0) -> void:
	canvas.draw_circle(centre + Vector2(0, radius * 0.12), radius * 1.02, Color(0, 0, 0, 0.45))
	canvas.draw_circle(centre, radius, Color("#1a2333"))
	draw_face(canvas, race_id, seed_text, centre, radius * 0.86)
	canvas.draw_arc(centre, radius, 0, TAU, 28, ring, rim_width, true)


static func draw_face(canvas: CanvasItem, race_id: String, seed_text: String, centre: Vector2, r: float) -> void:
	var seed := absi(hash(seed_text))
	match race_id:
		"terran":
			CrewFace.draw(canvas, centre, seed_text, r * 2.0 / CrewFace.WIDTH)
		"mecha":
			_mecha(canvas, centre, r)
		"tentauri":
			_tentauri(canvas, seed, centre, r)
		"azurethea":
			_moth(canvas, centre, r)
		"senti":
			_senti(canvas, centre, r)
		"lykario":
			_wolf(canvas, seed, centre, r)
		"malphen":
			_malphen(canvas, seed, centre, r)
		_:
			canvas.draw_circle(centre, r * 0.7, Color("#c9cfd8"))


static func _mecha(canvas: CanvasItem, c: Vector2, r: float) -> void:
	canvas.draw_circle(c, r * 0.82, Color("#2e3039"))
	canvas.draw_circle(c + Vector2(-r * 0.15, -r * 0.2), r * 0.45, Color("#4a4d5a"))
	canvas.draw_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.16), Vector2(r * 1.2, r * 0.3)), Color("#0a0a0e"))
	canvas.draw_rect(Rect2(c + Vector2(-r * 0.52, -r * 0.1), Vector2(r * 1.04, r * 0.18)), Color("#aa28eb"))
	canvas.draw_rect(Rect2(c + Vector2(-r * 0.2, -r * 0.08), Vector2(r * 0.4, r * 0.1)), Color("#ebe1fa"))
	canvas.draw_line(c + Vector2(-r * 0.5, r * 0.45), c + Vector2(r * 0.5, r * 0.45), Color("#7a7f8e"), r * 0.08, true)


static func _tentauri(canvas: CanvasItem, seed: int, c: Vector2, r: float) -> void:
	var body: Color = [Color("#f4d9e8"), Color("#cdeee9"), Color("#e7defa"), Color("#ffd8cc")][seed % 4]
	for index in 5:
		var x := (index - 2) * r * 0.28
		canvas.draw_line(c + Vector2(x, r * 0.2), c + Vector2(x * 1.3, r * 0.92), body.darkened(0.15), r * 0.16, true)
	canvas.draw_circle(c + Vector2(0, -r * 0.12), r * 0.66, body)
	canvas.draw_circle(c + Vector2(-r * 0.2, -r * 0.36), r * 0.2, Color(1, 1, 1, 0.55))
	for side in [-1.0, 1.0]:
		canvas.draw_circle(c + Vector2(side * r * 0.26, -r * 0.06), r * 0.17, Color("#1d2433"))
		canvas.draw_circle(c + Vector2(side * r * 0.22, -r * 0.11), r * 0.06, Color.WHITE)
	canvas.draw_arc(c + Vector2(0, r * 0.12), r * 0.12, 0.2, PI - 0.2, 8, Color("#ff5eca"), r * 0.07, true)


static func _moth(canvas: CanvasItem, c: Vector2, r: float) -> void:
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([c + Vector2(side * r * 0.2, -r * 0.1), c + Vector2(side * r * 0.98, -r * 0.6), c + Vector2(side * r * 0.9, r * 0.3), c + Vector2(side * r * 0.25, r * 0.4)])
		canvas.draw_colored_polygon(wing, Color("#3a7fe0"))
		canvas.draw_circle(c + Vector2(side * r * 0.62, -r * 0.08), r * 0.13, Color("#9fe3ff"))
		canvas.draw_line(c + Vector2(side * r * 0.1, -r * 0.45), c + Vector2(side * r * 0.42, -r * 0.95), Color("#cfe6ff"), r * 0.06, true)
	canvas.draw_circle(c, r * 0.36, Color("#2547b8"))
	for side in [-1.0, 1.0]:
		canvas.draw_circle(c + Vector2(side * r * 0.16, -r * 0.08), r * 0.11, Color("#e8f6ff"))


static func _senti(canvas: CanvasItem, c: Vector2, r: float) -> void:
	var glow := Color("#d2ff00")
	var cyan := Color("#4ff0ff")
	canvas.draw_circle(c, r * 0.72, Color(0.2, 0.9, 0.95, 0.18))
	canvas.draw_arc(c, r * 0.72, 0, TAU, 20, cyan, r * 0.08, true)
	for index in 4:
		var y := c.y - r * 0.4 + index * r * 0.26
		var half := sqrt(maxf(0.0, (r * 0.7) * (r * 0.7) - pow(y - c.y, 2)))
		canvas.draw_line(Vector2(c.x - half, y), Vector2(c.x + half, y), Color(cyan, 0.35), maxf(0.6, r * 0.04), true)
	canvas.draw_rect(Rect2(c + Vector2(-r * 0.42, -r * 0.16), Vector2(r * 0.28, r * 0.12)), glow)
	canvas.draw_rect(Rect2(c + Vector2(r * 0.14, -r * 0.16), Vector2(r * 0.28, r * 0.12)), glow)
	canvas.draw_line(c + Vector2(-r * 0.2, r * 0.3), c + Vector2(r * 0.2, r * 0.3), cyan, r * 0.07, true)


static func _wolf(canvas: CanvasItem, seed: int, c: Vector2, r: float) -> void:
	var fur: Color = [Color("#9aa3ad"), Color("#6d6458"), Color("#c9ccd1"), Color("#4b4e55")][seed % 4]
	for side in [-1.0, 1.0]:
		canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(side * r * 0.72, -r * 0.2), c + Vector2(side * r * 0.55, -r * 1.0), c + Vector2(side * r * 0.15, -r * 0.5)]), fur.darkened(0.2))
	canvas.draw_circle(c + Vector2(0, -r * 0.05), r * 0.66, fur)
	canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.32, r * 0.05), c + Vector2(r * 0.32, r * 0.05), c + Vector2(r * 0.14, r * 0.78), c + Vector2(-r * 0.14, r * 0.78)]), fur.lightened(0.3))
	canvas.draw_circle(c + Vector2(0, r * 0.7), r * 0.12, Color("#16161a"))
	for side in [-1.0, 1.0]:
		canvas.draw_line(c + Vector2(side * r * 0.42, -r * 0.18), c + Vector2(side * r * 0.16, -r * 0.08), Color("#f2d64b"), r * 0.12, true)
	# bone-white claw marks
	canvas.draw_line(c + Vector2(r * 0.15, -r * 0.6), c + Vector2(r * 0.42, -r * 0.3), Color(1, 1, 1, 0.8), r * 0.05, true)
	canvas.draw_line(c + Vector2(r * 0.25, -r * 0.66), c + Vector2(r * 0.52, -r * 0.36), Color(1, 1, 1, 0.8), r * 0.05, true)


static func _malphen(canvas: CanvasItem, seed: int, c: Vector2, r: float) -> void:
	var flesh := Color("#d98a8a")
	canvas.draw_circle(c, r * 0.72, flesh)
	for index in 4:
		var angle := float(seed % 7 + index * 2) * 0.9
		canvas.draw_circle(c + Vector2.from_angle(angle) * r * 0.45, r * 0.25, Color("#b8607a"))
	for index in 3:
		var at := c + Vector2.from_angle(float(seed % 5) + index * 2.1) * r * 0.3
		canvas.draw_circle(at, r * 0.12, Color("#f6e7d6"))
		canvas.draw_circle(at, r * 0.05, Color("#2a0f18"))
