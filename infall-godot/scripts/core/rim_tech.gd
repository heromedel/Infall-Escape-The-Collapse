class_name RimTech
extends RefCounted
## The Tech victory's pieces (content/tech/tech.xml, GV 2F): one from each race, carried in the squad's hold to the
## rim. Where a piece can be had: its race's tech site (one cluster in each of its regions, marked on the map), a
## store deep in its space, a ship of that race left whole, or a ship of that race that surrenders close to the rim.

static var pieces: Dictionary = {}     # race id -> {race, name, line, price_share, sold, surrendered}
static var order: Array[String] = []   # race ids in the file's order
static var base_price: int = 3631      # cents, before the band adjustment
static var from_band: int = 3
static var demand_band: int = 6
static var steal_chance: float = 0.2
static var steal_chance_late: float = 0.33
static var late_band: int = 6


static func load_from(node: XmlTree) -> void:
	pieces.clear()
	order.clear()
	base_price = Mawjig.amount(node.get_float("price", 36.31))
	from_band = node.get_int("from_band", 3)
	demand_band = node.get_int("demand_band", 6)
	steal_chance = node.get_float("steal_chance", 0.2)
	steal_chance_late = node.get_float("steal_chance_late", steal_chance)
	late_band = node.get_int("late_band", 6)
	for child in node.all("piece"):
		var race := child.get_attr("race")
		pieces[race] = {
			"race": race, "name": child.get_attr("name", race), "line": child.get_clean_text(),
			"price_share": child.get_float("price_share", 1.0),
			"sold": child.get_attr("sold", "yes") == "yes", "surrendered": child.get_attr("surrendered", "yes") == "yes",
		}
		order.append(race)


static func name_of(race: String) -> String:
	return pieces[race].name if pieces.has(race) else race


## The piece a store in this cluster sells, or "": deep or inner in a race's own space, from the band stores start
## selling them, and not where stores run short.
static func sold_at(cluster: Dictionary) -> String:
	var race: String = cluster.race
	if not pieces.has(race) or not pieces[race].sold or cluster.get("occupier", "") != "" or int(cluster.band) < from_band:
		return ""
	if cluster.rank == "border" or cluster.states.has("Doomed") or cluster.states.has("Refugee") or cluster.states.has("Abandoned"):
		return ""
	return race


## What a race's piece costs in a band, in cents: a core system's price times the band adjustment (Infall: Eco), and
## the race's own share of that (the Mecha part with theirs only for a good deal).
static func price(race: String, band: int, share: float = 1.0) -> int:
	if not pieces.has(race):
		return 0
	return int(round(base_price * (1.0 + 0.1 * (band - 1)) * float(pieces[race].price_share) * share))


static func steal_chance_in(band: int) -> float:
	return steal_chance_late if band >= late_band else steal_chance


## The event that plays at a race's tech site.
static func site_event(race: String) -> String:
	return "TECH_" + race.to_upper()
