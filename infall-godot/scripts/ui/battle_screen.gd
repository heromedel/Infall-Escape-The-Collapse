class_name BattleScreen
extends Node
## The ship view: the player's squad at the current cluster, and any enemy squad across the gap. It runs the
## encounter on its fixed ticks, shows it, and turns the player's clicks into orders: crew moves, weapon
## targets, power, doors, boarding and suits. Like the genre's main screen, it is where the whole run is
## played from; the map, events and store open over it.

signal fight_over(outcome: String)
signal surrender_offered(ship: Ship)
signal jump_pressed
signal ship_screen_pressed
signal hail_pressed
signal store_pressed
signal menu_pressed
signal squad_lost

const TICK_SECONDS := 0.05
const SQUAD_GAP := 120.0            # world pixels between the two squads' noses, top to bottom
const SQUAD_OFFSET := 420.0          # each squad sits this far to its side: the wide screen carries the distance
const FORMATION_DEPTH := 0.7         # GDD 3H: curve depth in ship lengths
const FORMATION_SPACING := 1.35

var encounter: Encounter
var run: RunState
var paused: bool = false
var hold_pause: bool = false        # an event or menu is open; the player can't unpause
var selected_ship: Ship
var selected_crew: Array[CrewMember] = []
var aim_mode: String = ""            # weapon, beam, teleport, suit
var aim_slot: WeaponSlot
var autofire_default: bool = false
var hover_ship: Ship
var hover_room: int = -1
var hover_cell := Vector2i(999, 999)
var hover_crew: CrewMember
var hover_door: ShipDoor
var store_here: bool = false
var auto_pause_ticks: int = 0
var tick_accumulator: float = 0.0

var world := Node2D.new()
var camera := BattleCamera.new()
var background := SpaceBackground.new()
var effects := EffectsLayer.new()
var divider := SquadDivider.new()
var hud: BattleHud
var views: Dictionary = {}           # Ship -> ShipView
var _drag_start := Vector2.ZERO
var _box_selecting := false
var _beam_start_local := Vector2.ZERO
var _beam_target: Ship


var _flash := ColorRect.new()
var hazard_layer := HazardAmbience.new()


func _ready() -> void:
	add_child(background)
	add_child(hazard_layer)
	add_child(world)
	world.add_child(divider)
	world.add_child(camera)
	camera.make_current()
	hud = BattleHud.new()
	hud.screen = self
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	hud_layer.add_child(hud)
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 15
	add_child(flash_layer)
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash)


## Starts showing an encounter: lays out the squads, builds a view for every ship and frames the camera.
func show_encounter(new_encounter: Encounter, wallet: RunState, look_seed: int, collapse_near: float, has_store: bool) -> void:
	for view in views.values():
		view.queue_free()
	views.clear()
	if effects.get_parent():
		world.remove_child(effects)
	encounter = new_encounter
	run = wallet
	store_here = has_store
	selected_crew.clear()
	aim_mode = ""
	_lay_out_squads()
	for ship in encounter.ships:
		var view := ShipView.new()
		view.setup(ship, encounter)
		world.add_child(view)
		views[ship] = view
	effects.encounter = encounter
	effects.particles.clear()
	world.add_child(effects)
	divider.visible = encounter.fight_started
	encounter.step()   # one tick so crew are at their consoles and the HUD reads true from the first frame
	encounter.notes.clear()
	if selected_ship == null or not encounter.ships.has(selected_ship) or selected_ship.is_gone():
		selected_ship = encounter.living(0)[0] if not encounter.living(0).is_empty() else null
	background.set_cluster_look(look_seed, collapse_near, encounter.hazard)
	hazard_layer.set_hazard(encounter.hazard, look_seed)
	frame_everything(true)


func _lay_out_squads() -> void:
	for side in [0, 1]:
		var squad: Array[Ship] = []
		for ship in encounter.ships:
			if ship.side == side:
				squad.append(ship)
		var widest := 200.0
		var longest := 200.0
		for ship in squad:
			var bounds := Formation.hull_bounds(ship.design)
			widest = maxf(widest, bounds.size.x)
			longest = maxf(longest, bounds.size.y)
		var spacing := widest * FORMATION_SPACING
		for index in squad.size():
			var ship := squad[index]
			var bounds := Formation.hull_bounds(ship.design)
			var offset := (index - (squad.size() - 1) * 0.5)
			var curve := 0.0
			if squad.size() > 1:
				var u := offset / maxf(1.0, (squad.size() - 1) * 0.5)
				curve = FORMATION_DEPTH * longest * (1.0 - u * u)   # outer ships forward, centre back (GDD 3H)
			ship.facing_down = side == 1
			# Player squad bottom, enemy squad top (GDD 3A), each shifted to its own side of the screen so the
			# space between them reads as distance while both stay large enough to work.
			var shift := SQUAD_OFFSET if encounter.fight_started else 0.0
			if side == 0:
				ship.world_position = Vector2(offset * spacing - shift, SQUAD_GAP * 0.5 - bounds.position.y + curve)
			else:
				ship.world_position = Vector2(-offset * spacing + shift, -SQUAD_GAP * 0.5 + bounds.position.y - curve)


## Frames the whole encounter, or just the player's squad when there is no one to fight.
func frame_everything(instant: bool = false) -> void:
	var rect := Rect2()
	var first := true
	for ship in encounter.ships:
		if ship.side == 1 and not encounter.fight_started:
			continue
		if ship.escaped or (ship.destroyed and ship.explosion_ticks > 60):
			continue
		var bounds := Formation.hull_bounds(ship.design)
		# Frame every room and the nose; only the engines behind the last room may sit under the HUD
		var floor_rect := ship.design.floor_rect()
		var trimmed := Rect2(Vector2(floor_rect.position.x - 50.0, bounds.position.y), Vector2(floor_rect.size.x + 100.0, floor_rect.end.y + 30.0 - bounds.position.y))
		var corners := [trimmed.position, trimmed.end, Vector2(trimmed.position.x, trimmed.end.y), Vector2(trimmed.end.x, trimmed.position.y)]
		for corner in corners:
			var world_point := encounter.local_to_world(ship, corner)
			if first:
				rect = Rect2(world_point, Vector2.ZERO)
				first = false
			else:
				rect = rect.expand(world_point)
	var view_size := get_viewport().get_visible_rect().size
	camera.frame(rect.grow(20.0), view_size, 104.0, 150.0)
	if instant:
		camera.zoom = Vector2.ONE * camera.target_zoom
		camera.position = camera.target_position


# --- The loop -------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if encounter == null:
		return
	if not paused and not hold_pause:
		tick_accumulator += delta
		var steps := 0
		while tick_accumulator >= TICK_SECONDS and steps < 4:
			tick_accumulator -= TICK_SECONDS
			steps += 1
			encounter.step()
			_tick_auto_pause()
			_read_notes()
		if steps >= 4:
			tick_accumulator = 0.0
	var alpha := clampf(tick_accumulator / TICK_SECONDS, 0.0, 1.0)
	_update_views(alpha)
	background.follow_camera(camera.position, camera.zoom.x)
	divider.zoom = camera.zoom.x


func _tick_auto_pause() -> void:
	if not Settings.get_value("auto_pause", false) or not encounter.in_fight():
		return
	auto_pause_ticks += 1
	if auto_pause_ticks >= int(Settings.get_value("auto_pause_seconds", 5.0) * 20.0):
		auto_pause_ticks = 0
		paused = true


func _update_views(alpha: float) -> void:
	effects.alpha = alpha
	var player_sees := _player_sees_inside()
	for ship in views:
		var view: ShipView = views[ship]
		view.alpha = alpha
		view.selected = ship == selected_ship
		view.interior_visible = ship.side == 0 or player_sees or _player_crew_aboard(ship)
		view.highlight_rooms.clear()
		view.highlight_tiles.clear()
		view.target_marks.clear()
		view.beam_marks.clear()
		if ship == hover_ship and hover_room >= 0:
			if aim_mode in ["weapon", "beam"] and ship.side == 1:
				# Shots hit a single tile: the tile under the cursor is what gets hit
				var colour := UiColours.TARGET_YELLOW if not _aim_is_autofire() else UiColours.ENEMY_RED
				view.highlight_rooms[hover_room] = Color(colour, 0.35)
				view.highlight_tiles[hover_cell] = colour
			elif aim_mode != "" and ship.side == 1:
				view.highlight_rooms[hover_room] = UiColours.TARGET_YELLOW
			elif not selected_crew.is_empty() and selected_crew[0].ship == ship:
				view.highlight_rooms[hover_room] = Color(UiColours.POWER_GREEN, 0.4)
				view.highlight_tiles[hover_cell] = UiColours.POWER_GREEN
	# Weapon targets of the selected ship's weapons (and every player ship's, dimmer)
	for ship in encounter.living(0):
		for index in ship.weapons.size():
			var slot := ship.weapons[index]
			if not slot.has_target() or slot.target_suit != null:
				continue
			var view: ShipView = views.get(slot.target_ship)
			if view == null:
				continue
			var colour := UiColours.ENEMY_RED if slot.autofire else UiColours.TARGET_YELLOW
			if ship != selected_ship:
				colour = Color(colour, 0.45)
			if slot.def.type == "beam":
				view.beam_marks.append({"start": slot.beam_start, "end": slot.beam_end, "colour": colour})
			else:
				view.target_marks.append({"cell": slot.target_cell, "label": index + 1, "colour": colour})
	if aim_mode == "beam" and _beam_target != null and views.has(_beam_target):
		var mouse_local := encounter.world_to_local(_beam_target, world.get_global_mouse_position())
		var direction := (mouse_local - _beam_start_local)
		if direction.length() > 1.0:
			var end := _beam_start_local + direction.normalized() * aim_slot.def.beam_length
			views[_beam_target].beam_marks.append({"start": _beam_start_local, "end": end, "colour": UiColours.TARGET_YELLOW})


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


# --- What happened: effects, sounds, decisions ----------------------------------------------------------------

func _read_notes() -> void:
	for note in encounter.notes:
		_show_note(note)
		if run:
			run.log_note(note)
	encounter.notes.clear()


func _show_note(note: Dictionary) -> void:
	var ship: Ship = note.get("ship") if note.get("ship") is Ship else null
	match note.kind:
		"shot":
			var weapon: WeaponDef = note.weapon
			Sfx.play("missile" if weapon.type == "missile" else ("laser_heavy" if weapon.damage >= 2 else "laser"), -6.0 if ship and ship.side == 1 else -3.0)
		"volley":
			var weapon: WeaponDef = note.weapon
			if weapon.type == "beam":
				Sfx.play("beam")
			elif weapon.type == "bomb":
				Sfx.play("teleport", -6.0)
		"hit":
			var damage: int = note.damage
			var at: Vector2 = note.position
			effects.explosion(at, 0.7 + 0.25 * damage)
			if damage > 0:
				effects.float_text(at + Vector2(0, -20), str(damage), UiColours.DAMAGED_RED, 26)
			Sfx.play("hit_hull" if damage > 0 else "hit_soft")
			if ship and ship.side == 0:
				shake(4.0 + damage * 2.0)
		"shield_hit":
			views[ship].shield_hit(note.position)
			effects.shield_sparks(note.position, UiColours.SHIELD_BLUE)
			Sfx.play("hit_shield")
		"supershield_hit":
			views[ship].shield_hit(note.position, true)
			effects.shield_sparks(note.position, UiColours.SUPERSHIELD)
			Sfx.play("hit_shield")
		"miss":
			effects.float_text(note.position, "MISS", Color(0.85, 0.9, 1.0), 20)
		"intercept", "shot_down":
			effects.small_burst(note.position, Color(1.0, 0.6, 0.9))
			Sfx.play("intercept")
		"ship_destroyed":
			_ship_explodes(ship)
		"crew_died":
			if ship and note.has("crew"):
				var member: CrewMember = note.crew
				member.selected = false
				selected_crew.erase(member)
				if note.position != Vector2.ZERO:
					effects.small_burst(encounter.local_to_world(ship, note.position), Color(1.0, 0.3, 0.3))
			Sfx.play("crew_death")
		"teleported":
			Sfx.play("teleport")
			var target: Ship = note.target
			for member in target.crew + target.visitors:
				if member.teleporting_ticks > 0 and member.ship == target:
					effects.sparkle(encounter.local_to_world(target, member.position), Color(0.7, 0.9, 1.0))
		"suit_launched":
			Sfx.play("launch")
		"suit_hit", "suit_destroyed":
			effects.explosion(note.position, 0.5, Color(0.8, 0.4, 1.0))
		"fire_started":
			Sfx.play("fire", -8.0)
		"breach":
			Sfx.play("breach", -4.0)
		"skill_up":
			var member: CrewMember = note.crew
			if member.side == 0 and member.is_active():
				effects.float_text(encounter.local_to_world(member.ship, member.position) + Vector2(0, -24), "+ " + str(note.skill).capitalize(), UiColours.POWER_GREEN, 17)
		"flare":
			Sfx.play("flare")
			shake(3.0)
		"surrender_offer":
			paused = true
			surrender_offered.emit(ship)
		"enemy_escaped":
			effects.sparkle(ship.world_position, Color(0.8, 0.9, 1.0))
			Sfx.play("jump")
		"no_mawjig":
			hud.flash_message("Not enough Mawjig to fire.")
		"fight_over":
			_on_fight_over(note.outcome)
		"squad_lost":
			squad_lost.emit()
		"cloaked":
			Sfx.play("cloak")


## The squad's Jigawatt Drives fire: the ships stretch toward the rim and the screen flashes white.
func play_jump_out() -> void:
	hold_pause = true
	var tween := create_tween()
	tween.set_parallel(true)
	for ship in encounter.living(0):
		var view: ShipView = views[ship]
		tween.tween_property(view, "scale", Vector2(0.6, 2.6), 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.tween_property(view, "modulate", Color(2.5, 2.5, 3.0, 0.0), 0.55).set_ease(Tween.EASE_IN)
	tween.tween_property(_flash, "color", Color(1, 1, 1, 0.9), 0.55).set_delay(0.2)
	await tween.finished
	hold_pause = false


func play_jump_in() -> void:
	var tween := create_tween()
	tween.tween_property(_flash, "color", Color(1, 1, 1, 0.0), 0.7)


func _ship_explodes(ship: Ship) -> void:
	Sfx.play("explosion_big")
	var view: ShipView = views[ship]
	var bounds := Formation.hull_bounds(ship.design)
	for index in 9:
		var local := Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y)) * 0.6
		var at := encounter.local_to_world(ship, local)
		get_tree().create_timer(index * 0.18).timeout.connect(func(): effects.explosion(at, 1.4 + randf()))
	shake(10.0)
	view.modulate = Color(1.5, 1.2, 1.0)


func _on_fight_over(outcome: String) -> void:
	aim_mode = ""
	divider.visible = false
	for ship in encounter.living(0):
		for slot in ship.weapons:
			slot.clear_target()
	get_tree().create_timer(1.6).timeout.connect(func():
		frame_everything()
		fight_over.emit(outcome))


var _shake := 0.0
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _physics_process(delta: float) -> void:
	if _shake > 0.1:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake / camera.zoom.x * 0.5
		_shake *= pow(0.02, delta)
	else:
		camera.offset = Vector2.ZERO


# --- Input ----------------------------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if encounter == null or hold_pause:
		return
	if camera.handle_drag(event):
		return
	if event is InputEventMouseMotion:
		_update_hover()
		if _box_selecting:
			hud.box_rect = Rect2(_drag_start, event.position - _drag_start).abs()
	elif event is InputEventMouseButton:
		_mouse_button(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_key(event)


func _mouse_button(event: InputEventMouseButton) -> void:
	var view_size := get_viewport().get_visible_rect().size
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		camera.zoom_at(event.position, 1.12, view_size)
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		camera.zoom_at(event.position, 1.0 / 1.12, view_size)
		return
	_update_hover()
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if aim_mode != "":
			if aim_slot:
				aim_slot.clear_target()
			cancel_aim()
		elif not selected_crew.is_empty():
			_order_selected_to_hover()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if aim_mode != "":
			_click_while_aiming(event)
			return
		if hover_crew and hover_crew.side == 0:
			_select_crew([hover_crew], event.shift_pressed)
			return
		if hover_door and hover_ship and hover_ship.side == 0:
			toggle_door(hover_ship, hover_door)
			return
		if not selected_crew.is_empty() and hover_room >= 0:
			_order_selected_to_hover()
			return
		_drag_start = event.position
		_box_selecting = true
		hud.box_rect = Rect2(event.position, Vector2.ZERO)
	else:
		if aim_mode == "beam" and _beam_target != null:
			_finish_beam()
			return
		if _box_selecting:
			_box_selecting = false
			var box: Rect2 = hud.box_rect
			hud.box_rect = Rect2()
			if box.size.length() > 8.0:
				_box_select(box)
			elif hover_ship and hover_ship.side == 0:
				selected_ship = hover_ship
				_select_crew([], false)


func _click_while_aiming(event: InputEventMouseButton) -> void:
	if hover_ship == null or hover_ship.side != 1 or hover_ship.is_gone():
		var suit := _suit_under_mouse()
		if aim_mode == "weapon" and suit:
			aim_slot.target_suit = suit
			aim_slot.target_ship = null
			aim_slot.autofire = _aim_is_autofire()
			Sfx.play("target")
			cancel_aim()
		return
	match aim_mode:
		"weapon":
			if hover_room < 0:
				return
			aim_slot.aim_at(hover_ship, hover_cell)
			aim_slot.autofire = _aim_is_autofire()
			Sfx.play("target")
			cancel_aim()
		"beam":
			if hover_room < 0:
				return
			_beam_target = hover_ship
			_beam_start_local = encounter.world_to_local(hover_ship, world.get_global_mouse_position())
		"teleport":
			if hover_room >= 0 and encounter.send_boarders(selected_ship, hover_ship, hover_room):
				cancel_aim()
			else:
				hud.flash_message("The teleporter can't reach that room.")
		"suit":
			if encounter.launch_suit(selected_ship, hover_ship):
				cancel_aim()
			else:
				hud.flash_message("No one is ready in the EVB Dock.")


func _finish_beam() -> void:
	var end_local := encounter.world_to_local(_beam_target, world.get_global_mouse_position())
	var direction := end_local - _beam_start_local
	if direction.length() < 4.0:
		direction = Vector2.RIGHT
	var start_cell := Vector2i(floor((_beam_start_local - _beam_target.design.cell_offset) / ShipDesign.TILE))
	if _beam_target.room_at(start_cell) < 0:
		start_cell = _beam_target.rooms[0].cells[0]
	aim_slot.aim_at(_beam_target, start_cell)
	aim_slot.beam_start = _beam_start_local
	aim_slot.beam_end = _beam_start_local + direction.normalized() * aim_slot.def.beam_length
	aim_slot.autofire = _aim_is_autofire()
	_beam_target = null
	Sfx.play("target")
	cancel_aim()


func _aim_is_autofire() -> bool:
	return autofire_default != Input.is_key_pressed(KEY_CTRL)


func _key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_SPACE:
			toggle_pause()
		KEY_ESCAPE:
			if aim_mode != "":
				cancel_aim()
			else:
				menu_pressed.emit()
		KEY_V:
			toggle_autofire()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			var index: int = event.keycode - KEY_1
			if selected_ship and index < selected_ship.weapons.size():
				arm_weapon(selected_ship.weapons[index])
		KEY_TAB:
			cycle_ship()
		KEY_HOME, KEY_F:
			frame_everything()
		KEY_J:
			jump_pressed.emit()
		KEY_U:
			ship_screen_pressed.emit()
		KEY_T:
			start_teleport()
		KEY_E:
			start_suit_launch()
		KEY_C:
			if selected_ship:
				encounter.cloak(selected_ship)
		KEY_Z:
			return_to_stations()


func _update_hover() -> void:
	var world_point := world.get_global_mouse_position()
	hover_ship = null
	hover_room = -1
	hover_cell = Vector2i(999, 999)
	hover_crew = null
	hover_door = null
	for ship in encounter.ships:
		if ship.is_gone():
			continue
		var local := encounter.world_to_local(ship, world_point)
		for member in ship.crew + ship.visitors:
			if member.ship == ship and member.is_active() and member.position.distance_to(local) <= ShipView.TOKEN_RADIUS + 2.0:
				if member.side == 0 or views[ship].interior_visible:
					hover_crew = member
		var cell := Vector2i(floor((local - ship.design.cell_offset) / ShipDesign.TILE))
		var room := ship.room_at(cell)
		for door in ship.doors:
			var middle := ship.design.cell_centre(door.cell_a) + Vector2(door.direction) * ShipDesign.TILE * 0.5
			if middle.distance_to(local) < 8.0:
				hover_door = door
				hover_ship = ship
		if room >= 0:
			hover_ship = ship
			hover_room = room
			hover_cell = cell
			return


func _suit_under_mouse() -> Battlesuit:
	var world_point := world.get_global_mouse_position()
	for suit in encounter.suits:
		if not suit.gone and suit.side == 1 and suit.position.distance_to(world_point) < 24.0:
			return suit
	return null


# --- Orders the HUD and the mouse give ------------------------------------------------------------------------

func toggle_pause() -> void:
	paused = not paused
	auto_pause_ticks = 0
	Sfx.play("pause" if paused else "unpause")


func toggle_autofire() -> void:
	autofire_default = not autofire_default
	for ship in encounter.living(0):
		for slot in ship.weapons:
			if slot.has_target():
				slot.autofire = autofire_default


func arm_weapon(slot: WeaponSlot) -> void:
	if slot.def.type == "suit":
		return
	if not slot.powered:
		if not selected_ship.set_weapon_powered(slot, true):
			if selected_ship.reactor_type == "pool" and selected_ship.reactor_free() < slot.def.power:
				hud.flash_message("Not enough reactor power.")
			else:
				hud.flash_message("The Weapons system can't hold more power.")
			Sfx.play("deny")
			return
		Sfx.play("power_up")
	aim_slot = slot
	aim_mode = "beam" if slot.def.type == "beam" else "weapon"
	Sfx.play("arm")


func cancel_aim() -> void:
	aim_mode = ""
	aim_slot = null
	_beam_target = null


func start_teleport() -> void:
	if selected_ship and encounter.can_teleport(selected_ship) and encounter.in_fight():
		aim_mode = "teleport"
	else:
		hud.flash_message("The teleporter isn't ready.")


func recall_boarders() -> void:
	if selected_ship and not encounter.recall_boarders(selected_ship):
		hud.flash_message("The teleporter isn't ready.")


func start_suit_launch() -> void:
	if selected_ship and selected_ship.system_by("evb_dock") and encounter.in_fight():
		aim_mode = "suit"


func cycle_ship() -> void:
	var ships := encounter.living(0)
	if ships.is_empty():
		return
	var index := ships.find(selected_ship)
	selected_ship = ships[(index + 1) % ships.size()]
	_select_crew([], false)


func select_ship(ship: Ship) -> void:
	selected_ship = ship
	_select_crew([], false)


func _select_crew(members: Array, add: bool) -> void:
	if not add:
		for member in selected_crew:
			member.selected = false
		selected_crew.clear()
	for member in members:
		if not selected_crew.has(member):
			selected_crew.append(member)
			member.selected = true
			if member.home.side == 0:
				selected_ship = member.home
	if not members.is_empty():
		Sfx.play("select")


func select_crew_member(member: CrewMember, add: bool) -> void:
	_select_crew([member], add)


func _box_select(box: Rect2) -> void:
	var picked: Array = []
	var view_size := get_viewport().get_visible_rect().size
	for ship in encounter.ships:
		for member in ship.crew:
			if member.side != 0 or not member.is_active():
				continue
			var world_point := encounter.local_to_world(member.ship, member.position)
			var screen := (world_point - camera.position) * camera.zoom.x + view_size * 0.5
			if box.has_point(screen):
				picked.append(member)
	_select_crew(picked, Input.is_key_pressed(KEY_SHIFT))


## Sends the selected crew to the tile under the cursor: the first to that tile, the others to the free tiles of
## the same room nearest to it.
func _order_selected_to_hover() -> void:
	if hover_ship == null or hover_room < 0:
		return
	var movers: Array[CrewMember] = []
	for member in selected_crew:
		if member.ship == hover_ship and member.is_active():
			movers.append(member)
	if movers.is_empty():
		return
	for member in movers:
		member.destination = Vector2i(999, 999)   # let go of old claims so the group can share the room
	var room := hover_ship.rooms[hover_room]
	var free: Array[Vector2i] = []
	for cell in room.cells:
		if not hover_ship.cell_is_claimed(cell, 0):
			free.append(cell)
	free.sort_custom(func(a, b): return Vector2(a - hover_cell).length_squared() < Vector2(b - hover_cell).length_squared())
	var moved := false
	for index in movers.size():
		if index >= free.size():
			break
		if CrewBrain.walk_to(movers[index], free[index], true):
			moved = true
	for member in movers:
		if member.destination == Vector2i(999, 999):
			member.destination = member.path.back() if not member.path.is_empty() else member.cell
	if moved:
		Sfx.play("order")


func toggle_door(ship: Ship, door: ShipDoor) -> void:
	if not ship.doors_controllable():
		hud.flash_message("The Doors system isn't working.")
		Sfx.play("deny")
		return
	door.held_open = not door.held_open
	Sfx.play("door")


func set_all_doors(ship: Ship, open: bool, airlocks: bool) -> void:
	if not ship.doors_controllable():
		hud.flash_message("The Doors system isn't working.")
		return
	for door in ship.doors:
		if door.to_space == airlocks or not open:
			door.held_open = open
	Sfx.play("door")


func return_to_stations() -> void:
	var ships: Array[Ship] = [selected_ship] if selected_ship else []
	for ship in ships:
		for member in ship.crew:
			if member.ship == ship and member.can_act():
				CrewBrain.order_to_room(member, member.station_room, true)


func save_stations() -> void:
	if selected_ship == null:
		return
	for member in selected_ship.crew:
		if member.ship == selected_ship and not member.dead:
			member.station_room = selected_ship.room_at(member.destination if not member.path.is_empty() else member.cell)
	hud.flash_message("Stations saved.")
