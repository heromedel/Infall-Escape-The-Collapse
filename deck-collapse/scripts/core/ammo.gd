## What firing costs, by the Ammo setting: limited stocks (missiles, battlesuit parts) or Mawjig per shot.
## One place answers "what does this card cost to fire" for the rules, the cards and the AI.
class_name Ammo
extends RefCounted

const ALL_MAWJIG := "All Use Mawjig"
const CLASSIC := "Classic"
const MISSILES_ONLY := "Limited Missiles Only"
const MISSILES_MAWJIG := "Missiles Use Mawjig"


static func mode() -> String:
	return Settings.value("ammo")


## Torpedoes use the ship's missile stock.
static func missiles_use_stock() -> bool:
	return mode() in [CLASSIC, MISSILES_ONLY]


## Battlesuit launches use the ship's suit parts.
static func suits_use_parts() -> bool:
	return mode() == CLASSIC


## Mawjig to fire one card of this weapon (0 when this mode doesn't charge it).
static func weapon_mawjig(weapon: Dictionary) -> float:
	if mode() == ALL_MAWJIG or mode() == MISSILES_MAWJIG and weapon.uses_missile:
		return float(weapon.ammo)
	return 0.0


## Mawjig to launch one battlesuit for its turns of air: every shot it can fire (0 when this mode doesn't charge
## it). Never ends in a zero (mawjig-cost-table.md).
static func suit_mawjig(suit_id: String, turns: int) -> float:
	if mode() != ALL_MAWJIG:
		return 0.0
	var cents := roundi(float(Catalog.suit_kind(suit_id).get("sortie", 0.0)) * turns * 100.0)
	return (cents + (1 if cents % 10 == 0 and cents > 0 else 0)) / 100.0
