class_name Situations
extends RefCounted
## Events come from the situation (GDD 9D; content/situations/situations.xml): what the squad finds at a cluster gives
## each kind of event a weight. Who holds the cluster and how the squad's race stands with them, the cluster's states,
## people on the road, the squad's reputation there, and the band.

const KINDS := ["hostile", "distress", "neutral", "items", "nothing"]

static var base: Dictionary = {}
static var holders: Array = []       # {race, states, weights}
static var own: Array = []           # {states, weights}
static var states: Dictionary = {}   # state -> weights
static var pairs: Array = []         # {squad, holder, states, weights, hard}
static var pressure: Dictionary = {}
static var pressure_cap: float = 2.0
static var preyed_step: float = 0.15
static var preyed_cap: float = 2.0
static var pledged: float = 0.5
static var band_step: float = 0.03


static func load_from(node: XmlTree) -> void:
	holders.clear()
	own.clear()
	states.clear()
	pairs.clear()
	base = _weights(node.first("base"))
	for child in node.all("holder"):
		holders.append({"race": child.get_attr("race"), "states": child.get_attr("states", "").split(",", false), "weights": _weights(child)})
	for child in node.all("own"):
		own.append({"states": child.get_attr("states", "").split(",", false), "weights": _weights(child)})
	for child in node.all("state"):
		states[child.get_attr("name")] = _weights(child)
	for child in node.all("pair"):
		pairs.append({"squad": child.get_attr("squad"), "holder": child.get_attr("holder"), "states": child.get_attr("states", "").split(",", false),
				"weights": _weights(child), "hard": child.get_bool("hard", false)})
	var pressure_node := node.first("pressure")
	if pressure_node:
		pressure = _weights(pressure_node)
		pressure_cap = pressure_node.get_float("cap", 2.0)
	var reputation := node.first("reputation")
	if reputation:
		preyed_step = reputation.get_float("preyed", 0.15)
		preyed_cap = reputation.get_float("cap", 2.0)
		pledged = reputation.get_float("pledged", 0.5)
	var band := node.first("band")
	if band:
		band_step = band.get_float("hostile", 0.03)
	var people := node.first("populations")
	if people:
		Populations.load_from(people)


static func _weights(node: XmlTree) -> Dictionary:
	var weights := {}
	if node:
		for kind in KINDS:
			if node.attributes.has(kind):
				weights[kind] = node.get_float(kind, 1.0)
	return weights


## The race that holds a cluster now: its occupier, or its own; "none" for space nobody holds.
static func holder_of(cluster: Dictionary) -> String:
	if cluster.states.has("Abandoned"):
		return "none"
	var race: String = cluster.occupier if String(cluster.get("occupier", "")) != "" else cluster.race
	return race if race != "" else "none"


static func _in_states(wanted: Array, cluster: Dictionary) -> bool:
	if wanted.is_empty():
		return true
	for state in wanted:
		if cluster.states.has(state):
			return true
	return false


## Every line of the file that applies at a cluster, as [what it is, its weights]: for the game, and for anyone
## who wants to see why a cluster is as dangerous as it is.
static func reasons(run: RunState, cluster: Dictionary) -> Array:
	var found: Array = [["base", base]]
	var holder := holder_of(cluster)
	var squad_race: String = run.galaxy.home_race
	for line in holders:
		if line.race == holder and _in_states(line.states, cluster):
			found.append(["held by %s%s" % [holder, "" if line.states.is_empty() else " (%s)" % ", ".join(line.states)], line.weights])
	if holder == squad_race:
		for line in own:
			if _in_states(line.states, cluster):
				found.append(["the squad's own people", line.weights])
	for state in cluster.states:
		if states.has(state):
			found.append([state, states[state]])
	for line in pairs:
		if line.squad == squad_race and line.holder == holder and _in_states(line.states, cluster):
			found.append(["%s squad in %s space" % [squad_race, holder], line.weights])
	var pushed := minf(pressure_cap, Populations.pressure(cluster))
	if pushed > 0.01:
		var by := {}
		for kind in pressure:
			by[kind] = 1.0 + float(pressure[kind]) * pushed
		found.append(["people on the road (pressure %.2f)" % pushed, by])
	var kills := int(run.preyed.get(holder, 0))
	if kills > 0:
		found.append(["preyed on their ships (%d)" % kills, {"hostile": minf(preyed_cap, 1.0 + preyed_step * kills)}])
	if holder != squad_race and run.has_pledge(holder):
		found.append(["pledged to the convoy", {"hostile": pledged}])
	found.append(["band %d" % int(cluster.band), {"hostile": 1.0 + band_step * (int(cluster.band) - 1)}])
	return found


## The weight of each kind of event at a cluster.
static func kind_weights(run: RunState, cluster: Dictionary) -> Dictionary:
	var weights := {}
	for kind in KINDS:
		weights[kind] = 1.0
	for reason in reasons(run, cluster):
		for kind in reason[1]:
			weights[kind] *= float(reason[1][kind])
	return weights


## Whether a fight here is a hard one (a pair marked hard): the enemy comes as if a band farther out.
static func hard_here(run: RunState, cluster: Dictionary) -> bool:
	var holder := holder_of(cluster)
	for line in pairs:
		if line.hard and line.squad == run.galaxy.home_race and line.holder == holder and _in_states(line.states, cluster):
			return true
	return false


## The chance, 0 to 1, that an arrival here is a hostile event.
static func threat(run: RunState, cluster: Dictionary) -> float:
	var weights := kind_weights(run, cluster)
	var total := 0.0
	for kind in KINDS:
		total += float(weights[kind])
	return float(weights.hostile) / maxf(0.001, total)
