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
## an EVB Dock has "suits": the suit type ids it holds (up to 4).
var systems: Array = []
## Each crew member: { "name", "skills" (see CrewSkills), "station" (a system id) }.
var crew: Array = []
## The enemy captain's plan for this ship (see BattleAI): { plan: "destroy" | "crew-kill", targets: [{ system,
## weapon, when, weight }] }. Empty targets: the captain plays as usual.
var ai := {"plan": "destroy", "targets": []}
## Parts of the ship file this game doesn't support yet (systems it doesn't know, floor plans and so on), kept as
## XML nodes so saving the design writes them back unchanged. See unsupported_parts().
var unsupported: Array = []
## Where the design was loaded from, so saving a user design overwrites the same file.
var source_path := ""
var built_in := false
## The difficulty bands this ship turns up in as an enemy, e.g. [1, 3] (default all).
var bands: Array = [1, Weapons.MAX_BAND]


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
	var band_range := String(attrs.get("bands", "1-%d" % Weapons.MAX_BAND)).split("-")
	design.bands = [int(band_range[0]), int(band_range[band_range.size() - 1])]
	for note_node in XmlTree.children_named(root, "note"):
		design.note = XmlTree.clean_text(note_node)
	var power_nodes := XmlTree.children_named(root, "power")
	for ai_node in XmlTree.children_named(root, "ai"):
		design.ai = {"plan": ai_node.attrs.get("plan", "destroy"), "targets": XmlTree.children_named(ai_node, "target").map(
			func(n): return {"system": n.attrs.get("system", ""), "weapon": n.attrs.get("weapon", ""),
				"when": n.attrs.get("when", "always"), "weight": _plan_line_weight(n.attrs, design.name)})}
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
			# Suit types as <suit ref="assault"/> children; an older file names one with suit="...".
			system.suits = XmlTree.children_named(system_node, "suit").map(func(n): return n.attrs.get("ref", n.attrs.get("id", "")))
			if system.suits.is_empty() and system_attrs.has("suit"):
				system.suits = [system_attrs.suit]
			system.suits = system.suits.filter(func(id): return Catalog.suit_kinds.has(id))
		design.systems.append(system)
	for node in root.children:
		if not node.name in ["note", "system", "crew", "power", "ai"]:
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
## about the power it would give: pool its level; AZC 5 bars per level (race-profiles.md, Terrans, Conversion);
## self the systems' own power; crew bars per crew member. Any kind but pool is kept in the file, so a saved design has
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
			level = 5 * int(power_node.attrs.get("level", 1))
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


## A plan line's weight from its file, lowered to the most a line may have (with a warning) if set higher.
static func _plan_line_weight(attrs: Dictionary, ship_name: String) -> float:
	var weight := float(attrs.get("weight", BattleAI.DEFAULT_PLAN_WEIGHT))
	if weight > BattleAI.MAX_PLAN_WEIGHT:
		push_warning("%s: a plan line's weight %s is lowered to %s." % [ship_name, weight, BattleAI.MAX_PLAN_WEIGHT])
	return minf(weight, BattleAI.MAX_PLAN_WEIGHT)


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


## A loadout (GDD 5J; Ship Design's G18): a patch of a base ship. Its attributes replace the ship's; <power> replaces
## the power; each <system> matches the base's by id, else by type, and changes it (removed="true" drops it, child
## weapons or suits replace the base's) or is added; <crew> with <member>s replaces the crew whole.
static func from_loadout(loadout: Dictionary, base: ShipDesign) -> ShipDesign:
	var root := XmlTree.parse(base.to_xml())
	for key in loadout.attrs:
		if not key in ["ship", "inherit"]:
			root.attrs[key] = loadout.attrs[key]
	var children: Array = root.children
	var power_patch := XmlTree.children_named(loadout, "power")
	if not power_patch.is_empty():
		children = children.filter(func(n): return n.name != "power" and not (n.name == "system" and n.attrs.get("type", "") == "reactor"))
		children.append(power_patch[0])
	for patch in XmlTree.children_named(loadout, "system"):
		var target := _matching_system(children, patch)
		if patch.attrs.get("removed", "false") == "true":
			children.erase(target)
		elif target.is_empty():
			children.append(patch)
		else:
			for key in patch.attrs:
				target.attrs[key] = patch.attrs[key]
			if not patch.children.is_empty():
				target.children = patch.children
	for ai_patch in XmlTree.children_named(loadout, "ai"):
		children = children.filter(func(n): return n.name != "ai")
		children.append(ai_patch)
	for crew_patch in XmlTree.children_named(loadout, "crew"):
		var members := XmlTree.children_named(crew_patch, "member")
		if not members.is_empty():
			children = children.filter(func(n): return n.name != "crew")
			for member in members:
				children.append({"name": "crew", "attrs": member.attrs, "text": "", "children": []})
	root.children = children
	return from_xml(XmlTree.to_xml(root, 0))


static func _matching_system(children: Array, patch: Dictionary) -> Dictionary:
	for node in children:
		if node.name != "system":
			continue
		if patch.attrs.has("id"):
			if node.attrs.get("id", node.attrs.get("type", "")) == patch.attrs.id:
				return node
		elif node.attrs.get("type", "") == patch.attrs.get("type", "") and not node.attrs.has("id"):
			return node
	if not patch.attrs.has("id"):
		for node in children:
			if node.name == "system" and node.attrs.get("type", "") == patch.attrs.get("type", ""):
				return node
	return {}


func to_xml() -> String:
	var lines: Array[String] = ['<?xml version="1.0" encoding="UTF-8"?>']
	var band_text := "" if bands == [1, Weapons.MAX_BAND] else ' bands="%d-%d"' % bands
	lines.append('<ship name="%s" faction="%s" color="%s" hull="%d" missiles="%d" suitParts="%d"%s>' % [
		XmlTree.escape(name), XmlTree.escape(faction), color, hull, missiles, suit_parts, band_text])
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
			lines.append('  <system type="evb" id="%s" level="%d">' % [XmlTree.escape(system.id), system.level])
			for suit_id in system.suits:
				lines.append('    <suit ref="%s"/>' % suit_id)
			lines.append("  </system>")
		else:
			lines.append('  <system type="%s" level="%d"/>' % [system.type, system.level])
	for member in crew:
		var skills := CrewSkills.to_attributes(member.skills)
		var race: String = member.get("race", "")
		lines.append('  <crew name="%s"%s station="%s"%s/>' % [XmlTree.escape(member.name),
			"" if race == "" else ' race="%s"' % XmlTree.escape(race), XmlTree.escape(member.station),
			"" if skills == "" else " " + skills])
	if ai.plan != "destroy" or not ai.targets.is_empty():
		lines.append('  <ai plan="%s">' % ai.plan)
		for line in ai.targets:
			var parts: Array[String] = ['system="%s"' % line.system]
			if line.when != "always":
				parts.append('when="%s"' % line.when)
			if line.weapon != "":
				parts.append('weapon="%s"' % XmlTree.escape(line.weapon))
			parts.append('weight="%s"' % str(line.weight))
			lines.append("    <target %s/>" % " ".join(parts))
		lines.append("  </ai>")
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
			for suit_id in system.suits:
				total += float(Catalog.suit_kind(suit_id).price)
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


func in_band(band: int) -> bool:
	return band >= int(bands[0]) and band <= int(bands[1])


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
			if system.suits.size() > Weapons.SLOTS_PER_SYSTEM:
				found.append("An EVB Dock holds at most %d suit types." % Weapons.SLOTS_PER_SYSTEM)
			for suit_id in system.suits:
				var suit := Catalog.suit_kind(suit_id)
				if suit.cost > definition.max_level:
					found.append("%s needs %d power, more than an EVB Dock can give." % [suit.name, suit.cost])
		else:
			if seen_types.has(system.type):
				found.append("Only one %s allowed." % definition.name)
			seen_types[system.type] = true
	if not systems.any(func(system): return system.type == "weapon" and not system.weapons.is_empty() or system.type == "evb" and not system.suits.is_empty()):
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
