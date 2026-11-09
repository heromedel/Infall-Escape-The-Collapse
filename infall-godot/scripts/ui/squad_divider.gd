class_name SquadDivider
extends Node2D
## The gap between the squads, drawn as a bar (GV 3I): the real space between them squeezed 1:10, with its edges
## marked and faint drifting stars, while the shots crossing it are drawn by the effects as minimap marks. The bar's
## depth follows the gap's. Its size is written out in Gatometers, 1:1 with the gap's pixels, with the time a laser
## takes to cross, and stays in the middle of the screen as the camera pans.

const REACH := 60000.0             # the edges run far past both ends of the battlefield
const STAR_TILE := 3000.0          # the drifting stars repeat every this many pixels
const STAR_COUNT := 160
const LASER_SPEED := 900.0         # pixels a second: the usual laser's speed, for the crossing time shown

var zoom: float = 1.0
var camera_x: float = 0.0          # along the bar: x with the battlefield vertical, y turned horizontal
var encounter: Encounter
var _time := 0.0
var _stars: Array = []             # [x, depth (-1 to 1), speed, size, brightness]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for index in STAR_COUNT:
		_stars.append([rng.randf() * STAR_TILE, rng.randf_range(-0.95, 0.95), rng.randf_range(10.0, 45.0), rng.randf_range(0.6, 1.6), rng.randf_range(0.2, 0.6)])


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if encounter == null:
		return
	var half := encounter.bar_half()
	var pixel := 1.0 / maxf(zoom, 0.05)   # one screen pixel in world pixels
	# A light tint: the squeezed space shows through (the background is the real one)
	draw_rect(Rect2(-REACH, -half, REACH * 2.0, half * 2.0), Color(0.02, 0.04, 0.09, 0.28))
	for y in [-half, half]:
		draw_line(Vector2(-REACH, y), Vector2(REACH, y), Color(0.55, 0.72, 1.0, 0.5), 1.6 * pixel)
		draw_line(Vector2(-REACH, y), Vector2(REACH, y), Color(0.55, 0.72, 1.0, 0.12), 6.0 * pixel)
	_draw_drift(half, pixel)
	_draw_label(pixel)


## Faint stars sliding sideways at their own pace, not the camera's: space passing between the squads.
func _draw_drift(half: float, pixel: float) -> void:
	var view_half := 1100.0 * pixel
	var first_tile := floorf((camera_x - view_half) / STAR_TILE)
	var last_tile := floorf((camera_x + view_half) / STAR_TILE)
	for tile in range(int(first_tile), int(last_tile) + 1):
		for star in _stars:
			var x: float = tile * STAR_TILE + fposmod(star[0] + _time * star[2], STAR_TILE)
			draw_circle(Vector2(x, star[1] * half), star[3] * pixel, Color(0.8, 0.88, 1.0, star[4]))


func _draw_label(pixel: float) -> void:
	var distance := "%sK Gatometers" % _thousands(roundi(encounter.gap))
	var delay := "a laser crosses in %.1f s" % encounter.crossing_seconds(LASER_SPEED)
	draw_set_transform(Vector2(camera_x, 0.0), -ShipView.view_turn, Vector2(pixel, pixel))
	var font := UiKit.font_bold()
	var width := maxf(font.get_string_size(distance, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x, font.get_string_size(delay, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
	draw_rect(Rect2(-width * 0.5 - 14, -24, width + 28, 48), Color(0.006, 0.01, 0.025, 0.75))
	UiKit.draw_text(self, Vector2(0, -2), distance, 20, Color(0.75, 0.85, 1.0, 0.9), font, HORIZONTAL_ALIGNMENT_CENTER, 0)
	UiKit.draw_text(self, Vector2(0, 18), delay, 14, Color(0.6, 0.7, 0.85, 0.75), null, HORIZONTAL_ALIGNMENT_CENTER, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _thousands(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	while text.length() > 3:
		out = "," + text.right(3) + out
		text = text.left(-3)
	return ("-" if value < 0 else "") + text + out
