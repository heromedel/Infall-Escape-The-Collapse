extends Node
## Playtesters: bots that play whole runs, the way three kinds of player would.
##   careless  doesn't try: fires each weapon as it charges at any room, picks event choices at random, flies
##             straight for the rim, repairs only when badly hurt and buys the odd thing. Shows how fast a run
##             can be lost. It never harms its own ships on purpose.
##   watcher   a good player who goes by what is on the screen: focuses the squad's fire on the weakest enemy,
##             shoots weapons then shields, takes blue choices, explores while the collapse is far off, keeps the
##             hull patched and upgrades to a plan. It can't see what an event choice leads to.
##   expert    knows the game: what every event choice is worth, which enemy to kill first, when to leave a
##             fight, and how to spend everything before the end. Thinks five times a second, as a player who
##             pauses does. Shows whether a run can be won.
## A ship in a fight is flown by the same captain code the enemy uses (ShipAI), so both sides play alike.
## Prints a line a run and a summary. About one win in ten is the genre's normal for a good player.
## Run: RUNS=40 SKILL=watcher godot --headless --path . tools/playtest.tscn
## Also: SHIP (starting ship id), SEED (first seed), VERBOSE=1 (every fight), DIFFICULTY (Easy, Normal, Hard)

const FIGHT_LIMIT := 20 * 600       # ten minutes of fight time: after that it is a stalemate
const SAFE_GAP := 560.0             # how far ahead of the collapse a careful player stays before exploring sideways
const SIZE_VALUE := {"tiny": 150, "low": 450, "medium": 900, "high": 1500, "huge": 2200}
const PLAYERS := {
	"careless": {"focus": false, "events": "random", "explore": false, "flee_below": 0.0, "repair_to": 0.5, "shop": "odd", "reserve": 3, "think_every": 20, "gives_up_after": 600},
	"watcher": {"focus": true, "events": "sees", "explore": true, "flee_below": 0.15, "repair_to": 0.8, "shop": "plan", "reserve": 6, "think_every": 10, "gives_up_after": 150},
	"expert": {"focus": true, "events": "knows", "explore": true, "flee_below": 0.3, "repair_to": 0.95, "shop": "all", "reserve": 10, "think_every": 4, "gives_up_after": 90},
}

var player: Dictionary = PLAYERS.watcher
var skill := "watcher"
var verbose := false
var _last: Encounter
var _fights: Dictionary = {}        # "band squad" -> what happened in every fight against it, for the balance table
var _starved := 0                   # times a squad had to wait because it couldn't pay for a jump


func _ready() -> void:
	var runs := int(_env("RUNS", "10"))
	var first := int(_env("SEED", "1000"))
	skill = _env("SKILL", "watcher")
	player = PLAYERS[skill]
	verbose = _env("VERBOSE", "") != ""
	if _env("DIFFICULTY", "") != "":
		Settings._values["difficulty"] = _env("DIFFICULTY", "Normal")
	var reports: Array = []
	for index in runs:
		var report := _play_one(first + index, _env("SHIP", "outrider"))
		reports.append(report)
		print("run %d %-5s band %d jump %3d  fights %2d (%2d won, %d fled, %d stalemates)  most ships %d  mawjig %7s  %s" % [report.seed, report.result, report.band, report.jumps, report.fights, report.won, report.fled, report.stalemates, report.most_ships, Mawjig.format(report.mawjig), report.ended_by])
	_summary(reports)
	get_tree().quit()


func _env(name: String, fallback: String) -> String:
	return OS.get_environment(name) if OS.get_environment(name) != "" else fallback


func _summary(reports: Array) -> void:
	var wins := reports.filter(func(r): return r.result == "WON").size()
	var bands := {}
	var killers := {}
	var fights := 0
	var stalemates := 0
	var fled := 0
	for report in reports:
		fights += report.fights
		stalemates += report.stalemates
		fled += report.fled
		if report.result != "WON":
			bands[report.band] = bands.get(report.band, 0) + 1
			killers[report.ended_by] = killers.get(report.ended_by, 0) + 1
	print("\n%s: %d of %d runs won (%.0f%%). Fights %d, stalemates %d, fights fled %d." % [skill, wins, reports.size(), 100.0 * wins / maxi(1, reports.size()), fights, stalemates, fled])
	var band_line := PackedStringArray()
	for band in range(1, 9):
		band_line.append("band %d: %d" % [band, bands.get(band, 0)])
	print("runs ended in  " + "  ".join(band_line))
	var names := killers.keys()
	names.sort_custom(func(a, b): return killers[a] > killers[b])
	print("ended by  " + ", ".join(names.map(func(name): return "%s %d" % [name, killers[name]])))
	print("waits for want of Mawjig: %d" % _starved)
	print("\nband squad                 fights  lost  left  hull lost  shots  paid  shots/paid")
	var keys := _fights.keys()
	keys.sort()
	for key in keys:
		var row: Dictionary = _fights[key]
		print("%-26s %6d %5d %5d %8.0f%% %6.2f %6.2f %8.0f%%" % [key, row.fights, row.lost, row.left, 100.0 * row.hull / row.fights, row.spent / 100.0 / row.fights, row.paid / 100.0 / row.fights, 100.0 * row.spent / maxf(1.0, row.paid)])


func _play_one(seed_number: int, ship_id: String) -> Dictionary:
	var run := RunState.start(seed_number, ship_id)
	var runner := EventRunner.new(run)
	var report := {"seed": seed_number, "result": "LOST", "band": 1, "jumps": 0, "fights": 0, "won": 0, "fled": 0, "stalemates": 0, "ships": 1, "most_ships": 1, "mawjig": 0, "ended_by": "ran out of jumps"}
	while run.jumps < 400:
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
				report.fights += 1
				var squad := runner.pick_squad(result.fight)
				var band := run.band()
				var hull_before := _hull(run)
				var mawjig_before := run.mawjig
				var outcome := _fight(run, runner, squad)
				var spent := mawjig_before - run.mawjig
				var paid := 0
				if outcome in ["won", "surrendered"]:
					var before_pay := run.mawjig
					runner.fight_rewards(_last)
					paid = run.mawjig - before_pay
				_note_fight(band, squad.id, outcome, hull_before, _hull(run), spent, paid)
				if verbose:
					print("    jump %d band %d: %s vs %s, hulls %s, mawjig %s" % [run.jumps, run.band(), outcome, squad.id, str(run.squad.map(func(s): return "%d/%d" % [s.hull, s.max_hull])), Mawjig.format(run.mawjig)])
				match outcome:
					"won", "surrendered":
						report.won += 1
					"fled":
						report.fled += 1
					"stalemate":
						report.stalemates += 1
					"lost":
						var gone := run.squad.filter(func(s): return s.destroyed).size()
						report.ended_by = "%s (%s)" % [squad.id, "ships destroyed" if gone > 0 else "crew killed"]
						return _close(report, run)
				if run.cluster().kind == "final" and outcome in ["won", "surrendered"]:
					report.result = "WON"
					report.ended_by = "reached the rim"
					return _close(report, run)
			if result.store or run.cluster().store:
				_shop(run)
		run.clear_lost_ships()
		report.most_ships = maxi(report.most_ships, run.living_ships().size())
		_rest(run)
		if not _travel(run):
			_starved += 1
			run.wait()
		if run.galaxy.is_swallowed(run.current) or run.collapse_distance() < 60.0:
			report.ended_by = "swallowed by the collapse"
			return _close(report, run)
	return _close(report, run)


## The squad's hull as [points left, points when whole].
func _hull(run: RunState) -> Array:
	var left := 0
	var whole := 0
	for ship in run.squad:
		whole += ship.max_hull
		left += maxi(0, ship.hull) if not ship.destroyed else 0
	return [left, whole]


func _note_fight(band: int, squad_id: String, outcome: String, before: Array, after: Array, spent: int, paid: int) -> void:
	var key := "%d %s" % [band, squad_id]
	if not _fights.has(key):
		_fights[key] = {"fights": 0, "lost": 0, "left": 0, "hull": 0.0, "spent": 0, "paid": 0}
	var row: Dictionary = _fights[key]
	row.fights += 1
	row.lost += 1 if outcome == "lost" else 0
	row.left += 1 if outcome in ["fled", "stalemate"] else 0
	row.hull += float(before[0] - after[0]) / maxf(1.0, float(before[1]))
	row.spent += spent
	row.paid += paid


func _close(report: Dictionary, run: RunState) -> Dictionary:
	report.band = run.band()
	report.jumps = run.jumps
	report.ships = run.living_ships().size()
	report.mawjig = run.mawjig
	return report


## Between clusters a player lets the crew finish repairs, and heal if the ship has a working medbay.
func _rest(run: RunState) -> void:
	for ship in run.living_ships():
		ship.repair_everything()
		if ship.system_by("medbay"):
			for member in ship.crew:
				member.health = member.max_health


# --- Events ---------------------------------------------------------------------------------------------------

func _resolve(runner: EventRunner, event: EventDef) -> Dictionary:
	var choices: Array = event.choices.filter(func(c): return runner.can_take(c))
	var choice: Dictionary = choices[runner.run.rng.randi_range(0, choices.size() - 1)]
	match String(player.events):
		"sees":
			# Blue choices first; short of Mawjig, a choice that asks for none
			var free: Array = choices.filter(func(c): return runner.most_given_away(c) <= 0)
			if runner.run.mawjig < 600 and not free.is_empty():
				choice = free[runner.run.rng.randi_range(0, free.size() - 1)]
			for each in choices:
				if runner.is_blue(each):
					choice = each
		"knows":
			var best := -INF
			for each in choices:
				var value := _choice_value(runner, each)
				if value > best:
					best = value
					choice = each
	return runner.resolve(choice, runner.crew_for_choice(choice))


## What a choice is worth to this player, in hundredths of Mawjig: the average over its outcomes.
func _choice_value(runner: EventRunner, choice: Dictionary) -> float:
	var run := runner.run
	var total := 0.0
	var weights := 0.0
	var strength := _squad_strength(run)
	for outcome in choice.get("outcomes", []):
		var value := 0.0
		for effect in outcome.effects:
			var attrs: Dictionary = effect.attrs
			match String(effect.tag):
				"mawjig":
					if attrs.has("size"):
						value += SIZE_VALUE.get(attrs.size, 600) * run.band_adjustment()
					else:
						value += float(attrs.get("amount", "0")) * 100.0
				"fight":
					value += (700.0 if strength > 0.6 else -1500.0) * run.band_adjustment()
				"crew":
					value += 1200.0 if _ship_short_of_crew(run) else 300.0
				"crew_hurt":
					value -= 300.0
				"ship":
					value += 9000.0 - float(attrs.get("pay", "0")) * 100.0
				"renew_contract":
					value += 2500.0
				"weapon", "upgrade":
					value += 1000.0
				"hull":
					value += float(attrs.get("amount", "0")) * 48.0
				"system_damage":
					value -= 400.0
				"store":
					value += 200.0
				"xp", "reveal":
					value += 100.0
		var weight := float(outcome.get("weight", 1))
		total += value * weight
		weights += weight
	var value := total / maxf(1.0, weights)
	if runner.is_blue(choice):
		value += 150.0
	if run.mawjig + minf(0.0, value) < Mawjig.JUMP_COST * 3:
		value -= 5000.0     # never pay down to where the squad can't jump
	return value


func _squad_strength(run: RunState) -> float:
	var hull := 0.0
	var full := 0.0
	for ship in run.living_ships():
		hull += ship.hull
		full += ship.max_hull
	return hull / maxf(1.0, full)


func _ship_short_of_crew(run: RunState) -> bool:
	return run.living_ships().any(func(ship: Ship): return ship.living_crew_count() < 4)


# --- Fights ---------------------------------------------------------------------------------------------------

func _fight(run: RunState, runner: EventRunner, squad: SquadDef) -> String:
	var enemies := runner.build_enemy_ships(squad)
	var encounter := Encounter.new()
	encounter.wallet = run
	encounter.squad = squad
	encounter.setup(run.living_ships(), enemies, run.jumps)
	_last = encounter
	var captains := {}
	for ship in encounter.living(0):
		var captain := ShipAI.new(ship, encounter)
		captain.fixed_target = player.focus
		captain.careless = skill == "careless"
		if skill != "careless":
			captain.preferred_targets = ["weapons", "shields", "piloting", "engines"]
		captains[ship] = captain
	var ticks := 0
	var enemy_left := INF
	var progress_at := 0
	while encounter.outcome.is_empty() and ticks < FIGHT_LIMIT:
		if ticks % 20 == 0:
			# A fight that isn't getting anywhere: a player stops pouring shots into it and jumps on
			var left := 0.0
			for enemy in encounter.living(1):
				left += enemy.hull + 3.0 * enemy.living_crew_count()
			if left < enemy_left:
				enemy_left = left
				progress_at = ticks
			if ticks - progress_at > 20 * int(player.gives_up_after) and encounter.can_squad_jump() and run.mawjig >= Mawjig.JUMP_COST:
				return _leave(run, encounter, "stalemate")
		if ticks % int(player.think_every) == 0:
			var focus := _focus(encounter)
			for ship in encounter.living(0):
				if captains.has(ship):
					if player.focus:
						captains[ship].target = focus
					captains[ship].think()
			if _losing(encounter) and encounter.can_squad_jump() and run.mawjig >= Mawjig.JUMP_COST:
				return _leave(run, encounter, "fled")
		for note in encounter.notes:
			if note.kind == "surrender_offer":
				for enemy in encounter.living(1):
					enemy.surrendered = true
		encounter.notes.clear()
		encounter.step()
		ticks += 1
	if encounter.outcome.is_empty():
		return _leave(run, encounter, "stalemate")
	return encounter.outcome


## The enemy ship the whole squad shoots. The watcher takes the one that looks weakest; the expert the one that
## does the most harm for how long it will take to kill.
func _focus(encounter: Encounter) -> Ship:
	var best: Ship = null
	var best_score := -INF
	for enemy in encounter.living(1):
		var toughness := float(enemy.hull + enemy.shield_layers * 4 + enemy.supershield * 2)
		var score := -toughness
		if skill == "expert":
			var harm := 0.2
			for slot in enemy.weapons:
				if slot.powered:
					harm += float(slot.def.shots * maxi(1, slot.def.damage)) / maxf(1.0, slot.def.charge_ticks / 20.0)
			score = harm / maxf(1.0, toughness)
		if score > best_score:
			best_score = score
			best = enemy
	return best


func _losing(encounter: Encounter) -> bool:
	var ours := 0.0
	var ours_full := 0.0
	for ship in encounter.living(0):
		ours += ship.hull
		ours_full += ship.max_hull
	var theirs := 0.0
	var theirs_full := 0.0
	for ship in encounter.enemy_ships():
		theirs += maxi(0, ship.hull) if not ship.is_gone() else 0
		theirs_full += ship.max_hull
	return ours / maxf(1.0, ours_full) < float(player.flee_below) and theirs / maxf(1.0, theirs_full) > 0.35


func _leave(run: RunState, encounter: Encounter, how: String) -> String:
	run.count_mercenary_crew()
	encounter.leave_behind_away_crew()
	return how


# --- The store ------------------------------------------------------------------------------------------------

func _price_scale(run: RunState) -> float:
	var states: Array = run.cluster().states
	if states.has("Doomed"):
		return 1.3
	return 1.12 if states.has("Struggling") or states.has("Occupied") else 1.0


func _shop(run: RunState) -> void:
	Refit.ensure_stock(run)
	var stock: Dictionary = run.cluster().store_stock
	var scale := _price_scale(run)
	var reserve := Mawjig.JUMP_COST * int(player.reserve)
	# Hull first
	var per_point := Refit.repair_price(run)
	var wanted := 0
	for ship in run.living_ships():
		wanted += maxi(0, int(ship.max_hull * float(player.repair_to)) - ship.hull)
	var points := mini(wanted, maxi(0, (run.mawjig - reserve) / per_point))
	if points > 0:
		Refit.apply(run, {"op": "repair", "points": points})
	if player.shop == "odd":
		# The careless player buys one thing, whatever comes up first
		for ship in run.living_ships():
			var wishes := _wish_list(ship, run)
			if not wishes.is_empty():
				var want: Dictionary = wishes[run.rng.randi_range(0, wishes.size() - 1)]
				if int(want.price) > 0 and run.mawjig - int(want.price) >= reserve:
					_buy_wish(run, ship, want)
				return
		return
	# Another ship, when the store has one and the squad can pay
	if stock.ship != "" and not stock.sold.has("ship"):
		var design := Library.ship(stock.ship)
		var price := Refit.ship_price(run, design, scale)
		if run.mawjig - price >= reserve:
			Refit.apply(run, {"op": "buy_ship", "id": stock.ship, "price": price})
	var ships: Array[Ship] = run.living_ships().filter(func(ship: Ship): return not ship.is_mercenary())
	# A medbay for a ship without one, and crew for a ship with fewer than four
	for ship in ships:
		var index := run.squad.find(ship)
		if ship.system_by("medbay") == null and stock.systems.has("medbay") and not stock.sold.has("system:medbay"):
			var def := Library.system("medbay")
			var price := Mawjig.amount(def.buy_price * scale / 100.0)
			var room := ShipOutfitter.room_for_new_system(ship, def)
			if room >= 0 and run.mawjig - price >= reserve:
				Refit.apply(run, {"op": "buy_system", "sq": index, "id": "medbay", "room": room, "price": price})
		for slot in stock.crew.size():
			if ship.living_crew_count() >= (6 if player.shop == "all" else 4) or stock.sold.has("crew:%d" % slot):
				continue
			var race := Library.race(stock.crew[slot])
			var price := Mawjig.amount(race.crew_price * scale / 100.0)
			if run.mawjig - price >= reserve:
				Refit.apply(run, {"op": "buy_crew", "sq": index, "race": race.id, "index": slot, "price": price})
	# Then, ship by ship, the upgrade a player would want most that the squad can pay for, until nothing fits
	var bought := true
	while bought:
		bought = false
		for ship in ships:
			var index := run.squad.find(ship)
			for want in _wish_list(ship, run):
				var price: int = want.price
				if price <= 0 or run.mawjig - price < reserve:
					continue
				_buy_wish(run, ship, want)
				bought = true
				break
	# A weapon for a ship with a free mount and the power to fire it
	for ship in ships:
		var index := run.squad.find(ship)
		var weapons_system := ship.system_by("weapons")
		if weapons_system == null or ShipOutfitter.free_mounts(ship).is_empty():
			continue
		var load := 0
		for slot in ship.weapons:
			load += slot.def.power
		for id in stock.weapons:
			var def := Library.weapon(id)
			var price := Mawjig.amount(def.price * scale / 100.0)
			if def == null or stock.sold.has("weapon:" + id) or def.defensive or load + def.power > weapons_system.level:
				continue
			if run.mawjig - price >= reserve:
				Refit.apply(run, {"op": "buy_weapon", "sq": index, "id": id, "price": price})
				break


func _buy_wish(run: RunState, ship: Ship, want: Dictionary) -> void:
	var index := run.squad.find(ship)
	if want.kind == "system":
		Refit.apply(run, {"op": "upgrade_system", "sq": index, "sys": ship.systems.find(want.system)})
	else:
		Refit.apply(run, {"op": "upgrade_reactor", "sq": index})


## What a ship's owner wants next, most wanted first: a second shield layer, a reactor that can feed everything,
## weapons power for the weapons fitted, then engines and more shields.
func _wish_list(ship: Ship, run: RunState) -> Array:
	var wishes: Array = []
	var shields := ship.system_by("shields")
	var engines := ship.system_by("engines")
	var weapons_system := ship.system_by("weapons")
	var draw := 0
	for system in ship.systems:
		if system.def.draws_power:
			draw += system.level
	if ship.reactor_type == "pool" and ship.reactor_total() < draw:
		wishes.append({"kind": "reactor", "price": ShipOutfitter.reactor_upgrade_price(ship)})
	if shields and shields.level < 4:
		wishes.append({"kind": "system", "system": shields, "price": ShipOutfitter.system_upgrade_price(shields)})
	if weapons_system:
		var load := 0
		for slot in ship.weapons:
			load += slot.def.power
		if weapons_system.level < load:
			wishes.append({"kind": "system", "system": weapons_system, "price": ShipOutfitter.system_upgrade_price(weapons_system)})
	var all: bool = player.shop == "all"
	if engines and engines.level < (5 if all else 2 + run.band() / 2):
		wishes.append({"kind": "system", "system": engines, "price": ShipOutfitter.system_upgrade_price(engines)})
	if shields and shields.level < (8 if all else mini(8, 2 + 2 * ((run.band() + 1) / 2))):
		wishes.append({"kind": "system", "system": shields, "price": ShipOutfitter.system_upgrade_price(shields)})
	if weapons_system and weapons_system.level < (weapons_system.def.max_level if all and not ShipOutfitter.free_mounts(ship).is_empty() else 2 + run.band() / 2):
		wishes.append({"kind": "system", "system": weapons_system, "price": ShipOutfitter.system_upgrade_price(weapons_system)})
	if ship.reactor_type == "core" and ship.core_load() >= ship.core_capacity():
		wishes.append({"kind": "reactor", "price": ShipOutfitter.reactor_upgrade_price(ship)})
	return wishes


# --- The map --------------------------------------------------------------------------------------------------

## Jumps to the next cluster; false when the squad can't jump (it waits). The careless player always heads straight out.
## The others look around while the collapse is far behind: an unvisited cluster nearby before one farther out.
func _travel(run: RunState) -> bool:
	if run.mawjig < Mawjig.JUMP_COST:
		return false
	var here: Dictionary = run.cluster()
	var outward := -1
	var sideways := -1
	for link in here.links:
		if not run.can_jump_to(link):
			continue
		var there: Dictionary = run.galaxy.clusters[link]
		if outward < 0 or there.radius > run.galaxy.clusters[outward].radius:
			outward = link
		var keeps_ahead: bool = run.galaxy.collapse_radius <= 0.0 or there.radius - run.galaxy.collapse_radius - Galaxy.COLLAPSE_STEP > SAFE_GAP
		if not there.visited and keeps_ahead and there.kind != "final" and (sideways < 0 or there.radius < run.galaxy.clusters[sideways].radius):
			sideways = link
	var hurt := _squad_strength(run) < 0.6
	var pick := outward
	if player.explore and sideways >= 0 and run.mawjig >= Mawjig.JUMP_COST * 4:
		pick = sideways
		if hurt:
			# Hurt: a store within reach comes first
			for link in here.links:
				if run.can_jump_to(link) and run.galaxy.clusters[link].store and not run.galaxy.clusters[link].visited:
					pick = link
	if pick < 0:
		return false
	run.jump_to(pick)
	return true
