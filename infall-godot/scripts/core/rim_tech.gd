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
	for child in node.all("piece"):
		var race := child.get_attr("race")
		pieces[race] = {
			"race": race, "name": child.get_attr("name", race), "line": child.get_clean_text(),
			"system": child.get_attr("system", ""),
			"price_share": child.get_float("price_share", 1.0),
			"sold": child.get_attr("sold", "yes") == "yes", "surrendered": child.get_attr("surrendered", "yes") == "yes",
		}
		order.append(race)


static func name_of(race: String) -> String:
	return pieces[race].name if pieces.has(race) else race


## The kind of system a race's piece is ("engines", "supershield"...), or "" when the game has no such system.
static func behaviour_of(race: String) -> String:
	if not pieces.has(race):
		return ""
	var def := Library.system(pieces[race].system)
	return def.behaviour if def else ""


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


## One line for each piece the squad lacks, with a pointer to that race's space (Infall: Lori's lines).
static func missing_lines(run: RunState) -> PackedStringArray:
	var lines: PackedStringArray = []
	for race in run.missing_tech():
		var race_name: String = Library.race(race).name
		var direction := direction_to(run, race)
		if direction == "":
			lines.append("%s: %s space is gone. Look for %s ships, refugees and mercenaries instead." % [name_of(race), race_name, race_name])
		elif direction == "here":
			lines.append("%s: from %s ships, stores or space. You are in %s space now." % [name_of(race), race_name, race_name])
		else:
			lines.append("%s: from %s ships, stores or space. The nearest %s region lies %s of you." % [name_of(race), race_name, race_name, direction])
	if lines.is_empty():
		lines.append("All seven pieces are aboard. Head for the rim.")
	return lines
