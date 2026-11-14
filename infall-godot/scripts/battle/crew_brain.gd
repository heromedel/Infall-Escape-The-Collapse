class_name CrewBrain
extends RefCounted
## What crew do on their own, as in the genre: walk where they are sent (opening doors, or breaking them when
## boarding), and in whatever room they stand in fight intruders, put out fires, patch breaches, repair
## systems and conduits, and otherwise man the console they stand at. A working medbay heals them whatever they
## are doing.
##
## Fights (GV 7G, docs/reference/genre-crew-fights): a tile holds one fighter from each side. Whoever walks into a
## room with foes in it goes onto a foe's tile, and the two punch. A fighter with no foe on their tile stays where
## they are and shoots at one foe in the room until that foe is dead or gone, turning on someone else only to fight
## back (heromedel, 2026-11-13; the genre's shooters change targets more freely). A punch or a shot lands about
## once a second.

const SKILLED_REPAIR_BONUS := 0.05  # repairing a system they have a skill level in is slightly faster (GDD 7H); the
									# number is Eco's placeholder, half of one repair level, for heromedel to settle
const HIT_TICKS := 20               # ticks between one fighter's punches or shots
const HIT_DAMAGE := 5.6             # health a hit costs at melee 1.0: a second of fighting, as before hits were counted
const FIRST_HIT_TICKS := 10         # a fighter's first hit comes this long after the fight reaches them
const SHOT_PIXELS_PER_TICK := 7.0   # a shot crosses a tile in a quarter of a second
const HIT_MARK_TICKS := 10          # how long a hit shows on the one hit
const SABOTAGE_PER_TICK := 0.6
const MEDBAY_HEAL_PER_TICK := 0.3   # per bar of medbay power
const BOARDER_DOOR_DAMAGE := 1.0
const XP_REPAIR_PER_BAR := 5.6      # GDD 7H
const XP_COMBAT := 12.5


## Sends a crew member to a room of the ship they are on. Returns false when there is no way there.
static func order_to_room(member: CrewMember, room_index: int, from_player: bool = false) -> bool:
	var ship := member.ship
	if room_index < 0 or room_index >= ship.rooms.size() or not member.is_active():
		return false
	if ship.room_at(member.cell) == room_index and member.path.is_empty() and not from_player:
		return true
	var goal := ship.pairing_cell(room_index, member)      # onto a foe's tile, if any are there to fight
	if goal == Ship.NO_CELL:
		goal = ship.free_cell_in_room(room_index, member.side, member)
	return walk_to(member, goal, from_player)


static func walk_to(member: CrewMember, goal: Vector2i, from_player: bool = false) -> bool:
	var ship := member.ship
	var start := member.cell
	if not member.path.is_empty():
		start = member.path[0]   # finish the step in progress first
	var route := find_path(ship, start, goal)
	if route.is_empty() and start != goal:
		return false
	if not member.path.is_empty():
		route.push_front(member.path[0])
	member.path = route
	member.destination = goal
	member.player_ordered = from_player
	member.melee_with = null      # walking off a shared tile ends that melee; the one left behind may follow
	return true


## Breadth-first search over tiles: steps inside a room, and through doors between rooms.
static func find_path(ship: Ship, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if start == goal or not ship.links.has(start) or not ship.links.has(goal):
		return result
	var came_from := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		if cell == goal:
			break
		for link in ship.links[cell]:
			var next: Vector2i = link.cell
			if not came_from.has(next):
				came_from[next] = cell
				queue.append(next)
	if not came_from.has(goal):
		return result
	var cell := goal
	while cell != start:
		result.push_front(cell)
		cell = came_from[cell]
	return result


static func door_between(ship: Ship, a: Vector2i, b: Vector2i) -> ShipDoor:
	for link in ship.links.get(a, []):
		if link.cell == b:
			return link.door
	return null


## One tick for one crew member.
static func tick(member: CrewMember, encounter: Encounter) -> void:
	if member.dead or member.in_suit:
		return
	if member.teleporting_ticks > 0:
		member.teleporting_ticks -= 1
		return
	member.previous_position = member.position
	_heal_in_medbay(member)
	if member.attack_cooldown > 0:
		member.attack_cooldown -= 1
	if member.hit_ticks > 0:
		member.hit_ticks -= 1
	_fly_shot(member, encounter)
	if member.mind_ticks > 0:
		member.mind_ticks -= 1
		if member.mind_ticks == 0:
			member.end_mind_control()
			encounter.note("mind_control_ended", {"crew": member})
	if member.stun_ticks > 0:
		member.stun_ticks -= 1
		member.task = "stunned"
		return
	if member.race.heals_slowly:
		member.health = minf(member.max_health, member.health + 0.03)
	if not member.path.is_empty():
		_step(member)
		member.task = "walking"
		# Crew fight back even mid-walk when cornered in a room with enemies
		return
	member.position = member.ship.design.cell_centre(member.cell)
	_work(member, encounter)


## A powered medbay heals everyone of its ship's side in its room every tick, at any task: its own crew and
## allies from other ships, never enemies. Fire or lack of air keeps hurting them at the same time.
static func _heal_in_medbay(member: CrewMember) -> void:
	member.healing = false
	var ship := member.ship
	if member.side != ship.side or member.health >= member.max_health:
		return
	var room_index := ship.room_at(member.cell)
	if room_index < 0:
		return
	for system in ship.rooms[room_index].systems:
		if system.behaviour == "medbay" and ship.system_power(system) > 0:
			member.health = minf(member.max_health, member.health + MEDBAY_HEAL_PER_TICK * ship.system_power(system))
			member.healing = true
			return


static func _step(member: CrewMember) -> void:
	var ship := member.ship
	var next: Vector2i = member.path[0]
	var door := door_between(ship, member.cell, next)
	if door and not door.is_open():
		var hostile := member.side != ship.side
		if hostile and ship.doors_controllable():
			door.health -= BOARDER_DOOR_DAMAGE * member.race.melee
			member.task = "breaking"
			if door.health <= 0.0:
				door.broken_open_ticks = 200
			return
		door.passing_ticks = 14
	elif door:
		door.passing_ticks = maxi(door.passing_ticks, 14)
	var target := ship.design.cell_centre(next)
	var speed := member.speed_pixels_per_tick()
	var offset := target - member.position
	if offset.length() <= speed:
		member.position = target
		member.cell = next
		member.path.pop_front()
		if member.path.is_empty():
			member.player_ordered = false
	else:
		member.position += offset.normalized() * speed


static func _work(member: CrewMember, encounter: Encounter) -> void:
	var ship := member.ship
	var room_index := ship.room_at(member.cell)
	if room_index < 0:
		return
	var room := ship.rooms[room_index]
	# 1. Fight anyone of the other side in the room
	var foes := ship.crew_in_room(room_index, 1 - member.side)
	if not foes.is_empty():
		_fight(member, foes, encounter)
		return
	member.melee_with = null
	member.aim_at = null
	var at_home := ship == member.home and member.mind_ticks <= 0
	if at_home:
		# 2. Fires, breaches, system damage, conduits, infection: the genre's order of trouble
		if not room.fires.is_empty():
			var fire_cell: Vector2i = room.fires.keys()[0]
			if room.fires.has(member.cell):
				fire_cell = member.cell
			room.fires[fire_cell] -= Ship.EXTINGUISH_PER_TICK * _repair_speed(member, ship)
			if room.fires[fire_cell] <= 0.0:
				room.fires.erase(fire_cell)
				room.scorch[fire_cell] = true
			member.task = "extinguishing"
			return
		if not room.breaches.is_empty():
			var breach_cell: Vector2i = room.breaches.keys()[0]
			room.breaches[breach_cell] -= Ship.PATCH_PER_TICK * _repair_speed(member, ship)
			if room.breaches[breach_cell] <= 0.0:
				room.breaches.erase(breach_cell)
				member.gain_xp("repair", XP_REPAIR_PER_BAR)
			member.task = "patching"
			return
		for system in room.systems:
			if system.damage > 0 or system.spored:
				_repair_system(member, system, ship, encounter)
				member.task = "repairing"
				return
		for cell in room.cells:
			if ship.broken_conduits.has(cell):
				ship.broken_conduits[cell] -= Ship.CONDUIT_REPAIR_PER_TICK * _repair_speed(member, ship)
				if ship.broken_conduits[cell] <= 0.0:
					ship.broken_conduits.erase(cell)
					member.gain_xp("repair", XP_REPAIR_PER_BAR * 0.5)
					encounter.note("conduit_repaired", {"ship": ship, "room": room_index})
				member.task = "repairing"
				return
		if room.infection > 0.0:
			room.infection = maxf(0.0, room.infection - 1.2 * _repair_speed(member, ship))
			member.task = "repairing"
			return
		member.task = "idle"
		return
	# Boarding: wreck what is in the room while nobody stops us
	for system in room.systems:
		if system.behaviour == "power_core" or system.is_broken():
			continue
		system.repair_progress -= SABOTAGE_PER_TICK * member.race.melee
		if system.repair_progress <= -100.0:
			system.repair_progress = 0.0
			ship.damage_system(system, 1)
		member.task = "sabotaging"
		return
	member.task = "idle"


static func _repair_speed(member: CrewMember, ship: Ship) -> float:
	var rate := member.race.repair_rate * (1.0 + 0.1 * member.skill_level("repair"))
	if ship.tech == "biomechanical":
		rate *= member.race.biomech_repair_rate
	return rate


static func _repair_system(member: CrewMember, system: ShipSystem, ship: Ship, encounter: Encounter) -> void:
	var speed := Ship.REPAIR_PER_TICK * _repair_speed(member, ship)
	if member.skill_level(system.behaviour) > 0:
		speed *= 1.0 + SKILLED_REPAIR_BONUS     # they know this system (GDD 7H)
	if system.spored:
		system.spore_progress += speed
		if system.spore_progress >= 100.0:
			system.spore_progress = 0.0
			system.spored = false
			encounter.note("system_repaired", {"ship": ship, "system": system})
		return
	system.repair_progress = maxf(0.0, system.repair_progress) + speed
	member.gain_xp("repair", XP_REPAIR_PER_BAR * speed / 100.0)
	if system.repair_progress >= 100.0:
		system.repair_progress = 0.0
		system.damage = maxi(0, system.damage - 1)
		encounter.note("system_repaired", {"ship": ship, "system": system})


## One tick of a fight for a crew member standing in a room with foes.
static func _fight(member: CrewMember, foes: Array[CrewMember], encounter: Encounter) -> void:
	var ship := member.ship
	if member.task != "fighting":
		member.attack_cooldown = maxi(member.attack_cooldown, FIRST_HIT_TICKS)
	member.task = "fighting"
	if _follows(member, foes):
		return
	var partner := ship.standing_on(member.cell, 1 - member.side)
	member.melee_with = partner
	if partner:
		member.aim_at = null
	elif not foes.has(member.aim_at):
		member.aim_at = _first_target(member, foes)
	if member.attack_cooldown > 0:
		return
	if partner:
		member.attack_cooldown = HIT_TICKS
		_hit(member, partner, encounter)
	elif member.shot_ticks <= 0:
		var target := member.aim_at
		member.attack_cooldown = HIT_TICKS
		member.shot_at = target
		member.shot_flight = maxi(1, ceili(member.position.distance_to(target.position) / SHOT_PIXELS_PER_TICK))
		member.shot_ticks = member.shot_flight


## The foe a fighter who shoots takes on first, and again when theirs is dead or gone: one already shooting at
## them if there is one, the nearest of those, or else the nearest foe in the room.
static func _first_target(member: CrewMember, foes: Array[CrewMember]) -> CrewMember:
	var target: CrewMember = null
	for foe in foes:
		if target == null:
			target = foe
			continue
		var after_us := foe.aim_at == member
		if after_us != (target.aim_at == member):
			if after_us:
				target = foe
		elif member.position.distance_squared_to(foe.position) < member.position.distance_squared_to(target.position):
			target = foe
	return target


## A fighter whose foe has walked off their shared tile goes after them, to go on with the melee (GV 7G: the genre
## has no tile orders, so never needed this). Only crew no player commands follow, and only inside the room.
## Returns true when they set off.
static func _follows(member: CrewMember, foes: Array[CrewMember]) -> bool:
	var partner := member.melee_with
	if partner == null or member.side == 0 or not foes.has(partner):
		return false
	var heading := partner.destination if partner.is_moving() else partner.cell
	if heading == member.cell:
		return false
	var ship := member.ship
	if ship.room_at(heading) != ship.room_at(member.cell) or ship.cell_is_claimed(heading, member.side, member):
		return false
	if not walk_to(member, heading):
		return false
	member.melee_with = partner   # still after them
	return true


## A shot in the air comes a tick nearer and lands on the one it was fired at, wherever they have got to on the ship.
static func _fly_shot(member: CrewMember, encounter: Encounter) -> void:
	if member.shot_ticks <= 0:
		return
	member.shot_ticks -= 1
	if member.shot_ticks > 0:
		return
	var target := member.shot_at
	member.shot_at = null
	if target and target.is_active() and target.ship == member.ship:
		_hit(member, target, encounter)


## A punch or a shot lands. A fighter who shoots fights back: hit by someone other than the foe they are shooting
## at, they turn on the one who hit them, unless their own foe is shooting at them too (or two foes shooting at one
## fighter would have them changing target at every hit).
static func _hit(member: CrewMember, target: CrewMember, encounter: Encounter) -> void:
	target.health -= HIT_DAMAGE * member.race.melee * (1.0 + 0.1 * member.skill_level("combat"))
	target.hit_ticks = HIT_MARK_TICKS
	if target.melee_with == null and target.aim_at != member and (target.aim_at == null or target.aim_at.aim_at != target):
		target.aim_at = member
	if target.health <= 0.0 and not target.dead:
		member.kills += 1
		if member.gain_xp("combat", XP_COMBAT):
			encounter.note("skill_up", {"crew": member, "skill": "combat"})
