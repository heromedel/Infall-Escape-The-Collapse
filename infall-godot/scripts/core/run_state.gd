class_name RunState
extends RefCounted
## One run: the seed, the galaxy and where the squad is in it, the squad's ships and their shared Mawjig pool
## (GDD 4E), spare weapons, what has happened, and the run's log. Saved as hand-readable JSON text with the
## seed (coding rule 11).

const SAVE_PATH := "user://saves/run.json"
const START_MAWJIG := 12.11

var seed_value: int = 0
var rng := RandomNumberGenerator.new()
var galaxy: Galaxy
var current: int = 0
var jumps: int = 0
var mawjig: int = 1211
var squad: Array[Ship] = []
var cargo: Array[String] = []        # weapons carried but not fitted
var used_events: Array[String] = []
var stats := {"ships_destroyed": 0, "crews_killed": 0, "jumps": 0, "mawjig_earned": 0, "events": 0, "ships_lost": 0}
var over: bool = false
var won: bool = false
var difficulty: String = "Normal"
var next_contract_id: int = 1
var pending_fight: String = ""      # the squad being fought, if the run was saved mid-fight
var log_book: LogBook


static func start(seed_number: int, ship_id: String) -> RunState:
	var run := RunState.new()
	run.seed_value = seed_number
	run.rng.seed = seed_number
	run.difficulty = Settings.get_value("difficulty", "Normal")
	var band_count := 4 if Settings.get_value("run_length", "Standard") == "Short" else 8
	run.galaxy = Galaxy.generate(seed_number, band_count, Library.ship(ship_id).race)
	run.current = run.galaxy.start_index
	run.galaxy.clusters[run.current].visited = true
	run.mawjig = Mawjig.amount(START_MAWJIG + (6.03 if run.difficulty == "Easy" else 0.0))
	var ship := Ship.from_design(Library.ship(ship_id), 0, run.rng, Settings.get_value("terran_conduits", true))
	run.squad.append(ship)
	run.log_book = LogBook.open_for_run(seed_number)
	run.log_book.write("run_started", {"seed": seed_number, "ship": ship_id, "bands": band_count}, "A new run begins with the %s. Seed %d." % [ship.name, seed_number])
	return run


# --- The squad's pool -----------------------------------------------------------------------------------------

## Pays from the squad's pool. Returns false, and pays nothing, when there isn't enough.
func spend(cents: int) -> bool:
	if cents > mawjig:
		return false
	mawjig -= cents
	return true


func earn(cents: int) -> void:
	mawjig += cents
	if cents > 0:
		stats.mawjig_earned += cents


func living_ships() -> Array[Ship]:
	var list: Array[Ship] = []
	for ship in squad:
		if not ship.is_gone():
			list.append(ship)
	return list


## Removes ships that were lost, so the squad only holds what still flies.
func clear_lost_ships() -> void:
	var kept: Array[Ship] = []
	for ship in squad:
		if ship.is_gone():
			stats.ships_lost += 1
			log_book.write("ship_lost", {"ship": ship.name}, "The %s is gone." % ship.name)
		else:
			kept.append(ship)
	squad = kept


# --- The map --------------------------------------------------------------------------------------------------

func cluster() -> Dictionary:
	return galaxy.clusters[current]


func band() -> int:
	return int(cluster().band)


## The reward multiplier by band (GDD 8I): x1.0 in band 1 up to x1.7 in band 8.
func band_adjustment() -> float:
	return 1.0 + 0.1 * (band() - 1)


func can_jump_to(index: int) -> bool:
	return cluster().links.has(index) and not galaxy.is_swallowed(index)


func jump_to(index: int) -> void:
	mawjig -= Mawjig.JUMP_COST
	var from := current
	current = index
	jumps += 1
	stats.jumps += 1
	galaxy.advance_collapse(jumps)
	_count_contract_jump()
	var arrived: Dictionary = cluster()
	arrived.visited = true
	log_book.write("jump", {"from": from, "to": index, "band": arrived.band, "mawjig": mawjig, "collapse": int(galaxy.collapse_radius)},
			"Jumped to %s (band %d). Mawjig left: %s." % [arrived.name, arrived.band, Mawjig.format(mawjig)])


## Waiting gathers 0.25 Mawjig for the whole squad while the collapse moves on (GDD 6B).
func wait() -> void:
	earn(Mawjig.WAIT_GAIN)
	jumps += 1
	galaxy.advance_collapse(jumps)
	_count_contract_jump()
	log_book.write("wait", {"cluster": current, "mawjig": mawjig}, "The squad waited at %s and gathered 0.25 Mawjig." % cluster().name)


# --- Mercenaries (GV 7C) --------------------------------------------------------------------------------------

## Each renewal costs a quarter more than the term before (Ai-Generated-Proposal: "a price that rises each time").
const RENEWAL_RISE := 1.25


## The squad's own ships: mercenaries fly with it but don't keep a run alive (GDD 7G).
func own_ships() -> Array[Ship]:
	return living_ships().filter(func(ship: Ship): return not ship.is_mercenary())


## Signs a ship on as a mercenary for some jumps, having been paid `pay` cents; its crew are on the contract too.
func hire(ship: Ship, jumps_long: int, pay: int) -> void:
	ship.contract = {"id": next_contract_id, "jumps": jumps_long, "jumps_left": jumps_long, "pay": pay, "crew_at_start": ship.crew.size()}
	next_contract_id += 1
	for member in ship.crew:
		member.contract_id = ship.contract.id
	log_book.write("hired_ship", {"ship": ship.name, "jumps": jumps_long, "pay": pay}, "The %s signed on for %d jumps." % [ship.name, jumps_long])


func renewal_price(ship: Ship) -> int:
	return roundi(int(ship.contract.get("pay", 0)) * RENEWAL_RISE)


func renew(ship: Ship) -> void:
	var price := renewal_price(ship)
	mawjig -= price
	ship.contract.pay = price
	ship.contract.jumps_left = ship.contract.jumps
	log_book.write("renewed", {"ship": ship.name, "pay": price}, "The %s's contract was renewed." % ship.name)


## Mercenary ships whose contract has run out.
func contracts_due() -> Array[Ship]:
	return living_ships().filter(func(ship: Ship): return ship.is_mercenary() and int(ship.contract.jumps_left) <= 0)


## Mercenary ships that lost any of their own crew in the last fight.
func mercenaries_with_losses() -> Array[Ship]:
	return living_ships().filter(func(ship: Ship): return ship.is_mercenary() and _contract_crew(ship).size() < int(ship.contract.crew_at_start))


## Called as a fight starts, so losses can be told apart from crew who left earlier.
func count_mercenary_crew() -> void:
	for ship in living_ships():
		if ship.is_mercenary():
			ship.contract.crew_at_start = _contract_crew(ship).size()


## The mercenaries leave: their ship, and their crew wherever they are. Anyone of yours aboard comes back first.
func release(ship: Ship) -> void:
	var id := int(ship.contract.id)
	var others := own_ships()
	for member in ship.crew.duplicate():
		if member.contract_id != id and not member.dead and not others.is_empty():
			ship.crew.erase(member)
			var fewest: Ship = others[0]
			for other in others:
				if other.crew.size() < fewest.crew.size():
					fewest = other
			fewest.add_crew(member)
			fewest.assign_stations()
	for other in living_ships():
		if other != ship:
			for member in other.crew.duplicate():
				if member.contract_id == id:
					other.crew.erase(member)
	squad.erase(ship)
	log_book.write("released", {"ship": ship.name}, "The %s left the squad." % ship.name)


func _contract_crew(ship: Ship) -> Array:
	var found: Array = []
	for each in living_ships():
		for member in each.crew:
			if member.contract_id == int(ship.contract.id) and not member.dead:
				found.append(member)
	return found


func _count_contract_jump() -> void:
	for ship in living_ships():
		if ship.is_mercenary():
			ship.contract.jumps_left = int(ship.contract.jumps_left) - 1


func collapse_distance() -> float:
	if galaxy.collapse_radius <= 0.0:
		return INF
	return float(cluster().radius) - galaxy.collapse_radius


## How close the collapse is, 0 far to 1 at the horizon, for the backdrop's glow.
func collapse_nearness() -> float:
	var distance := collapse_distance()
	if distance == INF:
		return 0.0 if jumps < 2 else 0.1 * jumps
	return clampf(1.0 - distance / 900.0, 0.1, 1.0)


func sensor_range() -> int:
	var best := 0
	for ship in living_ships():
		var sensors := ship.system_by("sensors")
		if sensors:
			best = maxi(best, sensors.usable_bars())
	return best


# --- Saving ---------------------------------------------------------------------------------------------------

func to_save() -> Dictionary:
	var ships: Array = []
	for ship in squad:
		if not ship.is_gone():
			ships.append(ship.to_save())
	return {
		"game": "Infall: Escape The Collapse", "version": 2, "seed": seed_value, "current": current, "jumps": jumps,
		"mawjig": mawjig, "cargo": cargo.duplicate(), "used_events": used_events.duplicate(), "stats": stats.duplicate(),
		"difficulty": difficulty, "pending_fight": pending_fight, "next_contract_id": next_contract_id, "squad": ships, "galaxy": galaxy.to_save(), "rng_state": rng.state,
	}


func save_to_disk() -> void:
	if over:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(to_save(), "\t"))


static func has_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return typeof(data) == TYPE_DICTIONARY and int(data.get("galaxy", {}).get("version", 1)) >= 2


static func load_from_disk() -> RunState:
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY or int(data.get("galaxy", {}).get("version", 1)) < 2:
		return null   # unreadable, or from a build with the old map
	var run := RunState.new()
	run.seed_value = int(data.seed)
	run.rng.seed = run.seed_value
	run.rng.state = int(data.get("rng_state", 0))
	run.current = int(data.current)
	run.jumps = int(data.jumps)
	run.mawjig = int(data.mawjig)
	run.cargo.assign(data.get("cargo", []))
	run.used_events.assign(data.get("used_events", []))
	for key in data.get("stats", {}):
		run.stats[key] = int(data.stats[key])
	run.difficulty = data.get("difficulty", "Normal")
	run.pending_fight = data.get("pending_fight", "")
	run.next_contract_id = int(data.get("next_contract_id", 1))
	run.galaxy = Galaxy.from_save(data.galaxy)
	for ship_data in data.squad:
		run.squad.append(Ship.from_save(ship_data, 0))
	run.log_book = LogBook.open_for_run(run.seed_value)
	run.log_book.write("run_loaded", {"seed": run.seed_value}, "The run was loaded from its save.")
	return run


## Writes what happened in a fight to the run's log (coding rule 10: a machine line and a readable line).
func log_note(note: Dictionary) -> void:
	if log_book == null:
		return
	var ship: Ship = note.get("ship") if note.get("ship") is Ship else null
	var ship_name := ship.name if ship else ""
	match note.kind:
		"hit":
			log_book.write("hit", {"ship": ship_name, "room": note.room, "damage": note.damage}, "%s took a hit for %d damage." % [ship_name, note.damage])
		"ship_destroyed":
			log_book.write("ship_destroyed", {"ship": ship_name}, "%s was destroyed." % ship_name)
		"crew_died":
			var member: CrewMember = note.crew
			log_book.write("crew_died", {"crew": member.name, "race": member.race.id}, "%s died." % member.name)
		"fight_over":
			log_book.write("fight_over", {"outcome": note.outcome}, "The fight ended: %s." % note.outcome)
		"skill_up":
			var member: CrewMember = note.crew
			log_book.write("skill_up", {"crew": member.name, "skill": note.skill}, "%s improved at %s." % [member.name, note.skill])
