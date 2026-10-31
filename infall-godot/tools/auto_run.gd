extends Node
## Plays whole runs without the screen: picks event choices at random, fights every fight with a simple
## captain (aim everything at the enemy's weapons, then shields), buys repairs at stores, and jumps outward.
## Prints how each run went. Run: RUNS=3 godot --headless --path . tools/auto_run.tscn

func _ready() -> void:
	var runs := int(OS.get_environment("RUNS")) if OS.get_environment("RUNS") != "" else 2
	for index in runs:
		_play_one(1000 + index)
	get_tree().quit()


func _play_one(seed_number: int) -> void:
	var run := RunState.start(seed_number, "outrider")
	var runner := EventRunner.new(run)
	var fights := 0
	var won := 0
	var squads_seen := {}
	var max_jumps := 140
	while run.jumps < max_jumps:
		var event := runner.opening_message()
		if event:
			_resolve(runner, event)
		event = runner.event_for_arrival()
		run.cluster().event_done = true
		if event:
			run.used_events.append(event.id)
			var result := _resolve(runner, event)
			while not String(result.next_event).is_empty():
				result = _resolve(runner, Library.events[result.next_event])
			if result.fight_given:
				fights += 1
				var squad := runner.pick_squad(result.fight)
				squads_seen[squad.id] = squads_seen.get(squad.id, 0) + 1
				var outcome := _fight(run, runner, squad)
				if outcome in ["won", "surrendered"]:
					won += 1
					runner.fight_rewards(_last)
				if outcome == "lost":
					print("    lost to %s; hulls %s" % [squad.id, str(run.squad.map(func(s): return "%s %d/%d destroyed=%s crew_dead=%s" % [s.name, s.hull, s.max_hull, s.destroyed, s.crew_dead]))])
					print("run %d LOST at jump %d band %d after %d fights (%d won)" % [seed_number, run.jumps, run.band(), fights, won])
					return
				if run.cluster().kind == "final" and outcome in ["won", "surrendered"]:
					print("run %d WON at jump %d after %d fights. mawjig %s squad %d" % [seed_number, run.jumps, fights, Mawjig.format(run.mawjig), run.living_ships().size()])
					print("  squads: ", squads_seen)
					return
			if result.store or run.cluster().store:
				_shop(run)
		run.clear_lost_ships()
		for ship in run.living_ships():
			ship.repair_everything()   # crew repair between clusters
			for member in ship.crew:
				member.health = member.max_health   # and heal in the medbay, as a player would
		# Jump outward: the linked cluster farthest from the core
		var best := -1
		for link in run.cluster().links:
			if run.can_jump_to(link) and (best < 0 or run.galaxy.clusters[link].radius > run.galaxy.clusters[best].radius):
				best = link
		if best < 0 or run.mawjig < Mawjig.JUMP_COST:
			run.wait()
			continue
		run.jump_to(best)
		if run.jumps % 10 == 0:
			var hulls := run.living_ships().map(func(s): return "%d/%d" % [s.hull, s.max_hull])
			print("  run %d jump %d band %d mawjig %s hull %s collapse gap %d" % [seed_number, run.jumps, run.band(), Mawjig.format(run.mawjig), str(hulls), int(run.collapse_distance()) if run.collapse_distance() != INF else -1])
		# Save and reload once in a while, to check saves round-trip
		if run.jumps % 25 == 0:
			run.save_to_disk()
			var loaded := RunState.load_from_disk()
			if loaded == null or loaded.living_ships().size() != run.living_ships().size():
				print("SAVE ROUND TRIP FAILED")
	print("run %d stopped at %d jumps, band %d" % [seed_number, run.jumps, run.band()])


var _last: Encounter


func _resolve(runner: EventRunner, event: EventDef) -> Dictionary:
	var choices: Array = event.choices.filter(func(c): return runner.can_take(c))
	# A sensible captain: takes blue options, avoids paying when short of Mawjig, otherwise picks at random
	var free: Array = choices.filter(func(c): return not str(c.outcomes).contains("amount\": \"-"))
	if runner.run.mawjig < 600 and not free.is_empty():
		choices = free
	for choice in choices:
		if runner.is_blue(choice):
			return runner.resolve(choice, runner.crew_for_choice(choice))
	var choice: Dictionary = choices[runner.run.rng.randi_range(0, choices.size() - 1)]
	return runner.resolve(choice, runner.crew_for_choice(choice))


func _fight(run: RunState, runner: EventRunner, squad: SquadDef) -> String:
	var enemies := runner.build_enemy_ships(squad)
	var encounter := Encounter.new()
	encounter.wallet = run
	encounter.squad = squad
	encounter.setup(run.living_ships(), enemies, run.jumps)
	var ticks := 0
	while encounter.outcome.is_empty() and ticks < 20 * 600:
		for ship in encounter.living(0):
			var targets := encounter.living(1)
			if targets.is_empty():
				break
			for slot in ship.weapons:
				if not slot.has_target():
					var target: Ship = targets[0]
					var system := target.system_by("weapons") if target.system_by("weapons") and not target.system_by("weapons").is_broken() else target.system_by("shields")
					slot.target_ship = target
					slot.target_room = system.room if system else 0
					slot.autofire = true
		if ticks % 20 == 0:
			_defend_against_boarders(encounter)
		for note in encounter.notes:
			if note.kind == "crew_died" and note.crew.side == 0:
				var member: CrewMember = note.crew
				var room_index: int = member.ship.room_at(member.cell)
				print("    crew died: %s on %s, room air %.2f fire %s, task %s, enemies in room %d, squad %s band %d t=%.0f" % [member.name, member.ship.name, member.ship.rooms[room_index].oxygen if room_index >= 0 else -1.0, member.ship.rooms[room_index].is_burning() if room_index >= 0 else false, member.task, member.ship.crew_in_room(room_index, 1).size() if room_index >= 0 else 0, squad.id, run.band(), ticks / 20.0])
			if note.kind == "surrender_offer":
				for enemy in encounter.living(1):
					enemy.surrendered = true
		encounter.notes.clear()
		encounter.step()
		ticks += 1
	_last = encounter
	if encounter.outcome.is_empty():
		return "timeout"
	return encounter.outcome


## What a player does about boarders: everyone who isn't flying goes to the fight, and the medbay gets power.
func _defend_against_boarders(encounter: Encounter) -> void:
	for ship in encounter.living(0):
		var boarded := -1
		for room in ship.rooms:
			if not ship.crew_in_room(room.index, 1).is_empty():
				boarded = room.index
		var medbay := ship.system_by("medbay")
		if boarded >= 0:
			for member in ship.crew:
				var pilot := ship.system_by("piloting")
				if member.ship == ship and member.can_act() and member.health > member.max_health * 0.35 and not (pilot and pilot.manned_by == member):
					CrewBrain.order_to_room(member, boarded, true)
			if medbay and ship.reactor_type == "core" and not medbay.enabled:
				var life := ship.system_by("oxygen")
				if life and life.enabled:
					life.enabled = false
				medbay.enabled = true
		else:
			var anyone_hurt := false
			for member in ship.crew:
				anyone_hurt = anyone_hurt or (not member.dead and member.health < member.max_health * 0.6)
			if anyone_hurt and medbay and ship.reactor_type == "core" and not medbay.enabled:
				var life := ship.system_by("oxygen")
				if life and life.enabled:
					life.enabled = false
				medbay.enabled = true
			for member in ship.crew:
				if member.ship == ship and member.can_act() and member.path.is_empty() and member.health < member.max_health * 0.45 and medbay and ship.room_at(member.cell) != medbay.room:
					CrewBrain.order_to_room(member, medbay.room, true)
					continue
				if member.ship == ship and member.can_act() and member.path.is_empty() and ship.room_at(member.cell) != member.station_room and member.health >= member.max_health * 0.9:
					if member.health < member.max_health * 0.5 and medbay:
						CrewBrain.order_to_room(member, medbay.room, true)
					else:
						CrewBrain.order_to_room(member, member.station_room, true)
			if medbay and ship.reactor_type == "core" and medbay.enabled:
				var hurt := false
				for member in ship.crew:
					hurt = hurt or (not member.dead and member.health < member.max_health * 0.9)
				if not hurt:
					medbay.enabled = false
					var life := ship.system_by("oxygen")
					if life:
						life.enabled = true


func _shop(run: RunState) -> void:
	var per_point := 48 if run.band() <= 3 else (73 if run.band() <= 6 else 97)
	for ship in run.living_ships():
		while ship.hull < ship.max_hull and run.mawjig > per_point + Mawjig.JUMP_COST * 3:
			run.spend(per_point)
			ship.repair_hull(1)
	# Upgrade shields and weapons when there's spare Mawjig
	for ship in run.living_ships():
		for behaviour in ["shields", "engines", "weapons"]:
			var system := ship.system_by(behaviour)
			if system and ShipOutfitter.system_upgrade_price(system) > 0 and run.mawjig > ShipOutfitter.system_upgrade_price(system) + 500:
				ShipOutfitter.upgrade_system(run, ship, system)
