extends Node
## Library (autoload): every piece of content, loaded once from content/. Ships, weapons, systems, races,
## squads and events are folders and XML files a modder can open and change (coding rule 4); nothing about a
## particular ship or weapon lives in code.

const CONTENT := "res://content"

var systems: Dictionary = {}     # id -> SystemDef
var weapons: Dictionary = {}     # id -> WeaponDef (suits included)
var races: Dictionary = {}       # id -> RaceDef
var ships: Dictionary = {}       # id -> ShipDesign (base ships and loadouts)
var squads: Dictionary = {}      # id -> SquadDef
var events: Dictionary = {}      # id -> EventDef
var problems: PackedStringArray = []
var _textures: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	_load_systems()
	_load_weapons()
	_load_races()
	_load_ships()
	_load_squads()
	_load_events()
	for problem in problems:
		push_warning(problem)


func _folders(path: String) -> PackedStringArray:
	var dir := DirAccess.open(path)
	if dir == null:
		return PackedStringArray()
	var names := dir.get_directories()
	names.sort()
	return names


func _files(path: String, extension: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var dir := DirAccess.open(path)
	if dir == null:
		return found
	for file_name in dir.get_files():
		# Exported builds list imported files with a .remap or .import suffix; content XML is copied as is.
		if file_name.ends_with("." + extension):
			found.append(file_name)
	found.sort()
	return found


func _load_systems() -> void:
	for folder in _folders(CONTENT + "/systems"):
		var node := XmlTree.load_file(CONTENT + "/systems/" + folder + "/system.xml")
		if node:
			var def := SystemDef.from_xml(node)
			systems[def.id] = def


func _load_weapons() -> void:
	for folder in _folders(CONTENT + "/weapons"):
		var path := CONTENT + "/weapons/" + folder
		var node := XmlTree.load_file(path + "/weapon.xml")
		if node:
			var def := WeaponDef.from_xml(node, path)
			weapons[def.id] = def


func _load_races() -> void:
	for folder in _folders(CONTENT + "/races"):
		var node := XmlTree.load_file(CONTENT + "/races/" + folder + "/race.xml")
		if node:
			var def := RaceDef.from_xml(node)
			races[def.id] = def


func _load_ships() -> void:
	for folder in _folders(CONTENT + "/ships"):
		var path := CONTENT + "/ships/" + folder
		var ship_path := path + "/ship.xml"
		var design := ShipDesign.from_file(ship_path)
		if design == null:
			continue
		ships[design.id] = design
		_note_problems(design)
		for file_name in _files(path, "xml"):
			if file_name.begins_with("loadout."):
				var loadout := ShipDesign.from_loadout(path + "/" + file_name, ship_path)
				if loadout:
					ships[loadout.id] = loadout
					_note_problems(loadout)


func _note_problems(design: ShipDesign) -> void:
	for problem in design.problems:
		problems.append("%s: %s" % [design.id, problem])
	for system in design.systems:
		if not systems.has(system.id):
			problems.append("%s: unknown system %s" % [design.id, system.id])
	for weapon in design.weapons:
		if not weapons.has(weapon.id):
			problems.append("%s: unknown weapon %s" % [design.id, weapon.id])


func _load_squads() -> void:
	for file_name in _files(CONTENT + "/squads", "xml"):
		var root := XmlTree.load_file(CONTENT + "/squads/" + file_name)
		if root == null:
			continue
		for node in root.all("squad"):
			var def := SquadDef.from_xml(node)
			squads[def.id] = def
			for tier in def.tiers:
				for ship in tier.ships:
					if not ships.has(ship.design):
						problems.append("squad %s: unknown ship %s" % [def.id, ship.design])


func _load_events() -> void:
	for file_name in _files(CONTENT + "/events", "xml"):
		var root := XmlTree.load_file(CONTENT + "/events/" + file_name)
		if root == null:
			continue
		for node in root.all("event"):
			var def := EventDef.from_xml(node)
			if events.has(def.id):
				problems.append("event %s is defined twice" % def.id)
			events[def.id] = def


func system(id: String) -> SystemDef:
	return systems.get(id)


func weapon(id: String) -> WeaponDef:
	return weapons.get(id)


func race(id: String) -> RaceDef:
	return races.get(id, races.get("terran"))


func ship(id: String) -> ShipDesign:
	return ships.get(id)


## Loads a picture from content: imported textures in the game's own files, plain image files for mods.
func texture(path: String, nearest: bool = false) -> Texture2D:
	if path.is_empty():
		return null
	if _textures.has(path):
		return _textures[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	else:
		var image := Image.load_from_file(path)
		if image:
			tex = ImageTexture.create_from_image(image)
	_textures[path] = tex
	return tex


func weapons_for_store(max_price: int = 99999) -> Array[WeaponDef]:
	var list: Array[WeaponDef] = []
	for def in weapons.values():
		if def.price <= max_price and def.type != "suit":
			list.append(def)
	return list
