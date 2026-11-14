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
	_check_docks()
	_check_species_words()
	_check_events()
	get_tree().quit()


## Every event's requirements, effects and references must be ones the game knows: a misspelt requirement is always
## met, and a fight with a squad that isn't there picks a random one.
const REQUIREMENTS := ["crew", "system", "mawjig", "hire", "weapon", "squad", "collapse", "renewal", "tech", "no_tech", "pledged", "not_pledged",
		"pledges", "state", "not_state", "crew_with", "afford_tech"]
const EFFECTS := ["mawjig", "hull", "repair", "crew", "crew_hurt", "crew_lose", "weapon", "system_damage", "upgrade", "ship", "renew_contract",
		"end_contract", "tech", "alliance_goal", "pledge", "tech_goal", "fight", "store", "event", "reveal", "xp", "vector_goal", "vector_trail", "vector_part"]
const STATES := ["Doing Fine", "Struggling", "Doomed", "Refugee", "Core", "Border", "Occupied", "At War", "Abandoned", "Unclaimed", "Collapsing"]

func _check_events() -> void:
	var choices := 0
	for id in Library.events:
		var def: EventDef = Library.events[id]
		for state in def.states:
			if not STATES.has(state):
				print("PROBLEM: event %s: unknown state %s" % [id, state])
		for choice in def.choices:
			choices += 1
			for requirement in [String(choice.requires), String(choice.get("also", ""))]:
				if String(requirement).is_empty():
					continue
				var parts: PackedStringArray = String(requirement).split(":")
				if not REQUIREMENTS.has(parts[0]):
					print("PROBLEM: event %s: unknown requirement %s" % [id, requirement])
				elif parts[0] in ["crew", "crew_with", "pledged", "not_pledged", "tech", "no_tech", "afford_tech"] and Library.race(parts[1]) == null:
					print("PROBLEM: event %s: unknown race in %s" % [id, requirement])
				elif parts[0] in ["state", "not_state"]:
					for state in parts[1].split(","):
						if not STATES.has(state):
							print("PROBLEM: event %s: unknown state in %s" % [id, requirement])
				elif parts[0] == "system" and parts[1].contains(","):
					for system_id in parts[1].split(","):
						if Library.system(system_id) == null:
							print("PROBLEM: event %s: unknown system in %s" % [id, requirement])
				elif parts[0] == "crew_with" and parts.size() > 2:
					for system_id in parts[2].split(","):
						if Library.system(system_id) == null:
							print("PROBLEM: event %s: unknown system in %s" % [id, requirement])
			for outcome in choice.outcomes:
				for effect in outcome.effects:
					var attrs: Dictionary = effect.attrs
					if not EFFECTS.has(effect.tag):
						print("PROBLEM: event %s: unknown effect <%s>" % [id, effect.tag])
					if effect.tag == "fight":
						if attrs.has("squad") and not Library.squads.has(attrs.squad):
							print("PROBLEM: event %s: fight with unknown squad %s" % [id, attrs.squad])
						if attrs.has("then") and not Library.events.has(attrs.then):
							print("PROBLEM: event %s: fight then unknown event %s" % [id, attrs.then])
						if attrs.has("pledge") and Library.race(attrs.pledge) == null:
							print("PROBLEM: event %s: fight pledges unknown race %s" % [id, attrs.pledge])
					if effect.tag == "event" and not Library.events.has(attrs.get("id", "")):
						print("PROBLEM: event %s: leads to unknown event %s" % [id, attrs.get("id", "")])
					if effect.tag == "ship" and Library.ship(attrs.get("design", "outrider")) == null:
						print("PROBLEM: event %s: unknown ship %s" % [id, attrs.get("design", "")])
					if effect.tag in ["pledge", "tech", "crew"] and attrs.get("race", "") not in ["", "region"] and Library.race(attrs.race) == null:
						print("PROBLEM: event %s: <%s> with unknown race %s" % [id, effect.tag, attrs.race])
	for squad in Library.squads.values():
		for tier in squad.tiers:
			for ship in tier.ships:
				if Library.ship(ship.design) == null:
					print("PROBLEM: squad %s: unknown ship %s" % [squad.id, ship.design])
		for design in squad.reinforcements:
			if Library.ship(design) == null:
				print("PROBLEM: squad %s: unknown reinforcement %s" % [squad.id, design])
	print("event choices checked: ", choices)


## A ship's EVA or EVB Dock sits at an airlock (GDD 5D).
func _check_docks() -> void:
	for id in Library.ships:
		var ship := Ship.from_design(Library.ships[id], 0, RandomNumberGenerator.new())
		for system in ship.systems:
			if system.behaviour in ShipOutfitter.DOCKS and not ShipOutfitter.dock_has_its_airlock(ship, system):
				print("PROBLEM: %s: %s is not at an airlock" % [id, system.def.name])


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
