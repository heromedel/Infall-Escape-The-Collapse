class_name TitleScreen
extends Control
## The title: the galaxy with its core going wrong, the game's name, and the way into a run.

signal new_run_pressed
signal continue_pressed
signal settings_pressed
signal quit_pressed

var _time := 0.0
var _stars: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for index in 900:
		var radius := pow(rng.randf(), 0.6) * 520.0
		var arm := float(index % 3) * TAU / 3.0
		var angle := arm + radius * 0.012 + rng.randf_range(-0.35, 0.35)
		_stars.append([radius, angle, rng.randf_range(0.6, 2.2), rng.randf()])
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 12)
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	menu.position = Vector2(140, 80)
	add_child(menu)
	var title := UiKit.title_label("INFALL", 110, Color("#eef3ff"))
	menu.add_child(title)
	menu.add_child(UiKit.title_label("ESCAPE THE COLLAPSE", 30, Color("#ff9a5a")))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	menu.add_child(gap)
	if RunState.has_save():
		menu.add_child(UiKit.button("CONTINUE RUN", func(): continue_pressed.emit(), 340))
	menu.add_child(UiKit.button("NEW RUN", func(): new_run_pressed.emit(), 340))
	menu.add_child(UiKit.button("SETTINGS", func(): settings_pressed.emit(), 340))
	menu.add_child(UiKit.button("QUIT", func(): quit_pressed.emit(), 340))
	for child in menu.get_children():
		if child is Button:
			child.add_theme_font_size_override("font_size", 22)
			child.custom_minimum_size.y = 52
	var footer := UiKit.label("The Galactic Core is collapsing. Scout the way out for the last of your people.", 18, UiColours.TEXT_DIM)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = Vector2(140, -70)
	add_child(footer)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.01, 0.025))
	var centre := Vector2(size.x * 0.66, size.y * 0.52)
	for ring in 18:
		draw_circle(centre, 40.0 + ring * 26.0, Color(0.55, 0.45, 0.85, 0.012))
	for star in _stars:
		var angle: float = star[1] + _time * 0.02 * (1.0 - star[0] / 600.0)
		var point: Vector2 = centre + Vector2.from_angle(angle) * star[0] * Vector2(1.0, 0.62)
		var warm := 1.0 - clampf(star[0] / 520.0, 0.0, 1.0)
		var colour := Color(0.75 + 0.25 * warm, 0.8, 1.0 - 0.3 * warm, 0.55 + 0.45 * star[3])
		draw_circle(point, star[2], colour)
	var pulse := 0.5 + 0.5 * sin(_time * 1.3)
	draw_circle(centre, 64, Color(1.0, 0.55, 0.2, 0.08 + 0.05 * pulse))
	for ring in 5:
		draw_arc(centre, 46 + ring * 2.5, 0, TAU, 96, Color(1.0, 0.5 - ring * 0.07, 0.15, 0.7 - ring * 0.13), 2.5, true)
	draw_circle(centre, 44, Color(0, 0, 0))
