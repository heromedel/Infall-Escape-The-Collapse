## A ship design: what a captain brings to a battle. Read from and written to ship XML files.
## A design is only data; the battle copies what it needs into its own ship state.
class_name ShipDesign
extends RefCounted

const DEFAULT_COLOR := "#66FF66"

var name := "New Ship"
var faction := "Independent"
var color := DEFAULT_COLOR
var note := ""
var hull := 16
var missiles := 0
## Battlesuit parts: one per launch, used when Ammo is Classic.
var suit_parts := 0
## Each system: { "id", "type", "level" }; a weapon system also has "name", "weapons" (see Weapons) and "max_slots";
## an EVB Dock has "suit".
var systems: Array = []
## Each crew member: { "name", "skills" (see CrewSkills), "station" (a system id) }.
var crew: Array = []
## Parts of the ship file this game doesn't support yet (systems it doesn't know, floor plans and so on), kept as
## XML nodes so saving the design writes them back unchanged. See unsupported_parts().
var unsupported: Array = []
## Where the design was loaded from, so saving a user design overwrites the same file.
var source_path := ""
var built_in := false


static func from_xml(xml_text: String) -> ShipDesign:
	var root := XmlTree.parse(xml_text)
	if root.is_empty() or root.name != "ship":
		return null
	var design := ShipDesign.new()
	var attrs: Dictionary = root.attrs
	design.name = attrs.get("name", design.name)
	design.faction = attrs.get("faction", design.faction)
	design.color = attrs.get("color", DEFAULT_COLOR)
	design.hull = int(attrs.get("hull", design.hull))
	design.missiles = int(attrs.get("missiles", 0))
	design.suit_parts = int(attrs.get("suitParts", 0))
	for note_node in XmlTree.children_named(root, "note"):
		design.note = XmlTree.clean_text(note_node)
	var power_nodes := XmlTree.children_named(root, "power")
	for system_node in XmlTree.children_named(root, "system"):
		var system_attrs: Dictionary = system_node.attrs
		var type: String = system_attrs.get("type", "")
		if not Catalog.systems.has(type):
			design.unsupported.append(system_node)
			continue
		var system := {"type": type, "level": int(system_attrs.get("level", 1))}
		system.id = system_attrs.get("id", type)
		if type == "weapon":
			system.name = system_attrs.get("name", "Weapons")
			system.max_slots = int(system_attrs.get("maxSlots", Weapons.SLOTS_PER_SYSTEM))
			system.weapons = _read_weapons(system_node, system)
		elif type == "evb":
			system.suit = system_attrs.get("suit", "assault")
		design.systems.append(system)
	for node in root.children:
		if not node.name in ["note", "system", "crew", "power"]:
			design.unsupported.append(node)
	for crew_node in XmlTree.children_named(root, "crew"):
		var crew_attrs: Dictionary = crew_node.attrs
		design.crew.append({
			"name": crew_attrs.get("name", "Crew"),
			"skills": CrewSkills.from_attributes(crew_attrs),
			"station": crew_attrs.get("station", ""),
			"race": crew_attrs.get("race", ""),
		})
	if not power_nodes.is_empty():
		design._add_vanilla_reactor(power_nodes[0], root)
	return design


## Ship Design's files give power as <power kind level> (gap G2). For now every kind runs as a plain reactor with
## about the power it would give: pool its level; AZC the levels of its 2 × level biggest drawing systems; self
## the systems' own power; crew bars per crew member. Any kind but pool is kept in the file, so a saved design has
## both its reactor and its <power>; then the reactor is used as it is.
func _add_vanilla_reactor(power_node: Dictionary, root: Dictionary) -> void:
	var kind: String = power_node.attrs.get("kind", "pool")
	if kind != "pool":
		unsupported.append(power_node)
	if has_system("reactor"):
		return
	var level := int(power_node.attrs.get("level", 2))
	match kind:
		"AZC":
			var drawing: Array = []
			for system_node in XmlTree.children_named(root, "system"):
				if system_node.attrs.get("draws", "true") != "false":
					drawing.append(int(system_node.attrs.get("level", 1)))
			drawing.sort()
			drawing.reverse()
			level = 0
			for bars in drawing.slice(0, 2 * int(power_node.attrs.get("level", 1))):
				level += bars
		"self":
			level = 0
			for system_node in XmlTree.children_named(root, "system"):
				level += int(system_node.attrs.get("ownPower", 0))
		"crew":
			level = crew.size() * int(power_node.attrs.get("barsPerCrew", 1))
	level = clampi(level, Catalog.systems.reactor.min_level, Catalog.systems.reactor.max_level)
	systems.push_front({"id": "reactor", "type": "reactor", "level": level})
	if kind != "pool":
		power_node.attrs.gdd = "G2: runs as a plain reactor of level %d for now" % level


## The weapons in a weapon system's file entry. An old entry (kind and weaponType on the system) becomes the
## matching premade weapon, as fast as the system's old level made it.
static func _read_weapons(system_node: Dictionary, system: Dictionary) -> Array:
	var found: Array = []
	for weapon_node in XmlTree.children_named(system_node, "weapon"):
		var attrs: Dictionary = weapon_node.attrs
		found.append(Weapons.from_attributes(attrs, Catalog.weapons.get(attrs.get("ref", attrs.get("id", "")), {})))
	var attrs: Dictionary = system_node.attrs
	if found.is_empty() and attrs.has("kind"):
		var ids: Array = Weapons.LEGACY.get(attrs.kind, Weapons.LEGACY.laser)
		var weapon := Catalog.weapon(ids[clampi(int(attrs.get("weaponType", 1)) - 1, 0, ids.size() - 1)])
		weapon.name = attrs.get("name", weapon.name)
		found.append(Weapons.finish(weapon, system.level))
		system.level = weapon.power
	return found


func to_xml() -> String:
	var lines: Array[String] = ['<?xml version="1.0" encoding="UTF-8"?>']
	lines.append('<ship name="%s" faction="%s" color="%s" hull="%d" missiles="%d" suitParts="%d">' % [
		XmlTree.escape(name), XmlTree.escape(faction), color, hull, missiles, suit_parts])
	if note != "":
		lines.append("  <note>%s</note>" % XmlTree.escape(note))
	for system in systems:
		if system.type == "weapon":
			lines.append('  <system type="weapon" id="%s" name="%s" level="%d">' % [
				XmlTree.escape(system.id), XmlTree.escape(system.name), system.level])
			for weapon in system.weapons:
				lines.append(Weapons.to_xml(weapon))
			lines.append("  </system>")
		elif system.type == "evb":
			lines.append('  <system type="evb" id="%s" suit="%s" level="%d"/>' % [XmlTree.escape(system.id), system.suit, system.level])
		else:
			lines.append('  <system type="%s" level="%d"/>' % [system.type, system.level])
	for member in crew:
		var skills := CrewSkills.to_attributes(member.skills)
		var race: String = member.get("race", "")
		lines.append('  <crew name="%s"%s station="%s"%s/>' % [XmlTree.escape(member.name),
			"" if race == "" else ' race="%s"' % XmlTree.escape(race), XmlTree.escape(member.station),
			"" if skills == "" else " " + skills])
	for node in unsupported:
		lines.append(XmlTree.to_xml(node))
	lines.append("</ship>")
	return "\n".join(lines) + "\n"


## The unsupported parts as readable lines, with the GDD reference and note the ship's designer left on them,
## e.g. "System 'fabricator' (level 2): GDD 6F · Builds drones mid-battle."
func unsupported_parts() -> Array[String]:
	var found: Array[String] = []
	for node in unsupported:
		var attrs: Dictionary = node.attrs
		var label: String = node.name.capitalize()
		if attrs.has("type"):
			label += " '%s'" % attrs.type
		elif attrs.has("kind"):
			label += " '%s'" % attrs.kind
		elif attrs.has("name"):
			label += " '%s'" % attrs.name
		if attrs.has("level"):
			label += " (level %s)" % attrs.level
		var details: Array[String] = []
		for key in attrs:
			if key.to_lower() in ["gdd", "ref", "reference", "note", "notes"]:
				details.append(String(attrs[key]))
		var text := XmlTree.clean_text(node)
		if text != "":
			details.append(text)
		for child in XmlTree.children_named(node, "note"):
			details.append(XmlTree.clean_text(child))
		found.append(label + (": " + " · ".join(details) if not details.is_empty() else ""))
	return found


func duplicate_design() -> ShipDesign:
	var copy := ShipDesign.from_xml(to_xml())
	copy.built_in = false
	copy.source_path = ""
	return copy


func system_by_id(system_id: String) -> Dictionary:
	for system in systems:
		if system.id == system_id:
			return system
	return {}


func has_system(type: String) -> bool:
	return systems.any(func(system): return system.type == type)


## The ship's value in Mawjig, as the economy docs price a ship: its systems at their levels (the reactor
## counted bar by bar), its weapons and its battlesuits. Crew and missiles are extra (see crew_value, total_cost).
## A wreck's reward is a share of this value.
func value() -> float:
	var total := 0.0
	for system in systems:
		var prices: Array = Catalog.systems[system.type].prices
		for level in mini(system.level, prices.size()):
			total += float(prices[level])
		if system.type == "weapon":
			for weapon in system.weapons:
				total += float(weapon.price)
		elif system.type == "evb":
			total += float(Catalog.suit_kind(system.suit).price)
	return total


## What the crew are worth: each crew member's hire price plus their trained skills.
func crew_value() -> float:
	var total := 0.0
	for member in crew:
		total += member_value(member.skills)
	return total


## One crew member's hire price plus their trained skills.
static func member_value(skills: Dictionary) -> float:
	var total := float(Catalog.rule("economy", "crew"))
	for skill in CrewSkills.NAMES:
		var level := int(skills.get(skill, 0))
		if level >= 1:
			total += float(Catalog.rule("economy", "skillVeteran"))
		if level >= 2:
			total += float(Catalog.rule("economy", "skillMaster"))
	return total


## Races that don't breathe (Senti, race profile; Ship Design's G15): a crew of only them needs no Life Support.
const NO_AIR_RACES := ["Senti-GPH"]


func crew_needs_no_air() -> bool:
	return not crew.is_empty() and crew.all(func(member): return member.get("race", "") in NO_AIR_RACES)


func uses_missile_weapons() -> bool:
	return systems.any(func(system): return system.type == "weapon" and system.weapons.any(func(w): return w.uses_missile))


## A system id the design doesn't use yet, from a base such as "weapon" (weapon, weapon2, weapon3 …).
func unused_system_id(base: String) -> String:
	var id := base
	var n := 2
	while not system_by_id(id).is_empty():
		id = "%s%d" % [base, n]
		n += 1
	return id


## Everything the design costs to build: the ship, its crew, its missiles and battlesuit parts.
func total_cost() -> float:
	return value() + crew_value() + missiles * float(Catalog.rule("economy", "missile")) \
		+ suit_parts * float(Catalog.rule("economy", "suitPart"))


## Problems that stop the design from being flown, as readable sentences. Empty means it can fly.
func problems() -> Array[String]:
	var found: Array[String] = []
	for type in Catalog.systems:
		var definition: Dictionary = Catalog.systems[type]
		if definition.required and not has_system(type) and not (type == "lifeSupport" and crew_needs_no_air()):
			found.append("Needs %s." % definition.name)
	var seen_types := {}
	for system in systems:
		var definition: Dictionary = Catalog.systems[system.type]
		if system.type == "weapon":
			if system.weapons.size() > system.get("max_slots", Weapons.SLOTS_PER_SYSTEM):
				found.append("%s holds at most %d weapons." % [system.name, system.get("max_slots", Weapons.SLOTS_PER_SYSTEM)])
			for weapon in system.weapons:
				if weapon.power > definition.max_level:
					found.append("%s needs %d power, more than a weapon system can give." % [weapon.name, weapon.power])
		elif system.type == "evb":
			var suit := Catalog.suit_kind(system.suit)
			if system.level < suit.cost:
				found.append("An EVB Dock with %s needs level %d or more." % [suit.name, suit.cost])
		else:
			if seen_types.has(system.type):
				found.append("Only one %s allowed." % definition.name)
			seen_types[system.type] = true
	if not systems.any(func(system): return system.type == "weapon" and not system.weapons.is_empty() or system.type == "evb"):
		found.append("Needs a weapon or an EVB Dock to fight.")
	if crew.is_empty():
		found.append("Needs at least 1 crew member.")
	if crew.size() > 8:
		found.append("At most 8 crew.")
	if hull < 4:
		found.append("Hull must be at least 4.")
	var uses_missiles := uses_missile_weapons()
	if uses_missiles and missiles <= 0 and Ammo.missiles_use_stock():
		found.append("Torpedoes need missiles in stock (Ammo setting).")
	if has_system("evb") and suit_parts <= 0 and Ammo.suits_use_parts():
		found.append("Battlesuits need suit parts in stock (Ammo setting).")
	return found
