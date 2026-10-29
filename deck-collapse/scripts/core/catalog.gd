## The game's content, read from the XML files in data/ and the player's saved ships.
## One owner for content: everything else asks the Catalog rather than reading files itself.
extends Node

const SYSTEMS_FILE := "res://data/systems.xml"
const WEAPONS_FILE := "res://data/weapons.xml"
const SUITS_FILE := "res://data/suits.xml"
const RULES_FILE := "res://data/rules.xml"
const BUILT_IN_SHIPS_FOLDER := "res://data/ships"
const NAMES_FOLDER := "res://data/names"
const USER_SHIPS_FOLDER := "user://ships"

## System definitions by type, in file order.
var systems := {}
## Weapon families (laser, flak, ion, missile, beam) by id: what each does with shields and crew.
var weapon_families := {}
## Premade weapons by id, in file order (see Weapons for a weapon's fields).
var weapons := {}
## EVB battlesuit types by id, in file order.
var suit_kinds := {}
## Rule numbers from rules.xml: element name -> its attributes (numbers and lists already converted).
var rules := {}
## Crew name lists by "race/style" (e.g. "gatos/cats"): { names: [{ name, sex, weight }], total }.
var name_lists := {}
## Every ship design that can be picked: built-in first, then the player's own.
var designs: Array[ShipDesign] = []


func _ready() -> void:
	load_systems()
	load_weapons()
	load_suit_kinds()
	load_rules()
	load_names()
	reload_designs()


func load_systems() -> void:
	systems.clear()
	var root := XmlTree.parse_file(SYSTEMS_FILE)
	for node in XmlTree.children_named(root, "system"):
		var attrs: Dictionary = node.attrs
		systems[attrs.type] = {
			"type": attrs.type,
			"name": attrs.get("name", attrs.type),
			"card": attrs.get("card", ""),
			"cards_per_level": int(attrs.get("cardsPerLevel", 0)),
			"min_level": int(attrs.get("minLevel", 1)),
			"max_level": int(attrs.get("maxLevel", 3)),
			"required": attrs.get("required", "false") == "true",
			"mannable": attrs.get("mannable", "false") == "true",
			"prices": number_list(attrs.get("prices", "")),
			"manned_evasion": number_list(attrs.get("mannedEvasion", "")),
			"crew_draw": number_list(attrs.get("crewDraw", "")),
			"unmanned_draw": float(attrs.get("unmannedDraw", 0)),
			"manned_level": int(attrs.get("mannedLevel", 0)),
			"evasion_by_level": number_list(attrs.get("evasionByLevel", "")),
			"summary": XmlTree.clean_text(node),
		}


func load_weapons() -> void:
	weapon_families.clear()
	weapons.clear()
	var root := XmlTree.parse_file(WEAPONS_FILE)
	for node in XmlTree.children_named(root, "family"):
		var attrs: Dictionary = node.attrs
		weapon_families[attrs.id] = {
			"id": attrs.id,
			"name": attrs.get("name", attrs.id),
			"shields": attrs.get("shields", "pop"),
			"ion": attrs.get("ion", "false") == "true",
			"uses_missile": attrs.get("usesMissile", "false") == "true",
			"never_misses": attrs.get("neverMisses", "false") == "true",
			"wounds_crew": attrs.get("woundsCrew", "false") == "true",
			"base": float(attrs.get("base", 0.02)),
			"summary": XmlTree.clean_text(node),
		}
	for node in XmlTree.children_named(root, "weapon"):
		var weapon := Weapons.from_attributes(node.attrs)
		weapons[weapon.id] = weapon


func load_suit_kinds() -> void:
	suit_kinds.clear()
	var root := XmlTree.parse_file(SUITS_FILE)
	for node in XmlTree.children_named(root, "suit"):
		var attrs: Dictionary = node.attrs
		suit_kinds[attrs.id] = {
			"id": attrs.id,
			"name": attrs.get("name", attrs.id),
			"cost": int(attrs.get("cost", 2)),
			"turns": int(attrs.get("turns", 3)),
			"action": attrs.get("action", "shoot"),
			"shots": int(attrs.get("shots", 1)),
			"damage": int(attrs.get("damage", 1)),
			"shields": attrs.get("shields", "pop"),
			"ion": attrs.get("ion", "false") == "true",
			"never_misses": attrs.get("neverMisses", "false") == "true",
			"price": float(attrs.get("price", 0)),
			"sortie": _suit_sortie(attrs),
			"summary": XmlTree.clean_text(node),
		}


## Mawjig for one launch: every shot over all its turns (mawjig-cost-table.md), or the file's sortie.
static func _suit_sortie(attrs: Dictionary) -> float:
	var turns := int(attrs.get("turns", 3))
	var per_turn := 0.0
	match attrs.get("action", ""):
		"shoot":
			var damage := int(attrs.get("damage", 1))
			var base := 0.03 if attrs.get("shields", "pop") == "reduce" else 0.02
			var per_shot := base * (1.0 + 0.5 * maxi(0, damage - 1)) + (0.02 if attrs.get("ion", "false") == "true" else 0.0)
			per_turn = per_shot * int(attrs.get("shots", 1))
		"intercept":
			per_turn = 0.02
		_:
			return float(attrs.get("sortie", 0))
	var cents := roundi(per_turn * turns * 100.0)
	return (cents + (1 if cents % 10 == 0 else 0)) / 100.0


func load_rules() -> void:
	rules.clear()
	for node in XmlTree.parse_file(RULES_FILE).get("children", []):
		var values := {}
		for key in node.attrs:
			var text: String = node.attrs[key]
			values[key] = number_list(text) if text.contains(",") else float(text)
		rules[node.name] = values


func load_names() -> void:
	name_lists.clear()
	for path in _xml_files_in(NAMES_FOLDER):
		var root := XmlTree.parse_file(path)
		var weights := {}
		for rarity in XmlTree.children_named(root, "rarity"):
			for level in XmlTree.children_named(rarity, "level"):
				weights[level.attrs.name] = float(level.attrs.get("weight", 1))
		var first_level: String = weights.keys()[0] if not weights.is_empty() else ""
		var entries: Array = []
		var total := 0.0
		for node in XmlTree.children_named(root, "name"):
			var weight := float(weights.get(node.attrs.get("rarity", first_level), 1.0))
			entries.append({"name": XmlTree.clean_text(node), "sex": node.attrs.get("sex", "B"), "weight": weight})
			total += weight
		name_lists["%s/%s" % [root.attrs.get("race", ""), root.attrs.get("style", "")]] = {"names": entries, "total": total}


## A name from a list, by rarity. Falls back to "Crew" if the list is missing.
func random_name(list_id: String, rng: RandomNumberGenerator) -> String:
	var list: Dictionary = name_lists.get(list_id, {})
	if list.is_empty():
		return "Crew"
	var roll := rng.randf() * float(list.total)
	for entry in list.names:
		roll -= entry.weight
		if roll <= 0.0:
			return entry.name
	return list.names.back().name


## A rule number, e.g. rule("jump", "chargesNeeded").
func rule(element: String, key: String, fallback = 0):
	return rules.get(element, {}).get(key, fallback)


## A per-skill number list from a rule or system ("10,15,20"), read at a skill level (0 untrained … 2 Master).
static func by_skill(values: Array, skill: int) -> float:
	if values.is_empty():
		return 0.0
	return float(values[clampi(skill, 0, values.size() - 1)])


static func number_list(text: String) -> Array:
	var numbers: Array = []
	for part in text.split(",", false):
		numbers.append(float(part.strip_edges()))
	return numbers


func suit_kind(suit_id: String) -> Dictionary:
	return suit_kinds.get(suit_id, suit_kinds.values()[0])


func weapon_family(family_id: String) -> Dictionary:
	return weapon_families.get(family_id, weapon_families.values()[0])


## A copy of a premade weapon, or of the first one if the id is unknown.
func weapon(weapon_id: String) -> Dictionary:
	return weapons.get(weapon_id, weapons.values()[0]).duplicate()


func reload_designs() -> void:
	designs.clear()
	for path in _xml_files_in(BUILT_IN_SHIPS_FOLDER):
		var design := ShipDesign.from_xml(FileAccess.get_file_as_string(path))
		if design:
			design.built_in = true
			design.source_path = path
			designs.append(design)
	DirAccess.make_dir_recursive_absolute(USER_SHIPS_FOLDER)
	for path in _xml_files_in(USER_SHIPS_FOLDER):
		var design := ShipDesign.from_xml(FileAccess.get_file_as_string(path))
		if design:
			design.source_path = path
			designs.append(design)


## Saves a player design into the user ships folder and returns the path written.
func save_user_design(design: ShipDesign) -> String:
	DirAccess.make_dir_recursive_absolute(USER_SHIPS_FOLDER)
	var path := design.source_path
	if design.built_in or path == "" or not path.begins_with(USER_SHIPS_FOLDER):
		path = "%s/%s.xml" % [USER_SHIPS_FOLDER, file_name_for(design.name)]
	write_text_file(path, design.to_xml())
	design.source_path = path
	reload_designs()
	return path


func delete_user_design(design: ShipDesign) -> void:
	if design.built_in or not design.source_path.begins_with(USER_SHIPS_FOLDER):
		return
	DirAccess.remove_absolute(design.source_path)
	reload_designs()


func write_text_file(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	return true


## System types in the order the game lists them (file order, weapons last).
func system_types_in_order() -> Array:
	return systems.keys()


func _xml_files_in(folder: String) -> Array[String]:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(folder):
		if file_name.ends_with(".xml"):
			paths.append("%s/%s" % [folder, file_name])
	paths.sort()
	return paths


func file_name_for(ship_name: String) -> String:
	var safe := ""
	for character in ship_name.to_lower():
		safe += character if (character >= "a" and character <= "z") or (character >= "0" and character <= "9") else "-"
	while safe.contains("--"):
		safe = safe.replace("--", "-")
	safe = safe.trim_prefix("-").trim_suffix("-")
	return safe if safe != "" else "ship"
