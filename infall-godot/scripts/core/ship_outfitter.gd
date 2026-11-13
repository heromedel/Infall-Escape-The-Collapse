class_name ShipOutfitter
extends RefCounted
## Changing a ship between fights: fitting weapons to mounts, installing a system in a room (GDD 5E: the
## system goes into a room, and on a conduit ship it is joined to the conduits when installed), upgrading
## systems and the reactor or AZC, with prices from system-prices.md.

const REACTOR_BAR_PRICES := [363, 484, 605, 726, 847]     # per bar, in bands of five bars
const AZC_STEP_PRICES := [1815, 2421, 3025, 3631, 4235]   # levels 1 to 5


static func free_mounts(ship: Ship) -> Array[int]:
	var used: Array[int] = []
	for slot in ship.weapons:
		used.append(slot.mount_id)
	var free: Array[int] = []
	for mount in ship.design.mounts:
		if not used.has(mount.id):
			free.append(mount.id)
	return free


static func fit_weapon(ship: Ship, def: WeaponDef) -> bool:
	if ship.system_by("weapons") == null:
		return false
	var free := free_mounts(ship)
	if free.is_empty():
		return false
	var slot := WeaponSlot.create(def, free[0])
	ship.weapons.append(slot)
	ship.set_weapon_powered(slot, true)
	return true


static func unfit_weapon(ship: Ship, slot: WeaponSlot) -> void:
	ship.weapons.erase(slot)


const DOCKS := ["evb_dock", "eva_dock"]     # systems whose crew leave the ship in a suit, by the airlock on their tile

## Why a system may not be installed in a room, or "" when it may (Ship Designs' placement rules for a purchase):
## - a system needs a tile of its own;
## - a Medbay shares a room only with systems crew can't man, so nobody heals while manning one (GDD 5B);
## - an EVA or EVB Dock sits on a tile that has an airlock: the crew member suits up there and goes out it (GDD 5D).
static func install_refusal(ship: Ship, def: SystemDef, room_index: int) -> String:
	if room_index < 0 or room_index >= ship.rooms.size() or _free_console_cell(ship, room_index) == Vector2i(999, 999):
		return "No free tile in that room."
	var room := ship.rooms[room_index]
	for system in room.systems:
		if def.behaviour == "medbay" and system.def.manned:
			return "Crew man %s in this room, and crew can't heal while they man a system, so %s can't go here." % [system.def.name, _with_article(def.name)]
		if def.manned and system.behaviour == "medbay":
			return "This room has %s, and crew can't heal while they man a system, so %s can't go here." % [_with_article(system.def.name), def.name]
	if def.behaviour in DOCKS and _free_airlock_cell(ship, room_index) == Vector2i(999, 999):
		return "%s goes on a tile with an airlock, and this room has none free." % _with_article(def.name).capitalize()
	return ""


## A tile of the room that has an airlock and no system on it, for a dock; (999, 999) when there is none.
static func _free_airlock_cell(ship: Ship, room_index: int) -> Vector2i:
	var used := {}
	for system in ship.systems:
		used[system.cell] = true
	for door in ship.doors:
		if door.to_space and not used.has(door.cell_a) and ship.room_at(door.cell_a) == room_index:
			return door.cell_a
	return Vector2i(999, 999)


static func _with_article(name: String) -> String:
	return ("an " if name.left(1).to_lower() in ["a", "e", "i", "o", "u"] else "a ") + name


## The room a new system goes into: an empty room if there is one, else the room with the fewest systems that
## may take it. -1 when no room may.
static func room_for_new_system(ship: Ship, def: SystemDef = null) -> int:
	var best := -1
	var best_count := 99
	for room in ship.rooms:
		if _free_console_cell(ship, room.index) == Vector2i(999, 999) or (def and not install_refusal(ship, def, room.index).is_empty()):
			continue
		var count := room.systems.size()
		if count < best_count:
			best_count = count
			best = room.index
	return best


static func install_system(ship: Ship, def: SystemDef, room_index: int) -> ShipSystem:
	var cell := _free_airlock_cell(ship, room_index) if def.behaviour in DOCKS else _free_console_cell(ship, room_index)
	var system := ShipSystem.new()
	system.def = def
	system.behaviour = def.behaviour
	system.level = 2 if def.behaviour in ["shields"] else 1
	system.room = room_index
	system.cell = cell
	system.wall = _wall_for(ship, cell)
	if ship.reactor_type == "none":
		system.own_power = system.level
	ship.systems.append(system)
	ship.rooms[room_index].systems.append(system)
	_join_conduits(ship, room_index)
	return system


static func _free_console_cell(ship: Ship, room_index: int) -> Vector2i:
	var used := {}
	for system in ship.systems:
		used[system.cell] = true
	var door_cells := {}
	for door in ship.doors:
		door_cells[door.cell_a] = true
	for cell in ship.rooms[room_index].cells:
		if not used.has(cell) and not door_cells.has(cell):
			return cell
	for cell in ship.rooms[room_index].cells:
		if not used.has(cell):
			return cell
	return Vector2i(999, 999)


## A wall of the tile with no door on it, preferring the ship's outer walls.
static func _wall_for(ship: Ship, cell: Vector2i) -> String:
	var room := ship.room_at(cell)
	for wall in ["north", "west", "east", "south"]:
		var step: Vector2i = ShipDesign.DIRECTIONS[wall]
		if ship.room_at(cell + step) == room:
			continue
		var has_door := false
		for door in ship.doors:
			if (door.cell_a == cell and door.direction == step) or (door.cell_b == cell and door.direction == -step):
				has_door = true
		if not has_door:
			return wall
	return "none"


static func _join_conduits(ship: Ship, room_index: int) -> void:
	if ship.reactor_type != "core":
		return
	for cell in ship.rooms[room_index].cells:
		if ship.conduits.has(cell):
			return
	var bits := {Vector2i(0, -1): [1, 4], Vector2i(1, 0): [2, 8], Vector2i(0, 1): [4, 1], Vector2i(-1, 0): [8, 2]}
	for cell in ship.rooms[room_index].cells:
		for step in bits:
			var next: Vector2i = cell + step
			if ship.conduits.has(next) and ship.room_at(next) != room_index:
				ship.conduits[cell] = int(bits[step][0])
				ship.conduits[next] = int(ship.conduits[next]) | int(bits[step][1])
				ship.refresh_conduit_power()
				return


static func system_upgrade_price(system: ShipSystem) -> int:
	return system.def.upgrade_price(system.level)


static func upgrade_system(run: RunState, ship: Ship, system: ShipSystem) -> bool:
	var price := system_upgrade_price(system)
	if price < 0 or not run.spend(price):
		return false
	system.level += 1
	if ship.reactor_type == "none":
		system.own_power = mini(system.level, system.own_power + 1)
	return true


static func reactor_upgrade_price(ship: Ship) -> int:
	match ship.reactor_type:
		"pool":
			if ship.reactor_level >= 25:
				return -1
			return REACTOR_BAR_PRICES[mini(ship.reactor_level / 5, 4)]
		"core":
			if ship.reactor_level >= 5 or (ship.reactor_level >= 4 and ship.race.id != "terran"):
				return -1
			return AZC_STEP_PRICES[ship.reactor_level]
	return -1


static func upgrade_reactor(run: RunState, ship: Ship) -> bool:
	var price := reactor_upgrade_price(ship)
	if price < 0 or not run.spend(price):
		return false
	ship.reactor_level += 1
	return true
