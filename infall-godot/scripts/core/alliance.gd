class_name Alliance
extends RefCounted
## The Alliance victory (content/alliance/alliance.xml, GV 2G): races pledge to a convoy of colony ships. A pledge is
## won in a talk, an ALLIANCE_ event of that race, met in its space, among its refugees or at its stores. With
## enough races pledged, those races' ships fight beside the squad at the rim against the ones that refused.

static var races: Array[String] = []
static var ally: Dictionary = {}       # race -> the design it sends to the rim, or ""
static var needed: int = 4
static var talk_one_in: int = 3        # a talk comes up on one arrival in this many, in a race's space


static func load_from(node: XmlTree) -> void:
	races.clear()
	ally.clear()
	needed = node.get_int("needed", 4)
	talk_one_in = maxi(1, node.get_int("talk_one_in", 3))
	for child in node.all("race"):
		var id := child.get_attr("id")
		races.append(id)
		ally[id] = child.get_attr("ally", "")


## The talk a race gives at a cluster. A race may have several, split by the cluster's state (the Mecha doing well
## refuse; doomed Senti fight): the one that names the fewest states and fits wins, then the race's plain talk.
static func talk_event(race: String, cluster: Dictionary = {}) -> String:
	var plain := "ALLIANCE_" + race.to_upper()
	var best := ""
	var fewest := 99
	for id in Library.events:
		var def: EventDef = Library.events[id]
		if not String(id).begins_with(plain) or def.kind != "alliance" or def.states.is_empty():
			continue
		for state in cluster.get("states", []):
			if def.states.has(state) and def.states.size() < fewest:
				best = id
				fewest = def.states.size()
	return best if best != "" else plain


## The race whose pledge can be asked for at a cluster, or "": the race that holds it, or whose refugees are there,
## when the convoy has been proposed and that race has not pledged.
static func race_to_ask(run: RunState, cluster: Dictionary) -> String:
	if not run.alliance_goal:
		return ""
	for race in [String(cluster.get("occupier", "")), String(cluster.race), String(cluster.get("refugees", ""))]:
		if races.has(race) and not run.has_pledge(race) and Library.events.has(talk_event(race, cluster)):
			return race
	return ""


## One line for each people still to win, with a pointer to where it is (for the map; Infall: Lori's lines).
static func lines(run: RunState) -> PackedStringArray:
	var out: PackedStringArray = []
	var pledged: Array = races.filter(func(race): return run.has_pledge(race))
	out.append("The convoy: %d of %d peoples pledged (%s)." % [pledged.size(), needed, ", ".join(pledged.map(func(race): return Library.race(race).name))])
	if run.alliance_ready():
		out.append("Every people has pledged. Head for the rim.")
	else:
		out.append("Ask a people at one of their stores, or meet them in their space.")
	for race in races:
		var name: String = Library.race(race).name
		if run.has_pledge(race):
			continue
		if race == "malphen" and not _has_gland(run):
			out.append("Malphen: they cannot be spoken to. A Pheromone Gland or a Lymph Gland might reach them.")
			continue
		var direction := RimTech.direction_to(run, race)
		if direction == "":
			out.append("%s: their space is gone. Look for their refugees and ships." % name)
		elif race == "mecha" and _all_seen_doing_well(run, race):
			out.append("Mecha: doing too well to leave. Look for them where they are struggling.")
		elif race == "senti" and run.cluster().race == race and run.cluster().states.has("Doomed"):
			out.append("Senti: their archive is behind their guns, and it will want everything you carry.")
		elif direction == "here":
			out.append("%s: you are in their space." % name)
		else:
			out.append("%s: their nearest space lies %s of you." % [name, direction])
	return out


static func _has_gland(run: RunState) -> bool:
	for ship in run.living_ships():
		if ship.system_by_id("pheromone-gland") or ship.system_by_id("lymph-gland"):
			return true
	return false


## Whether every cluster of a race the squad has seen is neither Struggling nor Doomed.
static func _all_seen_doing_well(run: RunState, race: String) -> bool:
	for cluster in run.galaxy.clusters:
		if cluster.race == race and cluster.get("seen", false) and (cluster.states.has("Struggling") or cluster.states.has("Doomed")):
			return false
	return true
