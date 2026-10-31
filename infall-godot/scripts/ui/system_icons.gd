class_name SystemIcons
extends RefCounted
## The standard system symbols, drawn as vectors so they stay sharp at any zoom and take any colour (power
## green, a race's power colour, damaged red). One function per symbol keeps each one easy to change.


static func draw(canvas: CanvasItem, icon: String, centre: Vector2, size: float, colour: Color) -> void:
	var s := size * 0.5
	var w := maxf(1.2, size * 0.11)
	match icon:
		"shields":
			for index in 3:
				var radius := s * (0.35 + 0.3 * index)
				canvas.draw_arc(centre + Vector2(0, s * 0.45), radius, PI * 1.18, PI * 1.82, 16, colour, w, true)
			canvas.draw_circle(centre + Vector2(0, s * 0.45), w * 0.9, colour)
		"engines":
			for index in 3:
				var x := centre.x - s * 0.7 + index * s * 0.55
				var top := Vector2(x, centre.y - s * 0.55)
				canvas.draw_polyline(PackedVector2Array([top, Vector2(x + s * 0.45, centre.y), Vector2(x, centre.y + s * 0.55)]), colour, w, true)
		"piloting":
			var tip := centre + Vector2(0, -s * 0.8)
			canvas.draw_colored_polygon(PackedVector2Array([tip, centre + Vector2(s * 0.7, s * 0.65), centre + Vector2(0, s * 0.25), centre + Vector2(-s * 0.7, s * 0.65)]), colour)
		"weapons":
			canvas.draw_arc(centre, s * 0.6, 0, TAU, 24, colour, w, true)
			for step in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				canvas.draw_line(centre + step * s * 0.25, centre + step * s * 0.95, colour, w, true)
			canvas.draw_circle(centre, w * 0.8, colour)
		"oxygen":
			canvas.draw_arc(centre + Vector2(-s * 0.32, s * 0.12), s * 0.42, 0, TAU, 20, colour, w, true)
			canvas.draw_arc(centre + Vector2(s * 0.4, -s * 0.38), s * 0.26, 0, TAU, 16, colour, w, true)
			canvas.draw_arc(centre + Vector2(s * 0.45, s * 0.5), s * 0.16, 0, TAU, 12, colour, w * 0.9, true)
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
