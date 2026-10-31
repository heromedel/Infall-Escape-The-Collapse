class_name BattleCamera
extends Camera2D
## The battle camera pans and zooms (GDD 3C): ships keep their size; zoomed out both squads show as an
## overview, zoomed in the rooms are worked. It eases toward where it is told to look, so it never jumps.

const MIN_ZOOM := 0.22
const MAX_ZOOM := 1.6

var target_position := Vector2.ZERO
var target_zoom := 0.6
var _dragging := false
var user_moved := false            # the player moved the camera; stop framing the fight by itself


func _ready() -> void:
	zoom = Vector2.ONE * target_zoom
	position_smoothing_enabled = false


func _process(delta: float) -> void:
	var blend := 1.0 - pow(0.0015, delta)
	var new_zoom := lerpf(zoom.x, target_zoom, blend)
	zoom = Vector2.ONE * new_zoom
	position = position.lerp(target_position, blend)
	var pan := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if pan != Vector2.ZERO:
		target_position += pan * 900.0 * delta / zoom.x
		user_moved = true


## Frames a world rectangle in the area of the screen between the HUD bands.
func frame(rect: Rect2, view_size: Vector2, margin_top: float = 70.0, margin_bottom: float = 150.0) -> void:
	var usable := Vector2(view_size.x - 120.0, view_size.y - margin_top - margin_bottom)
	var fit := minf(usable.x / maxf(rect.size.x, 1.0), usable.y / maxf(rect.size.y, 1.0))
	target_zoom = clampf(fit, MIN_ZOOM, MAX_ZOOM)
	var screen_shift := Vector2(0, (margin_bottom - margin_top) * 0.5) / target_zoom
	target_position = rect.get_center() + screen_shift
	user_moved = false


func zoom_at(screen_point: Vector2, factor: float, view_size: Vector2) -> void:
	var before := screen_to_world(screen_point, view_size, target_zoom, target_position)
	target_zoom = clampf(target_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	var after := screen_to_world(screen_point, view_size, target_zoom, target_position)
	target_position += before - after
	user_moved = true


func screen_to_world(screen_point: Vector2, view_size: Vector2, at_zoom: float, at_position: Vector2) -> Vector2:
	return at_position + (screen_point - view_size * 0.5) / at_zoom


func handle_drag(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = event.pressed
		return true
	if event is InputEventMouseMotion and _dragging:
		target_position -= event.relative / zoom.x
		position = target_position
		user_moved = true
		return true
	return false
