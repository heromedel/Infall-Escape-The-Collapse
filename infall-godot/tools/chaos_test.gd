extends Node
## Plays a run the way a careless or curious player would and reports what breaks: random clicks and right
## clicks all over the screen, double clicks, drags, wheel spam, random hotkeys, windows opened and closed in
## quick succession, jumping as often as it can, buying everything, fights started in the middle of events,
## pause spam, window resizes, save and continue, and crew ordered everywhere. Every couple of seconds it checks
## the game's invariants and prints a FAIL line for each one that is broken.
##
## Run: tools/chaos.sh (several seeds, headless or with xvfb), or one run:
##   CHAOS_SEED=3 CHAOS_SECONDS=120 godot --headless --path . --log-file /tmp/chaos.log tools/chaos_test.tscn
## Env: CHAOS_SEED (default 1), CHAOS_SECONDS (default 120), CHAOS_LOG (the engine log to scan for errors: pass
## the same path as --log-file, as chaos.sh does; without it, user://logs/godot.log), CHAOS_VERBOSE=1 prints every action. Runs one at a
## time: the game keeps one save file. Timing is real time, so the same seed takes the same choices but a
## fight can play out differently from run to run.

const CHECK_SECONDS := 2.0
const STUCK_SECONDS := 20.0
const SPIKE_MS := 1000
const DANGEROUS_BUTTONS := ["quit the game", "QUIT", "logs folder"]   # would end the test or open a file browser
const KEYS := [KEY_SPACE, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_TAB, KEY_HOME, KEY_F, KEY_J, KEY_U, KEY_T,
		KEY_E, KEY_C, KEY_Z, KEY_V, KEY_ESCAPE, KEY_QUOTELEFT, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_ENTER, KEY_H, KEY_Q]
const CONSOLE_COMMANDS := ["help", "mawjig 5", "mawjig 50", "mawjig", "heal", "fight", "fight terran-pirates", "fight nonsense",
		"win", "reveal", "band 2", "band 99", "band -1", "ship patrol-cutter", "ship nonsense", "crew", "crew dog",
		"mawjig abc", "", "   ", "win now please"]

var main: Node
var rng := RandomNumberGenerator.new()
var seed_value := 1
var budget := 120.0
var verbose := false
var only: PackedStringArray = []          # CHAOS_ONLY=probe,jump: just these actions, to reproduce one thing
var log_path := ""
var _log_pos := 0
var _start_ms := 0
var _last_frame_us := 0
var _check_left := CHECK_SECONDS
var _blocked_for := 0.0
var _held_without_window_for := 0.0
var _window_without_hold_for := 0.0
var _overdraw: Dictionary = {}           # "ship:system" -> seen on the previous check
var _done := false
var _action := "start"
var _recent: Array[String] = []
var fails: Dictionary = {}                # what -> count
var fail_order: Array[String] = []
var counts: Dictionary = {}               # action -> count
var errors_seen: Dictionary = {}          # error text -> count
var runs_started := 0
var jumps_made := 0
var bought := 0
var continues := 0
var spikes := 0
var _saved_user_files: Dictionary = {}


func _ready() -> void:
	seed_value = int(OS.get_environment("CHAOS_SEED")) if OS.get_environment("CHAOS_SEED") != "" else 1
	budget = float(OS.get_environment("CHAOS_SECONDS")) if OS.get_environment("CHAOS_SECONDS") != "" else 120.0
	verbose = OS.get_environment("CHAOS_VERBOSE") == "1"
	if OS.get_environment("CHAOS_ONLY") != "":
		only = OS.get_environment("CHAOS_ONLY").split(",", false)
	log_path = OS.get_environment("CHAOS_LOG")
	if log_path.is_empty():
		log_path = ProjectSettings.globalize_path(String(ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log")))
	_log_pos = _log_size()
	rng.seed = seed_value
	seed(seed_value)
	OS.set_environment("INFALL_SEED", str(seed_value * 7919 + 13))
	_keep_user_files()
	print("CHAOS START seed %d, %d s, display %s, log %s" % [seed_value, int(budget), DisplayServer.get_name(), log_path])
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_start_ms = Time.get_ticks_msec()
	_last_frame_us = Time.get_ticks_usec()
	await _frames(10)
	_new_run()
	await _wait(1.0)
	while _elapsed() < budget and not _done:
		await _random_action()
	_finish()


# --- The checks -----------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _done:
		return
	var now := Time.get_ticks_usec()
	var frame_ms := (now - _last_frame_us) / 1000
	_last_frame_us = now
	if frame_ms > SPIKE_MS and _elapsed() > 3.0:
		spikes += 1
		_fail("frame took %d ms (after %s)" % [frame_ms, _action], "frame spike")
	_track_blocking(delta)
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = CHECK_SECONDS
		_check_invariants()
		_scan_log()
	if _elapsed() > budget + 60.0:
		_fail("the chaos driver hung in '%s' for over a minute" % _action, "driver hung")
		_finish()


func _check_invariants() -> void:
	var run: RunState = main.run
	if run == null:
		return
	if run.mawjig < 0:
		_fail("Mawjig is negative: %d (after %s)" % [run.mawjig, _action], "mawjig negative")
	var ships: Array = run.squad.duplicate()
	if main.encounter:
		for ship in main.encounter.ships:
			if not ships.has(ship):
				ships.append(ship)
	for ship in ships:
		_check_ship(ship)
	var battle: BattleScreen = main.battle
	if battle and battle.encounter and not battle.encounter.living(0).is_empty():
		var selected := battle.selected_ship
		if selected == null:
			_fail("no ship is selected though the squad has %d living (after %s)" % [battle.encounter.living(0).size(), _action], "selected ship null")
		elif not battle.encounter.ships.has(selected):
			_fail("the selected ship %s is not in the encounter (after %s)" % [selected.name, _action], "selected ship not in encounter")
		elif selected.is_gone():
			_fail("the selected ship %s is gone but still selected while %d others live (after %s)" % [selected.name, battle.encounter.living(0).size(), _action], "selected ship gone")
		var counted := _windows().filter(func(w): return not w is RoomPicker).size()
		var drifted: bool = main._overlay_count != counted
		var drifted_before: bool = _overdraw.get("overlay_count", false)
		_overdraw["overlay_count"] = drifted
		if drifted and drifted_before:
			_fail("Main._overlay_count is %d but %d windows are open %s (after %s); the battle unpauses when it reaches 0" % [main._overlay_count, counted, _names(_windows()), _action], "overlay counter drifted")
		for member in battle.selected_crew:
			if member.dead:
				_fail("dead crew member %s is still selected" % member.name, "dead crew selected")


func _check_ship(ship: Ship) -> void:
	var tag := "%s (side %d)" % [ship.name, ship.side]
	if ship.hull > ship.max_hull or (ship.hull < 0 and not ship.destroyed) or ship.max_hull <= 0:
		_fail("%s hull %d of %d" % [tag, ship.hull, ship.max_hull], "hull out of range")
	if ship.hull < 0:
		_fail("%s hull went below zero: %d" % [tag, ship.hull], "hull negative")
	for member in ship.crew + ship.visitors:
		if member.dead:
			continue
		if is_nan(member.health) or member.health < 0.0:
			_fail("%s: crew %s is alive with health %s" % [tag, member.name, str(member.health)], "crew alive with bad health")
		elif member.health > member.max_health + 0.01:
			_fail("%s: crew %s health %.1f above max %.1f" % [tag, member.name, member.health, member.max_health], "crew health above max")
		if member.ship == null or member.home == null:
			_fail("%s: crew %s has no ship" % [tag, member.name], "crew without ship")
	for system in ship.systems:
		var power := ship.system_power(system)
		if power > system.level or system.power > system.level:
			_fail("%s %s has power %d (given %d) above its level %d" % [tag, system.display_name(), power, system.power, system.level], "system power above level")
		if system.damage > system.level or system.damage < 0 or system.ion > system.level:
			_fail("%s %s damage %d ion %d level %d" % [tag, system.display_name(), system.damage, system.ion, system.level], "system damage/ion out of range")
		if system.room < 0 or system.room >= ship.rooms.size():
			_fail("%s %s sits in room %d of %d" % [tag, system.display_name(), system.room, ship.rooms.size()], "system room out of range")
	if ship.reactor_type == "pool" and not ship.is_gone():
		var key := ship.name + ":reactor"
		if ship.reactor_used() > ship.reactor_total():
			if _overdraw.get(key, false):
				_fail("%s uses %d reactor bars of %d on two checks running" % [tag, ship.reactor_used(), ship.reactor_total()], "reactor overdrawn")
			_overdraw[key] = true
		else:
			_overdraw[key] = false
		var weapons := ship.system_by("weapons")
		if weapons and ship.powered_weapon_load() > maxi(0, weapons.usable_bars() - weapons.ion) + 0:
			if _overdraw.get(key + "w", false):
				_fail("%s powers %d weapon bars on a weapons system with %d usable" % [tag, ship.powered_weapon_load(), weapons.usable_bars() - weapons.ion], "weapons overpowered")
			_overdraw[key + "w"] = true
		else:
			_overdraw[key + "w"] = false


## Input is blocked when a window is open or the battle is held; a window open for 20 s while the chaos keeps
## clicking every button means it is stuck. The battle held with no window, or running under one, is a bug too.
func _track_blocking(delta: float) -> void:
	var battle: BattleScreen = main.battle
	if battle == null:
		_blocked_for = 0.0
		return
	var windows := _windows()
	var blocked := battle.hold_pause or not windows.is_empty()
	_blocked_for = _blocked_for + delta if blocked else 0.0
	if _blocked_for > STUCK_SECONDS:
		_fail("input blocked for %d s: windows %s, hold_pause %s (after %s)" % [int(_blocked_for), _names(windows), battle.hold_pause, _action], "input blocked over 20 s")
		_blocked_for = 0.0
		_force_close_windows()
	_held_without_window_for = _held_without_window_for + delta if battle.hold_pause and windows.is_empty() else 0.0
	if _held_without_window_for > 3.0:
		_fail("the battle is held (hold_pause) with no window open for 3 s (after %s)" % _action, "hold_pause stuck without window")
		_held_without_window_for = -1000.0
	var real_windows := windows.filter(func(w): return not w is RoomPicker)
	_window_without_hold_for = _window_without_hold_for + delta if not real_windows.is_empty() and not battle.hold_pause else 0.0
	if _window_without_hold_for > 1.0:
		_fail("the battle runs while %s is open (hold_pause false) (after %s)" % [_names(real_windows), _action], "battle runs under a window")
		_window_without_hold_for = -1000.0


## New engine errors in the log: script errors, push_error and engine errors, each with its "at:" line.
func _scan_log() -> void:
	var size := _log_size()
	if size <= _log_pos:
		_log_pos = mini(_log_pos, size)
		return
	var file := FileAccess.open(log_path, FileAccess.READ)
	if file == null:
		return
	file.seek(_log_pos)
	var text := file.get_buffer(size - _log_pos).get_string_from_utf8()
	_log_pos = size
	var lines := text.split("\n")
	for index in lines.size():
		var line := lines[index].strip_edges()
		if line.begins_with("SCRIPT ERROR") or line.begins_with("ERROR:") or line.begins_with("USER ERROR") or line.begins_with("USER SCRIPT ERROR"):
			var at := lines[index + 1].strip_edges() if index + 1 < lines.size() else ""
			var key := line + "  " + at
			errors_seen[key] = errors_seen.get(key, 0) + 1
			if errors_seen[key] == 1:
				_fail("engine error: %s  %s  (around %s)" % [line, at, _action], "error: " + line.left(90))
			else:
				fails["error: " + line.left(90)] = fails.get("error: " + line.left(90), 0) + 1


func _log_size() -> int:
	if log_path.is_empty() or not FileAccess.file_exists(log_path):
		return 0
	var file := FileAccess.open(log_path, FileAccess.READ)
	return file.get_length() if file else 0


func _fail(text: String, key: String) -> void:
	fails[key] = fails.get(key, 0) + 1
	if fails[key] == 1:
		fail_order.append(key)
	if fails[key] <= 3:
		print("FAIL %s  [t=%.1f s]" % [text, _elapsed()])
		if fails[key] == 1:
			print("     recent actions: ", " | ".join(_recent.slice(-10)))


func _exit_tree() -> void:
	if not _done:
		print("FAIL the game quit by itself during '%s' (recent: %s)" % [_action, " | ".join(_recent.slice(-8))])
		print("CHAOS ABORTED seed %d after %.0f s" % [seed_value, _elapsed()])
		_restore_user_files()


func _finish() -> void:
	if _done:
		return
	_scan_log()
	_done = true
	_restore_user_files()
	print("CHAOS DONE seed %d: %.0f s, %d actions, %d runs started, %d jumps, %d bought, %d continues, %d frame spikes, %d distinct failures, %d distinct engine errors" % [
			seed_value, _elapsed(), _total_actions(), runs_started, jumps_made, bought, continues, spikes, fails.size(), errors_seen.size()])
	for key in fail_order:
		print("  %4d x %s" % [fails[key], key])
	var listed := counts.keys()
	listed.sort()
	print("  actions: ", ", ".join(listed.map(func(k): return "%s %d" % [k, counts[k]])))
	get_tree().quit(1 if not fails.is_empty() else 0)


# --- Choosing what to do --------------------------------------------------------------------------------------

func _random_action() -> void:
	if main.battle == null:
		await _do("title", _from_title)
		return
	var choices := [
		["click", 14, _click_anywhere], ["right_click", 8, _right_click_anywhere], ["double_click", 4, _double_click],
		["drag", 4, _drag_box], ["middle_drag", 2, _middle_drag], ["wheel", 3, _wheel_spam], ["key", 12, _random_key],
		["window_button", 16, _press_window_button], ["hud", 10, _click_hud_region], ["crew_order", 8, _order_crew],
		["aim", 5, _aim_weapon], ["windows_rapid", 5, _windows_rapid], ["jump", 7, _jump], ["buy_all", 4, _buy_everything],
		["fight_mid_event", 2, _fight_mid_event], ["pause_spam", 3, _pause_spam], ["resize", 2, _resize],
		["save_continue", 3, _save_and_continue], ["console", 3, _console], ["let_it_run", 5, _let_it_run],
		["probe", 3, _probe],
	]
	if not only.is_empty():
		choices = choices.filter(func(c): return only.has(c[0]))
	var total := 0
	for choice in choices:
		total += choice[1]
	var roll := rng.randi_range(1, total)
	for choice in choices:
		roll -= choice[1]
		if roll <= 0:
			await _do(choice[0], choice[2])
			return


func _do(name: String, action: Callable) -> void:
	_action = name
	counts[name] = counts.get(name, 0) + 1
	_recent.append("%.1f %s" % [_elapsed(), name])
	if _recent.size() > 30:
		_recent.pop_front()
	if verbose:
		print("  [%.1f] %s" % [_elapsed(), name])
	await action.call()
	await _frames(rng.randi_range(0, 3))


func _note(text: String) -> void:
	_recent.append("    " + text)
	if verbose:
		print("      ", text)


# --- Actions ----------------------------------------------------------------------------------------------------

func _from_title() -> void:
	await _frames(5)
	if main.battle != null:
		return
	var buttons := _buttons()
	if not buttons.is_empty() and rng.randf() < 0.7:
		var button: Button = buttons[rng.randi() % buttons.size()]
		_note("title: " + button.text.left(30))
		await _click(_centre(button), MOUSE_BUTTON_LEFT)
		await _wait(0.3)
	if main.battle == null and _windows().filter(func(w): return w is Overlay).is_empty():
		_new_run()
		await _wait(0.5)


func _new_run() -> void:
	runs_started += 1
	_note("start_new_run")
	main.start_new_run("outrider")


func _click_anywhere() -> void:
	await _click(_random_point(), MOUSE_BUTTON_LEFT)


func _right_click_anywhere() -> void:
	await _click(_random_point(), MOUSE_BUTTON_RIGHT)


func _double_click() -> void:
	var at := _random_point()
	var ship := _random_ship()
	if ship and rng.randf() < 0.6:
		at = _ship_screen(ship, Formation.hull_bounds(ship.design).get_center())
	await _click(at, MOUSE_BUTTON_LEFT)
	await _click(at, MOUSE_BUTTON_LEFT, true)


func _drag_box() -> void:
	var from := _random_point()
	var to := from + Vector2(rng.randf_range(-700, 700), rng.randf_range(-500, 500))
	if rng.randf() < 0.5 and main.battle and main.battle.aim_mode == "":
		# A beam: arm a beam weapon if there is one, then press on an enemy and drag
		var ship: Ship = main.battle.selected_ship
		if ship:
			for index in ship.weapons.size():
				if ship.weapons[index].def.type == "beam":
					await _key(KEY_1 + index)
		var enemy := _random_ship(1)
		if enemy:
			from = _ship_screen(enemy, enemy.design.cell_centre(enemy.rooms[rng.randi() % enemy.rooms.size()].cells[0]))
			to = from + Vector2(rng.randf_range(-200, 200), rng.randf_range(-200, 200))
	await _drag(from, to, MOUSE_BUTTON_LEFT)


func _middle_drag() -> void:
	var from := _random_point()
	await _drag(from, from + Vector2(rng.randf_range(-900, 900), rng.randf_range(-600, 600)), MOUSE_BUTTON_MIDDLE)


func _wheel_spam() -> void:
	var at := _random_point()
	var up := rng.randf() < 0.5
	for count in rng.randi_range(3, 30):
		await _button_event(at, MOUSE_BUTTON_WHEEL_UP if (up if rng.randf() < 0.8 else not up) else MOUSE_BUTTON_WHEEL_DOWN, true)
		await _button_event(at, MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN, false)


func _random_key() -> void:
	var code: int = KEYS[rng.randi() % KEYS.size()]
	_note("key " + OS.get_keycode_string(code))
	await _key(code)
	if code in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN] and rng.randf() < 0.5:
		# Hold an arrow for a moment
		_key_event(code, true)
		await _wait(rng.randf_range(0.2, 1.5))
		_key_event(code, false)


func _press_window_button() -> void:
	var buttons := _buttons()
	if buttons.is_empty():
		await _click_anywhere()
		return
	var button: Button = buttons[rng.randi() % buttons.size()]
	_note("button '%s' in %s" % [button.text.left(40).replace("\n", " "), _owner_window(button)])
	await _click(_centre(button), MOUSE_BUTTON_LEFT, rng.randf() < 0.1)
	# A careless player presses Space or Enter right after, with that button still focused
	if rng.randf() < 0.15:
		await _key(KEY_SPACE if rng.randf() < 0.5 else KEY_ENTER)


func _click_hud_region() -> void:
	var battle: BattleScreen = main.battle
	if battle == null or battle.hud._regions.is_empty():
		return
	var region: Dictionary = battle.hud._regions[rng.randi() % battle.hud._regions.size()]
	var at: Vector2 = region.rect.get_center()
	_note("hud '%s'" % String(region.tooltip).left(40).replace("\n", " "))
	await _click(at, MOUSE_BUTTON_LEFT if rng.randf() < 0.7 else MOUSE_BUTTON_RIGHT)


func _order_crew() -> void:
	var battle: BattleScreen = main.battle
	if battle == null or battle.encounter == null:
		return
	var crew: Array = []
	for ship in battle.encounter.ships:
		for member in ship.crew:
			if member.side == 0 and member.is_active() and member.ship != null:
				crew.append(member)
	if crew.is_empty():
		return
	var member: CrewMember = crew[rng.randi() % crew.size()]
	await _click(_ship_screen(member.ship, member.position), MOUSE_BUTTON_LEFT)
	for count in rng.randi_range(1, 3):
		var ship := _random_ship(-1 if rng.randf() < 0.3 else 0)
		if ship == null:
			return
		var room: ShipRoom = ship.rooms[rng.randi() % ship.rooms.size()]
		var cell: Vector2i = room.cells[rng.randi() % room.cells.size()]
		await _click(_ship_screen(ship, ship.design.cell_centre(cell)), MOUSE_BUTTON_RIGHT if rng.randf() < 0.7 else MOUSE_BUTTON_LEFT)
	if rng.randf() < 0.3:
		await _key(KEY_Z)


func _aim_weapon() -> void:
	var battle: BattleScreen = main.battle
	if battle == null or battle.selected_ship == null:
		return
	var count := battle.selected_ship.weapons.size()
	await _key(KEY_1 + rng.randi_range(0, maxi(count, 1)))
	var enemy := _random_ship(1)
	if enemy:
		var room: ShipRoom = enemy.rooms[rng.randi() % enemy.rooms.size()]
		await _click(_ship_screen(enemy, enemy.design.cell_centre(room.cells[0])), MOUSE_BUTTON_LEFT)
	if rng.randf() < 0.2:
		await _key(KEY_V)


## Opens and closes the map, store, ship screen, menu and hail in quick succession, as fast as frames allow,
## only the ways a player can: hotkeys and the HUD's buttons.
func _windows_rapid() -> void:
	var openers := [
		[KEY_J, ""], [KEY_U, ""], [KEY_ESCAPE, ""], [0, "Open the map"], [0, "Upgrade systems"], [0, "Trade at"],
		[0, "Hail the enemy"], [0, "Menu. Hotkey"],
	]
	for count in rng.randi_range(2, 8):
		if main.battle == null:
			return
		var opener: Array = openers[rng.randi() % openers.size()]
		if opener[0] != 0:
			await _key(opener[0])
		else:
			await _click_hud(opener[1], MOUSE_BUTTON_LEFT)
		await _frames(rng.randi_range(0, 2))
		if rng.randf() < 0.4:
			await _press_window_button()
	_note("windows now " + _names(_windows()))


func _jump() -> void:
	if main.battle == null:
		return
	if _windows().is_empty() or rng.randf() < 0.5:
		await _key(KEY_J)
		await _frames(2)
	var map: MapScreen = null
	for window in _windows():
		if window is MapScreen:
			map = window
	if map == null:
		return
	var run: RunState = main.run
	var links: Array = run.cluster().links.filter(func(index): return run.can_jump_to(index))
	if links.is_empty():
		_note("no cluster to jump to")
		return
	var target: int = links[rng.randi() % links.size()]
	var stores: Array = links.filter(func(index): return run.galaxy.clusters[index].store)
	if not stores.is_empty() and rng.randf() < 0.6:
		target = stores[rng.randi() % stores.size()]   # stores are where the buying happens
	var at: Vector2 = map.get_global_transform() * map._to_screen(run.galaxy.clusters[target].position)
	var before := run.jumps
	await _click(at, MOUSE_BUTTON_LEFT)
	await _click(at, MOUSE_BUTTON_LEFT, true)
	await _frames(2)
	if rng.randf() < 0.3:
		# Impatient: press J and click JUMP again while the drive is firing
		await _key(KEY_J)
		await _click_hud("Open the map", MOUSE_BUTTON_LEFT)
	await _wait(1.0)
	if main.run and main.run.jumps > before:
		jumps_made += 1
		_note("jumped to " + str(main.run.cluster().name))


func _buy_everything() -> void:
	if main.battle == null or main.encounter == null or main.encounter.in_fight():
		return
	if main.battle.store_here:
		await _click_hud("Trade at", MOUSE_BUTTON_LEFT)
		await _frames(3)
	elif _windows().is_empty() and rng.randf() < 0.4:
		main.open_store()   # a shortcut: stores are rare on the map, and the store's buttons are what is tested here
		_note("store opened through the API at a cluster without one")
		await _frames(3)
	var store: StoreWindow = null
	for window in _windows():
		if window is StoreWindow:
			store = window
	if store == null:
		return
	for attempt in 6:
		if not is_instance_valid(store):
			return
		var priced := store.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree() and not b.disabled and (b.text.contains(".") or b.text.to_upper().begins_with("BUY") or b.text.to_upper().begins_with("REPAIR") or b.text.to_upper().begins_with("SELL")))
		if priced.is_empty():
			break
		var button: Button = priced[rng.randi() % priced.size()]
		var mawjig: int = main.run.mawjig
		_note("buy '%s'" % button.text.left(30))
		await _click(_centre(button), MOUSE_BUTTON_LEFT)
		await _frames(2)
		# The low Mawjig warning asks first: buying everything means spending it anyway
		if is_instance_valid(store):
			for each in _buttons_in(store):
				if each.text == "Spend it anyway":
					await _click(_centre(each), MOUSE_BUTTON_LEFT)
					await _frames(2)
					break
		# A room picker may ask where to install a system
		for window in _windows():
			if window is RoomPicker:
				var choices := _buttons_in(window)
				if not choices.is_empty():
					await _click(_centre(choices[rng.randi() % choices.size()]), MOUSE_BUTTON_LEFT)
		if main.run and main.run.mawjig < mawjig:
			bought += 1


## The admin console's fight command while an event or any window is open: a fight starts mid-event.
func _fight_mid_event() -> void:
	if main.run == null:
		return
	_note("fight with windows " + _names(_windows()))
	main.console._run("fight")
	await _frames(3)


func _pause_spam() -> void:
	for count in rng.randi_range(4, 30):
		if rng.randf() < 0.5:
			await _key(KEY_SPACE)
		else:
			await _click_hud("Pause or unpause", MOUSE_BUTTON_LEFT)


func _resize() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var sizes := [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(800, 600), Vector2i(640, 360), Vector2i(2560, 1080), Vector2i(1080, 1920), Vector2i(320, 240)]
	var wanted: Vector2i = sizes[rng.randi() % sizes.size()]
	_note("resize %s" % wanted)
	get_window().size = wanted
	await _frames(3)


func _save_and_continue() -> void:
	if main.run == null or main.battle == null:
		return
	if rng.randf() < 0.5:
		# The player's way: Esc for the menu, "Save and quit to the title", then CONTINUE RUN
		await _key(KEY_ESCAPE)
		await _frames(2)
		for button in _buttons():
			if button.text.begins_with("Save and quit to the title"):
				await _click(_centre(button), MOUSE_BUTTON_LEFT)
				break
		await _frames(4)
		for button in _buttons():
			if button.text == "CONTINUE RUN":
				var mawjig: int = main.run.mawjig if main.run else -1
				await _click(_centre(button), MOUSE_BUTTON_LEFT)
				await _frames(3)
				continues += 1
				if main.run and main.run.mawjig != mawjig:
					_note("continued with Mawjig %d, saved %d" % [main.run.mawjig, mawjig])
				break
	else:
		main.run.save_to_disk()
		main.show_title()
		await _frames(rng.randi_range(0, 3))
		main.continue_run()
		continues += 1
	await _frames(3)


func _console() -> void:
	await _key(KEY_QUOTELEFT)
	await _frames(1)
	if main.console.visible and rng.randf() < 0.7:
		var command: String = CONSOLE_COMMANDS[rng.randi() % CONSOLE_COMMANDS.size()]
		_note("console '%s'" % command)
		main.console._input.text = command
		main.console._input.text_submitted.emit(command)
		await _frames(2)
	await _key(KEY_QUOTELEFT)
	await _frames(1)
	if main.console.visible:
		_fail("the backtick key does not close the console once it is open: the command line now reads '%s'" % main.console._input.text, "console will not close with backtick")
		# What gets a player out: Esc, then backtick; or a click on the ship view, then backtick
		await _key(KEY_ESCAPE)
		await _key(KEY_QUOTELEFT)
		if main.console.visible:
			await _click(Vector2(960, 700), MOUSE_BUTTON_LEFT)
			await _key(KEY_QUOTELEFT)
			if main.console.visible:
				_fail("the console stays open after Esc + backtick and after a click on the ship view + backtick: the command line keeps the keyboard", "console cannot be closed by keys")
				main.console.toggle()
			else:
				_note("console closed after a click on the ship view, then backtick")
		else:
			_note("console closed after Esc, then backtick")


func _let_it_run() -> void:
	if main.battle and main.battle.paused and rng.randf() < 0.7:
		main.battle.paused = false
	await _wait(rng.randf_range(0.5, 3.0))


# --- Probes: one adversarial sequence with an expected result ------------------------------------------------

func _probe() -> void:
	var probes := [_probe_hud_under_window, _probe_space_on_focused_button, _probe_escape_closes_map, _probe_drag_into_window,
			_probe_jump_right_after_win, _probe_keys_after_squad_lost, _probe_save_in_fight, _probe_jump_with_boarders_out,
			_probe_move_every_crew_member_off_a_ship]
	var wanted := OS.get_environment("CHAOS_PROBE")
	if wanted != "":
		probes = probes.filter(func(p): return String(p.get_method()).contains(wanted))
		if probes.is_empty():
			return
	if not _windows().is_empty():
		_force_close_windows()   # each probe starts from the bare ship view
		await _frames(3)
	await probes[rng.randi() % probes.size()].call()


## A click on the HUD under an open window must not reach the HUD.
func _probe_hud_under_window() -> void:
	var battle: BattleScreen = main.battle
	if battle == null or main.encounter.in_fight() or not _windows().is_empty():
		return
	main.open_ship_screen()
	await _frames(3)
	var window := _windows().filter(func(w): return w is ShipScreen)
	if window.is_empty():
		return
	var paused := battle.paused
	await _click_hud("Pause or unpause", MOUSE_BUTTON_LEFT)
	if battle.paused != paused:
		_fail("a click on the HUD's pause button under the open ship screen toggles pause (BattleHud._input ignores windows)", "HUD clicks go through windows")
	var count := _windows().size()
	await _click_hud("Menu. Hotkey", MOUSE_BUTTON_LEFT)
	if _windows().size() > count:
		_fail("a click on the HUD's menu button under the open ship screen opens the pause menu on top of it", "HUD clicks go through windows")
	for each in _windows():
		if each is Overlay:
			each.close()


## Space is the pause key; with a window's button focused after a click it must not press that button again.
func _probe_space_on_focused_button() -> void:
	if main.battle == null or not _windows().is_empty():
		return
	main.open_menu()
	await _frames(3)
	var settings := _buttons().filter(func(b): return b.text == "Settings")
	if settings.is_empty():
		return
	await _click(_centre(settings[0]), MOUSE_BUTTON_LEFT)
	await _frames(2)
	var before := _windows().size()
	var focused := get_viewport().gui_get_focus_owner()
	await _key(KEY_SPACE)
	await _frames(2)
	if _windows().size() > before:
		_fail("Space with a window button focused presses it again (opened '%s' twice)" % (focused.text if focused is Button else "?"), "Space presses the focused button")
	for each in _windows():
		if each is Overlay:
			each.close()


func _probe_escape_closes_map() -> void:
	if main.battle == null or not _windows().is_empty():
		return
	main.open_map()
	await _frames(3)
	if _windows().filter(func(w): return w is MapScreen).is_empty():
		return
	await _key(KEY_ESCAPE)
	await _frames(2)
	var still := _windows().filter(func(w): return w is MapScreen)
	if not still.is_empty():
		_fail("Esc does not close the map (MapScreen._gui_input only gets keys with focus)", "Esc does not close the map")
		still[0].closed.emit()


## Press the middle button to pan, a window opens before the release: the camera must not keep panning.
func _probe_drag_into_window() -> void:
	var battle: BattleScreen = main.battle
	if battle == null or not _windows().is_empty():
		return
	var from := Vector2(960, 500)
	await _motion(from, Vector2.ZERO, 0)
	await _button_event(from, MOUSE_BUTTON_MIDDLE, true)
	if main.encounter.in_fight():
		main.open_menu()
	else:
		main.open_ship_screen()
	await _frames(2)
	await _button_event(from + Vector2(50, 0), MOUSE_BUTTON_MIDDLE, false)
	for each in _windows():
		if each is Overlay:
			each.close()
	await _frames(3)
	var before := battle.camera.target_position
	await _motion(from + Vector2(300, 200), Vector2(250, 200), 0)
	await _frames(2)
	if battle and is_instance_valid(battle) and battle.camera.target_position != before:
		_fail("the camera keeps panning with plain mouse moves after a middle drag whose release fell on a window", "camera stuck dragging")
		await _button_event(from, MOUSE_BUTTON_MIDDLE, true)
		await _button_event(from, MOUSE_BUTTON_MIDDLE, false)


## Win a fight and jump at once, in the 1.6 s before the victory window: the fight's rewards must still be paid.
func _probe_jump_right_after_win() -> void:
	if main.run == null or main.battle == null:
		return
	main.console._run("fight terran-pirates")
	await _frames(3)
	_force_close_windows()
	await _frames(2)
	if not main.encounter.in_fight():
		return
	var fight: Encounter = main.encounter
	main.battle.paused = false
	main.console._run("win")
	await _frames(3)
	if fight.outcome != "won":
		return
	var before: int = main.run.mawjig
	var jumps: int = main.run.jumps
	if main.run.mawjig < Mawjig.JUMP_COST:
		main.console._run("mawjig 2")   # the map only offers a jump the squad can pay for
	main.open_map()
	await _frames(2)
	for window in _windows():
		if window is MapScreen:
			var links: Array = main.run.cluster().links.filter(func(index): return main.run.can_jump_to(index))
			if not links.is_empty():
				window.jump_chosen.emit(links[0])
	await _wait(3.0)
	if main.run.jumps == jumps:
		return
	var expected := 0
	for enemy in fight.enemy_ships():
		expected += Mawjig.amount(enemy.design.value * 0.025 * main.run.band_adjustment() / 100.0)
	var gained: int = main.run.mawjig - before + Mawjig.JUMP_COST
	if gained < expected:
		_fail("jumping in the 1.6 s after winning loses the fight's reward: expected about +%s, got %s (fight_rewards reads main.encounter, which is the new cluster's by then)" % [Mawjig.format(expected), Mawjig.format(gained)], "jump right after a win loses the reward")


## After the last ship is lost, the keys and HUD buttons that open windows must not reach for a ship that is gone.
func _probe_keys_after_squad_lost() -> void:
	if main.run == null or main.battle == null:
		return
	_force_close_windows()
	await _frames(2)
	main.console._run("fight terran-pirates")
	await _frames(3)
	_force_close_windows()
	await _frames(2)
	main.battle.paused = false
	for ship in main.run.living_ships():
		ship.damage_hull(ship.hull)
	await _wait(0.4)
	var errors := errors_seen.size()
	await _key(KEY_U)
	await _key(KEY_J)
	await _click_hud("Upgrade systems", MOUSE_BUTTON_LEFT)
	await _wait(3.0)   # the end screen comes after 2.5 s
	await _click_hud("Upgrade systems", MOUSE_BUTTON_LEFT)
	await _click_hud("Open the map", MOUSE_BUTTON_LEFT)
	await _frames(3)
	_scan_log()
	if errors_seen.size() > errors:
		_note("errors after the squad was lost: %d new" % (errors_seen.size() - errors))
	_note("windows after squad lost: " + _names(_windows()))
	_force_close_windows()
	if main.battle == null:
		return
	await _frames(2)
	main.show_title()
	await _frames(3)


## Save and quit to the title in the middle of a fight, then continue: the fight should still be there.
func _probe_save_in_fight() -> void:
	if main.run == null or main.battle == null:
		return
	_force_close_windows()
	await _frames(2)
	main.console._run("fight terran-pirates")
	await _frames(3)
	_force_close_windows()
	await _frames(2)
	if not main.encounter.in_fight():
		return
	await _key(KEY_ESCAPE)
	await _frames(2)
	for button in _buttons_in(_windows().back() if not _windows().is_empty() else main):
		if button.text.begins_with("Save and quit to the title"):
			await _click(_centre(button), MOUSE_BUTTON_LEFT)
			break
	await _frames(3)
	for button in _buttons():
		if button.text == "CONTINUE RUN":
			await _click(_centre(button), MOUSE_BUTTON_LEFT)
			break
	await _frames(3)
	if main.encounter and not main.encounter.in_fight():
		_fail("Save and quit to the title in a fight, then CONTINUE RUN: the fight is gone (the cluster replays as visited); quitting escapes any fight for free", "save and continue drops the fight")


## Board an enemy ship with the teleporter (a Packrunner from the console's ship command), then jump away mid-fight:
## the boarders should come home, or be lost, not stay on a ship that is no longer anywhere.
func _probe_jump_with_boarders_out() -> void:
	if main.run == null or main.battle == null:
		return
	_force_close_windows()
	await _frames(2)
	if main.run.living_ships().filter(func(s): return s.has_system("teleporter")).is_empty():
		main.console._run("ship packrunner")
		await _frames(3)
		_force_close_windows()
	main.console._run("fight terran-pirates")
	await _frames(3)
	_force_close_windows()
	await _frames(2)
	var raiders: Array = main.encounter.living(0).filter(func(s): return s.has_system("teleporter"))
	if raiders.is_empty() or main.encounter.living(1).is_empty():
		return
	var raider: Ship = raiders[0]
	var enemy: Ship = main.encounter.living(1)[0]
	main.battle.select_ship(raider)
	main.battle.paused = false
	var pad: int = raider.system_by("teleporter").room
	for member in raider.crew:
		if member.can_act():
			CrewBrain.order_to_room(member, pad, true)   # as the player would: send them to the teleporter room
	await _wait(4.0)
	raider.teleporter_cooldown = 0   # skip the rest of the 12 s wait at the start of a fight
	var sent := false
	for attempt in 3:
		await _key(KEY_T)
		await _click(_ship_screen(enemy, enemy.design.cell_centre(enemy.rooms[0].cells[0])), MOUSE_BUTTON_LEFT)
		sent = raider.crew.any(func(m): return m.ship == enemy)
		if sent:
			break
		main.encounter.send_boarders(raider, enemy, 0)   # the click missed the room: the same order through the API
		sent = raider.crew.any(func(m): return m.ship == enemy)
		if sent:
			break
	if not sent:
		_note("could not send boarders")
		return
	for ship in main.encounter.living(0):
		ship.jump_charge = Ship.JUMP_FULL   # the drive is charged, as it would be after a while
	if main.run.mawjig < Mawjig.JUMP_COST:
		main.console._run("mawjig 2")   # the map only offers a jump the squad can pay for
	main.open_map()
	await _frames(2)
	for window in _windows():
		if window is MapScreen:
			var links: Array = main.run.cluster().links.filter(func(index): return main.run.can_jump_to(index))
			if not links.is_empty():
				window.jump_chosen.emit(links[0])
	await _wait(2.0)
	var stranded: Array = raider.crew.filter(func(m): return not m.dead and not main.encounter.ships.has(m.ship))
	if not stranded.is_empty():
		_fail("after jumping away with boarders on the enemy ship, %d crew stay alive on a ship that is not in the new encounter (never ticked, not drawn, still counted as crew)" % stranded.size(), "boarders stranded after jumping away")


## On the ship screen, move every crew member of one ship to another with the TO buttons (DISMISS keeps the last
## one; TO does not). An emptied ship should stay in the squad, or the button should refuse.
func _probe_move_every_crew_member_off_a_ship() -> void:
	if main.run == null or main.battle == null or main.encounter.in_fight():
		return
	_force_close_windows()
	await _frames(2)
	if main.run.living_ships().size() < 2:
		main.console._run("ship tentauri-scout")
		await _frames(3)
		_force_close_windows()
		await _frames(2)
	if main.run.living_ships().size() < 2 or main.encounter.in_fight():
		return
	var donor: Ship = main.run.living_ships().back()
	main.battle.select_ship(donor)
	await _key(KEY_U)
	await _frames(3)
	for attempt in 8:
		var screen: Array = _windows().filter(func(w): return w is ShipScreen)
		if screen.is_empty():
			return
		var moves: Array = _buttons_in(screen[0]).filter(func(b): return b.text.begins_with("TO ") and b.text != "TO HOLD")
		if moves.is_empty():
			break
		await _click(_centre(moves[0]), MOUSE_BUTTON_LEFT)
		await _frames(2)
	var left: int = donor.living_crew_count()
	for each in _windows():
		if each is ShipScreen:
			for button in _buttons_in(each):
				if button.text == "DONE":
					await _click(_centre(button), MOUSE_BUTTON_LEFT)
					break
	await _wait(0.5)
	_note("moved crew off the %s: %d left, gone %s" % [donor.name, left, donor.is_gone()])
	if left == 0 and (donor.is_gone() or not main.run.squad.has(donor)):
		_fail("moving every crew member off the %s with the ship screen's TO buttons makes it count as lost (crew_dead), so it leaves the squad with its weapons and systems, with no warning" % donor.name, "emptied ship is deleted")


# --- Mouse and keys ---------------------------------------------------------------------------------------------

func _click(at: Vector2, button: int, double: bool = false) -> void:
	await _motion(at, Vector2.ZERO, 0)
	if _is_dangerous(get_viewport().gui_get_hovered_control()):
		_note("skipped a click on a quit button")
		return
	await _button_event(at, button, true, double)
	await _button_event(at, button, false)


func _drag(from: Vector2, to: Vector2, button: int) -> void:
	await _motion(from, Vector2.ZERO, 0)
	if _is_dangerous(get_viewport().gui_get_hovered_control()):
		return
	await _button_event(from, button, true)
	var steps := rng.randi_range(2, 8)
	var last := from
	var mask := MOUSE_BUTTON_MASK_LEFT if button == MOUSE_BUTTON_LEFT else (MOUSE_BUTTON_MASK_MIDDLE if button == MOUSE_BUTTON_MIDDLE else MOUSE_BUTTON_MASK_RIGHT)
	for step in steps:
		var point := from.lerp(to, float(step + 1) / steps)
		await _motion(point, point - last, mask)
		last = point
	await _button_event(to, button, false)


func _motion(at: Vector2, relative: Vector2, mask: int) -> void:
	var window_point: Vector2 = get_viewport().get_final_transform() * at
	Input.warp_mouse(window_point)
	var event := InputEventMouseMotion.new()
	event.position = window_point
	event.global_position = window_point
	event.relative = relative
	event.button_mask = mask
	Input.parse_input_event(event)
	await _frames(1)


func _button_event(at: Vector2, button: int, pressed: bool, double: bool = false) -> void:
	var window_point: Vector2 = get_viewport().get_final_transform() * at
	var event := InputEventMouseButton.new()
	event.position = window_point
	event.global_position = window_point
	event.button_index = button
	event.pressed = pressed
	event.double_click = double and pressed
	Input.parse_input_event(event)
	await _frames(1)


func _key(code: int) -> void:
	_key_event(code, true)
	await _frames(1)
	_key_event(code, false)
	await _frames(1)


func _key_event(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	if code == KEY_QUOTELEFT:
		event.unicode = 96
	elif code == KEY_SPACE:
		event.unicode = 32
	elif code >= KEY_A and code <= KEY_Z:
		event.unicode = code + 32
	elif code >= KEY_0 and code <= KEY_9:
		event.unicode = code
	Input.parse_input_event(event)


func _click_hud(tooltip_start: String, button: int) -> void:
	if main.battle == null:
		return
	for region in main.battle.hud._regions:
		if String(region.tooltip).begins_with(tooltip_start):
			await _click(region.rect.get_center(), button)
			return


# --- Looking at the screen ---------------------------------------------------------------------------------------

func _windows() -> Array:
	var list: Array = []
	if main == null:
		return list
	for child in main.overlays.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion() and not child is TitleScreen:
			list.append(child)
	return list


func _names(windows: Array) -> String:
	return "[" + ", ".join(windows.map(_name_of)) + "]"


func _name_of(node: Node) -> String:
	if not is_instance_valid(node):
		return "freed"
	var script: Script = node.get_script()
	if script and script.get_global_name() != "":
		return String(script.get_global_name())
	return node.get_class()


## The buttons a player can reach: the top window's (windows fill the screen and stop clicks below them), and
## now and then any window's, to see whether a click gets through.
func _buttons() -> Array:
	var list: Array = []
	if main == null:
		return list
	var open: Array = []
	for child in main.overlays.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			open.append(child)
	if open.is_empty():
		return list
	if rng.randf() < 0.85:
		return _buttons_in(open.back())
	for child in open:
		list.append_array(_buttons_in(child))
	return list


func _buttons_in(node: Node) -> Array:
	return node.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree() and not b.disabled and not _is_dangerous(b))


func _is_dangerous(control: Control) -> bool:
	if not control is Button:
		return false
	for words in DANGEROUS_BUTTONS:
		if control.text.contains(words):
			return true
	return false


func _owner_window(node: Node) -> String:
	while node and node.get_parent() != main.overlays:
		node = node.get_parent()
	return _names([node]) if node else "?"


func _centre(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


func _random_point() -> Vector2:
	var size := get_viewport().get_visible_rect().size
	if rng.randf() < 0.25:
		# The HUD bands at the top and bottom, where most buttons are
		return Vector2(rng.randf() * size.x, rng.randf() * 120.0 if rng.randf() < 0.5 else size.y - rng.randf() * 200.0)
	return Vector2(rng.randf() * size.x, rng.randf() * size.y)


func _random_ship(side: int = -1) -> Ship:
	if main.encounter == null:
		return null
	var ships: Array = main.encounter.ships.filter(func(s): return not s.is_gone() and (side < 0 or s.side == side))
	return ships[rng.randi() % ships.size()] if not ships.is_empty() else null


func _ship_screen(ship: Ship, local: Vector2) -> Vector2:
	return main.battle.world.get_global_transform_with_canvas() * main.encounter.local_to_world(ship, local)


func _force_close_windows() -> void:
	for window in _windows():
		if window is MapScreen:
			window.closed.emit()
		elif window is Overlay:
			window.close()
		else:
			window.queue_free()


func _total_actions() -> int:
	var total := 0
	for key in counts:
		total += counts[key]
	return total


func _elapsed() -> float:
	return (Time.get_ticks_msec() - _start_ms) / 1000.0 if _start_ms > 0 else 0.0


func _frames(count: int) -> void:
	for index in count:
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## The chaos clicks every settings button and wins runs; the player's own settings, profile and save come back after.
func _keep_user_files() -> void:
	for path in ["user://settings.cfg", "user://profile.cfg", RunState.SAVE_PATH]:
		_saved_user_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null


func _restore_user_files() -> void:
	for path in _saved_user_files:
		if _saved_user_files[path] == null:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file:
				file.store_buffer(_saved_user_files[path])
