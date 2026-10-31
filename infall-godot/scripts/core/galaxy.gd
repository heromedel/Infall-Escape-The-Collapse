class_name Galaxy
extends RefCounted
## The open map of star clusters (GDD 2C, 2J): a wedge of the galaxy from near the collapsing core out to the
## rim. Clusters belong to race regions with deep, inner and border ranks (2K), change state as the collapse
## comes closer (2L, 2R), and every cluster links to at least one farther from the core (2F).
##
## Distances are map pixels. The core is at (0, 0) and the rim is up the screen.

const CORE_RADIUS := 700.0          # where band 1 begins
const BAND_DEPTH := 880.0           # one difficulty band (GDD 2H): about ten jumps outward
const WEDGE_HALF_ANGLE := 0.42      # radians either side of straight up
const MIN_SPACING := 100.0
const LINK_RANGE := 175.0
const COLLAPSE_STEP := 64.0          # how far the horizon grows per jump or wait (GDD 2S)
const OPENING_JUMPS := 5             # the collapse opening (GDD 2P)
const REGION_RACES := {"terran": 34, "mecha": 18, "azurethea": 12, "tentauri": 10, "senti": 9, "lykario": 9, "malphen": 8}

var bands: int = 8
var clusters: Array = []             # see _new_cluster
var regions: Array = []              # {race, centre, size}
var collapse_radius: float = 0.0     # 0 until the core collapses
var start_index: int = 0
var exit_index: int = -1


static func generate(seed_value: int, band_count: int) -> Galaxy:
	var galaxy := Galaxy.new()
	galaxy.bands = band_count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	galaxy._place_clusters(rng)
	galaxy._link_clusters(rng)
	galaxy._place_regions(rng)
	galaxy._assign_regions()
	galaxy._assign_contents(rng)
	galaxy.update_states(0)
	return galaxy


func outer_radius() -> float:
	return CORE_RADIUS + bands * BAND_DEPTH


func band_at(radius: float) -> int:
	return clampi(int((radius - CORE_RADIUS) / BAND_DEPTH) + 1, 1, bands)


func _new_cluster(position: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	var stars: Array = []
	for index in rng.randi_range(3, 7):
		stars.append([rng.randf_range(-13, 13), rng.randf_range(-11, 11), rng.randf_range(1.2, 3.2)])
	return {
		"position": position, "radius": position.length(), "band": band_at(position.length()),
		"links": [], "race": "", "region": -1, "rank": "", "states": [], "kind": "nothing", "hazard": "",
		"visited": false, "seen": false, "seed": rng.randi(), "stars": stars, "store": false, "name": "",
		"occupier": "", "event_done": false, "store_stock": {},
	}


func _place_clusters(rng: RandomNumberGenerator) -> void:
	var outer := outer_radius()
	var attempts := 0
	var target := int(bands * 58)
	# The start: near the inner edge, straight up from the core
	clusters.append(_new_cluster(Vector2(0, -CORE_RADIUS - 60.0), rng))
	var grid := {}   # cell -> cluster positions, so each new point only checks its neighbours
	grid[_grid_cell(clusters[0].position)] = [clusters[0].position]
	while clusters.size() < target and attempts < target * 40:
		attempts += 1
		var radius := sqrt(rng.randf_range(pow(CORE_RADIUS, 2), pow(outer, 2)))
		var angle := -PI / 2 + rng.randf_range(-WEDGE_HALF_ANGLE, WEDGE_HALF_ANGLE) * (0.8 + 0.2 * radius / outer)
		var point := Vector2.from_angle(angle) * radius
		var cell := _grid_cell(point)
		var crowded := false
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for other in grid.get(cell + Vector2i(dx, dy), []):
					if other.distance_to(point) < MIN_SPACING:
						crowded = true
		if not crowded:
			clusters.append(_new_cluster(point, rng))
			if not grid.has(cell):
				grid[cell] = []
			grid[cell].append(point)
	# The exit: the rim, the last cluster before the edge of the galaxy (Goal B's outer rim cluster)
	var exit := _new_cluster(Vector2(0, -outer - 120.0), rng)
	exit.kind = "final"
	clusters.append(exit)
	exit_index = clusters.size() - 1
	start_index = 0
	for index in clusters.size():
		clusters[index].name = _cluster_name(rng)
	clusters[exit_index].name = "The Rim"


func _grid_cell(point: Vector2) -> Vector2i:
	return Vector2i(floor(point / MIN_SPACING))


func _link_clusters(rng: RandomNumberGenerator) -> void:
	for a in clusters.size():
		for b in range(a + 1, clusters.size()):
			var distance: float = clusters[a].position.distance_to(clusters[b].position)
			if distance <= LINK_RANGE and rng.randf() < 0.82:
				_link(a, b)
	# No dead ends (GDD 2F): every cluster reaches at least one farther from the core
	for index in clusters.size():
		if index == exit_index:
			continue
		var cluster: Dictionary = clusters[index]
		var has_outward := false
		for other in cluster.links:
			if clusters[other].radius > cluster.radius:
				has_outward = true
				break
		if not has_outward:
			var best := -1
			var best_distance := INF
			for other in clusters.size():
				if clusters[other].radius > cluster.radius + 20.0:
					var distance: float = clusters[other].position.distance_to(cluster.position)
					if distance < best_distance:
						best_distance = distance
						best = other
			if best >= 0:
				_link(index, best)
	# The rim links to the outermost clusters
	var outermost: Array = range(clusters.size())
	outermost.erase(exit_index)
	outermost.sort_custom(func(a, b): return clusters[a].radius > clusters[b].radius)
	for index in mini(4, outermost.size()):
		_link(exit_index, outermost[index])


func _link(a: int, b: int) -> void:
	if a == b or clusters[a].links.has(b):
		return
	clusters[a].links.append(b)
	clusters[b].links.append(a)


func _place_regions(rng: RandomNumberGenerator) -> void:
	var total_weight := 0
	for race in REGION_RACES:
		total_weight += REGION_RACES[race]
	var count := bands * 3 + 2
	for index in count:
		var roll := rng.randi_range(1, total_weight)
		var race := "terran"
		for candidate in REGION_RACES:
			roll -= REGION_RACES[candidate]
			if roll <= 0:
				race = candidate
				break
		if index == 0:
			race = "terran"   # the run starts in GATOS space (GDD 7C: a Terran start)
		var radius := CORE_RADIUS + (float(index) + rng.randf()) / count * bands * BAND_DEPTH
		var angle := -PI / 2 + rng.randf_range(-WEDGE_HALF_ANGLE, WEDGE_HALF_ANGLE)
		if index == 0:
			radius = CORE_RADIUS + 120.0
			angle = -PI / 2
		var size := {"terran": 1.25, "mecha": 1.15, "tentauri": 0.6, "senti": 0.7, "lykario": 0.65, "azurethea": 0.9, "malphen": 1.0}.get(race, 1.0) as float
		regions.append({"race": race, "centre": Vector2.from_angle(angle) * radius, "size": size})


func _assign_regions() -> void:
	for index in clusters.size():
		var cluster: Dictionary = clusters[index]
		var best := -1
		var best_score := INF
		var second_score := INF
		for region_index in regions.size():
			var region: Dictionary = regions[region_index]
			var score: float = cluster.position.distance_to(region.centre) / region.size
			if score < best_score:
				second_score = best_score
				best_score = score
				best = region_index
			elif score < second_score:
				second_score = score
		if best_score > 720.0:
			cluster.race = ""          # unclaimed or neutral, between regions (2K)
			cluster.rank = "neutral"
			continue
		cluster.region = best
		cluster.race = regions[best].race
		if best_score < 170.0:
			cluster.rank = "core"
		elif second_score - best_score < 90.0:
			cluster.rank = "border"
		else:
			cluster.rank = "inner"
	for cluster in clusters:
		if cluster.rank == "inner":
			for other in cluster.links:
				if clusters[other].race != cluster.race:
					cluster.rank = "border"
					break


func _assign_contents(rng: RandomNumberGenerator) -> void:
	for index in clusters.size():
		var cluster: Dictionary = clusters[index]
		if index == exit_index:
			continue
		if index == start_index:
			cluster.kind = "opening"
			continue
		var roll := rng.randf()
		var store_chance := 0.11 + (0.08 if cluster.race == "terran" and cluster.rank == "core" else 0.0)
		var hostile_chance := 0.5
		if roll < store_chance:
			cluster.kind = "store"
			cluster.store = true
		elif roll < store_chance + hostile_chance:
			cluster.kind = "hostile"
		elif roll < store_chance + hostile_chance + 0.11:
			cluster.kind = "distress"
		elif roll < store_chance + hostile_chance + 0.21:
			cluster.kind = "neutral"
		elif roll < store_chance + hostile_chance + 0.31:
			cluster.kind = "items"
		elif roll < store_chance + hostile_chance + 0.38:
			cluster.kind = "hazard"
			cluster.hazard = ["asteroids", "sun", "nebula", "ion_storm"][rng.randi_range(0, 3)]
		else:
			cluster.kind = "nothing"


## Recomputes every cluster's states from the collapse and the regions (GDD 2R). Called after every jump.
func update_states(jumps: int) -> void:
	for index in clusters.size():
		var cluster: Dictionary = clusters[index]
		var states: Array = []
		var distance: float = cluster.radius - collapse_radius
		if collapse_radius > 0.0 and distance <= 0.0:
			states.append("Swallowed")
		else:
			if cluster.race != "":
				if collapse_radius > 0.0 and distance < 230.0:
					states.append("Doomed")
				elif collapse_radius > 0.0 and distance < BAND_DEPTH:
					states.append("Struggling")
				else:
					states.append("Doing Fine")
				if cluster.rank == "core":
					states.append("Core")
				if cluster.rank == "border":
					states.append("Border")
				var roll := float(int(cluster.seed) % 1000) / 1000.0
				if (states.has("Struggling") or states.has("Doomed")) and cluster.race in ["terran", "azurethea", "tentauri"] and roll < 0.22:
					states.append("Refugee")
				if states.has("Doomed") and roll > 0.8:
					states.append("Abandoned")
				if cluster.occupier != "":
					states.append("Occupied")
			else:
				states.append("Abandoned" if collapse_radius > 0.0 and distance < BAND_DEPTH * 0.5 else "Unclaimed")
		cluster.states = states
	_spread_occupation()


## The Mecha flow into the weakest neighbouring clusters (race profiles, Mecha 8): a struggling border cluster
## next to Mecha space may be occupied.
func _spread_occupation() -> void:
	for cluster in clusters:
		if cluster.race == "" or cluster.race == "mecha" or cluster.occupier != "":
			continue
		if not cluster.states.has("Struggling") or not cluster.states.has("Border"):
			continue
		for other in cluster.links:
			if clusters[other].race == "mecha" and clusters[other].states.has("Doing Fine") and (int(cluster.seed) % 5) == 0:
				cluster.occupier = "mecha"
				cluster.states.append("Occupied")
				break


func advance_collapse(jumps: int) -> void:
	if jumps < OPENING_JUMPS - 1:
		return   # the fifth cluster of the run is where the collapse appears
	if collapse_radius <= 0.0:
		# Entire regions are swallowed at once (GDD 2P, the fifth message)
		collapse_radius = CORE_RADIUS + 140.0
	else:
		collapse_radius += COLLAPSE_STEP
	update_states(jumps)


func is_swallowed(index: int) -> bool:
	return clusters[index].states.has("Swallowed")


func region_name(cluster: Dictionary) -> String:
	if cluster.race == "":
		return "Unclaimed space"
	var race := Library.race(cluster.race)
	return "%s space" % race.name


func _cluster_name(rng: RandomNumberGenerator) -> String:
	var first := ["Vela", "Kesh", "Oru", "Tamsin", "Ilex", "Corvan", "Mira", "Halen", "Sorrel", "Brannoc", "Ystra", "Daro", "Penna", "Quill", "Ashar", "Lumen", "Teska", "Varro", "Nim", "Ostra", "Calder", "Ebon", "Rhosk", "Selva", "Tirin", "Umbra", "Wend", "Zephyr", "Antor", "Belisk"]
	var second := ["Reach", "Drift", "Cluster", "Knot", "Gate", "Crossing", "Hollow", "Spindle", "Expanse", "Shoal", "Rest", "Narrows", "Verge", "Cradle", "Span", "Lattice", "Fold", "Spur"]
	return "%s %s" % [first[rng.randi_range(0, first.size() - 1)], second[rng.randi_range(0, second.size() - 1)]]


func to_save() -> Dictionary:
	var saved_clusters: Array = []
	for cluster in clusters:
		var copy: Dictionary = cluster.duplicate(true)
		copy.position = [cluster.position.x, cluster.position.y]
		saved_clusters.append(copy)
	var saved_regions: Array = []
	for region in regions:
		saved_regions.append({"race": region.race, "centre": [region.centre.x, region.centre.y], "size": region.size})
	return {"bands": bands, "clusters": saved_clusters, "regions": saved_regions, "collapse_radius": collapse_radius, "start": start_index, "exit": exit_index}


static func from_save(data: Dictionary) -> Galaxy:
	var galaxy := Galaxy.new()
	galaxy.bands = int(data.bands)
	galaxy.collapse_radius = float(data.collapse_radius)
	galaxy.start_index = int(data.start)
	galaxy.exit_index = int(data.exit)
	for region in data.regions:
		galaxy.regions.append({"race": region.race, "centre": Vector2(region.centre[0], region.centre[1]), "size": float(region.size)})
	for cluster in data.clusters:
		var copy: Dictionary = cluster.duplicate(true)
		copy.position = Vector2(cluster.position[0], cluster.position[1])
		var links: Array = []
		for link in cluster.links:
			links.append(int(link))
		copy.links = links
		copy.band = int(copy.band)
		galaxy.clusters.append(copy)
	return galaxy
