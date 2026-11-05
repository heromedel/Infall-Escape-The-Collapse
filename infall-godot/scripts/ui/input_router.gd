class_name InputRouter
extends Node
## Sends each player's input to their own view (GV 4C, 4F). The keyboard and mouse belong to the first player on
## this machine; each controller is a player of its own, who joins by pressing Start (GDD 4F: drop in at any time).
## A controller's cursor is drawn in its player's colour, and its buttons become the clicks and keys the game
## already knows (GDD 14E): X selects, A selects too, and gives orders when crew are selected and it points at a
## room; B goes back, the sticks' click pauses, Menu (Start) opens the menu, View (Select) opens the players menu,
## the triggers zoom and the right stick pans.
##
## Outside a run, and over the windows every player sees, a controller has a cursor of its own over the whole
## screen: it never moves the real mouse, which is the keyboard player's.

const CURSOR_SPEED := 1100.0
const DEAD_ZONE := 0.18

var main: Node
var _screen_cursors: Dictionary = {}  # controller -> where its cursor is over the whole screen (root pixels)
var _cursor_layer := CanvasLayer.new()
var _cursor_drawer := Node2D.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection)
	_cursor_layer.layer = 60
	add_child(_cursor_layer)
	_cursor_layer.add_child(_cursor_drawer)
	_cursor_drawer.draw.connect(_draw_screen_cursors)


# --- Keyboard and mouse ---------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_pad_button(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadMotion:
		return
	if not (event is InputEventMouse or event is InputEventKey):
		return
	if _root_has_the_input():
		return
	var view := _keys_view()
	if view == null:
		# Nobody has the keyboard and mouse: a key or a click brings their player back in (GDD 4F)
		var pressed: bool = (event is InputEventKey or event is InputEventMouseButton) and event.pressed
		if pressed and main.battle != null:
			main.session.add_local_player("keys")
			get_viewport().set_input_as_handled()
		return
	var routed := event.duplicate()
	if routed is InputEventMouse:
		var releasing: bool = event is InputEventMouseButton and not event.pressed
		if not Rect2(view.display.position, view.display.size).has_point(event.position) and not releasing:
			return   # the mouse is over another player's view
		routed.position = (event.position - view.display.position) / view.view_scale
		routed.global_position = routed.position
		if routed is InputEventMouseMotion:
			routed.relative = event.relative / view.view_scale
	view.viewport.push_input(routed)
	get_viewport().set_input_as_handled()


## The title, a shared window (an event) or the console take the keyboard and mouse themselves.
func _root_has_the_input() -> bool:
	if main.battle == null or main.battle.player_views.is_empty():
		return true
	if main.console.visible:
		return true
	return main.overlays.get_children().any(func(w): return w is Control and w.visible and not w.is_queued_for_deletion())


func _keys_view() -> PlayerView:
	for player in main.session.local_players():
		if player.device == "keys":
			return main.view_of(player.id)
	return null


# --- Controllers ----------------------------------------------------------------------------------------------

func _pad_view(device: int) -> PlayerView:
	for player in main.session.local_players():
		if player.device == "pad" and player.pad == device:
			return main.view_of(player.id)
	return null


func _pad_player(device: int) -> Dictionary:
	for player in main.session.local_players():
		if player.device == "pad" and player.pad == device:
			return player
	return {}


func _process(delta: float) -> void:
	var root_input := _root_has_the_input()
	for device in Input.get_connected_joypads():
		var view := _pad_view(device)
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		var zoom := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT)
		var pan := Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))
		if view and not root_input:
			if stick.length() > DEAD_ZONE:
				view.pointer = (view.pointer + stick * stick.length() * CURSOR_SPEED * delta).clamp(Vector2.ZERO, view.view_size())
				var motion := InputEventMouseMotion.new()
				motion.position = view.pointer
				motion.global_position = view.pointer
				view.viewport.push_input(motion)
			if absf(zoom) > DEAD_ZONE:
				view.camera.target_zoom = clampf(view.camera.target_zoom * (1.0 + zoom * delta * 1.6), BattleCamera.MIN_ZOOM, BattleCamera.MAX_ZOOM)
			if pan.length() > DEAD_ZONE:
				view.camera.target_position += pan * 900.0 * delta / view.camera.zoom.x
		elif stick.length() > DEAD_ZONE and root_input:
			_move_screen_cursor(device, stick, delta)   # a controller with no player in a run does nothing until Start
	_cursor_drawer.queue_redraw()


## Outside a run, or over a shared window: the controller's own cursor over the whole screen.
func _move_screen_cursor(device: int, stick: Vector2, delta: float) -> void:
	var size := get_viewport().get_visible_rect().size
	var at: Vector2 = _screen_cursors.get(device, size * 0.5)
	at = (at + stick * stick.length() * CURSOR_SPEED * delta).clamp(Vector2.ZERO, size)
	_screen_cursors[device] = at
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	get_viewport().push_input(motion, true)


func _draw_screen_cursors() -> void:
	if not _root_has_the_input():
		return
	for device in _screen_cursors:
		var player := _pad_player(device)
		var colour := Color(player.colour) if not player.is_empty() else Color.WHITE
		var at: Vector2 = _screen_cursors[device]
		var arrow := PackedVector2Array([at, at + Vector2(0, 26), at + Vector2(7, 19), at + Vector2(13, 31), at + Vector2(18, 28), at + Vector2(12, 17), at + Vector2(21, 17)])
		_cursor_drawer.draw_colored_polygon(arrow, colour)
		var outline := arrow.duplicate()
		outline.append(at)
		_cursor_drawer.draw_polyline(outline, Color(0.05, 0.05, 0.1), 2.0, true)


func _pad_button(event: InputEventJoypadButton) -> void:
	var device := event.device
	var view := _pad_view(device)
	if event.button_index == JOY_BUTTON_START and event.pressed and view == null and main.battle != null:
		if _pad_player(device).is_empty():
			main.session.add_local_player("pad", device)   # drop in (GDD 4F)
			return
	if _root_has_the_input():
		_title_button(event)
		return
	if view == null:
		return   # a controller with no player yet: only Start (joining) does anything
	var target := view.viewport
	match event.button_index:
		JOY_BUTTON_X:
			_push_click(target, view.pointer, MOUSE_BUTTON_LEFT, event.pressed)
		JOY_BUTTON_A:
			# A selects and presses like X; it gives an order when crew are selected and it points at a room
			_push_click(target, view.pointer, MOUSE_BUTTON_RIGHT if view.would_order_here() else MOUSE_BUTTON_LEFT, event.pressed)
		JOY_BUTTON_B:
			if event.pressed:
				_push_key(target, KEY_ESCAPE)
		JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK:
			if event.pressed:
				_push_key(target, KEY_SPACE)
		JOY_BUTTON_START:
			if event.pressed:
				_push_key(target, KEY_ESCAPE)
		JOY_BUTTON_BACK:
			if event.pressed:
				_push_key(target, KEY_P)


## Outside a run, or over a shared window: the buttons press where the controller's own cursor is.
func _title_button(event: InputEventJoypadButton) -> void:
	var size := get_viewport().get_visible_rect().size
	var at: Vector2 = _screen_cursors.get(event.device, size * 0.5)
	_screen_cursors[event.device] = at
	match event.button_index:
		JOY_BUTTON_X, JOY_BUTTON_A:
			var click := InputEventMouseButton.new()
			click.position = at
			click.global_position = at
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = event.pressed
			get_viewport().push_input(click, true)
		JOY_BUTTON_B, JOY_BUTTON_START:
			if event.pressed:
				for pressed in [true, false]:
					var key := InputEventKey.new()
					key.keycode = KEY_ESCAPE
					key.pressed = pressed
					get_viewport().push_input(key, true)


func _push_click(target: SubViewport, at: Vector2, button: MouseButton, pressed: bool) -> void:
	var click := InputEventMouseButton.new()
	click.position = at
	click.global_position = at
	click.button_index = button
	click.pressed = pressed
	target.push_input(click)


func _push_key(target: SubViewport, code: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = pressed
		target.push_input(key)


## A controller unplugged drops its player out; plugged back in, Start brings them back to their place.
func _on_joy_connection(device: int, connected: bool) -> void:
	if not connected:
		var player := _pad_player(device)
		if not player.is_empty():
			main.session.remove_local_player(player.id)
