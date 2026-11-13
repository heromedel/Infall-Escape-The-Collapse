class_name BattleOrders
extends RefCounted
## The orders players give in the battle (GV 4C): power, aiming, crew moves, doors, boarding, suits, cloaking and
## the pause. A player's screen turns a click into an order; every machine plays the order here, in the same
## place in the stream, so the fight stays the same everywhere. Orders name things by their place in the
## encounter (ship, crew, system, weapon and door indexes), not by objects, so they can cross the network.
##
## apply() returns "" when the order was carried out, or why not, for the player who gave it.

const KINDS := ["power", "wpower", "aim", "aim_beam", "aim_suit", "untarget", "autofire", "move", "door", "doors",
		"stations", "save_posts", "board", "recall", "suit", "cloak", "pause"]


# --- Naming things ------------------------------------------------------------------------------------------

static func ship_index(encounter: Encounter, ship: Ship) -> int:
	return encounter.ships.find(ship)


static func crew_ref(encounter: Encounter, member: CrewMember) -> Vector2i:
	return Vector2i(encounter.ships.find(member.home), member.home.crew.find(member))


static func _ship(encounter: Encounter, order: Dictionary, key: String = "s") -> Ship:
	var index := int(order.get(key, -1))
	return encounter.ships[index] if index >= 0 and index < encounter.ships.size() else null


static func crew_at(encounter: Encounter, ref: Vector2i) -> CrewMember:
	return _crew(encounter, ref)


static func _crew(encounter: Encounter, ref: Vector2i) -> CrewMember:
	if ref.x < 0 or ref.x >= encounter.ships.size():
		return null
	var home := encounter.ships[ref.x]
	return home.crew[ref.y] if ref.y >= 0 and ref.y < home.crew.size() else null


static func _weapon(ship: Ship, order: Dictionary) -> WeaponSlot:
	var index := int(order.get("w", -1))
	return ship.weapons[index] if ship and index >= 0 and index < ship.weapons.size() else null


# --- Playing an order ---------------------------------------------------------------------------------------

static func apply(battle: BattleScreen, order: Dictionary) -> String:
	var encounter := battle.encounter
	var ship := _ship(encounter, order)
	match String(order.k):
		"pause":
			battle.set_paused(bool(order.on), int(order.get("p", 0)))
		"autofire":
			for each in encounter.living(0):
				for slot in each.weapons:
					if slot.has_target():
						slot.autofire = bool(order.on)
		"power":
			var index := int(order.get("sys", -1))
			if ship == null or index < 0 or index >= ship.systems.size():
				return ""
			var system := ship.systems[index]
			if bool(order.up):
				if ship.reactor_type == "core" and system.enabled:
					ship.remove_power(system)
				elif not ship.add_power(system):
					if ship.reactor_type == "core":
						return "The AZC is running all the systems it can. Switch another off first."
					return "%s can't hold more power." % system.def.name if system.power >= system.usable_bars() else "No free reactor power."
			else:
				ship.remove_power(system)
		"wpower":
			var slot := _weapon(ship, order)
			if slot and not ship.set_weapon_powered(slot, bool(order.on)):
				if ship.reactor_type == "pool" and ship.reactor_free() < slot.def.power:
					return "Not enough reactor power."
				return "The Weapons system can't hold more power."
		"aim":
			var slot := _weapon(ship, order)
			var target := _ship(encounter, order, "ts")
			if slot and target and not target.is_gone():
				slot.aim_at(target, order.cell)
				slot.autofire = bool(order.auto)
		"aim_beam":
			var slot := _weapon(ship, order)
			var target := _ship(encounter, order, "ts")
			if slot and target and not target.is_gone():
				slot.aim_at(target, order.cell)
				slot.beam_start = order.a
				slot.beam_end = order.b
				slot.autofire = bool(order.auto)
		"aim_suit":
			var slot := _weapon(ship, order)
			var index := int(order.get("suit", -1))
			if slot and index >= 0 and index < encounter.suits.size() and not encounter.suits[index].gone:
				slot.target_suit = encounter.suits[index]
				slot.target_ship = null
				slot.autofire = bool(order.auto)
		"untarget":
			var slot := _weapon(ship, order)
			if slot:
				slot.clear_target()
		"move":
			var target := _ship(encounter, order, "ts")
			var movers: Array[CrewMember] = []
			for ref in order.get("crew", []):
				var member := _crew(encounter, ref)
				if member and member.ship == target and member.is_active():
					movers.append(member)
			if target and not movers.is_empty():
				move_crew(movers, target, order.cell)
		"door":
			var index := int(order.get("d", -1))
			if ship == null or index < 0 or index >= ship.doors.size():
				return ""
			if not ship.doors_controllable():
				return "The Doors system isn't working."
			ship.doors[index].held_open = not ship.doors[index].held_open
		"doors":
			if ship == null:
				return ""
			if not ship.doors_controllable():
				return "The Doors system isn't working."
			# Open Doors a second time, with every inner door already open, opens the airlocks too, as in the genre
			var airlocks := bool(order.airlocks)
			var both: bool = bool(order.open) and not airlocks and ship.doors.all(func(door: ShipDoor): return door.to_space or door.held_open)
			for door in ship.doors:
				if both or door.to_space == airlocks or not bool(order.open):
					door.held_open = bool(order.open)
		"stations":
			if ship:
				for member in ship.crew:
					if member.ship == ship and member.can_act():
						CrewBrain.order_to_room(member, member.station_room, true)
		"save_posts":
			if ship:
				for member in ship.crew:
					if member.ship == ship and not member.dead:
						member.station_room = ship.room_at(member.destination if not member.path.is_empty() else member.cell)
		"board":
			var target := _ship(encounter, order, "ts")
			if ship == null or target == null or not encounter.send_boarders(ship, target, int(order.room)):
				return "The teleporter can't reach that room."
		"recall":
			if ship == null or not encounter.recall_boarders(ship):
				return "The teleporter isn't ready."
		"suit":
			var target := _ship(encounter, order, "ts")
			if ship == null or target == null or not encounter.launch_suit(ship, target):
				return "No one is ready in the EVB Dock."
		"cloak":
			if ship:
				encounter.cloak(ship)
	return ""


## Sends crew to a tile: the first to that tile, the others to the free tiles of the same room nearest to it.
static func move_crew(movers: Array[CrewMember], ship: Ship, cell: Vector2i) -> bool:
	var room_index := ship.room_at(cell)
	if room_index < 0:
		return false
	for member in movers:
		member.destination = Vector2i(999, 999)   # let go of old claims so the group can share the room
	var free: Array[Vector2i] = []
	for each in ship.rooms[room_index].cells:
		if not ship.cell_is_claimed(each, 0):
			free.append(each)
	free.sort_custom(func(a, b): return Vector2(a - cell).length_squared() < Vector2(b - cell).length_squared())
	var moved := false
	for index in movers.size():
		if index >= free.size():
			break
		if CrewBrain.walk_to(movers[index], free[index], true):
			moved = true
	for member in movers:
		if member.destination == Vector2i(999, 999):
			member.destination = member.path.back() if not member.path.is_empty() else member.cell
	return moved
