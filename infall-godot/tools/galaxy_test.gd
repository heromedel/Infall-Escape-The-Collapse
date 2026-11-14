extends Node
## Builds galaxies and checks them: size, time, every cluster reachable from the start, the rim, names, and that
## a save rebuilds the same map. Run: godot --headless --path . tools/galaxy_test.tscn


func _ready() -> void:
	var failures := 0
	for seed_number in [1, 2, 3]:
		var started := Time.get_ticks_msec()
		var galaxy := Galaxy.generate(seed_number, 8)
		var took := Time.get_ticks_msec() - started
		var rim := 0
		var longest := 0.0
		var races := {}
		var names := {}
		for cluster in galaxy.clusters:
			if cluster.kind == "final":
				rim += 1
			races[cluster.race] = races.get(cluster.race, 0) + 1
			names[cluster.name] = true
			for other in cluster.links:
				var length: float = cluster.position.distance_to(galaxy.clusters[other].position)
				longest = maxf(longest, length)
				if length > 450.0 and OS.get_environment("LONG") != "":
					print("  long link %.0f from radius %.0f to %.0f" % [length, cluster.radius, galaxy.clusters[other].radius])
		var reached := {}
		galaxy._flood(galaxy.start_index, reached)
		# How far outward a squad could go without leaving its home race's space
		var home := {galaxy.start_index: true}
		var queue: Array = [galaxy.start_index]
		var farthest := 0.0
		while not queue.is_empty():
			var at: int = queue.pop_back()
			farthest = maxf(farthest, galaxy.clusters[at].radius)
			for other in galaxy.clusters[at].links:
				if not home.has(other) and galaxy.clusters[other].race == galaxy.home_race:
					home[other] = true
					queue.append(other)
		print("  home-race-only reach: %d clusters, %.1f bands outward" % [home.size(), (farthest - Galaxy.START_RADIUS) / Galaxy.BAND_DEPTH])
		var start: Dictionary = galaxy.clusters[galaxy.start_index]
		print("seed %d: %d clusters in %d ms, rim %d, reachable %d, longest link %.0f, unique names %d, start radius %.0f (%s), races %s" % [seed_number, galaxy.clusters.size(), took, rim, reached.size(), longest, names.size(), start.radius, start.race, races])
		if reached.size() != galaxy.clusters.size() or names.size() != galaxy.clusters.size() or rim == 0 or start.race != galaxy.home_race:
			failures += 1
		# Heading straight inward for the opening jumps never reaches the first horizon
		if start.radius - (Galaxy.OPENING_JUMPS - 1) * Galaxy.LINK_RANGE <= Galaxy.FIRST_COLLAPSE:
			failures += 1
		galaxy.clusters[5].visited = true
		galaxy.clusters[7].store_stock = {"weapons": ["fang"]}
		started = Time.get_ticks_msec()
		var copy := Galaxy.from_save(JSON.parse_string(JSON.stringify(galaxy.to_save())))
		var same: bool = copy.clusters.size() == galaxy.clusters.size() and copy.clusters[100].name == galaxy.clusters[100].name and copy.clusters[5].visited and copy.clusters[7].store_stock.has("weapons")
		print("  reload %d ms, same map: %s" % [Time.get_ticks_msec() - started, same])
		if not same:
			failures += 1
	failures += _check_people_and_situations()
	print("PASS" if failures == 0 else "FAIL (%d)" % failures)
	get_tree().quit()


## Populations (GV 2J) and events from the situation (GV 2I).
func _check_people_and_situations() -> int:
	var failed := 0
	var run := RunState.start(11, "outrider")
	var galaxy := run.galaxy
	var checks: Array = []
	checks.append(["no cluster is flagged hostile in advance", galaxy.clusters.all(func(c): return c.kind in ["open", "store", "hazard", "final", "opening"])])
	checks.append(["every race's cluster has people", galaxy.clusters.all(func(c): return c.race == "" or Populations.total(c.settled) > 0.0)])
	checks.append(["nobody is on the road before the collapse", galaxy.clusters.all(func(c): return c.on_road.is_empty())])
	var before := 0.0
	for cluster in galaxy.clusters:
		before += Populations.total(cluster.settled)
	for jump in range(4, 64):
		galaxy.advance_collapse(jump)
	var after := 0.0
	var on_road := 0.0
	var refugee := 0
	var too_many_left := 0
	var inward := 0
	for cluster in galaxy.clusters:
		after += Populations.total(cluster.settled) + Populations.total(cluster.on_road)
		on_road += Populations.total(cluster.on_road)
		refugee += 1 if cluster.states.has("Refugee") else 0
		var started: float = cluster.home
		# A large settled population gets a tenth of itself moving at most (the note); others may have settled here since
		if not cluster.states.has("Swallowed") and started >= 100.0 and float(cluster.settled.get(cluster.race, 0.0)) < started * 0.899:
			too_many_left += 1
		if not cluster.on_road.is_empty() and float(cluster.radius) < galaxy.collapse_radius and not cluster.states.has("Swallowed"):
			inward += 1
	checks.append(["people take to the road as the collapse grows: %s in %d Refugee clusters" % [Populations.words(on_road), refugee], on_road > 100.0 and refugee > 0])
	checks.append(["people are lost with the clusters they could not leave, and never made", after < before])
	checks.append(["a large settled population gets a tenth of itself moving at most", too_many_left == 0])
	checks.append(["nobody is left behind the collapse", inward == 0])
	# What the squad meets: a Terran squad's chance of a hostile arrival, by who holds the cluster
	var threat := {}
	for cluster in galaxy.clusters:
		if cluster.states.has("Doing Fine") and not cluster.states.has("Refugee") and not cluster.states.has("At War") and cluster.kind == "open" and int(cluster.band) == 6:
			var holder := Situations.holder_of(cluster)
			if not threat.has(holder):
				threat[holder] = Situations.threat(run, cluster)
	print("  a %s squad's chance of a hostile arrival in band 6, where things are fine: %s" % [galaxy.home_race, str(threat.keys().map(func(k): return "%s %d%%" % [k, int(round(100.0 * threat[k]))]))])
	if threat.has("malphen") and threat.has("mecha") and threat.has("terran"):
		checks.append(["Malphen space is the most dangerous, the squad's own the least", threat.malphen > threat.mecha and threat.mecha > threat.terran])
	var somewhere: Dictionary = galaxy.clusters.filter(func(c): return c.race == "mecha" and not c.states.has("Swallowed"))[0]
	var calm := Situations.threat(run, somewhere)
	run.preyed["mecha"] = 3
	checks.append(["preying on a race's ships is remembered in its space", Situations.threat(run, somewhere) > calm])
	var copy := Galaxy.from_save(JSON.parse_string(JSON.stringify(galaxy.to_save())))
	var same := true
	for index in galaxy.clusters.size():
		if Populations.total(galaxy.clusters[index].on_road) != Populations.total(copy.clusters[index].on_road) or galaxy.clusters[index].states != copy.clusters[index].states or galaxy.clusters[index].refugees != copy.clusters[index].refugees:
			same = false
	checks.append(["a save keeps the people and the states", same])
	for check in checks:
		print("  %s  %s" % ["ok  " if check[1] else "FAIL", check[0]])
		failed += 0 if check[1] else 1
	return failed
