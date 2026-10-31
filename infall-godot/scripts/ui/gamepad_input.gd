class_name GamepadInput
extends Node
## Controller play (GDD 14E, Xbox names with PlayStation in brackets): the left stick moves a cursor; X (Square)
## selects, A (Cross) gives orders and confirms, B (Circle) goes back or cancels; RT (R2) zooms in, LT (L2) out;
## the right stick pans; clicking either stick pauses; Menu (Start) opens the menu. Buttons become the same
## mouse and key presses the rest of the game already understands, so nothing else needs to know about pads.

const CURSOR_SPEED := 1100.0
const DEAD_ZONE := 0.18

var _cursor := Vector2(960, 540)
var _using_pad := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if Input.get_connected_joypads().is_empty():
		return
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if stick.length() > DEAD_ZONE:
		if not _using_pad:
			_cursor = get_viewport().get_mouse_position()
			_using_pad = true
		_cursor += stick * stick.length() * CURSOR_SPEED * delta
		var bounds := get_viewport().get_visible_rect().size
		_cursor = _cursor.clamp(Vector2.ZERO, bounds)
		var window_point: Vector2 = get_viewport().get_final_transform() * _cursor
		Input.warp_mouse(window_point)
		var motion := InputEventMouseMotion.new()
		motion.position = window_point
		motion.global_position = window_point
		Input.parse_input_event(motion)
	var zoom := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	var pan := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	var battle := _battle()
	if battle and battle.camera:
		if absf(zoom) > DEAD_ZONE:
			battle.camera.target_zoom = clampf(battle.camera.target_zoom * (1.0 + zoom * delta * 1.6), BattleCamera.MIN_ZOOM, BattleCamera.MAX_ZOOM)
		if pan.length() > DEAD_ZONE:
			battle.camera.target_position += pan * 900.0 * delta / battle.camera.zoom.x


func _input(event: InputEvent) -> void:
	if not event is InputEventJoypadButton:
		return
	var button := event as InputEventJoypadButton
	match button.button_index:
		JOY_BUTTON_X:
			_click(MOUSE_BUTTON_LEFT, button.pressed)
		JOY_BUTTON_A:
			_click(MOUSE_BUTTON_RIGHT if _battle() and not _menu_open() else MOUSE_BUTTON_LEFT, button.pressed)
		JOY_BUTTON_B:
			if button.pressed:
				_key(KEY_ESCAPE if _battle() and _battle().aim_mode != "" else KEY_ESCAPE)
		JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK:
			if button.pressed:
				_key(KEY_SPACE)
		JOY_BUTTON_START:
			if button.pressed:
				_key(KEY_ESCAPE)
		JOY_BUTTON_BACK:
			if button.pressed:
				_key(KEY_J)


func _battle() -> BattleScreen:
	var main := get_parent()
	return main.battle if main and "battle" in main else null


func _menu_open() -> bool:
	var main := get_parent()
	return main != null and "overlays" in main and main.overlays.get_child_count() > 0


func _click(button_index: int, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	var window_point: Vector2 = get_viewport().get_final_transform() * _cursor if _using_pad else get_viewport().get_final_transform() * get_viewport().get_mouse_position()
	event.position = window_point
	event.global_position = window_point
	event.button_index = button_index
	event.pressed = pressed
	Input.parse_input_event(event)


func _key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
