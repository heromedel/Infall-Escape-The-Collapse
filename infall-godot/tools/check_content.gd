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
	_check_species_words()
	get_tree().quit()


## Every {gatos:...} in the content must read as {gatos:Terran words|Tabby words}, and fill in both ways.
func _check_species_words() -> void:
	var dir := "res://content"
	var count := 0
	for path in _xml_files(dir):
		var text := FileAccess.get_file_as_string(path)
		var at := text.find("{gatos:")
		while at >= 0:
			var close := text.find("}", at)
			var part := text.substr(at, close - at + 1)
			if close < 0 or part.count("|") != 1:
				print("PROBLEM: %s: malformed %s" % [path, part])
			count += 1
			at = text.find("{gatos:", at + 1)
	var was: Variant = Settings.get_value("gatos_species")
	for species in ["Terrans", "Tabbys"]:
		Settings._values["gatos_species"] = species
		print("  %s: %s" % [species, Species.words("crammed in, {gatos:children|kittens} and all; {gatos:childishly|kittenishly}")])
	Settings._values["gatos_species"] = was
	print("species words: ", count)


func _xml_files(dir: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".xml"):
			found.append(dir + "/" + file)
	for sub in DirAccess.get_directories_at(dir):
		found.append_array(_xml_files(dir + "/" + sub))
	return found
