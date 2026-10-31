class_name HullPainter
extends Node2D
## Draws a hull for a ship that has no hull art (GDD 5K), shaped around its rooms in its race's style:
## clean white GATOS shuttles, dark scorched pirates, black Mecha blades, pillowy Tentauri, moth-winged
## Azurethea, white Senti hulls with light lines, patchwork Lykario and bulbous Malphen. The shape comes from the
## floor plan, so a modded ship with no art still looks like a ship.

const STYLES := {
	"terran": {"body": Color("#e9edf2"), "shade": Color("#b9c2cd"), "trim": Color("#3b6fd8"), "outline": Color("#1b2230"), "engine": Color("#9fd2ff"), "round": true},
	"gatos": {"body": Color("#e9edf2"), "shade": Color("#b9c2cd"), "trim": Color("#3b6fd8"), "outline": Color("#1b2230"), "engine": Color("#9fd2ff"), "round": true},
	"pirate": {"body": Color("#5d636d"), "shade": Color("#41464f"), "trim": Color("#b2452a"), "outline": Color("#12151b"), "engine": Color("#ffb070"), "round": false},
	"mecha": {"body": Color("#1c1d24"), "shade": Color("#111216"), "trim": Color("#aa28eb"), "outline": Color("#050507"), "engine": Color("#c060ff"), "round": false},
	"tentauri": {"body": Color("#efe6ee"), "shade": Color("#c9e7e4"), "trim": Color("#ff8fcf"), "outline": Color("#2a3346"), "engine": Color("#8ff0e6"), "round": true},
	"azurethea": {"body": Color("#3a7fe0"), "shade": Color("#2547b8"), "trim": Color("#9fe3ff"), "outline": Color("#0e1a3a"), "engine": Color("#bfe8ff"), "round": true},
	"senti": {"body": Color("#eef1f5"), "shade": Color("#c3cbd6"), "trim": Color("#4ff0ff"), "outline": Color("#1b2230"), "engine": Color("#d2ff00"), "round": true},
	"lykario": {"body": Color("#7c766c"), "shade": Color("#5a564f"), "trim": Color("#f0ece2"), "outline": Color("#17161a"), "engine": Color("#ffd27a"), "round": false},
	"malphen": {"body": Color("#cf7f86"), "shade": Color("#a4566a"), "trim": Color("#f6e7d6"), "outline": Color("#3a1420"), "engine": Color("#ffb39a"), "round": true},
}

var design: ShipDesign
var _body := PackedVector2Array()
var _extras: Array = []           # [polygon, colour] drawn before the body (wings, pods)
var _engines: Array[Vector2] = []
var _time := 0.0


var _lights := Node2D.new()


func _ready() -> void:
	_build()
	add_child(_lights)
	_lights.draw.connect(_draw_lights)


func _process(delta: float) -> void:
	_time += delta
	_lights.queue_redraw()


func _style() -> Dictionary:
	return STYLES.get(design.style, STYLES.get(design.faction, STYLES["terran"]))


func _build() -> void:
	var style := _style()
	var floor_rect := design.floor_rect()
	var tile := ShipDesign.TILE
	var margin := 20.0
	var shape := PackedVector2Array()
	for room in design.rooms:
		var rect := Rect2(design.cell_top_left(room.rect.position), Vector2(room.rect.size) * tile).grow(margin)
		var polygon := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
		shape = polygon if shape.is_empty() else _merge(shape, polygon)
	# A nose ahead of the rooms and an engine block behind them
	var nose_length := tile * (1.6 if design.style in ["terran", "gatos", "pirate", "senti", "mecha"] else 0.8)
	var top := floor_rect.position.y - margin
	var nose := PackedVector2Array([Vector2(floor_rect.position.x + tile * 0.4, top + 4), Vector2(floor_rect.get_center().x, top - nose_length), Vector2(floor_rect.end.x - tile * 0.4, top + 4)])
	shape = _merge(shape, nose)
	var bottom := floor_rect.end.y + margin
	var engine_count := 2 if floor_rect.size.x > tile * 3.5 else 1
	for index in engine_count:
		var x := floor_rect.get_center().x + (index - (engine_count - 1) * 0.5) * tile * 1.6
		var block := Rect2(Vector2(x - tile * 0.45, bottom - 10.0), Vector2(tile * 0.9, 22.0))
		shape = _merge(shape, PackedVector2Array([block.position, Vector2(block.end.x, block.position.y), block.end, Vector2(block.position.x, block.end.y)]))
		_engines.append(Vector2(x, block.end.y + 2.0))
	# Grow then shrink the outline: round styles come out smooth, angular ones keep their corners
	var grown := Geometry2D.offset_polygon(shape, 22.0, Geometry2D.JOIN_ROUND if style.round else Geometry2D.JOIN_MITER)
	var smooth := Geometry2D.offset_polygon(_thin(grown[0]), -16.0, Geometry2D.JOIN_ROUND if style.round else Geometry2D.JOIN_MITER) if not grown.is_empty() else []
	_body = _thin(smooth[0]) if not smooth.is_empty() else shape
	_add_style_extras(floor_rect, style)


func _merge(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	var merged := Geometry2D.merge_polygons(a, b)
	var best := a
	var best_area := 0.0
	for polygon in merged:
		if Geometry2D.is_polygon_clockwise(polygon) and merged.size() > 1:
			continue   # a hole
		var area := absf(_area(polygon))
		if area > best_area:
			best_area = area
			best = polygon
	return best


func _area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for index in polygon.size():
		var a := polygon[index]
		var b := polygon[(index + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5


func _add_style_extras(floor_rect: Rect2, style: Dictionary) -> void:
	var tile := ShipDesign.TILE
	var left := floor_rect.position.x - 20.0
	var right := floor_rect.end.x + 20.0
	var mid_y := floor_rect.get_center().y
	var span := floor_rect.size.y
	match design.style:
		"terran", "gatos", "senti":
			for side in [-1.0, 1.0]:
				var root_x := right if side > 0 else left
				var wing := PackedVector2Array([Vector2(root_x - side * 6, mid_y - span * 0.05), Vector2(root_x + side * tile * 2.4, mid_y + span * 0.32), Vector2(root_x + side * tile * 2.4, mid_y + span * 0.42), Vector2(root_x - side * 6, mid_y + span * 0.36)])
				_extras.append([wing, style.shade])
		"pirate", "lykario":
			for side in [-1.0, 1.0]:
				var root_x := right if side > 0 else left
				var fin := PackedVector2Array([Vector2(root_x - side * 6, mid_y + span * 0.1), Vector2(root_x + side * tile * 1.6, mid_y + span * 0.48), Vector2(root_x - side * 4, mid_y + span * 0.4)])
				_extras.append([fin, style.shade])
		"mecha":
			for side in [-1.0, 1.0]:
				var root_x := right if side > 0 else left
				var blade := PackedVector2Array([Vector2(root_x - side * 8, mid_y - span * 0.25), Vector2(root_x + side * tile * 2.0, mid_y - span * 0.62), Vector2(root_x + side * tile * 0.9, mid_y + span * 0.05), Vector2(root_x - side * 8, mid_y + span * 0.2)])
				_extras.append([blade, style.body.lightened(0.04)])
		"tentauri":
			for side in [-1.0, 1.0]:
				var pod := PackedVector2Array()
				var centre := Vector2((right + tile * 0.6) if side > 0 else (left - tile * 0.6), mid_y + span * 0.15)
				for index in 20:
					pod.append(centre + Vector2(cos(index * TAU / 20.0) * tile * 0.7, sin(index * TAU / 20.0) * span * 0.42))
				_extras.append([pod, style.shade])
		"azurethea":
			for side in [-1.0, 1.0]:
				var root := Vector2(right if side > 0 else left, mid_y)
				var upper := PackedVector2Array()
				var lower := PackedVector2Array()
				for index in 18:
					var angle := index * TAU / 18.0
					upper.append(root + Vector2(side * tile * 1.8, -span * 0.22) + Vector2(cos(angle) * tile * 1.9, sin(angle) * span * 0.34))
					lower.append(root + Vector2(side * tile * 1.3, span * 0.28) + Vector2(cos(angle) * tile * 1.3, sin(angle) * span * 0.22))
				_extras.append([upper, style.body.lightened(0.1)])
				_extras.append([lower, style.shade])
		"malphen":
			var seed := hash(design.id)
			for index in 6:
				var angle := float(seed % 97 + index * 61) * 0.1
				var centre := floor_rect.get_center() + Vector2(cos(angle) * floor_rect.size.x * 0.55, sin(angle) * floor_rect.size.y * 0.5)
				var blob := PackedVector2Array()
				var radius := tile * (0.9 + 0.35 * (index % 3))
				for step in 16:
					var wobble := 1.0 + 0.12 * sin(step * 2.7 + index)
					blob.append(centre + Vector2.from_angle(step * TAU / 16.0) * radius * wobble)
				_extras.append([blob, style.shade])


func _draw() -> void:
	if _body.is_empty():
		return
	var style := _style()
	_fill(_offset(_body, 12.0), Color(0, 0, 0, 0.32))
	for extra in _extras:
		var polygon: PackedVector2Array = extra[0]
		_shaded_polygon(polygon, extra[1])
		_outline(polygon, style.outline, 2.5)
		var inner := _offset(polygon, -7.0)
		if not inner.is_empty():
			_outline(inner, Color(style.trim, 0.45), 1.5)
		_draw_extra_details(polygon, style)
	_shaded_polygon(_body, style.body)
	var inner_body := _offset(_body, -16.0)
	if not inner_body.is_empty():
		_shaded_polygon(inner_body, style.body.lerp(style.shade, 0.3))
		_outline(inner_body, Color(style.outline, 0.2), 1.0)
	_draw_seams(style)
	_draw_rim(style)
	_outline(_body, style.outline, 3.0)
	_draw_markings(style)
	for engine in _engines:
		draw_rect(Rect2(engine + Vector2(-11, -14), Vector2(22, 12)), style.shade.darkened(0.3))
		draw_rect(Rect2(engine + Vector2(-11, -14), Vector2(22, 12)), style.outline, false, 1.5)


## Engine glow and blinking nav lights: the only parts of a drawn hull that move.
func _draw_lights() -> void:
	var style := _style()
	_draw_nav_lights()
	for engine in _engines:
		var flicker := 0.85 + 0.15 * sin(_time * 23.0 + engine.x)
		_lights.draw_circle(engine + Vector2(0, 8), 15.0 * flicker, Color(style.engine, 0.18))
		_lights.draw_circle(engine + Vector2(0, 3), 9.0 * flicker, Color(style.engine, 0.55))
		_lights.draw_circle(engine, 4.5, Color(1, 1, 1, 0.9))


## Fills a polygon lit from the upper left: each corner is lighter or darker by where it lies.
func _shaded_polygon(polygon: PackedVector2Array, base: Color) -> void:
	if polygon.size() < 3:
		return
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	var colours := PackedColorArray()
	for point in polygon:
		var u := (point.x - bounds.position.x) / maxf(1.0, bounds.size.x)
		var v := (point.y - bounds.position.y) / maxf(1.0, bounds.size.y)
		var light := 0.18 - 0.36 * (u * 0.7 + v * 0.3)
		colours.append(base.lightened(light) if light > 0.0 else base.darkened(-light))
	var triangles := Geometry2D.triangulate_polygon(polygon)
	for index in range(0, triangles.size(), 3):
		var a := triangles[index]
		var b := triangles[index + 1]
		var c := triangles[index + 2]
		if _triangle_area(polygon[a], polygon[b], polygon[c]) < 0.5:
			continue
		draw_polygon(PackedVector2Array([polygon[a], polygon[b], polygon[c]]), PackedColorArray([colours[a], colours[b], colours[c]]))


## Fills any polygon safely: self-touching outlines from merging rooms are split into triangles first.
func _fill(polygon: PackedVector2Array, colour: Color) -> void:
	if polygon.size() < 3:
		return
	var triangles := Geometry2D.triangulate_polygon(polygon)
	for index in range(0, triangles.size(), 3):
		var a := polygon[triangles[index]]
		var b := polygon[triangles[index + 1]]
		var c := polygon[triangles[index + 2]]
		if _triangle_area(a, b, c) >= 0.5:
			draw_colored_polygon(PackedVector2Array([a, b, c]), colour)


func _triangle_area(a: Vector2, b: Vector2, c: Vector2) -> float:
	return absf((b - a).cross(c - a)) * 0.5


## Plate seams across the hull at each row of rooms, clipped to the hull.
func _draw_seams(style: Dictionary) -> void:
	var bounds := design.floor_rect().grow(60.0)
	var step := ShipDesign.TILE * 2.0
	var y := bounds.position.y + step * 0.5
	var seam := Color(style.outline, 0.22)
	while y < bounds.end.y:
		var line := PackedVector2Array([Vector2(bounds.position.x, y), Vector2(bounds.end.x, y)])
		for piece in Geometry2D.intersect_polyline_with_polygon(line, _body):
			if piece.size() >= 2:
				draw_line(piece[0], piece[piece.size() - 1], seam, 1.2)
		y += step


## A lit edge along the hull's upper-left side.
func _draw_rim(style: Dictionary) -> void:
	var inner := _offset(_body, -3.0)
	if inner.size() < 3:
		return
	var centre := Vector2.ZERO
	for point in inner:
		centre += point
	centre /= inner.size()
	for index in inner.size():
		var a := inner[index]
		var b := inner[(index + 1) % inner.size()]
		var normal := (a + b) * 0.5 - centre
		var facing := normal.normalized().dot(Vector2(-0.6, -0.8))
		if facing > 0.15:
			draw_line(a, b, Color(1, 1, 1, 0.22 * facing), 2.0, true)


func _draw_extra_details(polygon: PackedVector2Array, style: Dictionary) -> void:
	var centre := Vector2.ZERO
	for point in polygon:
		centre += point
	centre /= maxf(1, polygon.size())
	match design.style:
		"azurethea":
			for index in 3:
				var vein_end := polygon[(index * polygon.size()) / 3]
				draw_line(centre, centre.lerp(vein_end, 0.85), Color(style.trim, 0.35), 1.5, true)
			draw_circle(centre, 9.0, Color(style.trim, 0.8))
			draw_circle(centre, 5.0, style.shade.darkened(0.4))
		"malphen":
			draw_circle(centre, 6.0, Color(style.trim, 0.35))
			for index in 4:
				var vein_end := polygon[(index * polygon.size()) / 4]
				draw_line(centre, centre.lerp(vein_end, 0.7), Color("#7d3048", 0.45), 2.0, true)
		"mecha":
			for index in 3:
				var at := centre + Vector2(0, (index - 1) * 12.0)
				draw_rect(Rect2(at - Vector2(5, 1.5), Vector2(10, 3)), Color(style.trim, 0.9))


func _draw_nav_lights() -> void:
	if _body.size() < 3:
		return
	var left := _body[0]
	var right := _body[0]
	for point in _body:
		if point.x < left.x:
			left = point
		if point.x > right.x:
			right = point
	for extra in _extras:
		for point in extra[0]:
			if point.x < left.x:
				left = point
			if point.x > right.x:
				right = point
	var blink := 0.4 + 0.6 * float(int(_time * 1.2) % 2)
	_lights.draw_circle(left + Vector2(5, 0), 3.0, Color(1.0, 0.25, 0.2, blink))
	_lights.draw_circle(right + Vector2(-5, 0), 3.0, Color(0.3, 1.0, 0.4, blink))


func _draw_markings(style: Dictionary) -> void:
	var floor_rect := design.floor_rect()
	match design.style:
		"terran", "gatos":
			var y := floor_rect.position.y - 26.0
			draw_line(Vector2(floor_rect.position.x + 6, y), Vector2(floor_rect.end.x - 6, y), style.trim, 4.0)
			draw_line(Vector2(floor_rect.position.x + 6, floor_rect.end.y + 22.0), Vector2(floor_rect.end.x - 6, floor_rect.end.y + 22.0), style.trim, 3.0)
		"mecha":
			for index in 8:
				var at := Vector2(floor_rect.position.x - 14.0 if index % 2 == 0 else floor_rect.end.x + 14.0, floor_rect.position.y + (index / 2) * floor_rect.size.y / 4.0 + 12.0)
				draw_rect(Rect2(at - Vector2(2, 2), Vector2(4, 4)), style.trim)
		"senti":
			for index in 5:
				var x := floor_rect.position.x - 12.0 + index * (floor_rect.size.x + 24.0) / 4.0
				draw_line(Vector2(x, floor_rect.position.y - 18.0), Vector2(x, floor_rect.end.y + 14.0), Color(style.trim, 0.55), 1.5)
		"lykario":
			for index in 3:
				var start := Vector2(floor_rect.end.x + 4.0 - index * 7.0, floor_rect.position.y - 6.0)
				draw_line(start, start + Vector2(-16, 34), style.trim, 3.0, true)
		"pirate":
			draw_line(Vector2(floor_rect.position.x - 10.0, floor_rect.position.y + 20.0), Vector2(floor_rect.position.x - 4.0, floor_rect.end.y - 30.0), Color(style.trim, 0.8), 4.0)
		"tentauri":
			draw_circle(Vector2(floor_rect.get_center().x, floor_rect.end.y + 18.0), 9.0, Color(style.trim, 0.75))


func _offset(polygon: PackedVector2Array, amount: float) -> PackedVector2Array:
	var result := Geometry2D.offset_polygon(polygon, amount, Geometry2D.JOIN_ROUND)
	return _thin(result[0]) if not result.is_empty() else PackedVector2Array()


## Drops points closer than a few pixels to the last one kept. Round joins add a point every fraction of a pixel,
## and each offset of an offset multiplies them; a hull drawn from thousands of points stalls the fight's start.
static func _thin(polygon: PackedVector2Array, spacing: float = 3.0) -> PackedVector2Array:
	if polygon.size() < 8:
		return polygon
	var kept := PackedVector2Array([polygon[0]])
	for point in polygon:
		if point.distance_squared_to(kept[kept.size() - 1]) >= spacing * spacing:
			kept.append(point)
	return kept if kept.size() >= 3 else polygon


func _outline(polygon: PackedVector2Array, colour: Color, width: float) -> void:
	var closed := polygon.duplicate()
	closed.append(polygon[0])
	draw_polyline(closed, colour, width, true)
