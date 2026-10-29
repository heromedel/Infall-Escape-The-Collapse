## Vector icons for cards and systems, drawn with simple shapes so they stay crisp at any size.
## Every icon is drawn in a box from -1 to 1 around a centre, then scaled.
class_name IconPainter
extends RefCounted

## Which icon a system type uses.
const SYSTEM_ART := {
	"reactor": "reactor", "shields": "shield", "engines": "engines", "piloting": "piloting", "sensors": "sensors",
	"lifeSupport": "life", "medBay": "med", "airlock": "airlock", "teleport": "teleport", "cloak": "cloak",
	"mindControl": "mind", "hacking": "hack", "battery": "battery", "evb": "suit",
}


static func system_art(system: Dictionary) -> String:
	if system.type == "weapon":
		var weapons: Array = system.get("weapons", [])
		return Weapons.art(weapons[0]) if not weapons.is_empty() else "laser"
	return SYSTEM_ART.get(system.type, "reactor")


## Draws the icon with a soft glow behind it.
static func paint_glowing(canvas: CanvasItem, art: String, center: Vector2, size: float, color: Color) -> void:
	var glow := color
	glow.a = 0.13
	for i in 3:
		canvas.draw_circle(center, size * (0.55 + i * 0.18), Color(glow, glow.a * (1.0 - i * 0.3)))
	paint(canvas, art, center, size, color)


static func paint(canvas: CanvasItem, art: String, center: Vector2, size: float, color: Color) -> void:
	var s := size * 0.5
	var p := func(x: float, y: float) -> Vector2: return center + Vector2(x, y) * s
	var dark := color.darkened(0.55)
	var light := color.lightened(0.45)
	var width := maxf(1.5, s * 0.12)
	match art:
		"power", "battery_bolt":
			_polygon(canvas, p, [[0.15, -1.0], [-0.6, 0.15], [-0.05, 0.15], [-0.25, 1.0], [0.6, -0.2], [0.05, -0.2], [0.35, -1.0]], color)
			_polygon(canvas, p, [[0.15, -0.8], [-0.35, 0.05], [0.0, 0.05]], light)
		"shield":
			var outline := [[0, -0.95], [0.8, -0.65], [0.72, 0.15], [0, 0.98], [-0.72, 0.15], [-0.8, -0.65]]
			_polygon(canvas, p, outline, dark)
			_outline(canvas, p, outline, color, width)
			_polygon(canvas, p, [[0, -0.6], [0.45, -0.42], [0.4, 0.08], [0, 0.6]], color)
		"jump":
			canvas.draw_arc(center, s * 0.82, PI * 0.6, PI * 2.2, 32, color, width)
			canvas.draw_arc(center, s * 0.5, PI * 1.1, PI * 2.6, 24, color.darkened(0.2), width * 0.8)
			_polygon(canvas, p, [[0.2, -0.3], [0.95, -0.05], [0.45, 0.55]], light)
			canvas.draw_circle(center, s * 0.16, light)
		"restore", "life":
			for i in 3:
				var y := -0.55 + i * 0.5
				var points := PackedVector2Array()
				for step in 13:
					var x := -0.85 + step * (1.7 / 12.0)
					points.append(p.call(x, y + sin(step * 0.9 + i) * 0.13))
				canvas.draw_polyline(points, color if i != 1 else light, width)
			if art == "life":
				canvas.draw_arc(center, s * 0.98, 0, TAU, 40, color.darkened(0.3), width * 0.6)
		"teleport":
			for i in 3:
				canvas.draw_arc(p.call(0, 0.75 - i * 0.12), s * (0.75 - i * 0.12), PI, TAU, 24, Color(color, 0.35 + i * 0.25), width * 0.7)
			canvas.draw_circle(p.call(0, -0.45), s * 0.22, light)
			_polygon(canvas, p, [[-0.35, 0.65], [-0.25, -0.1], [0.25, -0.1], [0.35, 0.65]], color)
			for sparkle in [[-0.75, -0.6], [0.7, -0.35], [-0.6, 0.2], [0.8, 0.4]]:
				_star(canvas, p.call(sparkle[0], sparkle[1]), s * 0.13, light)
		"cloak":
			var hull := [[0, -0.95], [0.75, 0.75], [0, 0.4], [-0.75, 0.75]]
			_dashed_outline(canvas, p, hull, color, width)
			_polygon(canvas, p, [[0, -0.5], [0.35, 0.4], [0, 0.22], [-0.35, 0.4]], Color(color, 0.35))
		"mind":
			canvas.draw_circle(p.call(-0.15, 0.05), s * 0.55, dark)
			canvas.draw_arc(p.call(-0.15, 0.05), s * 0.55, 0, TAU, 32, color, width)
			for i in 3:
				canvas.draw_arc(p.call(-0.15, 0.05), s * (0.72 + i * 0.16), -0.7, 0.7, 12, Color(light, 0.9 - i * 0.25), width * 0.7)
			canvas.draw_arc(p.call(-0.3, -0.05), s * 0.18, PI * 0.2, PI * 1.6, 12, light, width * 0.6)
			canvas.draw_arc(p.call(0.0, 0.15), s * 0.16, -PI * 0.8, PI * 0.6, 12, light, width * 0.6)
		"hack":
			canvas.draw_rect(Rect2(p.call(-0.55, -0.55), Vector2(s * 1.1, s * 1.1)), dark)
			canvas.draw_rect(Rect2(p.call(-0.55, -0.55), Vector2(s * 1.1, s * 1.1)), color, false, width)
			for i in 4:
				var offset := -0.38 + i * 0.25
				canvas.draw_line(p.call(offset, -0.55), p.call(offset, -0.85), color, width * 0.7)
				canvas.draw_line(p.call(offset, 0.55), p.call(offset, 0.85), color, width * 0.7)
				canvas.draw_line(p.call(-0.55, offset), p.call(-0.85, offset), color, width * 0.7)
				canvas.draw_line(p.call(0.55, offset), p.call(0.85, offset), color, width * 0.7)
			_polygon(canvas, p, [[0.05, -0.4], [-0.25, 0.05], [0.0, 0.05], [-0.1, 0.4], [0.25, -0.08], [0.0, -0.08], [0.15, -0.4]], light)
		"battery":
			canvas.draw_rect(Rect2(p.call(-0.45, -0.7), Vector2(s * 0.9, s * 1.6)), dark)
			canvas.draw_rect(Rect2(p.call(-0.45, -0.7), Vector2(s * 0.9, s * 1.6)), color, false, width)
			canvas.draw_rect(Rect2(p.call(-0.18, -0.92), Vector2(s * 0.36, s * 0.22)), color)
			for i in 3:
				canvas.draw_rect(Rect2(p.call(-0.3, 0.45 - i * 0.42), Vector2(s * 0.6, s * 0.3)), Color(color, 0.45 + i * 0.25))
		"suit":
			canvas.draw_rect(Rect2(p.call(-0.22, -0.95), Vector2(s * 0.44, s * 0.36)), color)
			canvas.draw_rect(Rect2(p.call(-0.14, -0.85), Vector2(s * 0.28, s * 0.1)), light)
			_polygon(canvas, p, [[-0.5, -0.5], [0.5, -0.5], [0.38, 0.25], [-0.38, 0.25]], dark)
			_outline(canvas, p, [[-0.5, -0.5], [0.5, -0.5], [0.38, 0.25], [-0.38, 0.25]], color, width)
			canvas.draw_rect(Rect2(p.call(-0.82, -0.48), Vector2(s * 0.25, s * 0.75)), color)
			canvas.draw_rect(Rect2(p.call(0.57, -0.48), Vector2(s * 0.25, s * 0.75)), color)
			canvas.draw_rect(Rect2(p.call(-0.36, 0.3), Vector2(s * 0.24, s * 0.65)), color)
			canvas.draw_rect(Rect2(p.call(0.12, 0.3), Vector2(s * 0.24, s * 0.65)), color)
			canvas.draw_circle(p.call(0, -0.15), s * 0.12, light)
		"repair":
			var a: Vector2 = p.call(-0.6, 0.6)
			var b: Vector2 = p.call(0.35, -0.35)
			canvas.draw_line(a, b, color, s * 0.3)
			canvas.draw_circle(a, s * 0.17, color)
			canvas.draw_circle(b, s * 0.42, color)
			canvas.draw_circle(p.call(0.52, -0.52), s * 0.24, dark)
			canvas.draw_line(p.call(0.25, -0.25), p.call(0.7, -0.7), dark, s * 0.25)
		"extinguish":
			canvas.draw_rect(Rect2(p.call(-0.6, -0.35), Vector2(s * 0.6, s * 1.25)), color)
			canvas.draw_circle(p.call(-0.3, -0.35), s * 0.3, color)
			canvas.draw_rect(Rect2(p.call(-0.5, -0.0), Vector2(s * 0.4, s * 0.3)), light)
			canvas.draw_line(p.call(-0.3, -0.62), p.call(0.25, -0.75), color.darkened(0.2), width * 1.3)
			for drop in [[0.45, -0.85], [0.65, -0.6], [0.55, -0.35], [0.82, -0.85], [0.85, -0.45]]:
				canvas.draw_circle(p.call(drop[0], drop[1]), s * 0.08, light)
		"airlock":
			canvas.draw_circle(center, s * 0.9, dark)
			canvas.draw_arc(center, s * 0.9, 0, TAU, 40, color, width)
			canvas.draw_arc(center, s * 0.62, 0, TAU, 32, color.darkened(0.2), width * 0.8)
			for i in 6:
				var angle := i * TAU / 6.0
				canvas.draw_line(center + Vector2.from_angle(angle) * s * 0.15, center + Vector2.from_angle(angle + 0.5) * s * 0.62, light, width * 0.8)
			canvas.draw_circle(center, s * 0.15, light)
		"laser":
			for i in 3:
				var offset := (i - 1) * 0.42
				canvas.draw_line(p.call(-0.8 + offset * 0.3, 0.55 + offset), p.call(0.55 + offset * 0.3, -0.55 + offset), Color(color, 0.5), s * 0.26)
				canvas.draw_line(p.call(-0.8 + offset * 0.3, 0.55 + offset), p.call(0.55 + offset * 0.3, -0.55 + offset), light, s * 0.1)
		"heavy":
			_polygon(canvas, p, [[-0.95, 0.45], [0.55, -0.6], [0.95, -0.55], [0.75, -0.2], [-0.75, 0.75]], color)
			_polygon(canvas, p, [[-0.75, 0.48], [0.6, -0.45], [0.72, -0.4], [-0.6, 0.6]], light)
		"ion":
			canvas.draw_circle(center, s * 0.38, color)
			canvas.draw_circle(center, s * 0.2, light)
			for i in 3:
				var angle := i * PI / 3.0
				var points := PackedVector2Array()
				for step in 33:
					var t := step * TAU / 32.0
					points.append(center + Vector2(cos(t) * s * 0.92, sin(t) * s * 0.34).rotated(angle))
				canvas.draw_polyline(points, Color(color, 0.85), width * 0.6)
		"missile":
			var body := [[0.85, -0.85], [0.55, -0.15], [-0.35, 0.75], [-0.75, 0.35], [0.15, -0.55]]
			_polygon(canvas, p, body, color)
			_polygon(canvas, p, [[-0.35, 0.75], [-0.6, 0.95], [-0.5, 0.6]], color.darkened(0.2))
			_polygon(canvas, p, [[-0.75, 0.35], [-0.95, 0.6], [-0.6, 0.5]], color.darkened(0.2))
			_polygon(canvas, p, [[0.85, -0.85], [0.6, -0.35], [0.35, -0.6]], light)
			_polygon(canvas, p, [[-0.55, 0.55], [-0.95, 0.95], [-0.7, 0.7]], UiKit.FIRE)
		"beam":
			canvas.draw_line(p.call(-0.9, 0.9), p.call(0.55, -0.55), Color(color, 0.35), s * 0.45)
			canvas.draw_line(p.call(-0.9, 0.9), p.call(0.55, -0.55), color, s * 0.2)
			canvas.draw_line(p.call(-0.9, 0.9), p.call(0.55, -0.55), light, s * 0.07)
			canvas.draw_circle(p.call(0.6, -0.6), s * 0.25, light)
			for spark in [[0.95, -0.35], [0.35, -0.95], [0.9, -0.85]]:
				canvas.draw_line(p.call(0.6, -0.6), p.call(spark[0], spark[1]), light, width * 0.6)
		"spore":
			# A seed pod bursting into spores.
			canvas.draw_circle(center, s * 0.38, color)
			canvas.draw_circle(center, s * 0.2, light)
			for i in 7:
				var angle := i * TAU / 7.0 + 0.3
				canvas.draw_circle(center + Vector2.from_angle(angle) * s * (0.62 + 0.18 * (i % 2)), s * 0.1, Color(light, 0.9))
		"mind":
			# A head outline with pulse rings.
			canvas.draw_arc(center, s * 0.35, 0, TAU, 24, color, width)
			for r in [0.6, 0.85]:
				canvas.draw_arc(center, s * r, -0.9, 0.9, 12, Color(light, 0.8), width * 0.7)
				canvas.draw_arc(center, s * r, PI - 0.9, PI + 0.9, 12, Color(light, 0.8), width * 0.7)
			canvas.draw_circle(center, s * 0.12, light)
		"flak":
			for chunk in [[-0.5, 0.4], [0.1, 0.0], [0.55, -0.45], [-0.1, -0.5], [0.45, 0.45]]:
				var at: Vector2 = p.call(chunk[0], chunk[1])
				canvas.draw_rect(Rect2(at - Vector2(s, s) * 0.14, Vector2(s, s) * 0.28), color)
				canvas.draw_rect(Rect2(at - Vector2(s, s) * 0.05, Vector2(s, s) * 0.1), light)
		"chain":
			for i in 3:
				var link_center: Vector2 = p.call(-0.55 + i * 0.55, 0.45 - i * 0.45)
				canvas.draw_arc(link_center, s * 0.3, 0, TAU, 20, color if i != 1 else light, width * 1.1)
		"combat":
			# Two crossed blades.
			for direction in [-1.0, 1.0]:
				var tip: Vector2 = p.call(0.75 * direction, -0.8)
				var hilt: Vector2 = p.call(-0.45 * direction, 0.45)
				canvas.draw_line(hilt, tip, light, width * 1.4)
				var across := (tip - hilt).normalized().orthogonal() * s * 0.25
				canvas.draw_line(hilt + across, hilt - across, color, width * 1.2)
				canvas.draw_line(hilt, hilt + (hilt - tip).normalized() * s * 0.3, color, width * 1.6)
		"suit_bolt":
			canvas.draw_circle(center, s * 0.5, color)
		"reactor":
			var hexagon: Array = []
			for i in 6:
				var angle := i * TAU / 6.0 + PI / 6.0
				hexagon.append([cos(angle) * 0.9, sin(angle) * 0.9])
			_polygon(canvas, p, hexagon, dark)
			_outline(canvas, p, hexagon, color, width)
			canvas.draw_circle(center, s * 0.45, Color(color, 0.4))
			canvas.draw_circle(center, s * 0.28, light)
		"engines":
			_polygon(canvas, p, [[-0.7, -0.85], [0.7, -0.85], [0.45, 0.1], [-0.45, 0.1]], color)
			_polygon(canvas, p, [[-0.45, 0.1], [0.45, 0.1], [0.25, 0.35], [-0.25, 0.35]], dark)
			_polygon(canvas, p, [[-0.3, 0.35], [0.3, 0.35], [0.0, 1.0]], UiKit.FIRE)
			_polygon(canvas, p, [[-0.15, 0.35], [0.15, 0.35], [0.0, 0.75]], Color("#fff1b0"))
		"piloting":
			canvas.draw_arc(center, s * 0.8, 0, TAU, 36, color, width * 1.2)
			canvas.draw_circle(center, s * 0.2, color)
			for angle in [-PI / 2.0, PI / 6.0, PI * 5.0 / 6.0]:
				canvas.draw_line(center, center + Vector2.from_angle(angle) * s * 0.8, color, width)
			_polygon(canvas, p, [[0, -1.0], [0.18, -0.72], [-0.18, -0.72]], light)
		"sensors":
			canvas.draw_circle(p.call(-0.55, 0.55), s * 0.14, light)
			for i in 3:
				canvas.draw_arc(p.call(-0.55, 0.55), s * (0.45 + i * 0.4), -PI / 2.0, 0, 16, Color(color, 1.0 - i * 0.22), width)
		"med":
			canvas.draw_rect(Rect2(p.call(-0.28, -0.85), Vector2(s * 0.56, s * 1.7)), color)
			canvas.draw_rect(Rect2(p.call(-0.85, -0.28), Vector2(s * 1.7, s * 0.56)), color)
			canvas.draw_rect(Rect2(p.call(-0.14, -0.7), Vector2(s * 0.28, s * 1.4)), light)
		_:
			canvas.draw_circle(center, s * 0.6, color)


static func _polygon(canvas: CanvasItem, p: Callable, points: Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(p.call(point[0], point[1]))
	canvas.draw_colored_polygon(polygon, color)


static func _outline(canvas: CanvasItem, p: Callable, points: Array, color: Color, width: float) -> void:
	var line := PackedVector2Array()
	for point in points:
		line.append(p.call(point[0], point[1]))
	line.append(line[0])
	canvas.draw_polyline(line, color, width, true)


static func _dashed_outline(canvas: CanvasItem, p: Callable, points: Array, color: Color, width: float) -> void:
	for i in points.size():
		var a: Vector2 = p.call(points[i][0], points[i][1])
		var b: Vector2 = p.call(points[(i + 1) % points.size()][0], points[(i + 1) % points.size()][1])
		canvas.draw_dashed_line(a, b, color, width, width * 2.5)


static func _star(canvas: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	canvas.draw_line(at + Vector2(-radius, 0), at + Vector2(radius, 0), color, 1.5)
	canvas.draw_line(at + Vector2(0, -radius), at + Vector2(0, radius), color, 1.5)
