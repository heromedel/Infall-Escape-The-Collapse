class_name RaceDef
extends RefCounted
## One crew race and faction, read from content/races/<id>/race.xml: crew traits (race profiles, point 9),
## its power colour (GDD 14D) and the names its crew are given.

var id: String
var name: String                 # what the race is called, e.g. "GATOS"
var singular: String             # one of them, e.g. "GATOS cat"
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
var names: PackedStringArray = []
var description: String = ""
var traits_text: String = ""


static func from_xml(node: XmlTree) -> RaceDef:
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
	var names_node := node.first("names")
	if names_node:
		for raw_name in names_node.get_clean_text().split(",", false):
			def.names.append(raw_name.strip_edges())
	var description_node := node.first("description")
	if description_node:
		def.description = description_node.get_clean_text()
	var traits_node := node.first("traits")
	if traits_node:
		def.traits_text = traits_node.get_clean_text()
	return def


func random_name(rng: RandomNumberGenerator, taken: Array) -> String:
	if names.is_empty():
		return singular
	for attempt in 12:
		var candidate := names[rng.randi_range(0, names.size() - 1)]
		if not taken.has(candidate):
			return candidate
	return names[rng.randi_range(0, names.size() - 1)]
