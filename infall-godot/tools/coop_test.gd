extends Node
## Players sharing a screen (GV 4F): controllers drop in with Start, each gets their own view, cursor and selection,
## and their orders reach the battle. Saves screenshots of two and four players. Controllers are simulated: their
## buttons as joypad events, their cursors moved by setting where they point.
## Run with a display: xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1920x1080 tools/coop_test.tscn

var main: Node
var failures := 0
var out := ""


func _ready() -> void:
	out = OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/claude-0/coop"
	DirAccess.make_dir_recursive_absolute(out)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RunState.SAVE_PATH))
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(0.4)
	main.start_new_run("outrider")
	await _wait(0.6)
	await _answer_shared_windows()
	_check("one player: one view, the whole screen", main.battle.player_views.size() == 1)
	# A controller presses Start: a second player, a second view
	await _pad_button(0, JOY_BUTTON_START)
	await _wait(0.4)
	_check("Start on a controller adds a player", main.session.local_players().size() == 2)
	_check("two players: two views side by side", main.battle.player_views.size() == 2 and main.battle.player_views[1].display.position.x > 100.0)
	var keys_view: PlayerView = main.battle.player_views[0]
	var pad_view: PlayerView = main.battle.player_views[1]
	_check("the controller's view draws its cursor", pad_view.show_cursor and not keys_view.show_cursor)
	# The controller selects a crew member with X and sends them with A; the mouse player's selection stays its own
	var ship: Ship = pad_view.selected_ship
	var member: CrewMember = ship.crew[0]
	pad_view.pointer = pad_view.world_to_screen(main.encounter.local_to_world(ship, member.position))
	await _pad_move(pad_view)
	await _pad_button(0, JOY_BUTTON_X)
	_check("the controller's X selects a crew member", pad_view.selected_crew.has(member))
	_check("the mouse player's selection is untouched", keys_view.selected_crew.is_empty())
	var engines := ship.system_by("engines")
	var tile: Vector2i = ship.rooms[engines.room].cells.back()
	pad_view.pointer = pad_view.world_to_screen(main.encounter.local_to_world(ship, ship.design.cell_centre(tile)))
	await _pad_move(pad_view)
	await _pad_button(0, JOY_BUTTON_A)
	await _wait(0.3)
	_check("the controller's A orders them to the tile", member.destination == tile)
	await _wait(0.6)
	await _shot("two_players")
	# The controller opens the map in its own view; the mouse player's view stays clear
	await _pad_button(0, JOY_BUTTON_BACK)
	await _wait(0.3)
	_check("View opens the players menu in the controller's view", pad_view.has_window() and not keys_view.has_window())
	await _shot("players_menu")
	await _pad_button(0, JOY_BUTTON_B)
	await _wait(0.3)
	_check("B closes it", not pad_view.has_window())
	# Two more controllers: quarters
	await _pad_button(1, JOY_BUTTON_START)
	await _pad_button(2, JOY_BUTTON_START)
	await _wait(0.5)
	_check("four players: four views", main.battle.player_views.size() == 4)
	await _shot("four_players")
	# A fight with four views
	main.start_fight("terran-pirates")
	main.battle.paused = false
	await _wait(3.0)
	await _shot("four_players_fight")
	# Only the Admiral pauses
	await _pad_button(1, JOY_BUTTON_LEFT_STICK)
	await _wait(0.3)
	_check("a controller player who isn't the Admiral can't pause", not main.battle.paused)
	# A controller leaves: back to three views
	var leaving: int = main.battle.player_views[3].player_id
	main.session.remove_local_player(leaving)
	await _wait(0.3)
	_check("a player who leaves takes their view with them", main.battle.player_views.size() == 3)
	print("PASS" if failures == 0 else "FAIL: %d" % failures)
	get_tree().quit()


func _answer_shared_windows() -> void:
	for attempt in 8:
		var open: Array = main.overlays.get_children().filter(func(w): return w is Overlay and w.shared and not w.is_queued_for_deletion())
		if open.is_empty():
			return
		var window: Overlay = open.back()
		main.session.submit(main.session.admiral, {"k": "shared", "w": window.serial, "pg": window.page, "i": 0})
		await _wait(0.3)


func _pad_button(device: int, button: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = device
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await _wait(0.05)


## A controller's stick moves its view's pointer; the view hears the move as the mouse's.
func _pad_move(view: PlayerView) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = view.pointer
	motion.global_position = view.pointer
	view.viewport.push_input(motion)
	await _wait(0.05)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _check(what: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
