class_name EventRunner
extends RefCounted
## Picks the event a cluster plays, works out which choices the squad can take (blue choices need a crew race,
## a system or a weapon), rolls an outcome and applies it to the run. A fight, a store or a following event is
## returned for the main flow to start; this class never opens screens itself.

const MAX_CREW_PER_SHIP := 8
const MAX_SQUAD := 6

var run: RunState
var mercenary: Ship = null   # the hired ship a contract event is about: {merc}, {price}, {jumps} ("3 jumps")


func _init(owner: RunState) -> void:
	run = owner


## The event for arriving at the current cluster.
func event_for_arrival() -> EventDef:
	var cluster := run.cluster()
	if cluster.kind == "final":
		return final_event()
	if cluster.kind == "opening":
		return Library.events.get("START_LAUNCH")
	# A race's tech site plays its event until the squad has the piece (GV 2F: never left to luck)
	var site: String = cluster.get("tech_site", "")
	if site != "" and not run.has_tech(site) and Library.events.has(RimTech.site_event(site)):
		return Library.events[RimTech.site_event(site)]
	if cluster.event_done:
		return before_or_after_collapse("REVISIT")
	var rival := _rival_event()
	if rival:
		return rival
	# A cluster at war is a front line: two quiet arrivals in five there turn into a fight (GDD 2R, Border: more fights)
	if cluster.states.has("At War") and cluster.kind in ["nothing", "neutral"] and int(cluster.seed) % 5 < 2:
		return pick("hostile")
	return pick(cluster.kind)


## What waits at the rim (GV 2F). With every piece of tech aboard, the rival's ambush and the Tech victory. Without
## them: the Last Fleet as ever, or, where the Tech victory is required, no way out yet.
func final_event() -> EventDef:
	if run.has_all_tech() and Library.events.has("FINAL_RIVAL_TECH"):
		return Library.events["FINAL_RIVAL_TECH"]
	if Settings.get_value("tech_victory", "Optional") == "Required" and Library.events.has("RIM_NO_WAY_OUT"):
		return Library.events["RIM_NO_WAY_OUT"]
	return Library.events.get("FINAL_RIVAL")


## The rival hunts a squad that is collecting the pieces (two or more aboard, or the Tech victory required) in the
## last two bands (heromedel, 2026-11-14): one meeting in each, on one arrival in three, by the cluster's own number
## so every machine and every reload agree.
func _rival_event() -> EventDef:
	if run.tech.size() < 2 and Settings.get_value("tech_victory", "Optional") != "Required":
		return null
	var last: int = run.galaxy.bands
	for step in [["RIVAL_FIRST", last - 1], ["RIVAL_SECOND", last]]:
		var id: String = step[0]
		if run.used_events.has(id):
			continue
		if not Library.events.has(id) or run.band() < int(step[1]) or run.cluster().store:
			return null
		return Library.events[id] if int(run.cluster().seed) % 3 == 0 else null
	return null


## The event after a meeting with the rival, when it has broken off (or been beaten), or null.
func after_rival_event(squad: SquadDef) -> EventDef:
	if squad == null or squad.id != "rival-hunt":
		return null
	return Library.events.get("RIVAL_SECOND_AFTER" if run.used_events.has("RIVAL_SECOND") else "RIVAL_FIRST_AFTER")


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
	if mercenary:
		result = result.replace("{merc}", mercenary.name).replace("{price}", Mawjig.format(run.renewal_price(mercenary)))
		var jumps := int(mercenary.contract.get("jumps", 0))
		result = result.replace("{jumps}", "%d jump%s" % [jumps, "" if jumps == 1 else "s"])
	if crew_name.is_empty():
		var anyone := _any_crew()
		crew_name = anyone.name if anyone else "your crew"
	return Species.words(result.replace("{crew}", crew_name))


## Whether the squad can take a choice; blue choices the squad can't take are not shown at all, as in the genre.
func can_take(choice: Dictionary) -> bool:
	return _meets(choice.requires) and _meets(choice.get("also", ""))


## Whether the squad meets one requirement: "crew:race", "system:id", "mawjig:amount", "tech:race" and so on.
func _meets(requirement: String) -> bool:
	if requirement.is_empty():
		return true
	var parts := requirement.split(":")
	match parts[0]:
		"crew":
			return _crew_of_race(parts[1]) != null
		"system":
			for ship in run.living_ships():
				# By the system's kind, so a race's own make counts too (the Pheromone Gland is Mind Control)
				if ship.system_by(parts[1]) or ship.system_by_id(parts[1]) or ship.system_by(parts[1].replace("-", "_")):
					return true
			return false
		"mawjig":
			return run.mawjig >= Mawjig.amount(float(parts[1]))
		"hire":
			return run.mawjig >= run.hire_price(float(parts[1]))
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
		"renewal":
			return mercenary != null and run.mawjig >= run.renewal_price(mercenary)
		"tech":
			return run.has_tech(parts[1])
		"no_tech":
			return not run.has_tech(parts[1])
		"afford_tech":      # the price of a race's piece here, times a share: "afford_tech:mecha:0.6"
			return run.mawjig >= RimTech.price(parts[1], run.band(), float(parts[2]) if parts.size() > 2 else 1.0)
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
		"hire":
			return "(%s Mawjig)" % Mawjig.format(run.hire_price(float(parts[1])))
		"renewal":
			return "(%s Mawjig)" % Mawjig.format(run.renewal_price(mercenary)) if mercenary else ""
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
				most = maxi(most, -_fixed_amount(effect.attrs))
			elif effect.tag == "renew_contract" and mercenary:
				most = maxi(most, run.renewal_price(mercenary))
	return mini(most, run.mawjig)


## A Mawjig effect's written amount in cents; one marked by_band (a mercenary's price) rises with the band.
func _fixed_amount(attrs: Dictionary) -> int:
	if attrs.has("tech"):       # the price of a race's piece here, times a share
		return -RimTech.price(attrs.tech, run.band(), float(attrs.get("share", "1")))
	var amount := float(attrs.get("amount", "0"))
	if attrs.get("by_band", "") == "yes":
		return -run.hire_price(-amount) if amount < 0.0 else run.hire_price(amount)
	return Mawjig.amount(amount)


func _apply(tag: String, attrs: Dictionary, result: Dictionary) -> void:
	match tag:
		"mawjig":
			var cents := 0
			if attrs.has("size"):
				cents = Mawjig.reward_for_size(attrs.size, run.band())
			else:
				cents = _fixed_amount(attrs)
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
				var ship := _ship_with_room(Library.race(race_id))
				if ship == null:
					result.lines.append("No Armoured Avatar Array with room to host a Senti" if Library.race(race_id) and Library.race(race_id).broadcast else "No room aboard for more crew")
					break
				var race := Library.race(race_id)
				var member := CrewMember.create(race, race.random_name(run.rng, ship.crew.map(func(c): return c.name)))
				ship.add_crew(member)
				ship.assign_stations()
				run.dress_crew()
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
				var ship := Ship.from_design(design, 0, run.rng, Settings.get_value("terran_conduits", false))
				if attrs.has("hull"):
					ship.hull = clampi(int(attrs.hull), 1, ship.max_hull)
				ship.name = attrs.get("name", ship.name)
				run.squad.append(ship)
				if attrs.has("contract"):   # a mercenary, paid what the choice cost (GV 7C)
					var pay := float(attrs.get("pay", "0"))
					run.hire(ship, int(attrs.contract), run.hire_price(pay) if attrs.get("by_band", "") == "yes" else Mawjig.amount(pay))
					result.lines.append("+1 ship: the %s signs on for %s jumps" % [ship.name, attrs.contract])
				else:
					result.lines.append("+1 ship: the %s joins the squad" % ship.name)
		"renew_contract":
			if mercenary:
				var price := run.renewal_price(mercenary)
				run.renew(mercenary)
				result.lines.append("Mawjig -%s: the %s signs on for %d more jumps" % [Mawjig.format(price), mercenary.name, mercenary.contract.jumps])
		"end_contract":
			if mercenary:
				run.release(mercenary)
				result.lines.append("The %s leaves the squad" % mercenary.name)
		"tech":
			var race_id: String = attrs.get("race", "")
			if race_id == "" or race_id == "region":
				race_id = run.cluster().race
			if run.give_tech(race_id, "event"):
				result.lines.append("Rim tech: %s (%d of %d)" % [RimTech.name_of(race_id), run.tech.size(), RimTech.order.size()])
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


func _ship_with_room(race: RaceDef = null) -> Ship:
	for ship in run.living_ships():
		if ship.living_crew_count() < MAX_CREW_PER_SHIP and (race == null or Refit.can_host(ship, race)):
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
		if cluster.enemy != "" and squad.where_races.has(cluster.enemy):
			weight += 2.0        # at war, the other side's ships are met here too (GDD 2R: ships of both sides)
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
		var ship := Ship.from_design(design, 1, run.rng, Settings.get_value("terran_conduits", false))
		# Ships met farther out carry a little more hull than their file lists, as the genre scales by sector
		var band_hull := 1.0 + 0.04 * (run.band() - 1)
		ship.max_hull = maxi(3, int(round(ship.max_hull * difficulty_hull * band_hull)))
		ship.hull = maxi(1, int(round(ship.max_hull * squad.starts_at)))
		ships.append(ship)
	return ships


## The ships a squad has waiting to replace its losses, built as its others are.
func build_reinforcements(squad: SquadDef) -> Array[Ship]:
	var ships: Array[Ship] = []
	var difficulty_hull := {"Easy": 0.8, "Normal": 1.0, "Hard": 1.25}.get(run.difficulty, 1.0) as float
	for design_id in squad.reinforcements:
		var design := Library.ship(design_id)
		if design:
			var ship := Ship.from_design(design, 1, run.rng, Settings.get_value("terran_conduits", false))
			ship.max_hull = maxi(3, int(round(ship.max_hull * difficulty_hull * (1.0 + 0.04 * (run.band() - 1)))))
			ship.hull = ship.max_hull
			ships.append(ship)
	return ships


## What a won fight pays (GDD 8I): each wreck 2.5% of the ship's value times the band adjustment; a ship whose
## crew were killed pays about 30% more; a surrender pays about half, on its own terms.
func fight_rewards(encounter: Encounter) -> Dictionary:
	var total := 0
	var surrender_paid := 0
	var lines: Array = []
	for ship in encounter.all_enemy_ships():
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
		elif ship.surrendered and encounter.surrender_pays:
			var paid := Mawjig.amount(base * 0.5 / 100.0)
			total += paid
			surrender_paid += paid
			lines.append("%s surrendered: Mawjig +%s" % [ship.name, Mawjig.format(paid)])
	if total > 0:
		run.earn(total)
	# The Tech victory's pieces (GV 2F): a ship left whole, its crew dead, may carry its race's piece
	for ship in encounter.all_enemy_ships():
		var race: String = ship.design.race
		if ship.crew_dead and not ship.destroyed and RimTech.pieces.has(race) and not run.has_tech(race) and run.band() >= RimTech.from_band and run.rng.randf() < RimTech.steal_chance_in(run.band()):
			run.give_tech(race, "taken")
			lines.append("You strip the %s out of the %s. (%d of %d)" % [RimTech.name_of(race), ship.name, run.tech.size(), RimTech.order.size()])
	# And close to the rim, a ship that surrenders can be asked for its piece in place of its Mawjig
	var demand := ""
	if surrender_paid > 0 and run.band() >= RimTech.demand_band:
		for ship in encounter.all_enemy_ships():
			var race: String = ship.design.race
			if ship.surrendered and RimTech.pieces.has(race) and RimTech.pieces[race].surrendered and not run.has_tech(race):
				demand = race
	# Now and then something useful survives in the wreckage
	var beaten := 0
	for ship in encounter.all_enemy_ships():
		if ship.destroyed or ship.crew_dead:
			beaten += 1
	if beaten > 0 and run.rng.randf() < 0.18:
		var ship := encounter.enemy_ships()[0]
		if not ship.weapons.is_empty():
			var weapon := ship.weapons[run.rng.randi_range(0, ship.weapons.size() - 1)].def
			run.cargo.append(weapon.id)
			lines.append("Salvaged weapon: %s" % weapon.display_name())
	# Survivors who may ask to join, for the player to accept or not (heromedel, 2026-10-31): boarders who surrendered
	# when their ship was destroyed, and now and then someone from a ship that surrendered. Never from a wreck.
	var survivors: Array = []
	for member in encounter.surrendered_boarders:
		survivors.append({"race": member.race.id, "name": member.name, "why": "surrendered when their ship was destroyed"})
	for ship in encounter.enemy_ships():
		if ship.surrendered and run.rng.randf() < 0.3:
			var crew: Array = ship.crew.filter(func(m): return not m.dead)
			if not crew.is_empty():
				var member: CrewMember = crew[run.rng.randi_range(0, crew.size() - 1)]
				survivors.append({"race": member.race.id, "name": member.name, "why": "has had enough of the %s" % ship.name})
	return {"mawjig": total, "lines": lines, "survivors": survivors, "tech_demand": demand, "surrender_paid": surrender_paid}


## The races whose piece the squad still lacks, where pieces are to be had at all (for a fight's captains).
func tech_wanted() -> Array[String]:
	var wanted: Array[String] = []
	if run.band() >= RimTech.from_band:
		wanted = run.missing_tech()
	return wanted


## The squad hands back a surrender's Mawjig and takes the ship's piece of tech instead.
func trade_surrender_for_tech(rewards: Dictionary) -> bool:
	var race: String = rewards.get("tech_demand", "")
	if race == "" or run.has_tech(race):
		return false
	run.mawjig = maxi(0, run.mawjig - int(rewards.get("surrender_paid", 0)))
	run.give_tech(race, "surrender")
	rewards["tech_demand"] = ""
	return true


## Takes a survivor aboard the first ship with room. Returns the ship, or null when every ship is full.
func take_survivor(survivor: Dictionary) -> Ship:
	var ship := _ship_with_room()
	if ship == null:
		return null
	ship.add_crew(CrewMember.create(Library.race(survivor.race), survivor.name))
	ship.assign_stations()
	run.dress_crew()
	run.log_book.write("survivor_joined", survivor, "%s joined the crew." % survivor.name)
	return ship
