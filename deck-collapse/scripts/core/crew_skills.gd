## Crew skills, as in the genre: six skills, each untrained, Veteran or Master.
## A crew member manning a system uses the skill that system needs; Repair and Combat apply wherever they are.
class_name CrewSkills
extends RefCounted

const NAMES := ["piloting", "engines", "shields", "weapons", "repair", "combat"]
const LABELS := {"piloting": "Piloting", "engines": "Engines", "shields": "Shields", "weapons": "Weapons",
	"repair": "Repair", "combat": "Combat"}
const LEVEL_NAMES := ["Untrained", "Veteran", "Master"]
const MAX_LEVEL := 2
## Which skill a crew member uses when manning each system type.
const FOR_SYSTEM := {"piloting": "piloting", "engines": "engines", "shields": "shields", "weapon": "weapons", "evb": "weapons"}


static func empty() -> Dictionary:
	var skills := {}
	for skill in NAMES:
		skills[skill] = 0
	return skills


## Reads skills from a crew element's attributes, e.g. piloting="2" weapons="1".
static func from_attributes(attrs: Dictionary) -> Dictionary:
	var skills := empty()
	for skill in NAMES:
		skills[skill] = clampi(int(attrs.get(skill, 0)), 0, MAX_LEVEL)
	return skills


## The attribute text for a crew element, listing only trained skills.
static func to_attributes(skills: Dictionary) -> String:
	var parts: Array[String] = []
	for skill in NAMES:
		if int(skills.get(skill, 0)) > 0:
			parts.append('%s="%d"' % [skill, skills[skill]])
	return " ".join(parts)


static func level(skills: Dictionary, system_type: String) -> int:
	var skill: String = FOR_SYSTEM.get(system_type, "")
	return int(skills.get(skill, 0)) if skill != "" else 0


static func total(skills: Dictionary) -> int:
	var sum := 0
	for skill in NAMES:
		sum += int(skills.get(skill, 0))
	return sum


## "Piloting Master, Repair Veteran", or "Untrained".
static func summary(skills: Dictionary) -> String:
	var parts: Array[String] = []
	for skill in NAMES:
		var value := int(skills.get(skill, 0))
		if value > 0:
			parts.append("%s %s" % [LABELS[skill], LEVEL_NAMES[value]])
	return ", ".join(parts) if not parts.is_empty() else "Untrained"
