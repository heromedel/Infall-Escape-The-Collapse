class_name Populations
extends RefCounted
## Cluster populations and their movement (docs/ideas.md, "Cluster populations and population movement", Proposed
## 2026-10-27; numbers in content/situations/situations.xml). Each cluster has people, counted in Gatillions (1,000
## Gatillion is 1 Gatzillion): those who live there (settled) and those passing through (on the road).
##
## It has three effects and no others (the note): numbers moving, with outcomes that are partly chance; the
## cluster's states (Refugee, and Struggling where the people passing through are more than it can carry); and the
## weights of the events met there (Situations).
##
## The rules: a race's people start to leave when the collapse is within that race's distance. A large settled
## population gets only a small share of itself moving; once on the road, people move on easily. They go outward,
## to their own people first. Among their own, where things are fine, they settle.

const GATZILLION := 1000.0
const LEAVING_STEPS := 6.0        # a settled population's share takes this many jumps to get on the road
const TOO_MANY := 0.5             # pressure over this and a cluster that was doing fine is Struggling

static var border: Dictionary = {}          # race -> Gatillions in a border cluster
static var moves_within: Dictionary = {}    # race -> bands from the collapse at which its people start to leave
static var minor_within: Dictionary = {}    # race -> bands at which a few leave already (the Tentauri)
static var rank_scale := {"border": 1.0, "inner": 2.5, "core": 5.0}
static var settled_share: float = 0.10
static var small: float = 30.0
static var small_share: float = 0.25


static func load_from(node: XmlTree) -> void:
	rank_scale = {"border": 1.0, "inner": node.get_float("inner", 2.5), "core": node.get_float("core", 5.0)}
	settled_share = node.get_float("settled_share", 0.10)
	small = node.get_float("small", 30.0)
	small_share = node.get_float("small_share", 0.25)
	for child in node.all("people"):
		var race := child.get_attr("race")
		border[race] = child.get_float("border", 50.0)
		moves_within[race] = child.get_float("moves_within", 1.0)
		if child.attributes.has("minor_within"):
			minor_within[race] = child.get_float("minor_within", 0.0)


## A number from 0 to 1 that is the same on every machine for the same cluster, jump and question.
static func _chance(cluster: Dictionary, jumps: int, salt: int) -> float:
	var mixed: int = (int(cluster.seed) * 73856093) ^ (jumps * 19349663) ^ (salt * 83492791)
	return float(posmod(mixed, 10007)) / 10007.0


## The people a cluster starts with: by its race and how deep in its region it lies, a third more or less.
static func home(cluster: Dictionary) -> float:
	if cluster.has("home"):
		return cluster.home
	var race: String = cluster.race
	if race == "" or not border.has(race):
		return 0.0
	var spread := 0.7 + 0.6 * _chance(cluster, 0, 1)
	return snappedf(float(border[race]) * float(rank_scale.get(cluster.rank, 1.0)) * spread, 0.1)


static func seed_galaxy(galaxy: Galaxy) -> void:
	var farthest := 0.0
	for race in moves_within:
		farthest = maxf(farthest, maxf(float(moves_within[race]), float(minor_within.get(race, 0.0))))
	galaxy.people_move_within = farthest
	for cluster in galaxy.clusters:
		cluster["home"] = home(cluster)
		cluster["settled"] = {cluster.race: cluster.home} if cluster.home > 0.0 else {}
		cluster["on_road"] = {}
	# The order people move in, the farthest out first, so nobody moves twice in a jump
	var order: Array = range(galaxy.clusters.size())
	order.sort_custom(func(a: int, b: int): return galaxy.clusters[a].radius > galaxy.clusters[b].radius)
	galaxy.outward_first = order


## The races of a count of people, always in the same order: a run loaded from a save, or sent to a machine that
## joins, must add them up and break ties exactly as the run that wrote it does.
static func _races(people: Dictionary) -> Array:
	var races: Array = people.keys()
	races.sort()
	return races


static func total(people: Dictionary) -> float:
	var sum := 0.0
	for race in _races(people):
		sum += float(people[race])
	return snappedf(sum, 0.1)


## The people on the road here who came from somewhere else, by race: everyone of another race, and of the
## cluster's own race those beyond what it could have sent out itself.
static func visitors(cluster: Dictionary) -> Dictionary:
	var from_elsewhere := {}
	var on_road: Dictionary = cluster.get("on_road", {})
	for race in _races(on_road):
		var group: float = float(on_road[race])
		if race == cluster.race:
			var started := home(cluster)
			group -= started * _share(started)
		if group >= 0.1:
			from_elsewhere[race] = group
	return from_elsewhere


## Those passing through over those who live there: 10 Gatillion arriving among 50 is 0.2, "quite a lot of pressure".
static func pressure(cluster: Dictionary) -> float:
	var passing := total(visitors(cluster))
	if passing <= 0.0:
		return 0.0
	return passing / maxf(5.0, total(cluster.get("settled", {})))


## The race with the most people passing through here, when there is a Gatillion of them or more; else "".
static func most_on_road(cluster: Dictionary) -> String:
	var best := ""
	var most := 1.0
	var passing := visitors(cluster)
	for race in _races(passing):
		if float(passing[race]) > most or (best == "" and float(passing[race]) >= most):
			most = float(passing[race])
			best = race
	return best


## The most of a settled population that takes to the road: a tenth of a large one, more of a small one.
static func _share(people: float) -> float:
	if people <= small:
		return small_share
	return lerpf(small_share, settled_share, clampf((people - small) / maxf(1.0, 100.0 - small), 0.0, 1.0))


## One jump's movement, after the collapse has grown and the states are known.
static func step(galaxy: Galaxy, jumps: int) -> void:
	if galaxy.collapse_radius <= 0.0:
		return
	# 1. Settled people take to the road
	for cluster in galaxy.clusters:
		if not cluster.has("settled"):
			continue
		if cluster.states.has("Swallowed"):
			cluster.settled = {}
			continue
		var bands_away: float = (float(cluster.radius) - galaxy.collapse_radius) / Galaxy.BAND_DEPTH
		if bands_away >= galaxy.people_move_within:
			continue      # too far from the collapse for anyone to think of leaving
		for race in _races(cluster.settled):
			var living: float = float(cluster.settled[race])
			var started: float = home(cluster) if race == cluster.race else living
			var most := started * _share(started)
			if bands_away >= float(moves_within.get(race, 1.0)):
				if bands_away >= float(minor_within.get(race, 0.0)):
					continue
				most *= 0.3      # a minor migration, well ahead of the collapse (the Tentauri)
			var gone := maxf(0.0, started - living)
			var leaving := minf(most - gone, most / LEAVING_STEPS)
			if leaving <= 0.05:
				continue
			cluster.settled[race] = snappedf(living - leaving, 0.1)
			cluster.on_road[race] = snappedf(float(cluster.on_road.get(race, 0.0)) + leaving, 0.1)
	# 2. People on the road move on, the farthest out first, so nobody moves twice in a jump
	for index in galaxy.outward_first:
		var here: Dictionary = galaxy.clusters[index]
		var on_road: Dictionary = here.on_road
		if on_road.is_empty():
			continue
		var gone_under: bool = here.states.has("Swallowed")
		var bands_away: float = (float(here.radius) - galaxy.collapse_radius) / Galaxy.BAND_DEPTH
		for race in _races(on_road):
			var group: float = float(on_road[race])
			var safe_here: bool = not gone_under and not here.states.has("Doomed") and not here.states.has("Struggling") and bands_away >= float(moves_within.get(race, 1.0))
			if safe_here:
				if here.race == race:      # among their own, where things are fine: they settle
					here.settled[race] = snappedf(float(here.settled.get(race, 0.0)) + group, 0.1)
					on_road.erase(race)
				continue
			var to := _way_on(galaxy, here, race, jumps)
			if to < 0:
				if gone_under:
					on_road.erase(race)     # they never got out
				continue
			# "Between 1 and all 10 Gatillion flee to still further clusters": half to all of them, by chance
			var moving: float = group if gone_under else snappedf(group * (0.5 + 0.5 * _chance(here, jumps, 7 + race.length())), 0.1)
			var there: Dictionary = galaxy.clusters[to]
			there.on_road[race] = snappedf(float(there.on_road.get(race, 0.0)) + moving, 0.1)
			if group - moving < 0.1:
				on_road.erase(race)
			else:
				on_road[race] = snappedf(group - moving, 0.1)
	for cluster in galaxy.clusters:
		cluster.refugees = "" if cluster.on_road.is_empty() else most_on_road(cluster)


## Where a group on the road goes next: outward, to its own people first, then anyone who isn't pushing into their
## neighbours, by chance among the ways open. -1 when there is no way on.
static func _way_on(galaxy: Galaxy, here: Dictionary, race: String, jumps: int) -> int:
	var options: Array = []
	var weights: Array = []
	for link in here.links:
		var there: Dictionary = galaxy.clusters[link]
		if there.states.has("Swallowed") or there.kind == "final" or float(there.radius) <= float(here.radius):
			continue
		var holder: String = there.occupier if String(there.occupier) != "" else there.race
		var weight := 1.0
		if holder == race:
			weight = 3.0
		elif holder in Galaxy.AGGRESSIVE_RACES:
			weight = 0.4
		elif holder != "":
			weight = 2.0
		options.append(link)
		weights.append(weight)
	if options.is_empty():
		return -1
	var sum := 0.0
	for weight in weights:
		sum += weight
	var roll := _chance(here, jumps, 3 + race.length() * 11) * sum
	for index in options.size():
		roll -= weights[index]
		if roll <= 0.0:
			return options[index]
	return options.back()


## A count of people as the map says it: "85 Gatillion", "1.2 Gatzillion".
static func words(people: float) -> String:
	if people >= GATZILLION:
		return "%.1f Gatzillion" % (people / GATZILLION)
	return ("%d Gatillion" % int(round(people))) if people >= 10.0 else ("%.1f Gatillion" % people)
