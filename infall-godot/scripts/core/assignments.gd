class_name Assignments
extends RefCounted
## Who commands what (GV 4I): each ship goes to Any player or to specific players, and its crew with it; a crew
## member can also be assigned on their own. The Admiral may always give orders. The host checks every order before
## it goes on the stream, so a refused order never reaches the other machines; the Admiral's assignments are orders
## themselves, played the same way everywhere.

## Orders that command one ship, named by its place in the encounter ("s").
const SHIP_ORDERS := ["power", "wpower", "aim", "aim_beam", "aim_suit", "untarget", "door", "doors", "stations",
		"save_posts", "board", "recall", "suit", "cloak"]
## Refits that change one ship of the squad ("sq"); buying a ship, repairs and selling are the squad's.
const SHIP_REFITS := ["buy_weapon", "buy_crew", "buy_system", "upgrade_system", "upgrade_reactor", "unfit", "fit", "crew_to", "dismiss", "promote"]


## Why a player may not give an order, or "" when they may.
static func refusal(main: Node, order: Dictionary) -> String:
	var who := int(order.get("p", 0))
	if main.session.is_admiral(who) or main.run == null:
		return ""
	var kind := String(order.k)
	if kind in SHIP_ORDERS and main.encounter:
		var index := int(order.get("s", -1))
		if index >= 0 and index < main.encounter.ships.size() and not main.encounter.ships[index].commanded_by(who):
			return _not_yours(main, main.encounter.ships[index].assigned)
	if kind == "move" and main.encounter:
		for ref in order.get("crew", []):
			var member := BattleOrders.crew_at(main.encounter, ref)
			if member and not member.commanded_by(who):
				return "%s takes orders from %s." % [member.name, _names(main, member.assigned if member.own_assignment else member.home.assigned)]
	if kind == "refit" and String(order.op) in SHIP_REFITS:
		var index := int(order.get("sq", -1))
		if index >= 0 and index < main.run.squad.size() and not main.run.squad[index].commanded_by(who):
			return _not_yours(main, main.run.squad[index].assigned)
	return ""


static func _not_yours(main: Node, assigned: Array) -> String:
	return "That ship is %s's to command." % _names(main, assigned)


static func _names(main: Node, ids: Array) -> String:
	return " or ".join(ids.map(func(id): return main.session.titled_name(id)))


## Plays an assignment (the Admiral's order), a handover (a player who left: theirs go to the Admiral, GV 4J) or a
## restore (the Admiral gives a player back what they commanded before they left, GDD 4F).
static func apply(run: RunState, order: Dictionary) -> void:
	match String(order.k):
		"assign":
			var index := int(order.get("sq", -1))
			if index < 0 or index >= run.squad.size():
				return
			var ship := run.squad[index]
			var players: Array = order.get("players", []).map(func(id): return int(id))
			var crew_index := int(order.get("crew", -1))
			if crew_index < 0:
				ship.assigned = players
			elif crew_index < ship.crew.size():
				var member := ship.crew[crew_index]
				member.own_assignment = bool(order.get("own", true))
				member.assigned = players if member.own_assignment else []
		"handover":
			var from := int(order.from)
			var to := int(order.to)
			var remembered := {"ships": {}, "crew": {}}
			for ship in run.squad:
				if ship.assigned.has(from):
					remembered.ships[ship] = ship.assigned.duplicate()
				ship.assigned = _swap(ship.assigned, from, to)
				for member in ship.crew:
					if member.assigned.has(from):
						remembered.crew[member] = [member.assigned.duplicate(), member.own_assignment]
					member.assigned = _swap(member.assigned, from, to)
			if not remembered.ships.is_empty() or not remembered.crew.is_empty():
				run.left_commands[from] = remembered
		"restore":
			var remembered: Dictionary = run.left_commands.get(int(order.player), {})
			run.left_commands.erase(int(order.player))
			for ship in remembered.get("ships", {}):
				if run.squad.has(ship) and not ship.is_gone():
					ship.assigned = remembered.ships[ship]
			for member in remembered.get("crew", {}):
				if not member.dead and run.squad.has(member.home):
					member.assigned = remembered.crew[member][0]
					member.own_assignment = remembered.crew[member][1]


## What a player who left used to command, for the Admiral's eyes: "the Outrider and Sable", or "".
static func remembered_text(run: RunState, player_id: int) -> String:
	var remembered: Dictionary = run.left_commands.get(player_id, {})
	var names: Array = []
	for ship in remembered.get("ships", {}):
		if run.squad.has(ship) and not ship.is_gone():
			names.append("the " + ship.name)
	for member in remembered.get("crew", {}):
		if not member.dead and run.squad.has(member.home):
			names.append(member.display_name())
	return " and ".join(names) if names.size() <= 2 else ", ".join(names.slice(0, -1)) + " and " + names.back()


static func _swap(ids: Array, from: int, to: int) -> Array:
	if not ids.has(from):
		return ids
	var swapped := ids.filter(func(id): return id != from)
	if not swapped.has(to):
		swapped.append(to)
	return swapped
