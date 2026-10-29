## One ship system on the battle screen: its symbol, level pips, damage, hazards and the crew standing in it.
## It only draws what the Battle says and reports clicks; the battle screen decides what a click means.
class_name SystemTile
extends Control

const TILE_SIZE := Vector2(118, 158)
const TOKEN_RADIUS := 12.0

signal tile_clicked(tile: SystemTile)
signal crew_clicked(tile: SystemTile, crew_id: int)
signal burn_clicked(tile: SystemTile)
signal treat_clicked(tile: SystemTile)
signal hovered(tile: SystemTile, is_hovered: bool)
## The crew token under the mouse changed: a crew id, or -1 when the mouse left all tokens.
signal crew_hovered(tile: SystemTile, crew_id: int)

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
## While an action animates, what the tile shows instead of the battle's final state, so a hit appears when the
## shot lands: { damage, on_fire, breached, disabled_turns }. Empty: show the battle as it is.
var shown := {}
## While an action animates, each crew member's shown wounds (health pips lost) by crew id. Shared by all tiles.
var shown_crew := {}
## The ship is a wreck: drawn dark with its systems gone.
var wrecked := false
## While aiming a sweeping beam: -1 or 1 if the beam would cross this tile (the way it sweeps), else 0.
var sweep := 0
## While aiming a multi-target weapon: how many of its bolts are aimed here.
var bolts_aimed := 0

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


var _hovered_crew := -1


func _process(delta: float) -> void:
	_time += delta
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 2.5)
	var under := -1
	if _hover:
		var mouse := get_local_mouse_position()
		for crew_id in _token_rects:
			if _token_rects[crew_id].grow(2).has_point(mouse):
				under = crew_id
	if under != _hovered_crew:
		_hovered_crew = under
		crew_hovered.emit(self, under)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if _burn_rect.has_point(event.position):
		var system_type: String = battle.ships[ship_side].systems[system_id].type
		if system_type == "medBay":
			treat_clicked.emit(self)
		else:
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
	if not shown.is_empty():
		system = system.duplicate()
		system.merge(shown, true)
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

	# Symbol, or for a weapon system or EVB Dock the weapons or suit types it holds, one per row.
	var contents := _contents(system)
	if contents.is_empty():
		var icon_center := Vector2(TILE_SIZE.x / 2.0, 48)
		draw_circle(icon_center, 24, Color(state_color, 0.10))
		draw_arc(icon_center, 24, 0, TAU, 32, Color(state_color, 0.35), 1.5, true)
		IconPainter.paint(self, IconPainter.system_art(system), icon_center, 30, state_color)
	else:
		for i in contents.size():
			var entry: Dictionary = contents[i]
			var top := 24.0 + i * 13.5
			IconPainter.paint(self, entry.art, Vector2(25, top + 6.5), 12, state_color)
			UiKit.draw_text_centered(self, UiKit.body_font, entry.name, Rect2(32, top, TILE_SIZE.x - 58, 13),
				UiKit.fit_size(UiKit.body_font, entry.name, TILE_SIZE.x - 58, 12, 9), UiKit.TEXT)
			UiKit.draw_text_centered(self, UiKit.display_bold_font, str(entry.power), Rect2(TILE_SIZE.x - 26, top, 12, 13), 11, UiKit.ACCENT)

	# Hazard badges
	var badge_x := TILE_SIZE.x - 14.0
	if system.on_fire:
		_draw_flame(Vector2(badge_x, 32))
		var pips := int(system.get("fire", 1))
		if pips > 1:
			UiKit.draw_text_centered(self, UiKit.display_bold_font, str(pips), Rect2(badge_x - 4, 36, 14, 12), 11, UiKit.FIRE)
		badge_x -= 18
	if system.breached:
		_draw_breach(Vector2(badge_x, 32))
		badge_x -= 18
	if system.disabled_turns > 0:
		IconPainter.paint(self, "power", Vector2(14, 32), 18, UiKit.ION)
	_draw_air_pips(ship, system)

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

	# Status line, or a button for Engines (BURN) and the Med Bay (TREAT).
	var status := _status_text(ship, system)
	_burn_rect = Rect2()
	var button_text := ""
	if ship_side == viewer_side and system.type == "engines" and battle.why_cannot_burn(viewer_side) == "":
		button_text = "BURN +5%"
	elif ship_side == viewer_side and system.type == "medBay" and battle.why_cannot_treat(viewer_side) == "":
		button_text = "TREAT +%d" % ship.capacity(system_id)
	if button_text != "":
		_burn_rect = Rect2(14, 92, TILE_SIZE.x - 28, 18)
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		var button_color := UiKit.ACCENT if system.type == "engines" else UiKit.GOOD
		draw_style_box(UiKit.box(Color(button_color, 0.15 + pulse * 0.1), button_color, 9, 1), _burn_rect)
		UiKit.draw_text_centered(self, UiKit.display_font, button_text, _burn_rect, 12, button_color)
	else:
		UiKit.draw_text_centered(self, UiKit.body_font, status, Rect2(4, 92, TILE_SIZE.x - 8, 18),
			UiKit.fit_size(UiKit.body_font, status, TILE_SIZE.x - 8, 12, 9), UiKit.MUTED if system.disabled_turns == 0 else UiKit.ION)

	# Crew
	draw_line(Vector2(10, 114), Vector2(TILE_SIZE.x - 10, 114), Color(UiKit.LINE, 0.8), 1.0)
	_draw_crew(ship)
	if sweep != 0:
		# The beam's path: a bright line across the tile, arrowed the way it sweeps.
		var y := 48.0
		draw_line(Vector2(0, y), Vector2(TILE_SIZE.x, y), Color(UiKit.DANGER, 0.85), 4.0)
		var tip := Vector2(TILE_SIZE.x - 8 if sweep > 0 else 8, y)
		draw_colored_polygon(PackedVector2Array([tip + Vector2(6 * sweep, 0), tip + Vector2(-4 * sweep, -6), tip + Vector2(-4 * sweep, 6)]), UiKit.DANGER)
	if bolts_aimed > 0:
		var badge := Vector2(TILE_SIZE.x - 16, 62)
		draw_circle(badge, 10, UiKit.ACCENT)
		UiKit.draw_text_centered(self, UiKit.display_bold_font, "×%d" % bolts_aimed, Rect2(badge - Vector2(10, 9), Vector2(20, 18)), 12, Color("#1a1220"))
	if wrecked:
		# A destroyed ship: scorched over, its systems gone.
		draw_style_box(UiKit.box(Color(0.12, 0.02, 0.03, 0.72), Color(UiKit.DANGER, 0.7), 10, 2), rect)
		draw_line(Vector2(14, 14), TILE_SIZE - Vector2(14, 14), Color(UiKit.DANGER, 0.45), 3.0)
		draw_line(Vector2(TILE_SIZE.x - 14, 14), Vector2(14, TILE_SIZE.y - 14), Color(UiKit.DANGER, 0.45), 3.0)
		UiKit.draw_text_centered(self, UiKit.display_bold_font, "WRECKED", Rect2(0, TILE_SIZE.y / 2.0 - 14, TILE_SIZE.x, 28), 18, UiKit.DANGER)


## A weapon system's weapons or an EVB Dock's suit types: [{ name, art, power }], or [] for other systems.
func _contents(system: Dictionary) -> Array:
	match system.type:
		"weapon":
			return system.weapons.map(func(w): return {"name": w.name, "art": Weapons.art(w), "power": w.power})
		"evb":
			return system.suits.map(func(id): return {"name": Catalog.suit_kind(id).name, "art": "suit", "power": Catalog.suit_kind(id).cost})
	return []


func _draw_crew(ship: ShipState) -> void:
	_token_rects.clear()
	var view := battle.sensor_view(viewer_side)
	var here := _crew_here()
	var members := here.filter(func(m):
		return m.owner == viewer_side or view.crew or ship_side == viewer_side and m.owner != viewer_side)
	var hidden := here.size() - members.size()
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
	# Health ring: one segment per health pip, lost ones in red.
	var pips := maxi(1, int(member.max_health))
	var left := float(member.max_health) - _wounds_of(member)
	var gap := 0.08 if pips > 8 else 0.12
	for segment in pips:
		var start := -PI / 2.0 + segment * TAU / pips + gap
		var lost: bool = segment >= ceili(left)
		draw_arc(center, TOKEN_RADIUS - 1, start, start + TAU / pips - gap * 2.0, 4, Color(UiKit.DANGER if lost else UiKit.GOOD, alpha), 2.5, true)
	if Settings.value("crew_portraits") == "Cat Faces":
		CrewFace.draw(self, center + Vector2(0, 0.5), member.name, 1.5, alpha)
	else:
		var initials := _initials(member.name)
		UiKit.draw_text_centered(self, UiKit.display_bold_font, initials, Rect2(center - Vector2(12, 9), Vector2(24, 18)), 11, Color(Color.WHITE, alpha))
	if member.get("locked", false):
		# Repairing: a small wrench badge; they stay here this turn.
		var badge := center + Vector2(TOKEN_RADIUS - 1, -TOKEN_RADIUS + 1)
		draw_circle(badge, 5, UiKit.GOOD.darkened(0.5))
		draw_line(badge + Vector2(-2.5, 2.5), badge + Vector2(2, -2), Color.WHITE, 1.5)
		draw_circle(badge + Vector2(2, -2), 1.6, Color.WHITE)
	# Pips under the token: their skill for the system they're in (Veteran 1, Master 2).
	var skill := CrewSkills.level(member.skills, battle.ships[ship_side].systems[system_id].type)
	for s in skill:
		draw_circle(center + Vector2((s - (skill - 1) / 2.0) * 6.0, TOKEN_RADIUS + 3), 1.8, UiKit.ACCENT)
	if member.controlled_by >= 0:
		draw_arc(center, TOKEN_RADIUS + 2, 0, TAU, 24, UiKit.MIND, 2.5, true)
	if member.leaving_to != "":
		# Forcing the doors: a turning dashed ring.
		for dash in 8:
			var angle := _time * 2.0 + dash * TAU / 8.0
			draw_arc(center, TOKEN_RADIUS + 3, angle, angle + 0.4, 4, UiKit.ACCENT, 2.0, true)


## Crew standing here: everyone alive, or while animating, everyone not yet shown dead.
func _crew_here() -> Array:
	if shown_crew.is_empty():
		return battle.crew_in_system(ship_side, system_id)
	return battle.crew.filter(func(m): return m.ship == ship_side and m.system == system_id and _wounds_of(m) < m.max_health)


func _wounds_of(member: Dictionary) -> float:
	return float(shown_crew.get(member.id, member.wounds))


func _state_color(ship: ShipState, system: Dictionary) -> Color:
	if system.get("spored", false):
		return Color("#7dffb0")
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
	if system.get("spored", false):
		return "SPORES"
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
			return "Jump %d/%d" % [ship.jump_charge, battle.jump_charges_needed()]
		"weapon":
			var text := "Power %d" % system.level
			if Ammo.missiles_use_stock() and system.weapons.any(func(w): return w.uses_missile):
				text += " · %d missiles" % ship.missiles
			return text
		"evb":
			var out := ship.suits.filter(func(s): return s.dock == system.id).size()
			return "Power %d · air %d" % [system.level, CardLibrary.suit_air(system.level)] + (" · %d out" % out if out > 0 else "")
		"cloak":
			return "CLOAKED" if ship.cloaked else "Level %d" % system.level
		"medBay":
			return "Treated" if ship.treated else "Unpowered"
		"lifeSupport":
			return "Air up to %d" % ship.air_max
		"sensors", "airlock":
			var level := battle.effective_level(ship, system.id)
			var manned := level > ship.capacity(system.id)
			if system.type == "airlock":
				var turns := int(Catalog.by_skill(Catalog.rule("airlock", "boarderExitTurns", [0]), level))
				return "Lv %d%s · doors %d turn%s" % [level, " manned" if manned else "", turns, "" if turns == 1 else "s"]
			return "Level %d%s" % [level, " (manned)" if manned else ""]
	return "Level %d" % system.level


func _draw_flame(at: Vector2) -> void:
	var flicker := 0.85 + 0.15 * sin(_time * 14.0)
	var outer := PackedVector2Array([at + Vector2(0, -9 * flicker), at + Vector2(6, 2), at + Vector2(3, 7), at + Vector2(-3, 7), at + Vector2(-6, 2)])
	draw_colored_polygon(outer, UiKit.FIRE)
	var inner := PackedVector2Array([at + Vector2(0, -3 * flicker), at + Vector2(3, 3), at + Vector2(0, 6), at + Vector2(-3, 3)])
	draw_colored_polygon(inner, Color("#ffe27a"))


## A system's air pips, down the left edge: pale bubbles for air, dark rings for pips gone. With none left, the
## last ring is crossed out in red.
func _draw_air_pips(ship: ShipState, system: Dictionary) -> void:
	if ship.air_max == 0:
		return
	var air: int = 0 if system.breached else system.air
	for i in maxi(1, ship.air_max):
		var at := Vector2(12, 62 - i * 12)
		if i < air:
			draw_circle(at, 4.5, Color("#9fd8ff", 0.85))
			draw_circle(at + Vector2(-1.3, -1.3), 1.3, Color(1, 1, 1, 0.9))
		else:
			draw_circle(at, 4.5, Color("#0a0d16"))
			draw_arc(at, 4.5, 0, TAU, 14, Color("#9fd8ff", 0.45), 1.2, true)
	if air == 0:
		var at := Vector2(12, 62)
		draw_arc(at, 4.5, 0, TAU, 14, UiKit.DANGER, 1.5, true)
		draw_line(at + Vector2(-3, 3), at + Vector2(3, -3), UiKit.DANGER, 1.5)


## A hull breach: a jagged red hole open to space.
func _draw_breach(at: Vector2) -> void:
	var pulse := 0.75 + 0.25 * sin(_time * 5.0)
	var rim := PackedVector2Array()
	for i in 10:
		var angle := i * TAU / 10.0
		rim.append(at + Vector2.from_angle(angle) * (8.0 if i % 2 == 0 else 5.5))
	draw_colored_polygon(rim, Color(UiKit.DANGER, pulse))
	var hole := PackedVector2Array()
	for i in 10:
		var angle := i * TAU / 10.0 + 0.3
		hole.append(at + Vector2.from_angle(angle) * (4.5 if i % 2 == 0 else 3.0))
	draw_colored_polygon(hole, Color("#05060c"))
	draw_circle(at + Vector2(1, -1), 0.8, Color(1, 1, 1, 0.7))


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
