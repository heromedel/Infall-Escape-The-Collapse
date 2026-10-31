## One ship during a battle: its hull, systems, cards and per-turn counters.
## Crew live in the Battle, not here, because they can stand on either ship.
class_name ShipState
extends RefCounted

var side := 0
var design: ShipDesign
var name := ""
var color := Color.WHITE
var hull_max := 0
var hull := 0
var missiles := 0
var suit_parts := 0
## Mawjig aboard, spent on shots and launches when the Ammo setting charges for them.
var mawjig := 0.0

## System id -> { id, type, name, level, damage, on_fire, breached, air, spored, disabled_turns }, plus "weapons"
## for a weapon system and "suits" (suit type ids) for an EVB Dock.
## "fire": pips of fire (0–4; on_fire while above 0). "air": pips of air in the system, up to air_max. "spored": overgrown, offline until a Repair clears it.
var systems := {}
## System ids in display order.
var system_order: Array = []

## Card instances are { uid, id, system, temporary }.
var deck: Array = []
var hand: Array = []
## Power cards in play: { card, flipped, held }. "held" means the power sits under a raised shield.
var power_row: Array = []
## Raised shield layers: each is the Raise Shield card instance it came from.
var shield_layers: Array = []

## Power spent on each system's cards this turn: system id -> amount.
var spent := {}
## Power from Backup Cells, lost at the end of the turn.
var temporary_power := 0
## Engine burns this turn (evasion until the captain's next turn).
var burns := 0
var cloaked := false
var cloak_streak := 0
var hacked_this_turn := false
var hack_streak := 0
var jump_charge := 0
## Most air pips a system can hold: the Life Support level (see Battle._refill_air and _use_air).
var air_max := 0
## Battlesuits out: { kind (suit kind id), dock (system id), pilot (crew id), target (the enemy system it drifts
## beside, or "" for suits that stay by their own ship), turns_left (air and ammo), recalling, ready }.
var suits: Array = []
## Temporary copies added by chain weapons: system id -> count.
var chain_copies := {}
var cards_played_this_turn := 0
## Torpedoes this ship's defensive weapons have shot down this enemy turn.
var defenses_used := 0
## The Med Bay was powered this turn (Treat): it heals everyone in it as the turn ends.
var treated := false


func _init(owner_side: int, ship_design: ShipDesign) -> void:
	side = owner_side
	design = ship_design
	name = ship_design.name
	color = Color.from_string(ship_design.color, Color.WHITE)
	hull_max = maxi(1, roundi(ship_design.hull * Settings.hull_multiplier()))
	hull = hull_max
	missiles = ship_design.missiles
	suit_parts = ship_design.suit_parts
	for system in ship_design.systems:
		var state := {
			"id": system.id, "type": system.type, "level": system.level, "damage": 0,
			"on_fire": false, "fire": 0, "breached": false, "air": 0, "spored": false, "disabled_turns": 0,
			"name": system.get("name", Catalog.systems[system.type].name),
		}
		if system.type == "weapon":
			state.weapons = system.weapons.duplicate(true)
		elif system.type == "evb":
			state.suits = system.suits.duplicate()
			state.name = "EVB Dock"
		systems[system.id] = state
		system_order.append(system.id)
		if system.type == "lifeSupport":
			air_max += system.level
	for system_id in systems:
		systems[system_id].air = air_max


## How much power this system's cards can use this turn: its level minus damage, or 0 while disabled.
func capacity(system_id: String) -> int:
	if not systems.has(system_id):
		return 0
	var system: Dictionary = systems[system_id]
	if system.disabled_turns > 0 and system.type != "reactor" or system.spored:
		return 0
	return maxi(0, system.level - system.damage)


func capacity_of_type(type: String) -> int:
	var system_id := first_system_of_type(type)
	return capacity(system_id) if system_id != "" else 0


func first_system_of_type(type: String) -> String:
	for system_id in system_order:
		if systems[system_id].type == type:
			return system_id
	return ""


func has_type(type: String) -> bool:
	return first_system_of_type(type) != ""


func is_broken(system_id: String) -> bool:
	var system: Dictionary = systems[system_id]
	return system.damage >= system.level


## Power cards beyond the reactor's working level are offline.
func online_power_cards() -> int:
	return mini(power_row.size(), capacity_of_type("reactor"))


func available_power() -> int:
	var used := 0
	for i in online_power_cards():
		if power_row[i].flipped:
			used += 1
	return maxi(0, online_power_cards() - used) + temporary_power


## Room left under a system's per-turn limit.
func system_room(system_id: String) -> int:
	return capacity(system_id) - int(spent.get(system_id, 0))


func shield_capacity() -> int:
	return capacity_of_type("shields")


func weapon_systems() -> Array:
	return system_order.filter(func(system_id): return systems[system_id].type == "weapon")


## How many working defensive weapons the ship has (each shoots down one torpedo per enemy turn).
func defensive_weapons() -> int:
	var count := 0
	for system_id in weapon_systems():
		if capacity(system_id) > 0:
			count += systems[system_id].weapons.filter(func(w): return w.defensive).size()
	return count


func uses_missile_weapons() -> bool:
	return weapon_systems().any(func(id): return systems[id].weapons.any(func(w): return w.uses_missile))


func count_cards_everywhere(card_id: String) -> int:
	var total := 0
	for card in deck + hand:
		if card.id == card_id:
			total += 1
	return total
