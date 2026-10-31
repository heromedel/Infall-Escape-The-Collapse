class_name SquadDivider
extends Node2D
## The line across the gap between the two squads in a fight (GDD 3H: each squad's front faces the divider).
## Drawn faint and wide, so the space between the squads reads as distance, not as a wall.

var zoom: float = 1.0
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var half_width := 6000.0
	var pixel := 1.0 / maxf(zoom, 0.05)
	for band in 6:
		var height := (band + 1) * 14.0
		draw_rect(Rect2(-half_width, -height, half_width * 2.0, height * 2.0), Color(0.35, 0.55, 0.9, 0.012))
	var dash := 26.0
	var gap := 18.0
	var x := -half_width + fmod(_time * 12.0, dash + gap)
	while x < half_width:
		draw_line(Vector2(x, 0), Vector2(x + dash, 0), Color(0.55, 0.75, 1.0, 0.22), 1.5 * pixel)
		x += dash + gap
	for index in range(-40, 41):
		var at := Vector2(index * 300.0, 0)
		draw_line(at + Vector2(-8, -6), at, Color(0.55, 0.75, 1.0, 0.18), 1.2 * pixel)
		draw_line(at + Vector2(8, -6), at, Color(0.55, 0.75, 1.0, 0.18), 1.2 * pixel)
		draw_line(at + Vector2(-8, 6), at, Color(0.9, 0.5, 0.4, 0.14), 1.2 * pixel)
		draw_line(at + Vector2(8, 6), at, Color(0.9, 0.5, 0.4, 0.14), 1.2 * pixel)
