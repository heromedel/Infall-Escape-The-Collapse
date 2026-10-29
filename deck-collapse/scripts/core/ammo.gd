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
static func weapon_mawjig(kind_id: String, weapon_type: int) -> float:
	var kind := Catalog.weapon_kind(kind_id)
	if mode() == ALL_MAWJIG or mode() == MISSILES_MAWJIG and kind.uses_missile:
		return float(Catalog.weapon_profile(kind_id, weapon_type).get("ammo", 0.0))
	return 0.0


## Mawjig to launch one battlesuit (0 when this mode doesn't charge it).
static func suit_mawjig(suit_id: String) -> float:
	return float(Catalog.suit_kind(suit_id).get("sortie", 0.0)) if mode() == ALL_MAWJIG else 0.0
