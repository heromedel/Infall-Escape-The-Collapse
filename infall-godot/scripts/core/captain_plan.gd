class_name CaptainPlan
extends RefCounted
## A ship's captain plan, from the <ai> block of its ship or loadout file (the format the card game version
## uses, so a plan can be copied between them). Lines say what to aim each weapon at, where to board and where
## to send a battlesuit, each with conditions and a chance; the first line whose roll succeeds is followed, and
## if none does the captain uses its own judgement. A loadout's <ai> replaces its ship's.
##
##   <ai plan="crew-kill" spareOwnCrew="false">
##     <target system="weapons" weapon="Gat 2.1 Twinshot" unless="ownCrewIn" weight="0.8"/>
##     <board system="medbay" when="enemyWounded" weight="0.6"/>
##     <suit system="shields"/>
##   </ai>

const DEFAULT_WEIGHT := 0.75
const MAX_WEIGHT := 0.9
# The card game's system names, read as this game's system behaviours
const SYSTEM_NAMES := {"weapon": "weapons", "medBay": "medbay", "lifeSupport": "oxygen", "life-support": "oxygen", "teleport": "teleporter", "evbDock": "evb_dock", "cloak": "cloaking"}
const CONDITIONS := ["always", "enemyWeaponsDown", "enemyShieldsDown", "enemyMedBayDown", "enemyLifeSupportDown", "enemyWounded", "ownBoardersAboard", "enemyBoardersAboard", "ownCrewIn"]

var plan: String = "destroy"       # destroy, or crew-kill: favour rooms with crew in them
var spare_own_crew: bool = true    # avoid firing on rooms holding our own boarders (by difficulty)
var lines: Array = []              # {kind: target|board|suit, system, weapon, when, unless, weight}
var problems: PackedStringArray = []


static func read(node: XmlTree) -> CaptainPlan:
	var result := CaptainPlan.new()
	result.plan = node.get_attr("plan", "destroy")
	result.spare_own_crew = node.get_attr("spareOwnCrew", "true") != "false"
	for child in node.children:
		if child.tag not in ["target", "board", "suit"]:
			continue
		var system := child.get_attr("system")
		var line := {
			"kind": child.tag, "system": SYSTEM_NAMES.get(system, system), "weapon": child.get_attr("weapon"),
			"when": child.get_attr("when", "always"), "unless": child.get_attr("unless", ""),
			"weight": minf(MAX_WEIGHT, child.get_float("weight", DEFAULT_WEIGHT)),
		}
		for condition in [line.when, line.unless]:
			if condition != "" and condition not in CONDITIONS:
				result.problems.append("unknown condition '%s'" % condition)
		result.lines.append(line)
	return result


## The plan's chance for a line at a difficulty: Easy captains follow their plans half as often, Hard ones more.
static func chance(weight: float, difficulty: String) -> float:
	match difficulty:
		"Easy":
			return weight * 0.5
		"Hard":
			return minf(MAX_WEIGHT, weight + 0.1)
	return weight


## Whether a line names this weapon (by id or by name, quotes and case ignored), or names none.
static func names_weapon(line: Dictionary, weapon: WeaponDef) -> bool:
	if String(line.weapon).is_empty():
		return true
	var wanted := String(line.weapon).replace("\"", "").to_lower()
	if wanted == weapon.id.to_lower() or wanted.replace(" ", "-") == weapon.id.to_lower():
		return true
	return wanted == weapon.display_name().replace("\"", "").to_lower() or wanted == weapon.name.to_lower()
