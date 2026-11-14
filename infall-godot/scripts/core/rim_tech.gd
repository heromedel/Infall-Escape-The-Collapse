class_name RimTech
extends RefCounted
## The Tech victory's pieces (content/tech/tech.xml, GV 2F). heromedel, 2026-11-14: goals, not destinations. Each is
## a race's own version of a real system: it counts on any ship of the squad that has that system in that race's
## make, or in the squad's hold. A piece comes from any of that race's ships (salvaged, taken, demanded in a
## surrender), its stores or its events.

static var pieces: Dictionary = {}     # race id -> {race, name, line, system, price_share, sold, surrendered}
static var order: Array[String] = []   # race ids in the file's order
static var base_price: int = 3631      # cents, before the band adjustment
static var goal_bands_from_rim: int = 2
static var demand_band: int = 6
static var steal_chance: float = 0.2
static var steal_chance_late: float = 0.33
static var late_band: int = 6
static var wreck_chance: float = 0.1
static var own_crew: int = 6           # genetic diversity: this many crew of the squad's own race aboard the one ship
static var own_crew_pair: String = "Record"


static func load_from(node: XmlTree) -> void:
	pieces.clear()
	order.clear()
	base_price = Mawjig.amount(node.get_float("price", 36.31))
	goal_bands_from_rim = node.get_int("goal_bands_from_rim", 2)
	demand_band = node.get_int("demand_band", 6)
	steal_chance = node.get_float("steal_chance", 0.2)
	steal_chance_late = node.get_float("steal_chance_late", steal_chance)
	late_band = node.get_int("late_band", 6)
	wreck_chance = node.get_float("wreck_chance", 0.1)
	own_crew = node.get_int("own_crew", 6)
	own_crew_pair = node.get_attr("own_crew_pair", "Record")
	for child in node.all("piece"):
		var race := child.get_attr("race")
		pieces[race] = {
			"race": race, "name": child.get_attr("name", race), "line": child.get_clean_text(),
			"system": child.get_attr("system", ""), "pair": child.get_attr("pair", race),
			"price_share": child.get_float("price_share", 1.0),
			"sold": child.get_attr("sold", "yes") == "yes", "surrendered": child.get_attr("surrendered", "yes") == "yes",
		}
		order.append(race)


static func name_of(race: String) -> String:
	return pieces[race].name if pieces.has(race) else race


## What the one ship must carry (GV 2F): by the setting, one piece of each pair (docs/ideas.md: power core or clone
## bay, engine or autopilot, shield or reinforcements, archive or genetic diversity), or all seven pieces.
## Each entry: {name, races, own_crew}; own_crew is how many of the squad's own race aboard also fill it, or 0.
static func groups() -> Array:
	var list: Array = []
	if Settings.get_value("tech_pieces", "One of Each Pair") == "All Seven":
		for race in order:
			list.append({"name": name_of(race), "races": [race], "own_crew": 0})
		return list
	var by_pair := {}
	for race in order:
		var pair: String = pieces[race].pair
		if not by_pair.has(pair):
			by_pair[pair] = {"name": pair, "races": [], "own_crew": own_crew if pair == own_crew_pair else 0}
			list.append(by_pair[pair])
		by_pair[pair].races.append(race)
	return list


## Whether a system is a race's piece: that race's own make of the system the piece is.
static func is_piece(system: ShipSystem, race: String) -> bool:
	return pieces.has(race) and system.def.id == String(pieces[race].system) and system.make == race


## The piece a store in this cluster sells, or "": a store in a race's own space sells that race's piece.
static func sold_at(cluster: Dictionary) -> String:
	var race: String = cluster.race
	if not pieces.has(race) or not pieces[race].sold or cluster.get("occupier", "") != "":
		return ""
	return race


## What a race's piece costs in a band, in cents: a core system's price times the band adjustment (Infall: Eco), and
## the race's own share of that (the Mecha part with theirs only for a good deal).
static func price(race: String, band: int, share: float = 1.0) -> int:
	if not pieces.has(race):
		return 0
	return Mawjig.no_trailing_zero(int(round(base_price * (1.0 + 0.1 * (band - 1)) * float(pieces[race].price_share) * share)))


static func steal_chance_in(band: int) -> float:
	return steal_chance_late if band >= late_band else steal_chance


## The race a TECH_ event is about ("TECH_SENTI" -> "senti"), or "" for any other event.
static func race_of_event(id: String) -> String:
	if not id.begins_with("TECH_"):
		return ""
	var race := id.trim_prefix("TECH_").to_lower()
	return race if pieces.has(race) else ""


const COMPASS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

## Where the nearest space of a race lies from the squad, as the map shows it ("north-west"), or "" when the
## collapse has taken all of it.
static func direction_to(run: RunState, race: String) -> String:
	var here: Vector2 = run.cluster().position
	var best := INF
	var toward := Vector2.ZERO
	for index in run.galaxy.clusters.size():
		var cluster: Dictionary = run.galaxy.clusters[index]
		if cluster.race != race or cluster.kind == "final" or run.galaxy.is_swallowed(index):
			continue
		var distance: float = here.distance_squared_to(cluster.position)
		if distance < best:
			best = distance
			toward = cluster.position - here
	if best == INF:
		return ""
	if best < 1.0:
		return "here"
	return COMPASS[posmod(int(round(toward.angle() / (TAU / 8.0))), 8)]


static func _with_article(name: String) -> String:
	if name.ends_with("s"):
		return name       # "Azurethea Engines" takes no article
	return ("an " if name.left(1).to_lower() in ["a", "e", "i", "o", "u"] else "a ") + name


## The state of the search (Infall: Lori's format): the ship, then a line for each thing it must carry, "{need}:
## {options}." and whether that is fitted, in the hold or on another ship, or missing, with a pointer to that
## race's space.
static func missing_lines(run: RunState) -> PackedStringArray:
	var lines: PackedStringArray = []
	var ship := run.crossing_ship()
	if ship == null:
		return lines
	if run.has_all_tech():
		lines.append("Everything the crossing needs is fitted to the %s. Head for the rim." % ship.name)
		return lines
	lines.append("To make the crossing, one ship needs these fitted:")
	var fitted := run.tech_on(ship)
	for group in groups():
		var options: PackedStringArray = []
		for race in group.races:
			options.append(_with_article(name_of(race)))
		if int(group.own_crew) > 0:
			options.append("%d of your own people aboard" % int(group.own_crew))
		var need := "%s: %s." % [group.name, " or ".join(options)] if group.races.size() > 1 or int(group.own_crew) > 0 else "%s." % name_of(group.races[0])
		if run.group_done_on(ship, group):
			lines.append("%s Fitted to the %s." % [need, ship.name])
			continue
		var have: Array = group.races.filter(func(race): return run.has_tech(race))
		if not have.is_empty():
			lines.append("%s %s. Fit it to the %s at a refit yard." % [need, "In the hold" if run.tech.has(have[0]) else "On another of your ships", ship.name])
			continue
		var ways: PackedStringArray = []
		for race in group.races:
			var race_name: String = Library.race(race).name
			var direction := direction_to(run, race)
			if direction == "":
				ways.append("%s space is gone: look for %s ships, refugees and mercenaries" % [race_name, race_name])
			elif direction == "here":
				ways.append("try %s ships, stores or space; you are in %s space now" % [race_name, race_name])
			else:
				ways.append("try %s ships, stores or space; the nearest %s region lies %s of you" % [race_name, race_name, direction])
		lines.append("%s Missing: %s." % [need, "; or ".join(ways)])
	return lines
