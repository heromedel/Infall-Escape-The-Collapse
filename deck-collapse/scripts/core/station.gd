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


func _init(design: ShipDesign, rng: RandomNumberGenerator) -> void:
	var choices: Array = [SECTION_WEAPONS, SECTION_SUITS, SECTION_CREW]
	if not _installable_systems(design).is_empty():
		choices.append(SECTION_SYSTEMS)
	_shuffle(choices, rng)
	var count := int(Catalog.rule("station", "sections", 2))
	var per_section := int(Catalog.rule("station", "itemsPerSection", 3))
	for section_id in choices.slice(0, count):
		sections.append({"id": section_id, "items": _roll_items(section_id, design, per_section, rng)})


func _roll_items(section_id: String, design: ShipDesign, count: int, rng: RandomNumberGenerator) -> Array:
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
			var kinds: Array = Catalog.weapon_kinds.keys()
			for i in count:
				var kind_id: String = kinds[rng.randi() % kinds.size()]
				var types: Array = Catalog.weapon_kinds[kind_id].types.keys()
				var weapon_type: int = types[rng.randi() % types.size()]
				var kind := Catalog.weapon_kind(kind_id)
				var profile := Catalog.weapon_profile(kind_id, weapon_type)
				items.append({"kind": "weapon", "weapon_kind": kind_id, "weapon_type": weapon_type,
					"name": "%s T%d" % [kind.name, weapon_type], "detail": CardLibrary.weapon_text(kind, profile),
					"price": float(profile.price)})
		SECTION_SUITS:
			var suits: Array = Catalog.suit_kinds.keys()
			_shuffle(suits, rng)
			for suit_id in suits.slice(0, count):
				var suit := Catalog.suit_kind(suit_id)
				items.append({"kind": "suit", "suit": suit_id, "name": suit.name,
					"detail": "Needs an EVB Dock of level %d. %s" % [suit.cost, suit.summary], "price": float(suit.price)})
		SECTION_CREW:
			for i in count:
				var member := _crew_for_hire(rng)
				items.append({"kind": "crew", "member": member, "name": member.name, "detail": _skills_text(member.skills),
					"price": ShipDesign.member_value(member.skills)})
	for item in items:
		item.price = Money.round_amount(item.price)
		item.sold = false
	return items


## Systems the design doesn't have yet that a station can install. Weapons and the Reactor are bought other ways,
## and systems every ship comes with (price 0) aren't for sale.
static func _installable_systems(design: ShipDesign) -> Array:
	var types: Array = []
	for type in Catalog.systems:
		var definition: Dictionary = Catalog.systems[type]
		if type in ["weapon", "reactor"] or design.has_system(type) or definition.prices.is_empty() or float(definition.prices[0]) <= 0.0:
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


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = values[i]
		values[i] = values[j]
		values[j] = swap
