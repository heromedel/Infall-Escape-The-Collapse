extends Node
## Two machines over LAN (GV 4C), run as two copies of the game on one computer: ROLE=host opens a game and plays,
## ROLE=client joins it partway through, catches up, gives orders, and both check they see the same run. Run both:
##   ROLE=host godot --headless --path . tools/lan_test.tscn & sleep 3; ROLE=client godot --headless --path . tools/lan_test.tscn

const SECONDS := 26.0

var main: Node
var role := ""
var failures := 0
var desyncs := 0
var _started := 0.0


func _ready() -> void:
	role = OS.get_environment("ROLE")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.session.note.connect(func(text: String):
		print("[%s] note: %s" % [role, text])
		if text.contains("out of step"):
			desyncs += 1)
	await _wait(0.4)
	_started = Time.get_ticks_msec() / 1000.0
	if role == "host":
		await _host()
	else:
		await _client()
	print("[%s] %s" % [role, "PASS" if failures == 0 else "FAIL: %d" % failures])
	get_tree().quit()


func _host() -> void:
	_check("the host opens to LAN", main.session.host_lan() == "")
	main.start_new_run("outrider")
	await _wait(0.5)
	await _answer()
	main.session.submit(1, {"k": "console", "text": "fight terran-pirates"})
	await _wait(0.5)
	main.session.submit(1, {"k": "pause", "on": false})
	# Play until the client has joined and given its orders
	while Time.get_ticks_msec() / 1000.0 - _started < SECONDS - 4.0:
		await _answer()
		await _wait(0.5)
	_check("a LAN player joined", main.session.players.size() == 2)
	var client: Dictionary = main.session.players.back() if main.session.players.size() == 2 else {}
	_check("the LAN player is not the Admiral", not client.is_empty() and not main.session.is_admiral(client.id))
	var ship: Ship = main.run.squad[0]
	_check("the client's door order reached the host", ship.doors[0].held_open)
	print("[host] checksum %d at tick %d" % [main.checksum(), main.encounter.tick_count])
	await _wait(3.0)


func _client() -> void:
	_check("joining starts", main.session.join_lan("127.0.0.1", "Lan Tester") == "")
	var waited := 0.0
	while main.run == null and waited < 8.0:
		await _wait(0.2)
		waited += 0.2
	_check("the run arrives from the host", main.run != null)
	if main.run == null:
		return
	await _wait(2.0)
	_check("the client caught up into the fight", main.encounter != null and main.encounter.in_fight())
	_check("the client's player is listed", main.session.local_players().size() == 1)
	var me: int = main.session.first_local_id()
	# Orders from the client: open a door; try to pause (only the Admiral may)
	main.session.submit(me, {"k": "door", "s": 0, "d": 0})
	main.session.submit(me, {"k": "pause", "on": true})
	await _wait(1.5)
	_check("the client sees its own door order played", main.run.squad[0].doors[0].held_open)
	_check("the client could not pause", not main.battle.paused)
	while Time.get_ticks_msec() / 1000.0 - _started < SECONDS - 6.0:
		await _wait(0.5)
	_check("no machine fell out of step", desyncs == 0)
	if main.encounter:
		print("[client] checksum %d at tick %d" % [main.checksum(), main.encounter.tick_count])
	main.session.leave_lan()


## Answers whatever shared window is open, as the Admiral (the host's player).
func _answer() -> void:
	for attempt in 6:
		var open: Array = main.overlays.get_children().filter(func(w): return w is Overlay and w.shared and w.visible and not w.is_queued_for_deletion())
		if open.is_empty():
			return
		var window: Overlay = open.back()
		main.session.submit(main.session.admiral, {"k": "shared", "w": window.serial, "pg": window.page, "i": 0})
		await _wait(0.3)


func _check(what: String, ok: bool) -> void:
	print("[%s] %s  %s" % [role, "PASS" if ok else "FAIL", what])
	if not ok:
		failures += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
