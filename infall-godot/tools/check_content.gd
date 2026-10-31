extends Node
## Loads all content and prints what was found and any problems. Run: godot --headless --path . tools/check_content.tscn

func _ready() -> void:
	print("systems: ", Library.systems.size(), "  weapons: ", Library.weapons.size(), "  races: ", Library.races.size())
	print("ships: ", Library.ships.keys())
	for id in Library.ships:
		var d: ShipDesign = Library.ships[id]
		print("  %s rooms=%d doors=%d systems=%d conduits=%d mounts=%d weapons=%s crew=%d grid=%s" % [id, d.rooms.size(), d.doors.size(), d.systems.size(), d.conduits.size(), d.mounts.size(), str(d.weapons.map(func(w): return w.id)), d.crew.size(), str(d.grid_rect())])
	print("squads: ", Library.squads.size(), " events: ", Library.events.size())
	for p in Library.problems:
		print("PROBLEM: ", p)
	get_tree().quit()
