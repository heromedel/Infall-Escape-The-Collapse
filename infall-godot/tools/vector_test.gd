extends Node
## Checks the Vector Drive victory (GV 2H): where the Vector Frame waits, what the rim plays, the fold out of a fight
## and what stops it, what becomes of the drive, and fitting it. Also the settings for each victory and the Alliance
## talks that are split by a cluster's state.
## Run: godot --headless --path . tools/vector_test.tscn

var failures := 0


func _ready() -> void:
	Settings._values["rim_victory"] = "Vector Drive"
	Settings._values["tech_victory"] = true
	Settings._values["alliance_victory"] = true
	var run := RunState.start(5, "outrider")
	var runner := EventRunner.new(run)
	run.galaxy.collapse_radius = 900.0
	var rim := _first(run, func(cluster): return cluster.kind == "final")
	run.current = rim
	var event := runner.event_for_arrival()
	_check(run.vector_at >= 0 and run.galaxy.is_rim(run.vector_at), "the Vector Frame takes a place on the rim")
	_check(run.vector_at != rim and event.id == "RIM_VECTOR_ELSEWHERE", "it is not where the squad reaches the rim: %s" % event.id)
	run.vector_goal = true
	_check(VectorHunt.map_lines(run)[0].contains("somewhere near the rim"), "with no trail the map knows nothing")
	runner.resolve(event.choices[0], "")
	_check(run.vector_trail == 1 and VectorHunt.map_lines(run)[0].contains("heading"), "its wake gives a heading: %s" % VectorHunt.map_lines(run)[0])
	run.current = run.vector_at
	_check(runner.event_for_arrival().id == "FINAL_VECTOR", "at its cluster the squad meets it")
	Settings._values["rim_victory"] = "Last Fleet"
	_check(runner.event_for_arrival().id == "FINAL_RIVAL", "the Rim Victory setting puts the Last Fleet there instead")
	Settings._values["rim_victory"] = "Vector Drive"
	# The other victories come first at the rim, when they are allowed
	run.alliance_goal = true
	for race in Alliance.races:
		run.pledge(race)
	_check(runner.final_event().id == "FINAL_ALLIANCE_ALL", "with all seven pledged the rim is the Metastasis")
	Settings._values["alliance_victory"] = false
	_check(runner.final_event().id == "FINAL_VECTOR", "not with the Alliance victory switched off")
	Settings._values["alliance_victory"] = true
	run.pledges.clear()
	# The fight: beaten down, it charges its fold; a damaged drive stops it; a jammed drive never starts
	var fight := _fight(run, runner, {})
	var encounter: Encounter = fight[0]
	var frame: Ship = fight[1]
	var drive := frame.system_by_id(VectorHunt.DRIVE)
	_check(encounter.living(1).size() >= 3, "it comes with escorts: %d ships" % encounter.living(1).size())
	var contest := _fight(run, runner, {"hold_back": "escorts"})
	_check(contest[0].living(1).size() == 1, "a contest holds the escorts back")
	contest[1].hull = int(contest[1].max_hull * 0.45)
	contest[0].step()
	_check(contest[0].living(1).size() >= 3, "until their ship is down to half its hull: then they come in")
	frame.hull = int(frame.max_hull * 0.2)
	encounter.step()
	_check(frame.charging_escape and not frame.escaped, "beaten down, it starts to fold away")
	frame.damage_system(drive, 1)
	encounter.step()
	_check(not frame.charging_escape and frame.fold_ticks == 0, "a damaged drive loses the fold")
	drive.damage = 0
	for tick in Encounter.FOLD_TICKS + 2:
		encounter.step()
	_check(frame.escaped, "left alone for %d seconds it is gone" % (Encounter.FOLD_TICKS / 20))
	var lines := runner.vector_after_fight(encounter)
	_check(run.vector_escapes == 1 and run.vector_at != run.current and run.vector_drive == "", "it folds to another cluster close by")
	_check(run.vector_hull > 0.2 and run.vector_hull < 0.6, "and mends only some of its hull: %.2f" % run.vector_hull)
	_check(VectorHunt.map_lines(run).size() == 2, "the squad saw where it went: %s" % str(VectorHunt.map_lines(run)))
	run.current = run.vector_at
	_check(runner.event_for_arrival().id == "VECTOR_CAUGHT", "and meets it again there")
	var jammed := _fight(run, runner, {"no_escape": "yes"})
	jammed[1].hull = 3
	for tick in Encounter.FOLD_TICKS + 2:
		jammed[0].step()
	_check(not jammed[1].escaped, "a jammed drive can't fold")
	# The drive: lost with a ship destroyed while it is damaged; scarred if it was mended first; whole otherwise
	for case in [["lost", true, true], ["scarred", true, false], ["whole", false, false]]:
		var again := _fight(run, runner, {})
		var ship: Ship = again[1]
		var its_drive := ship.system_by_id(VectorHunt.DRIVE)
		if case[1]:
			ship.damage_system(its_drive, 1)
		if not case[2]:
			its_drive.damage = 0
		ship.damage_hull(999)
		run.vector_drive = ""
		runner.vector_after_fight(again[0])
		_check(run.vector_drive == case[0], "destroyed with its drive %s: the drive is %s" % ["damaged" if case[2] else ("mended" if case[1] else "untouched"), run.vector_drive])
	var captured := _fight(run, runner, {})
	for member in captured[1].crew:
		member.dead = true
	captured[1].crew_dead = true
	captured[1].damage_system(captured[1].system_by_id(VectorHunt.DRIVE), 2)
	run.vector_drive = ""
	runner.vector_after_fight(captured[0])
	_check(run.vector_drive == "scarred", "its crew killed, the ship is taken with its drive, damaged or not: %s" % run.vector_drive)
	# Fitting it
	run.mawjig = 500
	_check(VectorHunt.fit_refusal(run, run.squad[0]) != "", "fitting it costs Mawjig the squad must have")
	run.mawjig = 30000
	_check(VectorHunt.scout_price(run) == 908 + VectorHunt.SCARRED_REPAIR, "a scarred drive costs its repair too: %s" % Mawjig.format(VectorHunt.scout_price(run)))
	_check(VectorHunt.fit_refusal(run, null) != "", "The Colony Ship needs a refit yard")
	run.current = _first(run, func(cluster): return Refit.has_yard(cluster))
	_check(VectorHunt.fit_refusal(run, null) == "", "at a yard it can be fitted to The Colony Ship")
	var copy := RunState.from_data(JSON.parse_string(JSON.stringify(run.to_save())))
	_check(copy.vector_drive == "scarred" and copy.vector_escapes == run.vector_escapes and copy.vector_at == run.vector_at, "the hunt is saved and loaded")
	Refit.apply(run, {"op": "fit_vector", "sq": -1})
	_check(run.victory == "fold" and run.mawjig == 30000 - VectorHunt.colony_price(copy), "fitted to The Colony Ship: everyone leaves")
	Refit.apply(copy, {"op": "fit_vector", "sq": 0})
	_check(copy.victory == "vector", "fitted to a ship of the squad: that ship leaves")
	# Alliance talks split by the cluster's state
	_check(Alliance.talk_event("mecha", {"states": ["Doing Fine", "Core"]}) == "ALLIANCE_MECHA_WINNING", "the Mecha doing well refuse")
	_check(Alliance.talk_event("mecha", {"states": ["Struggling", "Border"]}) == "ALLIANCE_MECHA", "struggling, they can be paid")
	_check(Alliance.talk_event("senti", {"states": ["Doomed", "Border"]}) == "ALLIANCE_SENTI_DOOMED", "doomed Senti fight first")
	_check(Alliance.talk_event("senti", {"states": ["Doing Fine"]}) == "ALLIANCE_SENTI", "Senti doing fine talk")
	_check(not runner.can_take(Library.events["ALLIANCE_MALPHEN"].choices[0]), "the Malphen can't be reached without a gland")
	print("PASS" if failures == 0 else "FAIL: %d" % failures)
	get_tree().quit()


func _first(run: RunState, test: Callable) -> int:
	for index in run.galaxy.clusters.size():
		if test.call(run.galaxy.clusters[index]) and not run.galaxy.is_swallowed(index):
			return index
	return -1


## A fight with the Vector Frame's squad under an event's terms: [the encounter, the Vector Frame].
func _fight(run: RunState, runner: EventRunner, terms: Dictionary) -> Array:
	run.fight_terms = terms
	var squad: SquadDef = Library.squads[VectorHunt.SQUAD]
	var encounter := Encounter.new()
	encounter.wallet = run
	encounter.squad = squad
	var foes := runner.build_enemy_ships(squad)
	encounter.setup(run.living_ships(), foes, 77)
	runner.apply_fight_terms(encounter, [])
	for ship in run.living_ships():
		ship.hull = ship.max_hull
		for slot in ship.weapons:
			slot.powered = false       # nobody fires in these fights: the test moves the hull itself
	for ship in foes:
		for slot in ship.weapons:
			slot.powered = false
	return [encounter, foes[0]]


func _check(ok: bool, what: String) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		failures += 1
