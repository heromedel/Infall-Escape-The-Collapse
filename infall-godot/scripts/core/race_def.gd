class_name RaceDef
extends RefCounted
## One crew race and faction, read from content/races/<id>/race.xml: crew traits (race profiles, point 9),
## its power colour (GDD 14D) and the names its crew are given.

var id: String
var name: String                 # what the race is called, e.g. "GATOS"
var singular: String             # one of them, e.g. "GATOS crew"
var max_health: float = 100.0
var speed: float = 1.0
var xp_rate: float = 1.0          # GDD 7H
var repair_rate: float = 1.0
var biomech_repair_rate: float = 0.6   # most races struggle to repair biomechanical tech (GDD 8D)
var melee: float = 1.0
var power_colour: Color = Color("#66ff66")
var hull_tint: Color = Color.WHITE
var breathes: bool = true
var fire_immune: bool = false
var makes_air: bool = false       # Azurethea: breathable air wherever they stand
var integrates: bool = false      # Mecha: integrating with a system powers it one bar
var systems_at_once: int = 1      # Tentauri: up to four systems in their room
var heals_slowly: bool = false
var crew_price: int = 1089
var portrait: String = "token"
var tech: String = "mechanical"
var consoles: String = ""          # its ships' console style, a folder in content/consoles (GV 7G); "" is the default
var crew_art: Array = []           # sprite sheets for the Art Style setting (GV 7F): {style, species, sheet, layout,
								   # particles, stand_back}; particles is {animation: {kind, facing or "any": point
								   # in the frame}}; stand_back is how far from a console's wall the figure is drawn
var token: Dictionary = {}         # a token cut from a sheet: {style, row, column, centre, radius}; empty for a drawn face
var skin_parts: Array = []         # the parts of its sheet that take a colour, in a subtype's order (CrewSkins):
								   # {id, sheet_tones, colours: {id: tones}}, tones being colour codes, lightest first
var subtypes: PackedStringArray = []   # its planned subtypes, e.g. "blue/forest"
var names: PackedStringArray = []
var species_names := {}            # GATOS Species setting value -> names only that species uses (GV 7A)
var description: String = ""
var traits_text: String = ""


static func from_xml(node: XmlTree, folder: String = "") -> RaceDef:
	var def := RaceDef.new()
	def.id = node.get_attr("id")
	def.name = node.get_attr("name", def.id.capitalize())
	def.singular = node.get_attr("singular", def.name)
	def.max_health = node.get_float("health", 100.0)
	def.speed = node.get_float("speed", 1.0)
	def.xp_rate = node.get_float("xp_rate", 1.0)
	def.repair_rate = node.get_float("repair", 1.0)
	def.biomech_repair_rate = node.get_float("biomech_repair", 0.6)
	def.melee = node.get_float("melee", 1.0)
	def.power_colour = Color(node.get_attr("power_colour", "#66ff66"))
	def.hull_tint = Color(node.get_attr("hull_tint", "#ffffff"))
	def.breathes = node.get_bool("breathes", true)
	def.fire_immune = node.get_bool("fire_immune", false)
	def.makes_air = node.get_bool("makes_air", false)
	def.integrates = node.get_bool("integrates", false)
	def.systems_at_once = node.get_int("systems_at_once", 1)
	def.heals_slowly = node.get_bool("heals_slowly", false)
	def.crew_price = Mawjig.amount(node.get_float("crew_price", 10.89))
	def.portrait = node.get_attr("portrait", "token")
	def.tech = node.get_attr("tech", "mechanical")
	def.consoles = node.get_attr("consoles")
	for art_node in node.all("crew_art"):
		var particles := {}
		for particles_node in art_node.all("particles"):
			var starts := {"kind": particles_node.get_attr("kind")}
			for facing in ["down", "right", "up", "left", "any"]:
				if particles_node.has_attr(facing):
					var point := particles_node.get_attr(facing).split(",")
					starts[facing] = Vector2(float(point[0]), float(point[1]))
			particles[particles_node.get_attr("animation")] = starts
		def.crew_art.append({"style": art_node.get_attr("style"), "species": art_node.get_attr("species"),
				"sheet": folder.path_join(art_node.get_attr("sheet")), "layout": art_node.get_attr("layout"),
				"particles": particles, "stand_back": art_node.get_float("stand_back", CrewArt.STAND_BACK)})
	var token_node := node.first("token")
	if token_node:
		var cell := token_node.get_attr("frame", "1,1").split(",")
		var centre := token_node.get_attr("centre").split(",")
		def.token = {"style": token_node.get_attr("style"), "row": int(cell[0]), "column": int(cell[1]),
				"centre": Vector2(float(centre[0]), float(centre[1])), "radius": token_node.get_float("radius", 11.5)}
	for part_node in node.all("skin_part"):
		var colours := {}
		for colour_node in part_node.all("colour"):
			colours[colour_node.get_attr("id")] = _colour_codes(colour_node.get_attr("tones"))
		def.skin_parts.append({"id": part_node.get_attr("id"), "sheet_tones": _colour_codes(part_node.get_attr("sheet_tones")), "colours": colours})
	for subtype_node in node.all("subtype"):
		def.subtypes.append(subtype_node.get_attr("wears"))
	for names_node in node.all("names"):
		var species := names_node.get_attr("species")
		var into: PackedStringArray = []
		for raw_name in names_node.get_clean_text().split(",", false):
			into.append(raw_name.strip_edges())
		if species.is_empty():
			def.names.append_array(into)
		else:
			def.species_names[species] = into
	var description_node := node.first("description")
	if description_node:
		def.description = description_node.get_clean_text()
	var traits_node := node.first("traits")
	if traits_node:
		def.traits_text = traits_node.get_clean_text()
	return def


func random_name(rng: RandomNumberGenerator, taken: Array) -> String:
	var pool := names.duplicate()
	pool.append_array(species_names.get(Settings.get_value("gatos_species", "Terrans"), PackedStringArray()))
	if pool.is_empty():
		return singular
	for attempt in 12:
		var candidate := pool[rng.randi_range(0, pool.size() - 1)]
		if not taken.has(candidate):
			return candidate
	return pool[rng.randi_range(0, pool.size() - 1)]


## A list of colour codes as written in a race.xml: "#e2fffa, #92e4e0".
static func _colour_codes(written: String) -> PackedStringArray:
	var codes := PackedStringArray()
	for code in written.split(",", false):
		codes.append(code.strip_edges().to_lower())
	return codes
