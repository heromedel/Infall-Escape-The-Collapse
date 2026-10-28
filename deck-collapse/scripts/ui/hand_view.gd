## The captain's hand: cards fanned along the bottom of the screen. Hovering a card lifts and enlarges it so its
## text is easy to read. New cards slide in from the deck; the view keeps card views by uid so they glide into place.
class_name HandView
extends Control

const CARD_SCALE := 0.86
const HOVER_SCALE := 1.22
const HOVER_LIFT := 150.0

signal card_clicked(card: Dictionary)
signal card_hovered(card: Dictionary, is_hovered: bool)

## uid -> CardView
var _views := {}
var _cards: Array = []
var _hovered_uid := -1
var _selected_uid := -1
## Where newly drawn cards start (global position of the deck).
var deck_point := Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false


## Rebuilds the hand from the battle. playable_check(card) returns "" if the card can be played now.
func show_hand(cards: Array, battle: Battle, side: int, playable_check: Callable, selected_uid: int) -> void:
	_selected_uid = selected_uid
	_cards = cards.duplicate()
	var ship := battle.ships[side]
	var keep := {}
	for card in cards:
		keep[card.uid] = true
		var view: CardView = _views.get(card.uid)
		if view == null:
			view = CardView.new()
			view.scale = Vector2.ONE * CARD_SCALE
			view.position = deck_point - global_position - CardView.BASE_SIZE / 2.0
			view.modulate.a = 0.0
			view.clicked.connect(func(v): card_clicked.emit(v.card))
			view.hovered.connect(_on_hovered)
			add_child(view)
			_views[card.uid] = view
		var definition := battle.card_definition(ship, card)
		view.setup(card, definition, _footer_for(ship, card))
		var reason: String = playable_check.call(card)
		view.playable = reason == ""
		view.dimmed = reason != "" and battle.active_side == side
		view.selected = card.uid == selected_uid
	for uid in _views.keys():
		if not keep.has(uid):
			_views[uid].queue_free()
			_views.erase(uid)
	if not keep.has(_hovered_uid):
		_hovered_uid = -1
	_arrange(cards)


## The global centre of a card in hand, for flight animations.
func card_center(uid: int) -> Vector2:
	if _views.has(uid):
		var view: CardView = _views[uid]
		return view.global_position + CardView.BASE_SIZE * view.scale / 2.0
	return global_position + size / 2.0


func view_for(uid: int) -> CardView:
	return _views.get(uid)


func _arrange(cards: Array) -> void:
	var count := cards.size()
	if count == 0:
		return
	var card_width := CardView.BASE_SIZE.x * CARD_SCALE
	var spacing := minf(card_width + 8.0, (size.x - card_width) / maxf(1.0, count - 1))
	var total := spacing * (count - 1) + card_width
	var start_x := (size.x - total) / 2.0
	for i in count:
		var card: Dictionary = cards[i]
		var view: CardView = _views[card.uid]
		var offset := i - (count - 1) / 2.0
		var hovered: bool = card.uid == _hovered_uid
		var lifted: bool = hovered or card.uid == _selected_uid
		var target_scale := HOVER_SCALE if hovered else CARD_SCALE
		var target_position := Vector2(start_x + i * spacing, 4.0 + absf(offset) * absf(offset) * 1.6)
		target_position -= CardView.BASE_SIZE * (target_scale - CARD_SCALE) / 2.0
		if lifted:
			target_position.y -= HOVER_LIFT if hovered else 34.0
		var rotation_target := 0.0 if hovered else offset * 0.028
		view.z_index = 50 if hovered else i
		view.pivot_offset = Vector2.ZERO
		var tween := view.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "position", target_position, 0.22)
		tween.tween_property(view, "scale", Vector2.ONE * target_scale, 0.18)
		tween.tween_property(view, "rotation", rotation_target, 0.22)
		tween.tween_property(view, "modulate:a", 1.0, 0.25)


func _on_hovered(view: CardView, is_hovered: bool) -> void:
	if is_hovered:
		_hovered_uid = view.card.uid
		Sounds.play("hover", -12.0)
	elif _hovered_uid == view.card.uid:
		_hovered_uid = -1
	card_hovered.emit(view.card, is_hovered)
	_arrange(_cards)


func _footer_for(ship: ShipState, card: Dictionary) -> String:
	if card.id == "weapon" or card.id == "suit":
		return ship.systems[card.system].name if ship.systems.has(card.system) else ""
	if card.id in CardLibrary.CREW_CARDS:
		return "Crew card"
	for type in Catalog.systems:
		if Catalog.systems[type].card == card.id:
			return Catalog.systems[type].name
	return ""
