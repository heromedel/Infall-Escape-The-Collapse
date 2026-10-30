## A station's store at a stop between battles: what it always sells, and its random sections of systems,
## weapons, battlesuits and crew. The stock is rolled once when the station is reached and stays until you leave.
class_name Station
extends RefCounted

const SECTION_SYSTEMS := "systems"
const SECTION_WEAPONS := "weapons"
const SECTION_SUITS := "suits"
const SECTION_CREW := "crew"
const SECTION_NAMES := {SECTION_SYSTEMS: "Systems", SECTION_WEAPONS: "Weapons", SECTION_SUITS: "Battlesuits", SECTION_CREW: "Crew"}

## Each section: { id, items }. Each item: { kind (system, weapon, suit, crew), name, detail, price, sold, ... }
## with its own fields: system { type }, weapon { weapon_kind, weapon_type }, suit { suit }, crew { member }.
var sections: Array = []


## band: the run's difficulty band; weapons only turn up in the bands they're allowed in.
func _init(design: ShipDesign, rng: RandomNumberGenerator, band: int = 1) -> void:
	var choices: Array = [SECTION_WEAPONS, SECTION_SUITS, SECTION_CREW]
	if not _installable_systems(design).is_empty():
		choices.append(SECTION_SYSTEMS)
	_shuffle(choices, rng)
	var count := int(Catalog.rule("station", "sections", 2))
	var per_section := int(Catalog.rule("station", "itemsPerSection", 3))
	for section_id in choices.slice(0, count):
		sections.append({"id": section_id, "items": _roll_items(section_id, design, per_section, rng, band)})


func _roll_items(section_id: String, design: ShipDesign, count: int, rng: RandomNumberGenerator, band: int) -> Array:
	var items: Array = []
	match section_id:
		SECTION_SYSTEMS:
			var types := _installable_systems(design)
			_shuffle(types, rng)
			for type in types.slice(0, count):
				var definition: Dictionary = Catalog.systems[type]
				items.append({"kind": "system", "type": type, "name": definition.name, "detail": definition.summary,
					"price": float(definition.prices[0])})
		SECTION_WEAPONS:
			var ids: Array = Catalog.weapons.keys().filter(func(id): return Weapons.allowed_in_band(Catalog.weapons[id], band))
			for weapon_id in _weighted_picks(ids, count, rng, func(id): return Weapons.store_weight(Catalog.weapons[id])):
				var weapon := Catalog.weapon(weapon_id)
				items.append({"kind": "weapon", "weapon": weapon, "name": weapon.name,
					"detail": "%d card%s in your deck. %s" % [weapon.speed, "" if weapon.speed == 1 else "s", Weapons.card_text(weapon)],
					"price": float(weapon.price)})
		SECTION_SUITS:
			var suits: Array = Catalog.suit_kinds.keys()
			_shuffle(suits, rng)
			for suit_id in suits.slice(0, count):
				var suit := Catalog.suit_kind(suit_id)
				items.append({"kind": "suit", "suit": suit_id, "name": suit.name,
					"detail": "%d power to launch, %d card%s. %s" % [suit.cost, suit.speed, "" if suit.speed == 1 else "s", suit.summary],
					"price": float(suit.price)})
		SECTION_CREW:
			for i in count:
				var member := _crew_for_hire(rng)
				items.append({"kind": "crew", "member": member, "name": member.name, "detail": _skills_text(member.skills),
					"price": ShipDesign.member_value(member.skills)})
	for item in items:
		item.price = Money.round_amount(item.price)
		item.sold = false
	return items


## Systems the design doesn't have yet that a station can install: a weapon system only if it has none (weapons
## are bought on their own), never the Reactor, and not systems every ship comes with (price 0).
static func _installable_systems(design: ShipDesign) -> Array:
	var types: Array = []
	for type in Catalog.systems:
		var definition: Dictionary = Catalog.systems[type]
		if type == "reactor" or design.has_system(type) or definition.prices.is_empty() or float(definition.prices[0]) <= 0.0:
			continue
		# An Avatar Array only helps a crew it can broadcast (Senti).
		if type == "aaa" and not design.crew.any(func(m): return Catalog.race(m.get("race", "")).broadcast):
			continue
		types.append(type)
	return types


## A crew member for hire: untrained, sometimes a Veteran in one skill. Named for the crew portraits in use.
static func _crew_for_hire(rng: RandomNumberGenerator) -> Dictionary:
	var list := "gatos/cats" if Settings.value("crew_portraits") == "Cat Faces" else "gatos/human"
	var skills := CrewSkills.empty()
	if rng.randf() * 100.0 < float(Catalog.rule("station", "crewSkillChance", 0)):
		skills[CrewSkills.NAMES[rng.randi() % CrewSkills.NAMES.size()]] = 1
	return {"name": Catalog.random_name(list, rng), "skills": skills}


static func _skills_text(skills: Dictionary) -> String:
	var trained: Array[String] = []
	for skill in CrewSkills.NAMES:
		if int(skills.get(skill, 0)) > 0:
			trained.append("%s %s" % [CrewSkills.LEVEL_NAMES[int(skills[skill])], CrewSkills.LABELS[skill]])
	return "Untrained." if trained.is_empty() else ", ".join(trained) + "."


## Up to count different values, each pick weighted by weight_of (weight 0: never picked).
static func _weighted_picks(values: Array, count: int, rng: RandomNumberGenerator, weight_of: Callable) -> Array:
	var left := values.filter(func(value): return weight_of.call(value) > 0.0)
	var picks: Array = []
	while picks.size() < count and not left.is_empty():
		var total := 0.0
		for value in left:
			total += weight_of.call(value)
		var roll := rng.randf() * total
		var chosen = left[left.size() - 1]
		for value in left:
			roll -= weight_of.call(value)
			if roll < 0.0:
				chosen = value
				break
		picks.append(chosen)
		left.erase(chosen)
	return picks


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = values[i]
		values[i] = values[j]
		values[j] = swap
