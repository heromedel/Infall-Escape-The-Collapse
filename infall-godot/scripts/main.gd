extends Node
## Main: the flow of the game, read top to bottom (coding rule 8). It shows the title, starts or loads a run,
## and at each cluster plays the arrival events, any fight and its rewards, then lets the squad trade, refit
## and jump on, until the squad reaches the rim or is lost.
##
## The game always runs as a server with its players as clients (GV 4A): everything a player does is an order,
## and Main plays the orders and the clock's ticks in the order the Session's stream brings them, the same on every
## machine. Screens report what a player chose by giving an order; they never change the run themselves. Windows
## every player sees (events, victories, hails) are shared: the Admiral answers them. Each player's own windows
## (map, store, ship screen, menu) open in their own view.

## Ai-Generated-Proposal: how likely mercenaries are to leave after a battle that killed any of their own (GV 7C).
const MERCENARIES_LEAVE_CHANCE := 0.75
## How long a won fight shows before the victory window covers it.
const AFTER_FIGHT_SECONDS := 1.6

signal run_changed                    # a refit or an event changed the squad: open windows show it again

var run: RunState
var runner: EventRunner
var battle: BattleScreen
var encounter: Encounter
var enemy_squad: SquadDef
var session := Session.new()
var overlays := CanvasLayer.new()     # shared windows and the title, over every player's view
var views_layer := CanvasLayer.new()  # the players' views, side by side
var router := InputRouter.new()
var title: TitleScreen
var console := DebugConsole.new()
var shared_count := 0                 # shared windows opened this run, counted the same on every machine
var _waiting: Overlay


func _ready() -> void:
	name = "Main"
	session.main = self
	add_child(session)
	session.players_changed.connect(_lay_out_views)
	get_viewport().size_changed.connect(_lay_out_views)
	session.session_ended.connect(func(reason: String):
		show_title()
		_notice(reason))
	session.note.connect(func(text: String):
		if battle:
			battle.flash_message(text))
	views_layer.layer = 0
	add_child(views_layer)
	overlays.layer = 20
	add_child(overlays)
	router.main = self
	add_child(router)
	var console_layer := CanvasLayer.new()
	console_layer.layer = 50
	add_child(console_layer)
	console.main = self
	console_layer.add_child(console)
	add_child(BattleWarmup.new())
	Overlay.press_shared = func(window: Overlay, page: int, index: int):
		session.submit(_answering_player(), {"k": "shared", "w": window.serial, "pg": page, "i": index})
	Overlay.may_answer = func(): return session.admiral_is_local()
	LowMawjigWarning.current_run = func(): return run
	session.add_local_player("keys")
	show_title()
	if OS.has_environment("INFALL_SMOKE"):
		_smoke_test()


## The hooks other classes keep to Main are let go, so nothing calls into a freed Main as the game closes.
func _exit_tree() -> void:
	Overlay.press_shared = Callable()
	Overlay.may_answer = Callable()
	LowMawjigWarning.current_run = Callable()
	Settings.rule_changed = Callable()


## Backtick opens and closes the console, caught before any text box can type it.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_QUOTELEFT:
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
	if session.is_host:
		session.end_run()
	title = TitleScreen.new()
	overlays.add_child(title)
	title.new_run_pressed.connect(choose_starting_ship)
	title.continue_pressed.connect(continue_run)
	title.settings_pressed.connect(func(): _open(MenuWindows.settings()))
	title.players_pressed.connect(open_players)
	title.quit_pressed.connect(func(): get_tree().quit())
	Sfx.play_music("title")


func choose_starting_ship() -> void:
	_open(MenuWindows.ship_select(start_new_run, func(): pass))


func start_new_run(ship_id: String) -> void:
	var seed_number := randi()
	if OS.get_environment("INFALL_SEED") != "":
		seed_number = int(OS.get_environment("INFALL_SEED"))
	session.start_run(Session.new_origin(ship_id, seed_number))


func continue_run() -> void:
	var data = RunState.saved_data()
	if data != null:
		session.start_run(Session.load_origin(data))


## A machine that joined another's game, while the host is not in a run.
func wait_for_host() -> void:
	_close_battle()
	if title:
		title.queue_free()
		title = null
	_waiting = Overlay.new()
	overlays.add_child(_waiting)
	_waiting.place_panel(640)
	_waiting.add_title("CONNECTED")
	_waiting.add_text("You're in %s's game. The run starts when the host starts one." % session.titled_name(session.admiral), 20)
	_waiting.add_button("Players", open_players)
	_waiting.add_button("Leave", func():
		session.leave_lan()
		show_title())


## Every machine starts the same run from the same origin: a new run's seed and ship, or the host's save.
func begin_run(origin: Dictionary) -> void:
	_close_battle()
	if title:
		title.queue_free()
		title = null
	run = RunState.start(int(origin.seed), origin.ship) if origin.kind == "new" else RunState.from_data(origin.save)
	runner = EventRunner.new(run)
	shared_count = 0
	battle = BattleScreen.new()
	battle.session = session
	add_child(battle)
	move_child(battle, 0)
	battle.fight_over.connect(_on_fight_over)
	battle.surrender_offered.connect(_on_surrender_offered)
	battle.squad_lost.connect(_on_squad_lost)
	_lay_out_views()
	Sfx.play_music("explore")
	if run.pending_fight != "":
		# Saved in the middle of a fight: it starts again, rather than the cluster counting as done
		_show_quiet_cluster()
		start_fight(run.pending_fight)
		return
	arrive_at_cluster()


# --- Players and their views ----------------------------------------------------------------------------------

## One view for each player on this machine, side by side (GV 4F): left and right for two, quarters for three or
## four, sixths (three across, two down) for five or six, GDD 4A's most. With Local Co-op View set to Shared, the
## players share one.
func _lay_out_views() -> void:
	if battle == null:
		return
	var wanted: Array[Dictionary] = session.local_players()
	if Settings.get_value("local_coop_view", "Split") == "Shared" and wanted.size() > 1:
		wanted = [wanted[0]]
	for view in battle.player_views.duplicate():
		if not wanted.any(func(p): return p.id == view.player_id):
			battle.player_views.erase(view)
			view.display.queue_free()
			view.queue_free()
	for view in battle.player_views:
		var player := session.player_by_id(view.player_id)
		view.uses_keys = player.get("device", "keys") == "keys"   # a player can change their input (GV 4H)
		view.show_cursor = not view.uses_keys
	for player in wanted:
		if not battle.player_views.any(func(v): return v.player_id == player.id):
			var view := PlayerView.new()
			view.setup(battle, player.id, Color(player.colour), player.device == "keys")
			battle.player_views.append(view)
			add_child(view)
			views_layer.add_child(view.display)
			view.jump_pressed.connect(open_map)
			view.ship_screen_pressed.connect(open_ship_screen)
			view.store_pressed.connect(open_store)
			view.hail_pressed.connect(func(v: PlayerView):
				if session.is_admiral(v.player_id):
					v._give({"k": "hail_open"})
				else:
					v.hud.flash_message("The Admiral hails (%s)." % session.titled_name(session.admiral)))
			view.menu_pressed.connect(open_menu)
			view.players_pressed.connect(open_players)
	battle.player_views.sort_custom(func(a, b): return a.player_id < b.player_id)
	var screen := get_viewport().get_visible_rect().size
	var count := battle.player_views.size()
	for index in count:
		var view: PlayerView = battle.player_views[index]
		match count:
			1:
				view.place(Rect2(Vector2.ZERO, screen), screen.y)
			2:
				view.place(Rect2(Vector2(screen.x * 0.5 * index, 0), Vector2(screen.x * 0.5, screen.y)), screen.y * 1.5)
			_:
				var columns := ceili(count / 2.0)     # two rows: quarters for three or four, sixths for five or six
				var cell := Vector2(screen.x / columns, screen.y * 0.5)
				view.place(Rect2(Vector2(index % columns, index / columns) * cell, cell), screen.y)
		if battle.encounter:
			view.frame_everything(true)


func view_of(player_id: int) -> PlayerView:
	if battle == null:
		return null
	for view in battle.player_views:
		if view.player_id == player_id:
			return view
	return battle.player_views[0] if Settings.get_value("local_coop_view", "Split") == "Shared" and not battle.player_views.is_empty() else null


## The player on this machine who answers shared windows: the Admiral when they are here.
func _answering_player() -> int:
	return session.admiral if session.admiral_is_local() else session.first_local_id()


func open_players(view: PlayerView = null) -> void:
	var window := PlayersWindow.new()
	window.open(session, self)
	if view == null:
		view = view_of(session.first_local_id())
	if view:
		view.open_window(window)
	else:
		_open(window)


# --- Playing the stream ---------------------------------------------------------------------------------------

## Whether the host's clock may tick: not paused, and no shared window or Admiral's window holds the battle.
func can_tick() -> bool:
	return battle != null and battle.encounter != null and not battle.paused and not _held()


func _held() -> bool:
	if _shared_windows().any(func(w): return w.visible):
		return true
	if session.remote_hold:
		return true
	var admiral_view := view_of(session.admiral) if session.admiral_is_local() else null
	return admiral_view != null and admiral_view.has_window()


func apply_tick() -> void:
	_update_hold()
	battle.step_tick()


func apply_order(order: Dictionary) -> void:
	var kind := String(order.k)
	if kind in BattleOrders.KINDS:
		if battle == null or battle.encounter == null:
			return
		var why := BattleOrders.apply(battle, order)
		if not why.is_empty():
			var view := view_of(int(order.get("p", 0)))
			if view:
				view.hud.flash_message(why)
		return
	match kind:
		"shared":
			for window in _shared_windows():
				if window.serial == int(order.w):
					window.press(int(order.pg), int(order.i))
		"jump":
			await jump_to(int(order.to))
		"wait":
			wait_here()
		"hail_open":
			open_hail()
		"refit":
			Refit.apply(run, order)
			_refresh_quiet_cluster(false)
			run_changed.emit()
		"rule":
			if Settings.session_rules.has(order.id):
				Settings.session_rules[order.id] = order.value
		"console":
			console.execute(String(order.text))
		"assign", "handover", "restore":
			Assignments.apply(run, order)
			run_changed.emit()
	_update_hold()


## Why the host refuses a player's order, or "" (GV 4I).
func refusal(order: Dictionary) -> String:
	return Assignments.refusal(self, order)


## A message for one player, in their own view.
func tell(player_id: int, text: String) -> void:
	var view := view_of(player_id)
	if view:
		view.hud.flash_message(text)


func checksum() -> int:
	if run == null:
		return 0
	return hash([battle.checksum() if battle else 0, run.mawjig, run.current, run.jumps, run.rng.state, shared_count])


## The Admiral's machine dropped out: the game pauses and saves until they return (GDD 4N at its default).
func admiral_gone() -> void:
	if battle and battle.encounter and not battle.paused:
		session._emit({"k": "pause", "on": true, "p": 0})
	if run:
		run.save_to_disk()


# --- Arriving at a cluster ------------------------------------------------------------------------------------

func arrive_at_cluster() -> void:
	_show_quiet_cluster()
	run.save_to_disk()
	_check_unlocks()
	_mercenary_events(run.contracts_due(), "MERCENARY_CONTRACT_UP", func():
		var opening := runner.opening_message()
		if opening:
			show_event(opening, _play_cluster_event)
		else:
			_play_cluster_event())


## One contract event for each mercenary ship in turn (GV 7C), then `then`.
func _mercenary_events(ships: Array, event_id: String, then: Callable) -> void:
	if ships.is_empty():
		runner.mercenary = null
		then.call()
		return
	runner.mercenary = ships.pop_front()
	show_event(Library.events[event_id], func(): _mercenary_events(ships, event_id, then))


## Mercenaries who lost any of their own in the fight are likely to leave after it (GV 7C).
func _mercenaries_after_fight() -> void:
	var leaving := run.mercenaries_with_losses().filter(func(_ship): return run.rng.randf() < MERCENARIES_LEAVE_CHANCE)
	run.count_mercenary_crew()   # counted: the same losses are not asked about twice
	_mercenary_events(leaving, "MERCENARY_WALKOUT", func(): pass)


func _play_cluster_event() -> void:
	var event := runner.event_for_arrival()
	run.cluster().event_done = true
	if event:
		run.used_events.append(event.id)
		run.stats.events += 1
		show_event(event)


## The squad at the cluster with nobody to fight: crew repair, the drive is ready, the store may open.
func _show_quiet_cluster(reframe: bool = true) -> void:
	run.clear_lost_ships()
	encounter = Encounter.new()
	encounter.wallet = run
	encounter.hazard = _hazard_here()
	encounter.setup(run.living_ships(), [], int(run.cluster().seed))
	enemy_squad = null
	battle.show_encounter(encounter, run, int(run.cluster().seed), run.collapse_nearness(), run.cluster().store, reframe)


func _hazard_here() -> String:
	if run.galaxy.is_swallowed(run.current) or run.collapse_distance() < 60.0:
		return "collapse_edge"
	return String(run.cluster().hazard)


# --- Shared windows -------------------------------------------------------------------------------------------

## Opens a window every player sees and the Admiral answers. `visible_now` false holds it back (after a fight).
func _open_shared(window: Overlay, visible_now: bool = true) -> void:
	shared_count += 1
	window.serial = shared_count
	window.visible = visible_now or session.catching_up
	overlays.add_child(window)
	window.tree_exited.connect(_update_hold)
	_update_hold()


## Nobody plays the battle while a shared window shows.
func _update_hold() -> void:
	if battle and is_inside_tree():
		battle.hold_pause = _shared_windows().any(func(w): return w.visible)


func _shared_windows() -> Array:
	return overlays.get_children().filter(func(w): return w is Overlay and w.shared and not w.is_queued_for_deletion())


func show_event(event: EventDef, then: Callable = Callable()) -> void:
	var cluster := run.cluster()
	var heading := "%s  ·  %s  ·  %s" % [cluster.name, run.galaxy.region_name(cluster), ", ".join(cluster.states.filter(func(s): return s != "Core"))]
	var window := EventWindow.new()
	window.shared = true
	_open_shared(window)
	window.show_event(event, runner, heading)
	window.resolved.connect(func(result: Dictionary): _after_event(result, then))


func _after_event(result: Dictionary, then: Callable) -> void:
	run.save_to_disk()
	run_changed.emit()
	if not String(result.next_event).is_empty() and Library.events.has(result.next_event):
		show_event(Library.events[result.next_event], then)
		return
	if result.fight_given:
		start_fight(result.fight)
		return
	_refresh_quiet_cluster()
	if result.store:
		var view := view_of(session.admiral) if session.admiral_is_local() else null
		if view:
			open_store(view)
	if then.is_valid():
		then.call()


# --- Fights ---------------------------------------------------------------------------------------------------

func start_fight(squad_id: String) -> void:
	var asked := Time.get_ticks_usec()
	enemy_squad = runner.pick_squad(squad_id)
	run.count_mercenary_crew()
	var enemies := runner.build_enemy_ships(enemy_squad)
	encounter = Encounter.new()
	encounter.wallet = run
	encounter.squad = enemy_squad
	encounter.band = run.band()
	encounter.hazard = _hazard_here()
	encounter.setup(run.living_ships(), enemies, int(run.cluster().seed) + run.jumps)
	encounter.reinforcements = runner.build_reinforcements(enemy_squad)
	encounter.tech_wanted = runner.tech_wanted()
	run.pending_fight = enemy_squad.id
	battle.show_encounter(encounter, run, int(run.cluster().seed), run.collapse_nearness(), false)
	battle.paused = Settings.get_value("event_auto_pause", true)
	battle.paused_by = 0
	run.log_book.write("fight", {"squad": enemy_squad.id, "ships": enemies.map(func(s): return s.design.id)}, "A fight with %s." % enemy_squad.name)
	# How long the fight took to appear, so a slow start can be measured on the player's machine
	RenderingServer.frame_post_draw.connect(func():
		var took := (Time.get_ticks_usec() - asked) / 1000
		if run:
			run.log_book.write("fight_shown", {"ms": took}, "The fight took %d ms to appear." % took), CONNECT_ONE_SHOT)
	Sfx.play_music("combat")


## The fight's end is played the same moment on every machine; the victory window shows a little later, so the
## last explosion can be seen.
func _on_fight_over(outcome: String, finished: Encounter) -> void:
	run.pending_fight = ""
	Sfx.play_music("explore")
	if outcome == "lost":
		return
	var rewards := runner.fight_rewards(finished) if outcome in ["won", "surrendered"] else {"mawjig": 0, "lines": []}
	var final_fight: bool = run.cluster().kind == "final" and outcome in ["won", "surrendered"]
	var window := Overlay.new()
	window.shared = true
	_open_shared(window, false)
	window.place_panel(760)
	match outcome:
		"won":
			window.add_title("VICTORY", UiColours.POWER_GREEN)
			window.add_text(_after_fight_text(), 20)
		"surrendered":
			window.add_title("THEY SURRENDER", UiColours.POWER_GREEN)
			window.add_text("They power down and pay to be let go." if finished.surrender_pays else "They are gone, and what you demanded is in your hold.", 20)
		"enemy_fled":
			window.add_title("THEY GOT AWAY", UiColours.WARNING)
			window.add_text("The enemy's Jigawatt Drive flares and they're gone. There is nothing left here to salvage.", 20)
		"passage", "paid":
			window.add_title("THE CHANNEL CLOSES")
			window.add_text("The enemy breaks off and leaves you to go your way.", 20)
	for line in rewards.lines:
		window.body.add_child(UiKit.label(line, 18, UiColours.POWER_GREEN, true))
	if String(rewards.get("tech_demand", "")) != "":
		var piece := RimTech.name_of(rewards.tech_demand)
		var trade: Array[Button] = []
		trade.append(window.add_button("Demand their %s as the price of surrender (hand back the %s Mawjig)." % [piece, Mawjig.format(int(rewards.surrender_paid))], func():
			if runner.trade_surrender_for_tech(rewards):
				trade[0].text = "They hand over the %s (%d of %d)." % [piece, run.tech.size(), RimTech.order.size()]
			trade[0].disabled = true
			run_changed.emit(), Color("#ffd46b")))
	var survivors: Array = rewards.get("survivors", [])
	for index in survivors.size():
		var survivor: Dictionary = survivors[index]
		var race := Library.race(survivor.race)
		window.add_text("A survivor, %s (%s), %s and asks to join your crew." % [survivor.name, race.singular, survivor.why], 18)
		var holder: Array[Button] = []   # the button, for its own press to change it
		holder.append(window.add_button("Take %s aboard." % survivor.name, func():
			var ship := runner.take_survivor(survivor)
			holder[0].text = "%s joins the %s." % [survivor.name, ship.name] if ship else "There is no room aboard for %s." % survivor.name
			holder[0].disabled = true
			run_changed.emit(), UiColours.POWER_GREEN))
	window.add_button("Continue...", func():
		window.close()
		_after_fight(final_fight))
	if not session.catching_up:
		var window_id := window.get_instance_id()   # the window may be gone by then (a jump, the title)
		get_tree().create_timer(AFTER_FIGHT_SECONDS).timeout.connect(func():
			var shown := instance_from_id(window_id) as Overlay
			if shown and not shown.is_queued_for_deletion():
				shown.visible = true
				_update_hold()
				if battle:
					for view in battle.player_views:
						view.frame_everything())


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
	var fought := enemy_squad
	_show_quiet_cluster()
	run.save_to_disk()
	var after_rival := runner.after_rival_event(fought)
	if after_rival:
		show_event(after_rival, _mercenaries_after_fight)
		return
	_mercenaries_after_fight()


## A losing Malphen ship and a squad without the Brood Heart: the surrender is settled with the organ, not Mawjig
## (heromedel by way of Infall: Lori, 2026-11-14: "a negotiated surrender during a fight the squad is winning").
func _malphen_offers_its_organ() -> void:
	var window := EventWindow.new()
	window.shared = true
	_open_shared(window)
	window.show_event(Library.events["MALPHEN_SURRENDER_TECH"], runner, "")
	window.resolved.connect(func(_result: Dictionary):
		if run.has_tech("malphen"):
			encounter.surrender_pays = false
			for enemy in encounter.living(1):
				enemy.surrendered = true
		battle.paused = false
		run_changed.emit())


func _on_surrender_offered(ship: Ship) -> void:
	if ship.design.race == "malphen" and encounter.tech_wanted.has("malphen") and not run.has_tech("malphen") and Library.events.has("MALPHEN_SURRENDER_TECH"):
		_malphen_offers_its_organ()
		return
	var value := 0
	for enemy in encounter.living(1):
		value += Mawjig.amount(enemy.design.value * 0.025 * run.band_adjustment() * 0.5 / 100.0)
	var window := MenuWindows.surrender_offer(ship, value, func(accept: bool):
		if accept:
			for enemy in encounter.living(1):
				enemy.surrendered = true
		battle.paused = false, true)
	_open_shared(window)


func open_hail() -> void:
	if not encounter.in_fight():
		return
	var window := HailWindow.new()
	window.shared = true
	_open_shared(window)
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
	get_tree().create_timer(2.5).timeout.connect(func(): _open(MenuWindows.end_screen(run, false, _after_the_end)))


func _win_run() -> void:
	run.over = true
	run.won = true
	run.victory = "tech" if run.has_all_tech() else "escape"
	run.save_to_disk()
	Profile.unlock("win")
	run.log_book.write("run_won", run.stats, "The squad reached the rim and beat the Last Fleet. The colony ship has its way out." if run.victory == "escape" else "The squad carried a piece of every race's tech to the rim and beat the Last Fleet's ambush. The Tech victory.")
	_open(MenuWindows.end_screen(run, true, _after_the_end))


## After the end screen: the host goes back to the title; a machine that joined waits for the next run.
func _after_the_end() -> void:
	if session.is_host:
		show_title()
	else:
		wait_for_host()


# --- The map: jumping and waiting -----------------------------------------------------------------------------

func open_map(view: PlayerView) -> void:
	if encounter.in_fight() and not encounter.can_squad_jump():
		view.hud.flash_message("The Jigawatt Drive is still charging.")
		return
	var map := MapScreen.new()
	view.open_window(map)
	var can_jump: bool = encounter.can_squad_jump() and run.mawjig >= Mawjig.JUMP_COST or not encounter.in_fight() and run.mawjig >= Mawjig.JUMP_COST
	map.open(run, can_jump and session.is_admiral(view.player_id))
	map.closed.connect(func(): map.queue_free())
	map.jump_chosen.connect(func(index: int):
		map.queue_free()
		view._give({"k": "jump", "to": index}))
	map.wait_chosen.connect(func():
		map.queue_free()
		view._give({"k": "wait"}))


func jump_to(index: int) -> void:
	if not run.can_jump_to(index) or run.mawjig < Mawjig.JUMP_COST:
		return
	if encounter.in_fight():
		run.log_book.write("fled", {"cluster": run.current}, "The squad jumped away from a fight.")
		run.count_mercenary_crew()
	run.pending_fight = ""
	encounter.leave_behind_away_crew()
	for window in _shared_windows():
		window.queue_free()   # a victory not yet shown: its rewards were already given
	if not session.catching_up:
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

func open_store(view: PlayerView) -> void:
	if encounter.in_fight() or run.living_ships().is_empty():
		return
	var window := StoreWindow.new()
	window.give = view._give
	view.open_window(window)
	window.open(run, view.selected_ship if view.selected_ship else run.living_ships()[0])
	run_changed.connect(window._rebuild)


func open_ship_screen(view: PlayerView) -> void:
	if encounter.in_fight() or run.living_ships().is_empty():
		return
	var window := ShipScreen.new()
	window.give = view._give
	view.open_window(window)
	window.open(run, view.selected_ship)
	run_changed.connect(window._rebuild)


## After a refit the ships' views are rebuilt so new weapons, systems and crew show.
func _refresh_quiet_cluster(reframe: bool = true) -> void:
	if encounter.in_fight():
		return
	run.save_to_disk()
	_show_quiet_cluster(reframe)


# --- The menu -------------------------------------------------------------------------------------------------

func open_menu(view: PlayerView) -> void:
	var leave_text := "Save and quit to the title" if session.is_host else "Leave the game"
	var window := MenuWindows.pause_menu(func(): pass,
		func(): view.open_window(MenuWindows.settings()),
		func():
			if session.is_host:
				run.save_to_disk()
			else:
				session.leave_lan()
			show_title(),
		func():
			if session.is_host:
				run.save_to_disk()
			get_tree().quit(),
		func(): OS.shell_open(run.log_book.folder()), leave_text)
	view.open_window(window)


# --- Bookkeeping ----------------------------------------------------------------------------------------------

func _check_unlocks() -> void:
	if run.band() >= 3 and Profile.unlock("reach_band_3"):
		run.log_book.write("unlocked", {"ship": "patrol-cutter"}, "Unlocked the GATOS Patrol Cutter as a starting ship.")
	if run.band() >= 5:
		Profile.unlock("reach_band_5")


## Opens a window over everything (the title's windows, the end screen).
func _open(window: Control) -> void:
	overlays.add_child(window)


func _notice(text: String) -> void:
	if text.is_empty():
		return
	var window := Overlay.new()
	_open(window)
	window.place_panel(560)
	window.add_text(text, 20)
	window.add_button("OK", window.close)


func _close_battle() -> void:
	for child in overlays.get_children():
		child.queue_free()
	_waiting = null
	if battle:
		for view in battle.player_views:
			view.display.queue_free()
			view.queue_free()
		battle.player_views.clear()
		battle.queue_free()
		battle = null
	run = null
	encounter = null
