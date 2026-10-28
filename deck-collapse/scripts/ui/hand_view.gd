## The captain's hand: cards fanned between the centre and the ship. Hovering a card lifts and enlarges it so its
## text is easy to read. Hover and clicks are worked out from each card's resting slot, not from the moving card,
## so a lifted card stays lifted while the mouse is on its slot or on the lifted card itself.
## Identical cards sit together and overlap more, like a small stack.
class_name HandView
extends Control

const CARD_SCALE := 0.86
const HOVER_SCALE := 1.22
const HOVER_LIFT := 150.0
## How much of a card shows when the next card is an identical one, as a share of the card's width.
const STACK_STEP := 0.3
const GROUP_ORDER := ["power", "weapon", "defense", "tactic", "crew"]

signal card_clicked(card: Dictionary)
signal card_hovered(card: Dictionary, is_hovered: bool)

## Off while an overlay covers the hand.
var input_enabled := true
## Where newly drawn cards start (global position of the deck).
var deck_point := Vector2.ZERO

## uid -> CardView
var _views := {}
## Cards in display order.
var _cards: Array = []
## Each card's resting rectangle, in display order: { uid, rect }.
var _slots: Array = []
var _hovered_uid := -1
var _selected_uid := -1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false


## Rebuilds the hand from the battle. playable_check(card) returns "" if the card can be played now.
func show_hand(cards: Array, battle: Battle, side: int, playable_check: Callable, selected_uid: int) -> void:
	_selected_uid = selected_uid
	var ship := battle.ships[side]
	var keep := {}
	var definitions := {}
	for card in cards:
		keep[card.uid] = true
		var view: CardView = _views.get(card.uid)
		if view == null:
			view = CardView.new()
			view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			view.scale = Vector2.ONE * CARD_SCALE
			view.position = deck_point - global_position - CardView.BASE_SIZE / 2.0
			view.modulate.a = 0.0
			add_child(view)
			_views[card.uid] = view
		var definition := battle.card_definition(ship, card)
		definitions[card.uid] = definition
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
	_cards = cards.duplicate()
	_cards.sort_custom(func(a, b): return _sort_key(a, definitions[a.uid]) < _sort_key(b, definitions[b.uid]))
	_arrange()


## The global centre of a card in hand, for flight animations.
func card_center(uid: int) -> Vector2:
	if _views.has(uid):
		var view: CardView = _views[uid]
		return view.global_position + CardView.BASE_SIZE * view.scale / 2.0
	return global_position + size / 2.0


func view_for(uid: int) -> CardView:
	return _views.get(uid)


func _process(_delta: float) -> void:
	var hovered := _card_under_mouse() if input_enabled else -1
	if hovered == _hovered_uid:
		return
	var previous := _hovered_uid
	_hovered_uid = hovered
	if previous >= 0 and _views.has(previous):
		card_hovered.emit(_views[previous].card, false)
	if hovered >= 0:
		Sounds.play("hover", -12.0)
		card_hovered.emit(_views[hovered].card, true)
	_arrange()


func _input(event: InputEvent) -> void:
	if not input_enabled or not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var uid := _card_under_mouse()
		if uid >= 0:
			get_viewport().set_input_as_handled()
			card_clicked.emit(_views[uid].card)


## The card whose slot the mouse is on. A lifted card also counts its lifted area, so it doesn't drop and rise.
func _card_under_mouse() -> int:
	var mouse := get_local_mouse_position()
	if _hovered_uid >= 0:
		for slot in _slots:
			if slot.uid == _hovered_uid:
				var lifted: Rect2 = slot.rect.grow_individual(0, HOVER_LIFT + 40.0, 0, 0)
				var view: CardView = _views.get(_hovered_uid)
				if view:
					lifted = lifted.merge(Rect2(view.position, CardView.BASE_SIZE * HOVER_SCALE))
				if lifted.has_point(mouse):
					return _hovered_uid
	# Later cards lie on top, so the last slot containing the mouse wins.
	var found := -1
	for slot in _slots:
		if slot.rect.has_point(mouse):
			found = slot.uid
	return found


func _arrange() -> void:
	_slots.clear()
	var count := _cards.size()
	if count == 0:
		return
	var card_size := CardView.BASE_SIZE * CARD_SCALE
	# Step to the next card: a full card for different cards, a sliver for identical ones.
	var steps: Array[float] = []
	for i in range(1, count):
		var same := _stack_key(_cards[i]) == _stack_key(_cards[i - 1])
		steps.append(card_size.x * STACK_STEP if same else card_size.x + 8.0)
	var total_steps := 0.0
	for step in steps:
		total_steps += step
	if total_steps + card_size.x > size.x and total_steps > 0.0:
		var squeeze := (size.x - card_size.x) / total_steps
		for i in steps.size():
			steps[i] *= squeeze
		total_steps *= squeeze
	var x := (size.x - total_steps - card_size.x) / 2.0
	for i in count:
		var card: Dictionary = _cards[i]
		var view: CardView = _views[card.uid]
		var offset := (x + card_size.x / 2.0 - size.x / 2.0) / maxf(1.0, size.x / 2.0)
		var rest := Vector2(x, 4.0 + offset * offset * 14.0)
		_slots.append({"uid": card.uid, "rect": Rect2(rest, card_size)})
		var hovered: bool = card.uid == _hovered_uid
		var target_scale := HOVER_SCALE if hovered else CARD_SCALE
		var target_position := rest - CardView.BASE_SIZE * (target_scale - CARD_SCALE) / 2.0
		if hovered:
			target_position.y -= HOVER_LIFT
		elif card.uid == _selected_uid:
			target_position.y -= 34.0
		view.z_index = 60 if hovered else i
		view.pivot_offset = Vector2.ZERO
		var tween := view.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "position", target_position, 0.2)
		tween.tween_property(view, "scale", Vector2.ONE * target_scale, 0.16)
		tween.tween_property(view, "rotation", 0.0 if hovered else offset * 0.06, 0.2)
		tween.tween_property(view, "modulate:a", 1.0, 0.25)
		if i < steps.size():
			x += steps[i]


func _stack_key(card: Dictionary) -> String:
	return "%s|%s" % [card.id, card.system]


func _sort_key(card: Dictionary, definition: Dictionary) -> String:
	var group_rank := GROUP_ORDER.find(definition.get("group", "crew"))
	return "%d|%s|%s|%08d" % [group_rank, definition.get("name", ""), card.system, card.uid]


func _footer_for(ship: ShipState, card: Dictionary) -> String:
	if card.id == "weapon" or card.id == "suit":
		return ship.systems[card.system].name if ship.systems.has(card.system) else ""
	if card.id in CardLibrary.CREW_CARDS:
		return "Crew card"
	for type in Catalog.systems:
		if Catalog.systems[type].card == card.id:
			return Catalog.systems[type].name
	return ""
