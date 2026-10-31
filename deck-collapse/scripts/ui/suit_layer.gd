## Battlesuits out in space, drawn over the battle: each is a suit outline with its pilot's face, beside the system
## it is near. Suits drift smoothly when they move and bob and sway while idle. Click one of yours to pick it, then
## RECALL to call it home. Clicks anywhere else pass through to the tiles below.
class_name SuitLayer
extends Control

signal suit_clicked(side: int, index: int)
signal recall_clicked(index: int)

const MARKER := Vector2(30, 34)

var battle: Battle
## [side] -> { system id -> SystemTile }, the battle screen's tiles.
var tiles: Array = []
## The player's side, and the index of the player's suit picked to recall (-1 for none).
var player_side := 0
var selected := -1

## Where each suit is drawn now, by suit id; it eases toward its system each frame (the drift).
var _positions := {}
## Clickable areas this frame: [{ rect, side, index, recall }].
var _hit_areas: Array = []
var _time := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_time += delta
	if battle == null:
		return
	var seen := {}
	for side in 2:
		var stack := {}
		for suit in battle.ships[side].suits:
			var anchor := _anchor(side, suit, stack)
			seen[suit.id] = true
			if not _positions.has(suit.id):
				_positions[suit.id] = _launch_point(side, suit)
			_positions[suit.id] = _positions[suit.id].lerp(anchor, 1.0 - exp(-delta * 2.5))
	for id in _positions.keys():
		if not seen.has(id):
			_positions.erase(id)
	queue_redraw()


## Clicks only count over a suit or its Recall button; everywhere else they reach the tiles underneath.
func _has_point(point: Vector2) -> bool:
	return _hit_areas.any(func(area): return area.rect.has_point(point))


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	for area in _hit_areas:
		if area.rect.has_point(event.position):
			accept_event()
			if area.recall:
				recall_clicked.emit(area.index)
			else:
				suit_clicked.emit(area.side, area.index)
			return


func _draw() -> void:
	_hit_areas.clear()
	if battle == null:
		return
	for side in 2:
		var suits: Array = battle.ships[side].suits
		for index in suits.size():
			var suit: Dictionary = suits[index]
			if not _positions.has(suit.id):
				continue
			_draw_suit(side, index, suit, _positions[suit.id])


func _draw_suit(side: int, index: int, suit: Dictionary, at: Vector2) -> void:
	var seed_value := float(suit.id)
	var bob := sin(_time * 2.1 + seed_value) * 3.0
	var sway := sin(_time * 1.3 + seed_value * 0.7) * 0.14
	var center := at + Vector2(0, bob)
	var color: Color = battle.ships[side].color
	if suit.damaged:
		color = color.lerp(UiKit.DANGER, 0.6)
	var rect := Rect2(center - MARKER / 2.0, MARKER)
	_hit_areas.append({"rect": rect.grow(3), "side": side, "index": index, "recall": false})
	if side == player_side and index == selected:
		draw_circle(center, 23, Color(UiKit.ACCENT, 0.3 + 0.15 * sin(_time * 8.0)))
	draw_set_transform(center, sway, Vector2.ONE)
	# The suit: a rounded body, arms out, a small thruster glow under it.
	draw_circle(Vector2(0, MARKER.y / 2.0 + 2), 4.0 + sin(_time * 9.0 + seed_value) * 1.0, Color(UiKit.ACCENT, 0.5))
	draw_style_box(UiKit.box(color.darkened(0.6), color, 10, 2), Rect2(-MARKER / 2.0, MARKER))
	draw_line(Vector2(-15, 2), Vector2(-21, 11), color, 3.0)
	draw_line(Vector2(15, 2), Vector2(21, 11), color, 3.0)
	var pilot := battle.crew_by_id(suit.pilot)
	if not pilot.is_empty() and Settings.value("crew_portraits") == "Cat Faces":
		CrewFace.draw(self, Vector2(0, -2), pilot.name, 1.6)
	elif not pilot.is_empty():
		UiKit.draw_text_centered(self, UiKit.display_bold_font, pilot.name.left(2).to_upper(), Rect2(-MARKER / 2.0, MARKER), 11, Color.WHITE)
	if suit.damaged:
		draw_line(Vector2(-8, -10), Vector2(2, 0), UiKit.DANGER, 2.0)
		draw_line(Vector2(2, 0), Vector2(-3, 9), UiKit.DANGER, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if suit.turns_left <= 0 and not suit.recalling:
		draw_arc(center, 21, 0, TAU, 24, Color(UiKit.DANGER, 0.6 + 0.4 * sin(_time * 6.0)), 2.0, true)
	if suit.recalling:
		UiKit.draw_text_centered(self, UiKit.display_bold_font, "↩ HOME", Rect2(center + Vector2(-24, 20), Vector2(48, 14)), 10, UiKit.ACCENT)
	elif side == player_side and index == selected and battle.why_cannot_recall(side, index) == "":
		var pill := Rect2(center + Vector2(-27, 21), Vector2(54, 17))
		draw_style_box(UiKit.box(Color(UiKit.ACCENT, 0.9), UiKit.ACCENT, 8, 1), pill)
		UiKit.draw_text_centered(self, UiKit.display_bold_font, "RECALL", pill, 11, Color("#1a1220"))
		_hit_areas.append({"rect": pill.grow(2), "side": side, "index": index, "recall": true})


## Where a suit should be: beside the enemy system it is near (outside the tile's top right, stacked), or by its own
## dock for suits that stay home.
func _anchor(side: int, suit: Dictionary, stack: Dictionary) -> Vector2:
	var tile_side := 1 - side if suit.target != "" else side
	var system_id: String = suit.target if suit.target != "" else suit.dock
	var tile: SystemTile = tiles[tile_side].get(system_id)
	if tile == null:
		return Vector2.ZERO
	var key := "%d/%s" % [tile_side, system_id]
	var order: int = stack.get(key, 0)
	stack[key] = order + 1
	var rect := tile.get_global_rect()
	var local := get_global_transform().affine_inverse() * rect.position
	return local + Vector2(rect.size.x - 12, 26 + order * 40)


func _launch_point(side: int, suit: Dictionary) -> Vector2:
	var tile: SystemTile = tiles[side].get(suit.dock)
	if tile == null:
		return Vector2.ZERO
	return get_global_transform().affine_inverse() * tile.get_global_rect().get_center()
