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
## Pick a crew member, then a system for them (Mind Control).
const TARGET_CREW_THEN_SYSTEM := "crew_then_system"
## Teleport: your Teleport Bay then any system (send everyone in the bay there), or any other system (bring your
## crew there back to the bay). Target: { system, ship } and, when sending, { to_system, to_ship }.
const TARGET_TELEPORT := "teleport"

## Crew card ids: every crew member adds one of each.
const CREW_CARDS := ["repair"]
## Airlock Control adds this many Cycle Airlock cards at level 1, and one more per level above it.
const AIRLOCK_BASE_CARDS := 3

const FIXED_CARDS := {
	"power": {"name": "Power Cell", "cost": 0, "group": GROUP_POWER, "target": TARGET_NONE, "art": "power",
		"text": "Put into your power row. Spend it to play cards; it recharges each turn."},
	"shield": {"name": "Raise Shield", "cost": 1, "group": GROUP_DEFENSE, "target": TARGET_NONE, "art": "shield",
		"text": "Raise 1 shield layer. Its power stays under it until the layer is hit."},
	"restore": {"name": "Restore Environment", "cost": 1, "group": GROUP_CREW, "target": TARGET_NONE, "art": "restore",
		"text": "Every system that isn't breached gains 1 pip of air. Needs a working Life Support."},
	"teleport": {"name": "Teleport", "cost": 1, "group": GROUP_TACTIC, "target": TARGET_TELEPORT, "art": "teleport",
		"text": "Click your Teleport Bay, then any system on either ship: everyone of yours in the bay goes there. Or click another system: your crew there come back to the bay."},
	"cloak": {"name": "Cloak", "cost": 1, "group": GROUP_DEFENSE, "target": TARGET_NONE, "art": "cloak",
		"text": "+40% evasion until your next turn."},
	"mindControl": {"name": "Mind Control", "cost": 1, "group": GROUP_TACTIC, "target": TARGET_CREW_THEN_SYSTEM, "art": "mind",
		"text": "Send an enemy crew member to sabotage a system on their own ship. Or free one of yours."},
	"hack": {"name": "Hack", "cost": 1, "group": GROUP_TACTIC, "target": TARGET_ENEMY_SYSTEM, "art": "hack",
		"text": "The target system can't be used during the enemy's next turn."},
	"battery": {"name": "Backup Cell", "cost": 0, "group": GROUP_POWER, "target": TARGET_NONE, "art": "battery",
		"text": "+1 power this turn only."},
	"repair": {"name": "Repair", "cost": 0, "group": GROUP_CREW, "target": TARGET_OWN_SYSTEM, "art": "repair",
		"text": "Your crew here fix the worst problem first: the fire, then the breach, then the spores, then 1 damage. They stay until the turn ends."},
	"airlock": {"name": "Cycle Airlock", "cost": 1, "group": GROUP_CREW, "target": TARGET_OWN_SYSTEM, "art": "airlock",
		"text": "Needs a working Airlock Control. Vent a system: its fire goes out, its air is gone, and everyone in it takes a wound."},
}

const GROUP_NAMES := {
	GROUP_POWER: "Power", GROUP_WEAPON: "Weapon", GROUP_DEFENSE: "Defense", GROUP_CREW: "Crew", GROUP_TACTIC: "Tactic",
}


## The full definition of a card instance: fixed cards come from the table, weapon cards from their system.
## A card instance is { uid, id, system, temporary }.
static func definition(card: Dictionary, ship_systems: Dictionary) -> Dictionary:
	if card.id == "suit":
		var dock: Dictionary = ship_systems.get(card.system, {})
		var suits: Array = dock.get("suits", ["assault"])
		return suit_definition(suits[mini(int(card.get("slot", 0)), suits.size() - 1)] if not suits.is_empty() else "assault",
			int(dock.get("level", 1)))
	if card.id != "weapon":
		var fixed: Dictionary = FIXED_CARDS[card.id].duplicate()
		fixed.id = card.id
		return fixed
	var weapon := weapon_of(card, ship_systems)
	return {
		"id": "weapon", "name": weapon.name, "cost": weapon.power, "group": GROUP_WEAPON,
		"target": TARGET_ENEMY_SYSTEM, "art": Weapons.art(weapon), "weapon": weapon, "kind": weapon.kind,
		"mawjig": Ammo.weapon_mawjig(weapon), "text": Weapons.card_text(weapon),
	}


## The weapon a weapon card fires: the one in its system's slot.
static func weapon_of(card: Dictionary, ship_systems: Dictionary) -> Dictionary:
	var weapons: Array = ship_systems.get(card.system, {}).get("weapons", [])
	var slot := int(card.get("slot", 0))
	return weapons[slot] if slot < weapons.size() else Catalog.weapon("")


## A Launch card for a suit type from a dock of this level (its air is level + 1 turns).
static func suit_definition(suit_id: String, dock_level: int) -> Dictionary:
	var suit := Catalog.suit_kind(suit_id)
	var air := suit_air(dock_level)
	return {
		"id": "suit", "name": "Launch " + suit.name, "cost": suit.cost, "group": GROUP_TACTIC, "target": TARGET_NONE,
		"art": "suit", "suit": suit.id, "mawjig": Ammo.suit_mawjig(suit.id, air),
		"text": "A crew member in the dock flies it out. %s %d turns of air, then its pilot suffocates: click it to recall." % [
			suit.summary, air],
	}


## Turns of air (and ammo) a suit gets from a dock of this level.
static func suit_air(dock_level: int) -> int:
	return dock_level + 1


## The cards a ship design puts into its deck, as (card id, system id) pairs before uids are given.
static func deck_list(design: ShipDesign) -> Array:
	var entries: Array = []
	for system in design.systems:
		if system.type == "weapon":
			# Each weapon adds as many cards as its speed.
			for slot in system.weapons.size():
				for i in system.weapons[slot].speed:
					entries.append({"id": "weapon", "system": system.id, "slot": slot})
			continue
		if system.type == "evb":
			# Each suit type adds as many Launch cards as its speed.
			for slot in system.suits.size():
				for i in Catalog.suit_kind(system.suits[slot]).speed:
					entries.append({"id": "suit", "system": system.id, "slot": slot})
			continue
		if system.type == "airlock":
			for i in AIRLOCK_BASE_CARDS + system.level - 1:
				entries.append({"id": "airlock", "system": system.id})
			continue
		var system_definition: Dictionary = Catalog.systems[system.type]
		var card_id: String = system_definition.card
		if card_id == "":
			continue
		for i in system.level * system_definition.cards_per_level:
			entries.append({"id": card_id, "system": system.id})
	for member in design.crew:
		for card_id in CREW_CARDS:
			entries.append({"id": card_id, "system": ""})
	return entries


## Counts of each distinct card in a design's deck, for the designer's deck preview: [{ entry, count }].
static func deck_summary(design: ShipDesign) -> Array:
	var counts := {}
	var order: Array = []
	for entry in deck_list(design):
		# Weapon and suit cards differ by system; other cards are the same whichever system added them.
		var key: String = entry.id + ("|%s|%d" % [entry.system, entry.get("slot", 0)] if entry.id in ["weapon", "suit"] else "")
		if not counts.has(key):
			counts[key] = {"entry": entry, "count": 0}
			order.append(key)
		counts[key].count += 1
	return order.map(func(key): return counts[key])
