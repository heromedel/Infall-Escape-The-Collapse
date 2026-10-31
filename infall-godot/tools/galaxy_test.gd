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
		var start: Dictionary = galaxy.clusters[galaxy.start_index]
		print("seed %d: %d clusters in %d ms, rim %d, reachable %d, longest link %.0f, unique names %d, start radius %.0f (%s), races %s" % [seed_number, galaxy.clusters.size(), took, rim, reached.size(), longest, names.size(), start.radius, start.race, races])
		if reached.size() != galaxy.clusters.size() or names.size() != galaxy.clusters.size() or rim == 0 or start.race != "terran":
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
	print("PASS" if failures == 0 else "FAIL (%d)" % failures)
	get_tree().quit()
