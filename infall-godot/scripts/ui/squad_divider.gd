class_name SquadDivider
extends Node2D
## The barrier between the two squads (GDD 3Q, 3R): two lines across the whole battlefield with a strip of
## drifting stars between them, standing for the distance between the squads. The distance is written out in
## Gatometers with the time a shot takes to cross it, and stays in the middle of the screen as the camera pans.

const REACH := 60000.0             # the lines run far past both ends of the battlefield
const STAR_TILE := 3000.0          # the drifting stars repeat every this many pixels
const STAR_COUNT := 260

var zoom: float = 1.0
var camera_x: float = 0.0
var encounter: Encounter
var _time := 0.0
var _stars: Array = []             # [x, y, speed, size, brightness]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var half := Encounter.BARRIER_HALF_DEPTH
	for index in STAR_COUNT:
		_stars.append([rng.randf() * STAR_TILE, rng.randf_range(-half + 6.0, half - 6.0), rng.randf_range(10.0, 45.0), rng.randf_range(0.6, 1.6), rng.randf_range(0.25, 0.8)])


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var half := Encounter.BARRIER_HALF_DEPTH
	var pixel := 1.0 / maxf(zoom, 0.05)   # one screen pixel in world pixels
	draw_rect(Rect2(-REACH, -half, REACH * 2.0, half * 2.0), Color(0.006, 0.01, 0.025, 0.6))
	for y in [-half, half]:
		draw_line(Vector2(-REACH, y), Vector2(REACH, y), Color(0.55, 0.72, 1.0, 0.5), 1.6 * pixel)
		draw_line(Vector2(-REACH, y), Vector2(REACH, y), Color(0.55, 0.72, 1.0, 0.12), 6.0 * pixel)
	_draw_drift(pixel)
	_draw_label(pixel)


## Faint stars sliding sideways at their own pace, not the camera's: space passing between the squads.
func _draw_drift(pixel: float) -> void:
	var view_half := 1100.0 * pixel
	var first_tile := floorf((camera_x - view_half) / STAR_TILE)
	var last_tile := floorf((camera_x + view_half) / STAR_TILE)
	for tile in range(int(first_tile), int(last_tile) + 1):
		for star in _stars:
			var x: float = tile * STAR_TILE + fposmod(star[0] + _time * star[2], STAR_TILE)
			draw_circle(Vector2(x, star[1]), star[3] * pixel, Color(0.8, 0.88, 1.0, star[4]))


func _draw_label(pixel: float) -> void:
	if encounter == null:
		return
	var distance := "%d Gatometers" % roundi(encounter.gatometers)
	var delay := "%.1f s" % encounter.crossing_seconds("laser")
	draw_set_transform(Vector2(camera_x, 0.0), 0.0, Vector2(pixel, pixel))
	var font := UiKit.font_bold()
	var width := font.get_string_size(distance, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_rect(Rect2(-width * 0.5 - 14, -24, width + 28, 48), Color(0.006, 0.01, 0.025, 0.75))
	UiKit.draw_text(self, Vector2(0, -2), distance, 20, Color(0.75, 0.85, 1.0, 0.9), font, HORIZONTAL_ALIGNMENT_CENTER, 0)
	UiKit.draw_text(self, Vector2(0, 18), delay, 15, Color(0.6, 0.7, 0.85, 0.75), null, HORIZONTAL_ALIGNMENT_CENTER, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
