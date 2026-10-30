## The battle: both ships' systems, the hand, the log and the turn controls. It turns the captain's clicks into
## Battle actions, animates the events each action returns, and runs the enemy captain's turns.
class_name BattleScreen
extends Control

signal finished(choice: String)

const PLAYER := 0
const ENEMY := 1
const LOG_WIDTH := 330.0
const SIDE_PANEL_WIDTH := 300.0

var battle: Battle
var enemy_captain: BattleAI
## For testing: the AI plays the player's side as well.
var autoplay := false
var _player_autopilot: BattleAI
var player_design: ShipDesign
var enemy_design: ShipDesign
## The run this battle belongs to, for showing rewards. The screen never changes it; main records the result.
var run: RunState

# What the captain is doing right now.
var _busy := false
var _targeting_uid := -1
var _targeting_crew := -1
## Systems already aimed at, one per bolt, while aiming a multi-target weapon.
var _aimed_bolts: Array = []
## Teleport: the bay has been clicked; the next system clicked is where its crew go.
var _teleport_from_bay := false
## A battlesuit of yours picked to recall: its index in your ship's suits, or -1.
var _selected_suit := -1
var _suit_layer: SuitLayer
var _moving_crew := -1
var _hover_info := ""

# Nodes
var _starfield: Starfield
var _fx: FxLayer
var _headers: Array[ShipHeader] = []
var _tile_rows: Array[HBoxContainer] = []
var _tiles := [{}, {}]
var _hand: HandView
var _enemy_hand_row: HBoxContainer
var _enemy_hand_label: Label
var _log: RichTextLabel
var _info: RichTextLabel
var _end_turn_button: Button
var _reroute_button: Button
var _jump_button: Button
var _turn_label: Label
var _stage: Control
var _overlay: Control
var _crew_popup: Control
var _log_file := BattleLogFile.new()


## carry: the player's ship state from the run's last battle (empty for a fresh ship).
func start(player: ShipDesign, enemy: ShipDesign, carry: Dictionary = {}, the_run: RunState = null) -> void:
	player_design = player
	enemy_design = enemy
	run = the_run
	var first := randi() % 2
	match Settings.value("first_turn"):
		"You": first = PLAYER
		"Enemy": first = ENEMY
	battle = Battle.new(player, enemy, first, 0, carry)
	enemy_captain = BattleAI.new(Settings.value("ai_level"))
	_player_autopilot = BattleAI.new("Normal")
	_log_file.open(battle)
	_build()
	_refresh()
	await get_tree().process_frame
	await _play_events(battle.opening_events)
	_refresh()
	await _run_ai_turns()


# ---------------------------------------------------------------- layout

func _build() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_starfield = Starfield.new()
	_starfield.collapse_center = Vector2(0.9, 0.47)
	_starfield.collapse_size = 0.55
	add_child(_starfield)

	var column := UiKit.vbox(8)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 14
	column.offset_right = -14
	column.offset_top = 10
	add_child(column)

	for side in [ENEMY, PLAYER]:
		var header := ShipHeader.new()
		header.battle = battle
		header.ship_side = side
		header.viewer_side = PLAYER
		_headers.append(header)
	_headers.reverse()  # index by side: [player, enemy]

	column.add_child(_headers[ENEMY])
	_tile_rows = [HBoxContainer.new(), HBoxContainer.new()]
	for side in 2:
		_tile_rows[side].alignment = BoxContainer.ALIGNMENT_CENTER
		_tile_rows[side].add_theme_constant_override("separation", 8)
		for system_id in battle.ships[side].system_order:
			var tile := SystemTile.new().setup(battle, side, system_id, PLAYER)
			tile.tile_clicked.connect(_on_tile_clicked)
			tile.crew_clicked.connect(_on_crew_clicked)
			tile.burn_clicked.connect(func(_t): _act(func(): return battle.burn_engines(PLAYER)))
			tile.treat_clicked.connect(func(_t): _act(func(): return battle.treat(PLAYER)))
			tile.hovered.connect(_on_tile_hovered)
			tile.crew_hovered.connect(_on_crew_hovered)
			_tile_rows[side].add_child(tile)
			_tiles[side][system_id] = tile
	column.add_child(_tile_rows[ENEMY])

	# Middle band: log, enemy hand, turn controls.
	var middle := UiKit.hbox(12)
	middle.custom_minimum_size = Vector2(0, 140)
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(middle)
	var log_panel := UiKit.panel(Color(0.05, 0.07, 0.12, 0.88))
	log_panel.custom_minimum_size = Vector2(LOG_WIDTH, 0)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 13)
	_log.add_theme_font_size_override("bold_font_size", 13)
	log_panel.add_child(_log)
	middle.add_child(log_panel)

	var center := UiKit.vbox(2)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_hand_label = UiKit.label("ENEMY HAND", 12, UiKit.MUTED, UiKit.display_font)
	_enemy_hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_enemy_hand_label)
	_enemy_hand_row = HBoxContainer.new()
	_enemy_hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_hand_row.add_theme_constant_override("separation", -12)
	center.add_child(_enemy_hand_row)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.add_theme_font_size_override("normal_font_size", 14)
	_info.add_theme_font_size_override("bold_font_size", 14)
	center.add_child(_info)
	middle.add_child(center)

	var controls := UiKit.vbox(6)
	controls.custom_minimum_size = Vector2(SIDE_PANEL_WIDTH, 0)
	_turn_label = UiKit.heading("", 22, UiKit.GOOD)
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(_turn_label)
	_end_turn_button = UiKit.primary_button("END TURN", _on_end_turn, 22)
	_end_turn_button.custom_minimum_size = Vector2(0, 46)
	controls.add_child(_end_turn_button)
	var small_row := UiKit.hbox(6)
	_reroute_button = UiKit.button("Reroute", _on_reroute, 14)
	_reroute_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reroute_button.tooltip_text = "Reroute Power. Only if you played no cards this turn: put a Power Cell from your deck into play, shuffle, and end your turn."
	small_row.add_child(_reroute_button)
	_jump_button = UiKit.button("Jump", _on_jump, 14)
	_jump_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_jump_button.tooltip_text = "Jump away once the Jig Drive is charged: it charges each turn you burn power in Engines. Needs Piloting working and manned (or Auto Pilot)."
	small_row.add_child(_jump_button)
	var menu_button := UiKit.button("Menu", _on_menu, 14)
	small_row.add_child(menu_button)
	controls.add_child(small_row)
	middle.add_child(controls)

	# Your hand sits between the centre and your ship, so hovered cards rise into the open middle.
	_hand = HandView.new()
	_hand.custom_minimum_size = Vector2(0, 222)
	_hand.card_clicked.connect(_on_card_clicked)
	_hand.card_hovered.connect(_on_card_hovered)
	column.add_child(_hand)
	column.add_child(_tile_rows[PLAYER])
	column.add_child(_headers[PLAYER])
	var bottom_gap := Control.new()
	bottom_gap.custom_minimum_size = Vector2(0, 2)
	column.add_child(bottom_gap)

	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.z_index = 90
	add_child(_stage)
	_suit_layer = SuitLayer.new()
	_suit_layer.battle = battle
	_suit_layer.tiles = _tiles
	_suit_layer.player_side = PLAYER
	_suit_layer.z_index = 85
	_suit_layer.suit_clicked.connect(_on_suit_clicked)
	_suit_layer.recall_clicked.connect(func(index):
		_selected_suit = -1
		_suit_layer.selected = -1
		_act(func(): return battle.recall_suit(PLAYER, index)))
	add_child(_suit_layer)
	_fx = FxLayer.new()
	_fx.z_index = 100
	add_child(_fx)
	_fit_tiles()
	resized.connect(_fit_tiles)


## Shrinks system tiles when a ship has too many to fit across the screen.
func _fit_tiles() -> void:
	for side in 2:
		var count := battle.ships[side].system_order.size()
		var available := size.x - 28.0
		var needed := count * (SystemTile.TILE_SIZE.x + 8.0)
		var tile_scale := clampf(available / needed, 0.6, 1.0)
		for tile in _tiles[side].values():
			tile.custom_minimum_size = SystemTile.TILE_SIZE * tile_scale
			tile.scale = Vector2.ONE * tile_scale
			tile.pivot_offset = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	var cancel: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	cancel = cancel or event.is_action_pressed("ui_cancel")
	if cancel:
		_cancel_selection()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and not _busy:
		_on_end_turn()


# ---------------------------------------------------------------- drawing the state

func _refresh() -> void:
	var targets := _current_targets()
	for side in 2:
		for system_id in _tiles[side]:
			var tile: SystemTile = _tiles[side][system_id]
			tile.highlight = ""
			tile.selected_crew_id = _moving_crew if _moving_crew >= 0 else _targeting_crew
			tile.choosable_crew = []
			tile.bolts_aimed = _aimed_bolts.count(system_id) if side != PLAYER else 0
			for target in targets:
				var aim_system: String = target.get("to_system", target.get("system", "")) if _teleport_from_bay else target.get("system", "")
				var aim_ship := int(target.get("to_ship", target.get("ship", -1))) if _teleport_from_bay else int(target.get("ship", -1))
				if aim_system != "" and aim_ship == side and aim_system == system_id:
					tile.highlight = "target"
				elif not target.has("system") and target.has("crew"):
					tile.choosable_crew.append(target.crew)
			if _moving_crew >= 0:
				var member := battle.crew_by_id(_moving_crew)
				if battle.why_cannot_move(PLAYER, member, system_id) == "" and member.ship == side:
					tile.highlight = "move"
	_hand.deck_point = _headers[PLAYER].global_position + Vector2(_headers[PLAYER].size.x - 60, 30)
	_hand.show_hand(battle.ships[PLAYER].hand, battle, PLAYER,
		func(card): return battle.why_cannot_play_anywhere(PLAYER, card.uid) if battle.active_side == PLAYER else "not your turn", _targeting_uid)
	_refresh_enemy_hand()
	_refresh_beaten_enemy()
	var my_turn := battle.active_side == PLAYER and not battle.over
	_turn_label.text = "YOUR TURN" if my_turn else ("ENEMY TURN" if not battle.over else "BATTLE OVER")
	if battle.aftermath and not battle.over:
		_turn_label.text = "ENEMY BEATEN"
	_turn_label.add_theme_color_override("font_color", UiKit.GOOD if my_turn else Color("#FF8500"))
	_end_turn_button.disabled = not my_turn or _busy
	_reroute_button.disabled = not my_turn or _busy or battle.why_cannot_reroute(PLAYER) != ""
	var ship := battle.ships[PLAYER]
	_jump_button.text = "JUMP %d/%d" % [ship.jump_charge, battle.jump_charges_needed()]
	var jump_reason := battle.why_cannot_jump(PLAYER)
	_jump_button.disabled = not my_turn or _busy or jump_reason != ""
	_jump_button.tooltip_text = "Jump away. " + (jump_reason if jump_reason != "" else "Ready!")
	if not _jump_button.disabled:
		_jump_button.add_theme_color_override("font_color", UiKit.GOOD)
	else:
		_jump_button.remove_theme_color_override("font_color")
	_refresh_info()


## Once the enemy is beaten its bar is stamped, its hand is gone, and a destroyed ship's systems show as wrecked.
## A ship whose crew is lost keeps its systems, since your boarders may still be aboard.
func _refresh_beaten_enemy() -> void:
	if not battle.aftermath:
		return
	var loser := 1 - battle.winner
	_headers[loser].stamp = {Battle.OUTCOME_DESTROYED: "DESTROYED", Battle.OUTCOME_CREW_LOST: "DERELICT",
		Battle.OUTCOME_ESCAPED: "FLED"}.get(battle.outcome, "BEATEN")
	for tile in _tiles[loser].values():
		tile.wrecked = battle.outcome == Battle.OUTCOME_DESTROYED
	_enemy_hand_row.visible = false
	_enemy_hand_label.text = "ENEMY %s" % _headers[loser].stamp


func _refresh_enemy_hand() -> void:
	for child in _enemy_hand_row.get_children():
		child.queue_free()
	var enemy := battle.ships[ENEMY]
	var view := battle.sensor_view(PLAYER)
	var shown := 0
	for card in enemy.hand:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(48, 66)
		var card_view := CardView.new()
		card_view.scale = Vector2.ONE * 0.26
		card_view.custom_minimum_size = Vector2.ZERO
		card_view.mouse_filter = Control.MOUSE_FILTER_PASS
		var visible: bool = view.hand or (view.weapons and card.id == "weapon")
		card_view.face_down = not visible
		card_view.owner_color = enemy.color
		if visible:
			card_view.setup(card, battle.card_definition(enemy, card))
			card_view.tooltip_text = battle.card_definition(enemy, card).name
			shown += 1
		holder.add_child(card_view)
		_enemy_hand_row.add_child(holder)
	var note := ""
	if not view.weapons:
		note = " · Sensors 3 shows their weapons"
	elif not view.hand:
		note = " · man Sensors 3 to see all"
	_enemy_hand_label.text = "ENEMY HAND  %d%s" % [enemy.hand.size(), note]


func _refresh_info() -> void:
	if _hover_info != "":
		_info.text = _hover_info
		return
	_info.text = "[center]%s[/center]" % _instruction()


## What the captain can do right now, so the game teaches itself.
func _instruction() -> String:
	if battle.over:
		return ""
	if battle.active_side != PLAYER:
		return "[color=#ff8500]The enemy captain is acting…[/color]"
	if _targeting_uid >= 0:
		var card := _card_in_hand(_targeting_uid)
		var definition := battle.card_definition(battle.ships[PLAYER], card)
		match definition.target:
			CardLibrary.TARGET_ENEMY_SYSTEM:
				var ship := battle.ships[PLAYER]
				var bolts := battle.bolts_to_aim(ship, card)
				if bolts > 1:
					return "[b]%s[/b]: click an [color=#ffb347]enemy system[/color] for bolt %d of %d (the same one again is fine). Right-click to cancel." % [
						definition.name, _aimed_bolts.size() + 1, bolts]
				if battle.beam_rooms(ship, card) > 1:
					return "[b]%s[/b]: click an [color=#ffb347]enemy system[/color]. Click its left or right half to sweep the beam that way. Right-click to cancel." % definition.name
				return "[b]%s[/b]: click a glowing [color=#ffb347]enemy system[/color] to aim. Right-click to cancel." % definition.name
			CardLibrary.TARGET_OWN_SYSTEM:
				return "[b]%s[/b]: click one of [color=#ffb347]your systems[/color]. Right-click to cancel." % definition.name
			CardLibrary.TARGET_TELEPORT:
				if _teleport_from_bay:
					return "[b]Teleport[/b]: click the system on either ship to send the bay's crew to. Right-click to cancel."
				return "[b]Teleport[/b]: click your [color=#ffb347]Teleport Bay[/color] to send its crew, or a system with your crew in it to bring them back. Right-click to cancel."
			CardLibrary.TARGET_CREW_THEN_SYSTEM:
				if _targeting_crew < 0:
					return "[b]%s[/b]: click a ringed [color=#ffb347]crew member[/color]. Right-click to cancel." % definition.name
				return "[b]%s[/b]: now click the system to send them to." % definition.name
	if _moving_crew >= 0:
		return "Click a [color=#66ff66]green system[/color] to move %s there. Right-click to cancel." % battle.crew_by_id(_moving_crew).name
	var ship := battle.ships[PLAYER]
	if battle.aftermath:
		if battle.why_cannot_jump(PLAYER) == "":
			return "[color=#66ff66]Jig Drive ready.[/color] Finish repairs and healing, then press [b]JUMP[/b] to leave."
		return "The enemy is beaten. Repair, send the wounded to the Med Bay, and get Engines and Piloting working to charge the Jig Drive (%d/%d)." % [ship.jump_charge, battle.jump_charges_needed()]
	if ship.hand.any(func(c): return c.id == "power"):
		return "Play [color=#ffc247]Power Cells[/color] to build up power, then spend it on your cards. Click your crew to move them between systems."
	if ship.available_power() == 0 and ship.power_row.is_empty():
		return "No power yet. [b]Reroute Power[/b] brings a Power Cell from your deck into play and ends your turn."
	return "Click a card to play it. Crew in a system boost its cards. [b]Space[/b] or END TURN when you're done."


# ---------------------------------------------------------------- captain input

func _on_card_clicked(card: Dictionary) -> void:
	if _busy or battle.active_side != PLAYER:
		return
	if _targeting_uid == card.uid:
		_cancel_selection()
		return
	_moving_crew = -1
	var reason := battle.why_cannot_play(PLAYER, card.uid)
	if reason != "":
		_refuse(reason, _hand.card_center(card.uid))
		return
	var definition := battle.card_definition(battle.ships[PLAYER], card)
	if definition.target == CardLibrary.TARGET_NONE:
		_act(func(): return battle.play_card(PLAYER, card.uid, {}))
		return
	_targeting_uid = card.uid
	_targeting_crew = -1
	_aimed_bolts.clear()
	_teleport_from_bay = false
	if battle.valid_targets(PLAYER, card.uid).is_empty():
		_targeting_uid = -1
		_refuse("No valid target for %s right now." % definition.name, _hand.card_center(card.uid))
		return
	Sounds.play("click")
	_refresh()


func _on_tile_clicked(tile: SystemTile) -> void:
	if _busy or battle.active_side != PLAYER:
		return
	var target := {"system": tile.system_id, "ship": tile.ship_side}
	if _targeting_uid >= 0:
		var card := _card_in_hand(_targeting_uid)
		var definition := battle.card_definition(battle.ships[PLAYER], card)
		if definition.target == CardLibrary.TARGET_ENEMY_SYSTEM and tile.ship_side == PLAYER:
			# Clicking your own ship while aiming at the enemy changes your mind.
			_cancel_selection()
			return
		if definition.target == CardLibrary.TARGET_CREW_THEN_SYSTEM:
			if _targeting_crew < 0:
				_refuse("Pick a crew member first.", tile.global_position + tile.size / 2.0)
				return
			target.crew = _targeting_crew
		if definition.target == CardLibrary.TARGET_TELEPORT:
			var bay := battle.ships[PLAYER].first_system_of_type("teleport")
			if _teleport_from_bay:
				target = {"system": bay, "ship": PLAYER, "to_system": tile.system_id, "to_ship": tile.ship_side}
			elif tile.ship_side == PLAYER and tile.system_id == bay:
				if battle.teleport_senders(PLAYER).is_empty():
					_refuse("Nobody of yours is free in the Teleport Bay.", tile.global_position + tile.size / 2.0)
					return
				_teleport_from_bay = true
				Sounds.play("click")
				_refresh()
				return
		var reason := battle.why_cannot_play(PLAYER, _targeting_uid, target)
		if reason != "":
			_refuse(reason, tile.global_position + tile.size / 2.0)
			return
		var ship := battle.ships[PLAYER]
		if battle.beam_rooms(ship, card) > 1:
			target.direction = _sweep_direction(tile)
		var bolts := battle.bolts_to_aim(ship, card)
		if bolts > 1:
			_aimed_bolts.append(tile.system_id)
			if _aimed_bolts.size() < bolts:
				Sounds.play("click")
				_refresh()
				return
			target.systems = _aimed_bolts.duplicate()
		var uid := _targeting_uid
		_targeting_uid = -1
		_targeting_crew = -1
		_aimed_bolts.clear()
		_teleport_from_bay = false
		_act(func(): return battle.play_card(PLAYER, uid, target))
		return
	if _moving_crew >= 0:
		var member := battle.crew_by_id(_moving_crew)
		var reason := battle.why_cannot_move(PLAYER, member, tile.system_id)
		if reason == "" and member.ship != tile.ship_side:
			reason = "%s can only move within the ship they're on." % member.name
		if reason != "":
			_refuse(reason, tile.global_position + tile.size / 2.0)
			return
		var crew_id := _moving_crew
		_moving_crew = -1
		_act(func(): return battle.move_crew(PLAYER, crew_id, tile.system_id))


func _on_crew_clicked(tile: SystemTile, crew_id: int) -> void:
	if _busy or battle.active_side != PLAYER:
		return
	if _targeting_uid >= 0:
		var card := _card_in_hand(_targeting_uid)
		var definition := battle.card_definition(battle.ships[PLAYER], card)
		if definition.target == CardLibrary.TARGET_CREW_THEN_SYSTEM and _targeting_crew < 0:
			var choices := battle.valid_targets(PLAYER, _targeting_uid)
			if not choices.any(func(t): return t.get("crew", -1) == crew_id and not t.has("system")):
				_refuse("Not a valid crew member for %s." % definition.name, tile.crew_token_center(crew_id))
				return
			# Freeing your own mind-controlled crew needs no system.
			if battle.why_cannot_play(PLAYER, _targeting_uid, {"crew": crew_id}) == "":
				var uid := _targeting_uid
				_targeting_uid = -1
				_act(func(): return battle.play_card(PLAYER, uid, {"crew": crew_id}))
				return
			_targeting_crew = crew_id
			Sounds.play("click")
			_refresh()
			return
		_on_tile_clicked(tile)
		return
	var member := battle.crew_by_id(crew_id)
	if member.owner != PLAYER:
		_on_tile_clicked(tile)
		return
	if _moving_crew == crew_id:
		_cancel_selection()
		return
	if _moving_crew >= 0:
		_on_tile_clicked(tile)
		return
	var reason := battle.why_cannot_move(PLAYER, member, "")
	if reason.begins_with("No such system"):
		reason = ""
	if reason != "":
		_refuse(reason, tile.crew_token_center(crew_id))
		return
	_moving_crew = crew_id
	Sounds.play("click")
	_refresh()


## Clicking one of your battlesuits picks it and shows its RECALL button; clicking it again unpicks it. Enemy suits
## just explain themselves.
func _on_suit_clicked(side: int, index: int) -> void:
	var suit: Dictionary = battle.ships[side].suits[index]
	var kind := Catalog.suit_kind(suit.kind)
	var pilot := battle.crew_by_id(suit.pilot)
	var pilot_name: String = pilot.get("name", "?")
	if side != PLAYER or _busy or battle.active_side != PLAYER:
		_hover_info = "[center][b]%s[/b], flown by %s. %d turn%s of air left.[/center]" % [kind.name, pilot_name,
			suit.turns_left, "" if suit.turns_left == 1 else "s"]
		_refresh_info()
		return
	if _selected_suit == index:
		_selected_suit = -1
		_suit_layer.selected = -1
		return
	_cancel_selection()
	_selected_suit = index
	_suit_layer.selected = index
	Sounds.play("click")
	_hover_info = "[center][b]%s[/b], flown by %s: %d turn%s of air left%s. Press [color=#ffb347]RECALL[/color] to bring it home (it docks as your turn ends).[/center]" % [
		kind.name, pilot_name, suit.turns_left, "" if suit.turns_left == 1 else "s", ", damaged" if suit.damaged else ""]
	_refresh_info()


func _on_card_hovered(card: Dictionary, is_hovered: bool) -> void:
	if not is_hovered:
		_hover_info = ""
	else:
		var reason := battle.why_cannot_play_anywhere(PLAYER, card.uid) if battle.active_side == PLAYER else ""
		var definition := battle.card_definition(battle.ships[PLAYER], card)
		_hover_info = "[center][b]%s[/b] — %s%s[/center]" % [definition.name, definition.text,
			"" if reason == "" else "\n[color=#ff7a7a]%s[/color]" % reason]
	_refresh_info()


func _on_tile_hovered(tile: SystemTile, is_hovered: bool) -> void:
	if not is_hovered:
		_hover_info = ""
		_refresh_info()
		return
	var ship := battle.ships[tile.ship_side]
	var system: Dictionary = ship.systems[tile.system_id]
	var definition: Dictionary = Catalog.systems[system.type]
	var lines: Array[String] = []
	var title := "[b]%s[/b] (%s) · level %d" % [system.name, "yours" if tile.ship_side == PLAYER else "enemy", system.level]
	if system.damage > 0:
		title += " · [color=#ff4d5e]%d damaged[/color]" % system.damage
	if system.disabled_turns > 0 and system.type != "reactor":
		title += " · [color=#62d0ff]offline[/color]"
	lines.append(title)
	var summary: String = definition.summary
	if system.type == "weapon":
		summary = "Power %d a turn. " % system.level + " ".join(system.weapons.map(func(w): return "[b]%s[/b]: %s (%d card%s)." % [
			w.name, Weapons.summary(w), w.speed, "" if w.speed == 1 else "s"]))
	elif system.type == "evb":
		summary = "Power %d a turn; suits get %d turns of air. " % [system.level, CardLibrary.suit_air(system.level)] + " ".join(
			system.suits.map(func(id): return "[b]%s[/b]: %s" % [Catalog.suit_kind(id).name, Catalog.suit_kind(id).summary]))
	lines.append(summary)
	var hazards: Array[String] = []
	if system.on_fire:
		hazards.append("[color=#ff7a2a]On fire: 1 system damage and a wound to everyone inside each turn.[/color]")
	if system.breached:
		hazards.append("[color=#ff4d5e]Breached: no air; everyone inside takes a wound each turn. A Repair seals it.[/color]")
	if system.get("spored", false):
		hazards.append("[color=#7dffb0]Spores: offline until a Repair clears them.[/color]")
	if not system.breached and not battle.room_has_air(ship, tile.system_id):
		hazards.append("[color=#9fd8ff]No air: everyone inside takes a wound each turn.[/color]")
	if battle.has_hostiles(tile.ship_side, tile.system_id):
		hazards.append("[color=#ff4d5e]Enemies inside: it can't be repaired.[/color]")
	hazards.append("Air %d/%d." % [system.air, ship.air_max])
	var draw_chance := battle.bonus_draw_chance(ship, tile.system_id)
	if draw_chance > 0.0:
		hazards.append("Extra card chance %d%% a turn." % roundi(draw_chance))
	if definition.mannable:
		hazards.append("Crew here give a bonus.")
	if not hazards.is_empty():
		lines.append(" ".join(hazards))
	_hover_info = "[center]%s[/center]" % "\n".join(lines)
	_refresh_info()


## Hovering a crew token shows who they are: health, what they're doing and their six skills.
func _on_crew_hovered(tile: SystemTile, crew_id: int) -> void:
	if _crew_popup:
		_crew_popup.queue_free()
		_crew_popup = null
	var member := battle.crew_by_id(crew_id)
	if member.is_empty():
		return
	var owner_color := battle.ships[member.owner].color
	var panel := UiKit.panel(Color("#0d1220"), owner_color.darkened(0.2), 8)
	panel.z_index = 95
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UiKit.vbox(6)
	panel.add_child(box)
	var race := Catalog.race(member.race)
	box.add_child(UiKit.label(member.name, 17, UiKit.TEXT, UiKit.display_bold_font))
	var status: Array[String] = ["%s %s" % ["Your" if member.owner == PLAYER else "Enemy", race.name],
		"health %s/%d" % [str(snappedf(member.max_health - member.wounds, 0.1)), member.max_health]]
	if member.controlled_by >= 0:
		status.append("mind controlled")
	if member.stunned:
		status.append("stunned")
	if member.leaving_to != "":
		status.append("forcing doors (%d turn%s)" % [member.leaving_turns, "" if member.leaving_turns == 1 else "s"])
	if member.owner == battle.active_side:
		if member.moved:
			status.append("moved this turn")
		if member.acted:
			status.append("acted this turn")
	box.add_child(UiKit.label(" · ".join(status), 13, UiKit.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for skill in CrewSkills.NAMES:
		grid.add_child(SkillChip.new().setup(skill, int(member.skills.get(skill, 0)), false, float(member.xp.get(skill, 0.0))))
	box.add_child(grid)
	add_child(panel)
	_crew_popup = panel
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	var anchor := tile.crew_token_center(crew_id)
	var popup_size := panel.get_combined_minimum_size()
	var at := anchor + Vector2(18, -popup_size.y - 14)
	at.x = clampf(at.x, 8, size.x - popup_size.x - 8)
	at.y = clampf(at.y, 8, size.y - popup_size.y - 8)
	panel.position = at


func _cancel_selection() -> void:
	if _targeting_uid >= 0 or _moving_crew >= 0:
		_targeting_uid = -1
		_targeting_crew = -1
		_aimed_bolts.clear()
		_teleport_from_bay = false
		_selected_suit = -1
		if _suit_layer:
			_suit_layer.selected = -1
		_moving_crew = -1
		Sounds.play("click", -6.0)
		_refresh()


## Which way a beam clicked on this tile sweeps: left half -1, right half 1.
func _sweep_direction(tile: SystemTile) -> int:
	return -1 if tile.get_local_mouse_position().x < SystemTile.TILE_SIZE.x / 2.0 else 1


## While aiming a sweeping beam, the tiles under the mouse's sweep show the beam's path.
func _process(_delta: float) -> void:
	if battle == null:
		return
	var enemy_side := 1 - PLAYER
	var swept: Array = []
	var direction := 0
	if _targeting_uid >= 0 and not _busy:
		var card := _card_in_hand(_targeting_uid)
		var rooms := battle.beam_rooms(battle.ships[PLAYER], card) if not card.is_empty() else 1
		if rooms > 1:
			for system_id in _tiles[enemy_side]:
				var tile: SystemTile = _tiles[enemy_side][system_id]
				if tile.get_global_rect().has_point(get_global_mouse_position()):
					direction = _sweep_direction(tile)
					swept = battle.sweep_systems(enemy_side, system_id, direction, rooms)
	for system_id in _tiles[enemy_side]:
		_tiles[enemy_side][system_id].sweep = direction if system_id in swept else 0


func _refuse(reason: String, at: Vector2) -> void:
	Sounds.play("error")
	_fx.float_text(at, reason, Color("#ff9a9a"), 17)


func _on_end_turn() -> void:
	if _busy or battle.active_side != PLAYER or battle.over:
		return
	_cancel_selection()
	await _act(func(): return battle.end_turn(PLAYER))
	await _run_ai_turns()


func _on_jump() -> void:
	if _busy or battle.why_cannot_jump(PLAYER) != "":
		return
	await _act(func(): return battle.jump(PLAYER))
	await _run_ai_turns()


func _on_reroute() -> void:
	if _busy or battle.why_cannot_reroute(PLAYER) != "":
		return
	await _act(func(): return battle.reroute_power(PLAYER))
	await _run_ai_turns()


func _on_menu() -> void:
	_show_overlay("PAUSED", "The battle is waiting.", UiKit.TEXT, true)


## Performs a captain action, animates what it caused, then redraws.
func _act(action: Callable) -> void:
	if _busy:
		return
	_busy = true
	_refresh()
	_hold_shown_values()
	var events: Array = action.call()
	await _play_events(events)
	_release_shown_values()
	_busy = false
	_refresh()


## Runs AI turns until it is a human captain's turn (with autoplay, until the battle ends).
func _run_ai_turns() -> void:
	_busy = true
	_refresh()
	var guard := 0
	while not battle.over and (battle.active_side == ENEMY or autoplay) and guard < 5000:
		guard += 1
		var side := battle.active_side
		var captain: BattleAI = enemy_captain if side == ENEMY else _player_autopilot
		var action := captain.next_action(battle, side)
		_hold_shown_values()
		var events: Array = []
		match action.kind:
			"play": events = battle.play_card(side, action.uid, action.target)
			"move": events = battle.move_crew(side, action.crew, action.system)
			"burn": events = battle.burn_engines(side)
			"reroute": events = battle.reroute_power(side)
			"treat": events = battle.treat(side)
			"recall": events = battle.recall_suit(side, action.suit)
			"jump": events = battle.jump(side)
			_: events = battle.end_turn(side)
		if events.any(func(e): return e.type == "refused"):
			events = battle.end_turn(side)
		await _play_events(events)
		_release_shown_values()
		_refresh()
		if action.kind == "move":
			await _wait(0.12)
		else:
			await _wait(0.3)
	_busy = false
	_refresh()


# ---------------------------------------------------------------- animating events

func _play_events(events: Array) -> void:
	for event in events:
		_log_file.write_event(event, battle)
	for event in events:
		await _play_event(event)


func _exit_tree() -> void:
	_log_file.close()


func _play_event(event: Dictionary) -> void:
	_advance_shown(event)
	match event.type:
		"log":
			_add_log(event.text, event.side)
		"refused":
			if event.side == PLAYER:
				_refuse(event.reason, get_viewport_rect().size / 2.0)
		"turn_start":
			Sounds.play("turn")
			_refresh()
			var mine: bool = event.side == PLAYER
			await _fx.banner("YOUR TURN" if mine else "ENEMY TURN", UiKit.GOOD if mine else Color("#FF8500"))
		"drew":
			if event.side == PLAYER:
				Sounds.play("draw")
				_refresh()
				if event.get("bonus", false):
					_fx.float_text(_hand.card_center(event.card.uid) + Vector2(0, -60), "+1 CARD", UiKit.GOOD, 20)
				await _wait(0.12)
		"card_played":
			await _animate_card_played(event)
		"shot":
			await _animate_shot(event)
		"damage":
			_animate_damage(event)
			await _wait(0.08)
		"shield_up":
			Sounds.play("shield_up")
			_headers[event.side].shown_layers = event.layers
			_headers[event.side].shield_flash = 1.0
			_fx.shield_ripple(_shield_point(event.side))
		"shield_down":
			_headers[event.side].shown_layers = event.layers
		"fire_started":
			Sounds.play("fire")
			_fx.float_text(_tile_center(event.side, event.system) + Vector2(0, -30), "FIRE!", UiKit.FIRE, 22)
		"breached":
			_fx.float_text(_tile_center(event.side, event.system) + Vector2(0, -50), "BREACH", UiKit.DANGER, 20)
		"ionized", "hacked":
			Sounds.play("ion" if event.type == "ionized" else "hack")
			_fx.sparkle(_tile_center(event.side, event.system), UiKit.ION, 18)
			_fx.float_text(_tile_center(event.side, event.system), "OFFLINE" if event.type == "hacked" or battle.ships[event.side].systems[event.system].type != "reactor" else "-1 CELL", UiKit.ION, 22)
			await _wait(0.25)
		"power_lost":
			_fx.float_text(_headers[event.side].global_position + Vector2(_headers[event.side].size.x - 300, 40), "-1 POWER CELL", UiKit.ION, 18)
		"wounded":
			Sounds.play("wound")
			_fx.float_text(_crew_point(event.crew), "-%s" % str(snappedf(float(event.get("amount", 1.0)), 0.1)), UiKit.DANGER, 18)
		"crew_died":
			Sounds.play("death")
			_fx.explosion(_crew_point(event.crew), UiKit.DANGER, 0.5)
			_fx.float_text(_crew_point(event.crew), "KILLED", UiKit.DANGER, 20)
			await _wait(0.35)
		"healed":
			_fx.float_text(_crew_point(event.crew), "+%d" % event.amount, UiKit.GOOD, 18)
		"repaired":
			Sounds.play("repair")
			_fx.sparkle(_tile_center(event.side, event.system), UiKit.GOOD)
			_fx.float_text(_tile_center(event.side, event.system), "REPAIRED +%d" % event.amount, UiKit.GOOD, 18)
			await _wait(0.2)
		"fire_fought":
			Sounds.play("repair")
			_fx.float_text(_tile_center(event.side, event.system), "FIRE BEATEN BACK", UiKit.SHIELD, 18)
		"treat":
			Sounds.play("repair", -4.0, 1.2)
			_fx.float_text(_tile_center(event.side, event.system), "TREATING", UiKit.GOOD, 18)
		"aired":
			Sounds.play("shield_up", -6.0, 1.3)
			_fx.sparkle(_tile_center(event.side, event.system), Color("#9fd8ff"), 16)
			_fx.float_text(_tile_center(event.side, event.system), "AIR BACK", Color("#9fd8ff"), 18)
		"extinguished", "restored":
			Sounds.play("repair")
			_fx.sparkle(_tile_center(event.side, event.system), UiKit.SHIELD)
			_fx.float_text(_tile_center(event.side, event.system), "FIRE OUT" if event.type == "extinguished" else "BREACH SEALED",
				UiKit.SHIELD, 18)
			await _wait(0.2)
		"vented":
			Sounds.play("miss")
			_fx.sparkle(_tile_center(event.side, event.system), Color("#cfe2ff"), 30)
			_fx.float_text(_tile_center(event.side, event.system), "VENTED", Color("#cfe2ff"), 20)
			await _wait(0.3)
		"crew_moved":
			Sounds.play("click", -4.0)
			_refresh()
		"teleported":
			Sounds.play("teleport")
			_refresh()
			_fx.sparkle(_crew_point(event.crew), UiKit.MIND, 24)
			await _wait(0.35)
		"mind_controlled", "mind_released":
			Sounds.play("hack")
			_refresh()
			_fx.sparkle(_crew_point(event.crew), UiKit.MIND, 24)
			_fx.float_text(_crew_point(event.crew), "CONTROLLED" if event.type == "mind_controlled" else "FREED", UiKit.MIND, 18)
			await _wait(0.3)
		"cloaked":
			Sounds.play("cloak")
			_fx.float_text(_shield_point(event.side), "CLOAKED", UiKit.ION, 24)
		"battery":
			Sounds.play("power")
		"burn":
			Sounds.play("power", -4.0, 1.3)
			_fx.float_text(_tile_center(event.side, event.system), "+5% EVASION", UiKit.ACCENT, 18)
		"jump_charge":
			Sounds.play("power", 0.0, 0.7)
			_fx.float_text(_shield_point(event.side), "JUMP %d/%d" % [event.charge, battle.jump_charges_needed()], UiKit.ACCENT, 24)
		"jumped":
			Sounds.play("jump")
			_fx.float_text(_shield_point(event.side), "JUMP!", UiKit.ACCENT, 36)
			await _wait(0.8)
		"enemy_beaten":
			await _animate_enemy_beaten(event)
			Sounds.play("victory")
			_refresh()
			var title: String = {Battle.OUTCOME_DESTROYED: "ENEMY DESTROYED", Battle.OUTCOME_CREW_LOST: "ENEMY CREW LOST",
				Battle.OUTCOME_ESCAPED: "ENEMY FLED"}.get(event.outcome, "ENEMY BEATEN")
			await _fx.banner(title, UiKit.GOOD)
		"crew_level_up":
			Sounds.play("power", 0.0, 1.4)
			_fx.sparkle(_crew_point(event.crew), UiKit.ACCENT, 20)
			_fx.float_text(_crew_point(event.crew), "%s %s!" % [CrewSkills.LEVEL_NAMES[event.level].to_upper(),
				CrewSkills.LABELS[event.skill].to_upper()], UiKit.ACCENT, 18)
			await _wait(0.3)
		"fire_out":
			_fx.float_text(_tile_center(event.side, event.system), "FIRE OUT", Color("#cfd6e8"), 18)
		"crew_leaving":
			_fx.float_text(_crew_point(event.crew), "FORCING DOORS", UiKit.ACCENT, 16)
		"reroute":
			Sounds.play("power")
			_fx.float_text(_shield_point(event.side), "POWER REROUTED", Color("#ffc247"), 22)
			await _wait(0.3)
		"suit_launched":
			Sounds.play("teleport", -3.0, 1.4)
			_fx.sparkle(_tile_center(event.side, event.dock), UiKit.GROUP_COLORS.tactic, 20)
		"suit_hit":
			Sounds.play("wound")
			var at := _tile_center(1 - int(event.side), event.target) if event.target != "" else _tile_center(event.side, event.dock)
			_fx.explosion(at + Vector2(40, 0), UiKit.DANGER, 0.5)
			_fx.float_text(at + Vector2(40, -20), "SUIT HIT", UiKit.DANGER, 18)
		"suit_lost":
			Sounds.play("explosion", -4.0, 1.2)
			_refresh()
		"suit_shot":
			Sounds.play("laser", -4.0, 1.2)
			if event.target != "":
				await _fx.shoot(_tile_center(event.side, event.dock), _tile_center(1 - int(event.target_side), event.target) + Vector2(40, 0),
					"laser", battle.ships[event.side].color, not event.hit)
		"suit_recalling":
			Sounds.play("click")
			_fx.float_text(_tile_center(event.side, event.dock), "RECALLING", UiKit.ACCENT, 18)
		"suit_returned":
			_refresh()
		"spored":
			_fx.sparkle(_tile_center(event.side, event.system), Color("#7dffb0"), 22)
			_fx.float_text(_tile_center(event.side, event.system), "SPORES", Color("#7dffb0"), 20)
		"spores_cleared":
			Sounds.play("repair")
			_fx.float_text(_tile_center(event.side, event.system), "SPORES CLEARED", Color("#7dffb0"), 18)
		"stunned":
			_fx.float_text(_crew_point(event.crew), "STUNNED", UiKit.ION, 16)
		"suit_bores":
			_fx.sparkle(_tile_center(1 - event.side, event.target), UiKit.GROUP_COLORS.tactic, 10)
		"crew_fight":
			Sounds.play("wound", 0.0, 0.8)
			_fx.float_text(_tile_center(event.ship, event.system) + Vector2(0, -40), "FIGHT!", UiKit.DANGER, 20)
			await _wait(0.25)
		"sabotage":
			_fx.sparkle(_tile_center(event.ship, event.system), UiKit.MIND, 10)
		"battle_over":
			await _wait(0.6)
			_show_result(event)


## The enemy goes down: a destroyed ship shakes and blows apart system by system; any ship's hand fades away.
func _animate_enemy_beaten(event: Dictionary) -> void:
	var loser := 1 - int(event.winner)
	var fade := create_tween()
	fade.tween_property(_enemy_hand_row, "modulate:a", 0.0, 0.4)
	if event.outcome != Battle.OUTCOME_DESTROYED:
		await fade.finished
		_enemy_hand_row.modulate.a = 1.0
		return
	for system_id in battle.ships[loser].system_order:
		var tile: SystemTile = _tiles[loser][system_id]
		tile.flash = 1.0
		_shake(tile, 7.0)
		_fx.explosion(_tile_center(loser, system_id), UiKit.FIRE, 1.2)
		Sounds.play("explosion", -4.0, randf_range(0.8, 1.1))
		await _wait(0.09)
	for i in 3:
		_shake(_headers[loser], 9.0)
		_shake(self, 6.0)
		await _wait(0.12)
	_enemy_hand_row.modulate.a = 1.0


## Moves the tiles' held look on by this event, so each hit, fire, wound or repair shows as it plays.
func _advance_shown(event: Dictionary) -> void:
	match event.type:
		"damage":
			_show_on_tile(event.side, event.system, {"damage": event.system_damage})
		"repaired":
			_show_on_tile(event.side, event.system, {"damage": -int(event.amount)})
		"fire_started":
			_show_on_tile(event.side, event.system, {"on_fire": true})
		"fire_out", "extinguished", "vented":
			_show_on_tile(event.side, event.system, {"on_fire": false})
		"breached":
			_show_on_tile(event.side, event.system, {"breached": true})
		"restored":
			_show_on_tile(event.side, event.system, {"breached": false})
		"ionized", "hacked":
			_show_on_tile(event.side, event.system, {"disabled_turns": 1})
		"wounded":
			_show_crew_wounds(event.crew, _shown_wounds(event.crew) + float(event.get("amount", 1.0)))
		"crew_died":
			_show_crew_wounds(event.crew, 999.0)
		"healed":
			_show_crew_wounds(event.crew, maxf(0.0, _shown_wounds(event.crew) - float(event.amount)))
		"enemy_beaten":
			if event.outcome == Battle.OUTCOME_DESTROYED:
				var loser := 1 - int(event.winner)
				for system_id in _tiles[loser]:
					var tile: SystemTile = _tiles[loser][system_id]
					if not tile.shown.is_empty():
						tile.shown.damage = battle.ships[loser].systems[system_id].level
						tile.shown.on_fire = false


func _shown_wounds(crew_id: int) -> float:
	for tile in _tiles[PLAYER].values():
		if not tile.shown_crew.is_empty():
			return float(tile.shown_crew.get(crew_id, 0.0))
	for member in battle.crew:
		if member.id == crew_id:
			return member.wounds
	return 0


func _animate_card_played(event: Dictionary) -> void:
	var side: int = event.side
	var definition: Dictionary = event.definition
	var view := CardView.new().setup(event.card, definition)
	view.pivot_offset = Vector2.ZERO
	_stage.add_child(view)
	var start: Vector2
	if side == PLAYER:
		var hand_view := _hand.view_for(event.card.uid)
		start = _hand.card_center(event.card.uid)
		if hand_view:
			hand_view.visible = false
	else:
		start = _enemy_hand_row.global_position + _enemy_hand_row.size / 2.0
	var speed := Settings.animation_scale()
	var stage_scale := 1.05 if side == PLAYER else 1.2
	var stage_center := Vector2(size.x / 2.0, size.y * (0.47 if side == PLAYER else 0.38))
	view.scale = Vector2.ONE * 0.5
	view.position = start - CardView.BASE_SIZE * 0.25
	Sounds.play("power" if event.card.id == "power" else "play")
	if event.card.id == "power":
		# Power Cells fly straight to the power row.
		var row_point := _headers[side].global_position + Vector2(_headers[side].size.x - 360 + battle.ships[side].power_row.size() * 19, 40)
		var quick := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		quick.tween_property(view, "position", row_point - CardView.BASE_SIZE * 0.08, 0.35 * speed)
		quick.tween_property(view, "scale", Vector2.ONE * 0.16, 0.35 * speed)
		await quick.finished
		_fx.sparkle(row_point, Color("#ffc247"), 10)
		view.queue_free()
		return
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "position", stage_center - CardView.BASE_SIZE * stage_scale / 2.0, 0.32 * speed)
	tween.tween_property(view, "scale", Vector2.ONE * stage_scale, 0.32 * speed)
	await tween.finished
	var target: Dictionary = event.target
	if target.has("system") and _tiles[int(target.ship)].has(target.system):
		_flash_target(int(target.ship), target.system)
	await _wait((0.45 if side == PLAYER else 1.0) * speed)
	var deck_point := _headers[side].global_position + Vector2(_headers[side].size.x - 70, 35)
	var leave := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	leave.tween_property(view, "position", deck_point, 0.3 * speed)
	leave.tween_property(view, "scale", Vector2.ONE * 0.1, 0.3 * speed)
	leave.tween_property(view, "modulate:a", 0.2, 0.3 * speed)
	leave.chain().tween_callback(view.queue_free)
	await _wait(0.12 * speed)


func _animate_shot(event: Dictionary) -> void:
	var attacker: int = event.side
	var defender := 1 - attacker
	var from := _tile_center(attacker, event.from) if event.from != "" else _shield_point(attacker)
	var to := _tile_center(defender, event.target)
	var kind: String = event.kind
	var color := battle.ships[attacker].color
	if kind == "ion":
		color = UiKit.ION
	elif kind == "heavy":
		color = UiKit.FIRE
	if kind == "beam":
		Sounds.play("beam")
		await _fx.beam(from, to, Color("#ff5a5f"))
	else:
		Sounds.play({"laser": "laser", "chain": "laser", "suit": "laser", "heavy": "heavy", "ion": "ion", "missile": "missile",
			"spore": "missile", "mind": "hack", "flak": "heavy", "bomb": "teleport"}.get(kind, "laser"), -2.0, randf_range(0.92, 1.08))
		if event.result == "intercepted":
			await _fx.shoot(from, from.lerp(to, 0.7), kind, color, false)
		else:
			await _fx.shoot(from, to, kind, color, event.result == "miss")
	match event.result:
		"miss":
			Sounds.play("miss")
			_fx.float_text(to, "MISS", Color("#cfd6e8"), 22)
		"intercepted":
			Sounds.play("explosion", -6.0, 1.3)
			_fx.explosion(from.lerp(to, 0.7), Color("#cfe2ff"), 0.6)
			_fx.float_text(from.lerp(to, 0.7), "SHOT DOWN", Color("#cfe2ff"), 20)
		"shield":
			Sounds.play("shield_hit")
			_fx.shield_ripple(to.lerp(from, 0.18))
			_fx.float_text(to.lerp(from, 0.2), "BLOCKED", UiKit.SHIELD, 20)
			_headers[defender].shield_flash = 1.0
		"hit":
			if kind == "ion":
				_fx.explosion(to, UiKit.ION, 0.7)
			else:
				_fx.explosion(to, UiKit.FIRE, 1.0 if kind != "laser" else 0.7)
	await _wait(0.06)


func _animate_damage(event: Dictionary) -> void:
	var side: int = event.side
	var tile: SystemTile = _tiles[side].get(event.system)
	if tile:
		tile.flash = 1.0
		_shake(tile)
	if event.hull > 0:
		Sounds.play("explosion" if event.hull >= 2 else "hull_hit")
		var header := _headers[side]
		if header.shown_hull >= 0:
			header.shown_hull = maxi(battle.ships[side].hull, header.shown_hull - event.hull)
		header.hull_flash = 1.0
		_fx.float_text(_tile_center(side, event.system), "-%d" % event.hull, UiKit.DANGER, 30)
		_shake(self, 4.0 if event.hull >= 2 else 2.0)
	elif event.system_damage > 0:
		Sounds.play("hull_hit", -6.0)
		_fx.float_text(_tile_center(side, event.system), "-%d %s" % [event.system_damage, str(event.cause).to_upper()], UiKit.FIRE, 18)


## Holds each header at the hull and shield values from before an action, so the animation can lower them
## shot by shot as the events play.
func _hold_shown_values() -> void:
	for side in 2:
		_headers[side].shown_hull = battle.ships[side].hull
		_headers[side].shown_layers = battle.ships[side].shield_layers.size()
		for system_id in _tiles[side]:
			var system: Dictionary = battle.ships[side].systems[system_id]
			_tiles[side][system_id].shown = {"damage": system.damage, "on_fire": system.on_fire,
				"breached": system.breached, "disabled_turns": system.disabled_turns}
	var wounds := {}
	for member in battle.crew:
		wounds[member.id] = member.wounds
	for side in 2:
		for tile in _tiles[side].values():
			tile.shown_crew = wounds


func _release_shown_values() -> void:
	for header in _headers:
		header.shown_hull = -1
		header.shown_layers = -1
	for side in 2:
		for tile in _tiles[side].values():
			tile.shown = {}
			tile.shown_crew = {}


## Moves a tile's shown state on by one event, so the change appears as the event plays.
func _show_on_tile(side: int, system_id: String, changes: Dictionary) -> void:
	var tile: SystemTile = _tiles[side].get(system_id)
	if tile == null or tile.shown.is_empty():
		return
	var system: Dictionary = battle.ships[side].systems[system_id]
	for key in changes:
		if key == "damage":
			tile.shown.damage = clampi(int(tile.shown.damage) + int(changes.damage), 0, system.level)
		else:
			tile.shown[key] = changes[key]


func _show_crew_wounds(crew_id: int, wounds: float) -> void:
	for side in 2:
		for tile in _tiles[side].values():
			if not tile.shown_crew.is_empty():
				tile.shown_crew[crew_id] = wounds
				return

func _flash_target(side: int, system_id: String) -> void:
	var tile: SystemTile = _tiles[side][system_id]
	var tween := tile.create_tween()
	tween.tween_property(tile, "modulate", Color(1.6, 1.4, 0.9), 0.12)
	tween.tween_property(tile, "modulate", Color.WHITE, 0.25)


func _shake(node: Control, strength: float = 5.0) -> void:
	var origin := node.position
	var tween := node.create_tween()
	for i in 5:
		tween.tween_property(node, "position", origin + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.03)
	tween.tween_property(node, "position", origin, 0.04)


func _tile_center(side: int, system_id: String) -> Vector2:
	var tile: SystemTile = _tiles[side].get(system_id)
	if tile == null:
		return _shield_point(side)
	return tile.global_position + SystemTile.TILE_SIZE * tile.scale * Vector2(0.5, 0.3)


func _crew_point(crew_id: int) -> Vector2:
	for member in battle.crew:
		if member.id == crew_id:
			var tile: SystemTile = _tiles[member.ship].get(member.system)
			if tile:
				return tile.crew_token_center(crew_id)
	return size / 2.0


func _shield_point(side: int) -> Vector2:
	return _headers[side].global_position + Vector2(_headers[side].size.x * 0.5, ShipHeader.HEIGHT * 0.5)


func _add_log(text: String, side: int) -> void:
	var color := "#c9d1e6"
	if side == PLAYER:
		color = "#9dffa0"
	elif side == ENEMY:
		color = "#ffb877"
	if text.begins_with("—"):
		_log.append_text("\n[b][color=%s]%s[/color][/b]\n" % [color, text])
	else:
		_log.append_text("[color=%s]%s[/color]\n" % [color, text])


# ---------------------------------------------------------------- end of battle

func _show_result(event: Dictionary) -> void:
	var enemy := battle.ships[ENEMY]
	var mine := battle.ships[PLAYER]
	var survived := player_survived()
	var title := "VICTORY"
	var color := UiKit.GOOD
	var text := ""
	if not survived:
		title = "DEFEAT"
		color = UiKit.DANGER
		text = "%s is destroyed." % mine.name if mine.hull <= 0 else "Your whole crew is lost."
		Sounds.play("defeat")
	elif event.outcome == Battle.OUTCOME_ESCAPED:
		title = "ESCAPED" if event.escaped == PLAYER else "ENEMY FLED"
		color = UiKit.ACCENT
		text = "You jumped away mid-battle." if event.escaped == PLAYER else "%s jumped away; you regrouped and jumped on." % enemy.name
	else:
		text = ("%s broke apart" % enemy.name if event.outcome == Battle.OUTCOME_DESTROYED else "No one is left alive aboard %s" % enemy.name) + ", and you jumped away."
	var lines: Array[String] = [text, ""]
	lines.append("Turns: %d   ·   Your hull: %d/%d   ·   Crew: %d" % [battle.turn_number, mine.hull, mine.hull_max, battle.living_crew_of(PLAYER).size()])
	if run:
		if survived:
			var reward := RunState.wreck_reward(enemy.design, event.outcome) if battle.winner == PLAYER and event.outcome != Battle.OUTCOME_ESCAPED else 0.0
			var jump_cost := float(Catalog.rule("economy", "jumpCost", 0))
			lines.append("Salvage: +%s   ·   Jump: -%s   ·   Mawjig after: %s" % [Money.text(reward, false), Money.text(jump_cost, false),
				Money.text(maxf(0.0, run.mawjig + reward - jump_cost))])
		else:
			lines.append("Run over: %d battle%s won, %s banked." % [run.battles_won, "" if run.battles_won == 1 else "s", Money.text(run.mawjig)])
	_show_overlay(title, "\n".join(lines), color, false)


## True once the battle is over and the player's ship and crew made it out.
func player_survived() -> bool:
	return battle.over and battle.ships[PLAYER].hull > 0 and not battle.living_crew_of(PLAYER).is_empty()


func _show_overlay(title: String, text: String, color: Color, can_resume: bool) -> void:
	if _overlay:
		_overlay.queue_free()
	_overlay = ColorRect.new()
	_overlay.z_index = 110
	_overlay.color = Color(0, 0, 0, 0.72)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := UiKit.panel(Color("#0f1424"), color.darkened(0.2), 14)
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var box := UiKit.vbox(16)
	panel.add_child(UiKit.margin(box, 18))
	var heading := UiKit.heading(title, 54, color)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var body := UiKit.label(text, 17, UiKit.TEXT)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	var buttons := UiKit.hbox(10)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	if can_resume:
		buttons.add_child(UiKit.primary_button("Resume", func():
			_overlay.queue_free()
			_overlay = null, 18))
		buttons.add_child(UiKit.button("Restart", func(): finished.emit("rematch"), 18))
	elif player_survived():
		buttons.add_child(UiKit.primary_button("Continue Run", func(): finished.emit("continue"), 18))
	else:
		buttons.add_child(UiKit.primary_button("Retry Battle", func(): finished.emit("rematch"), 18))
	buttons.add_child(UiKit.button("Change Ships", func(): finished.emit("setup"), 18))
	buttons.add_child(UiKit.button("Main Menu", func(): finished.emit("menu"), 18))
	box.add_child(buttons)
	_overlay.modulate.a = 0.0
	_hand.input_enabled = false
	_overlay.tree_exited.connect(func(): if is_instance_valid(_hand): _hand.input_enabled = true)
	create_tween().tween_property(_overlay, "modulate:a", 1.0, 0.3)


# ---------------------------------------------------------------- helpers

func _current_targets() -> Array:
	if _targeting_uid < 0:
		return []
	return battle.valid_targets(PLAYER, _targeting_uid, _targeting_crew, _teleport_from_bay)


func _card_in_hand(uid: int) -> Dictionary:
	for card in battle.ships[PLAYER].hand:
		if card.uid == uid:
			return card
	return {}


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds * Settings.animation_scale()).timeout
