class_name Galaxy
extends RefCounted
## The open map of star clusters (GDD 2C, 2J): the whole galaxy, a disc of spiral arms around the collapsing
## core. The squad may head any way it likes except through the core; the run is won by reaching the rim
## anywhere. Clusters belong to race regions with deep, inner and border ranks (2K), change state as the
## collapse comes closer (2L, 2R), and every cluster links to at least one farther from the core (2F).
##
## Distances are map pixels. The core is at (0, 0).

const CORE_RADIUS := 700.0          # the core itself: nothing lies inside it
const BAND_DEPTH := 880.0           # one difficulty band (GDD 2H): about ten jumps outward
const MIN_SPACING := 100.0
const LINK_RANGE := 175.0
const COLLAPSE_STEP := 64.0          # how far the horizon grows per jump or wait (GDD 2S)
const OPENING_JUMPS := 5             # the collapse opening (GDD 2P)
const FIRST_COLLAPSE := CORE_RADIUS + 140.0
# The squad starts close enough to the core to head inward for a few jumps, but not so close that those jumps
# can reach the horizon when the collapse appears.
const START_RADIUS := FIRST_COLLAPSE + (OPENING_JUMPS - 1) * LINK_RANGE + 160.0
const RIM_DEPTH := 260.0             # the rim: the outermost ring of clusters; reaching any of them wins
const CLUSTER_AREA := 54000.0        # map area per cluster, on average
const ARMS := 4
const ARM_TWIST := 2.4               # how tightly the arms wind
const REGION_AREA := 960000.0        # map area per race region, on average
const REGION_RACES := {"terran": 34, "mecha": 18, "azurethea": 12, "tentauri": 10, "senti": 9, "lykario": 9, "malphen": 8}

var seed_value: int = 0
var bands: int = 8
var clusters: Array = []             # see _new_cluster
var regions: Array = []              # {race, centre, size}
var collapse_radius: float = 0.0     # 0 until the core collapses
var start_index: int = 0
var _grid := {}                      # grid cell -> cluster indices, for finding neighbours fast


static func generate(seed_number: int, band_count: int) -> Galaxy:
	var galaxy := Galaxy.new()
	galaxy.seed_value = seed_number
	galaxy.bands = band_count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_number
	galaxy._place_clusters(rng)
	galaxy._link_clusters(rng)
	galaxy._place_regions(rng)
	galaxy._assign_regions()
	galaxy._assign_contents(rng)
	galaxy.update_states(0)
	return galaxy


func outer_radius() -> float:
	return START_RADIUS + bands * BAND_DEPTH


func rim_radius() -> float:
	return outer_radius() - RIM_DEPTH


func band_at(radius: float) -> int:
	return clampi(int((radius - START_RADIUS) / BAND_DEPTH) + 1, 1, bands)


func is_rim(index: int) -> bool:
	return clusters[index].kind == "final"


## How strongly the spiral arms gather clusters at a point, 0.5 between arms to 1 along one.
static func arm_density(point: Vector2) -> float:
	var radius := maxf(point.length(), 1.0)
	var phase := ARMS * (point.angle() - ARM_TWIST * log(radius / CORE_RADIUS))
	var along := 0.5 + 0.5 * cos(phase)
	return 0.5 + 0.5 * along * along


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
	var target := int(PI * (outer * outer - CORE_RADIUS * CORE_RADIUS) / CLUSTER_AREA)
	# The start: in GATOS space at a random heading from the core
	var start_angle := rng.randf() * TAU
	_add_cluster(_new_cluster(Vector2.from_angle(start_angle) * START_RADIUS, rng))
	var attempts := 0
	while clusters.size() < target and attempts < target * 30:
		attempts += 1
		var radius := sqrt(rng.randf_range(pow(CORE_RADIUS + 40.0, 2), pow(outer, 2)))
		var point := Vector2.from_angle(rng.randf() * TAU) * radius
		if rng.randf() > arm_density(point):
			continue
		if not _crowded(point):
			_add_cluster(_new_cluster(point, rng))
	start_index = 0
	var used := {}
	for index in clusters.size():
		clusters[index].name = _cluster_name(rng, used)


func _add_cluster(cluster: Dictionary) -> void:
	clusters.append(cluster)
	var cell := _grid_cell(cluster.position)
	if not _grid.has(cell):
		_grid[cell] = []
	_grid[cell].append(clusters.size() - 1)


func _crowded(point: Vector2) -> bool:
	var cell := _grid_cell(point)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for other in _grid.get(cell + Vector2i(dx, dy), []):
				if clusters[other].position.distance_to(point) < MIN_SPACING:
					return true
	return false


func _grid_cell(point: Vector2) -> Vector2i:
	return Vector2i(floor(point / MIN_SPACING))


## The clusters in the grid cells within `rings` cells of a point.
func _near(point: Vector2, rings: int) -> Array:
	var found: Array = []
	var cell := _grid_cell(point)
	for dx in range(-rings, rings + 1):
		for dy in range(-rings, rings + 1):
			found.append_array(_grid.get(cell + Vector2i(dx, dy), []))
	return found


func _link_clusters(rng: RandomNumberGenerator) -> void:
	var rings := int(ceil(LINK_RANGE / MIN_SPACING))
	for a in clusters.size():
		for b in _near(clusters[a].position, rings):
			if b > a and clusters[a].position.distance_to(clusters[b].position) <= LINK_RANGE and rng.randf() < 0.82:
				_link(a, b)
	# A lonely cluster between the arms links to its nearest neighbours
	for index in clusters.size():
		var tries := 0
		while clusters[index].links.size() < 2 and tries < 2:
			tries += 1
			var best := _nearest(clusters[index].position, func(other: int): return not clusters[index].links.has(other), 3)
			if best >= 0:
				_link(index, best)
	# No dead ends (GDD 2F): every cluster short of the rim reaches at least one farther from the core
	var rim := rim_radius()
	for index in clusters.size():
		var cluster: Dictionary = clusters[index]
		if cluster.radius >= rim:
			continue
		var has_outward := false
		for other in cluster.links:
			if clusters[other].radius > cluster.radius:
				has_outward = true
				break
		if not has_outward:
			var best := _nearest(cluster.position, func(other: int): return clusters[other].radius > cluster.radius + 20.0, 5)
			if best >= 0:
				_link(index, best)
	_join_islands()


## The nearest cluster to a point that passes a test, searching up to `max_rings` grid cells out; -1 if none.
func _nearest(point: Vector2, test: Callable, max_rings: int = 12) -> int:
	var best := -1
	var best_distance := INF
	for rings in range(1, max_rings + 1):
		for other in _near(point, rings):
			var distance: float = clusters[other].position.distance_to(point)
			if distance < best_distance and distance > 0.0 and test.call(other):
				best_distance = distance
				best = other
		if best >= 0:
			return best
	return best


## Every cluster can be reached from the start: working out from the start, any island of clusters gets a link to
## the nearest reachable one.
func _join_islands() -> void:
	var reached := {}
	_flood(start_index, reached)
	var origin: Vector2 = clusters[start_index].position
	var order: Array = range(clusters.size())
	order.sort_custom(func(a, b): return clusters[a].position.distance_squared_to(origin) < clusters[b].position.distance_squared_to(origin))
	var waiting: Array = order
	while not waiting.is_empty():
		var still: Array = []
		for index in waiting:
			if reached.has(index):
				continue
			var best := _nearest(clusters[index].position, func(other: int): return reached.has(other), 6)
			if best >= 0:
				_link(index, best)
				_flood(index, reached)
			else:
				still.append(index)
		if still.size() == waiting.size():
			break
		waiting = still


func _flood(from: int, reached: Dictionary) -> void:
	var queue: Array = [from]
	reached[from] = true
	while not queue.is_empty():
		var at: int = queue.pop_back()
		for other in clusters[at].links:
			if not reached.has(other):
				reached[other] = true
				queue.append(other)


func _link(a: int, b: int) -> void:
	if a == b or clusters[a].links.has(b):
		return
	clusters[a].links.append(b)
	clusters[b].links.append(a)


func _place_regions(rng: RandomNumberGenerator) -> void:
	var total_weight := 0
	for race in REGION_RACES:
		total_weight += REGION_RACES[race]
	var outer := outer_radius()
	var count := int(PI * (outer * outer - CORE_RADIUS * CORE_RADIUS) / REGION_AREA)
	for index in count:
		var roll := rng.randi_range(1, total_weight)
		var race := "terran"
		for candidate in REGION_RACES:
			roll -= REGION_RACES[candidate]
			if roll <= 0:
				race = candidate
				break
		var centre := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf_range(pow(CORE_RADIUS, 2), pow(outer, 2)))
		if index == 0:
			race = "terran"   # the run starts in GATOS space (GDD 7C: a Terran start)
			centre = clusters[start_index].position * 1.04
		var size := {"terran": 1.25, "mecha": 1.15, "tentauri": 0.6, "senti": 0.7, "lykario": 0.65, "azurethea": 0.9, "malphen": 1.0}.get(race, 1.0) as float
		regions.append({"race": race, "centre": centre, "size": size})


func _assign_regions() -> void:
	const REGION_CELL := 1000.0
	var region_grid := {}
	for region_index in regions.size():
		var cell := Vector2i(floor(regions[region_index].centre / REGION_CELL))
		if not region_grid.has(cell):
			region_grid[cell] = []
		region_grid[cell].append(region_index)
	for index in clusters.size():
		var cluster: Dictionary = clusters[index]
		var best := -1
		var best_score := INF
		var second_score := INF
		var cell := Vector2i(floor(cluster.position / REGION_CELL))
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for region_index in region_grid.get(cell + Vector2i(dx, dy), []):
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
	var rim := rim_radius()
	for index in clusters.size():
		var cluster: Dictionary = clusters[index]
		if cluster.radius >= rim:
			cluster.kind = "final"   # the rim (Goal B): someone else wants out too
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
		collapse_radius = FIRST_COLLAPSE
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


func _cluster_name(rng: RandomNumberGenerator, used: Dictionary) -> String:
	var first := ["Vela", "Kesh", "Oru", "Tamsin", "Ilex", "Corvan", "Mira", "Halen", "Sorrel", "Brannoc", "Ystra", "Daro", "Penna", "Quill", "Ashar", "Lumen", "Teska", "Varro", "Nim", "Ostra", "Calder", "Ebon", "Rhosk", "Selva", "Tirin", "Umbra", "Wend", "Zephyr", "Antor", "Belisk",
		"Cassin", "Delve", "Esker", "Fennix", "Galen", "Harrow", "Isolde", "Jessamy", "Korrin", "Lyra", "Morrow", "Nadir", "Orrin", "Pallas", "Rook", "Sable", "Thane", "Ulla", "Veyra", "Wyth", "Yarrow", "Zarek", "Aubade", "Bryn", "Cindral", "Dunmere", "Elloch", "Fallow", "Gyre", "Hesper"]
	var second := ["Reach", "Drift", "Cluster", "Knot", "Gate", "Crossing", "Hollow", "Spindle", "Expanse", "Shoal", "Rest", "Narrows", "Verge", "Cradle", "Span", "Lattice", "Fold", "Spur",
		"Haven", "Wake", "Tangle", "Sweep", "Mire", "Scatter", "Weir", "Arc", "Bloom", "Ember", "Tide", "Coil"]
	var name := ""
	for attempt in 6:
		name = "%s %s" % [first[rng.randi_range(0, first.size() - 1)], second[rng.randi_range(0, second.size() - 1)]]
		if not used.has(name):
			break
	if used.has(name):
		var numeral := 2
		while used.has("%s %s" % [name, _numeral(numeral)]):
			numeral += 1
		name = "%s %s" % [name, _numeral(numeral)]
	used[name] = true
	return name


static func _numeral(value: int) -> String:
	var parts := [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
	var text := ""
	for part in parts:
		while value >= part[0]:
			text += part[1]
			value -= part[0]
	return text


## Saves only what a run changes; the map itself is rebuilt from its seed.
func to_save() -> Dictionary:
	var changed := {}
	for index in clusters.size():
		var cluster: Dictionary = clusters[index]
		if cluster.visited or cluster.seen or cluster.event_done or cluster.occupier != "" or not cluster.store_stock.is_empty() or (cluster.store and cluster.kind != "store"):
			changed[str(index)] = {"visited": cluster.visited, "seen": cluster.seen, "event_done": cluster.event_done, "occupier": cluster.occupier, "store": cluster.store, "store_stock": cluster.store_stock}
	return {"version": 2, "seed": seed_value, "bands": bands, "collapse_radius": collapse_radius, "changed": changed}


static func from_save(data: Dictionary) -> Galaxy:
	var galaxy := Galaxy.generate(int(data.seed), int(data.bands))   # the same seed builds the same map
	galaxy.collapse_radius = float(data.collapse_radius)
	for key in data.changed:
		var cluster: Dictionary = galaxy.clusters[int(key)]
		for field in data.changed[key]:
			cluster[field] = data.changed[key][field]
	galaxy.update_states(0)
	return galaxy
