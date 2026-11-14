extends Node
## Checks ShipValue against Infall: Eco's reference values (economy-findings.md, F13) and prints every ship's parts.
## Run: godot --headless --path . tools/ship_value_test.tscn

const ECO := {"polyp": 173.56, "pirate-scrapper": 238.55, "relay-picket": 304.88, "spawnling": 267.43, "vein-moth": 286.12, "moth-skiff": 289.01, "packrunner": 328.39, "light-attack-frame": 338.15, "patrol-cutter": 368.41, "tentauri-scout": 393.79, "sporecarrier": 435.47, "outrider": 420.11, "tentauri-warden": 463.77, "assault-frame": 470.21, "pirate-hijacker": 474.23}   # Eco, revised 2026-11-14; changed since by the same rule: the Hijacker less a door, the docs' Relay Picket, the Sporecarrier with its gland


func _ready() -> void:
	var worst := 0.0
	for id in ECO:
		var design: ShipDesign = Library.ship(id)
		var ours := ShipValue.of(design) / 100.0
		var off: float = ours - ECO[id]
		worst = maxf(worst, absf(off))
		var with_system := 0
		for room_index in design.rooms.size():
			if design.systems.any(func(sys): return sys.room == room_index):
				with_system += 1
		print("  hull %d rooms %d (%d) doors %d mounts listed %d weapons %d reactor %s %d" % [design.hull, design.rooms.size(), with_system, design.doors.size(), design.mounts_listed, design.weapons.size(), design.reactor_type, design.reactor_level])
		print("%-20s ours %7.2f  Eco %7.2f  off %+7.2f   structure %6.2f reactor %6.2f systems %6.2f weapons %6.2f" % [id, ours, ECO[id], off, ShipValue.structure(design) / 100.0, ShipValue.reactor(design) / 100.0, ShipValue.systems(design) / 100.0, ShipValue.weapons(design) / 100.0])
	# Within 0.05: both sides round each part to a hundredth
	print("PASS" if worst < 0.05 else "FAIL: off by up to %.2f" % worst)
	get_tree().quit()
