class_name HudLayout
extends RefCounted
## Where each battle HUD card sits: pinned to a corner or edge of the screen, or docked to another card's side.
## The player drags cards by their grab bar, and they snap to the screen's edges and to each other; a card
## dropped against another's side docks there and moves with it. Cards can be folded to their bar. One layout
## is shared by every ship and kept between runs (heromedel, 2026-10-31).

const PATH := "user://hud_layout.cfg"
const SNAP := 18.0                 # how close an edge must come to snap or dock
const GAP := 6.0                   # space between docked cards
const MARGIN := 16.0

# Where the cards start: the genre's places for them. `anchor` pins a card's matching corner or edge to the
# screen's, `offset` is how far in; `dock` puts it against another card's side instead.
const DEFAULTS := {
	"top": {"anchor": "top_centre", "offset": Vector2(26, 16)},
	"ship": {"anchor": "top_left", "offset": Vector2(16, 16)},
	"crew": {"dock": "ship", "side": "below"},
	"power": {"anchor": "bottom_left", "offset": Vector2(16, 16)},
	"subsystems": {"dock": "power", "side": "right"},
	"weapons": {"anchor": "bottom_centre", "offset": Vector2(120, 16)},
	"specials": {"anchor": "bottom_right", "offset": Vector2(16, 16)},
}
const ANCHORS := ["top_left", "top_centre", "top_right", "bottom_left", "bottom_centre", "bottom_right"]

var cards: Dictionary = {}         # id -> {anchor, offset} or {dock, side}, plus folded: bool
var rects: Dictionary = {}         # id -> where the card was drawn this frame
var dragging: String = ""          # the card being dragged, placed at `drag_position` until it is dropped
var drag_position := Vector2.ZERO


static func load_saved() -> HudLayout:
	var layout := HudLayout.new()
	layout.reset(false)
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		for id in DEFAULTS:
			var saved = file.get_value("cards", id, null)
			if saved is Dictionary and (saved.has("anchor") or saved.has("dock")):
				layout.cards[id] = saved
	return layout


func reset(write: bool = true) -> void:
	cards.clear()
	for id in DEFAULTS:
		cards[id] = DEFAULTS[id].duplicate()
		cards[id]["folded"] = false
	if write:
		save()


func save() -> void:
	var file := ConfigFile.new()
	for id in cards:
		file.set_value("cards", id, cards[id])
	file.save(PATH)


func is_folded(id: String) -> bool:
	return bool(cards.get(id, {}).get("folded", false))


func set_folded(id: String, folded: bool) -> void:
	cards[id]["folded"] = folded
	save()


## The card a card is docked to, if any.
func host_of(id: String) -> String:
	return String(cards.get(id, {}).get("dock", ""))


## Where a card of `card_size` goes on a screen of `screen_size`. A docked card's host must be placed first.
func place(id: String, card_size: Vector2, screen_size: Vector2) -> Vector2:
	if id == dragging:
		return drag_position
	var card: Dictionary = cards[id]
	var host := host_of(id)
	if host != "" and rects.has(host):
		var host_rect: Rect2 = rects[host]
		return host_rect.position + (Vector2(host_rect.size.x + GAP, 0) if card.side == "right" else Vector2(0, host_rect.size.y + GAP))
	var anchor := String(card.get("anchor", "top_left"))
	var offset: Vector2 = card.get("offset", Vector2(MARGIN, MARGIN))
	var at := offset
	if anchor.ends_with("right"):
		at.x = screen_size.x - offset.x - card_size.x
	elif anchor.ends_with("centre"):
		at.x = screen_size.x * 0.5 - card_size.x * 0.5 + offset.x
	if anchor.begins_with("bottom"):
		at.y = screen_size.y - offset.y - card_size.y
	return at


## Moves a dragged card, snapping its edges to the screen's and to other cards'.
func drag_to(id: String, top_left: Vector2, screen_size: Vector2) -> void:
	var size: Vector2 = rects[id].size if rects.has(id) else Vector2(100, 40)
	var at := top_left
	var xs := [MARGIN, screen_size.x - MARGIN - size.x]
	var ys := [MARGIN, screen_size.y - MARGIN - size.y]
	for other in rects:
		if other == id:
			continue
		var r: Rect2 = rects[other]
		xs.append_array([r.position.x, r.end.x + GAP, r.position.x - GAP - size.x, r.end.x - size.x])
		ys.append_array([r.position.y, r.end.y + GAP, r.position.y - GAP - size.y, r.end.y - size.y])
	at.x = _snap(at.x, xs)
	at.y = _snap(at.y, ys)
	at.x = clampf(at.x, 0.0, maxf(0.0, screen_size.x - size.x))
	at.y = clampf(at.y, 0.0, maxf(0.0, screen_size.y - size.y))
	dragging = id
	drag_position = at


## Ends a drag: the card docks to a card whose side it was dropped against, or is pinned to the nearest corner
## or edge of the screen.
func drop(id: String, screen_size: Vector2) -> void:
	if dragging != id:
		return
	dragging = ""
	var size: Vector2 = rects[id].size if rects.has(id) else Vector2(100, 40)
	var rect := Rect2(drag_position, size)
	var folded := is_folded(id)
	for other in rects:
		if other == id or _docks_to(other, id):
			continue
		var r: Rect2 = rects[other]
		if absf(rect.position.x - (r.end.x + GAP)) < SNAP and absf(rect.position.y - r.position.y) < SNAP:
			cards[id] = {"dock": other, "side": "right", "folded": folded}
			save()
			return
		if absf(rect.position.y - (r.end.y + GAP)) < SNAP and absf(rect.position.x - r.position.x) < SNAP:
			cards[id] = {"dock": other, "side": "below", "folded": folded}
			save()
			return
	var centre := rect.get_center()
	var horizontal := "left" if centre.x < screen_size.x / 3.0 else ("right" if centre.x > screen_size.x * 2.0 / 3.0 else "centre")
	var vertical := "top" if centre.y < screen_size.y * 0.5 else "bottom"
	var offset := rect.position
	if horizontal == "right":
		offset.x = screen_size.x - rect.end.x
	elif horizontal == "centre":
		offset.x = rect.get_center().x - screen_size.x * 0.5
	if vertical == "bottom":
		offset.y = screen_size.y - rect.end.y
	cards[id] = {"anchor": "%s_%s" % [vertical, horizontal], "offset": offset, "folded": folded}
	save()


## Whether `id` is docked to `other`, directly or through other cards (so docking can't loop).
func _docks_to(id: String, other: String) -> bool:
	var host := host_of(id)
	var steps := 0
	while host != "" and steps < 10:
		if host == other:
			return true
		host = host_of(host)
		steps += 1
	return false


static func _snap(value: float, targets: Array) -> float:
	for target in targets:
		if absf(value - target) < SNAP:
			return target
	return value
