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
## Each system: { "id", "type", "level", and for weapons "name", "kind", "weapon_type" }.
var systems: Array = []
## Each crew member: { "name", "skill" (0 Green, 1 Trained, 2 Veteran), "station" (a system id) }.
var crew: Array = []
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
	for note_node in XmlTree.children_named(root, "note"):
		design.note = XmlTree.clean_text(note_node)
	for system_node in XmlTree.children_named(root, "system"):
		var system_attrs: Dictionary = system_node.attrs
		var type: String = system_attrs.get("type", "")
		if not Catalog.systems.has(type):
			push_warning("Ship '%s' has an unknown system type '%s'; skipped." % [design.name, type])
			continue
		var system := {"type": type, "level": int(system_attrs.get("level", 1))}
		system.id = system_attrs.get("id", type)
		if type == "weapon":
			system.kind = system_attrs.get("kind", "laser")
			system.weapon_type = int(system_attrs.get("weaponType", 1))
			system.name = system_attrs.get("name", Catalog.weapon_kind(system.kind).name)
		design.systems.append(system)
	for crew_node in XmlTree.children_named(root, "crew"):
		var crew_attrs: Dictionary = crew_node.attrs
		design.crew.append({
			"name": crew_attrs.get("name", "Crew"),
			"skill": clampi(int(crew_attrs.get("skill", 0)), 0, 2),
			"station": crew_attrs.get("station", ""),
		})
	return design


func to_xml() -> String:
	var lines: Array[String] = ['<?xml version="1.0" encoding="UTF-8"?>']
	lines.append('<ship name="%s" faction="%s" color="%s" hull="%d" missiles="%d">' % [
		XmlTree.escape(name), XmlTree.escape(faction), color, hull, missiles])
	if note != "":
		lines.append("  <note>%s</note>" % XmlTree.escape(note))
	for system in systems:
		if system.type == "weapon":
			lines.append('  <system type="weapon" id="%s" name="%s" kind="%s" weaponType="%d" level="%d"/>' % [
				XmlTree.escape(system.id), XmlTree.escape(system.name), system.kind, system.weapon_type, system.level])
		else:
			lines.append('  <system type="%s" level="%d"/>' % [system.type, system.level])
	for member in crew:
		lines.append('  <crew name="%s" skill="%d" station="%s"/>' % [
			XmlTree.escape(member.name), member.skill, XmlTree.escape(member.station)])
	lines.append("</ship>")
	return "\n".join(lines) + "\n"


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


## Design points: what the ship is worth, so two designs can be compared for a fair fight.
func points() -> int:
	var total := hull / 2 + missiles / 2
	for system in systems:
		total += int(Catalog.systems[system.type].points_per_level) * system.level
		if system.type == "weapon":
			total += system.weapon_type * 2
	for member in crew:
		total += 3 + member.skill
	return total


## Problems that stop the design from being flown, as readable sentences. Empty means it can fly.
func problems() -> Array[String]:
	var found: Array[String] = []
	for type in Catalog.systems:
		var definition: Dictionary = Catalog.systems[type]
		if definition.required and not has_system(type):
			found.append("Needs %s." % definition.name)
	var seen_types := {}
	for system in systems:
		var definition: Dictionary = Catalog.systems[system.type]
		if system.type != "weapon":
			if seen_types.has(system.type):
				found.append("Only one %s allowed." % definition.name)
			seen_types[system.type] = true
		elif system.level < system.weapon_type:
			found.append("%s needs level %d or more for Type %d." % [system.name, system.weapon_type, system.weapon_type])
	if not systems.any(func(system): return system.type == "weapon" or system.type == "evb"):
		found.append("Needs a weapon system or an EVB Dock to fight.")
	if crew.is_empty():
		found.append("Needs at least 1 crew member.")
	if crew.size() > 8:
		found.append("At most 8 crew.")
	if hull < 4:
		found.append("Hull must be at least 4.")
	var uses_missiles := systems.any(func(system): return system.type == "weapon" and system.kind == "missile")
	if uses_missiles and missiles <= 0:
		found.append("Torpedoes need missiles in stock.")
	return found
