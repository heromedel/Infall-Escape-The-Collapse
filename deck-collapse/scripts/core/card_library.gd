## Every card in the game: what it is called, what it costs, what it targets and its rules text,
## and how a ship's systems and crew build a deck from them.
class_name CardLibrary
extends RefCounted

## Card groups set the frame colour and tell the captain at a glance what a card is for.
const GROUP_POWER := "power"
const GROUP_WEAPON := "weapon"
const GROUP_DEFENSE := "defense"
const GROUP_CREW := "crew"
const GROUP_TACTIC := "tactic"

## What a card needs to be aimed at.
const TARGET_NONE := "none"
const TARGET_ENEMY_SYSTEM := "enemy_system"
const TARGET_OWN_SYSTEM := "own_system"
## Pick a crew member, then a system for them (Teleport, Mind Control).
const TARGET_CREW_THEN_SYSTEM := "crew_then_system"

## Crew card ids: every crew member adds one of each (the airlock one only with Airlock Control).
const CREW_CARDS := ["repair", "extinguish", "airlock"]

const FIXED_CARDS := {
	"power": {"name": "Power Cell", "cost": 0, "group": GROUP_POWER, "target": TARGET_NONE, "art": "power",
		"text": "Put into your power row. Spend it to play cards; it recharges each turn."},
	"shield": {"name": "Raise Shield", "cost": 1, "group": GROUP_DEFENSE, "target": TARGET_NONE, "art": "shield",
		"text": "Raise 1 shield layer. Its power stays under it until the layer is hit."},
	"jump": {"name": "Spool Jig Drive", "cost": 1, "group": GROUP_TACTIC, "target": TARGET_NONE, "art": "jump",
		"text": "Add 1 charge to the Jig Drive. Fully charged (6), you can JUMP away. Needs a working, manned Piloting."},
	"restore": {"name": "Restore Environment", "cost": 1, "group": GROUP_CREW, "target": TARGET_OWN_SYSTEM, "art": "restore",
		"text": "Seal the breach in one of your systems. Crew there recover 1 wound."},
	"teleport": {"name": "Teleport", "cost": 1, "group": GROUP_TACTIC, "target": TARGET_CREW_THEN_SYSTEM, "art": "teleport",
		"text": "Send one of your crew to any system on either ship. Boarders damage their system and the hull each enemy turn."},
	"cloak": {"name": "Cloak", "cost": 1, "group": GROUP_DEFENSE, "target": TARGET_NONE, "art": "cloak",
		"text": "+40% evasion until your next turn."},
	"mindControl": {"name": "Mind Control", "cost": 1, "group": GROUP_TACTIC, "target": TARGET_CREW_THEN_SYSTEM, "art": "mind",
		"text": "Send an enemy crew member to sabotage a system on their own ship. Or free one of yours."},
	"hack": {"name": "Hack", "cost": 1, "group": GROUP_TACTIC, "target": TARGET_ENEMY_SYSTEM, "art": "hack",
		"text": "The target system can't be used during the enemy's next turn."},
	"battery": {"name": "Backup Cell", "cost": 0, "group": GROUP_POWER, "target": TARGET_NONE, "art": "battery",
		"text": "+1 power this turn only."},
	"repair": {"name": "Repair", "cost": 0, "group": GROUP_CREW, "target": TARGET_OWN_SYSTEM, "art": "repair",
		"text": "A crew member in the system repairs 1 damage; a repair Veteran 2. A Master can act again."},
	"extinguish": {"name": "Extinguish Fire", "cost": 0, "group": GROUP_CREW, "target": TARGET_OWN_SYSTEM, "art": "extinguish",
		"text": "A crew member in the system puts out its fire."},
	"airlock": {"name": "Cycle Airlock", "cost": 0, "group": GROUP_CREW, "target": TARGET_OWN_SYSTEM, "art": "airlock",
		"text": "Needs crew in Airlock Control. Vent a system: its fire goes out and everyone in it dies."},
}

const GROUP_NAMES := {
	GROUP_POWER: "Power", GROUP_WEAPON: "Weapon", GROUP_DEFENSE: "Defense", GROUP_CREW: "Crew", GROUP_TACTIC: "Tactic",
}


## The full definition of a card instance: fixed cards come from the table, weapon cards from their system.
## A card instance is { uid, id, system, temporary }.
static func definition(card: Dictionary, ship_systems: Dictionary) -> Dictionary:
	if card.id == "suit":
		return suit_definition(ship_systems.get(card.system, {}))
	if card.id != "weapon":
		var fixed: Dictionary = FIXED_CARDS[card.id].duplicate()
		fixed.id = card.id
		return fixed
	var system: Dictionary = ship_systems.get(card.system, {})
	var kind := Catalog.weapon_kind(system.get("kind", "laser"))
	var weapon_type: int = system.get("weapon_type", 1)
	return {
		"id": "weapon", "name": system.get("name", kind.name), "cost": weapon_type, "group": GROUP_WEAPON,
		"target": TARGET_ENEMY_SYSTEM, "art": kind.id, "weapon_type": weapon_type, "kind": kind.id,
		"mawjig": Ammo.weapon_mawjig(kind.id, weapon_type),
		"text": weapon_text(kind, Catalog.weapon_profile(kind.id, weapon_type)),
	}


static func suit_definition(dock: Dictionary) -> Dictionary:
	var suit := Catalog.suit_kind(dock.get("suit", "assault"))
	var target := TARGET_ENEMY_SYSTEM if suit.action in ["shoot", "board"] else TARGET_NONE
	return {
		"id": "suit", "name": "Launch " + suit.name, "cost": suit.cost, "group": GROUP_TACTIC, "target": target,
		"art": "suit", "suit": suit.id, "mawjig": Ammo.suit_mawjig(suit.id),
		"text": "Needs crew in the dock. Out for %d turns. %s" % [suit.turns, suit.summary],
	}


static func weapon_text(kind: Dictionary, profile: Dictionary) -> String:
	var lines: Array[String] = []
	if kind.ion:
		lines.append("%d ion charge%s." % [profile.shots, "" if profile.shots == 1 else "s"])
	elif profile.shots > 1:
		lines.append("%d bolts, %d damage each." % [profile.shots, profile.damage])
	else:
		lines.append("%d damage." % profile.damage)
	lines.append(kind.summary)
	return " ".join(lines)


## The cards a ship design puts into its deck, as (card id, system id) pairs before uids are given.
static func deck_list(design: ShipDesign) -> Array:
	var entries: Array = []
	for system in design.systems:
		var system_definition: Dictionary = Catalog.systems[system.type]
		var card_id: String = system_definition.card
		if card_id == "":
			continue
		for i in system.level * system_definition.cards_per_level:
			entries.append({"id": card_id, "system": system.id})
	var has_airlock := design.has_system("airlock")
	for member in design.crew:
		for card_id in CREW_CARDS:
			if card_id == "airlock" and not has_airlock:
				continue
			entries.append({"id": card_id, "system": ""})
	return entries


## Counts of each distinct card in a design's deck, for the designer's deck preview: [{ entry, count }].
static func deck_summary(design: ShipDesign) -> Array:
	var counts := {}
	var order: Array = []
	for entry in deck_list(design):
		# Weapon and suit cards differ by system; other cards are the same whichever system added them.
		var key: String = entry.id + ("|" + entry.system if entry.id in ["weapon", "suit"] else "")
		if not counts.has(key):
			counts[key] = {"entry": entry, "count": 0}
			order.append(key)
		counts[key].count += 1
	return order.map(func(key): return counts[key])
