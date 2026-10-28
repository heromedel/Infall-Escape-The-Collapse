## A ship's status bar on the battle screen: name, hull, shield layers, evasion, power row and card counts.
## Hull and shields can be held at "shown" values while animations play, so numbers drop when the shot lands.
class_name ShipHeader
extends Control

const HEIGHT := 70.0

var battle: Battle
var ship_side := 0
var viewer_side := 0
## While animating, the hull and layer counts the player sees. -1 means "use the battle's value".
var shown_hull := -1
var shown_layers := -1
var hull_flash := 0.0
var shield_flash := 0.0
var _time := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	hull_flash = maxf(0.0, hull_flash - delta * 2.0)
	shield_flash = maxf(0.0, shield_flash - delta * 2.0)
	queue_redraw()


## Where the shield bubble icons sit, for shield-hit effects.
func shield_point() -> Vector2:
	return global_position + Vector2(size.x * 0.5, HEIGHT * 0.5)


func _draw() -> void:
	if battle == null:
		return
	var ship := battle.ships[ship_side]
	var mine := ship_side == viewer_side
	var view := battle.sensor_view(viewer_side)
	var rect := Rect2(Vector2.ZERO, Vector2(size.x, HEIGHT))
	draw_style_box(UiKit.box(Color("#0e1322"), ship.color.darkened(0.55), 10, 1), rect)
	draw_rect(Rect2(0, 8, 4, HEIGHT - 16), ship.color)
	var active := battle.active_side == ship_side and not battle.over
	if active:
		draw_style_box(UiKit.box(Color(0, 0, 0, 0), Color(ship.color, 0.4 + 0.25 * sin(_time * 3.0)), 10, 2), rect)

	# Name and faction
	draw_string(UiKit.display_bold_font, Vector2(18, 30), ship.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 250, 22, UiKit.TEXT)
	var subtitle := "%s · %s" % [ship.design.faction, "your ship" if mine else "enemy ship"]
	draw_string(UiKit.body_font, Vector2(18, 52), subtitle, HORIZONTAL_ALIGNMENT_LEFT, 250, 13, ship.color.lightened(0.2))

	# Hull bar: one segment per hull point, grouped so 30 hull still reads at a glance.
	var hull := shown_hull if shown_hull >= 0 else ship.hull
	var bar := Rect2(280, 12, minf(430, size.x * 0.3), 20)
	var segment_width := bar.size.x / ship.hull_max
	for i in ship.hull_max:
		var segment := Rect2(bar.position.x + i * segment_width, bar.position.y, maxf(1.0, segment_width - 1.5), bar.size.y)
		var filled := i < hull
		var color := UiKit.GOOD if float(hull) / ship.hull_max > 0.5 else (UiKit.ACCENT if float(hull) / ship.hull_max > 0.25 else UiKit.DANGER)
		draw_rect(segment, color if filled else Color("#2a1418"))
	if hull_flash > 0.0:
		draw_rect(bar.grow(3), Color(UiKit.DANGER, hull_flash * 0.5), false, 3.0)
	draw_string(UiKit.display_bold_font, Vector2(bar.position.x, bar.end.y + 22), "HULL %d / %d" % [hull, ship.hull_max],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.TEXT)

	# Shields
	var layers := shown_layers if shown_layers >= 0 else ship.shield_layers.size()
	var shield_x := bar.position.x + 150
	var capacity := ship.shield_capacity()
	for i in maxi(capacity, layers):
		var center := Vector2(shield_x + i * 26, bar.end.y + 16)
		var up := i < layers
		_draw_hexagon(center, 10, Color(UiKit.SHIELD, 0.85 if up else 0.08), UiKit.SHIELD if up else Color(UiKit.SHIELD, 0.35))
	if shield_flash > 0.0:
		draw_circle(Vector2(shield_x + 10, bar.end.y + 16), 18 + (1.0 - shield_flash) * 14, Color(UiKit.SHIELD, shield_flash * 0.4))

	# Evasion, cloak, suits, missiles
	var info_x := bar.end.x + 24
	var evasion := battle.evasion(ship)
	draw_string(UiKit.display_font, Vector2(info_x, 28), "EVASION %d%%" % evasion, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiKit.TEXT)
	var tags: Array[String] = []
	if ship.cloaked:
		tags.append("CLOAKED")
	if ship.burns > 0:
		tags.append("BURN +%d%%" % (ship.burns * Battle.BURN_EVASION))
	if ship.jump_charge > 0:
		tags.append("JUMP %d/%d" % [ship.jump_charge, Battle.JUMP_CHARGES_NEEDED])
	if not ship.suits.is_empty():
		tags.append("%d SUIT%s OUT" % [ship.suits.size(), "" if ship.suits.size() == 1 else "S"])
	if ship.weapon_systems().any(func(id): return Catalog.weapon_kind(ship.systems[id].kind).uses_missile):
		tags.append("%d MISSILES" % ship.missiles)
	draw_string(UiKit.body_font, Vector2(info_x, 52), "  ·  ".join(tags), HORIZONTAL_ALIGNMENT_LEFT, 360, 13, UiKit.ACCENT)

	# Power row (hidden for the enemy without level 2 sensors)
	var power_x := size.x - 360.0
	draw_string(UiKit.display_font, Vector2(power_x, 22), "POWER", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.MUTED)
	if mine or view.power:
		var online := ship.online_power_cards()
		for i in ship.power_row.size():
			var entry: Dictionary = ship.power_row[i]
			var cell := Rect2(power_x + i * 19, 30, 15, 26)
			var color := Color("#ffc247")
			var fill := color
			if i >= online:
				fill = Color(UiKit.DANGER, 0.25)
				color = UiKit.DANGER
			elif entry.held:
				fill = Color(UiKit.HELD, 0.55)
				color = UiKit.HELD
			elif entry.flipped:
				fill = Color(color, 0.12)
			draw_rect(cell, fill)
			draw_rect(cell, color, false, 1.0)
			if not entry.flipped and i < online:
				IconPainter.paint(self, "power", cell.get_center(), 14, Color("#3a2604"))
		if ship.temporary_power > 0:
			draw_string(UiKit.display_font, Vector2(power_x + ship.power_row.size() * 19 + 6, 50), "+%d" % ship.temporary_power, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiKit.GOOD)
		draw_string(UiKit.display_bold_font, Vector2(power_x + 60, 22), "%d AVAILABLE" % ship.available_power() if mine else "", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffc247"))
	else:
		draw_string(UiKit.body_font, Vector2(power_x, 48), "Sensors 2 needed to see power", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.FAINT)

	# Deck and hand counts
	var counts_x := size.x - 110.0
	draw_string(UiKit.display_font, Vector2(counts_x, 28), "DECK  %d" % ship.deck.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.MUTED)
	draw_string(UiKit.display_font, Vector2(counts_x, 50), "HAND  %d" % ship.hand.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.MUTED)


func _draw_hexagon(center: Vector2, radius: float, fill: Color, line: Color) -> void:
	var points := PackedVector2Array()
	for i in 6:
		points.append(center + Vector2.from_angle(i * TAU / 6.0) * radius)
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, line, 1.5, true)
