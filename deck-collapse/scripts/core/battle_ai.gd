## The enemy captain. Each call looks at the battle and picks one action; the caller performs it, animates it,
## and asks again until the AI ends its turn. It uses the same actions and checks as the human captain.
class_name BattleAI
extends RefCounted

## Action shapes: { kind: "play", uid, target } · { kind: "move", crew, system } · { kind: "burn" } ·
## { kind: "reroute" } · { kind: "jump" } · { kind: "end" }
var level := "Normal"
var _rng := RandomNumberGenerator.new()

## Station order when nothing urgent needs a crew member.
const STATION_PRIORITY := ["piloting", "weapon", "shields", "engines", "evb", "sensors", "teleport", "airlock", "medBay"]
## Enemy systems worth breaking, best first.
const TARGET_PRIORITY := ["shields", "weapon", "piloting", "engines", "teleport", "evb", "cloak", "hacking",
	"lifeSupport", "mindControl", "medBay", "sensors", "reactor", "battery", "airlock"]


func _init(ai_level: String = "Normal", seed_value: int = 0) -> void:
	level = ai_level
	_rng.seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec())


func next_action(battle: Battle, side: int) -> Dictionary:
	var ship := battle.ships[side]
	var enemy := battle.ships[1 - side]
	var steps: Array[Callable] = [
		func(): return _play_first(battle, side, "power", {}),
		func(): return _crew_move(battle, side),
		func(): return _crew_cards(battle, side),
		func(): return _free_own_crew(battle, side),
		func(): return _battery_if_needed(battle, side),
		func(): return _play_first(battle, side, "shield", {}),
		func(): return _hack(battle, side),
		func(): return _mind_control(battle, side),
		func(): return _fire_weapons(battle, side),
		func(): return _launch_suit(battle, side),
		func(): return _teleport(battle, side),
		func(): return _cloak(battle, side),
		func(): return _jump(battle, side),
		func(): return _burn(battle, side),
	]
	for step in steps:
		var action: Dictionary = step.call()
		if not action.is_empty():
			return action
	if battle.why_cannot_reroute(side) == "" and ship.power_row.size() < ship.capacity_of_type("reactor"):
		return {"kind": "reroute"}
	return {"kind": "end"}


# ---------------------------------------------------------------- crew

func _crew_move(battle: Battle, side: int) -> Dictionary:
	var ship := battle.ships[side]
	var free := battle.living_crew_of(side).filter(func(m): return m.controlled_by < 0)
	var wanted := _wanted_stations(battle, side)
	var assignment := {}  # crew id -> system id
	var unassigned := free.duplicate()
	for station in wanted:
		if unassigned.is_empty():
			break
		var ship_side: int = station.ship
		var system_id: String = station.system
		var chosen := {}
		for member in unassigned:
			if member.ship == ship_side and member.system == system_id:
				chosen = member
				break
		if chosen.is_empty():
			for member in unassigned:
				var fits: bool = member.wounds >= 2 if station.get("wounded_only", false) else true
				if member.ship == ship_side and not member.moved and fits:
					chosen = member
					break
		if chosen.is_empty():
			continue
		unassigned.erase(chosen)
		assignment[chosen.id] = system_id
	for member in free:
		if assignment.has(member.id) and member.system != assignment[member.id]:
			if battle.why_cannot_move(side, member, assignment[member.id]) == "":
				return {"kind": "move", "crew": member.id, "system": assignment[member.id]}
	return {}


## Where crew should be this turn, most urgent first: { ship, system, wounded_only? }.
func _wanted_stations(battle: Battle, side: int) -> Array:
	var ship := battle.ships[side]
	var wanted: Array = []
	var hand_ids := ship.hand.map(func(card): return card.id)
	var med_bay := ship.first_system_of_type("medBay")
	# Badly hurt crew go to the Med Bay.
	if med_bay != "" and ship.capacity(med_bay) > 0:
		for member in battle.living_crew_of(side):
			if member.wounds >= 2 and member.ship == side:
				wanted.append({"ship": side, "system": med_bay, "wounded_only": true})
	# Boarders on our ship get met.
	for member in battle.living_crew():
		if member.owner != side and member.ship == side:
			wanted.append({"ship": side, "system": member.system})
	# Fires, breaches and damage get a worker when we hold a Repair.
	if "repair" in hand_ids:
		for system_id in ship.system_order:
			if ship.systems[system_id].on_fire:
				wanted.append({"ship": side, "system": system_id})
		for type in ["lifeSupport"] + STATION_PRIORITY + ["reactor", "battery", "cloak", "hacking", "mindControl"]:
			for system_id in ship.system_order:
				if ship.systems[system_id].type == type and Battle.needs_repair(ship.systems[system_id]):
					wanted.append({"ship": side, "system": system_id})
	# A launch needs someone in the EVB Dock right after the pilot.
	if "suit" in hand_ids:
		wanted.append({"ship": side, "system": ship.first_system_of_type("piloting")})
		for card in ship.hand:
			if card.id == "suit":
				wanted.append({"ship": side, "system": card.system})
	# Ordinary stations.
	for type in STATION_PRIORITY:
		if type == "evb" and not "suit" in hand_ids:
			continue
		if type == "medBay":
			continue
		for system_id in ship.system_order:
			if ship.systems[system_id].type == type:
				wanted.append({"ship": side, "system": system_id})
	return wanted


func _crew_cards(battle: Battle, side: int) -> Dictionary:
	var ship := battle.ships[side]
	for system_id in _systems_by_importance(ship):
		var action := _play_first(battle, side, "repair", {"system": system_id, "ship": side})
		if not action.is_empty():
			return action
	if battle.life_support_down(ship):
		var action := _play_first(battle, side, "restore", {})
		if not action.is_empty():
			return action
	# Vent a burning or boarded system nobody of ours is in.
	for system_id in ship.system_order:
		var system: Dictionary = ship.systems[system_id]
		var ours_inside := battle.crew_in_system(side, system_id).any(func(m): return m.owner == side)
		var boarders_inside := battle.crew_in_system(side, system_id).any(func(m): return m.owner != side)
		if (system.on_fire or boarders_inside) and not ours_inside:
			var action := _play_first(battle, side, "airlock", {"system": system_id, "ship": side})
			if not action.is_empty():
				return action
	return {}


func _free_own_crew(battle: Battle, side: int) -> Dictionary:
	for member in battle.living_crew_of(side):
		if member.controlled_by >= 0:
			var action := _play_first(battle, side, "mindControl", {"crew": member.id})
			if not action.is_empty():
				return action
	return {}


# ---------------------------------------------------------------- tactics

func _battery_if_needed(battle: Battle, side: int) -> Dictionary:
	var ship := battle.ships[side]
	var wanted_power := 0
	for card in ship.hand:
		wanted_power += battle.card_definition(ship, card).cost
	if wanted_power > ship.available_power():
		return _play_first(battle, side, "battery", {})
	return {}


func _hack(battle: Battle, side: int) -> Dictionary:
	if level == "Easy":
		return {}
	var enemy := battle.ships[1 - side]
	var targets: Array = []
	if not enemy.shield_layers.is_empty() and _has_weapon_cards(battle, side):
		targets.append(enemy.first_system_of_type("shields"))
	targets.append_array(_ranked_targets(battle, side))
	for system_id in targets:
		if enemy.systems[system_id].disabled_turns > 0 or enemy.systems[system_id].type == "reactor":
			continue
		var action := _play_first(battle, side, "hack", {"system": system_id, "ship": 1 - side})
		if not action.is_empty():
			return action
	return {}


func _mind_control(battle: Battle, side: int) -> Dictionary:
	var enemy := battle.ships[1 - side]
	var victims := battle.living_crew_of(1 - side).filter(func(m): return m.ship == 1 - side and m.controlled_by < 0)
	victims.sort_custom(func(a, b): return CrewSkills.total(a.skills) > CrewSkills.total(b.skills))
	var targets := _ranked_targets(battle, side)
	for victim in victims:
		for system_id in targets:
			if enemy.is_broken(system_id):
				continue
			var action := _play_first(battle, side, "mindControl", {"crew": victim.id, "system": system_id, "ship": 1 - side})
			if not action.is_empty():
				return action
	return {}


func _fire_weapons(battle: Battle, side: int) -> Dictionary:
	var ship := battle.ships[side]
	var enemy := battle.ships[1 - side]
	var weapon_cards := ship.hand.filter(func(card): return card.id == "weapon")
	# Ion first to strip shields, then torpedoes, then bolts, then beams once shields are down.
	var order := {"ion": 0, "missile": 1, "heavy": 2, "laser": 3, "chain": 3, "beam": 4}
	weapon_cards.sort_custom(func(a, b): return order.get(ship.systems[a.system].kind, 3) < order.get(ship.systems[b.system].kind, 3))
	for card in weapon_cards:
		var kind: String = ship.systems[card.system].kind
		if kind == "beam" and not enemy.shield_layers.is_empty() and level != "Easy":
			var beam_damage: int = Catalog.weapon_profile(kind, ship.systems[card.system].weapon_type).damage
			if beam_damage <= enemy.shield_layers.size():
				continue
		for system_id in _weapon_targets(battle, side, kind):
			if battle.why_cannot_play(side, card.uid, {"system": system_id, "ship": 1 - side}) == "":
				return {"kind": "play", "uid": card.uid, "target": {"system": system_id, "ship": 1 - side}}
	return {}


func _weapon_targets(battle: Battle, side: int, kind: String) -> Array:
	var enemy := battle.ships[1 - side]
	var ranked := _ranked_targets(battle, side)
	if level == "Easy":
		ranked.shuffle()
		return ranked
	var shields_id := enemy.first_system_of_type("shields")
	if kind in ["ion", "missile"] and shields_id != "" and not enemy.shield_layers.is_empty():
		ranked.erase(shields_id)
		ranked.push_front(shields_id)
	if kind == "beam":
		# Beams burn crew: aim where the most enemy crew stand among the top targets.
		ranked.sort_custom(func(a, b): return battle.crew_in_system(1 - side, a).size() > battle.crew_in_system(1 - side, b).size())
	return ranked


## Enemy systems in the order worth hitting. Hard captains finish off nearly broken systems first.
func _ranked_targets(battle: Battle, side: int) -> Array:
	var enemy := battle.ships[1 - side]
	var ranked: Array = []
	for type in TARGET_PRIORITY:
		for system_id in enemy.system_order:
			if enemy.systems[system_id].type == type:
				ranked.append(system_id)
	var useful := ranked.filter(func(system_id): return not enemy.is_broken(system_id))
	var broken := ranked.filter(func(system_id): return enemy.is_broken(system_id))
	if level == "Hard":
		useful.sort_custom(func(a, b):
			var left_a: int = enemy.systems[a].level - enemy.systems[a].damage
			var left_b: int = enemy.systems[b].level - enemy.systems[b].damage
			return ranked.find(a) + left_a * 3 < ranked.find(b) + left_b * 3)
	elif level == "Normal" and _rng.randf() < 0.25:
		useful.shuffle()
	return useful + broken


func _launch_suit(battle: Battle, side: int) -> Dictionary:
	var ship := battle.ships[side]
	var enemy := battle.ships[1 - side]
	for card in ship.hand:
		if card.id != "suit":
			continue
		var definition := battle.card_definition(ship, card)
		if definition.target == CardLibrary.TARGET_NONE:
			var wanted := true
			if definition.suit == "repair":
				wanted = ship.systems.values().any(func(s): return s.damage > 0)
			elif definition.suit == "guardian":
				wanted = enemy.weapon_systems().any(func(id): return Catalog.weapon_kind(enemy.systems[id].kind).uses_missile)
			if wanted and battle.why_cannot_play(side, card.uid, {}) == "":
				return {"kind": "play", "uid": card.uid, "target": {}}
			continue
		var targets := _ranked_targets(battle, side)
		if definition.suit == "ion" and not enemy.shield_layers.is_empty():
			targets.push_front(enemy.first_system_of_type("shields"))
		for system_id in targets:
			if battle.why_cannot_play(side, card.uid, {"system": system_id, "ship": 1 - side}) == "":
				return {"kind": "play", "uid": card.uid, "target": {"system": system_id, "ship": 1 - side}}
	return {}


func _teleport(battle: Battle, side: int) -> Dictionary:
	var ship := battle.ships[side]
	# Bring hurt boarders home to the Med Bay (or anywhere).
	for member in battle.living_crew_of(side):
		if member.ship != side and member.wounds >= 2:
			var home := ship.first_system_of_type("medBay")
			if home == "":
				home = ship.system_order[0]
			var action := _play_first(battle, side, "teleport", {"crew": member.id, "system": home, "ship": side})
			if not action.is_empty():
				return action
	var boarders := battle.living_crew_of(side).filter(func(m): return m.ship != side).size()
	if boarders >= 2 or level == "Easy" and boarders >= 1:
		return {}
	var crew_aboard := battle.living_crew_of(side).filter(func(m): return m.ship == side and m.controlled_by < 0 and m.wounds == 0)
	if crew_aboard.size() < 2:
		return {}
	crew_aboard.sort_custom(func(a, b): return int(a.skills.combat) > int(b.skills.combat))
	var enemy := battle.ships[1 - side]
	for system_id in _ranked_targets(battle, side):
		if enemy.is_broken(system_id):
			continue
		var action := _play_first(battle, side, "teleport", {"crew": crew_aboard[0].id, "system": system_id, "ship": 1 - side})
		if not action.is_empty():
			return action
	return {}


func _cloak(battle: Battle, side: int) -> Dictionary:
	var ship := battle.ships[side]
	if ship.hull * 3 <= ship.hull_max * 2 or level == "Hard":
		return _play_first(battle, side, "cloak", {})
	return {}


## Jump: in the aftermath to leave (repairs come earlier in the step order), mid-battle only to flee.
## The Jig Drive charges by itself on turns the Engines burn.
func _jump(battle: Battle, side: int) -> Dictionary:
	if battle.aftermath:
		if battle.why_cannot_jump(side) == "":
			return {"kind": "jump"}
		return {}
	if level == "Easy" or Settings.value("jump_escape") == "Off":
		return {}
	var ship := battle.ships[side]
	var enemy := battle.ships[1 - side]
	var losing := float(ship.hull) / ship.hull_max < 0.3 and float(enemy.hull) / enemy.hull_max > 0.5
	if losing and battle.why_cannot_jump(side) == "":
		return {"kind": "jump"}
	return {}


func _burn(battle: Battle, side: int) -> Dictionary:
	# Every earlier step has passed, so any power left over goes into evasion.
	if battle.why_cannot_burn(side) != "":
		return {}
	return {"kind": "burn"}


# ---------------------------------------------------------------- helpers

## Plays the first card with this id that is legal against the target.
func _play_first(battle: Battle, side: int, card_id: String, target: Dictionary) -> Dictionary:
	for card in battle.ships[side].hand:
		if card.id == card_id and battle.why_cannot_play(side, card.uid, target) == "":
			return {"kind": "play", "uid": card.uid, "target": target}
	return {}


func _has_weapon_cards(battle: Battle, side: int) -> bool:
	return battle.ships[side].hand.any(func(card): return card.id == "weapon")


func _systems_by_importance(ship: ShipState) -> Array:
	var ordered: Array = []
	for type in ["lifeSupport", "shields", "weapon", "piloting", "engines", "reactor", "medBay", "teleport", "evb",
			"cloak", "hacking", "mindControl", "sensors", "battery", "airlock"]:
		for system_id in ship.system_order:
			if ship.systems[system_id].type == type:
				ordered.append(system_id)
	return ordered
