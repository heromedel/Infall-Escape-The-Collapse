class_name Alliance
extends RefCounted
## The Alliance victory (content/alliance/alliance.xml, GV 2G): races pledge to a convoy of colony ships. A pledge is
## won in a talk, an ALLIANCE_ event of that race, met in its space, among its refugees or at its stores. With
## enough races pledged, those races' ships fight beside the squad at the rim against the ones that refused.

static var races: Array[String] = []
static var ally: Dictionary = {}       # race -> the design it sends to the rim, or ""
static var foe: Dictionary = {}        # race -> the design it fields if it refused
static var needed: int = 4
static var talk_one_in: int = 3        # a talk comes up on one arrival in this many, in a race's space


static func load_from(node: XmlTree) -> void:
	races.clear()
	ally.clear()
	foe.clear()
	needed = node.get_int("needed", 4)
	talk_one_in = maxi(1, node.get_int("talk_one_in", 3))
	for child in node.all("race"):
		var id := child.get_attr("id")
		races.append(id)
		ally[id] = child.get_attr("ally", "")
		foe[id] = child.get_attr("foe", child.get_attr("ally", ""))


static func talk_event(race: String) -> String:
	return "ALLIANCE_" + race.to_upper()


## The race whose pledge can be asked for at a cluster, or "": the race that holds it, or whose refugees are there,
## when the convoy has been proposed and that race has not pledged.
static func race_to_ask(run: RunState, cluster: Dictionary) -> String:
	if not run.alliance_goal:
		return ""
	for race in [String(cluster.get("occupier", "")), String(cluster.race), String(cluster.get("refugees", ""))]:
		if races.has(race) and not run.has_pledge(race) and Library.events.has(talk_event(race)):
			return race
	return ""


## The enemy at the rim: a ship from each race that never pledged, the strongest four of them.
static func refusers(run: RunState) -> Array[String]:
	var designs: Array[String] = []
	for race in races:
		if not run.has_pledge(race) and String(foe.get(race, "")) != "":
			designs.append(foe[race])
	designs.sort_custom(func(a, b): return Library.ship(a).value > Library.ship(b).value)
	return designs.slice(0, 4)


## One line for each race still to win, with a pointer to where it is (for the map).
static func lines(run: RunState) -> PackedStringArray:
	var out: PackedStringArray = []
	var pledged: Array = races.filter(func(race): return run.has_pledge(race))
	out.append("The convoy: %d of %d races pledged (%s)." % [pledged.size(), needed, ", ".join(pledged.map(func(race): return Library.race(race).name))])
	if run.alliance_ready():
		out.append("Enough have pledged. Head for the rim; more allies mean fewer enemies there.")
	for race in races:
		if run.has_pledge(race):
			continue
		var name: String = Library.race(race).name
		var direction := RimTech.direction_to(run, race)
		if direction == "":
			out.append("%s: their space is gone. Look for their refugees and ships." % name)
		elif direction == "here":
			out.append("%s: you are in their space. Ask at their stores, or keep travelling here." % name)
		else:
			out.append("%s: their nearest space lies %s of you." % [name, direction])
	return out
