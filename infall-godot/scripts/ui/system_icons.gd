class_name SystemIcons
extends RefCounted
## The standard system symbols, drawn as vectors so they stay sharp at any zoom and take any colour (power
## green, a race's power colour, damaged red). One function per symbol keeps each one easy to change.

## Shields, Engines and Life Support are the shapes agreed in the first coding version (content/systems/<id>/symbol.svg
## at the repo's root), which are drawn in a box this many units wide; here that box is the symbol's `size`.
const AGREED_BOX := 17.5


static func draw(canvas: CanvasItem, icon: String, centre: Vector2, size: float, colour: Color) -> void:
	var s := size * 0.5
	var w := maxf(0.8, size * 0.11) if size < 11.0 else maxf(1.2, size * 0.11)     # thinner on a small console bulb
	match icon:
		"shields":       # two arcs, one inside the other
			_curve(canvas, centre, size, Vector2(3, 12.1), Vector2(10, 0.9), Vector2(17, 12.1), 2.2, colour)
			_curve(canvas, centre, size, Vector2(6.15, 14.9), Vector2(10, 7.2), Vector2(13.85, 14.9), 1.8, colour)
		"engines":       # a jet from the side: cooling fins and the nozzle
			for fin in [[4.5, 2.05], [7.45, 1.1], [9.45, 1.1], [11.45, 1.1], [13.45, 2.05]]:
				canvas.draw_rect(Rect2(_agreed(centre, size, Vector2(4, fin[0])), Vector2(5, fin[1]) * size / AGREED_BOX), colour)
			canvas.draw_colored_polygon(PackedVector2Array([_agreed(centre, size, Vector2(9, 5.5)), _agreed(centre, size, Vector2(15.5, 7.8)),
					_agreed(centre, size, Vector2(15.5, 12.2)), _agreed(centre, size, Vector2(9, 14.5))]), colour)
		"piloting":
			var tip := centre + Vector2(0, -s * 0.8)
			canvas.draw_colored_polygon(PackedVector2Array([tip, centre + Vector2(s * 0.7, s * 0.65), centre + Vector2(0, s * 0.25), centre + Vector2(-s * 0.7, s * 0.65)]), colour)
		"weapons":
			canvas.draw_arc(centre, s * 0.6, 0, TAU, 24, colour, w, true)
			for step in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				canvas.draw_line(centre + step * s * 0.25, centre + step * s * 0.95, colour, w, true)
			canvas.draw_circle(centre, w * 0.8, colour)
		"oxygen":        # a fan in a ring
			canvas.draw_arc(centre, 6.3 * size / AGREED_BOX, 0, TAU, 28, colour, maxf(1.0, 1.6 * size / AGREED_BOX), true)
			for blade in [Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1)]:
				_curve(canvas, centre, size, Vector2(10, 10), Vector2(10, 10) + blade * 4.0, Vector2(10, 10) + blade * Vector2(6, 1), 2.0, colour)
		"medbay":
			var arm := s * 0.28
			canvas.draw_rect(Rect2(centre - Vector2(arm, s * 0.8), Vector2(arm * 2, s * 1.6)), colour)
			canvas.draw_rect(Rect2(centre - Vector2(s * 0.8, arm), Vector2(s * 1.6, arm * 2)), colour)
		"servicing_core":
			var arm := s * 0.22
			canvas.draw_rect(Rect2(centre - Vector2(arm, s * 0.75), Vector2(arm * 2, s * 1.5)), colour)
			canvas.draw_rect(Rect2(centre - Vector2(s * 0.75, arm), Vector2(s * 1.5, arm * 2)), colour)
			canvas.draw_arc(centre, s * 0.92, 0, TAU, 6, colour, w * 0.8, true)
		"growth_organ":
			for angle in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
				canvas.draw_circle(centre + Vector2.from_angle(angle - PI / 2) * s * 0.38, s * 0.3, colour)
			canvas.draw_circle(centre, s * 0.22, colour.darkened(0.5))
		"sensors":
			canvas.draw_arc(centre, s * 0.8, 0, TAU, 24, colour, w, true)
			canvas.draw_line(centre, centre + Vector2.from_angle(-PI / 4) * s * 0.8, colour, w, true)
			canvas.draw_circle(centre + Vector2(-s * 0.3, s * 0.25), w * 1.1, colour)
			canvas.draw_circle(centre + Vector2(s * 0.25, -s * 0.05), w * 0.9, colour)
		"doors":
			canvas.draw_rect(Rect2(centre - Vector2(s * 0.75, s * 0.75), Vector2(s * 0.62, s * 1.5)), colour, false, w)
			canvas.draw_rect(Rect2(centre + Vector2(s * 0.13, -s * 0.75), Vector2(s * 0.62, s * 1.5)), colour, false, w)
			canvas.draw_line(centre + Vector2(-s * 0.3, 0), centre + Vector2(-s * 0.3, s * 0.2), colour, w, true)
			canvas.draw_line(centre + Vector2(s * 0.3, 0), centre + Vector2(s * 0.3, s * 0.2), colour, w, true)
		"teleporter":
			canvas.draw_arc(centre + Vector2(0, s * 0.55), s * 0.75, PI, TAU, 16, colour, w, true)
			for index in 3:
				var x := centre.x + (index - 1) * s * 0.42
				canvas.draw_line(Vector2(x, centre.y + s * 0.3), Vector2(x, centre.y - s * 0.75), colour, w * 0.9, true)
		"supershield":
			var points := PackedVector2Array()
			for index in 7:
				points.append(centre + Vector2.from_angle(index * TAU / 6.0 + PI / 6.0) * s * 0.85)
			canvas.draw_polyline(points, colour, w, true)
			canvas.draw_arc(centre, s * 0.42, 0, TAU, 16, colour, w, true)
		"evb_dock":
			canvas.draw_arc(centre + Vector2(0, -s * 0.15), s * 0.5, PI, TAU, 14, colour, w, true)
			canvas.draw_rect(Rect2(centre + Vector2(-s * 0.5, -s * 0.15), Vector2(s, s * 0.45)), colour, false, w)
			canvas.draw_line(centre + Vector2(-s * 0.32, -s * 0.18), centre + Vector2(s * 0.32, -s * 0.18), colour, w * 1.3, true)
			canvas.draw_line(centre + Vector2(-s * 0.7, s * 0.75), centre + Vector2(s * 0.7, s * 0.75), colour, w, true)
		"hacking":       # a probe: an antenna dish on a stalk, with two signal arcs
			canvas.draw_line(centre + Vector2(0, s * 0.85), centre + Vector2(0, -s * 0.1), colour, w, true)
			canvas.draw_circle(centre + Vector2(0, -s * 0.25), s * 0.22, colour)
			canvas.draw_arc(centre + Vector2(0, -s * 0.25), s * 0.55, PI * 1.15, PI * 1.85, 10, colour, w, true)
			canvas.draw_arc(centre + Vector2(0, -s * 0.25), s * 0.9, PI * 1.2, PI * 1.8, 12, colour, w, true)
			canvas.draw_line(centre + Vector2(-s * 0.5, s * 0.85), centre + Vector2(s * 0.5, s * 0.85), colour, w, true)
		"mind_control":  # a head in outline with a spiral inside
			canvas.draw_arc(centre + Vector2(0, -s * 0.1), s * 0.8, PI * 0.85, PI * 2.15, 20, colour, w, true)
			canvas.draw_line(centre + Vector2(-s * 0.45, s * 0.55), centre + Vector2(-s * 0.45, s * 0.9), colour, w, true)
			canvas.draw_line(centre + Vector2(s * 0.45, s * 0.55), centre + Vector2(s * 0.45, s * 0.9), colour, w, true)
			canvas.draw_arc(centre + Vector2(0, -s * 0.1), s * 0.38, 0, PI * 1.5, 12, colour, w * 0.9, true)
			canvas.draw_circle(centre + Vector2(0, -s * 0.1), s * 0.12, colour)
		"cloaking":
			canvas.draw_arc(centre, s * 0.75, PI * 1.1, PI * 1.9, 14, colour, w, true)
			canvas.draw_arc(centre, s * 0.75, PI * 0.1, PI * 0.9, 14, colour, w, true)
			canvas.draw_circle(centre, s * 0.25, colour)
			canvas.draw_line(centre + Vector2(-s * 0.85, s * 0.85), centre + Vector2(s * 0.85, -s * 0.85), colour, w, true)
		"azc":
			canvas.draw_arc(centre, s * 0.82, 0, TAU, 28, colour, w, true)
			canvas.draw_arc(centre, s * 0.45, 0, TAU, 20, colour, w * 0.9, true)
			canvas.draw_circle(centre, s * 0.2, colour)
		_:
			canvas.draw_rect(Rect2(centre - Vector2(s, s) * 0.6, Vector2(s, s) * 1.2), colour, false, w)


## A point of an agreed symbol, given in its own 20-unit drawing, on the canvas.
static func _agreed(centre: Vector2, size: float, point: Vector2) -> Vector2:
	return centre + (point - Vector2(10, 10)) * size / AGREED_BOX


## A curved stroke of an agreed symbol: from `start` to `end`, bent toward `bend`.
static func _curve(canvas: CanvasItem, centre: Vector2, size: float, start: Vector2, bend: Vector2, end: Vector2, width: float, colour: Color) -> void:
	var points := PackedVector2Array()
	for step in 13:
		var t := step / 12.0
		points.append(_agreed(centre, size, start.lerp(bend, t).lerp(bend.lerp(end, t), t)))
	canvas.draw_polyline(points, colour, maxf(1.0, width * size / AGREED_BOX), true)
