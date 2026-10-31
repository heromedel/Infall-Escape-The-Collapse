class_name MapScreen
extends Control
## The galaxy map (GDD 2C-2S): star clusters as groups of dots, the links between them, race regions, the
## collapse growing out from the core, and what the squad's sensors can read about nearby clusters (2E).
## The player picks a linked cluster and jumps, or waits.

signal jump_chosen(index: int)
signal wait_chosen
signal closed

const STATE_COLOURS := {
	"Doing Fine": Color("#cfe3ff"), "Struggling": Color("#ffd27a"), "Doomed": Color("#ff7a52"),
	"Swallowed": Color("#5a3a6e"), "Abandoned": Color("#8a8f99"), "Unclaimed": Color("#9aa6b8"),
}
const RACE_TINTS := {
	"terran": Color("#66ff66"), "mecha": Color("#aa28eb"), "tentauri": Color("#ff5eca"), "azurethea": Color("#4f8fff"),
	"senti": Color("#d2ff00"), "lykario": Color("#d1dbe7"), "malphen": Color("#ffa480"),
}

var run: RunState
var can_jump: bool = true
var camera := Vector2.ZERO
var zoom := 0.8
var hover := -1
var chosen := -1
var _dragging := false
var _time := 0.0
var _jump_button: Button
var _wait_button: Button
var _info := RichTextLabel.new()
var _backdrop_stars: Array = []


func open(run_state: RunState, jumping_allowed: bool) -> void:
	run = run_state
	can_jump = jumping_allowed
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	camera = run.cluster().position + Vector2(0, -180)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(-330, -86)
	add_child(bar)
	_jump_button = UiKit.button("JUMP  (1.21 Mawjig)", _on_jump, 260)
	_jump_button.disabled = true
	bar.add_child(_jump_button)
	_wait_button = UiKit.button("WAIT  (+0.25 Mawjig)", func(): wait_chosen.emit(), 240)
	_wait_button.tooltip_text = "Stay at this cluster: the ships gather a little Mawjig while the collapse moves on (GDD 6B)."
	_wait_button.disabled = not can_jump
	bar.add_child(_wait_button)
	bar.add_child(UiKit.button("CLOSE", func(): closed.emit(), 140))
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.custom_minimum_size = Vector2(380, 0)
	_info.position = Vector2(30, 120)
	_info.add_theme_font_size_override("normal_font_size", 18)
	_info.add_theme_font_size_override("bold_font_size", 18)
	add_child(_info)
	_update_info()
	var rng := RandomNumberGenerator.new()
	rng.seed = run.seed_value
	for index in 500:
		_backdrop_stars.append([Vector2(rng.randf(), rng.randf()), rng.randf_range(0.5, 1.6), rng.randf_range(0.2, 0.8)])


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _to_screen(point: Vector2) -> Vector2:
	return (point - camera) * zoom + size * 0.5


func _to_map(point: Vector2) -> Vector2:
	return (point - size * 0.5) / zoom + camera


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var limits := _zoom_limits()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = clampf(zoom * 1.12, limits.x, limits.y)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = clampf(zoom / 1.12, limits.x, limits.y)
		elif event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if hover >= 0 and run.can_jump_to(hover) and can_jump:
				chosen = hover
				Sfx.play("select")
				_jump_button.disabled = run.mawjig < Mawjig.JUMP_COST
				_jump_button.text = "JUMP TO %s" % run.galaxy.clusters[chosen].name.to_upper()
				if event.double_click and not _jump_button.disabled:
					_on_jump()
		_clamp_camera()
	elif event is InputEventMouseMotion:
		if _dragging:
			camera -= event.relative / zoom
			_clamp_camera()
		_update_hover(event.position)
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE, KEY_J]:
		closed.emit()


func _zoom_limits() -> Vector2:
	if Settings.get_value("map_zoom", "Clamped") == "Free":
		return Vector2(0.06, 2.0)
	return Vector2(0.5, 1.5)


func _clamp_camera() -> void:
	if Settings.get_value("map_zoom", "Clamped") == "Free":
		return
	var centre: Vector2 = run.cluster().position
	var offset := camera - centre
	if offset.length() > 1300.0:
		camera = centre + offset.normalized() * 1300.0


func _update_hover(screen_point: Vector2) -> void:
	hover = -1
	var best := 28.0
	for index in run.galaxy.clusters.size():
		var distance := _to_screen(run.galaxy.clusters[index].position).distance_to(screen_point)
		if distance < best:
			best = distance
			hover = index
	_update_info()


func _on_jump() -> void:
	if chosen >= 0:
		jump_chosen.emit(chosen)


## How far the squad's sensors read the map (GDD 2E): clusters this many links away show what they hold.
func _readable(index: int) -> bool:
	var cluster: Dictionary = run.galaxy.clusters[index]
	if cluster.visited or cluster.seen or index == run.galaxy.exit_index:
		return true
	var reach := maxi(1, run.sensor_range())
	var frontier := [run.current]
	var seen := {run.current: true}
	for step in reach:
		var next: Array = []
		for at in frontier:
			for link in run.galaxy.clusters[at].links:
				if not seen.has(link):
					seen[link] = true
					next.append(link)
		frontier = next
	return seen.has(index)


func _update_info() -> void:
	var index := hover if hover >= 0 else run.current
	var cluster: Dictionary = run.galaxy.clusters[index]
	var lines := PackedStringArray()
	lines.append("[b][font_size=26]%s[/font_size][/b]" % cluster.name)
	lines.append("[color=#a8b8cc]%s · %s[/color]" % [run.galaxy.region_name(cluster), _rank_text(cluster.rank)])
	var states: Array = cluster.states.filter(func(s): return s not in ["Core"])
	if not states.is_empty():
		lines.append(", ".join(states))
	if index == run.current:
		lines.append("[color=#66ff66]Your squad is here.[/color]")
	if index == run.galaxy.exit_index:
		lines.append("[color=#ffd46b]The rim: the last cluster before the edge of the galaxy. Someone else wants it too.[/color]")
	elif _readable(index):
		var what: String = {"store": "A store", "hostile": "Ships on sensors", "distress": "A distress signal", "hazard": "A hazard", "items": "Something drifting", "neutral": "Ship traffic", "nothing": "Nothing much", "opening": ""}.get(cluster.kind, "")
		if cluster.kind == "hazard":
			what = {"asteroids": "An asteroid field", "sun": "A star close by: flares", "nebula": "A nebula: sensors blind", "ion_storm": "An ion storm"}.get(cluster.hazard, "A hazard")
		if not what.is_empty():
			lines.append("Sensors: " + what)
		if cluster.visited:
			lines.append("[color=#a8b8cc]Visited[/color]")
	else:
		lines.append("[color=#7d8ba0]Beyond sensor range[/color]")
	if run.galaxy.collapse_radius > 0.0:
		var distance: float = cluster.radius - run.galaxy.collapse_radius
		if distance <= 0.0:
			lines.append("[color=#c86bff]Swallowed by the collapse[/color]")
		else:
			lines.append("[color=#ff9a6b]About %d jumps ahead of the collapse[/color]" % maxi(0, int(distance / Galaxy.COLLAPSE_STEP)))
	elif run.jumps < Galaxy.OPENING_JUMPS:
		lines.append("[color=#a8b8cc]Something is wrong with the Galactic Core.[/color]")
	if hover >= 0 and hover != run.current:
		if run.can_jump_to(hover):
			lines.append("[color=#66ff66]In jump range. Click to set course.[/color]")
		else:
			lines.append("[color=#7d8ba0]Not linked to your cluster.[/color]")
	_info.text = "\n".join(lines)


func _rank_text(rank: String) -> String:
	return {"core": "deep space of its region", "inner": "inner cluster", "border": "border cluster", "neutral": "between regions"}.get(rank, rank)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.012, 0.03))
	for star in _backdrop_stars:
		var point: Vector2 = star[0] * size - (camera * 0.02).posmodv(size)
		draw_circle(point.posmodv(size), star[1], Color(0.8, 0.85, 1.0, star[2]))
	var galaxy := run.galaxy
	# The core's glow and the collapse
	var core := _to_screen(Vector2.ZERO)
	for ring in 12:
		draw_circle(core, (Galaxy.CORE_RADIUS * 1.1 + ring * 70.0) * zoom, Color(0.9, 0.7, 0.45, 0.012))
	if galaxy.collapse_radius > 0.0:
		var radius := galaxy.collapse_radius * zoom
		draw_circle(core, radius, Color(0.02, 0.0, 0.04, 0.96))
		for ring in 6:
			draw_arc(core, radius + ring * 3.0, 0, TAU, 256, Color(1.0, 0.45 - ring * 0.05, 0.15, 0.55 - ring * 0.08), 3.0, true)
		draw_arc(core, radius + Galaxy.COLLAPSE_STEP * zoom, 0, TAU, 256, Color(1.0, 0.4, 0.2, 0.18 + 0.08 * sin(_time * 3.0)), 1.5, true)
	else:
		draw_circle(core, Galaxy.CORE_RADIUS * 0.6 * zoom, Color(1.0, 0.85, 0.6, 0.08 + 0.04 * clampf(run.jumps / 5.0, 0.0, 1.0)))
	# Region tints
	for cluster in galaxy.clusters:
		if cluster.race != "":
			draw_circle(_to_screen(cluster.position), 95.0 * zoom, Color(RACE_TINTS.get(cluster.race, Color.WHITE), 0.035))
	# Links
	for index in galaxy.clusters.size():
		var cluster: Dictionary = galaxy.clusters[index]
		for other in cluster.links:
			if other < index:
				continue
			var a := _to_screen(cluster.position)
			var b := _to_screen(galaxy.clusters[other].position)
			var from_here: bool = index == run.current or other == run.current
			var colour := Color(0.5, 0.65, 0.85, 0.16)
			if from_here and can_jump:
				var target: int = other if index == run.current else index
				colour = Color(0.4, 1.0, 0.45, 0.6) if run.can_jump_to(target) else Color(0.6, 0.3, 0.4, 0.4)
			if chosen >= 0 and ((index == run.current and other == chosen) or (other == run.current and index == chosen)):
				colour = Color(1.0, 0.9, 0.4, 0.95)
			draw_line(a, b, colour, 2.0 if from_here else 1.2, true)
	# Clusters
	for index in galaxy.clusters.size():
		_draw_cluster(index)
	# The squad
	var here := _to_screen(run.cluster().position)
	var bob := sin(_time * 3.0) * 3.0
	draw_colored_polygon(PackedVector2Array([here + Vector2(0, -34 + bob), here + Vector2(9, -18 + bob), here + Vector2(-9, -18 + bob)]), UiColours.POWER_GREEN)
	draw_arc(here, 22, 0, TAU, 32, Color(UiColours.POWER_GREEN, 0.8), 2.0, true)
	# Header
	UiKit.draw_text(self, Vector2(30, 60), "STAR MAP", 34, UiColours.TEXT, UiKit.font_title())
	UiKit.draw_text(self, Vector2(30, 92), "Mawjig %s   ·   jumps %d" % [Mawjig.format(run.mawjig), run.jumps], 18, UiColours.TEXT_DIM, UiKit.font_bold())
	_draw_legend()
	if not can_jump:
		UiKit.draw_text(self, Vector2(size.x * 0.5, size.y - 110), "The Jigawatt Drive isn't charged: you can look, but not jump.", 18, UiColours.WARNING, UiKit.font_bold(), HORIZONTAL_ALIGNMENT_CENTER, 0)


func _draw_cluster(index: int) -> void:
	var cluster: Dictionary = run.galaxy.clusters[index]
	var at := _to_screen(cluster.position)
	if at.x < -60 or at.y < -60 or at.x > size.x + 60 or at.y > size.y + 60:
		return
	var state: String = cluster.states[0] if not cluster.states.is_empty() else "Doing Fine"
	var colour: Color = STATE_COLOURS.get(state, Color.WHITE)
	var readable := _readable(index)
	if not readable and not cluster.visited:
		colour = colour.darkened(0.35)
	var scale := clampf(zoom, 0.6, 1.4)
	for star in cluster.stars:
		var point := at + Vector2(star[0], star[1]) * scale
		draw_circle(point, float(star[2]) * scale + 2.5, Color(colour, 0.12))
		draw_circle(point, float(star[2]) * scale * 0.7, colour)
	if index == run.galaxy.exit_index:
		var pulse := 0.5 + 0.5 * sin(_time * 2.0)
		draw_arc(at, 26 + pulse * 6, 0, TAU, 32, Color("#ffd46b"), 2.5, true)
		UiKit.draw_text(self, at + Vector2(0, 52), "THE RIM", 16, Color("#ffd46b"), UiKit.font_bold(), HORIZONTAL_ALIGNMENT_CENTER, 0)
	if index == hover:
		draw_arc(at, 22, 0, TAU, 28, Color(1, 1, 1, 0.7), 1.5, true)
	if index == chosen:
		draw_arc(at, 25, 0, TAU, 28, Color("#ffe14d"), 2.5, true)
	if cluster.visited and index != run.current:
		draw_circle(at + Vector2(14, 12), 3.0, Color(0.6, 0.7, 0.8))
	if readable and index != run.current:
		var badge := ""
		match cluster.kind:
			"store":
				badge = "$"
			"hazard":
				badge = "!"
			"distress":
				badge = "?"
		if not badge.is_empty():
			draw_circle(at + Vector2(0, -24), 10, Color(0.05, 0.08, 0.14, 0.95))
			draw_arc(at + Vector2(0, -24), 10, 0, TAU, 20, Color("#ffd46b") if badge == "$" else (UiColours.WARNING if badge == "!" else UiColours.ACCENT), 1.5, true)
			UiKit.draw_text(self, at + Vector2(0, -18), badge, 15, Color("#ffd46b") if badge == "$" else (UiColours.WARNING if badge == "!" else UiColours.ACCENT), UiKit.font_bold(), HORIZONTAL_ALIGNMENT_CENTER, 0)
	if run.galaxy.collapse_radius > 0.0 and cluster.radius - run.galaxy.collapse_radius < Galaxy.COLLAPSE_STEP and cluster.radius > run.galaxy.collapse_radius:
		draw_arc(at, 18, 0, TAU, 20, Color(1.0, 0.35, 0.2, 0.5 + 0.4 * sin(_time * 6.0)), 2.0, true)


func _draw_legend() -> void:
	var at := Vector2(size.x - 300, 40)
	UiKit.draw_frame(self, Rect2(at, Vector2(270, 196)), UiColours.PANEL, UiColours.BORDER_DIM)
	var rows := [["Doing Fine", STATE_COLOURS["Doing Fine"]], ["Struggling", STATE_COLOURS["Struggling"]], ["Doomed", STATE_COLOURS["Doomed"]], ["Abandoned or unclaimed", STATE_COLOURS["Abandoned"]], ["Swallowed", STATE_COLOURS["Swallowed"]]]
	for index in rows.size():
		var y := at.y + 30 + index * 26
		draw_circle(Vector2(at.x + 22, y - 5), 6, rows[index][1])
		UiKit.draw_text(self, Vector2(at.x + 40, y), rows[index][0], 16, UiColours.TEXT_DIM)
	UiKit.draw_text(self, Vector2(at.x + 16, at.y + 172), "$ store   ! hazard   ? distress", 15, UiColours.TEXT_DIM, UiKit.font_bold())
