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
	"Swallowed": Color("#050507"), "Abandoned": Color("#8a8f99"), "Unclaimed": Color("#9aa6b8"),
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
var _overview: ImageTexture = null
static var _region_glow: ImageTexture = null   # race regions as soft blobs, built once per galaxy
static var _region_glow_seed: int = -1


func open(run_state: RunState, jumping_allowed: bool) -> void:
	run = run_state
	can_jump = jumping_allowed
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	camera = run.cluster().position + run.cluster().position.normalized() * 180.0   # a little toward the rim
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(-330, -86)
	add_child(bar)
	_jump_button = UiKit.button("JUMP  (1.21 Mawjig)", _on_jump, 260)
	_jump_button.disabled = true
	bar.add_child(_jump_button)
	_wait_button = UiKit.button("WAIT  (+0.25 Mawjig)", func(): wait_chosen.emit(), 240)
	_wait_button.tooltip_text = "Stay at this cluster: the ships gather a little Mawjig while the collapse moves on."
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
	var near := _to_map(screen_point)
	var reach := best / zoom
	for index in run.galaxy.clusters.size():
		var position: Vector2 = run.galaxy.clusters[index].position
		if absf(position.x - near.x) > reach or absf(position.y - near.y) > reach:
			continue
		var distance := _to_screen(position).distance_to(screen_point)
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
	if cluster.visited or cluster.seen or run.galaxy.is_rim(index):
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
	if run.galaxy.is_rim(index):
		lines.append("[color=#ffd46b]The rim: the edge of the galaxy, and the way out. Someone else wants out too.[/color]")
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
	# The rim: reach it anywhere to escape
	var rim := galaxy.rim_radius() * zoom
	draw_arc(core, rim, 0, TAU, 512, Color("#ffd46b", 0.35), 2.0, true)
	draw_arc(core, galaxy.outer_radius() * zoom, 0, TAU, 512, Color("#ffd46b", 0.12), 1.0, true)
	var view := Rect2(Vector2(-200, -200), size + Vector2(400, 400))
	# Race regions: one faint wash of colour per region, under the clusters
	if _region_glow == null or _region_glow_seed != galaxy.seed_value:
		_region_glow = _render_regions(galaxy)
		_region_glow_seed = galaxy.seed_value
	var outer := galaxy.outer_radius()
	draw_texture_rect(_region_glow, Rect2(_to_screen(Vector2(-outer, -outer)), Vector2(outer, outer) * 2.0 * zoom), false, Color(1, 1, 1, 0.11))
	# Links
	for index in galaxy.clusters.size():
		var cluster: Dictionary = galaxy.clusters[index]
		var a := _to_screen(cluster.position)
		for other in cluster.links:
			if other < index:
				continue
			var b := _to_screen(galaxy.clusters[other].position)
			if not view.intersects(Rect2(a, Vector2.ZERO).expand(b)):
				continue
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
	_draw_overview()
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
	var scale := clampf(zoom * 1.25, 0.8, 1.6)
	var swallowed := state == "Swallowed"
	for star in cluster.stars:
		var point := at + Vector2(star[0], star[1]) * scale
		if swallowed:
			draw_circle(point, float(star[2]) * scale * 0.7 + 1.2, Color(0.45, 0.45, 0.5, 0.7))
		else:
			draw_circle(point, float(star[2]) * scale + 2.5, Color(colour, 0.12))
		draw_circle(point, float(star[2]) * scale * 0.7, colour)
	if run.galaxy.is_rim(index):
		var pulse := 0.5 + 0.5 * sin(_time * 2.0)
		draw_arc(at, 22 + pulse * 4, 0, TAU, 32, Color("#ffd46b", 0.8), 2.0, true)
	if index == hover:
		draw_arc(at, 22, 0, TAU, 28, Color(1, 1, 1, 0.7), 1.5, true)
		UiKit.draw_text(self, at + Vector2(0, 40), cluster.name, 15, Color(1, 1, 1, 0.85), UiKit.font_bold(), HORIZONTAL_ALIGNMENT_CENTER, 0)
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


const REGION_PIXEL := 24.0   # map units per pixel of the region wash


static func _render_regions(galaxy: Galaxy) -> ImageTexture:
	var outer := galaxy.outer_radius()
	var pixels := int(outer * 2.0 / REGION_PIXEL)
	var image := Image.create(pixels, pixels, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var reach := int(115.0 / REGION_PIXEL)
	for cluster in galaxy.clusters:
		if cluster.race == "":
			continue
		var colour: Color = RACE_TINTS.get(cluster.race, Color.WHITE)
		var centre: Vector2 = (cluster.position + Vector2(outer, outer)) / REGION_PIXEL
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				if dx * dx + dy * dy > reach * reach:
					continue
				var x := int(centre.x) + dx
				var y := int(centre.y) + dy
				if x >= 0 and y >= 0 and x < pixels and y < pixels:
					image.set_pixel(x, y, colour)
	return ImageTexture.create_from_image(image)


## The whole galaxy in a corner: its arms and regions, the collapse, the rim, the squad, and the part of the map
## on screen.
func _draw_overview() -> void:
	const SIDE := 230.0
	var galaxy := run.galaxy
	var centre := Vector2(size.x - 30 - SIDE * 0.5, size.y - 120 - SIDE * 0.5)
	var scale := SIDE * 0.5 / galaxy.outer_radius()
	draw_circle(centre, SIDE * 0.5 + 8, Color(0.02, 0.03, 0.06, 0.92))
	draw_arc(centre, SIDE * 0.5 + 8, 0, TAU, 64, UiColours.BORDER_DIM, 1.5, true)
	if _overview == null:
		_overview = _render_overview(SIDE)
	draw_texture(_overview, centre - Vector2(SIDE, SIDE) * 0.5)
	draw_circle(centre, Galaxy.CORE_RADIUS * scale, Color(1.0, 0.85, 0.6, 0.5))
	if galaxy.collapse_radius > 0.0:
		draw_circle(centre, galaxy.collapse_radius * scale, Color(0.05, 0.0, 0.08))
		draw_arc(centre, galaxy.collapse_radius * scale, 0, TAU, 64, Color(1.0, 0.45, 0.15, 0.9), 1.5, true)
	draw_arc(centre, galaxy.rim_radius() * scale, 0, TAU, 96, Color("#ffd46b", 0.5), 1.0, true)
	var on_screen := Rect2(centre + (_to_map(Vector2.ZERO)) * scale, size / zoom * scale)
	draw_rect(on_screen, Color(1, 1, 1, 0.5), false, 1.0)
	var here: Vector2 = centre + run.cluster().position * scale
	draw_circle(here, 3.5, UiColours.POWER_GREEN)
	draw_arc(here, 6.0 + sin(_time * 4.0), 0, TAU, 16, Color(UiColours.POWER_GREEN, 0.7), 1.2, true)
	UiKit.draw_text(self, centre + Vector2(0, SIDE * 0.5 + 30), "THE GALAXY", 14, UiColours.TEXT_DIM, UiKit.font_bold(), HORIZONTAL_ALIGNMENT_CENTER, 0)


func _render_overview(side: float) -> ImageTexture:
	var galaxy := run.galaxy
	var pixels := int(side)
	var image := Image.create(pixels, pixels, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var scale := side * 0.5 / galaxy.outer_radius()
	# The glow of the disc: brighter along the spiral arms and toward the core
	for y in pixels:
		for x in pixels:
			var point := (Vector2(x, y) + Vector2(0.5, 0.5) - Vector2(side, side) * 0.5) / scale
			var radius := point.length()
			if radius > galaxy.outer_radius():
				continue
			var arm := (Galaxy.arm_density(point) - 0.5) * 2.0
			var bulge := exp(-pow(radius / 2600.0, 2.0))
			var fade := clampf((galaxy.outer_radius() - radius) / 900.0, 0.0, 1.0)
			var glow := Color(0.5, 0.58, 0.85) * (0.05 + 0.2 * arm) * fade + Color(1.0, 0.82, 0.55) * bulge * 0.45
			image.set_pixel(x, y, Color(glow.r, glow.g, glow.b, 1.0))
	for cluster in galaxy.clusters:
		var point: Vector2 = cluster.position * scale + Vector2(side, side) * 0.5
		var colour: Color = RACE_TINTS.get(cluster.race, Color(0.75, 0.8, 0.9))
		colour.a = 0.5 if cluster.race != "" else 0.3
		var x := clampi(int(point.x), 0, pixels - 1)
		var y := clampi(int(point.y), 0, pixels - 1)
		var under := image.get_pixel(x, y)
		image.set_pixel(x, y, under.blend(colour))
	return ImageTexture.create_from_image(image)


func _draw_legend() -> void:
	var races := []
	for race_id in RACE_TINTS:
		if Library.race(race_id):
			races.append(race_id)
	var rows := [["Doing Fine", STATE_COLOURS["Doing Fine"]], ["Struggling", STATE_COLOURS["Struggling"]], ["Doomed", STATE_COLOURS["Doomed"]], ["Abandoned or unclaimed", STATE_COLOURS["Abandoned"]], ["Swallowed", STATE_COLOURS["Swallowed"]]]
	var height := 40.0 + rows.size() * 26 + 34 + 30 + races.size() * 22 + 14
	var at := Vector2(size.x - 300, 40)
	UiKit.draw_frame(self, Rect2(at, Vector2(270, height)), UiColours.PANEL, UiColours.BORDER_DIM)
	UiKit.draw_text(self, Vector2(at.x + 16, at.y + 26), "CLUSTERS", 13, UiColours.TEXT_DIM, UiKit.font_bold())
	var y := at.y + 52
	for row in rows:
		_draw_cluster_icon(Vector2(at.x + 26, y - 6), row[1], row[0] == "Swallowed")
		UiKit.draw_text(self, Vector2(at.x + 46, y), row[0], 16, UiColours.TEXT_DIM)
		y += 26
	UiKit.draw_text(self, Vector2(at.x + 16, y + 2), "$ store   ! hazard   ? distress", 15, UiColours.TEXT_DIM, UiKit.font_bold())
	y += 34
	UiKit.draw_text(self, Vector2(at.x + 16, y), "REGIONS", 13, UiColours.TEXT_DIM, UiKit.font_bold())
	y += 24
	for race_id in races:
		draw_circle(Vector2(at.x + 26, y - 5), 8.0, Color(RACE_TINTS[race_id], 0.35))
		UiKit.draw_text(self, Vector2(at.x + 46, y), "%s space" % Library.race(race_id).name, 15, UiColours.TEXT_DIM)
		y += 22


## A small three-star cluster, as the map draws them.
func _draw_cluster_icon(centre: Vector2, colour: Color, swallowed: bool) -> void:
	for offset in [Vector2(-5, 2), Vector2(4, -3), Vector2(2, 5)]:
		if swallowed:
			draw_circle(centre + offset, 3.2, Color(0.45, 0.45, 0.5, 0.8))
		else:
			draw_circle(centre + offset, 4.2, Color(colour, 0.15))
		draw_circle(centre + offset, 2.2, colour)
