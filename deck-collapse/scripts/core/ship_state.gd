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

## System id -> { id, type, name, level, damage, on_fire, breached, vented, disabled_turns, kind, weapon_type }.
## "vented": its air was let out through the airlock; it has none until its captain's next turn.
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
## Air reserve: one pip per Life Support level. Used up while Life Support is down (see Battle._use_air).
var air := 0
var air_max := 0
## Battlesuits out: { kind (suit kind id), dock (system id), target, turns_left, ready }.
var suits: Array = []
## Temporary copies added by chain weapons: system id -> count.
var chain_copies := {}
var cards_played_this_turn := 0
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
			"on_fire": false, "breached": false, "vented": false, "disabled_turns": 0,
			"name": system.get("name", Catalog.systems[system.type].name),
		}
		if system.type == "weapon":
			state.kind = system.kind
			state.weapon_type = system.weapon_type
		elif system.type == "evb":
			state.suit = system.suit
			state.name = Catalog.suit_kind(system.suit).name + " Dock"
		systems[system.id] = state
		system_order.append(system.id)
		if system.type == "lifeSupport":
			air_max += system.level
	air = air_max


## How much power this system's cards can use this turn: its level minus damage, or 0 while disabled.
func capacity(system_id: String) -> int:
	if not systems.has(system_id):
		return 0
	var system: Dictionary = systems[system_id]
	if system.disabled_turns > 0 and system.type != "reactor":
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


func count_cards_everywhere(card_id: String) -> int:
	var total := 0
	for card in deck + hand:
		if card.id == card_id:
			total += 1
	return total
