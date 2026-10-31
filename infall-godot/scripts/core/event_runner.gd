class_name EventRunner
extends RefCounted
## Picks the event a cluster plays, works out which choices the squad can take (blue choices need a crew race,
## a system or a weapon), rolls an outcome and applies it to the run. A fight, a store or a following event is
## returned for the main flow to start; this class never opens screens itself.

const MAX_CREW_PER_SHIP := 8
const MAX_SQUAD := 6

var run: RunState


func _init(owner: RunState) -> void:
	run = owner


## The event for arriving at the current cluster.
func event_for_arrival() -> EventDef:
	var cluster := run.cluster()
	if cluster.kind == "final":
		return Library.events.get("FINAL_RIVAL")
	if cluster.kind == "opening":
		return Library.events.get("START_LAUNCH")
	if cluster.event_done:
		return before_or_after_collapse("REVISIT")
	return pick(cluster.kind)


## The collapse opening message laid over this jump's event (GDD 2P), or null.
func opening_message() -> EventDef:
	if run.jumps >= 1 and run.jumps < Galaxy.OPENING_JUMPS:
		return Library.events.get("COLLAPSE_OPENING_%d" % (run.jumps + 1))
	return null


func pick(kind: String) -> EventDef:
	var cluster := run.cluster()
	var race: String = cluster.race if cluster.occupier == "" else cluster.occupier
	var states: Array = cluster.states
	var candidates: Array[EventDef] = []
	var weights: Array[float] = []
	for def in Library.events.values():
		if def.kind != kind or not def.fits(run.band(), states, race):
			continue
		if def.unique and run.used_events.has(def.id):
			continue
		if def.after_collapse and not collapse_known():
			continue
		if not def.hazard.is_empty() and def.hazard != cluster.hazard:
			continue
		var weight: float = def.weight
		if not def.races.is_empty() and def.races.has(race):
			weight *= 2.5   # a race's own events come up more in its own space
		if run.used_events.has(def.id):
			weight *= 0.25
		candidates.append(def)
		weights.append(weight)
	if candidates.is_empty():
		if kind != "nothing":
			return pick("nothing")
		return Library.events.get("NOTHING_GENERIC")
	var total := 0.0
	for weight in weights:
		total += weight
	var roll := run.rng.randf() * total
	for index in candidates.size():
		roll -= weights[index]
		if roll <= 0.0:
			return candidates[index]
	return candidates.back()


## The text with placeholders filled: {crew} a crew member who fits the choice, {race} the cluster's race.
func fill_text(text: String, crew_name: String = "") -> String:
	var cluster := run.cluster()
	var race: String = cluster.race if cluster.race != "" else "terran"
	var result := text.replace("{race}", Library.race(race).name).replace("{cluster}", cluster.name)
	result = result.replace("{ship}", run.living_ships()[0].name if not run.living_ships().is_empty() else "your ship")
	if crew_name.is_empty():
		var anyone := _any_crew()
		crew_name = anyone.name if anyone else "your crew"
	return result.replace("{crew}", crew_name)


## Whether the squad can take a choice; blue choices the squad can't take are not shown at all, as in the genre.
func can_take(choice: Dictionary) -> bool:
	var requirement: String = choice.requires
	if requirement.is_empty():
		return true
	var parts := requirement.split(":")
	match parts[0]:
		"crew":
			return _crew_of_race(parts[1]) != null
		"system":
			for ship in run.living_ships():
				if ship.system_by(parts[1]) or ship.system_by_id(parts[1]):
					return true
			return false
		"mawjig":
			return run.mawjig >= Mawjig.amount(float(parts[1]))
		"weapon":
			for ship in run.living_ships():
				for slot in ship.weapons:
					if slot.def.type == parts[1]:
						return true
			return false
		"squad":
			return run.living_ships().size() >= int(parts[1])
		"collapse":
			return collapse_known()
	return true


## Whether the squad knows about the collapse: from the opening's fifth cluster, when it appears (GDD 2P).
## Before that, events must not speak of it.
func collapse_known() -> bool:
	return run.galaxy.collapse_radius > 0.0


## An event, or its _EARLY version while the collapse is still unknown.
func before_or_after_collapse(id: String) -> EventDef:
	if not collapse_known() and Library.events.has(id + "_EARLY"):
		return Library.events[id + "_EARLY"]
	return Library.events.get(id)


func is_blue(choice: Dictionary) -> bool:
	var requirement: String = choice.requires
	return requirement.begins_with("crew:") or requirement.begins_with("system:") or requirement.begins_with("weapon:")


func requirement_label(choice: Dictionary) -> String:
	var parts := String(choice.requires).split(":")
	match parts[0]:
		"crew":
			return "(%s Crew)" % Library.race(parts[1]).name
		"system":
			var def := Library.system(parts[1])
			return "(%s)" % (def.name if def else parts[1].capitalize())
		"weapon":
			return "(%s)" % parts[1].capitalize()
		"mawjig":
			return "(%s Mawjig)" % parts[1]
	return ""


func crew_for_choice(choice: Dictionary) -> String:
	var parts := String(choice.requires).split(":")
	if parts[0] == "crew":
		var member := _crew_of_race(parts[1])
		if member:
			return member.name
	return ""


## Rolls an outcome of a choice and applies it. Returns {text, lines, fight, store, next_event, reveal, end_run}.
func resolve(choice: Dictionary, crew_name: String) -> Dictionary:
	var outcomes: Array = choice.outcomes
	var total := 0.0
	for outcome in outcomes:
		total += float(outcome.weight)
	var roll := run.rng.randf() * total
	var picked: Dictionary = outcomes[0]
	for outcome in outcomes:
		roll -= float(outcome.weight)
		if roll <= 0.0:
			picked = outcome
			break
	var result := {"text": fill_text(picked.text, crew_name), "lines": [], "fight": "", "fight_given": false, "store": false, "next_event": "", "reveal": false, "surprise": false}
	for effect in picked.effects:
		_apply(effect.tag, effect.attrs, result)
	return result


## The most Mawjig a choice can give away, over all its outcomes (for the low Mawjig warning, GDD 14L).
func most_given_away(choice: Dictionary) -> int:
	var most := 0
	for outcome in choice.outcomes:
		for effect in outcome.effects:
			if effect.tag == "mawjig" and not effect.attrs.has("size"):
				most = maxi(most, -Mawjig.amount(float(effect.attrs.get("amount", "0"))))
	return mini(most, run.mawjig)


func _apply(tag: String, attrs: Dictionary, result: Dictionary) -> void:
	match tag:
		"mawjig":
			var cents := 0
			if attrs.has("size"):
				cents = Mawjig.reward_for_size(attrs.size, run.band())
			else:
				cents = Mawjig.amount(float(attrs.get("amount", "0")))
			if cents < 0:
				cents = -mini(-cents, run.mawjig)
				run.mawjig += cents
			else:
				run.earn(cents)
			result.lines.append("Mawjig %s%s" % ["+" if cents >= 0 else "", Mawjig.format(cents)])
		"hull":
			var amount := int(attrs.get("amount", "0"))
			var ships := run.living_ships()
			if ships.is_empty():
				return
			var ship := ships[run.rng.randi_range(0, ships.size() - 1)]
			if amount < 0:
				ship.damage_hull(-amount)
				if ship.destroyed:
					ship.hull = 1   # an event never destroys a ship outright
					ship.destroyed = false
				result.lines.append("%s hull -%d" % [ship.name, -amount])
			else:
				ship.repair_hull(amount)
				result.lines.append("%s hull +%d" % [ship.name, amount])
		"repair":
			for ship in run.living_ships():
				if attrs.get("amount", "all") == "all":
					ship.hull = ship.max_hull
				else:
					ship.repair_hull(int(attrs.amount))
				ship.repair_everything()
			result.lines.append("Squad repaired")
		"crew":
			var race_id: String = attrs.get("race", "")
			if race_id == "" or race_id == "region":
				race_id = run.cluster().race if run.cluster().race != "" else "terran"
			for copy in int(attrs.get("count", "1")):
				var ship := _ship_with_room()
				if ship == null:
					result.lines.append("No room aboard for more crew")
					break
				var race := Library.race(race_id)
				var member := CrewMember.create(race, race.random_name(run.rng, ship.crew.map(func(c): return c.name)))
				ship.add_crew(member)
				ship.assign_stations()
				result.lines.append("+1 crew: %s (%s) joins the %s" % [member.name, race.singular, ship.name])
		"crew_hurt":
			var member := _any_crew()
			if member:
				member.health = maxf(1.0, member.health - float(attrs.get("amount", "30")))
				result.lines.append("%s injured" % member.name)
		"crew_lose":
			var member := _any_crew()
			if member and member.home.living_crew_count() > 1:
				member.dead = true
				member.home.crew.erase(member)
				result.lines.append("%s lost" % member.name)
		"weapon":
			var weapon_id: String = attrs.get("id", "")
			if weapon_id.is_empty() or weapon_id == "random":
				weapon_id = random_weapon(attrs.get("tier", "low"), attrs.get("race", ""))
			if Library.weapon(weapon_id):
				run.cargo.append(weapon_id)
				result.lines.append("Weapon: %s (in the hold)" % Library.weapon(weapon_id).display_name())
		"system_damage":
			for ship in run.living_ships():
				var system := ship.systems[run.rng.randi_range(0, ship.systems.size() - 1)]
				ship.damage_system(system, int(attrs.get("amount", "1")))
				result.lines.append("%s damaged on the %s" % [system.def.name, ship.name])
				break
		"upgrade":
			var options: Array = []
			for ship in run.living_ships():
				for system in ship.systems:
					if system.level < system.def.max_level and system.behaviour != "power_core":
						options.append([ship, system])
			if not options.is_empty():
				var pick: Array = options[run.rng.randi_range(0, options.size() - 1)]
				var system: ShipSystem = pick[1]
				system.level += 1
				result.lines.append("%s upgraded to level %d on the %s" % [system.def.name, system.level, pick[0].name])
		"ship":
			if run.living_ships().size() >= MAX_SQUAD:
				result.lines.append("The squad is full; the ship goes its own way")
				return
			var design := Library.ship(attrs.get("design", "outrider"))
			if design:
				var ship := Ship.from_design(design, 0, run.rng, Settings.get_value("terran_conduits", true))
				if attrs.has("hull"):
					ship.hull = clampi(int(attrs.hull), 1, ship.max_hull)
				ship.name = attrs.get("name", ship.name)
				run.squad.append(ship)
				result.lines.append("+1 ship: the %s joins the squad" % ship.name)
		"fight":
			result.fight = attrs.get("squad", "")
			result.fight_given = true
			result.surprise = attrs.get("surprise", "no") == "yes"
		"store":
			result.store = true
			run.cluster().store = true
		"event":
			result.next_event = attrs.get("id", "")
		"reveal":
			result.reveal = true
			for index in run.galaxy.clusters.size():
				if run.galaxy.clusters[index].position.distance_to(run.cluster().position) < 700.0:
					run.galaxy.clusters[index].seen = true
			result.lines.append("Nearby clusters charted")
		"xp":
			var member := _any_crew()
			if member:
				member.gain_xp(attrs.get("skill", "repair"), float(attrs.get("amount", "25")))
				result.lines.append("%s gains %s experience" % [member.name, String(attrs.get("skill", "repair"))])


func random_weapon(tier: String, race: String) -> String:
	var options: Array[String] = []
	var limits := {"low": [0, 900], "mid": [700, 1500], "high": [1300, 99999]}.get(tier, [0, 99999]) as Array
	for def in Library.weapons.values():
		if def.type == "suit" or def.id.ends_with("-stolen"):
			continue
		if not race.is_empty() and def.race != race:
			continue
		if def.price >= limits[0] and def.price <= limits[1]:
			options.append(def.id)
	if options.is_empty():
		return "gat-2-1"
	return options[run.rng.randi_range(0, options.size() - 1)]


func _crew_of_race(race_id: String) -> CrewMember:
	for ship in run.living_ships():
		for member in ship.crew:
			if not member.dead and member.race.id == race_id:
				return member
	return null


func _any_crew() -> CrewMember:
	var everyone: Array[CrewMember] = []
	for ship in run.living_ships():
		for member in ship.crew:
			if not member.dead:
				everyone.append(member)
	if everyone.is_empty():
		return null
	return everyone[run.rng.randi_range(0, everyone.size() - 1)]


func _ship_with_room() -> Ship:
	for ship in run.living_ships():
		if ship.living_crew_count() < MAX_CREW_PER_SHIP:
			return ship
	return null


# --- Fights ---------------------------------------------------------------------------------------------------

## The enemy squad for a fight here: a named squad, or one that fits the cluster's race, state and band.
func pick_squad(squad_id: String) -> SquadDef:
	if not squad_id.is_empty() and Library.squads.has(squad_id):
		return Library.squads[squad_id]
	var cluster := run.cluster()
	var race: String = cluster.occupier if cluster.occupier != "" else cluster.race
	var options: Array[SquadDef] = []
	var weights: Array[float] = []
	for squad in Library.squads.values():
		if squad.id.begins_with("final") or not squad.has_band(run.band()):
			continue
		var weight := squad_weight(squad, race, cluster.states)
		if weight > 0.0:
			options.append(squad)
			weights.append(weight)
	if options.is_empty():
		return Library.squads.values()[0]
	var total := 0.0
	for weight in weights:
		total += weight
	var roll := run.rng.randf() * total
	for index in options.size():
		roll -= weights[index]
		if roll <= 0.0:
			return options[index]
	return options.back()


func squad_weight(squad: SquadDef, race: String, states: Array) -> float:
	var weight := 0.0
	if squad.where_races.has(race):
		weight += 3.0
	if squad.where_races.has("any"):
		weight += 0.6
	if weight == 0.0:
		return 0.0
	var state_match := squad.where_states.is_empty()
	for state in states:
		if squad.where_states.has(state):
			state_match = true
	return weight if state_match else weight * 0.15


func build_enemy_ships(squad: SquadDef) -> Array[Ship]:
	var ships: Array[Ship] = []
	var difficulty_hull := {"Easy": 0.8, "Normal": 1.0, "Hard": 1.25}.get(run.difficulty, 1.0) as float
	for design_id in squad.roll_ships(run.band(), run.rng):
		var design := Library.ship(design_id)
		if design == null:
			continue
		var ship := Ship.from_design(design, 1, run.rng, true)
		# Ships met farther out carry a little more hull than their file lists, as the genre scales by sector
		var band_hull := 1.0 + 0.04 * (run.band() - 1)
		ship.max_hull = maxi(3, int(round(ship.max_hull * difficulty_hull * band_hull)))
		ship.hull = ship.max_hull
		ships.append(ship)
	return ships


## What a won fight pays (GDD 8I): each wreck 2.5% of the ship's value times the band adjustment; a ship whose
## crew were killed pays about 30% more; a surrender pays about half, on its own terms.
func fight_rewards(encounter: Encounter) -> Dictionary:
	var total := 0
	var lines: Array = []
	for ship in encounter.enemy_ships():
		var base := ship.design.value * 0.025 * run.band_adjustment()
		if ship.crew_dead and not ship.destroyed:
			var paid := Mawjig.amount(base * 1.3 / 100.0)
			total += paid
			lines.append("%s, crew killed: Mawjig +%s" % [ship.name, Mawjig.format(paid)])
			run.stats.crews_killed += 1
		elif ship.destroyed:
			var paid := Mawjig.amount(base / 100.0)
			total += paid
			lines.append("%s wreckage converted: Mawjig +%s" % [ship.name, Mawjig.format(paid)])
			run.stats.ships_destroyed += 1
		elif ship.surrendered:
			var paid := Mawjig.amount(base * 0.5 / 100.0)
			total += paid
			lines.append("%s surrendered: Mawjig +%s" % [ship.name, Mawjig.format(paid)])
	if total > 0:
		run.earn(total)
	# Now and then something useful survives in the wreckage
	var beaten := 0
	for ship in encounter.enemy_ships():
		if ship.destroyed or ship.crew_dead:
			beaten += 1
	if beaten > 0 and run.rng.randf() < 0.18:
		var ship := encounter.enemy_ships()[0]
		if not ship.weapons.is_empty():
			var weapon := ship.weapons[run.rng.randi_range(0, ship.weapons.size() - 1)].def
			run.cargo.append(weapon.id)
			lines.append("Salvaged weapon: %s" % weapon.display_name())
	if beaten > 0 and run.rng.randf() < 0.08:
		var ship := _ship_with_room()
		if ship:
			var race := Library.race(encounter.enemy_ships()[0].race.id)
			var member := CrewMember.create(race, race.random_name(run.rng, []))
			ship.add_crew(member)
			ship.assign_stations()
			lines.append("A survivor, %s (%s), asks to join your crew" % [member.name, race.singular])
	return {"mawjig": total, "lines": lines}
