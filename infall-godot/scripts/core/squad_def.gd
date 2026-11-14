class_name SquadDef
extends RefCounted
## An enemy squad: a named list of ship designs with counts per band (rough-example-squad-layout.md), plus
## its conduct in a fight: when it surrenders, when it runs, what it aims at and how it answers a Hail.

var id: String
var name: String
var race: String
var faction: String
var tiers: Array = []            # {low_band, high_band, ships: [{design, min, max}]}
var surrender_chance: int = 0     # percent, rolled once when a ship first drops under surrender_hull
var surrender_hull: float = 0.3
var escape_chance: int = 0
var escape_hull: float = 0.25
var leave_after: float = 0.0      # seconds; its ships break off and jump away after this long (the rival)
var breaks_off_at: float = 0.0    # and at once when their hull falls below this share
var starts_at: float = 1.0        # the share of their hull its ships start a fight with (the rival comes scarred)
var augment: String = ""          # the name of what lets them do it, shown on their ships (Jig Drive MC-Flywheel)
var reinforcements: Array[String] = []   # designs that jump in, one by one, to replace its ships as they are lost
var targets: PackedStringArray = []   # systems the squad prefers to aim at, in order
var hail: String = "hostile"      # which Hail answers it gives
var description: String = ""
var where_races: PackedStringArray = []   # region races it shows up in; "any" for anywhere
var where_states: PackedStringArray = []  # cluster states it shows up in; empty for any


static func from_xml(node: XmlTree) -> SquadDef:
	var def := SquadDef.new()
	def.id = node.get_attr("id")
	def.name = node.get_attr("name", def.id)
	def.race = node.get_attr("race", "terran")
	def.faction = node.get_attr("faction", def.race)
	def.where_races = node.get_attr("where_races", def.race).split(",", false)
	def.where_states = node.get_attr("where_states", "").split(",", false)
	for tier in node.all("tier"):
		var bands := tier.get_attr("bands", "1-8").split("-")
		var entry := {"low_band": int(bands[0]), "high_band": int(bands[bands.size() - 1]), "ships": []}
		for ship in tier.all("ship"):
			var counts := ship.get_attr("count", "1").split("-")
			entry.ships.append({"design": ship.get_attr("design"), "min": int(counts[0]), "max": int(counts[counts.size() - 1])})
		def.tiers.append(entry)
	for extra in node.all("reinforce"):
		for copy in extra.get_int("count", 1):
			def.reinforcements.append(extra.get_attr("design"))
	var conduct := node.first("conduct")
	if conduct:
		def.surrender_chance = conduct.get_int("surrender_chance", 0)
		def.surrender_hull = conduct.get_float("surrender_hull", 0.3)
		def.escape_chance = conduct.get_int("escape_chance", 0)
		def.escape_hull = conduct.get_float("escape_hull", 0.25)
		def.leave_after = conduct.get_float("leave_after", 0.0)
		def.breaks_off_at = conduct.get_float("breaks_off_at", 0.0)
		def.augment = conduct.get_attr("augment", "")
		def.starts_at = conduct.get_float("starts_at", 1.0)
		def.targets = conduct.get_attr("targets", "").split(",", false)
		def.hail = conduct.get_attr("hail", "hostile")
	var description_node := node.first("description")
	if description_node:
		def.description = description_node.get_clean_text()
	return def


## The ship designs this squad fields in a band; empty when it has no tier for that band.
func roll_ships(band: int, rng: RandomNumberGenerator) -> Array[String]:
	var picked: Array[String] = []
	var best_tier: Dictionary = {}
	var fitting: Array = tiers.filter(func(tier): return band >= tier.low_band and band <= tier.high_band)
	if not fitting.is_empty():
		best_tier = fitting[rng.randi_range(0, fitting.size() - 1)]     # several tiers for a band: one of them
	if best_tier.is_empty() and not tiers.is_empty():
		best_tier = tiers.back() if band > tiers.back().high_band else tiers.front()
	if best_tier.is_empty():
		return picked
	for ship in best_tier.ships:
		for copy in rng.randi_range(ship.min, ship.max):
			picked.append(ship.design)
	return picked


func has_band(band: int) -> bool:
	for tier in tiers:
		if band >= tier.low_band and band <= tier.high_band:
			return true
	return false
