class_name ShipValue
extends RefCounted
## What a ship is worth, worked out from its parts by system-prices.md (Infall: Eco; heromedel, 2026-10-31): its
## structure, reactor, systems at their levels and weapons; crew are not counted. A wreck pays 2.5% of this (GDD 8I),
## and the shipyard sells by it, so it is never typed into a ship file.
##
##   structure: 2.42 a hull point; a room holding a system 10% of that system's level-1 price (its dearest system's,
##              the AZC's at 18.15, shields' for one layer); other rooms and doors 0.48 each; 6.05 a weapon mount
##              (one per weapon when a ship lists no mounts)
##   reactor:   bars at the banded per-bar prices, the AZC's levels, or 8.47 a self-powered bar (Mecha)
##   systems:   the level-1 price plus every step up to the system's level
##   weapons:   their prices

const HULL_POINT := 242
const EMPTY_ROOM := 48
const DOOR := 48
const MOUNT := 605
const SYSTEM_ROOM_PERCENT := 0.1
const SELF_POWERED_BAR := 847
## Systems whose files count a smaller step than the docs' level 1: shields are stored in bars, two to a layer, while
## the shield test (GDD 8H) prices a layer as level 1.
const DOCS_LEVEL_ONE := {"shields": 2}


static func of(design: ShipDesign) -> int:
	return structure(design) + reactor(design) + systems(design) + weapons(design)


static func structure(design: ShipDesign) -> int:
	var total := design.hull * HULL_POINT + design.doors.size() * DOOR
	for room_index in design.rooms.size():
		var dearest := -1   # a room holding several systems counts its dearest
		for system in design.systems:
			if system.room == room_index:
				dearest = maxi(dearest, _level_one_price(system.id))
		total += EMPTY_ROOM if dearest < 0 else roundi(dearest * SYSTEM_ROOM_PERCENT)
	var mounts := design.mounts_listed if design.mounts_listed > 0 else design.weapons.size()
	return total + mounts * MOUNT


static func reactor(design: ShipDesign) -> int:
	var total := 0
	match design.reactor_type:
		"pool":
			for bar in design.reactor_level:
				total += ShipOutfitter.REACTOR_BAR_PRICES[mini(bar / 5, 4)]
		"core":
			for level in design.reactor_level:
				total += ShipOutfitter.AZC_STEP_PRICES[mini(level, 4)]
		_:
			for system in design.systems:
				total += int(system.own_power) * SELF_POWERED_BAR
	return total


static func systems(design: ShipDesign) -> int:
	var total := 0
	for system in design.systems:
		var def := Library.system(system.id)
		if def == null or def.behaviour == "power_core":
			continue
		total += def.buy_price
		for level in range(1, int(system.level)):
			total += maxi(0, def.upgrade_price(level))
	return total


static func weapons(design: ShipDesign) -> int:
	var total := 0
	for entry in design.weapons:
		var def := Library.weapon(entry.id)
		if def:
			total += def.price
	return total


static func _level_one_price(system_id: String) -> int:
	var def := Library.system(system_id)
	if def == null:
		return 0
	if def.behaviour == "power_core":
		return ShipOutfitter.AZC_STEP_PRICES[0]
	var price := def.buy_price
	for level in range(1, DOCS_LEVEL_ONE.get(system_id, 1)):
		price += def.upgrade_price(level)
	return price
