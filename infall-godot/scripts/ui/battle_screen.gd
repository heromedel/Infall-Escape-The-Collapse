class_name BattleScreen
extends Node
## The battle itself, shared by every player: the squads at the current cluster and any enemy squad across the
## barrier. It plays the encounter one tick at a time as the stream brings ticks (Session), plays orders on it,
## and turns what happens into explosions and sounds. It draws the world once; each player looks at it through
## their own PlayerView (camera, cards, selection), side by side when they share a screen (GV 4F).

signal fight_over(outcome: String, finished: Encounter)
signal surrender_offered(ship: Ship)
signal squad_lost

const TICK_SECONDS := 0.05

var encounter: Encounter
var run: RunState
var paused: bool = false
var paused_by: int = 0               # the player who paused, for the indicator (GDD 4L)
var hold_pause: bool = false         # a shared window is open (an event): nobody plays the battle meanwhile
var store_here: bool = false
var auto_pause_ticks: int = 0
var session: Session
var player_views: Array = []         # PlayerView: one for each player on this machine

## The world is drawn by every player's view; it lives in a viewport of its own that never draws by itself.
var world_host := SubViewport.new()
var world := Node2D.new()
var effects := EffectsLayer.new()
var views: Dictionary = {}           # Ship -> ShipView
var look_seed := 0
var collapse_near := 0.0


func _ready() -> void:
	world_host.size = Vector2i(2, 2)
	world_host.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(world_host)
	world_host.add_child(world)


## Starts showing an encounter: lays out the squads, builds a view for every ship and frames every camera.
func show_encounter(new_encounter: Encounter, wallet: RunState, cluster_look: int, collapse_nearness: float, has_store: bool, reframe: bool = true) -> void:
	for view in views.values():
		view.queue_free()
	views.clear()
	if effects.get_parent():
		world.remove_child(effects)
	encounter = new_encounter
	run = wallet
	store_here = has_store
	look_seed = cluster_look
	collapse_near = collapse_nearness
	Formation.lay_out(encounter, String(Settings.get_value("formation", "Curve")))
	for ship in encounter.ships:
		var view := ShipView.new()
		view.setup(ship, encounter)
		world.add_child(view)
		views[ship] = view
	effects.encounter = encounter
	effects.particles.clear()
	world.add_child(effects)
	encounter.step()   # one tick so crew are at their consoles and the HUD reads true from the first frame
	encounter.notes.clear()
	for view in player_views:
		view.encounter_changed(reframe)


## One tick of the battle, from the stream.
func step_tick() -> void:
	if encounter == null:
		return
	encounter.step()
	_tick_auto_pause()
	_read_notes()


func _process(_delta: float) -> void:
	if encounter == null:
		return
	var alpha := session.tick_progress if session and not paused and not hold_pause else 1.0
	effects.alpha = alpha
	if not player_views.is_empty():
		effects.zoom = player_views[0].camera.zoom.x
	var player_sees := _player_sees_inside()
	var several := player_views.size() > 1
	for ship in views:
		var view: ShipView = views[ship]
		view.alpha = alpha
		view.selected = player_views.any(func(p): return p.selected_ship == ship)
		view.interior_visible = ship.side == 0 or player_sees or _player_crew_aboard(ship)
		view.target_marks.clear()
		view.beam_marks.clear()
	# Every player ship's weapon targets, seen by everyone
	for ship in encounter.living(0):
		for index in ship.weapons.size():
			var slot := ship.weapons[index]
			if not slot.has_target() or slot.target_suit != null:
				continue
			var view: ShipView = views.get(slot.target_ship)
			if view == null:
				continue
			var colour := UiColours.ENEMY_RED if slot.autofire else UiColours.TARGET_YELLOW
			if not player_views.any(func(p): return p.selected_ship == ship):
				colour = Color(colour, 0.45)
			if slot.def.type == "beam":
				view.beam_marks.append({"start": slot.beam_start, "end": slot.beam_end, "colour": colour})
			else:
				view.target_marks.append({"cell": slot.target_cell, "label": index + 1, "colour": colour})
	# Selected crew wear the ring of the player who selected them (green when one plays alone)
	for ship in encounter.ships:
		for member in ship.crew:
			member.selected = false
			for view in player_views:
				if view.selected_crew.has(member):
					member.selected = true
					member.selection_colour = view.colour if several else UiColours.POWER_GREEN
					break


func _tick_auto_pause() -> void:
	if not Settings.get_value("auto_pause", false) or not encounter.in_fight():
		return
	auto_pause_ticks += 1
	if auto_pause_ticks >= int(Settings.get_value("auto_pause_seconds", 5.0) * 20.0):
		auto_pause_ticks = 0
		paused = true
		paused_by = 0


func set_paused(on: bool, by: int = 0) -> void:
	if on == paused:
		return
	paused = on
	paused_by = by if on else 0
	auto_pause_ticks = 0
	_sound("pause" if paused else "unpause")


func _player_sees_inside() -> bool:
	if encounter.hazard == "nebula":
		return false
	for ship in encounter.living(0):
		if ship.sensor_level() >= 2:
			return true
	return false


func _player_crew_aboard(ship: Ship) -> bool:
	for member in ship.visitors:
		if member.side == 0 and not member.dead:
			return true
	return false


func _sound(name: String, volume: float = 0.0) -> void:
	if session == null or not session.catching_up:
		Sfx.play(name, volume)


## A message for every player on this machine.
func flash_message(text: String) -> void:
	for view in player_views:
		view.hud.flash_message(text)


func shake(amount: float) -> void:
	if Settings.get_value("screen_shake", true):
		for view in player_views:
			view.shake(amount)


# --- What happened: effects, sounds, decisions ----------------------------------------------------------------

func _read_notes() -> void:
	for note in encounter.notes:
		_show_note(note)
		if run:
			run.log_note(note)
	encounter.notes.clear()


func _show_note(note: Dictionary) -> void:
	var ship: Ship = note.get("ship") if note.get("ship") is Ship else null
	var quiet := session != null and session.catching_up
	match note.kind:
		"shot":
			var weapon: WeaponDef = note.weapon
			_sound("missile" if weapon.type == "missile" else ("laser_heavy" if weapon.damage >= 2 else "laser"), -6.0 if ship and ship.side == 1 else -3.0)
		"volley":
			var weapon: WeaponDef = note.weapon
			if weapon.type == "beam":
				_sound("beam")
			elif weapon.type == "bomb":
				_sound("teleport", -6.0)
		"hit":
			var damage: int = note.damage
			var at: Vector2 = note.position
			if not quiet:
				effects.explosion(at, 0.7 + 0.25 * damage)
				if damage > 0:
					effects.float_text(at + Vector2(0, -20), str(damage), UiColours.DAMAGED_RED, 26)
			_sound("hit_hull" if damage > 0 else "hit_soft")
			if ship and ship.side == 0:
				shake(4.0 + damage * 2.0)
		"shield_hit":
			views[ship].shield_hit(note.position)
			effects.shield_sparks(note.position, UiColours.SHIELD_BLUE)
			_sound("hit_shield")
		"supershield_hit":
			views[ship].shield_hit(note.position, true)
			effects.shield_sparks(note.position, UiColours.SUPERSHIELD)
			_sound("hit_shield")
		"miss":
			effects.float_text(note.position, "MISS", Color(0.85, 0.9, 1.0), 20)
		"intercept", "shot_down":
			effects.small_burst(note.position, Color(1.0, 0.6, 0.9))
			_sound("intercept")
		"ship_destroyed":
			_ship_explodes(ship)
		"crew_died":
			if ship and note.has("crew"):
				var member: CrewMember = note.crew
				for view in player_views:
					view.selected_crew.erase(member)
				if note.position != Vector2.ZERO:
					effects.small_burst(encounter.local_to_world(ship, note.position), Color(1.0, 0.3, 0.3))
			_sound("crew_death")
		"teleported":
			_sound("teleport")
			var target: Ship = note.target
			for member in target.crew + target.visitors:
				if member.teleporting_ticks > 0 and member.ship == target:
					effects.sparkle(encounter.local_to_world(target, member.position), Color(0.7, 0.9, 1.0))
		"suit_launched":
			_sound("launch")
		"suit_hit", "suit_destroyed":
			effects.explosion(note.position, 0.5, Color(0.8, 0.4, 1.0))
		"fire_started":
			_sound("fire", -8.0)
		"breach":
			_sound("breach", -4.0)
		"skill_up":
			var member: CrewMember = note.crew
			if member.side == 0 and member.is_active():
				effects.float_text(encounter.local_to_world(member.ship, member.position) + Vector2(0, -24), "+ " + str(note.skill).capitalize(), UiColours.POWER_GREEN, 17)
		"flare":
			_sound("flare")
			shake(3.0)
		"surrender_offer":
			paused = true
			paused_by = 0
			surrender_offered.emit(ship)
		"enemy_escaped":
			effects.sparkle(ship.world_position, Color(0.8, 0.9, 1.0))
			_sound("jump")
		"no_mawjig":
			flash_message("Not enough Mawjig to fire.")
		"fight_over":
			_on_fight_over(note.outcome)
		"squad_lost":
			squad_lost.emit()
		"cloaked":
			_sound("cloak")


## The squad's Jigawatt Drives fire: the ships stretch toward the rim and every player's screen flashes white.
func play_jump_out() -> void:
	if session and session.catching_up:
		return
	var tween := create_tween()
	tween.set_parallel(true)
	for ship in encounter.living(0):
		var view: ShipView = views[ship]
		tween.tween_property(view, "scale", Vector2(0.6, 2.6), 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.tween_property(view, "modulate", Color(2.5, 2.5, 3.0, 0.0), 0.55).set_ease(Tween.EASE_IN)
	for view in player_views:
		view.flash_white(0.55)
	await tween.finished


func play_jump_in() -> void:
	for view in player_views:
		view.flash_clear()


func _ship_explodes(ship: Ship) -> void:
	_sound("explosion_big")
	var view: ShipView = views[ship]
	var bounds := Formation.hull_bounds(ship.design)
	for index in 9:
		var local := Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y)) * 0.6
		var at := encounter.local_to_world(ship, local)
		get_tree().create_timer(index * 0.18).timeout.connect(func(): effects.explosion(at, 1.4 + randf()))
	shake(10.0)
	view.modulate = Color(1.5, 1.2, 1.0)


func _on_fight_over(outcome: String) -> void:
	for view in player_views:
		view.cancel_aim()
	for ship in encounter.living(0):
		for slot in ship.weapons:
			slot.clear_target()
	fight_over.emit(outcome, encounter)


## A number that every machine should agree on after the same ticks and orders; the host checks it (GV 4C).
func checksum() -> int:
	if encounter == null:
		return 0
	var parts: Array = [encounter.ships.size()]
	for ship in encounter.ships:
		parts.append_array([ship.hull, ship.shield_layers, ship.destroyed, ship.crew.size()])
		for member in ship.crew:
			parts.append_array([member.cell, int(member.health), member.dead])
		for slot in ship.weapons:
			parts.append_array([slot.powered, int(slot.charge)])
	parts.append(encounter.projectiles.size() if "projectiles" in encounter else 0)
	return hash(parts)
