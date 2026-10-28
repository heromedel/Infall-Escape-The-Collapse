## One ship system on the battle screen: its symbol, level pips, damage, hazards and the crew standing in it.
## It only draws what the Battle says and reports clicks; the battle screen decides what a click means.
class_name SystemTile
extends Control

const TILE_SIZE := Vector2(118, 158)
const TOKEN_RADIUS := 12.0

signal tile_clicked(tile: SystemTile)
signal crew_clicked(tile: SystemTile, crew_id: int)
signal burn_clicked(tile: SystemTile)
signal hovered(tile: SystemTile, is_hovered: bool)

var battle: Battle
var ship_side := 0
var system_id := ""
var viewer_side := 0
## "" (plain), "target" (a card can aim here) or "move" (the selected crew member can go here).
var highlight := ""
var selected_crew_id := -1
## Crew ids that can be clicked right now (e.g. teleport or mind control choices), shown with a ring.
var choosable_crew: Array = []
## Damage flash, set by the battle screen's effects.
var flash := 0.0

var _token_rects := {}
var _burn_rect := Rect2()
var _hover := false
var _time := 0.0


func _init() -> void:
	custom_minimum_size = TILE_SIZE
	size = TILE_SIZE
	pivot_offset = TILE_SIZE / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func():
		_hover = true
		hovered.emit(self, true)
		queue_redraw())
	mouse_exited.connect(func():
		_hover = false
		hovered.emit(self, false)
		queue_redraw())


func setup(the_battle: Battle, side: int, id: String, viewer: int) -> SystemTile:
	battle = the_battle
	ship_side = side
	system_id = id
	viewer_side = viewer
	return self


func _process(delta: float) -> void:
	_time += delta
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 2.5)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if _burn_rect.has_point(event.position):
		burn_clicked.emit(self)
		return
	for crew_id in _token_rects:
		if _token_rects[crew_id].has_point(event.position):
			crew_clicked.emit(self, crew_id)
			return
	tile_clicked.emit(self)


## Where a crew member's token sits, in global coordinates (for effects).
func crew_token_center(crew_id: int) -> Vector2:
	if _token_rects.has(crew_id):
		return global_position + _token_rects[crew_id].get_center() * scale
	return global_position + size * scale / 2.0


func _draw() -> void:
	if battle == null:
		return
	var ship := battle.ships[ship_side]
	var system: Dictionary = ship.systems[system_id]
	var rect := Rect2(Vector2.ZERO, TILE_SIZE)
	var ship_color := ship.color
	var state_color := _state_color(ship, system)

	# Panel
	var border := ship_color.darkened(0.45)
	var fill := Color("#111726")
	if _hover:
		fill = Color("#18203a")
	match highlight:
		"target":
			border = UiKit.ACCENT.lerp(Color.WHITE, 0.3 * (0.5 + 0.5 * sin(_time * 6.0)))
			fill = Color("#22190c")
		"move":
			border = UiKit.GOOD.lerp(Color.WHITE, 0.3 * (0.5 + 0.5 * sin(_time * 6.0)))
			fill = Color("#10261a")
	draw_style_box(UiKit.box(fill, border, 10, 2 if highlight != "" else 1), rect)
	if flash > 0.0:
		draw_style_box(UiKit.box(Color(UiKit.DANGER, flash * 0.45), Color(UiKit.DANGER, flash), 10, 2), rect)

	# Name
	var title: String = system.name
	UiKit.draw_text_centered(self, UiKit.display_font, title, Rect2(4, 4, TILE_SIZE.x - 8, 18),
		UiKit.fit_size(UiKit.display_font, title, TILE_SIZE.x - 10, 14, 9), UiKit.TEXT)

	# Symbol
	var icon_center := Vector2(TILE_SIZE.x / 2.0, 48)
	draw_circle(icon_center, 24, Color(state_color, 0.10))
	draw_arc(icon_center, 24, 0, TAU, 32, Color(state_color, 0.35), 1.5, true)
	IconPainter.paint(self, IconPainter.system_art(system), icon_center, 30, state_color)

	# Hazard badges
	var badge_x := TILE_SIZE.x - 14.0
	if system.on_fire:
		_draw_flame(Vector2(badge_x, 32))
		badge_x -= 18
	if system.breached:
		_draw_breach(Vector2(badge_x, 32))
		badge_x -= 18
	if system.disabled_turns > 0:
		IconPainter.paint(self, "power", Vector2(14, 32), 18, UiKit.ION)

	# Level pips: working, spent this turn, damaged.
	var spent := int(ship.spent.get(system_id, 0)) if ship_side == battle.active_side else 0
	var level: int = system.level
	var pip_width := minf(14.0, (TILE_SIZE.x - 16) / level - 3)
	var total_width := level * (pip_width + 3) - 3
	var pip_x := (TILE_SIZE.x - total_width) / 2.0
	for i in level:
		var pip := Rect2(pip_x + i * (pip_width + 3), 78, pip_width, 9)
		var damaged: bool = i >= level - system.damage
		if damaged:
			draw_rect(pip, Color(UiKit.DANGER, 0.25))
			draw_rect(pip, UiKit.DANGER, false, 1.0)
			draw_line(pip.position, pip.end, UiKit.DANGER, 1.0)
		elif system.disabled_turns > 0 and system.type != "reactor":
			draw_rect(pip, Color(UiKit.ION, 0.35))
			draw_rect(pip, UiKit.ION, false, 1.0)
		elif i < spent:
			draw_rect(pip, Color(ship_color, 0.18))
			draw_rect(pip, Color(ship_color, 0.6), false, 1.0)
		else:
			draw_rect(pip, ship_color)

	# Status line
	var status := _status_text(ship, system)
	_burn_rect = Rect2()
	if system.type == "engines" and ship_side == viewer_side and battle.why_cannot_burn(viewer_side) == "":
		_burn_rect = Rect2(14, 92, TILE_SIZE.x - 28, 18)
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		draw_style_box(UiKit.box(Color(UiKit.ACCENT, 0.15 + pulse * 0.1), UiKit.ACCENT, 9, 1), _burn_rect)
		UiKit.draw_text_centered(self, UiKit.display_font, "BURN +5%", _burn_rect, 12, UiKit.ACCENT)
	else:
		UiKit.draw_text_centered(self, UiKit.body_font, status, Rect2(4, 92, TILE_SIZE.x - 8, 18),
			UiKit.fit_size(UiKit.body_font, status, TILE_SIZE.x - 8, 12, 9), UiKit.MUTED if system.disabled_turns == 0 else UiKit.ION)

	# Crew
	draw_line(Vector2(10, 114), Vector2(TILE_SIZE.x - 10, 114), Color(UiKit.LINE, 0.8), 1.0)
	_draw_crew(ship)


func _draw_crew(ship: ShipState) -> void:
	_token_rects.clear()
	var view := battle.sensor_view(viewer_side)
	var members := battle.crew_in_system(ship_side, system_id).filter(func(m):
		return m.owner == viewer_side or view.crew or ship_side == viewer_side and m.owner != viewer_side)
	var hidden := battle.crew_in_system(ship_side, system_id).size() - members.size()
	var per_row := 4
	for i in members.size():
		var member: Dictionary = members[i]
		var row := i / per_row
		var column := i % per_row
		var in_row := mini(per_row, members.size() - row * per_row)
		var center := Vector2(TILE_SIZE.x / 2.0 + (column - (in_row - 1) / 2.0) * 26.0, 130 + row * 22)
		_draw_token(member, center)
		_token_rects[member.id] = Rect2(center - Vector2(TOKEN_RADIUS, TOKEN_RADIUS), Vector2(TOKEN_RADIUS, TOKEN_RADIUS) * 2)
	if hidden > 0 and members.is_empty():
		UiKit.draw_text_centered(self, UiKit.body_font, "? crew unknown", Rect2(4, 122, TILE_SIZE.x - 8, 16), 11, UiKit.FAINT)


func _draw_token(member: Dictionary, center: Vector2) -> void:
	var owner_color: Color = battle.ships[member.owner].color
	var alpha := 0.55 if member.acted and member.owner == battle.active_side else 1.0
	if member.id == selected_crew_id:
		draw_circle(center, TOKEN_RADIUS + 5, Color(UiKit.ACCENT, 0.35 + 0.2 * sin(_time * 8.0)))
	elif member.id in choosable_crew:
		draw_arc(center, TOKEN_RADIUS + 4, 0, TAU, 24, Color(UiKit.ACCENT, 0.6 + 0.4 * sin(_time * 6.0)), 2, true)
	draw_circle(center, TOKEN_RADIUS, Color(owner_color.darkened(0.6), alpha))
	draw_circle(center, TOKEN_RADIUS - 3, Color(owner_color.darkened(0.25), alpha))
	# Health ring: three segments, lost ones in red.
	for segment in 3:
		var start := -PI / 2.0 + segment * TAU / 3.0 + 0.12
		var lost: bool = segment >= Battle.WOUNDS_TO_DIE - member.wounds
		draw_arc(center, TOKEN_RADIUS - 1, start, start + TAU / 3.0 - 0.24, 8, Color(UiKit.DANGER if lost else UiKit.GOOD, alpha), 2.5, true)
	var initials := _initials(member.name)
	UiKit.draw_text_centered(self, UiKit.display_bold_font, initials, Rect2(center - Vector2(12, 9), Vector2(24, 18)), 11, Color(Color.WHITE, alpha))
	# Skill pips under the token.
	for s in member.skill:
		draw_circle(center + Vector2((s - (member.skill - 1) / 2.0) * 6.0, TOKEN_RADIUS + 3), 1.8, UiKit.ACCENT)
	if member.controlled_by >= 0:
		draw_arc(center, TOKEN_RADIUS + 2, 0, TAU, 24, UiKit.MIND, 2.5, true)


func _state_color(ship: ShipState, system: Dictionary) -> Color:
	if system.disabled_turns > 0 and system.type != "reactor":
		return UiKit.ION
	if system.damage >= system.level:
		return UiKit.DANGER
	if system.damage > 0:
		return UiKit.ACCENT
	return ship.color


func _status_text(ship: ShipState, system: Dictionary) -> String:
	if system.disabled_turns > 0 and system.type != "reactor":
		return "OFFLINE"
	if system.damage >= system.level:
		return "BROKEN"
	match system.type:
		"reactor":
			return "%d/%d cells online" % [ship.online_power_cards(), ship.power_row.size()] if ship.power_row.size() > 0 else "No cells yet"
		"shields":
			return "%d/%d layers" % [ship.shield_layers.size(), ship.shield_capacity()]
		"engines":
			return "Evasion %d%%" % battle.evasion(ship)
		"piloting":
			return "Jump %d/%d" % [ship.jump_charge, Battle.JUMP_CHARGES_NEEDED] if ship.jump_charge > 0 else "Evasion %d%%" % battle.evasion(ship)
		"weapon":
			var kind := Catalog.weapon_kind(system.kind)
			var text := "%s · T%d" % [kind.name, system.weapon_type]
			if kind.uses_missile:
				text += " · %d left" % ship.missiles
			return text
		"evb":
			var out := ship.suits.filter(func(s): return s.dock == system.id).size()
			return "%d suit%s out" % [out, "" if out == 1 else "s"] if out > 0 else "Docked"
		"cloak":
			return "CLOAKED" if ship.cloaked else "Level %d" % system.level
		"medBay":
			return "Heals %d" % ship.capacity(system.id)
	return "Level %d" % system.level


func _draw_flame(at: Vector2) -> void:
	var flicker := 0.85 + 0.15 * sin(_time * 14.0)
	var outer := PackedVector2Array([at + Vector2(0, -9 * flicker), at + Vector2(6, 2), at + Vector2(3, 7), at + Vector2(-3, 7), at + Vector2(-6, 2)])
	draw_colored_polygon(outer, UiKit.FIRE)
	var inner := PackedVector2Array([at + Vector2(0, -3 * flicker), at + Vector2(3, 3), at + Vector2(0, 6), at + Vector2(-3, 3)])
	draw_colored_polygon(inner, Color("#ffe27a"))


func _draw_breach(at: Vector2) -> void:
	draw_circle(at, 7, Color("#0a0d16"))
	draw_arc(at, 7, 0, TAU, 16, UiKit.SHIELD, 1.5, true)
	draw_polyline(PackedVector2Array([at + Vector2(-5, -3), at + Vector2(-1, 0), at + Vector2(-3, 4)]), UiKit.SHIELD, 1.5)
	draw_polyline(PackedVector2Array([at + Vector2(5, -4), at + Vector2(1, 1), at + Vector2(4, 5)]), UiKit.SHIELD, 1.5)


func _initials(full_name: String) -> String:
	# Numbered names ("Ossa-3", "Unit K-5") read best as their first letter and number.
	var digits := ""
	for character in full_name:
		if character >= "0" and character <= "9":
			digits += character
	if digits != "":
		return (full_name.left(1) + digits).to_upper().left(3)
	var parts := full_name.replace(".", "").split(" ", false)
	if parts.size() >= 2:
		return (parts[parts.size() - 2].left(1) + parts[parts.size() - 1].left(1)).to_upper()
	return full_name.left(2).to_upper()
