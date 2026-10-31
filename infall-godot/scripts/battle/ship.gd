class_name Ship
extends RefCounted
## One ship in play, from the start of the run until it is lost: its hull, systems, power, weapons, rooms,
## air, fires and crew. A ship changes its own state and returns; the encounter it is in decides what hits it
## and the screen draws it (coding rule 8).
##
## Three power models share this code (GDD 7E, race profiles):
##   pool - a reactor of bars the captain hands out (the genre's default; the Azurethea and Tentauri)
##   core - the Terran AZC: any system joined to it by unbroken conduits has full power, and the core's level
##          sets how many power-hungry systems run at once
##   none - Mecha: each system carries its own bars, and an integrated Mecha adds one

const TICKS := 20
const EVASION_BY_ENGINE_POWER := [0, 5, 10, 15, 20, 25, 28, 31, 35]
const SHIELD_LAYER_TICKS := 40      # 2 s to raise a layer
const DOOR_HEALTH_PER_LEVEL := 100.0
const REPAIR_PER_TICK := 0.91       # 100 points is one bar: 5.5 s for one crew member
const EXTINGUISH_PER_TICK := 1.5
const PATCH_PER_TICK := 0.75
const CONDUIT_REPAIR_PER_TICK := 1.0
const SUFFOCATION_PER_TICK := 0.3   # 6 health a second with no air
const FIRE_BURN_PER_TICK := 0.15
const JUMP_FULL := 1.0
const CONSOLE_ORDER := ["piloting", "weapons", "shields", "engines", "evb_dock", "teleporter", "doors", "sensors", "oxygen", "medbay"]

var design: ShipDesign
var name: String
var side: int = 0
var race: RaceDef
var tech: String = "mechanical"
var faction: String = ""
var hull: int = 30
var max_hull: int = 30
var reactor_type: String = "pool"
var reactor_level: int = 8
var rooms: Array[ShipRoom] = []
var systems: Array[ShipSystem] = []
var doors: Array[ShipDoor] = []
var weapons: Array[WeaponSlot] = []
var suits: Array[String] = []
var crew: Array[CrewMember] = []    # this ship's own crew, wherever they are
var conduits: Dictionary = {}       # Vector2i -> direction mask
var broken_conduits: Dictionary = {} # Vector2i -> repair still needed, 0 to 100
var powered_conduits: Dictionary = {} # Vector2i -> true when it carries power right now
var links: Dictionary = {}          # Vector2i -> Array of {cell, door}
var core_cell := Vector2i(999, 999)
var core_capacity_penalty: int = 0  # an ion storm or other hazard taking core capacity
var reactor_penalty: int = 0

# Fight state
var world_position := Vector2.ZERO
var facing_down: bool = false
var shield_layers: int = 0
var shield_progress: float = 0.0
var supershield: int = 0
var supershield_progress: float = 0.0
var jump_charge: float = 0.0
var cloak_ticks: int = 0
var cloak_cooldown: int = 0
var teleporter_cooldown: int = 0
var evb_cooldown: int = 0
var suit_out: bool = false
var destroyed: bool = false
var escaped: bool = false
var surrendered: bool = false
var crew_dead: bool = false
var charging_escape: bool = false
var hit_flash: int = 0
var explosion_ticks: int = 0
var event_sink: Callable            # Encounter.note: what happened, for the screen and the log


## Builds a fresh ship from a design, with its starting crew.
static func from_design(ship_design: ShipDesign, ship_side: int, rng: RandomNumberGenerator, conduits_on: bool = true) -> Ship:
	var ship := Ship.new()
	ship.design = ship_design
	ship.name = ship_design.name
	ship.side = ship_side
	ship.race = Library.race(ship_design.race)
	ship.tech = ship.race.tech
	ship.faction = ship_design.faction
	ship.hull = ship_design.hull
	ship.max_hull = ship_design.hull
	ship.reactor_type = ship_design.reactor_type
	ship.reactor_level = ship_design.reactor_level
	if ship.reactor_type == "core" and not conduits_on:
		# Terran Ship Conduits: Off - each AZC level becomes 5 bars (race profiles, Terrans 6).
		ship.reactor_type = "pool"
		ship.reactor_level = ship_design.reactor_level * 5
	ship._build_layout()
	for entry in ship_design.weapons:
		var weapon_def := Library.weapon(entry.id)
		if weapon_def:
			ship.weapons.append(WeaponSlot.create(weapon_def, entry.mount))
	ship.suits.assign(ship_design.suits)
	var taken: Array = []
	for entry in ship_design.crew:
		var crew_race := Library.race(entry.race)
		var crew_name: String = entry.name if not entry.name.is_empty() else crew_race.random_name(rng, taken)
		taken.append(crew_name)
		var member := CrewMember.create(crew_race, crew_name)
		member.station_preference = entry.station
		ship.add_crew(member)
	ship.assign_stations()
	ship.power_everything()
	return ship


func _build_layout() -> void:
	rooms.clear()
	for index in design.rooms.size():
		var room := ShipRoom.new()
		room.index = index
		room.name = design.rooms[index].name
		room.cells.assign(design.rooms[index].cells)
		room.rect = design.rooms[index].rect
		rooms.append(room)
	if systems.is_empty():
		for entry in design.systems:
			var def := Library.system(entry.id)
			if def == null or entry.room < 0:
				continue
			var system := ShipSystem.new()
			system.def = def
			system.behaviour = def.behaviour
			system.label = entry.label
			system.level = entry.level
			system.own_power = entry.own_power
			system.room = entry.room
			system.cell = entry.cell
			system.wall = entry.wall
			systems.append(system)
	for system in systems:
		rooms[system.room].systems.append(system)
		if system.behaviour == "power_core":
			core_cell = system.cell
	doors.clear()
	for entry in design.doors:
		var door := ShipDoor.new()
		door.id = entry.id
		door.cell_a = entry.a
		door.cell_b = entry.b
		door.direction = entry.direction
		door.to_space = entry.to_space
		doors.append(door)
	conduits = design.conduits.duplicate()
	_build_links()
	_find_neighbour_rooms()


func _build_links() -> void:
	links.clear()
	for room in rooms:
		for cell in room.cells:
			var list: Array = []
			for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if room.has_cell(cell + step):
					list.append({"cell": cell + step, "door": null})
			links[cell] = list
	for door in doors:
		if door.to_space:
			continue
		links[door.cell_a].append({"cell": door.cell_b, "door": door})
		links[door.cell_b].append({"cell": door.cell_a, "door": door})


func _find_neighbour_rooms() -> void:
	for room in rooms:
		room.neighbours.clear()
	for room in rooms:
		for cell in room.cells:
			for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var other: int = design.cell_room.get(cell + step, -1)
				if other >= 0 and other != room.index and not room.neighbours.has(other):
					room.neighbours.append(other)


func add_crew(member: CrewMember) -> void:
	member.home = self
	member.ship = self
	member.side = side
	crew.append(member)


## Gives every crew member a station: the system their file named if it is free, otherwise the most important
## system nobody holds yet. Several crew can share a room as long as each has a console.
func assign_stations() -> void:
	var taken: Array[ShipSystem] = []
	for member in crew:
		var system: ShipSystem = null
		if not member.station_preference.is_empty():
			system = system_by(member.station_preference)
		if member.station_room >= 0 and member.station_room < rooms.size() and system == null:
			continue
		if system == null or taken.has(system):
			system = null
			for candidate in CONSOLE_ORDER:
				var found := system_by(candidate)
				if found and not taken.has(found):
					system = found
					break
		if system:
			taken.append(system)
			member.station_room = system.room
			member.station_preference = system.behaviour
		elif member.station_room < 0:
			member.station_room = 0


## Puts every crew member who is aboard at their station, on a free tile. Used when a fight or a cluster starts.
func place_crew_at_stations() -> void:
	for member in crew:
		if member.dead or member.ship != self:
			continue
		member.path.clear()
		var cell := free_cell_in_room(member.station_room, member.side, member)
		member.cell = cell
		member.destination = cell
		member.position = design.cell_centre(cell)
		member.previous_position = member.position


# --- Queries -------------------------------------------------------------------------------------------------

func system_by(behaviour: String) -> ShipSystem:
	for system in systems:
		if system.behaviour == behaviour:
			return system
	return null


func system_by_id(system_id: String) -> ShipSystem:
	for system in systems:
		if system.def.id == system_id:
			return system
	return null


func has_system(behaviour: String) -> bool:
	return system_by(behaviour) != null


func room_at(cell: Vector2i) -> int:
	return design.cell_room.get(cell, -1)


func is_gone() -> bool:
	return destroyed or escaped or crew_dead


func is_enemy() -> bool:
	return side == 1


func crew_aboard(of_side: int = -1) -> Array[CrewMember]:
	var found: Array[CrewMember] = []
	for member in _everyone_aboard():
		if of_side < 0 or member.side == of_side:
			found.append(member)
	return found


## Everyone standing on this ship: its own crew at home and boarders. The encounter fills `visitors`.
var visitors: Array[CrewMember] = []


func _everyone_aboard() -> Array[CrewMember]:
	var found: Array[CrewMember] = []
	for member in crew:
		if member.ship == self and member.is_active():
			found.append(member)
	for member in visitors:
		if member.ship == self and member.is_active():
			found.append(member)
	return found


## Everyone on this ship who is ticking: including crew still arriving by teleporter.
func crew_present() -> Array[CrewMember]:
	var found: Array[CrewMember] = []
	for member in crew + visitors:
		if member.ship == self and not member.dead and not member.in_suit:
			found.append(member)
	return found


func crew_in_room(room_index: int, of_side: int = -1) -> Array[CrewMember]:
	var found: Array[CrewMember] = []
	for member in _everyone_aboard():
		if (of_side < 0 or member.side == of_side) and room_at(member.cell) == room_index:
			found.append(member)
	return found


func living_crew_count() -> int:
	var count := 0
	for member in crew:
		if not member.dead:
			count += 1
	return count


func cell_is_claimed(cell: Vector2i, of_side: int, ignore: CrewMember = null) -> bool:
	for member in _everyone_aboard():
		if member == ignore or member.side != of_side:
			continue
		if member.destination == cell or (member.path.is_empty() and member.cell == cell):
			return true
	return false


## A free tile in a room for a crew member of a side: a system console first, then any tile.
func free_cell_in_room(room_index: int, of_side: int, member: CrewMember = null) -> Vector2i:
	var room := rooms[room_index]
	if member and member.home == self:
		var own := system_by(member.station_preference)
		if own and own.room == room_index and not cell_is_claimed(own.cell, of_side, member):
			return own.cell
	var consoles: Array = room.systems.duplicate()
	consoles.sort_custom(func(a, b): return _console_rank(a) < _console_rank(b))
	for system in consoles:
		if system.behaviour != "power_core" and system.def.manned and not cell_is_claimed(system.cell, of_side, member):
			return system.cell
	for cell in room.cells:
		if not cell_is_claimed(cell, of_side, member):
			return cell
	return room.cells[0]


func _console_rank(system: ShipSystem) -> int:
	var rank := CONSOLE_ORDER.find(system.behaviour)
	return rank if rank >= 0 else 99


func room_has_space(room_index: int, of_side: int, member: CrewMember = null) -> bool:
	for cell in rooms[room_index].cells:
		if not cell_is_claimed(cell, of_side, member):
			return true
	return false


# --- Power ---------------------------------------------------------------------------------------------------

## The power a system works at right now, whatever the ship's power model.
func system_power(system: ShipSystem) -> int:
	if system == null or system.spored:
		return 0
	var usable := system.usable_bars() - system.ion
	if usable <= 0:
		return 0
	var bars := 0
	match reactor_type:
		"pool":
			if system.behaviour == "weapons":
				bars = mini(usable, powered_weapon_load())
			elif system.def.draws_power:
				bars = mini(usable, system.power)
			else:
				bars = usable
		"core":
			if system_connected(system) and (system.enabled or not system.def.draws_power):
				bars = usable
		_:
			bars = mini(usable, system.own_power)
	if system.integration_bar:
		bars = mini(usable, bars + 1)
	return bars


func powered_weapon_load() -> int:
	var load := 0
	for slot in weapons:
		if slot.powered:
			load += slot.def.power
	return load


## Bars the weapons can draw on: what the weapons system can carry.
func weapon_capacity() -> int:
	var system := system_by("weapons")
	if system == null or system.spored:
		return 0
	var usable := system.usable_bars() - system.ion
	match reactor_type:
		"pool":
			return maxi(0, usable)
		_:
			# Core and self-powered ships: the system's own working power (an integrated Mecha adds one)
			var saved := system.power
			var bars := system_power_without_weapons(system)
			system.power = saved
			return bars


func system_power_without_weapons(system: ShipSystem) -> int:
	var usable := system.usable_bars() - system.ion
	if usable <= 0:
		return 0
	var bars := 0
	if reactor_type == "core":
		bars = usable if system_connected(system) and system.enabled else 0
	else:
		bars = mini(usable, system.own_power)
	if system.integration_bar:
		bars = mini(usable, bars + 1)
	return bars


func reactor_total() -> int:
	return maxi(0, reactor_level - reactor_penalty)


func reactor_used() -> int:
	var used := 0
	for system in systems:
		if not system.def.draws_power:
			continue
		if system.behaviour == "weapons":
			used += powered_weapon_load()
		else:
			used += system.power
	return used


func reactor_free() -> int:
	return reactor_total() - reactor_used()


## How many power-hungry systems the AZC runs at once (2 per level).
func core_capacity() -> int:
	return maxi(0, reactor_level * 2 - core_capacity_penalty)


func core_load() -> int:
	var load := 0
	for system in systems:
		if system.def.draws_power and system.enabled:
			load += 1
	return load


func system_connected(system: ShipSystem) -> bool:
	if reactor_type != "core":
		return true
	for cell in rooms[system.room].cells:
		if powered_conduits.has(cell):
			return true
	return false


## Walks the conduits out from the AZC through unbroken tiles; two tiles join only where each runs to the other.
func refresh_conduit_power() -> void:
	powered_conduits.clear()
	if reactor_type != "core" or not conduits.has(core_cell):
		return
	var bits := {Vector2i(0, -1): [1, 4], Vector2i(1, 0): [2, 8], Vector2i(0, 1): [4, 1], Vector2i(-1, 0): [8, 2]}
	var todo: Array[Vector2i] = [core_cell]
	powered_conduits[core_cell] = true
	while not todo.is_empty():
		var cell: Vector2i = todo.pop_back()
		var mask: int = conduits[cell]
		for step in bits:
			var next: Vector2i = cell + step
			if powered_conduits.has(next) or not conduits.has(next) or broken_conduits.has(next):
				continue
			if mask & bits[step][0] and conduits[next] & bits[step][1]:
				powered_conduits[next] = true
				todo.append(next)


func can_add_power(system: ShipSystem) -> bool:
	if system == null or not system.def.draws_power:
		return false
	match reactor_type:
		"pool":
			if system.behaviour == "weapons":
				return _next_unpowered_weapon() != null
			return system.power < system.usable_bars() - system.ion and reactor_free() > 0
		"core":
			return not system.enabled and core_load() < core_capacity()
	return false


func add_power(system: ShipSystem) -> bool:
	if not can_add_power(system):
		return false
	match reactor_type:
		"pool":
			if system.behaviour == "weapons":
				return set_weapon_powered(_next_unpowered_weapon(), true)
			system.power += 1
		"core":
			system.enabled = true
	return true


func remove_power(system: ShipSystem) -> bool:
	if system == null or not system.def.draws_power:
		return false
	match reactor_type:
		"pool":
			if system.behaviour == "weapons":
				for index in range(weapons.size() - 1, -1, -1):
					if weapons[index].powered:
						return set_weapon_powered(weapons[index], false)
				return false
			if system.power <= 0:
				return false
			system.power -= 1
		"core":
			if not system.enabled:
				return false
			system.enabled = false
	return true


func _next_unpowered_weapon() -> WeaponSlot:
	for slot in weapons:
		if not slot.powered and _weapon_fits(slot):
			return slot
	return null


func _weapon_fits(slot: WeaponSlot) -> bool:
	if slot.def.type == "suit":
		return false
	var capacity := weapon_capacity()
	if reactor_type == "pool":
		var system := system_by("weapons")
		if system == null:
			return false
		capacity = system.usable_bars() - system.ion
		if reactor_free() < slot.def.power:
			return false
	return powered_weapon_load() + slot.def.power <= capacity


func set_weapon_powered(slot: WeaponSlot, on: bool) -> bool:
	if slot == null:
		return false
	if on == slot.powered:
		return true
	if on and not _weapon_fits(slot):
		return false
	slot.powered = on
	if not on:
		slot.charge = minf(slot.charge, slot.charge * 0.5)
	return true


## Hands out power at the start of a fight: everything that fits, weapons last.
func power_everything() -> void:
	refresh_conduit_power()
	var order := systems.duplicate()
	order.sort_custom(func(a, b): return a.def.order < b.def.order)
	if reactor_type == "core":
		for system in order:
			system.enabled = false
		for behaviour in ["shields", "engines", "weapons", "oxygen", "medbay", "teleporter", "evb_dock", "supershield", "cloaking"]:
			var system := system_by(behaviour)
			if system and system.def.draws_power and core_load() < core_capacity():
				system.enabled = true
	elif reactor_type == "pool":
		for behaviour in ["shields", "engines", "supershield", "oxygen", "weapons", "medbay", "teleporter", "evb_dock", "cloaking"]:
			var system := system_by(behaviour)
			if system == null or system.behaviour == "weapons":
				continue
			while can_add_power(system):
				add_power(system)
	for slot in weapons:
		set_weapon_powered(slot, true)


## Takes power back from systems that can no longer hold it (damage, ion, a lost conduit path).
func settle_power() -> void:
	if reactor_type == "pool":
		for system in systems:
			if system.def.draws_power and system.behaviour != "weapons":
				system.power = clampi(system.power, 0, maxi(0, system.usable_bars() - system.ion))
		while reactor_used() > reactor_total():
			var dropped := false
			for system in systems:
				if system.def.draws_power and system.behaviour != "weapons" and system.power > 0:
					system.power -= 1
					dropped = true
					break
			if not dropped:
				break
	var capacity := weapon_capacity()
	if reactor_type == "pool":
		capacity = mini(capacity, powered_weapon_load() + reactor_free())
	for index in range(weapons.size() - 1, -1, -1):
		if powered_weapon_load() <= capacity:
			break
		if weapons[index].powered:
			weapons[index].powered = false


# --- Combat numbers -------------------------------------------------------------------------------------------

func is_cloaked() -> bool:
	return cloak_ticks > 0


func evasion() -> int:
	var engines := system_by("engines")
	var piloting := system_by("piloting")
	if engines == null or piloting == null:
		return 0
	var engine_power := system_power(engines)
	var pilot_power := system_power(piloting)
	if engine_power <= 0 or pilot_power <= 0:
		return 0
	var value := float(EVASION_BY_ENGINE_POWER[mini(engine_power, 8)])
	var pilot := piloting.manned_by
	if pilot:
		value += [5, 7, 10][pilot.skill_level("piloting")]
	else:
		value *= [0.0, 0.0, 0.5, 0.8][mini(pilot_power, 3)]
	if engines.manned_by:
		value += [5, 7, 10][engines.manned_by.skill_level("engines")]
	if is_cloaked():
		value += 60
	return clampi(int(value), 0, 95)


func max_shield_layers() -> int:
	return system_power(system_by("shields")) / 2


func can_charge_jump() -> bool:
	var engines := system_by("engines")
	var piloting := system_by("piloting")
	if engines == null or piloting == null:
		return false
	if system_power(engines) <= 0 or system_power(piloting) <= 0:
		return false
	return piloting.manned_by != null or system_power(piloting) >= 2


func jump_ready() -> bool:
	return jump_charge >= JUMP_FULL


func sensor_level() -> int:
	return system_power(system_by("sensors"))


# --- Each tick ----------------------------------------------------------------------------------------------

## Advances everything inside the ship by one tick. `in_fight` is false at a quiet cluster, where the jump
## drive is ready at once and there is nothing to dodge.
func tick(in_fight: bool, rng: RandomNumberGenerator) -> void:
	if destroyed:
		explosion_ticks += 1
		return
	if hit_flash > 0:
		hit_flash -= 1
	for system in systems:
		system.tick_ion()
	refresh_conduit_power()
	settle_power()
	_tick_manning()
	_tick_shields()
	_tick_supershield()
	_tick_jump_drive(in_fight)
	_tick_cooldowns()
	_tick_air()
	_tick_fires(rng)
	_tick_infection(rng)
	_tick_doors()


func _tick_manning() -> void:
	for system in systems:
		system.manned_by = null
		system.manned_count = 0
		system.integration_bar = false
	for member in crew_aboard(side):
		if not member.can_act() or member.is_moving() or member.task in ["fighting", "repairing", "extinguishing", "patching"]:
			member.integrate_ticks = 0
			continue
		var room_index := room_at(member.cell)
		if room_index < 0:
			continue
		var manned_here := 0
		for system in rooms[room_index].systems:
			if not system.def.manned and not (member.race.integrates and system.behaviour != "power_core"):
				continue
			var at_console: bool = member.cell == system.cell
			if not at_console and member.race.systems_at_once <= 1:
				continue
			if manned_here >= member.race.systems_at_once or system.manned_by != null:
				continue
			system.manned_by = member
			system.manned_count += 1
			manned_here += 1
			member.task = "manning"
			if member.race.integrates and at_console:
				member.integrate_ticks += 1
				var needed: int = 40 if tech == "mechanical" else 80
				if member.integrate_ticks >= needed:
					system.integration_bar = true


func _tick_shields() -> void:
	var shields := system_by("shields")
	var max_layers := max_shield_layers()
	if shield_layers > max_layers:
		shield_layers = max_layers
	if shields == null or shield_layers >= max_layers:
		shield_progress = 0.0
		return
	var rate := 1.0
	if shields.manned_by:
		rate += [0.1, 0.2, 0.3][shields.manned_by.skill_level("shields")]
	shield_progress += rate
	if shield_progress >= SHIELD_LAYER_TICKS:
		shield_progress = 0.0
		shield_layers += 1


func _tick_supershield() -> void:
	var generator := system_by("supershield")
	if generator == null:
		return
	var bars := system_power(generator)
	if bars <= 0 or supershield >= 5:
		supershield_progress = 0.0
		return
	supershield_progress += 1.0
	var needed: float = [400.0, 400.0, 300.0, 200.0][mini(bars, 3)]
	if supershield_progress >= needed:
		supershield_progress = 0.0
		supershield += 1


func _tick_jump_drive(in_fight: bool) -> void:
	if not can_charge_jump():
		return
	if not in_fight:
		jump_charge = JUMP_FULL
		return
	var engines_power := system_power(system_by("engines"))
	jump_charge = minf(JUMP_FULL, jump_charge + 0.0006 + 0.00025 * engines_power)


func _tick_cooldowns() -> void:
	if cloak_ticks > 0:
		cloak_ticks -= 1
		if cloak_ticks == 0:
			cloak_cooldown = 400
	elif cloak_cooldown > 0:
		cloak_cooldown -= 1
	var teleporter := system_by("teleporter")
	if teleporter_cooldown > 0 and teleporter and system_power(teleporter) > 0:
		teleporter_cooldown -= 1
	var dock := system_by("evb_dock")
	if evb_cooldown > 0 and dock and system_power(dock) > 0:
		evb_cooldown -= 1
	for door in doors:
		if door.passing_ticks > 0:
			door.passing_ticks -= 1
		if door.broken_open_ticks > 0:
			door.broken_open_ticks -= 1
			if door.broken_open_ticks == 0:
				door.health = door_max_health()


func door_max_health() -> float:
	var doors_system := system_by("doors")
	if doors_system == null:
		return 0.0
	return DOOR_HEALTH_PER_LEVEL * maxi(1, system_power(doors_system))


func doors_controllable() -> bool:
	var doors_system := system_by("doors")
	return doors_system != null and system_power(doors_system) > 0


func _tick_air() -> void:
	var life_support := system_by("oxygen")
	var refill := 0.0
	if life_support:
		refill = 0.0008 * system_power(life_support)
	var leak := 0.0 if refill > 0.0 else 0.0003
	for room in rooms:
		room.oxygen += refill - leak
		room.oxygen -= 0.0025 * room.breaches.size() * 4.0 / max(1, room.cells.size())
		room.oxygen -= 0.0005 * room.fires.size()
	for door in doors:
		if not door.is_open():
			continue
		var room_a := room_at(door.cell_a)
		if door.to_space:
			rooms[room_a].oxygen -= 0.02
			continue
		var room_b := room_at(door.cell_b)
		var flow := (rooms[room_a].oxygen - rooms[room_b].oxygen) * 0.05
		rooms[room_a].oxygen -= flow
		rooms[room_b].oxygen += flow
	for member in _everyone_aboard():
		if member.race.makes_air:
			rooms[room_at(member.cell)].oxygen += 0.0015
	for room in rooms:
		room.oxygen = clampf(room.oxygen, 0.0, 1.0)
	for member in _everyone_aboard():
		member.suffocating = member.race.breathes and rooms[room_at(member.cell)].oxygen < 0.05
		if member.suffocating:
			member.health -= SUFFOCATION_PER_TICK


func _tick_fires(rng: RandomNumberGenerator) -> void:
	var new_fires: Array = []
	for room in rooms:
		if room.fires.is_empty():
			continue
		for cell in room.fires.keys():
			if room.oxygen < 0.1:
				room.fires[cell] -= 0.6
			else:
				room.fires[cell] = minf(100.0, room.fires[cell] + 0.2)
			if room.fires[cell] <= 0.0:
				room.fires.erase(cell)
				continue
			if rng.randf() < 0.004:
				for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var next: Vector2i = cell + step
					var next_room := room_at(next)
					if next_room < 0:
						continue
					if next_room == room.index or rng.randf() < 0.25:
						new_fires.append(next)
						break
		room.fire_system_damage += 0.004 * room.fires.size()
		if room.fire_system_damage >= 1.0:
			room.fire_system_damage -= 1.0
			for system in room.systems:
				damage_system(system, 1)
	for cell in new_fires:
		start_fire(cell)
	for member in _everyone_aboard():
		var room := rooms[room_at(member.cell)]
		if room.fires.has(member.cell) and not member.race.fire_immune:
			member.health -= FIRE_BURN_PER_TICK


func _tick_infection(rng: RandomNumberGenerator) -> void:
	for room in rooms:
		if room.infection <= 0.0:
			continue
		if room.is_burning():
			room.infection = maxf(0.0, room.infection - 1.0)   # fire burns it out (GDD 8G)
			continue
		room.infection = minf(100.0, room.infection + 0.05)
		var rate := 0.003 * room.infection / 100.0 * (1.6 if tech == "biomechanical" else 1.0)
		room.infection_system_damage += rate
		if room.infection_system_damage >= 1.0:
			room.infection_system_damage -= 1.0
			for system in room.systems:
				damage_system(system, 1)
		if room.infection > 50.0 and rng.randf() < 0.0015 and not room.neighbours.is_empty():
			var target := rooms[room.neighbours[rng.randi_range(0, room.neighbours.size() - 1)]]
			target.infection = maxf(target.infection, 10.0)


func _tick_doors() -> void:
	pass


# --- Damage ---------------------------------------------------------------------------------------------------

func damage_system(system: ShipSystem, bars: int) -> void:
	if system == null or system.behaviour == "power_core":
		return   # the AZC is armoured
	var before := system.damage
	system.damage = mini(system.level, system.damage + bars)
	if system.damage > before:
		_note("system_damaged", {"system": system})


func damage_hull(amount: int) -> void:
	if amount <= 0 or destroyed:
		return
	hull = maxi(0, hull - amount)
	hit_flash = 8
	if hull <= 0:
		destroyed = true
		explosion_ticks = 0
		_note("ship_destroyed", {})


func start_fire(cell: Vector2i) -> void:
	var room_index := room_at(cell)
	if room_index < 0 or rooms[room_index].fires.has(cell):
		return
	if rooms[room_index].oxygen < 0.1:
		return
	rooms[room_index].fires[cell] = 40.0
	_note("fire_started", {"room": room_index})


func breach(cell: Vector2i) -> void:
	var room_index := room_at(cell)
	if room_index < 0 or rooms[room_index].breaches.has(cell):
		return
	rooms[room_index].breaches[cell] = 100.0
	_note("breach", {"room": room_index})


func break_conduit_in_room(room_index: int, rng: RandomNumberGenerator) -> void:
	var candidates: Array[Vector2i] = []
	for cell in rooms[room_index].cells:
		if conduits.has(cell) and not broken_conduits.has(cell) and cell != core_cell:
			candidates.append(cell)
	if candidates.is_empty():
		return
	broken_conduits[candidates[rng.randi_range(0, candidates.size() - 1)]] = 100.0
	_note("conduit_cut", {"room": room_index})


func _note(kind: String, data: Dictionary) -> void:
	if event_sink.is_valid():
		data["ship"] = self
		event_sink.call(kind, data)


# --- Repairs between fights -----------------------------------------------------------------------------------

func repair_hull(points: int) -> void:
	hull = mini(max_hull, hull + points)


func repair_everything() -> void:
	for system in systems:
		system.damage = 0
		system.ion = 0
		system.spored = false
	for room in rooms:
		room.fires.clear()
		room.breaches.clear()
		room.infection = 0.0
		room.oxygen = 1.0
	broken_conduits.clear()


## Clears what only matters in a fight; called when a new cluster or fight starts.
func begin_encounter() -> void:
	shield_layers = max_shield_layers()
	shield_progress = 0.0
	var generator := system_by("supershield")
	supershield = 5 if generator and system_power(generator) > 0 else 0
	jump_charge = 0.0
	cloak_ticks = 0
	cloak_cooldown = 0
	teleporter_cooldown = 240
	evb_cooldown = 60
	charging_escape = false
	surrendered = false
	for slot in weapons:
		slot.charge = 0.0
		slot.clear_target()
		slot.shots_left = 0
	for door in doors:
		door.health = door_max_health()
		door.held_open = false
		door.broken_open_ticks = 0


# --- Saving ---------------------------------------------------------------------------------------------------

func to_save() -> Dictionary:
	var data := {
		"design": design.id, "name": name, "hull": hull, "max_hull": max_hull,
		"reactor_type": reactor_type, "reactor_level": reactor_level,
		"systems": [], "weapons": [], "suits": suits.duplicate(), "crew": [], "broken_conduits": [],
	}
	for system in systems:
		data.systems.append({"id": system.def.id, "label": system.label, "level": system.level, "damage": system.damage,
				"room": system.room, "cell": [system.cell.x, system.cell.y], "wall": system.wall, "own_power": system.own_power,
				"power": system.power, "enabled": system.enabled})
	for slot in weapons:
		data.weapons.append({"id": slot.def.id, "mount": slot.mount_id, "powered": slot.powered})
	for member in crew:
		if not member.dead:
			data.crew.append(member.to_save())
	for cell in broken_conduits:
		data.broken_conduits.append([cell.x, cell.y])
	return data


static func from_save(data: Dictionary, ship_side: int) -> Ship:
	var ship_design := Library.ship(data.get("design", "outrider"))
	var ship := Ship.new()
	ship.design = ship_design
	ship.name = data.get("name", ship_design.name)
	ship.side = ship_side
	ship.race = Library.race(ship_design.race)
	ship.tech = ship.race.tech
	ship.faction = ship_design.faction
	ship.hull = int(data.get("hull", ship_design.hull))
	ship.max_hull = int(data.get("max_hull", ship_design.hull))
	ship.reactor_type = data.get("reactor_type", ship_design.reactor_type)
	ship.reactor_level = int(data.get("reactor_level", ship_design.reactor_level))
	for entry in data.get("systems", []):
		var def := Library.system(entry.id)
		if def == null:
			continue
		var system := ShipSystem.new()
		system.def = def
		system.behaviour = def.behaviour
		system.label = entry.get("label", "")
		system.level = int(entry.level)
		system.damage = int(entry.get("damage", 0))
		system.room = int(entry.room)
		system.cell = Vector2i(int(entry.cell[0]), int(entry.cell[1]))
		system.wall = entry.get("wall", "north")
		system.own_power = int(entry.get("own_power", 0))
		system.power = int(entry.get("power", 0))
		system.enabled = bool(entry.get("enabled", true))
		ship.systems.append(system)
	ship._build_layout()
	for entry in data.get("weapons", []):
		var def := Library.weapon(entry.id)
		if def:
			var slot := WeaponSlot.create(def, int(entry.mount))
			slot.powered = bool(entry.get("powered", false))
			ship.weapons.append(slot)
	ship.suits.assign(data.get("suits", []))
	for entry in data.get("crew", []):
		ship.add_crew(CrewMember.from_save(entry))
	for cell in data.get("broken_conduits", []):
		ship.broken_conduits[Vector2i(int(cell[0]), int(cell[1]))] = 100.0
	ship.assign_stations()
	return ship
