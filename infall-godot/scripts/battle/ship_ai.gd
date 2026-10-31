class_name ShipAI
extends RefCounted
## The captain of one enemy ship. Twice a second it hands out power, aims its weapons, sends its crew where
## they are needed, boards, launches suits, cloaks, and decides when to run or offer surrender (the squad's
## conduct). It only gives orders the player could give; the encounter carries them out.

const TROUBLE_ORDER := ["shields", "weapons", "piloting", "oxygen", "engines", "supershield", "medbay", "teleporter", "evb_dock", "doors", "sensors"]
const STATION_ORDER := ["piloting", "weapons", "shields", "engines", "evb_dock", "teleporter", "doors", "sensors", "oxygen", "medbay"]
const ROOM_WEIGHT := {"shields": 4, "weapons": 4, "piloting": 2, "engines": 2, "oxygen": 1, "medbay": 1, "teleporter": 1, "evb_dock": 2, "supershield": 3, "sensors": 1, "doors": 1, "cloaking": 2}

var ship: Ship
var encounter: Encounter
var target: Ship = null
var surrender_rolled: bool = false
var escape_rolled: bool = false
var boarding_party_out: bool = false
var gathering: Array[CrewMember] = []   # crew called to the teleporter to board


func _init(controlled: Ship, owner: Encounter) -> void:
	ship = controlled
	encounter = owner


func think() -> void:
	if ship.destroyed or ship.crew_dead:
		return
	_manage_power()
	_choose_target()
	_aim_weapons()
	_order_crew()
	_order_boarders()
	_use_specials()
	_consider_conduct()


# --- Power ----------------------------------------------------------------------------------------------------

func _manage_power() -> void:
	match ship.reactor_type:
		"pool":
			var wanted := ["shields", "weapons", "engines", "supershield", "cloaking", "teleporter", "evb_dock"]
			if _air_is_low():
				wanted.insert(1, "oxygen")
			else:
				wanted.append("oxygen")
			if _anyone_hurt():
				wanted.append("medbay")
			for behaviour in wanted:
				var system := ship.system_by(behaviour)
				if system == null:
					continue
				var guard := 0
				while ship.can_add_power(system) and guard < 10:
					ship.add_power(system)
					guard += 1
		"core":
			var order := ["shields", "weapons", "engines", "teleporter", "evb_dock", "supershield", "cloaking", "oxygen", "medbay"]
			if _air_is_low():
				order.erase("oxygen")
				order.insert(1, "oxygen")
			var budget := ship.core_capacity()
			for behaviour in order:
				var system := ship.system_by(behaviour)
				if system == null or not system.def.draws_power:
					continue
				system.enabled = budget > 0 and (behaviour != "medbay" or _anyone_hurt())
				if system.enabled:
					budget -= 1
	for slot in ship.weapons:
		if not slot.powered:
			ship.set_weapon_powered(slot, true)


func _air_is_low() -> bool:
	if not ship.race.breathes:
		return false
	for room in ship.rooms:
		if room.oxygen < 0.6:
			return true
	return false


func _anyone_hurt() -> bool:
	for member in ship.crew:
		if not member.dead and member.health < member.max_health * 0.7:
			return true
	return false


# --- Weapons --------------------------------------------------------------------------------------------------

func _choose_target() -> void:
	var options := encounter.living(0)
	if options.is_empty():
		target = null
		return
	if target != null and options.has(target) and encounter.rng.randf() > 0.02:
		return
	# Squads pick the weakest ship of the player's squad (ship-suggestions.md, Light Attack Pair)
	options.sort_custom(func(a, b): return a.hull < b.hull)
	target = options[0] if encounter.rng.randf() < 0.7 else options[encounter.rng.randi_range(0, options.size() - 1)]


func _aim_weapons() -> void:
	if target == null:
		return
	var lasers_ready := true
	var lasers_close := true
	var laser_count := 0
	for slot in ship.weapons:
		if not slot.powered or slot.def.ignores_shields() or slot.def.defensive:
			continue
		laser_count += 1
		var needed := slot.charge_needed(ship.tech)
		if slot.charge < needed:
			lasers_ready = false
			if needed - slot.charge > 70.0:
				lasers_close = false
	var hold_lasers := laser_count >= 2 and not lasers_ready and lasers_close and target.shield_layers > 0
	var taken_rooms: Array[int] = []
	for slot in ship.weapons:
		if not slot.powered:
			continue
		if slot.def.defensive:
			# Defend unless the player's shields are already down
			if target.shield_layers == 0 and target.supershield == 0:
				_aim(slot, taken_rooms)
			else:
				slot.clear_target()
			continue
		if hold_lasers and not slot.def.ignores_shields():
			slot.clear_target()
			continue
		if not slot.has_target() or slot.target_ship != target:
			_aim(slot, taken_rooms)


func _aim(slot: WeaponSlot, taken_rooms: Array[int]) -> void:
	var room_index := _pick_room(slot.def, taken_rooms)
	if room_index < 0:
		return
	taken_rooms.append(room_index)
	slot.target_ship = target
	slot.target_room = room_index
	slot.target_suit = null
	slot.autofire = true
	if slot.def.type == "beam":
		var start: Vector2 = target.rooms[room_index].centre_local(target.design)
		var angle := encounter.rng.randf() * TAU
		slot.beam_start = start
		slot.beam_end = start + Vector2.from_angle(angle) * slot.def.beam_length


## Which room to hit: the squad's preferred systems first (its conduct), else a weighted pick of system rooms;
## hull-bonus weapons go for empty rooms.
func _pick_room(weapon: WeaponDef, taken_rooms: Array[int]) -> int:
	if encounter.squad:
		for behaviour in encounter.squad.targets:
			var system := target.system_by(behaviour)
			if system and not taken_rooms.has(system.room) and not system.is_broken():
				return system.room
	var total := 0
	var weights: Array[int] = []
	for room in target.rooms:
		var weight := 1
		if weapon.hull_bonus:
			weight = 4 if room.systems.is_empty() else 1
		else:
			for system in room.systems:
				weight = maxi(weight, ROOM_WEIGHT.get(system.behaviour, 1))
		if taken_rooms.has(room.index):
			weight = maxi(1, weight / 3)
		weights.append(weight)
		total += weight
	var roll := encounter.rng.randi_range(1, maxi(1, total))
	for index in weights.size():
		roll -= weights[index]
		if roll <= 0:
			return index
	return 0


# --- Crew -----------------------------------------------------------------------------------------------------

func _order_crew() -> void:
	var available: Array[CrewMember] = []
	for member in ship.crew:
		if member.ship == ship and member.can_act() and not boarding_reserved(member):
			available.append(member)
	if available.is_empty():
		return
	var plans := {}   # CrewMember -> room
	# Intruders: send the healthiest to fight them
	for room in ship.rooms:
		var intruders := ship.crew_in_room(room.index, 1 - ship.side)
		if intruders.is_empty():
			continue
		for count in mini(available.size(), intruders.size() + 1):
			var fighter := _closest(available, room.index, plans)
			if fighter and fighter.health > fighter.max_health * 0.35:
				plans[fighter] = room.index
	# Hurt crew go to the medbay when there is no fight in it
	var medbay := ship.system_by("medbay")
	if medbay and ship.system_power(medbay) > 0:
		for member in available:
			if not plans.has(member) and member.health < member.max_health * 0.4:
				plans[member] = medbay.room
	# Stations: one crew member each, in order of importance
	var station_of := {}   # CrewMember -> importance of the station they hold
	for index in STATION_ORDER.size():
		var system := ship.system_by(STATION_ORDER[index])
		if system == null or not (system.def.manned or ship.race.integrates or system.behaviour in ["evb_dock", "teleporter"]):
			continue
		var member := _closest(available, system.room, plans)
		if member == null:
			break
		plans[member] = system.room
		var importance := TROUBLE_ORDER.find(system.behaviour)
		station_of[member] = importance if importance >= 0 else TROUBLE_ORDER.size()
	# Trouble: fires, breaches and damaged systems, the most important first. Spare crew go; a station keeper
	# leaves only for trouble more important than their own station.
	for index in TROUBLE_ORDER.size():
		var system := ship.system_by(TROUBLE_ORDER[index])
		if system == null or not (system.is_damaged() or ship.rooms[system.room].has_trouble()):
			continue
		_send_fixer(available, plans, station_of, system.room, index)
	for room in ship.rooms:
		if room.is_burning() or room.is_breached() or room.infection > 0.0:
			_send_fixer(available, plans, station_of, room.index, TROUBLE_ORDER.size())
	for cell in ship.broken_conduits:
		_send_fixer(available, plans, station_of, ship.room_at(cell), TROUBLE_ORDER.size())
	for member in plans:
		var room_index: int = plans[member]
		if ship.room_at(member.destination) != room_index or (member.path.is_empty() and ship.room_at(member.cell) != room_index):
			CrewBrain.order_to_room(member, room_index)


func _send_fixer(available: Array[CrewMember], plans: Dictionary, station_of: Dictionary, room_index: int, importance: int) -> void:
	if room_index < 0:
		return
	for member in plans:
		if plans[member] == room_index:
			return   # someone is already going, or already there
	if ship.rooms[room_index].oxygen < 0.08 and ship.race.breathes and not ship.rooms[room_index].is_burning():
		return
	var fixer := _closest(available, room_index, plans)
	if fixer == null:
		var best_station := -1
		for member in station_of:
			if station_of[member] > importance and station_of[member] > best_station and plans[member] != room_index:
				best_station = station_of[member]
				fixer = member
		if fixer == null:
			return
		station_of.erase(fixer)
	plans[fixer] = room_index


func _stations_needed() -> int:
	var count := 0
	for behaviour in ["piloting", "weapons", "shields", "engines"]:
		if ship.has_system(behaviour):
			count += 1
	return count


func _closest(pool: Array[CrewMember], room_index: int, plans: Dictionary) -> CrewMember:
	var best: CrewMember = null
	var best_distance := INF
	var centre := ship.rooms[room_index].centre_local(ship.design)
	for member in pool:
		if plans.has(member):
			continue
		var distance := member.position.distance_squared_to(centre)
		if distance < best_distance:
			best_distance = distance
			best = member
	return best


func boarding_reserved(member: CrewMember) -> bool:
	return gathering.has(member) and member.ship == ship


## Boarders aboard the player's ship head for its systems and wreck them; badly hurt ones are recalled.
func _order_boarders() -> void:
	var recall := false
	for member in ship.crew:
		if member.dead or member.ship == ship or member.in_suit or not member.can_act():
			continue
		if member.health < member.max_health * 0.3:
			recall = true
			continue
		var host := member.ship
		var here := host.room_at(member.cell)
		if not member.path.is_empty():
			continue
		var room := host.rooms[here]
		var worth_staying := false
		for system in room.systems:
			if not system.is_broken() and system.behaviour != "power_core":
				worth_staying = true
		if not host.crew_in_room(here, host.side).is_empty():
			worth_staying = true
		if worth_staying:
			continue
		for behaviour in ["weapons", "shields", "piloting", "oxygen", "engines", "medbay"]:
			var system := host.system_by(behaviour)
			if system and not system.is_broken():
				CrewBrain.order_to_room(member, system.room)
				break
	if recall and encounter.can_teleport(ship):
		encounter.recall_boarders(ship)
		boarding_party_out = false


func _use_specials() -> void:
	if target == null:
		return
	var teleporter := ship.system_by("teleporter")
	if teleporter and encounter.can_teleport(ship) and target.supershield == 0:
		var party := 0
		for member in ship.crew:
			if member.ship != ship and not member.dead:
				party += 1
		if party == 0:
			# Gather two boarders who are not flying or gunning
			var gathered := 0
			for member in ship.crew_in_room(teleporter.room, ship.side):
				if member.can_act() and member.path.is_empty():
					gathered += 1
			if gathered >= 2 or (gathered >= 1 and ship.living_crew_count() <= 2):
				var room_index := _boarding_room()
				if encounter.send_boarders(ship, target, room_index):
					boarding_party_out = true
					gathering.clear()
			else:
				var sent := 0
				for member in ship.crew:
					if sent >= 2 - gathered or member.dead or member.ship != ship or not member.can_act():
						continue
					var station := ship.system_by("piloting")
					if station and station.manned_by == member:
						continue
					if ship.room_at(member.cell) == teleporter.room:
						continue
					if ship.living_crew_count() > 2 and not gathering.has(member) and gathering.size() < 2:
						CrewBrain.order_to_room(member, teleporter.room)
						gathering.append(member)
						sent += 1
	if ship.system_by("evb_dock") and not ship.suit_out:
		encounter.launch_suit(ship, target)
	if ship.system_by("cloaking") and ship.cloak_ticks == 0:
		var incoming := 0
		for shot in encounter.projectiles:
			if shot.target == ship and not shot.missed:
				incoming += 1
		if incoming >= 2:
			encounter.cloak(ship)


func _boarding_room() -> int:
	for behaviour in ["weapons", "shields", "piloting", "oxygen"]:
		var system := target.system_by(behaviour)
		if system:
			return system.room
	return 0


# --- Conduct: running and surrendering ------------------------------------------------------------------------

func _consider_conduct() -> void:
	var squad := encounter.squad
	var surrender_chance := squad.surrender_chance if squad else 20
	var surrender_hull := squad.surrender_hull if squad else 0.3
	var escape_chance := squad.escape_chance if squad else 25
	var escape_hull := squad.escape_hull if squad else 0.25
	var hull_fraction := float(ship.hull) / float(ship.max_hull)
	if not surrender_rolled and hull_fraction <= surrender_hull:
		surrender_rolled = true
		if not encounter.surrender_offered and encounter.rng.randi_range(1, 100) <= surrender_chance:
			encounter.surrender_offered = true
			encounter.note("surrender_offer", {"ship": ship})
	if not escape_rolled and hull_fraction <= escape_hull:
		escape_rolled = true
		if encounter.rng.randi_range(1, 100) <= escape_chance:
			ship.charging_escape = true
			ship.jump_charge = 0.0
			encounter.note("enemy_charging_escape", {"ship": ship})
	if ship.charging_escape and ship.jump_ready():
		ship.escaped = true
		encounter.note("enemy_escaped", {"ship": ship})
