class_name Encounter
extends RefCounted
## Everything happening at the current cluster, on fixed ticks of 0.05 s (GDD 3E): the player's squad, any
## enemy squad, the shots between them, battlesuits, teleports and hazards. It runs even when no one is
## fighting, so crew keep repairing between fights, as in the genre.
##
## Each tick changes state and returns. What happened is noted in `notes` for the screen to show and the log
## to write; nothing here draws or plays sound (coding rule 8).

const TICKS := 20
const DODGE_XP := 6.7
const SHIELD_XP := 1.8
const VOLLEY_XP := 1.5
const SUIT_SPEED := 7.0
const TELEPORT_TICKS := 20
# The barrier (GDD 3Q, 3R): a strip across the battlefield between the squads that stands for the distance
# between them. It is 12 tiles deep (heromedel, 2026-10-31) and centred on y = 0, the player squad below it.
const BARRIER_HALF_DEPTH := 6.0 * ShipDesign.TILE
const DEFAULT_GATOMETERS := 400.0
# How fast each kind of shot covers Gatometers; a longer gap only means a longer wait (GDD 3Q).
# Not in the docs yet: lasers and flak 400 a second (1 s for the default gap), missiles 260, battlesuits 130.
const GATOMETERS_PER_SECOND := {"laser": 400.0, "flak": 400.0, "missile": 260.0, "suit": 130.0}

var ships: Array[Ship] = []
var projectiles: Array[Projectile] = []
var suits: Array[Battlesuit] = []
var beams: Array = []              # {weapon, source, target, start, end (world), ticks, total, rooms_hit}
var bombs: Array = []              # {weapon, source, target, room, ticks}
var notes: Array = []              # what happened this tick, for the screen and the log
var tick_count: int = 0
var rng := RandomNumberGenerator.new()
var hazard: String = ""
var hazard_timer: int = 200
var squad: SquadDef = null
var band: int = 1
var ai: Dictionary = {}            # Ship -> ShipAI
var outcome: String = ""            # won, lost, surrendered, enemy_fled
var wallet: RunState = null         # pays for the player's shots (GDD 8C)
var fight_started: bool = false
var surrender_offered: bool = false
var no_mawjig_warned: bool = false
var gatometers: float = DEFAULT_GATOMETERS   # this battle's distance across the barrier


func setup(player_ships: Array, enemy_ships: Array, seed_value: int) -> void:
	rng.seed = seed_value
	ships.clear()
	for ship in player_ships:
		ships.append(ship)
	for ship in enemy_ships:
		ships.append(ship)
		ai[ship] = ShipAI.new(ship, self)
	for ship in ships:
		ship.event_sink = note
		ship.visitors.clear()
		ship.begin_encounter()
		ship.place_crew_at_stations()
	fight_started = not enemy_ships.is_empty()
	for ship in ships:
		ship.power_everything()
		ship.begin_encounter()


func note(kind: String, data: Dictionary = {}) -> void:
	data["kind"] = kind
	data["tick"] = tick_count
	notes.append(data)


func player_ships() -> Array[Ship]:
	var list: Array[Ship] = []
	for ship in ships:
		if ship.side == 0:
			list.append(ship)
	return list


func enemy_ships() -> Array[Ship]:
	var list: Array[Ship] = []
	for ship in ships:
		if ship.side == 1:
			list.append(ship)
	return list


func living(side_index: int) -> Array[Ship]:
	var list: Array[Ship] = []
	for ship in ships:
		if ship.side == side_index and not ship.is_gone() and not ship.surrendered:
			list.append(ship)
	return list


func in_fight() -> bool:
	return fight_started and outcome.is_empty() and not living(1).is_empty()


# --- The tick -------------------------------------------------------------------------------------------------

func step() -> void:
	tick_count += 1
	var fighting := in_fight()
	_tick_hazard()
	for ship in ships:
		if ship.destroyed:
			ship.explosion_ticks += 1
			continue
		for member in ship.crew_present():
			CrewBrain.tick(member, self)
	_remove_the_dead()
	for ship in ships:
		ship.tick(fighting, rng)
		if not ship.destroyed:
			_tick_weapons(ship, fighting)
	if fighting and tick_count % 10 == 0:
		for ship in ai:
			if not ship.is_gone() and not ship.surrendered:
				ai[ship].think()
	_tick_projectiles()
	_tick_bombs()
	_tick_beams()
	_tick_suits()
	_check_crews()
	_check_outcome()


func _remove_the_dead() -> void:
	for ship in ships:
		for member in ship.crew:
			if not member.dead and member.health <= 0.0:
				member.dead = true
				member.path.clear()
				note("crew_died", {"ship": member.ship, "crew": member, "position": member.ship.design.cell_centre(member.cell)})


func _check_crews() -> void:
	for ship in ships:
		if ship.is_gone():
			continue
		var anyone := false
		for member in ship.crew:
			if not member.dead:
				anyone = true
				break
		if not anyone:
			ship.crew_dead = true   # GDD 1F: a ship whose crew are all dead is gone; nobody keeps it
			note("crew_lost", {"ship": ship})


func _check_outcome() -> void:
	if not outcome.is_empty():
		return
	if living(0).is_empty():
		outcome = "lost"
		note("squad_lost")
		return
	if not fight_started:
		return
	var enemies_left := living(1)
	if enemies_left.is_empty():
		var any_fled := false
		var any_beaten := false
		var any_surrendered := false
		for ship in enemy_ships():
			any_fled = any_fled or ship.escaped
			any_beaten = any_beaten or ship.destroyed or ship.crew_dead
			any_surrendered = any_surrendered or ship.surrendered
		if any_beaten:
			outcome = "won"
		elif any_surrendered:
			outcome = "surrendered"
		else:
			outcome = "enemy_fled"
		_bring_boarders_home()
		note("fight_over", {"outcome": outcome})


## When a fight ends, crew still aboard enemy ships come home, unless the ship blew up under them.
func _bring_boarders_home() -> void:
	for ship in ships:
		for member in ship.crew:
			if member.dead or member.ship == ship:
				continue
			if member.ship.destroyed:
				member.dead = true
				note("crew_died", {"ship": member.ship, "crew": member, "position": Vector2.ZERO})
				continue
			_land(member, ship, ship.system_by("teleporter").room if ship.system_by("teleporter") else ship.crew[0].station_room)


# --- Weapons --------------------------------------------------------------------------------------------------

func _tick_weapons(ship: Ship, fighting: bool) -> void:
	var weapons_system := ship.system_by("weapons")
	var gunner: CrewMember = weapons_system.manned_by if weapons_system else null
	var rate := 1.0
	if gunner:
		rate += [0.1, 0.15, 0.2][gunner.skill_level("weapons")]
	for slot in ship.weapons:
		slot.slide = move_toward(slot.slide, 1.0 if slot.powered else 0.0, 0.06)
		if slot.fired_flash > 0:
			slot.fired_flash -= 1
		var needed := slot.charge_needed(ship.tech)
		if slot.powered and not ship.is_cloaked():
			if fighting or slot.charge > 0.0:
				slot.charge = minf(needed, slot.charge + rate)
		elif not slot.powered:
			slot.charge = maxf(0.0, slot.charge - 3.0)
		if slot.is_firing():
			slot.shot_timer -= 1
			if slot.shot_timer <= 0:
				_fire_one_shot(ship, slot)
				slot.shots_left -= 1
				slot.shot_timer = WeaponSlot.SHOT_GAP_TICKS
			continue
		if not fighting or not slot.powered or slot.charge < needed or ship.is_cloaked():
			continue
		if slot.def.defensive and not slot.has_target():
			_defend(ship, slot)
			continue
		if slot.has_target():
			_start_volley(ship, slot, gunner)


func _start_volley(ship: Ship, slot: WeaponSlot, gunner: CrewMember) -> void:
	if ship.side == 0 and wallet != null and not wallet.spend(slot.def.cost_per_volley):
		if not no_mawjig_warned:
			no_mawjig_warned = true
			note("no_mawjig", {"ship": ship})
		return
	slot.charge = 0.0
	slot.volley_target_ship = slot.target_ship
	slot.volley_target_room = slot.target_room
	slot.volley_target_cell = slot.target_cell if slot.target_ship and slot.target_ship.room_at(slot.target_cell) >= 0 else _any_cell(slot.target_ship, slot.target_room)
	slot.volley_target_suit = slot.target_suit
	slot.fired_flash = 6
	if gunner and gunner.gain_xp("weapons", VOLLEY_XP):
		note("skill_up", {"crew": gunner, "skill": "weapons"})
	note("volley", {"ship": ship, "weapon": slot.def, "slot": slot})
	match slot.def.type:
		"beam":
			_start_beam(ship, slot)
		"flak":
			for shot in slot.def.shots:
				_fire_one_shot(ship, slot)
		_:
			slot.shots_left = slot.def.shots
			slot.shot_timer = 0
	if not slot.autofire:
		slot.clear_target()


func mount_world_position(ship: Ship, slot: WeaponSlot) -> Vector2:
	var mount := ship.design.mount_by_id(slot.mount_id)
	if mount.is_empty():
		return local_to_world(ship, ship.design.floor_rect().get_center())
	return local_to_world(ship, mount.position + mount.slide * 10.0 * slot.slide)


func _fire_one_shot(ship: Ship, slot: WeaponSlot) -> void:
	var weapon := slot.def
	var origin := mount_world_position(ship, slot)
	if slot.volley_target_suit != null:
		if slot.volley_target_suit.gone:
			return
		_launch(weapon, ship, null, Vector2i(999, 999), origin, slot.volley_target_suit.position, "laser", slot.volley_target_suit)
		return
	var target := slot.volley_target_ship
	if target == null or target.is_gone():
		return
	var cell := slot.volley_target_cell
	match weapon.type:
		"bomb":
			bombs.append({"weapon": weapon, "source": ship, "target": target, "cell": cell, "ticks": 14})
			note("bomb_away", {"ship": ship, "target": target, "room": target.room_at(cell)})
		"flak":
			# Flak scatters: each piece lands on a tile near the one aimed at
			var spread := Vector2(rng.randf_range(-45.0, 45.0), rng.randf_range(-45.0, 45.0))
			var landing := _tile_near(target, target.design.cell_centre(cell) + spread)
			var aim := local_to_world(target, target.design.cell_centre(landing))
			_launch(weapon, ship, target, landing, origin, aim, "flak")
		_:
			var aim := local_to_world(target, target.design.cell_centre(cell) + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)))
			_launch(weapon, ship, target, cell, origin, aim, "missile" if weapon.type == "missile" else "laser")
	note("shot", {"ship": ship, "weapon": weapon, "position": origin})


## The ship's tile nearest a local point.
func _tile_near(ship: Ship, local: Vector2) -> Vector2i:
	var best := Vector2i(999, 999)
	var best_distance := INF
	for cell in ship.design.cell_room:
		var distance := ship.design.cell_centre(cell).distance_squared_to(local)
		if distance < best_distance:
			best_distance = distance
			best = cell
	return best


## Some tile of a room: its system console first, since that is what shooting a room is usually for.
func _any_cell(ship: Ship, room_index: int) -> Vector2i:
	if ship == null or room_index < 0 or room_index >= ship.rooms.size():
		return Vector2i(999, 999)
	var room := ship.rooms[room_index]
	if not room.systems.is_empty():
		return room.systems[rng.randi_range(0, room.systems.size() - 1)].cell
	return room.cells[rng.randi_range(0, room.cells.size() - 1)]


func _launch(weapon: WeaponDef, source: Ship, target: Ship, cell: Vector2i, origin: Vector2, aim: Vector2, kind: String, suit: Battlesuit = null) -> Projectile:
	var shot := Projectile.new()
	shot.weapon = weapon
	shot.source = source
	shot.target = target
	shot.target_cell = cell
	shot.target_room = target.room_at(cell) if target else -1
	shot.target_suit = suit
	shot.kind = kind
	shot.position = origin
	shot.previous_position = origin
	shot.aim_point = aim
	shot.side = source.side if source else 2
	shot.damage = weapon.damage if weapon else 1
	shot.colour = weapon.colour if weapon else Color("#c9b79c")
	var speed := weapon.projectile_speed if weapon else 500.0
	shot.velocity = (aim - origin).normalized() * speed / TICKS
	projectiles.append(shot)
	return shot


## A defensive weapon that is charged and not aimed shoots down the nearest missile, asteroid or battlesuit
## coming at its squad (Tentauri Defense Laser; Defensive special, ship-suggestions.md).
func _defend(ship: Ship, slot: WeaponSlot) -> void:
	var origin := mount_world_position(ship, slot)
	var best: Projectile = null
	var best_distance := 700.0 * 700.0
	for shot in projectiles:
		if not shot.can_be_shot_down() or shot.side == ship.side or shot.target == null or shot.target.side != ship.side or in_barrier(shot.position):
			continue
		var distance := shot.position.distance_squared_to(origin)
		if distance < best_distance:
			best_distance = distance
			best = shot
	if best:
		slot.charge = 0.0
		slot.fired_flash = 6
		best.shot_down = true
		best.resolved = true
		var bolt := _launch(slot.def, ship, null, Vector2i(999, 999), origin, best.position, "defense")
		bolt.hunting = best
		note("shot_down", {"ship": ship, "position": best.position})
		return
	for suit in suits:
		if suit.gone or suit.side == ship.side or suit.target == null or suit.target.side != ship.side or in_barrier(suit.position):
			continue
		if suit.position.distance_squared_to(origin) < 650.0 * 650.0:
			slot.charge = 0.0
			slot.fired_flash = 6
			_launch(slot.def, ship, null, Vector2i(999, 999), origin, suit.position, "laser", suit)
			return


# --- Shots in flight ------------------------------------------------------------------------------------------

func _tick_projectiles() -> void:
	var still_flying: Array[Projectile] = []
	for shot in projectiles:
		shot.previous_position = shot.position
		shot.life_ticks += 1
		if shot.kind == "defense":
			if shot.hunting:
				shot.velocity = (shot.hunting.position - shot.position).normalized() * shot.velocity.length()
				if shot.position.distance_to(shot.hunting.position) < shot.velocity.length() * 1.5:
					note("intercept", {"position": shot.hunting.position})
					shot.hunting.shot_down = true
					continue
			shot.position += shot.velocity
			if shot.life_ticks < 80:
				still_flying.append(shot)
			continue
		if shot.shot_down:
			continue
		shot.position += shot.velocity * barrier_pace(shot.kind, shot.position, shot.velocity)
		if shot.missed:
			if shot.life_ticks < 160:
				still_flying.append(shot)
			continue
		if shot.target_suit != null:
			if _resolve_suit_shot(shot):
				continue
			shot.aim_point = shot.target_suit.position
			shot.velocity = (shot.aim_point - shot.position).normalized() * shot.velocity.length()
			still_flying.append(shot)
			continue
		if shot.target == null or shot.target.destroyed:
			shot.missed = true
			still_flying.append(shot)
			continue
		if not shot.resolved and _inside_bubble(shot.target, shot.position):
			shot.resolved = true
			if not _resolve_at_bubble(shot):
				continue
		if shot.resolved and shot.position.distance_to(shot.aim_point) <= shot.velocity.length() * 1.2:
			_hit_tile(shot.target, shot.target_cell, shot.weapon, shot.position, shot.source)
			continue
		still_flying.append(shot)
	projectiles = still_flying


func _resolve_suit_shot(shot: Projectile) -> bool:
	var suit := shot.target_suit
	if suit.gone:
		shot.missed = true
		return false
	if shot.position.distance_to(suit.position) > 22.0:
		return false
	if rng.randf() < 0.6:
		_hit_suit(suit)
	else:
		note("miss", {"position": suit.position, "ship": null})
	return true


func _hit_suit(suit: Battlesuit) -> void:
	suit.hits_taken += 1
	if suit.hits_taken >= 2:
		suit.gone = true
		suit.pilot.dead = true
		suit.pilot.health = 0.0
		note("suit_destroyed", {"position": suit.position, "crew": suit.pilot})
	else:
		suit.stun_ticks = 40
		suit.state = "returning"
		note("suit_hit", {"position": suit.position})


## Decides what happens where a shot meets the target's shield bubble: a dodge, the Supershield, a shield
## layer, or nothing (it flies on into the room). Returns false when the shot ends here.
func _resolve_at_bubble(shot: Projectile) -> bool:
	var target := shot.target
	var dodge_chance := target.evasion()
	if rng.randi_range(1, 100) <= dodge_chance:
		shot.missed = true
		note("miss", {"ship": target, "position": shot.position})
		_reward_dodge(target, shot.kind)
		return true
	if target.supershield > 0:
		target.supershield = maxi(0, target.supershield - maxi(1, shot.damage))
		note("supershield_hit", {"ship": target, "position": shot.position})
		return false
	var blocked_by_shields := shot.kind in ["laser", "flak", "asteroid"]
	var pierce := shot.weapon.pierce if shot.weapon else 0
	if blocked_by_shields and target.shield_layers > pierce:
		target.shield_layers -= 1
		target.shield_progress = 0.0
		if shot.weapon and shot.weapon.ion > 0:
			target.system_by("shields").add_ion(shot.weapon.ion)
		note("shield_hit", {"ship": target, "position": shot.position})
		var shields := target.system_by("shields")
		if shields and shields.manned_by and shields.manned_by.gain_xp("shields", SHIELD_XP):
			note("skill_up", {"crew": shields.manned_by, "skill": "shields"})
		return false
	return true


func _reward_dodge(ship: Ship, kind: String) -> void:
	if kind == "asteroid" and not in_fight():
		return   # asteroid dodges count only during a fight (GDD 7H)
	if ship.is_cloaked():
		return   # a shot avoided while cloaked isn't a dodge
	for behaviour in ["piloting", "engines"]:
		var system := ship.system_by(behaviour)
		if system and system.manned_by and system.manned_by.gain_xp(behaviour, DODGE_XP):
			note("skill_up", {"crew": system.manned_by, "skill": behaviour})


func _inside_bubble(ship: Ship, world_point: Vector2) -> bool:
	var local := world_to_local(ship, world_point) - bubble_centre(ship)
	var radii := bubble_radii(ship)
	return (local.x * local.x) / (radii.x * radii.x) + (local.y * local.y) / (radii.y * radii.y) <= 1.0


func bubble_centre(ship: Ship) -> Vector2:
	return Formation.shield_shape(ship.design).centre


## The shield bubble's half-width and half-height: it wraps the whole hull.
func bubble_radii(ship: Ship) -> Vector2:
	return Formation.shield_shape(ship.design).radii


# --- Hits -----------------------------------------------------------------------------------------------------

## A shot or bomb landing on one tile (heromedel, 2026-10-31: the system and the tile are hit, not the whole room):
## the hull takes the damage; the system is damaged only when its console is on that tile; crew standing on the
## tile are hurt or stunned; fire and breaches start on that tile. `hull` is false for the later tiles of a beam's
## sweep through a room it already cut.
func _hit_tile(target: Ship, cell: Vector2i, weapon: WeaponDef, world_point: Vector2, source: Ship, hull: bool = true) -> void:
	var room_index := target.room_at(cell)
	if target.destroyed or room_index < 0:
		return
	var room := target.rooms[room_index]
	var damage := weapon.damage if weapon else 1
	var hull_damage := 0
	if hull:
		hull_damage = damage * (2 if weapon and weapon.hull_bonus and room.systems.is_empty() else 1)
		target.damage_hull(hull_damage)
	var system := _system_on(target, cell)
	if damage > 0 and system:
		target.damage_system(system, damage)
	var crew_hurt := (weapon.crew_damage if weapon else 15) * damage
	for member in target.crew_on_tile(cell):
		member.health -= crew_hurt
		if weapon and weapon.stun_ticks > 0:
			member.stun_ticks = maxi(member.stun_ticks, weapon.stun_ticks)
	if weapon:
		if weapon.fire_chance > 0 and rng.randi_range(1, 100) <= weapon.fire_chance:
			target.start_fire(cell)
		if weapon.breach_chance > 0 and rng.randi_range(1, 100) <= weapon.breach_chance:
			target.breach(cell)
		if weapon.ion > 0 and system:
			system.add_ion(weapon.ion)
		if weapon.spores and system and system.behaviour != "power_core":
			system.spored = true
			system.spore_progress = 0.0
		if weapon.conduit_chance > 0 and rng.randi_range(1, 100) <= weapon.conduit_chance:
			target.break_conduit_at(cell, room_index, rng)
		if weapon.infection_chance > 0 and rng.randi_range(1, 100) <= weapon.infection_chance:
			room.infection = maxf(room.infection, 30.0)
			note("infected", {"ship": target, "room": room_index})
	note("hit", {"ship": target, "room": room_index, "cell": cell, "damage": hull_damage, "position": world_point, "weapon": weapon, "source": source})


## The system whose console stands on a tile, if any.
func _system_on(ship: Ship, cell: Vector2i) -> ShipSystem:
	for system in ship.systems:
		if system.cell == cell:
			return system
	return null


func _tick_bombs() -> void:
	var waiting: Array = []
	for bomb in bombs:
		bomb.ticks -= 1
		if bomb.ticks > 0:
			waiting.append(bomb)
			continue
		var target: Ship = bomb.target
		if target.is_gone():
			continue
		var point := local_to_world(target, target.design.cell_centre(bomb.cell))
		if rng.randi_range(1, 100) <= target.evasion():
			note("miss", {"ship": target, "position": point})
			continue
		if target.supershield > 0:
			target.supershield = maxi(0, target.supershield - 1)
			note("supershield_hit", {"ship": target, "position": point})
			continue
		_hit_tile(target, bomb.cell, bomb.weapon, point, bomb.source)
	bombs = waiting


# --- Beams ----------------------------------------------------------------------------------------------------

func _start_beam(ship: Ship, slot: WeaponSlot) -> void:
	var target := slot.volley_target_ship
	if target == null or target.is_gone():
		return
	var start_local := slot.beam_start
	var end_local := slot.beam_end
	if start_local == end_local:
		var centre := target.rooms[slot.volley_target_room].centre_local(target.design)
		start_local = centre
		end_local = centre + Vector2(slot.def.beam_length, 0)
	beams.append({"weapon": slot.def, "source": ship, "slot": slot, "target": target, "start": start_local, "end": end_local,
			"ticks": 0, "total": 24, "rooms_hit": [], "blocked": false})


func _tick_beams() -> void:
	var still: Array = []
	for beam in beams:
		beam.ticks += 1
		var target: Ship = beam.target
		if target.destroyed:
			continue
		var weapon: WeaponDef = beam.weapon
		var shielded := maxi(0, weapon.damage - target.shield_layers)
		if target.supershield > 0:
			if beam.ticks == 1:
				target.supershield = maxi(0, target.supershield - weapon.damage)
				note("supershield_hit", {"ship": target, "position": local_to_world(target, beam.start)})
			beam.blocked = true
		elif shielded <= 0:
			beam.blocked = true
		var t: float = float(beam.ticks) / beam.total
		var sweep_point: Vector2 = beam.start.lerp(beam.end, clampf(t, 0.0, 1.0))
		beam["point"] = sweep_point
		if not beam.blocked:
			var cell := Vector2i(floor((sweep_point - target.design.cell_offset) / ShipDesign.TILE))
			var room_index := target.room_at(cell)
			if room_index >= 0 and not beam.tiles_hit.has(cell):
				# A beam cuts every tile it crosses; the hull takes its damage once per room swept
				beam.tiles_hit.append(cell)
				var first_in_room: bool = not beam.rooms_hit.has(room_index)
				if first_in_room:
					beam.rooms_hit.append(room_index)
				var applied := WeaponDef.new()
				applied.damage = shielded
				applied.hull_bonus = weapon.hull_bonus
				applied.fire_chance = weapon.fire_chance
				applied.breach_chance = weapon.breach_chance
				applied.crew_damage = weapon.crew_damage
				applied.colour = weapon.colour
				_hit_tile(target, cell, applied, local_to_world(target, sweep_point), beam.source, first_in_room)
		if beam.ticks < beam.total + 6:
			still.append(beam)
	beams = still


# --- Battlesuits ----------------------------------------------------------------------------------------------

func launch_suit(ship: Ship, target: Ship) -> bool:
	var dock := ship.system_by("evb_dock")
	if dock == null or ship.system_power(dock) <= 0 or ship.evb_cooldown > 0 or ship.suits.is_empty() or ship.suit_out:
		return false
	if target == null or target.is_gone():
		return false
	var pilot: CrewMember = null
	for member in ship.crew_in_room(dock.room, ship.side):
		if member.home == ship and member.can_act() and not member.is_moving() and member.race.id != "azurethea":
			pilot = member
			break
	if pilot == null:
		return false
	var suit_def := Library.weapon(ship.suits[0])
	if suit_def == null:
		return false
	if ship.side == 0 and wallet != null and not wallet.spend(suit_def.cost_per_volley):
		note("no_mawjig", {"ship": ship})
		return false
	var suit := Battlesuit.new()
	suit.def = suit_def
	suit.pilot = pilot
	suit.home = ship
	suit.target = target
	suit.side = ship.side
	suit.oxygen_ticks = suit_def.suit_oxygen_ticks + 100 * maxi(0, ship.system_power(dock) - 2)
	suit.position = local_to_world(ship, ship.design.cell_centre(dock.cell))
	suit.previous_position = suit.position
	suit.orbit_angle = rng.randf() * TAU
	pilot.in_suit = true
	pilot.path.clear()
	ship.suit_out = true
	suits.append(suit)
	note("suit_launched", {"ship": ship, "position": suit.position})
	return true


func _tick_suits() -> void:
	var kept: Array[Battlesuit] = []
	for suit in suits:
		if suit.gone:
			suit.home.suit_out = false
			continue
		suit.previous_position = suit.position
		suit.oxygen_ticks -= 1
		if suit.oxygen_ticks <= 0:
			suit.pilot.health -= Ship.SUFFOCATION_PER_TICK
			if suit.pilot.health <= 0.0:
				suit.pilot.dead = true
				suit.gone = true
				suit.home.suit_out = false
				note("crew_died", {"ship": suit.home, "crew": suit.pilot, "position": Vector2.ZERO})
				continue
		if suit.stun_ticks > 0:
			suit.stun_ticks -= 1
			kept.append(suit)
			continue
		var home_point := local_to_world(suit.home, suit.home.design.cell_centre(suit.home.system_by("evb_dock").cell)) if suit.home.system_by("evb_dock") else suit.home.world_position
		var heading_home_ticks := suit.position.distance_to(home_point) / SUIT_SPEED + crossing_seconds("suit") * TICKS + 40.0
		if suit.state != "returning" and (suit.target == null or suit.target.is_gone() or suit.oxygen_ticks < heading_home_ticks or suit.is_damaged()):
			suit.state = "returning"
		match suit.state:
			"outbound", "attacking":
				suit.orbit_angle += 0.012
				var radii := bubble_radii(suit.target) * 1.12
				var orbit_point := local_to_world(suit.target, bubble_centre(suit.target) + Vector2(cos(suit.orbit_angle) * radii.x, sin(suit.orbit_angle) * radii.y))
				suit.position = suit.position.move_toward(orbit_point, SUIT_SPEED * barrier_pace("suit", suit.position, (orbit_point - suit.position).normalized() * SUIT_SPEED))
				if suit.state == "outbound" and suit.position.distance_to(orbit_point) < 30.0:
					suit.state = "attacking"
				if suit.state == "attacking":
					suit.shot_timer -= 1
					if suit.shot_timer <= 0:
						suit.shot_timer = suit.def.suit_shot_ticks
						var cell := _any_cell(suit.target, _suit_target_room(suit))
						var aim := local_to_world(suit.target, suit.target.design.cell_centre(cell))
						var shot := _launch(suit.def, suit.home, suit.target, cell, suit.position, aim, "laser")
						shot.kind = "laser"
						note("shot", {"ship": suit.home, "weapon": suit.def, "position": suit.position})
				kept.append(suit)
			"returning":
				suit.position = suit.position.move_toward(home_point, SUIT_SPEED * barrier_pace("suit", suit.position, (home_point - suit.position).normalized() * SUIT_SPEED))
				if suit.position.distance_to(home_point) < 10.0 or suit.home.destroyed:
					_suit_docks(suit)
					continue
				kept.append(suit)
	suits = kept


func _suit_target_room(suit: Battlesuit) -> int:
	var shields := suit.target.system_by("shields")
	if suit.target_room >= 0:
		return suit.target_room
	if shields:
		return shields.room
	return rng.randi_range(0, suit.target.rooms.size() - 1)


func _suit_docks(suit: Battlesuit) -> void:
	suit.gone = true
	suit.home.suit_out = false
	suit.home.evb_cooldown = 160
	if suit.home.destroyed:
		suit.pilot.dead = true
		return
	var dock := suit.home.system_by("evb_dock")
	suit.pilot.in_suit = false
	suit.pilot.ship = suit.home
	var cell := suit.home.free_cell_in_room(dock.room if dock else 0, suit.pilot.side, suit.pilot)
	suit.pilot.cell = cell
	suit.pilot.destination = cell
	suit.pilot.position = suit.home.design.cell_centre(cell)
	note("suit_docked", {"ship": suit.home})


# --- Teleporter and cloaking ----------------------------------------------------------------------------------

func can_teleport(ship: Ship) -> bool:
	var teleporter := ship.system_by("teleporter")
	return teleporter != null and ship.system_power(teleporter) > 0 and ship.teleporter_cooldown <= 0


## Sends the crew standing in the teleporter room to a room on another ship. A Supershield blocks it.
func send_boarders(ship: Ship, target: Ship, room_index: int) -> bool:
	if not can_teleport(ship) or target == null or target.is_gone() or target.supershield > 0:
		return false
	var teleporter := ship.system_by("teleporter")
	var party: Array[CrewMember] = []
	for member in ship.crew_in_room(teleporter.room, ship.side):
		if member.home == ship and member.can_act() and party.size() < 4:
			party.append(member)
	if party.is_empty():
		return false
	for member in party:
		_land(member, target, room_index)
	ship.teleporter_cooldown = [600, 600, 400, 200][mini(ship.system_power(teleporter), 3)]
	note("teleported", {"ship": ship, "target": target, "count": party.size()})
	return true


func recall_boarders(ship: Ship) -> bool:
	if not can_teleport(ship):
		return false
	var teleporter := ship.system_by("teleporter")
	var any := false
	for member in ship.crew:
		if not member.dead and member.ship != ship and not member.in_suit:
			_land(member, ship, teleporter.room)
			any = true
	if any:
		ship.teleporter_cooldown = [600, 600, 400, 200][mini(ship.system_power(teleporter), 3)]
		note("teleported", {"ship": ship, "target": ship, "count": 0})
	return any


func _land(member: CrewMember, ship: Ship, room_index: int) -> void:
	if member.ship != member.home:
		member.ship.visitors.erase(member)
	member.ship = ship
	if ship != member.home and not ship.visitors.has(member):
		ship.visitors.append(member)
	member.path.clear()
	var cell := ship.free_cell_in_room(room_index, member.side, member)
	member.cell = cell
	member.destination = cell
	member.position = ship.design.cell_centre(cell)
	member.previous_position = member.position
	member.teleporting_ticks = TELEPORT_TICKS


func cloak(ship: Ship) -> bool:
	var system := ship.system_by("cloaking")
	if system == null or ship.system_power(system) <= 0 or ship.cloak_ticks > 0 or ship.cloak_cooldown > 0:
		return false
	ship.cloak_ticks = [100, 100, 200, 300][mini(ship.system_power(system), 3)]
	note("cloaked", {"ship": ship})
	return true


# --- Hazards --------------------------------------------------------------------------------------------------

func _tick_hazard() -> void:
	# Set every tick, hazard or not, so a storm's penalty ends when the squad leaves it
	for ship in ships:
		var stormed := ship.reactor_penalty > 0 or ship.core_capacity_penalty > 0
		ship.reactor_penalty = ship.reactor_level / 2 if hazard == "ion_storm" else 0
		ship.core_capacity_penalty = 2 if hazard == "ion_storm" else 0
		if stormed and hazard != "ion_storm":
			ship.power_everything()   # out of the storm: the power it took comes back
	if hazard.is_empty():
		return
	hazard_timer -= 1
	if hazard_timer > 0:
		return
	var targets: Array[Ship] = []
	for ship in ships:
		if not ship.is_gone():
			targets.append(ship)
	if targets.is_empty():
		return
	match hazard:
		"asteroids":
			hazard_timer = rng.randi_range(120, 260)
			var target := targets[rng.randi_range(0, targets.size() - 1)]
			var room := target.rooms[rng.randi_range(0, target.rooms.size() - 1)]
			var cell: Vector2i = room.cells[rng.randi_range(0, room.cells.size() - 1)]
			var aim := local_to_world(target, target.design.cell_centre(cell))
			var origin := aim + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.3, 0.3)).normalized() * 1500.0
			var rock := _launch(null, null, target, cell, origin, aim, "asteroid")
			rock.velocity = (aim - origin).normalized() * 380.0 / TICKS
			rock.damage = 1
			rock.side = 2
		"sun":
			hazard_timer = 560
			note("flare")
			for ship in targets:
				for count in 2:
					var room := ship.rooms[rng.randi_range(0, ship.rooms.size() - 1)]
					ship.start_fire(room.cells[rng.randi_range(0, room.cells.size() - 1)])
		"collapse_edge":
			hazard_timer = 320
			var victim := targets[rng.randi_range(0, targets.size() - 1)]
			victim.damage_hull(1)
			note("shear", {"ship": victim})
		_:
			hazard_timer = 999999


# --- Geometry -------------------------------------------------------------------------------------------------

## The ship whose shield bubble holds a world point, if any.
func ship_under(world_point: Vector2) -> Ship:
	for ship in ships:
		if not ship.is_gone() and _inside_bubble(ship, world_point):
			return ship
	return null


func in_barrier(world_point: Vector2) -> bool:
	return absf(world_point.y) < BARRIER_HALF_DEPTH


## Seconds a kind of shot (or a battlesuit) takes to cross the barrier at this battle's distance.
func crossing_seconds(kind: String) -> float:
	return gatometers / float(GATOMETERS_PER_SECOND.get(kind, 400.0))


## How much of its normal speed something keeps inside the barrier, so that crossing it takes
## crossing_seconds whatever its speed and angle: the line stays straight, only the time stretches (GDD 3R).
## Shots that don't cross between the squads (asteroids, defence bolts) keep their speed.
func barrier_pace(kind: String, world_point: Vector2, velocity: Vector2) -> float:
	if not GATOMETERS_PER_SECOND.has(kind) or not in_barrier(world_point) or velocity.length_squared() < 0.0001:
		return 1.0
	var direction := velocity.normalized()
	var path := BARRIER_HALF_DEPTH * 2.0 / maxf(absf(direction.y), 0.1)
	var normal_ticks := path / velocity.length()
	return clampf(normal_ticks / maxf(1.0, crossing_seconds(kind) * TICKS), 0.01, 1.0)


func local_to_world(ship: Ship, local: Vector2) -> Vector2:
	return ship.world_position + (-local if ship.facing_down else local)


func world_to_local(ship: Ship, world: Vector2) -> Vector2:
	var offset := world - ship.world_position
	return -offset if ship.facing_down else offset


func can_squad_jump() -> bool:
	for ship in living(0):
		if not ship.jump_ready():
			return false
	return true


func squad_jump_charge() -> float:
	var lowest := 1.0
	for ship in living(0):
		lowest = minf(lowest, ship.jump_charge)
	return lowest
