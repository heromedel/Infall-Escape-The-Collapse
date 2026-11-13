extends Node
## Checks ShipValue against Infall: Eco's reference values (economy-findings.md, F13) and prints every ship's parts.
## Run: godot --headless --path . tools/ship_value_test.tscn

const ECO := {"pirate-scrapper": 240.97, "spawnling": 260.77, "relay-picket": 266.01, "moth-skiff": 288.41, "packrunner": 328.39, "light-attack-frame": 338.15, "patrol-cutter": 346.62, "tentauri-scout": 364.27, "sporecarrier": 411.29, "outrider": 421.44, "tentauri-warden": 424.81, "assault-frame": 470.21, "pirate-hijacker": 477.14}


func _ready() -> void:
	var worst := 0.0
	for id in ECO:
		var design: ShipDesign = Library.ship(id)
		var ours := ShipValue.of(design) / 100.0
		var off: float = ours - ECO[id]
		# F13 priced the Supershield at 19.36 with no upgrades (now 38.72, 7.26, 12.11) and the growth organ at its
		# 6.05 placeholder (now a clone bay's 12.11: Eco, 2026-11-13), so ships with either are off by those amounts
		if not design.systems.any(func(sys): return sys.id in ["supershield", "growth-organ"]):
			worst = maxf(worst, absf(off))
		var with_system := 0
		for room_index in design.rooms.size():
			if design.systems.any(func(sys): return sys.room == room_index):
				with_system += 1
		print("  hull %d rooms %d (%d) doors %d mounts listed %d weapons %d reactor %s %d" % [design.hull, design.rooms.size(), with_system, design.doors.size(), design.mounts_listed, design.weapons.size(), design.reactor_type, design.reactor_level])
		print("%-20s ours %7.2f  Eco %7.2f  off %+7.2f   structure %6.2f reactor %6.2f systems %6.2f weapons %6.2f" % [id, ours, ECO[id], off, ShipValue.structure(design) / 100.0, ShipValue.reactor(design) / 100.0, ShipValue.systems(design) / 100.0, ShipValue.weapons(design) / 100.0])
	# Within 2.5: F13 counted a room's first listed system and some shields rooms at half a layer; the shared rule
	# (Eco, 2026-10-31) is the dearest system, shields at one layer, which moves those ships by 1.8 to 2.42
	print("PASS" if worst < 2.5 else "FAIL: off by up to %.2f" % worst)
	get_tree().quit()
