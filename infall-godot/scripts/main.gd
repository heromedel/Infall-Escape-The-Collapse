extends Node
## Main: the flow of the game, read top to bottom (coding rule 8). It shows the title, starts or loads a run,
## and at each cluster plays the arrival events, any fight and its rewards, then lets the squad trade, refit
## and jump on, until the squad reaches the rim or is lost. Screens report what the player chose; Main decides
## what happens next and calls the screen that shows it.

var run: RunState
var runner: EventRunner
var battle: BattleScreen
var encounter: Encounter
var enemy_squad: SquadDef
var overlays := CanvasLayer.new()
var title: TitleScreen
var console := DebugConsole.new()


func _ready() -> void:
	overlays.layer = 20
	add_child(overlays)
	add_child(GamepadInput.new())
	var console_layer := CanvasLayer.new()
	console_layer.layer = 50
	add_child(console_layer)
	console.main = self
	console_layer.add_child(console)
	add_child(BattleWarmup.new())
	show_title()
	if OS.has_environment("INFALL_SMOKE"):
		_smoke_test()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		console.toggle()
		get_viewport().set_input_as_handled()


## A quick check that a build loads its content and can start a run: INFALL_SMOKE=1 ./Infall
func _smoke_test() -> void:
	print("content: %d ships, %d weapons, %d systems, %d races, %d squads, %d events" % [Library.ships.size(), Library.weapons.size(), Library.systems.size(), Library.races.size(), Library.squads.size(), Library.events.size()])
	start_new_run("outrider")
	await get_tree().create_timer(1.0).timeout
	print("run started at %s, squad of %d, %d clusters" % [run.cluster().name, run.squad.size(), run.galaxy.clusters.size()])
	if OS.has_environment("INFALL_SHOT"):
		for child in overlays.get_children():
			child.queue_free()
		start_fight("")
		battle.paused = false
		await get_tree().create_timer(8.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("INFALL_SHOT"))
		print("screenshot saved")
	get_tree().quit()


# --- The title ------------------------------------------------------------------------------------------------

func show_title() -> void:
	_close_battle()
	title = TitleScreen.new()
	overlays.add_child(title)
	title.new_run_pressed.connect(choose_starting_ship)
	title.continue_pressed.connect(continue_run)
	title.settings_pressed.connect(func(): _open(MenuWindows.settings()))
	title.quit_pressed.connect(func(): get_tree().quit())
	Sfx.play_music("title")


func choose_starting_ship() -> void:
	_open(MenuWindows.ship_select(start_new_run, func(): pass))


func start_new_run(ship_id: String) -> void:
	var seed_number := randi()
	if OS.get_environment("INFALL_SEED") != "":
		seed_number = int(OS.get_environment("INFALL_SEED"))
	run = RunState.start(seed_number, ship_id)
	_begin_playing()
	arrive_at_cluster()


func continue_run() -> void:
	run = RunState.load_from_disk()
	if run == null:
		return
	_begin_playing()
	if run.pending_fight != "":
		# Saved in the middle of a fight: it starts again, rather than the cluster counting as done
		_show_quiet_cluster()
		start_fight(run.pending_fight)
		return
	arrive_at_cluster()


func _begin_playing() -> void:
	if title:
		title.queue_free()
		title = null
	runner = EventRunner.new(run)
	battle = BattleScreen.new()
	add_child(battle)
	move_child(battle, 0)
	battle.fight_over.connect(_on_fight_over)
	battle.surrender_offered.connect(_on_surrender_offered)
	battle.jump_pressed.connect(open_map)
	battle.ship_screen_pressed.connect(open_ship_screen)
	battle.store_pressed.connect(open_store)
	battle.hail_pressed.connect(open_hail)
	battle.menu_pressed.connect(open_menu)
	battle.squad_lost.connect(_on_squad_lost)
	Sfx.play_music("explore")


# --- Arriving at a cluster ------------------------------------------------------------------------------------

func arrive_at_cluster() -> void:
	_show_quiet_cluster()
	run.save_to_disk()
	_check_unlocks()
	var opening := runner.opening_message()
	if opening:
		show_event(opening, _play_cluster_event)
	else:
		_play_cluster_event()


func _play_cluster_event() -> void:
	var event := runner.event_for_arrival()
	run.cluster().event_done = true
	if event:
		run.used_events.append(event.id)
		run.stats.events += 1
		show_event(event)


## The squad at the cluster with nobody to fight: crew repair, the drive is ready, the store may open.
func _show_quiet_cluster() -> void:
	run.clear_lost_ships()
	encounter = Encounter.new()
	encounter.wallet = run
	encounter.hazard = _hazard_here()
	encounter.setup(run.living_ships(), [], int(run.cluster().seed))
	enemy_squad = null
	battle.show_encounter(encounter, run, int(run.cluster().seed), run.collapse_nearness(), run.cluster().store)


func _hazard_here() -> String:
	if run.galaxy.is_swallowed(run.current) or run.collapse_distance() < 60.0:
		return "collapse_edge"
	return String(run.cluster().hazard)


# --- Events ---------------------------------------------------------------------------------------------------

func show_event(event: EventDef, then: Callable = Callable()) -> void:
	var cluster := run.cluster()
	var heading := "%s  ·  %s  ·  %s" % [cluster.name, run.galaxy.region_name(cluster), ", ".join(cluster.states.filter(func(s): return s != "Core"))]
	var window := EventWindow.new()
	_open(window)
	window.show_event(event, runner, heading)
	window.resolved.connect(func(result: Dictionary): _after_event(result, then))


func _after_event(result: Dictionary, then: Callable) -> void:
	run.save_to_disk()
	if not String(result.next_event).is_empty() and Library.events.has(result.next_event):
		show_event(Library.events[result.next_event], then)
		return
	if result.fight_given:
		start_fight(result.fight)
		return
	_refresh_quiet_cluster()
	if result.store:
		open_store()
	if then.is_valid():
		then.call()


# --- Fights ---------------------------------------------------------------------------------------------------

func start_fight(squad_id: String) -> void:
	var asked := Time.get_ticks_usec()
	enemy_squad = runner.pick_squad(squad_id)
	var enemies := runner.build_enemy_ships(enemy_squad)
	encounter = Encounter.new()
	encounter.wallet = run
	encounter.squad = enemy_squad
	encounter.band = run.band()
	encounter.hazard = _hazard_here()
	encounter.setup(run.living_ships(), enemies, int(run.cluster().seed) + run.jumps)
	run.pending_fight = enemy_squad.id
	battle.show_encounter(encounter, run, int(run.cluster().seed), run.collapse_nearness(), false)
	battle.paused = Settings.get_value("event_auto_pause", true)
	run.log_book.write("fight", {"squad": enemy_squad.id, "ships": enemies.map(func(s): return s.design.id)}, "A fight with %s." % enemy_squad.name)
	# How long the fight took to appear, so a slow start can be measured on the player's machine
	RenderingServer.frame_post_draw.connect(func():
		var took := (Time.get_ticks_usec() - asked) / 1000
		run.log_book.write("fight_shown", {"ms": took}, "The fight took %d ms to appear." % took), CONNECT_ONE_SHOT)
	Sfx.play_music("combat")


func _on_fight_over(outcome: String, finished: Encounter) -> void:
	run.pending_fight = ""
	Sfx.play_music("explore")
	if outcome == "lost":
		return
	var rewards := runner.fight_rewards(finished) if outcome in ["won", "surrendered"] else {"mawjig": 0, "lines": []}
	var final_fight: bool = run.cluster().kind == "final" and outcome in ["won", "surrendered"]
	var window := Overlay.new()
	_open(window)
	window.place_panel(760)
	match outcome:
		"won":
			window.add_title("VICTORY", UiColours.POWER_GREEN)
			window.add_text(_after_fight_text(), 20)
		"surrendered":
			window.add_title("THEY SURRENDER", UiColours.POWER_GREEN)
			window.add_text("They power down and pay to be let go.", 20)
		"enemy_fled":
			window.add_title("THEY GOT AWAY", UiColours.WARNING)
			window.add_text("The enemy's Jigawatt Drive flares and they're gone. There is nothing left here to salvage.", 20)
		"passage", "paid":
			window.add_title("THE CHANNEL CLOSES")
			window.add_text("The enemy breaks off and leaves you to go your way.", 20)
	for line in rewards.lines:
		window.body.add_child(UiKit.label(line, 18, UiColours.POWER_GREEN, true))
	window.add_button("Continue...", func():
		window.close()
		_after_fight(final_fight))


func _after_fight_text() -> String:
	var race := enemy_squad.race if enemy_squad else "terran"
	match race:
		"malphen":
			return "The living ship comes apart in strands. Your crew convert what doesn't twitch into Mawjig."
		"mecha":
			return "The black frame breaks apart along its seams. Your converters strip the wreckage of everything they can turn into Mawjig."
		"tentauri":
			return "The pearl-white hull goes dark and drifts. Your crew salvage the wreck, quietly."
		"senti":
			return "The cyan light lines go out one by one. Whatever the Senti- were archiving, they will have to finish somewhere else."
	return "The enemy is beaten. Your crews convert the wreckage into Mawjig."


func _after_fight(final_fight: bool) -> void:
	run.clear_lost_ships()
	if final_fight:
		_win_run()
		return
	_show_quiet_cluster()
	run.save_to_disk()


func _on_surrender_offered(ship: Ship) -> void:
	var value := 0
	for enemy in encounter.living(1):
		value += Mawjig.amount(enemy.design.value * 0.025 * run.band_adjustment() * 0.5 / 100.0)
	var window := MenuWindows.surrender_offer(ship, value, func(accept: bool):
		if accept:
			for enemy in encounter.living(1):
				enemy.surrendered = true
		battle.paused = false)
	_open(window)


func open_hail() -> void:
	if not encounter.in_fight():
		return
	var window := HailWindow.new()
	_open(window)
	window.open(run, encounter, enemy_squad)
	window.decided.connect(_on_hail_decided)


func _on_hail_decided(outcome: String, _paid: int) -> void:
	match outcome:
		"surrendered":
			for enemy in encounter.living(1):
				enemy.surrendered = true
		"passage", "paid":
			for enemy in encounter.living(1):
				enemy.escaped = true


func _on_squad_lost() -> void:
	run.over = true
	run.save_to_disk()
	run.log_book.write("run_lost", run.stats, "The last scout ship is gone. The run is over.")
	Sfx.play_music("title")
	get_tree().create_timer(2.5).timeout.connect(func(): _open(MenuWindows.end_screen(run, false, show_title)))


func _win_run() -> void:
	run.over = true
	run.won = true
	run.save_to_disk()
	Profile.unlock("win")
	run.log_book.write("run_won", run.stats, "The squad reached the rim and beat the Last Fleet. The colony ship has its way out.")
	_open(MenuWindows.end_screen(run, true, show_title))


# --- The map: jumping and waiting -----------------------------------------------------------------------------

func open_map() -> void:
	if encounter.in_fight() and not encounter.can_squad_jump():
		battle.hud.flash_message("The Jigawatt Drive is still charging.")
		return
	var map := MapScreen.new()
	_open(map)
	map.open(run, encounter.can_squad_jump() and run.mawjig >= Mawjig.JUMP_COST or not encounter.in_fight() and run.mawjig >= Mawjig.JUMP_COST)
	map.closed.connect(func(): _close(map))
	map.jump_chosen.connect(func(index: int):
		_close(map)
		jump_to(index))
	map.wait_chosen.connect(func():
		_close(map)
		wait_here())


func jump_to(index: int) -> void:
	if encounter.in_fight():
		run.log_book.write("fled", {"cluster": run.current}, "The squad jumped away from a fight.")
	run.pending_fight = ""
	encounter.leave_behind_away_crew()
	Sfx.play("jump")
	await battle.play_jump_out()
	run.jump_to(index)
	arrive_at_cluster()
	battle.play_jump_in()


func wait_here() -> void:
	run.wait()
	if run.mawjig < Mawjig.JUMP_COST and Library.events.has("STRANDED"):
		show_event(Library.events["STRANDED"])
	elif run.rng.randf() < 0.18 and run.cluster().kind != "final":
		show_event(runner.pick("hostile"))
	elif Library.events.has("WAITED"):
		show_event(runner.before_or_after_collapse("WAITED"))
	_refresh_quiet_cluster()


# --- Refitting ------------------------------------------------------------------------------------------------

func open_store() -> void:
	if encounter.in_fight() or run.living_ships().is_empty():
		return
	var window := StoreWindow.new()
	_open(window)
	window.open(run, battle.selected_ship if battle.selected_ship else run.living_ships()[0])
	window.closed.connect(_refresh_quiet_cluster)


func open_ship_screen() -> void:
	if encounter.in_fight() or run.living_ships().is_empty():
		return
	var window := ShipScreen.new()
	_open(window)
	window.open(run, battle.selected_ship)
	window.closed.connect(_refresh_quiet_cluster)


## After a refit the ships' views are rebuilt so new weapons, systems and crew show.
func _refresh_quiet_cluster() -> void:
	if encounter.in_fight():
		return
	run.save_to_disk()
	_show_quiet_cluster()


# --- The menu -------------------------------------------------------------------------------------------------

func open_menu() -> void:
	var window := MenuWindows.pause_menu(func(): pass,
		func(): _open(MenuWindows.settings()),
		func():
			run.save_to_disk()
			show_title(),
		func():
			run.save_to_disk()
			get_tree().quit(),
		func(): OS.shell_open(run.log_book.folder()))
	_open(window)


# --- Bookkeeping ----------------------------------------------------------------------------------------------

func _check_unlocks() -> void:
	if run.band() >= 3 and Profile.unlock("reach_band_3"):
		run.log_book.write("unlocked", {"ship": "patrol-cutter"}, "Unlocked the GATOS Patrol Cutter as a starting ship.")
	if run.band() >= 5:
		Profile.unlock("reach_band_5")


## Opens a window over the ship view; the battle holds still while any window is open.
func _open(window: Control) -> void:
	overlays.add_child(window)
	_refresh_hold()
	window.tree_exited.connect(_refresh_hold)


## The battle holds while any window is open, worked out from the windows themselves so it can't drift.
func _refresh_hold() -> void:
	if battle == null or not is_inside_tree():
		return
	var open := overlays.get_children().filter(func(w): return not w.is_queued_for_deletion() and not w is TitleScreen)
	battle.hold_pause = not open.is_empty()


func _close(window: Control) -> void:
	window.queue_free()


func _close_battle() -> void:
	for child in overlays.get_children():
		child.queue_free()
	if battle:
		battle.queue_free()
		battle = null
