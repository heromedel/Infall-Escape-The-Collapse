class_name BattleHud
extends Control
## The ship view's HUD, drawn every frame from the encounter: the selected ship's hull, shields and evasion,
## its crew, its power bars, its weapons and special systems, the Jigawatt Drive, Mawjig, and a card for each
## enemy ship. Every clickable part registers a region while it is drawn; clicks and tooltips go through those
## regions, and anything not on the HUD falls through to the battle world.
##
## The HUD is a set of cards the player can move by their grab bars, dock to each other and fold away; HudLayout
## keeps where they are. A folded card opens by itself when something goes wrong on it, and folds again after
## five quiet seconds (heromedel, 2026-10-31).

const PAD := 16.0
const CARD_NAMES := {"top": "MAWJIG AND DRIVE", "ship": "SHIP", "crew": "CREW", "power": "SYSTEMS", "subsystems": "SUBSYSTEMS", "weapons": "WEAPONS", "specials": "SPECIALS"}
const FOLDED_HEIGHT := 26.0
const FOLD_BACK_SECONDS := 5.0
const OPACITY := {"85%": 0.86, "100%": 1.0, "70%": 0.7}

var screen: BattleScreen
var box_rect := Rect2()
var _regions: Array = []             # {rect, left: Callable, right: Callable, tooltip: String}
var _hover_region: Dictionary = {}
var _hover_time := 0.0
var _message := ""
var _message_time := 0.0
var _time := 0.0
var layout := HudLayout.load_saved()
var _drag_grab := Vector2.ZERO        # where on the card the grab bar was taken
var _trouble: Dictionary = {}         # card -> how much is wrong on it, to notice when it gets worse
var _peeking: Dictionary = {}         # folded card -> time of its last change, while it shows itself


func _ready() -> void:
	add_to_group("battle_hud")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func flash_message(text: String) -> void:
	_message = text
	_message_time = 2.5


func _process(delta: float) -> void:
	_time += delta
	if _message_time > 0.0:
		_message_time -= delta
	var mouse := get_local_mouse_position()
	var region := _region_at(mouse)
	if not _same_region(region, _hover_region):
		_hover_time = 0.0
	else:
		_hover_time += delta
	_hover_region = region   # the fresh copy, so a tooltip shows the latest numbers
	queue_redraw()


func _input(event: InputEvent) -> void:
	if screen == null or screen.encounter == null or not is_visible_in_tree():
		return
	if layout.dragging != "":
		# A card is being moved: it follows the mouse and lands where the button is let go
		if event is InputEventMouseMotion:
			layout.drag_to(layout.dragging, get_local_mouse_position() - _drag_grab, size)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			layout.drop(layout.dragging, size)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		for id in _peeking.keys():   # clicking a card that opened by itself keeps it open
			if layout.rects.has(id) and layout.rects[id].has_point(get_local_mouse_position()):
				_peeking.erase(id)
				layout.set_folded(id, false)
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var region := _region_at(get_local_mouse_position())
		if region.is_empty():
			return
		var action: Callable = region.left if event.button_index == MOUSE_BUTTON_LEFT else region.right
		if action.is_valid():
			action.call()
		get_viewport().set_input_as_handled()


## Regions are rebuilt every frame with fresh callables, so the same spot is recognised by its place.
func _same_region(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty():
		return a.is_empty() and b.is_empty()
	return a.rect == b.rect


func _region_at(point: Vector2) -> Dictionary:
	for index in range(_regions.size() - 1, -1, -1):
		if _regions[index].rect.has_point(point):
			return _regions[index]
	return {}


func _region(rect: Rect2, left: Callable, tooltip: String = "", right: Callable = Callable()) -> void:
	_regions.append({"rect": rect, "left": left, "right": right, "tooltip": tooltip})


# --- Drawing --------------------------------------------------------------------------------------------------

func _draw() -> void:
	_regions.clear()
	if screen == null or screen.encounter == null:
		return
	var ship := screen.selected_ship
	layout.rects.clear()
	for id in HudLayout.DEFAULTS:
		if id == "top" or (ship and not ship.is_gone()):
			_draw_card(id, ship)
	_draw_enemies()
	_draw_overlays()
	_draw_tooltip()


# --- Cards ----------------------------------------------------------------------------------------------------

## Draws one card where the layout puts it (its host first, if it is docked), folded or open, with its grab bar.
func _draw_card(id: String, ship: Ship) -> void:
	if layout.rects.has(id):
		return
	var host := layout.host_of(id)
	if host != "" and HudLayout.DEFAULTS.has(host) and (host == "top" or ship):
		_draw_card(host, ship)
	_watch(id, ship)
	var full := _card_size(id, ship)
	var folded := layout.is_folded(id) and not _peeking.has(id)
	var card_size := Vector2(clampf(full.x, 170.0, 260.0), FOLDED_HEIGHT) if folded and full != Vector2.ZERO else full
	var at := layout.place(id, card_size, size)
	var rect := Rect2(at, card_size)
	layout.rects[id] = rect
	if full == Vector2.ZERO:
		return
	if folded:
		UiKit.draw_frame(self, rect, _panel(), UiColours.BORDER_DIM, 5.0)
		UiKit.draw_text(self, rect.position + Vector2(12, 18), CARD_NAMES[id], 13, UiColours.TEXT_DIM, UiKit.font_bold())
		_region(rect, func(): layout.set_folded(id, false), "%s is folded. Click to open it." % CARD_NAMES[id].capitalize())
	else:
		match id:
			"top": _draw_top_centre(at)
			"ship": _draw_ship_card(ship, at)
			"crew": _draw_crew_list(ship, at)
			"power": _draw_power(ship, at)
			"subsystems": _draw_subsystems(ship, at)
			"weapons": _draw_weapons(ship, at)
			"specials": _draw_specials(ship, at)
	if Settings.get_value("hud_layout", "Movable") == "Movable":
		_draw_grab_bar(id, rect, folded)


## How big a card is when open, worked out from what it shows; zero when it has nothing to show.
func _card_size(id: String, ship: Ship) -> Vector2:
	match id:
		"top":
			return Vector2(692, 74)
		"ship":
			var ships := screen.encounter.player_ships()
			var tabs := 44.0 if ships.size() > 1 else 0.0
			return Vector2(maxf(560.0, ships.size() * 178.0 - 8.0 if tabs > 0.0 else 0.0), 136.0 + tabs)
		"crew":
			return Vector2(290, ship.crew.filter(func(m): return not m.dead).size() * 54.0 + 36.0)
		"power":
			return Vector2(120.0 + _power_systems(ship, true).size() * SYSTEM_COLUMN + 10.0, POWER_HEIGHT)
		"subsystems":
			var count := _power_systems(ship, false).size()
			return Vector2(count * SYSTEM_COLUMN + 20.0, POWER_HEIGHT) if count > 0 else Vector2.ZERO
		"weapons":
			if ship.weapons.filter(func(s): return s.def.type != "suit").is_empty() and ship.system_by("weapons") == null:
				return Vector2.ZERO
			return Vector2(maxi(_weapon_slots(ship).size(), 1) * (WEAPON_SLOT.x + 8) + 16, WEAPON_SLOT.y + 74)
		"specials":
			var count := _special_buttons(ship).size()
			return Vector2(170, count * 38.0 + 40.0) if count > 0 else Vector2.ZERO
	return Vector2.ZERO


## The grab bar: a small tab on the card's top edge to drag it by, with a button to fold or open it. It stays
## faint until the mouse comes near.
func _draw_grab_bar(id: String, rect: Rect2, folded: bool) -> void:
	var handle := Rect2(rect.position.x + rect.size.x * 0.5 - 34.0, rect.position.y - 7.0, 68.0, 12.0)
	var fold := Rect2(handle.end.x + 4.0, handle.position.y, 16.0, 12.0)
	var near := rect.grow(6.0).has_point(get_local_mouse_position()) or layout.dragging == id
	var alpha := 0.95 if near else 0.3
	for part in [handle, fold]:
		draw_rect(part, Color(UiColours.PANEL_LIGHT, alpha))
		draw_rect(part, Color(UiColours.BORDER, alpha * 0.8), false, 1.0)
	for dot in 4:
		draw_circle(handle.position + Vector2(22.0 + dot * 8.0, 6.0), 1.6, Color(UiColours.TEXT, alpha))
	draw_line(fold.get_center() - Vector2(4, 0), fold.get_center() + Vector2(4, 0), Color(UiColours.TEXT, alpha), 1.5)
	if folded:
		draw_line(fold.get_center() - Vector2(0, 4), fold.get_center() + Vector2(0, 4), Color(UiColours.TEXT, alpha), 1.5)
	_region(handle, func(): _start_drag(id), "Drag to move this card; drop it against another card's side to dock it there. Right click puts it back.", func(): _reset_card(id))
	_region(fold, func(): _toggle_fold(id), "Fold this card to its bar, or open it.")


func _start_drag(id: String) -> void:
	_drag_grab = get_local_mouse_position() - layout.rects[id].position
	layout.drag_to(id, layout.rects[id].position, size)


func _toggle_fold(id: String) -> void:
	_peeking.erase(id)
	layout.set_folded(id, not layout.is_folded(id))


func _reset_card(id: String) -> void:
	layout.cards[id] = HudLayout.DEFAULTS[id].duplicate()
	layout.cards[id]["folded"] = false
	layout.save()


## Notices when something gets worse on a card. A folded card then shows itself, and folds again five quiet
## seconds later unless the player clicks it (settings: Collapsed Cards Reopen on Change, Reopened Cards Fold
## Back).
func _watch(id: String, ship: Ship) -> void:
	var trouble := _card_trouble(id, ship)
	var worse := trouble > float(_trouble.get(id, trouble)) + 0.01
	_trouble[id] = trouble
	if not layout.is_folded(id):
		_peeking.erase(id)
		return
	if worse and Settings.get_value("collapsed_cards_reopen", true):
		_peeking[id] = _time
	elif _peeking.has(id) and Settings.get_value("reopened_cards_fold_back", true) and _time - float(_peeking[id]) > FOLD_BACK_SECONDS:
		_peeking.erase(id)


## How much is wrong on a card: it rises when crew are hurt, hull or shields are lost, or systems and weapons
## are damaged or lose power, and falls as things recover.
func _card_trouble(id: String, ship: Ship) -> float:
	if ship == null or ship.is_gone():
		return 0.0
	var trouble := 0.0
	match id:
		"crew":
			for member in ship.crew:
				trouble += 100.0 if member.dead else (member.max_health - member.health)
				if not member.dead and (member.stun_ticks > 0 or member.suffocating or member.task in ["fighting", "extinguishing"]):
					trouble += 20.0
		"ship":
			trouble = (ship.max_hull - ship.hull) * 10.0 + ship.max_shield_layers() - ship.shield_layers
		"power", "subsystems":
			for system in _power_systems(ship, id == "power"):
				trouble += system.damage * 10.0 + system.ion * 5.0 + (10.0 if system.spored else 0.0) + system.level - ship.system_power(system)
		"weapons":
			for slot in ship.weapons:
				trouble += 0.0 if slot.powered else 10.0
	return trouble


func _panel() -> Color:
	return Color(UiColours.PANEL, OPACITY.get(Settings.get_value("hud_card_opacity", "85%"), 0.86))


func _draw_squad_tabs(at: Vector2) -> float:
	var y := at.y
	var ships := screen.encounter.player_ships()
	if ships.size() <= 1:
		return y
	var x := at.x
	for ship in ships:
		var rect := Rect2(x, y, 170, 34)
		var chosen := ship == screen.selected_ship
		var gone := ship.is_gone()
		UiKit.draw_frame(self, rect, UiColours.PANEL_LIGHT if chosen else UiColours.PANEL, UiColours.BORDER if chosen else UiColours.BORDER_DIM, 7.0)
		UiKit.draw_text(self, rect.position + Vector2(10, 22), ship.name if not gone else ship.name + " (lost)", 15, UiColours.TEXT if not gone else UiColours.TEXT_DIM, UiKit.font_bold())
		if not gone:
			var fraction := float(ship.hull) / ship.max_hull
			draw_rect(Rect2(rect.position + Vector2(10, 27), Vector2(150 * fraction, 3)), UiColours.hull_colour(fraction))
			_region(rect, func(): screen.select_ship(ship), "Select this ship. Tab cycles through the squad.")
		x += 178
	return y + 44


func _draw_ship_card(ship: Ship, card_at: Vector2) -> void:
	var at := Vector2(card_at.x, _draw_squad_tabs(card_at))
	var rect := Rect2(at, Vector2(560, 136))
	UiKit.draw_frame(self, rect, _panel())
	UiKit.draw_text(self, at + Vector2(16, 30), ship.name.to_upper(), 24, UiColours.TEXT, UiKit.font_title())
	UiKit.draw_text(self, at + Vector2(16, 52), "%s  ·  %s" % [ship.design.class_text, ship.race.name], 15, UiColours.TEXT_DIM)
	# Hull: one segment per point, as the genre shows it
	var fraction := float(ship.hull) / maxf(1.0, ship.max_hull)
	var bar_at := at + Vector2(16, 66)
	UiKit.draw_text(self, bar_at + Vector2(0, 17), "HULL", 15, UiColours.TEXT_DIM, UiKit.font_bold())
	var segments := ship.max_hull
	var bar_width := 420.0
	var segment := bar_width / segments
	for index in segments:
		var cell := Rect2(bar_at + Vector2(52 + index * segment, 2), Vector2(maxf(1.0, segment - 2.0), 18))
		draw_rect(cell, UiColours.hull_colour(fraction) if index < ship.hull else UiColours.BAR_EMPTY)
	UiKit.draw_text(self, bar_at + Vector2(480, 17), "%d/%d" % [ship.hull, ship.max_hull], 16, UiColours.TEXT, UiKit.font_bold())
	_region(Rect2(bar_at, Vector2(520, 22)), Callable(), "Hull: the ship is destroyed when it reaches zero. Repair it at a store.")
	# Shields
	var shield_at := at + Vector2(16, 100)
	UiKit.draw_text(self, shield_at + Vector2(0, 16), "SHIELDS", 15, UiColours.TEXT_DIM, UiKit.font_bold())
	var max_layers := maxi(ship.max_shield_layers(), ship.system_by("shields").level / 2 if ship.system_by("shields") else 0)
	var x := 86.0
	for index in max_layers:
		var centre := shield_at + Vector2(x + 12, 10)
		var up := index < ship.shield_layers
		draw_circle(centre, 11, Color(0.1, 0.16, 0.28))
		if up:
			draw_circle(centre, 9, UiColours.SHIELD_BLUE)
			draw_circle(centre + Vector2(-3, -3), 3, Color(1, 1, 1, 0.6))
		elif index == ship.shield_layers and index < ship.max_shield_layers():
			draw_arc(centre, 8, -PI / 2, -PI / 2 + TAU * ship.shield_progress / Ship.SHIELD_LAYER_TICKS, 20, UiColours.SHIELD_BLUE, 3.0, true)
		draw_arc(centre, 11, 0, TAU, 24, UiColours.BORDER_DIM, 1.2, true)
		x += 28
	if ship.has_system("supershield"):
		for index in 5:
			var centre := shield_at + Vector2(x + 10 + index * 18, 10)
			draw_circle(centre, 7, UiColours.SUPERSHIELD if index < ship.supershield else Color(0.25, 0.12, 0.22))
		x += 100
	_region(Rect2(shield_at, Vector2(x + 10, 22)), Callable(), "Shield layers. Each stops one laser or flak shot, then recharges. Missiles and bombs pass through.")
	# Evasion and air
	var evasion := ship.evasion()
	var air := 0.0
	for room in ship.rooms:
		air += room.oxygen
	air /= maxf(1.0, ship.rooms.size())
	var stats_at := at + Vector2(300, 116)
	UiKit.draw_text(self, stats_at, "EVASION %d%%" % evasion, 16, UiColours.TEXT if evasion > 0 else UiColours.WARNING, UiKit.font_bold())
	UiKit.draw_text(self, stats_at + Vector2(140, 0), "AIR %d%%" % int(air * 100.0), 16, UiColours.TEXT if air > 0.5 else UiColours.DAMAGED_RED, UiKit.font_bold())
	_region(Rect2(stats_at + Vector2(0, -18), Vector2(130, 24)), Callable(), "Evasion: the chance an incoming shot misses. It needs Engines powered and a pilot at Piloting.")
	_region(Rect2(stats_at + Vector2(140, -18), Vector2(110, 24)), Callable(), "The ship's air. Crew who breathe suffocate in rooms without it. Life Support refills it.")


func _draw_crew_list(ship: Ship, at: Vector2) -> void:
	var members: Array[CrewMember] = []
	for member in ship.crew:
		if not member.dead:
			members.append(member)
	var y := at.y
	for member in members:
		var rect := Rect2(at.x, y, 290, 50)
		var chosen := member.selected
		UiKit.draw_frame(self, rect, UiColours.PANEL_LIGHT if chosen else _panel(), UiColours.POWER_GREEN if chosen else UiColours.BORDER_DIM, 6.0)
		CrewPortraits.draw_token(self, member.race.id, member.name, rect.position + Vector2(22, 25), 16.0, UiColours.POWER_GREEN)
		UiKit.draw_text(self, rect.position + Vector2(46, 20), member.name, 16, UiColours.TEXT, UiKit.font_bold())
		var fraction := member.health_fraction()
		draw_rect(Rect2(rect.position + Vector2(46, 29), Vector2(120, 7)), UiColours.BAR_EMPTY)
		draw_rect(Rect2(rect.position + Vector2(46, 29), Vector2(120 * fraction, 7)), UiColours.hull_colour(fraction))
		if member.healing:
			var pulse := 0.5 + 0.5 * sin(_time * 6.0)
			draw_rect(Rect2(rect.position + Vector2(46, 29), Vector2(120 * fraction, 7)), Color(1, 1, 1, 0.35 * pulse))
		# What they are doing, and where: "manning" over "Piloting"
		var status := _crew_status(member)
		var place := _crew_place(member)
		var status_colour := UiColours.POWER_GREEN if status == "healing" else (UiColours.WARNING if status in ["fire!", "fighting", "stunned", "no air!"] else UiColours.TEXT)
		UiKit.draw_text(self, rect.position + Vector2(rect.size.x - 10, 21), status, 13, status_colour, UiKit.font_bold(), HORIZONTAL_ALIGNMENT_RIGHT, 0)
		UiKit.draw_text(self, rect.position + Vector2(rect.size.x - 10, 39), place, 12, UiColours.TEXT_DIM, null, HORIZONTAL_ALIGNMENT_RIGHT, 0)
		_region(rect, func(): screen.select_crew_member(member, Input.is_key_pressed(KEY_SHIFT)), _crew_tooltip(member))
		y += 54
	var buttons_at := Vector2(at.x, y + 4)
	_button(Rect2(buttons_at, Vector2(142, 32)), "STATIONS", func(): screen.return_to_stations(), "Send this ship's crew back to their saved stations. Hotkey: Z")
	_button(Rect2(buttons_at + Vector2(148, 0), Vector2(142, 32)), "SAVE POSTS", func(): screen.save_stations(), "Save where every crew member stands now as their station.")


func _crew_status(member: CrewMember) -> String:
	if member.in_suit:
		return "in a battlesuit"
	if member.suffocating:
		return "no air!"
	match member.task:
		"manning":
			return "manning"
		"repairing", "patching":
			return "repairing"
		"extinguishing":
			return "fire!"
		"fighting":
			return "fighting"
		"breaking":
			return "breaking a door"
		"sabotaging":
			return "sabotaging"
		"walking":
			return "moving"
		"stunned":
			return "stunned"
	if member.healing:
		return "healing"
	return "boarding" if member.ship != member.home else "standing by"


## Where they are doing it: the station they man, the system they repair, the room they stand in or are
## walking to.
func _crew_place(member: CrewMember) -> String:
	if member.in_suit:
		return "outside"
	var ship := member.ship
	var room_index := ship.room_at(member.destination if member.task == "walking" else member.cell)
	if room_index < 0:
		room_index = ship.room_at(member.cell)
	if member.task == "manning":
		var names := PackedStringArray()
		for system in ship.systems:
			if system.manned_by == member:
				names.append(system.display_name())
		if not names.is_empty():
			return ", ".join(names)
	var place := _room_label(ship, room_index)
	if member.task == "walking":
		place = "to " + place
	if member.ship != member.home:
		place += " (%s)" % ship.name
	return place


func _room_label(ship: Ship, room_index: int) -> String:
	if room_index < 0:
		return ""
	var room := ship.rooms[room_index]
	for system in room.systems:
		if system.behaviour != "power_core":
			return system.display_name()
	if not room.name.is_empty():
		return room.name
	return "Room %d" % (room_index + 1)


func _crew_tooltip(member: CrewMember) -> String:
	var lines := PackedStringArray()
	lines.append("%s, %s" % [member.name, member.race.singular])
	lines.append("Health %d / %d" % [int(member.health), int(member.max_health)])
	for skill in CrewMember.SKILLS:
		var level := member.skill_level(skill)
		var points := int(member.xp[skill])
		var next := " (%d / %d)" % [points, int(CrewMember.LEVEL_XP[level])] if level < 2 else ""
		lines.append("%s: %s%s" % [skill.capitalize(), ["untrained", "level 1", "level 2"][level], next])
	lines.append(member.race.traits_text)
	return "\n".join(lines)


func _button(rect: Rect2, text: String, action: Callable, tooltip: String = "", enabled: bool = true, lit: bool = false) -> void:
	var hovered := rect.has_point(get_local_mouse_position()) and enabled
	var fill := UiColours.PANEL_LIGHT.lightened(0.18) if hovered else UiColours.PANEL_LIGHT
	if lit:
		fill = Color(0.18, 0.42, 0.24, 0.95) if not hovered else Color(0.24, 0.55, 0.3, 0.95)
	if not enabled:
		fill = UiColours.PANEL_DARK
	UiKit.draw_frame(self, rect, fill, UiColours.BORDER if enabled else Color(UiColours.BORDER_DIM, 0.3), 6.0)
	UiKit.draw_text(self, rect.position + Vector2(0, rect.size.y * 0.5 + 6), text, 15, UiColours.TEXT if enabled else Color(UiColours.TEXT_DIM, 0.5), UiKit.font_bold(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	_region(rect, (func(): Sfx.play("click"); action.call()) if enabled else Callable(), tooltip)


# --- Power ----------------------------------------------------------------------------------------------------

const SYSTEM_COLUMN := 44.0
const POWER_HEIGHT := 170.0
const POWER_BAR := 9.0


## The systems that draw power (`main`) or the subsystems that don't, in their display order.
func _power_systems(ship: Ship, main: bool) -> Array:
	var systems: Array = ship.systems.filter(func(s): return s.behaviour != "power_core" and s.def.draws_power == main)
	systems.sort_custom(func(a, b): return a.def.order < b.def.order)
	return systems


func _draw_power(ship: Ship, at: Vector2) -> void:
	var main_systems := _power_systems(ship, true)
	var bottom := at.y + POWER_HEIGHT
	var x := at.x
	var bar_height := POWER_BAR
	var rect := Rect2(at, _card_size("power", ship))
	UiKit.draw_frame(self, rect, _panel())
	# The power source: reactor bars, the AZC, or nothing for a self-powered ship
	var source_at := Vector2(x + 14, bottom - 30)
	match ship.reactor_type:
		"pool":
			var total := ship.reactor_total()
			var free := ship.reactor_free()
			var shown := mini(total, 14)
			for index in shown:
				var cell := Rect2(source_at + Vector2(0, -index * (bar_height + 2) - bar_height), Vector2(30, bar_height))
				draw_rect(cell, UiColours.POWER_GREEN if index < free else UiColours.BAR_EMPTY)
			UiKit.draw_text(self, source_at + Vector2(38, -2), "%d / %d" % [free, total], 15, UiColours.TEXT, UiKit.font_bold())
			UiKit.draw_text(self, source_at + Vector2(38, 18), "REACTOR", 12, UiColours.TEXT_DIM, UiKit.font_bold())
			_region(Rect2(source_at + Vector2(0, -150), Vector2(100, 170)), Callable(), "Reactor: free power is lit. Click a system's bars to give it power; right click takes it away.")
		"core":
			var running := ship.core_load()
			var capacity := ship.core_capacity()
			draw_circle(source_at + Vector2(30, -70), 26, Color("#20262f"))
			draw_arc(source_at + Vector2(30, -70), 22, 0, TAU, 32, Color(UiColours.POWER_GREEN, 0.6 + 0.3 * sin(_time * 2.4)), 3.0, true)
			SystemIcons.draw(self, "azc", source_at + Vector2(30, -70), 26, UiColours.POWER_GREEN)
			for index in capacity:
				var pip := source_at + Vector2(8 + (index % 4) * 16, -32 + (index / 4) * 14)
				draw_rect(Rect2(pip, Vector2(12, 8)), UiColours.POWER_GREEN if index < running else UiColours.BAR_EMPTY)
			UiKit.draw_text(self, source_at + Vector2(0, 18), "AZC LV%d  %d/%d" % [ship.reactor_level, running, capacity], 12, UiColours.TEXT_DIM, UiKit.font_bold())
			_region(Rect2(source_at + Vector2(0, -110), Vector2(100, 130)), Callable(), "Armoured ZeroPoint Core: any system joined to it by unbroken conduits has full power. Its level sets how many power-hungry systems run at once. Click a system to switch it on or off.")
		_:
			UiKit.draw_text(self, source_at + Vector2(0, -2), "SELF-", 14, UiColours.TEXT_DIM, UiKit.font_bold())
			UiKit.draw_text(self, source_at + Vector2(0, 16), "POWERED", 14, UiColours.TEXT_DIM, UiKit.font_bold())
	x += 120.0
	for system in main_systems:
		_draw_system_column(ship, system, Vector2(x, bottom - 30), SYSTEM_COLUMN, bar_height, true)
		x += SYSTEM_COLUMN


## The subsystems (piloting, sensors, doors and the like): their own card, docked beside the systems at first.
func _draw_subsystems(ship: Ship, at: Vector2) -> void:
	UiKit.draw_frame(self, Rect2(at, _card_size("subsystems", ship)), _panel())
	var x := at.x + 10.0
	for system in _power_systems(ship, false):
		_draw_system_column(ship, system, Vector2(x, at.y + POWER_HEIGHT - 30), SYSTEM_COLUMN, POWER_BAR, false)
		x += SYSTEM_COLUMN


func _draw_system_column(ship: Ship, system: ShipSystem, base: Vector2, column: float, bar_height: float, main: bool) -> void:
	var power := ship.system_power(system)
	var level := system.level
	var colour := UiColours.POWER_GREEN
	var bar_width := column - 14.0
	for index in level:
		var cell := Rect2(base + Vector2(4, -index * (bar_height + 2) - bar_height - 22), Vector2(bar_width, bar_height))
		var fill := UiColours.BAR_EMPTY
		var from_top := level - 1 - index
		if from_top < system.damage:
			fill = UiColours.DAMAGED_RED
		elif index < power:
			fill = colour
		elif index < system.usable_bars() and index >= system.usable_bars() - system.ion:
			fill = UiColours.ION_BLUE
		draw_rect(cell, fill)
		if fill == UiColours.BAR_EMPTY:
			draw_rect(cell, Color(UiColours.BORDER_DIM, 0.35), false, 1.0)
	var icon_centre := base + Vector2(column * 0.5 - 3, 0)
	var icon_colour := UiColours.POWER_GREEN if power > 0 else Color("#8b93a3")
	if system.is_broken() or system.spored:
		icon_colour = UiColours.DAMAGED_RED
	elif system.damage > 0:
		icon_colour = Color("#ff9a3d")
	draw_circle(icon_centre, 15, Color(0.04, 0.06, 0.1))
	draw_arc(icon_centre, 15, 0, TAU, 24, icon_colour, 1.5, true)
	SystemIcons.draw(self, system.def.icon, icon_centre, 18, icon_colour)
	if system.manned_by:
		draw_circle(icon_centre + Vector2(12, -12), 4, UiColours.POWER_GREEN)
	if ship.reactor_type == "core" and not ship.system_connected(system):
		var flash := 0.5 + 0.5 * sin(_time * 9.0)
		draw_circle(icon_centre + Vector2(-12, -12), 5, Color(UiColours.DAMAGED_RED, flash))
	var rect := Rect2(base + Vector2(0, -level * (bar_height + 2) - 30), Vector2(column - 4, level * (bar_height + 2) + 48))
	var tooltip := _system_tooltip(ship, system)
	if main and ship.reactor_type != "none":
		_region(rect, func(): _add_power(ship, system), tooltip, func(): _remove_power(ship, system))
	else:
		_region(rect, Callable(), tooltip)


func _add_power(ship: Ship, system: ShipSystem) -> void:
	if ship.reactor_type == "core" and system.enabled:
		_remove_power(ship, system)
		return
	if ship.add_power(system):
		Sfx.play("power_up")
	else:
		Sfx.play("deny")
		if ship.reactor_type == "core":
			flash_message("The AZC is running all the systems it can. Switch another off first.")
		elif system.power >= system.usable_bars():
			flash_message("%s can't hold more power." % system.def.name)
		else:
			flash_message("No free reactor power.")


func _remove_power(ship: Ship, system: ShipSystem) -> void:
	if ship.remove_power(system):
		Sfx.play("power_down")


func _system_tooltip(ship: Ship, system: ShipSystem) -> String:
	var lines := PackedStringArray()
	lines.append("%s (level %d)" % [system.display_name(), system.level])
	lines.append(system.def.description)
	var note := system.def.level_note(system.level if system.behaviour != "shields" else system.level)
	if not note.is_empty():
		lines.append("Now: " + note)
	var state := PackedStringArray()
	state.append("power %d" % ship.system_power(system))
	if system.damage > 0:
		state.append("%d bar%s damaged" % [system.damage, "" if system.damage == 1 else "s"])
	if system.ion > 0:
		state.append("ionized")
	if system.spored:
		state.append("spored: repair to clear")
	if ship.reactor_type == "core" and not ship.system_connected(system):
		state.append("cut off from the AZC: repair its conduits")
	if system.def.manned:
		state.append("manned" if system.manned_by else "unmanned")
	lines.append("Status: " + ", ".join(state))
	if system.behaviour == "medbay":
		if ship.system_power(system) > 0:
			lines.append("Hurt crew standing in this room heal.")
		elif ship.reactor_type == "core":
			lines.append("Switch it on to heal crew standing in it; another system may need to go off first.")
		else:
			lines.append("Give it power to heal crew standing in it.")
	if system.def.draws_power and ship.reactor_type == "pool":
		lines.append("Click to add power, right click to remove.")
	elif system.def.draws_power and ship.reactor_type == "core":
		lines.append("Click to switch on or off.")
	return "\n".join(lines)


# --- Weapons --------------------------------------------------------------------------------------------------

const WEAPON_SLOT := Vector2(170, 86)


func _weapon_slots(ship: Ship) -> Array:
	return ship.weapons.filter(func(s): return s.def.type != "suit")


func _draw_weapons(ship: Ship, card_at: Vector2) -> void:
	var weapons_system := ship.system_by("weapons")
	var slots := _weapon_slots(ship)
	var slot_size := WEAPON_SLOT
	var count := maxi(slots.size(), 1)
	var width := count * (slot_size.x + 8) + 16
	var at := card_at + Vector2(8, 30)
	var rect := Rect2(card_at, Vector2(width, slot_size.y + 40 + 34))
	UiKit.draw_frame(self, rect, _panel())
	UiKit.draw_text(self, at + Vector2(0, -10), "WEAPONS", 15, UiColours.TEXT_DIM, UiKit.font_bold())
	if weapons_system:
		var capacity := ship.weapon_capacity() if ship.reactor_type != "pool" else weapons_system.usable_bars() - weapons_system.ion
		UiKit.draw_text(self, at + Vector2(90, -10), "%d / %d power" % [ship.powered_weapon_load(), maxi(0, capacity)], 14, UiColours.TEXT_DIM)
	for index in slots.size():
		var slot: WeaponSlot = slots[index]
		var slot_rect := Rect2(at + Vector2(index * (slot_size.x + 8), 0), slot_size)
		_draw_weapon_slot(ship, slot, ship.weapons.find(slot), slot_rect)
	var auto_rect := Rect2(at + Vector2(width - 16 - 150, slot_size.y + 6), Vector2(150, 30))
	_button(auto_rect, "AUTOFIRE", func(): screen.toggle_autofire(), "Autofire: weapons keep firing at their targets every time they charge. Hold Ctrl while aiming to do the opposite for that shot. Hotkey: V", true, screen.autofire_default)


func _draw_weapon_slot(ship: Ship, slot: WeaponSlot, index: int, rect: Rect2) -> void:
	var armed := screen.aim_slot == slot
	var needed := slot.charge_needed(ship.tech)
	var charge := clampf(slot.charge / maxf(1.0, needed), 0.0, 1.0)
	var border := UiColours.BORDER_DIM
	if armed:
		border = UiColours.ENEMY_RED if screen._aim_is_autofire() else UiColours.TARGET_YELLOW
	elif slot.powered and charge >= 1.0:
		border = UiColours.POWER_GREEN
	UiKit.draw_frame(self, rect, UiColours.PANEL_LIGHT if slot.powered else UiColours.PANEL_DARK, border, 7.0, 2.0 if armed else 1.5)
	UiKit.draw_text(self, rect.position + Vector2(10, 22), slot.def.short_name(), 16, UiColours.TEXT if slot.powered else UiColours.TEXT_DIM, UiKit.font_bold())
	UiKit.draw_text(self, rect.position + Vector2(rect.size.x - 10, 22), str(index + 1), 15, UiColours.TEXT_DIM, UiKit.font_bold(), HORIZONTAL_ALIGNMENT_RIGHT, 0)
	for pip in slot.def.power:
		draw_rect(Rect2(rect.position + Vector2(10 + pip * 13, 30), Vector2(10, 8)), UiColours.POWER_GREEN if slot.powered else UiColours.BAR_EMPTY)
	var bar := Rect2(rect.position + Vector2(10, rect.size.y - 22), Vector2(rect.size.x - 20, 10))
	draw_rect(bar, UiColours.BAR_EMPTY)
	if slot.powered:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * charge, bar.size.y)), UiColours.POWER_GREEN if charge >= 1.0 else Color("#e8e8e8"))
	var state := "OFF"
	if slot.powered:
		state = "READY" if charge >= 1.0 else "%.1fs" % ((needed - slot.charge) / 20.0)
		if slot.def.defensive and not slot.has_target() and charge >= 1.0:
			state = "DEFENDING"
	UiKit.draw_text(self, rect.position + Vector2(rect.size.x - 10, 42), state, 13, UiColours.POWER_GREEN if charge >= 1.0 and slot.powered else UiColours.TEXT_DIM, UiKit.font_bold(), HORIZONTAL_ALIGNMENT_RIGHT, 0)
	if slot.has_target():
		var mark_colour := UiColours.ENEMY_RED if slot.autofire else UiColours.TARGET_YELLOW
		draw_arc(rect.position + Vector2(rect.size.x - 22, 58), 7, 0, TAU, 16, mark_colour, 2.0, true)
	var tooltip := "%s\n%s\n%s\nCharge %.1f s · Power %d · %s Mawjig a volley\nClick to aim, then click a tile of an enemy ship. Right click to power on or off." % [slot.def.display_name(), slot.def.description, slot.def.stat_line(), needed / 20.0, slot.def.power, Mawjig.format(slot.def.cost_per_volley)]
	_region(rect, func(): screen.arm_weapon(slot), tooltip, func(): _toggle_weapon_power(ship, slot))


func _toggle_weapon_power(ship: Ship, slot: WeaponSlot) -> void:
	if ship.set_weapon_powered(slot, not slot.powered):
		Sfx.play("power_up" if slot.powered else "power_down")
	else:
		Sfx.play("deny")
		flash_message("Not enough weapon power.")


# --- Specials, the drive and the squad's resources -------------------------------------------------------------

## The special system buttons: boarding, suits, cloaking and the doors.
func _special_buttons(ship: Ship) -> Array:
	var buttons: Array = []
	var encounter := screen.encounter
	var teleporter := ship.system_by("teleporter")
	if teleporter:
		var ready := encounter.can_teleport(ship)
		buttons.append(["BOARD", func(): screen.start_teleport(), "Send the crew standing in the teleporter room to an enemy room. Hotkey: T", ready and encounter.in_fight(), ship.teleporter_cooldown])
		buttons.append(["RECALL", func(): screen.recall_boarders(), "Bring every boarder home.", ready, -1])
	var dock := ship.system_by("evb_dock")
	if dock:
		buttons.append(["LAUNCH SUIT", func(): screen.start_suit_launch(), "A crew member in the EVB Dock room suits up and flies out to fight an enemy ship. Each launch uses a new suit (%s Mawjig). Hotkey: E" % Mawjig.format(Library.weapon(ship.suits[0]).cost_per_volley if not ship.suits.is_empty() else 21), not ship.suit_out and ship.evb_cooldown <= 0 and encounter.in_fight(), ship.evb_cooldown])
	var cloak := ship.system_by("cloaking")
	if cloak:
		buttons.append(["CLOAK", func(): encounter.cloak(ship), "Hide the ship: most shots miss and its weapons hold their charge. Hotkey: C", ship.cloak_ticks <= 0 and ship.cloak_cooldown <= 0 and ship.system_power(cloak) > 0, ship.cloak_cooldown])
	if ship.has_system("doors"):
		buttons.append(["OPEN DOORS", func(): screen.set_all_doors(ship, true, false), "Open every inner door.", ship.doors_controllable(), -1])
		buttons.append(["CLOSE DOORS", func(): screen.set_all_doors(ship, false, false), "Close every door, airlocks too.", ship.doors_controllable(), -1])
		buttons.append(["VENT", func(): screen.set_all_doors(ship, true, true), "Open the airlocks to vent air and fires into space.", ship.doors_controllable(), -1])
	return buttons


func _draw_specials(ship: Ship, at: Vector2) -> void:
	var buttons := _special_buttons(ship)
	var width := 150.0
	var x := at.x + 10.0
	var y := at.y + 34.0
	var frame := Rect2(at, Vector2(width + 20, buttons.size() * 38.0 + 40))
	UiKit.draw_frame(self, frame, _panel())
	UiKit.draw_text(self, Vector2(x, y - 12), "SPECIALS", 15, UiColours.TEXT_DIM, UiKit.font_bold())
	for entry in buttons:
		var rect := Rect2(x, y, width, 32)
		_button(rect, entry[0], entry[1], entry[2], entry[3])
		if entry[4] > 0:
			draw_rect(Rect2(rect.position + Vector2(4, 28), Vector2((width - 8) * clampf(1.0 - entry[4] / 600.0, 0.0, 1.0), 3)), UiColours.ACCENT)
		y += 38


func _draw_top_centre(at: Vector2) -> void:
	var encounter := screen.encounter
	var rect := Rect2(at, Vector2(640, 74))
	var centre := rect.get_center().x
	UiKit.draw_frame(self, rect, _panel())
	# Mawjig
	var mawjig := screen.run.mawjig if screen.run else 0
	UiKit.draw_text(self, rect.position + Vector2(16, 26), "MAWJIG", 13, UiColours.TEXT_DIM, UiKit.font_bold())
	var mawjig_colour := LowMawjigWarning.counter_colour(mawjig, _time)
	UiKit.draw_text(self, rect.position + Vector2(16, 58), Mawjig.format(mawjig), 30, mawjig_colour, UiKit.font_title())
	if mawjig < LowMawjigWarning.DANGER:
		_draw_notice("LOW ON MAWJIG: every shot and every jump spends it", rect.end.y + 44, UiColours.DAMAGED_RED)
	_region(Rect2(rect.position, Vector2(140, 74)), Callable(), "Mawjig: the squad's fuel, ammunition and money in one. A jump costs 1.21; every shot costs a little.")
	# Jigawatt Drive
	var charge := encounter.squad_jump_charge()
	var fighting := encounter.in_fight()
	var drive_at := rect.position + Vector2(170, 12)
	UiKit.draw_text(self, drive_at + Vector2(0, 14), "JIGAWATT DRIVE", 13, UiColours.TEXT_DIM, UiKit.font_bold())
	var bar := Rect2(drive_at + Vector2(0, 24), Vector2(170, 14))
	draw_rect(bar, UiColours.BAR_EMPTY)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * charge, bar.size.y)), UiColours.ACCENT if charge < 1.0 else UiColours.POWER_GREEN)
	var drive_text := "READY" if charge >= 1.0 else ("CHARGING" if _any_charging() else "NEEDS PILOT + ENGINES")
	UiKit.draw_text(self, drive_at + Vector2(0, 56), drive_text, 12, UiColours.TEXT_DIM, UiKit.font_bold())
	var can_jump := encounter.can_squad_jump() and screen.hold_pause == false
	_button(Rect2(drive_at + Vector2(184, 6), Vector2(96, 44)), "JUMP", func(): screen.jump_pressed.emit(), "Open the map and jump the squad to another cluster (1.21 Mawjig). In a fight the drive must charge first, and needs a pilot. Hotkey: J", can_jump, can_jump and _time - floor(_time) < 0.5)
	_button(Rect2(drive_at + Vector2(288, 6), Vector2(66, 21)), "SHIP", func(): screen.ship_screen_pressed.emit(), "Upgrade systems, manage weapons and crew. Hotkey: U", not fighting)
	if fighting:
		_button(Rect2(drive_at + Vector2(288, 29), Vector2(66, 21)), "HAIL", func(): screen.hail_pressed.emit(), "Hail the enemy squad: ask for surrender, or offer terms.", true)
	elif screen.store_here:
		_button(Rect2(drive_at + Vector2(288, 29), Vector2(66, 21)), "STORE", func(): screen.store_pressed.emit(), "Trade at this cluster's store.", true)
	var pause_rect := Rect2(rect.end.x + 8, rect.position.y, 44, 32)
	_button(pause_rect, "", func(): screen.toggle_pause(), "Pause or unpause. Hotkey: Space", true, screen.paused)
	var middle := pause_rect.get_center()
	if screen.paused:
		draw_colored_polygon(PackedVector2Array([middle + Vector2(-6, -8), middle + Vector2(8, 0), middle + Vector2(-6, 8)]), UiColours.TEXT)
	else:
		draw_rect(Rect2(middle + Vector2(-7, -8), Vector2(5, 16)), UiColours.TEXT)
		draw_rect(Rect2(middle + Vector2(2, -8), Vector2(5, 16)), UiColours.TEXT)
	var menu_rect := Rect2(rect.end.x + 8, rect.position.y + 38, 44, 32)
	_button(menu_rect, "", func(): screen.menu_pressed.emit(), "Menu. Hotkey: Esc", true)
	for line in 3:
		draw_rect(Rect2(menu_rect.get_center() + Vector2(-9, -7 + line * 6), Vector2(18, 2.5)), UiColours.TEXT)
	if encounter.hazard != "":
		var hazard_text: String = {"asteroids": "ASTEROID FIELD", "sun": "CLOSE TO A STAR: FLARES", "nebula": "NEBULA: SENSORS BLIND", "ion_storm": "ION STORM: HALF POWER", "collapse_edge": "COLLAPSE EDGE: HULL SHEAR"}.get(encounter.hazard, "")
		UiKit.draw_text(self, Vector2(centre, rect.end.y + 22), hazard_text, 15, UiColours.WARNING, UiKit.font_bold(), HORIZONTAL_ALIGNMENT_CENTER, 0)


func _any_charging() -> bool:
	for ship in screen.encounter.living(0):
		if ship.can_charge_jump():
			return true
	return false


## Each enemy's hull, shields and state float beside it in the world (GDD 3B: a ship's information near the
## ship), so a squad of several reads at a glance. Squad-mates of the selected ship get the same.
func _draw_enemies() -> void:
	var encounter := screen.encounter
	for ship in encounter.ships:
		if ship.escaped:
			continue
		if ship.side == 1 and not encounter.fight_started:
			continue
		if ship.destroyed and ship.explosion_ticks > 60:
			continue
		if _draw_offscreen_marker(ship):
			continue
		if ship != screen.selected_ship:
			_draw_floating_status(ship)


## A ship out of view gets an arrow at the screen's edge pointing to it, with its name and hull; clicking the
## arrow flies the camera there. Returns false when the ship is on screen.
func _draw_offscreen_marker(ship: Ship) -> bool:
	var centre_world := screen.encounter.local_to_world(ship, Formation.hull_bounds(ship.design).get_center())
	var at: Vector2 = screen.world.get_global_transform_with_canvas() * centre_world
	if Rect2(Vector2.ZERO, size).grow(60.0).has_point(at):
		return false
	var inner := Rect2(Vector2(70, 110), size - Vector2(140, 280))
	var middle := inner.get_center()
	var direction := (at - middle).normalized()
	var reach_x := inner.size.x * 0.5 / maxf(absf(direction.x), 0.001)
	var reach_y := inner.size.y * 0.5 / maxf(absf(direction.y), 0.001)
	var point := middle + direction * minf(reach_x, reach_y)
	var colour := UiColours.POWER_GREEN if ship.side == 0 else UiColours.ENEMY_RED
	var side := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([point + direction * 18.0, point + side * 11.0, point - side * 11.0]), Color(colour, 0.9))
	var label_at := point - direction * 34.0
	var box := Rect2(label_at - Vector2(64, 18), Vector2(128, 36))
	draw_rect(box, Color(0.02, 0.035, 0.07, 0.85))
	draw_rect(box, Color(colour, 0.6), false, 1.0)
	UiKit.draw_text(self, box.position + Vector2(64, 15), ship.name, 12, UiColours.TEXT, UiKit.font_bold(), HORIZONTAL_ALIGNMENT_CENTER, 0)
	var fraction := float(ship.hull) / float(maxi(1, ship.max_hull))
	draw_rect(Rect2(box.position + Vector2(10, 23), Vector2(108, 5)), UiColours.BAR_EMPTY)
	draw_rect(Rect2(box.position + Vector2(10, 23), Vector2(108 * fraction, 5)), UiColours.hull_colour(fraction))
	_region(box.merge(Rect2(point - Vector2(18, 18), Vector2(36, 36))), func(): screen.focus_ship(ship), "%s is out of view. Click to fly there." % ship.name)
	return true


func _draw_floating_status(ship: Ship) -> void:
	var bounds := Formation.hull_bounds(ship.design)
	var floor_rect := ship.design.floor_rect()
	# Just past the ship's nose, in the open space toward the divider, where it hides nothing of the ship
	var local_anchor := Vector2(floor_rect.get_center().x, bounds.position.y - 18.0)
	var world_point := screen.encounter.local_to_world(ship, local_anchor)
	var at: Vector2 = screen.world.get_global_transform_with_canvas() * world_point
	var width := 230.0
	var rect := Rect2(at - Vector2(width * 0.5, 62 if ship.side == 0 else 0), Vector2(width, 62))
	rect.position.x = clampf(rect.position.x, PAD, size.x - width - PAD)
	rect.position.y = clampf(rect.position.y, 104.0, size.y - 240.0)
	var enemy := ship.side == 1
	var border := UiColours.ENEMY_RED if enemy and not ship.is_gone() else (UiColours.POWER_GREEN if not enemy else UiColours.BORDER_DIM)
	UiKit.draw_frame(self, rect, Color(0.04, 0.05, 0.09, 0.82) if not enemy else Color(0.14, 0.05, 0.07, 0.84), Color(border, 0.8), 6.0)
	var title := ship.name.to_upper()
	while UiKit.font_bold().get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x > width - 100.0 and title.length() > 4:
		title = title.substr(0, title.length() - 4) + "..."
	UiKit.draw_text(self, rect.position + Vector2(10, 19), title, 14, UiColours.TEXT, UiKit.font_bold())
	var state := ""
	if ship.destroyed:
		state = "DESTROYED"
	elif ship.crew_dead:
		state = "CREW LOST"
	elif ship.surrendered:
		state = "SURRENDERED"
	elif ship.charging_escape:
		state = "JUMPING %d%%" % int(ship.jump_charge * 100.0)
	elif ship.is_cloaked():
		state = "CLOAKED"
	else:
		state = "EVADE %d%%" % ship.evasion()
	UiKit.draw_text(self, rect.position + Vector2(width - 10, 19), state, 12, UiColours.WARNING if state != "EVADE %d%%" % ship.evasion() else UiColours.TEXT_DIM, UiKit.font_bold(), HORIZONTAL_ALIGNMENT_RIGHT, 0)
	var fraction := float(ship.hull) / maxf(1.0, ship.max_hull)
	var segment := (width - 20.0) / ship.max_hull
	for index in ship.max_hull:
		draw_rect(Rect2(rect.position + Vector2(10 + index * segment, 26), Vector2(maxf(1.0, segment - 1.5), 10)), UiColours.hull_colour(fraction) if index < ship.hull else UiColours.BAR_EMPTY)
	var pip_x := 10.0
	var layers := ship.system_by("shields").level / 2 if ship.system_by("shields") else 0
	for index in layers:
		draw_circle(rect.position + Vector2(pip_x + 6, 49), 6, UiColours.SHIELD_BLUE if index < ship.shield_layers else Color(0.15, 0.15, 0.25))
		pip_x += 16
	for index in (5 if ship.has_system("supershield") else 0):
		draw_circle(rect.position + Vector2(pip_x + 5, 49), 5, UiColours.SUPERSHIELD if index < ship.supershield else Color(0.25, 0.12, 0.22))
		pip_x += 13
	UiKit.draw_text(self, rect.position + Vector2(width - 10, 54), "%d/%d" % [ship.hull, ship.max_hull], 12, UiColours.TEXT_DIM, UiKit.font_bold(), HORIZONTAL_ALIGNMENT_RIGHT, 0)
	if enemy:
		_region(rect, func(): _look_at(ship), "%s (%s)\n%s\nHull %d / %d. Click to look at it." % [ship.name, ship.design.class_text, ship.design.description, ship.hull, ship.max_hull])
	else:
		_region(rect, func(): screen.select_ship(ship), "%s: click to select this ship." % ship.name)


func _look_at(ship: Ship) -> void:
	screen.focus_ship(ship)


func _draw_overlays() -> void:
	var centre := size * 0.5
	if screen.paused:
		var text := "PAUSED"
		UiKit.draw_text(self, Vector2(centre.x, 150), text, 44, Color(0.9, 0.95, 1.0, 0.9), UiKit.font_title(), HORIZONTAL_ALIGNMENT_CENTER, 0)
		UiKit.draw_text(self, Vector2(centre.x, 178), "press Space to resume", 17, UiColours.TEXT_DIM, null, HORIZONTAL_ALIGNMENT_CENTER, 0)
	if screen.aim_mode != "":
		var hint: String = {"weapon": "Click a tile of an enemy ship to aim. Right click cancels.", "beam": "Press on an enemy tile and drag to aim the beam's sweep.", "teleport": "Click an enemy room to send boarders.", "suit": "Click an enemy ship to send the battlesuit."}.get(screen.aim_mode, "")
		_draw_notice(hint, size.y - 300, UiColours.TARGET_YELLOW)
		var mouse := get_local_mouse_position()
		var colour := UiColours.ENEMY_RED if screen._aim_is_autofire() else UiColours.TARGET_YELLOW
		draw_arc(mouse, 14, 0, TAU, 24, colour, 2.0, true)
		for step in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			draw_line(mouse + step * 8, mouse + step * 20, colour, 2.0)
	if _message_time > 0.0:
		var alpha := clampf(_message_time, 0.0, 1.0)
		_draw_notice(_message, size.y - 250, UiColours.WARNING, alpha)
	if box_rect.size.length() > 4.0:
		draw_rect(box_rect, Color(UiColours.POWER_GREEN, 0.12))
		draw_rect(box_rect, Color(UiColours.POWER_GREEN, 0.8), false, 1.5)
	if screen.hover_ship and screen.hover_room >= 0 and _hover_region.is_empty() and screen.aim_mode == "":
		_draw_room_info(screen.hover_ship, screen.hover_room)


## A line of text on a dark plate, centred on the screen, so it reads over any ship or star.
func _draw_notice(text: String, baseline: float, colour: Color, alpha: float = 1.0) -> void:
	var font := UiKit.font_bold()
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
	var plate := Rect2(size.x * 0.5 - width * 0.5 - 18, baseline - 24, width + 36, 34)
	draw_rect(plate, Color(0.02, 0.035, 0.07, 0.88 * alpha))
	draw_rect(plate, Color(colour, 0.55 * alpha), false, 1.5)
	UiKit.draw_text(self, Vector2(size.x * 0.5, baseline), text, 19, Color(colour, alpha), font, HORIZONTAL_ALIGNMENT_CENTER, 0)


## What the mouse is over inside a ship: on a console tile just that system, elsewhere the room and what is in it.
func _draw_room_info(ship: Ship, room_index: int) -> void:
	var room := ship.rooms[room_index]
	var view: ShipView = screen.views.get(ship)
	if view == null or (ship.side == 1 and not view.interior_visible):
		return
	var lines := PackedStringArray()
	var console: ShipSystem = null
	for system in room.systems:
		if system.cell == screen.hover_cell:
			console = system
	if console:
		lines.append(console.display_name())
		lines.append("Level %d · power %d" % [console.level, ship.system_power(console)])
		if console.damage > 0:
			lines.append("%d bar%s damaged" % [console.damage, "" if console.damage == 1 else "s"])
		if console.ion > 0:
			lines.append("Ionized")
		if console.spored:
			lines.append("Spored")
		if console.def.manned:
			lines.append("Manned by %s" % console.manned_by.name if console.manned_by else "Unmanned")
	else:
		lines.append(room.name if not room.name.is_empty() else "Room")
		if not room.systems.is_empty():
			var names := PackedStringArray()
			for system in room.systems:
				names.append(system.display_name() + (" (damaged)" if system.damage > 0 else ""))
			lines.append("Systems here: " + ", ".join(names))
	lines.append("Air %d%%" % int(room.oxygen * 100.0))
	if room.is_burning():
		lines.append("On fire")
	if room.is_breached():
		lines.append("Hull breach")
	if room.infection > 0.0:
		lines.append("Infected")
	var font := UiKit.font_regular()
	var width := 0.0
	for line in lines:
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x)
	var at := get_local_mouse_position() + Vector2(22, 18)
	var box := Rect2(at, Vector2(width + 18, lines.size() * 20 + 10))
	box.position.x = minf(box.position.x, size.x - box.size.x - 8)
	box.position.y = minf(box.position.y, size.y - box.size.y - 8)
	draw_rect(box, Color(0.02, 0.04, 0.08, 0.88))
	draw_rect(box, UiColours.BORDER_DIM, false, 1.0)
	for index in lines.size():
		UiKit.draw_text(self, box.position + Vector2(9, 20 + index * 20), lines[index], 15, UiColours.TEXT if index == 0 else UiColours.TEXT_DIM)


func _draw_tooltip() -> void:
	if _hover_region.is_empty() or _hover_time < 0.35 or String(_hover_region.tooltip).is_empty():
		return
	var text: String = _hover_region.tooltip
	var font := UiKit.font_regular()
	var width := 420.0
	var lines := PackedStringArray()
	for paragraph in text.split("\n"):
		var line := ""
		for word in paragraph.split(" "):
			var candidate := word if line.is_empty() else line + " " + word
			if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x > width - 20:
				lines.append(line)
				line = word
			else:
				line = candidate
		lines.append(line)
	var height := lines.size() * 21 + 14
	var at := get_local_mouse_position() + Vector2(18, -height - 10)
	at.x = clampf(at.x, 8, size.x - width - 8)
	at.y = clampf(at.y, 8, size.y - height - 8)
	UiKit.draw_frame(self, Rect2(at, Vector2(width, height)), Color(0.02, 0.035, 0.07, 0.96), UiColours.BORDER, 8.0)
	for index in lines.size():
		UiKit.draw_text(self, at + Vector2(10, 22 + index * 21), lines[index], 16, UiColours.TEXT if index == 0 else UiColours.TEXT_DIM, UiKit.font_bold() if index == 0 else null)
