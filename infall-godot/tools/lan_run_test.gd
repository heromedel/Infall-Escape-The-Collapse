extends Node
## A longer stretch of a run over LAN (GV 4C) than lan_test: a fight won, a purchase by each machine, the client
## leaving and coming back while the host jumps (with orders queued behind the jump), an event, a rule change,
## a wait, a second fight with orders from the client, then both machines paused on the same tick and their state
## compared. Run it with tools/lan_run_test.sh, which starts both machines on one clock and compares what they print.
## REJOIN_AFTER_JUMP (seconds, default 0.15) is how long after the host's jump order the client comes back; the jump
## plays for about half a second, and the host prints whether the client arrived while it was playing.

var main: Node
var role := ""
var failures := 0
var desyncs := 0
var start_at := 0.0
var joined_while_busy := false


func _ready() -> void:
	role = OS.get_environment("ROLE")
	start_at = float(OS.get_environment("START_AT"))
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.session.note.connect(func(text: String):
		print("[%s] note: %s" % [role, text])
		if text.contains("out of step"):
			desyncs += 1
		if text.ends_with("joined.") and main.session.busy:
			joined_while_busy = true)
	await _until(0.0)
	if role == "host":
		await _host()
	else:
		await _client()
	_check("no machine fell out of step", desyncs == 0)
	await _until(40.0)
	var crew := 0
	if main.run:
		for ship in main.run.squad:
			crew += ship.living_crew_count()
		print("STATE jumps=%d current=%d mawjig=%d crew=%d tick=%d checksum=%d difficulty=%s" % [main.run.jumps, main.run.current,
				main.run.mawjig, crew, main.encounter.tick_count if main.encounter else -1, main.checksum(), Settings.get_value("difficulty", "?")])
	print("[%s] %s" % [role, "PASS" if failures == 0 else "FAIL: %d" % failures])
	await _wait(1.0)
	get_tree().quit()


func _host() -> void:
	_check("the host opens to LAN", main.session.host_lan() == "")
	main.start_new_run("outrider")
	await _wait(0.5)
	await _answer()
	_console("mawjig 60")
	_console("fight terran-pirates")
	await _wait(0.5)
	_admiral({"k": "pause", "on": false})
	await _answering_until(8.0)
	_check("a LAN player joined mid-fight", main.session.players.size() == 2)
	_console("win")
	await _answering_until(13.0)
	_check("the fight is over", main.encounter != null and not main.encounter.in_fight())
	var crew_before := _crew()
	_admiral({"k": "refit", "op": "buy_crew", "race": "terran", "index": 0, "price": 101, "sq": 0})
	await _until(15.0)
	_check("the host's purchase and the client's both went through", _crew() == crew_before + 2)
	# The jump, with two orders queued behind it; the client is rejoining about now
	var target := -1
	for index in main.run.galaxy.clusters.size():
		if target < 0 and main.run.can_jump_to(index):
			target = index
	var jumps_before: int = main.run.jumps
	_admiral({"k": "jump", "to": target})
	_admiral({"k": "refit", "op": "buy_crew", "race": "terran", "index": 0, "price": 103, "sq": 0})   # the next cluster's first
	_admiral({"k": "door", "s": 0, "d": 1})
	await _answering_until(20.0)
	_check("the squad jumped", main.run.jumps == jumps_before + 1)
	_check("the purchase queued behind the jump went through once", _crew() == crew_before + 3)
	print("[host] the client rejoined while the jump was playing: %s" % joined_while_busy)
	_admiral({"k": "rule", "id": "difficulty", "value": "Hard"})
	await _answering_until(21.0)
	_admiral({"k": "wait"})
	await _answering_until(24.0)
	_console("fight terran-pirates")
	await _wait(0.5)
	_admiral({"k": "pause", "on": false})
	await _answering_until(34.0)
	print("[host] second fight: paused=%s held=%s ticks=%d shared windows=%d" % [main.battle.paused, main._held(), main.encounter.tick_count, main._shared_windows().size()])
	_check("the second fight ran", main.encounter.tick_count > 100)
	_check("the client is in the game at the end", main.session.players.filter(func(p): return p.here).size() == 2)
	_admiral({"k": "pause", "on": true})


func _client() -> void:
	await _until(2.0)
	_check("joining starts", main.session.join_lan("127.0.0.1", "Lan Tester") == "")
	await _until(5.0)
	_check("the client caught up into the fight", main.run != null and main.encounter != null and main.encounter.in_fight())
	var me: int = main.session.first_local_id()
	main.session.submit(me, {"k": "door", "s": 0, "d": 0})
	await _until(13.5)
	var crew_before := _crew()
	main.session.submit(me, {"k": "refit", "op": "buy_crew", "race": "terran", "index": 1, "price": 107, "sq": 0})
	await _until(14.3)
	_check("the client's purchase went through", _crew() == crew_before + 1)
	main.session.leave_lan()
	await _until(15.0 + float(OS.get_environment("REJOIN_AFTER_JUMP") if OS.get_environment("REJOIN_AFTER_JUMP") != "" else "0.15"))
	_check("rejoining starts", main.session.join_lan("127.0.0.1", "Lan Tester") == "")
	await _until(19.0)
	_check("the client is back in the run after the jump", main.run != null and main.run.jumps >= 1)
	_check("the client has its old place back", main.session.players.size() == 2)
	await _until(27.0)
	me = main.session.first_local_id()
	_check("the client is in the second fight", main.encounter != null and main.encounter.in_fight())
	main.session.submit(me, {"k": "door", "s": 0, "d": 0})
	main.session.submit(me, {"k": "stations", "s": 0})
	await _until(36.0)
	_check("the game was paused by the Admiral at the end", main.battle.paused)


func _crew() -> int:
	var count := 0
	for ship in main.run.squad:
		count += ship.living_crew_count()
	return count


func _console(text: String) -> void:
	_admiral({"k": "console", "text": text})


func _admiral(order: Dictionary) -> void:
	main.session.submit(main.session.admiral, order)


## Answers whatever shared window is open, as the Admiral (the host's player).
func _answer() -> void:
	for attempt in 6:
		var open: Array = main.overlays.get_children().filter(func(w): return w is Overlay and w.shared and w.visible and not w.is_queued_for_deletion())
		if open.is_empty():
			return
		var window: Overlay = open.back()
		_admiral({"k": "shared", "w": window.serial, "pg": window.page, "i": 0})
		await _wait(0.3)


func _answering_until(mark: float) -> void:
	while Time.get_unix_time_from_system() - start_at < mark:
		await _answer()
		await _wait(0.25)


func _until(mark: float) -> void:
	var left := start_at + mark - Time.get_unix_time_from_system()
	if left > 0.0:
		await _wait(left)


func _check(what: String, ok: bool) -> void:
	print("[%s] %s  %s" % [role, "PASS" if ok else "FAIL", what])
	if not ok:
		failures += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
