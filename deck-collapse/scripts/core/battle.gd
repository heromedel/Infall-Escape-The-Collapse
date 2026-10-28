## The rules of a card battle between two ships. It holds the battle's state and changes it only through
## the captain actions below (play a card, move crew, burn engines, reroute power, end turn).
## Each action returns the events it caused, in order, so the screen can animate them; the Battle never draws.
class_name Battle
extends RefCounted

const OPENING_HAND := 7
const OPENING_POWER := 2
const WOUNDS_TO_DIE := 3
const JUMP_CHARGES_NEEDED := 3
const CLOAK_EVASION := 40
const BURN_EVASION := 5
const EVASION_CAP := 80
const MAX_CHAIN_COPIES := 3
const SKILL_NAMES := ["Green", "Trained", "Veteran"]

const OUTCOME_DESTROYED := "destroyed"
const OUTCOME_CREW_LOST := "crew_lost"
const OUTCOME_ESCAPED := "escaped"

var ships: Array[ShipState] = []
## Every crew member of both ships: { id, owner, name, skill, wounds, ship, system, moved, acted, controlled_by }.
## "ship" is the side of the ship they stand on; "controlled_by" is -1 or the side mind-controlling them.
var crew: Array = []
var active_side := 0
var turn_number := 1
var over := false
var winner := -1
var outcome := ""
## Side that jumped away, when the outcome is an escape.
var escaped_side := -1
var rng := RandomNumberGenerator.new()
var draw_per_turn := 1
var guaranteed_opening_power := false
## Events from setting up the battle and starting the first turn.
var opening_events: Array = []

var _events: Array = []
var _next_uid := 1
var _next_crew_id := 1


func _init(design_a: ShipDesign, design_b: ShipDesign, first_side: int, seed_value: int = 0) -> void:
	rng.seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec())
	draw_per_turn = int(Settings.value("draw_per_turn"))
	guaranteed_opening_power = Settings.value("opening_power") == "2 Guaranteed"
	for side in 2:
		var design := design_a if side == 0 else design_b
		var ship := ShipState.new(side, design)
		ships.append(ship)
		for entry in CardLibrary.deck_list(design):
			ship.deck.append(_new_card(entry.id, entry.system))
		_shuffle(ship.deck)
		for member in design.crew:
			var station: String = member.station if ship.systems.has(member.station) else ship.system_order[0]
			crew.append({"id": _next_crew_id, "owner": side, "name": member.name, "skill": member.skill, "wounds": 0,
				"ship": side, "system": station, "moved": false, "acted": false, "controlled_by": -1})
			_next_crew_id += 1
	for ship in ships:
		_deal_opening_hand(ship)
	active_side = first_side
	_log("Battle start: %s vs %s. %s goes first." % [ships[0].name, ships[1].name, ships[first_side].name])
	_start_turn(first_side, true)
	opening_events = _events
	_events = []


# ---------------------------------------------------------------- captain actions

## Plays a card from the side's hand. target: { system, ship, crew } as the card needs. Returns events.
func play_card(side: int, uid: int, target: Dictionary = {}) -> Array:
	_events = []
	var reason := why_cannot_play(side, uid, target)
	if reason != "":
		_emit({"type": "refused", "side": side, "reason": reason})
		return _events
	var ship := ships[side]
	var card := _card_in_hand(ship, uid)
	var definition := card_definition(ship, card)
	ship.hand.erase(card)
	_pay(ship, card, definition)
	ship.cards_played_this_turn += 1
	_emit({"type": "card_played", "side": side, "card": card, "definition": definition, "target": target})
	_resolve_card(ship, card, definition, target)
	_check_battle_end()
	return _events


## Moves a crew member to another system on the ship they stand on. Once per crew member per turn.
func move_crew(side: int, crew_id: int, system_id: String) -> Array:
	_events = []
	var member := crew_by_id(crew_id)
	var reason := why_cannot_move(side, member, system_id)
	if reason != "":
		_emit({"type": "refused", "side": side, "reason": reason})
		return _events
	var from_system: String = member.system
	member.system = system_id
	member.moved = true
	_emit({"type": "crew_moved", "side": side, "crew": crew_id, "from": from_system, "to": system_id, "ship": member.ship})
	_log("%s moves to %s." % [member.name, ships[member.ship].systems[system_id].name], side)
	return _events


## Spends 1 power on Engines for +10% evasion until the captain's next turn. Limited by the Engines level.
func burn_engines(side: int) -> Array:
	_events = []
	var reason := why_cannot_burn(side)
	if reason != "":
		_emit({"type": "refused", "side": side, "reason": reason})
		return _events
	var ship := ships[side]
	var engines_id := ship.first_system_of_type("engines")
	_spend_power(ship, 1)
	ship.spent[engines_id] = int(ship.spent.get(engines_id, 0)) + 1
	ship.burns += 1
	_emit({"type": "burn", "side": side, "system": engines_id})
	_log("Engines burn: evasion now %d%%." % evasion(ship), side)
	return _events


## If the captain played no cards this turn: put a Power card from the deck into play, shuffle, and end the turn.
func reroute_power(side: int) -> Array:
	_events = []
	var reason := why_cannot_reroute(side)
	if reason != "":
		_emit({"type": "refused", "side": side, "reason": reason})
		return _events
	var ship := ships[side]
	for card in ship.deck:
		if card.id == "power":
			ship.deck.erase(card)
			ship.power_row.append({"card": card, "flipped": false, "held": false})
			break
	_shuffle(ship.deck)
	_emit({"type": "reroute", "side": side})
	_log("Reroutes power: a Power Cell comes online.", side)
	_finish_turn(side)
	return _events


## Ends the side's turn: end-of-turn hazards, then the other captain's turn starts. Returns events.
func end_turn(side: int) -> Array:
	_events = []
	if over or side != active_side:
		return _events
	_finish_turn(side)
	return _events


func _finish_turn(side: int) -> void:
	_emit({"type": "turn_end", "side": side})
	_end_of_turn_effects(ships[side])
	_check_battle_end()
	if over:
		return
	turn_number += 1
	_start_turn(1 - side, false)
	_check_battle_end()


# ---------------------------------------------------------------- questions the screen and the AI ask

func card_definition(ship: ShipState, card: Dictionary) -> Dictionary:
	return CardLibrary.definition(card, ship.systems)


## Why the card can't be played right now, or "" if it can. With a target, also checks the target.
func why_cannot_play(side: int, uid: int, target: Dictionary = {}) -> String:
	if over:
		return "The battle is over."
	if side != active_side:
		return "Not your turn."
	var ship := ships[side]
	var card := _card_in_hand(ship, uid)
	if card.is_empty():
		return "That card isn't in your hand."
	var definition := card_definition(ship, card)
	var system_id := _paying_system(ship, card)
	if system_id != "":
		if not ship.systems.has(system_id):
			return "You have no %s." % _system_name_for_card(card)
		var system: Dictionary = ship.systems[system_id]
		if system.disabled_turns > 0:
			return "%s is disabled this turn." % system.name
		if ship.system_room(system_id) < maxi(1, definition.cost):
			if ship.capacity(system_id) < maxi(1, definition.cost):
				return "%s is too damaged." % system.name
			return "%s can't take more power this turn." % system.name
	if ship.available_power() < definition.cost:
		return "Needs %d power." % definition.cost
	var special := _card_requirement_problem(ship, card, definition)
	if special != "":
		return special
	if not target.is_empty() or definition.target == CardLibrary.TARGET_NONE:
		return _target_problem(ship, card, definition, target)
	return ""


## Like why_cannot_play, but an aimed card also needs at least one valid target right now.
func why_cannot_play_anywhere(side: int, uid: int) -> String:
	var reason := why_cannot_play(side, uid)
	if reason != "":
		return reason
	var definition := card_definition(ships[side], _card_in_hand(ships[side], uid))
	if definition.target != CardLibrary.TARGET_NONE and valid_targets(side, uid).is_empty():
		return "No valid target right now."
	return ""


## Every valid target for a card, for highlighting. For crew-then-system cards, pass the chosen crew id.
func valid_targets(side: int, uid: int, chosen_crew_id: int = -1) -> Array:
	var ship := ships[side]
	var card := _card_in_hand(ship, uid)
	if card.is_empty():
		return []
	var definition := card_definition(ship, card)
	var candidates: Array = []
	match definition.target:
		CardLibrary.TARGET_ENEMY_SYSTEM:
			for system_id in ships[1 - side].system_order:
				candidates.append({"system": system_id, "ship": 1 - side})
		CardLibrary.TARGET_OWN_SYSTEM:
			for system_id in ship.system_order:
				candidates.append({"system": system_id, "ship": side})
		CardLibrary.TARGET_CREW_THEN_SYSTEM:
			if chosen_crew_id < 0:
				for member in living_crew():
					candidates.append({"crew": member.id})
			else:
				var member := crew_by_id(chosen_crew_id)
				for ship_side in 2:
					for system_id in ships[ship_side].system_order:
						candidates.append({"crew": chosen_crew_id, "system": system_id, "ship": ship_side})
				if not member.is_empty():
					candidates.append({"crew": chosen_crew_id})
	return candidates.filter(func(target): return _target_problem(ship, card, definition, target) == "" or (
		definition.target == CardLibrary.TARGET_CREW_THEN_SYSTEM and chosen_crew_id < 0 and _crew_choice_problem(ship, card, target.crew) == ""))


func why_cannot_move(side: int, member: Dictionary, system_id: String) -> String:
	if over or side != active_side:
		return "Not your turn."
	if member.is_empty() or member.wounds >= WOUNDS_TO_DIE:
		return "No such crew member."
	if member.owner != side or member.controlled_by >= 0:
		return "%s isn't under your command." % member.name
	if member.moved:
		return "%s has already moved this turn." % member.name
	if not ships[member.ship].systems.has(system_id):
		return "No such system on that ship."
	if member.system == system_id:
		return "%s is already there." % member.name
	return ""


func why_cannot_burn(side: int) -> String:
	if over or side != active_side:
		return "Not your turn."
	if Settings.value("engine_burn") == "Off":
		return "Engine Burn is off in Settings."
	var ship := ships[side]
	var engines_id := ship.first_system_of_type("engines")
	if engines_id == "":
		return "No Engines."
	if ship.system_room(engines_id) < 1:
		return "Engines can't take more power this turn."
	if ship.available_power() < 1:
		return "No power left."
	return ""


func why_cannot_reroute(side: int) -> String:
	if over or side != active_side:
		return "Not your turn."
	var ship := ships[side]
	if ship.cards_played_this_turn > 0:
		return "Only when you play no cards this turn."
	if not ship.deck.any(func(card): return card.id == "power"):
		return "No Power cards left in your deck."
	return ""


func living_crew() -> Array:
	return crew.filter(func(member): return member.wounds < WOUNDS_TO_DIE)


func crew_by_id(crew_id: int) -> Dictionary:
	for member in crew:
		if member.id == crew_id and member.wounds < WOUNDS_TO_DIE:
			return member
	return {}


## Living crew standing in a system of a ship (any owner).
func crew_in_system(ship_side: int, system_id: String) -> Array:
	return living_crew().filter(func(member): return member.ship == ship_side and member.system == system_id)


## The best skill among the ship's own, free crew in a system, or -1 if nobody mans it.
func manning_skill(ship: ShipState, system_id: String) -> int:
	var best := -1
	for member in crew_in_system(ship.side, system_id):
		if member.owner == ship.side and member.controlled_by < 0:
			best = maxi(best, member.skill)
	return best


## Chance to dodge a shot, in percent.
func evasion(ship: ShipState) -> int:
	var piloting_id := ship.first_system_of_type("piloting")
	if piloting_id == "" or ship.capacity(piloting_id) <= 0:
		return 0
	var pilot_skill := manning_skill(ship, piloting_id)
	var unmanned_factor := 0.0
	match ship.capacity(piloting_id):
		2: unmanned_factor = 0.5
		3: unmanned_factor = 1.0
	var factor := 1.0 if pilot_skill >= 0 else unmanned_factor
	var engines_id := ship.first_system_of_type("engines")
	var base := 0
	if engines_id != "":
		base += ship.capacity(engines_id) * 5
		var engine_skill := manning_skill(ship, engines_id)
		if engine_skill >= 0 and ship.capacity(engines_id) > 0:
			base += 5 * (engine_skill + 1)
	if pilot_skill >= 0:
		base += 5 * (pilot_skill + 1)
	var total := int(base * factor) + ship.burns * BURN_EVASION + (CLOAK_EVASION if ship.cloaked else 0)
	return clampi(total, 0, EVASION_CAP)


## Chance in percent that a shot from this weapon system hits the defender.
func hit_chance(attacker: ShipState, weapon_system_id: String, defender: ShipState) -> int:
	var system: Dictionary = attacker.systems.get(weapon_system_id, {})
	if system.get("type", "") == "weapon" and Catalog.weapon_kind(system.kind).never_misses:
		return 100
	var bonus := 0
	var skill := manning_skill(attacker, weapon_system_id)
	if skill >= 0:
		bonus = 5 * (skill + 1)
	return clampi(100 - evasion(defender) + bonus, 5, 100)


## What the viewer's sensors reveal about the other ship.
func sensor_view(viewer_side: int) -> Dictionary:
	if Settings.value("sensor_fog") == "Off":
		return {"crew": true, "power": true, "weapons": true, "hand": true}
	var viewer := ships[viewer_side]
	var sensors_id := viewer.first_system_of_type("sensors")
	var level := viewer.capacity(sensors_id) if sensors_id != "" else 0
	var manned := sensors_id != "" and manning_skill(viewer, sensors_id) >= 0
	return {"crew": level >= 1, "power": level >= 2, "weapons": level >= 3, "hand": level >= 3 and manned}


func living_crew_of(side: int) -> Array:
	return living_crew().filter(func(member): return member.owner == side)


# ---------------------------------------------------------------- turn flow

func _start_turn(side: int, first_turn_of_battle: bool) -> void:
	active_side = side
	var ship := ships[side]
	# 1. Clean up what lasted until this captain's turn.
	if not ship.cloaked:
		ship.cloak_streak = 0
	ship.cloaked = false
	if not ship.hacked_this_turn:
		ship.hack_streak = 0
	ship.hacked_this_turn = false
	ship.burns = 0
	ship.spent.clear()
	ship.cards_played_this_turn = 0
	ship.temporary_power = 0
	for member in crew:
		if member.owner == side:
			member.moved = false
			member.acted = false
	for guardian in ships[1 - side].suits:
		guardian.ready = true
	_emit({"type": "turn_start", "side": side, "turn": turn_number})
	_log("— %s's turn —" % ship.name, side)
	_heal_in_med_bay(ship)
	# 2. Recharge power.
	for entry in ship.power_row:
		if not entry.held:
			entry.flipped = false
	# 3. Draw.
	if not first_turn_of_battle:
		for i in draw_per_turn:
			_draw(ship)


func _end_of_turn_effects(ship: ShipState) -> void:
	var enemy := ships[1 - ship.side]
	_suits_act(ship, enemy)
	# Enemy boarding suits bore into this ship as its captain's turn ends.
	for suit in enemy.suits:
		if Catalog.suit_kind(suit.kind).action == "board" and not ship.is_broken(suit.target):
			_emit({"type": "suit_bores", "side": enemy.side, "target": suit.target})
			_log("A boarding suit tears into %s." % ship.systems[suit.target].name, enemy.side)
			_damage_system(ship, suit.target, 1, true, "boarding suit")
	# Fire, breaches and air: hazards hurt this captain's ship at the end of their turn.
	for system_id in ship.system_order:
		var system: Dictionary = ship.systems[system_id]
		if system.on_fire:
			_damage_system(ship, system_id, 1, false, "fire")
			_wound_all_in(ship.side, system_id, "fire")
		if system.breached:
			_wound_all_in(ship.side, system_id, "breach")
	var life_support_id := ship.first_system_of_type("lifeSupport")
	if life_support_id != "" and ship.capacity(life_support_id) <= 0:
		_log("Life Support is down: everyone aboard %s struggles to breathe." % ship.name, ship.side)
		for member in living_crew().filter(func(m): return m.ship == ship.side):
			_wound(member, "no air")
	# Boarders and mind-controlled crew sabotage the system they stand in.
	for member in living_crew().filter(func(m): return m.ship == ship.side and (m.owner != ship.side or m.controlled_by >= 0)):
		var system_id: String = member.system
		if not ship.is_broken(system_id):
			_emit({"type": "sabotage", "crew": member.id, "ship": ship.side, "system": system_id})
			_log("%s sabotages %s." % [member.name, ship.systems[system_id].name], 1 - ship.side)
			_damage_system(ship, system_id, 1, true, "sabotage")
		if member.controlled_by >= 0 and member.owner == ship.side:
			member.controlled_by = -1
			_emit({"type": "mind_released", "crew": member.id})
			_log("%s shakes off the mind control." % member.name, ship.side)
	_crew_fights(ship)
	# Ion and hacks wear off after the turn they blocked.
	for system_id in ship.system_order:
		var system: Dictionary = ship.systems[system_id]
		if system.disabled_turns > 0:
			system.disabled_turns -= 1
	ship.temporary_power = 0


## The ship's battlesuits act as its captain's turn ends, then count down their time out.
func _suits_act(ship: ShipState, enemy: ShipState) -> void:
	for suit in ship.suits.duplicate():
		if over:
			break
		var kind := Catalog.suit_kind(suit.kind)
		match kind.action:
			"shoot":
				_emit({"type": "suit_fires", "side": ship.side, "dock": suit.dock, "target": suit.target, "suit": kind.id})
				_log("%s fires at %s." % [kind.name, enemy.systems[suit.target].name], ship.side)
				var shot := {"shields": kind.shields, "damage": kind.damage, "fire_chance": 0, "breach_chance": 0,
					"wounds_crew": false, "ion": kind.ion, "never_misses": kind.never_misses,
					"kind": "ion" if kind.ion else ("beam" if kind.shields == "reduce" else "suit")}
				for shot_index in kind.shots:
					_fire_shot(ship, enemy, suit.dock, suit.target, shot, shot_index)
			"repair":
				var worst := ""
				for system_id in ship.system_order:
					if ship.systems[system_id].damage > 0 and (worst == "" or ship.systems[system_id].damage > ship.systems[worst].damage):
						worst = system_id
				if worst != "":
					ship.systems[worst].damage -= 1
					_emit({"type": "repaired", "side": ship.side, "system": worst, "amount": 1, "crew": -1})
					_log("%s repairs %s (+1)." % [kind.name, ship.systems[worst].name], ship.side)
		suit.turns_left -= 1
		if suit.turns_left <= 0:
			ship.suits.erase(suit)
			_emit({"type": "suit_returned", "side": ship.side, "dock": suit.dock})
			_log("%s returns to its dock." % kind.name, ship.side)


## Crew of both sides in the same system on this ship trade blows.
func _crew_fights(ship: ShipState) -> void:
	if Settings.value("crew_fights") == "Off":
		return
	for system_id in ship.system_order:
		var here := crew_in_system(ship.side, system_id)
		var defenders := here.filter(func(m): return m.owner == ship.side and m.controlled_by < 0)
		var boarders := here.filter(func(m): return m.owner != ship.side)
		if defenders.is_empty() or boarders.is_empty():
			continue
		_emit({"type": "crew_fight", "ship": ship.side, "system": system_id})
		_log("Crew fight in %s!" % ship.systems[system_id].name)
		var hits_on_boarders := defenders.size()
		var hits_on_defenders := boarders.size()
		for i in hits_on_defenders:
			_wound(defenders[rng.randi() % defenders.size()], "boarders")
		for i in hits_on_boarders:
			_wound(boarders[rng.randi() % boarders.size()], "defenders")


func _heal_in_med_bay(ship: ShipState) -> void:
	var med_bay_id := ship.first_system_of_type("medBay")
	if med_bay_id == "":
		return
	var healing := ship.capacity(med_bay_id)
	if healing <= 0:
		return
	for member in crew_in_system(ship.side, med_bay_id):
		if member.owner == ship.side and member.wounds > 0:
			var healed := mini(healing, member.wounds)
			member.wounds -= healed
			_emit({"type": "healed", "crew": member.id, "amount": healed})
			_log("%s is patched up in the Med Bay." % member.name, ship.side)


# ---------------------------------------------------------------- cards

func _resolve_card(ship: ShipState, card: Dictionary, definition: Dictionary, target: Dictionary) -> void:
	var enemy := ships[1 - ship.side]
	match card.id:
		"power":
			ship.power_row.append({"card": card, "flipped": false, "held": false})
			_log("Power Cell online (%d power)." % ship.available_power(), ship.side)
			return
		"shield":
			ship.shield_layers.append(card)
			_hold_power_under_shield(ship)
			_emit({"type": "shield_up", "side": ship.side, "layers": ship.shield_layers.size()})
			_log("Shield layer raised (%d up)." % ship.shield_layers.size(), ship.side)
			return
		"weapon":
			_fire_weapon(ship, enemy, card, target.system)
		"jump":
			if Settings.value("jump_escape") == "Off":
				_log("The jump drive hums, but escape is off in Settings.", ship.side)
				_return_to_deck(ship, card)
				return
			ship.jump_charge += 1
			_emit({"type": "jump_charge", "side": ship.side, "charge": ship.jump_charge})
			_log("Jump drive spooling: %d/%d." % [ship.jump_charge, JUMP_CHARGES_NEEDED], ship.side)
			if ship.jump_charge >= JUMP_CHARGES_NEEDED:
				over = true
				outcome = OUTCOME_ESCAPED
				escaped_side = ship.side
				_emit({"type": "jumped", "side": ship.side})
				_log("%s jumps away!" % ship.name, ship.side)
		"restore":
			var system: Dictionary = ship.systems[target.system]
			system.breached = false
			for member in crew_in_system(ship.side, target.system):
				if member.owner == ship.side and member.wounds > 0:
					member.wounds -= 1
					_emit({"type": "healed", "crew": member.id, "amount": 1})
			_emit({"type": "restored", "side": ship.side, "system": target.system})
			_log("Environment restored in %s." % system.name, ship.side)
		"teleport":
			var member := crew_by_id(target.crew)
			member.ship = target.ship
			member.system = target.system
			member.moved = true
			_emit({"type": "teleported", "crew": member.id, "ship": target.ship, "system": target.system})
			_log("%s teleports to %s on %s." % [member.name, ships[target.ship].systems[target.system].name, ships[target.ship].name], ship.side)
		"cloak":
			ship.cloaked = true
			ship.cloak_streak += 1
			_emit({"type": "cloaked", "side": ship.side})
			_log("Cloaked: evasion %d%% until your next turn." % evasion(ship), ship.side)
		"mindControl":
			var member := crew_by_id(target.crew)
			if member.owner == ship.side:
				member.controlled_by = -1
				_emit({"type": "mind_released", "crew": member.id})
				_log("%s is freed from mind control." % member.name, ship.side)
			else:
				member.controlled_by = ship.side
				if target.has("system"):
					member.system = target.system
				_emit({"type": "mind_controlled", "crew": member.id, "system": member.system})
				_log("%s is mind controlled and heads for %s." % [member.name, ships[member.ship].systems[member.system].name], ship.side)
		"hack":
			ship.hacked_this_turn = true
			ship.hack_streak += 1
			_disable_system(enemy, target.system, "hacked")
		"battery":
			ship.temporary_power += 1
			_emit({"type": "battery", "side": ship.side})
			_log("Backup Cell: +1 power this turn.", ship.side)
		"suit":
			var pilot := _free_crew_in(ship, card.system)
			pilot.acted = true
			var kind := Catalog.suit_kind(ship.systems[card.system].suit)
			var aim: String = target.get("system", "")
			ship.suits.append({"kind": kind.id, "dock": card.system, "target": aim, "turns_left": kind.turns, "ready": true})
			_emit({"type": "suit_launched", "side": ship.side, "dock": card.system, "target": aim, "suit": kind.id})
			if aim != "":
				_log("%s flies out toward %s." % [kind.name, enemy.systems[aim].name], ship.side)
			else:
				_log("%s flies out." % kind.name, ship.side)
		"repair":
			var worker := _free_crew_in(ship, target.system)
			worker.acted = true
			var system: Dictionary = ship.systems[target.system]
			var amount := mini(system.damage, 2 if worker.skill >= 2 else 1)
			system.damage -= amount
			_emit({"type": "repaired", "side": ship.side, "system": target.system, "amount": amount, "crew": worker.id})
			_log("%s repairs %s (+%d)." % [worker.name, system.name, amount], ship.side)
		"extinguish":
			var worker := _free_crew_in(ship, target.system)
			worker.acted = true
			ship.systems[target.system].on_fire = false
			_emit({"type": "extinguished", "side": ship.side, "system": target.system, "crew": worker.id})
			_log("%s puts out the fire in %s." % [worker.name, ship.systems[target.system].name], ship.side)
		"airlock":
			var operator := _free_crew_in(ship, ship.first_system_of_type("airlock"))
			operator.acted = true
			var system: Dictionary = ship.systems[target.system]
			system.on_fire = false
			_emit({"type": "vented", "side": ship.side, "system": target.system})
			_log("%s vents %s to space." % [operator.name, system.name], ship.side)
			for member in crew_in_system(ship.side, target.system):
				member.wounds = WOUNDS_TO_DIE
				_emit({"type": "crew_died", "crew": member.id, "cause": "vented"})
				_log("%s is blown out of the airlock." % member.name, member.owner)
	_return_to_deck(ship, card)


func _fire_weapon(ship: ShipState, enemy: ShipState, card: Dictionary, target_system_id: String) -> void:
	var system: Dictionary = ship.systems[card.system]
	var kind := Catalog.weapon_kind(system.kind)
	var profile := Catalog.weapon_profile(system.kind, system.weapon_type)
	if kind.uses_missile:
		ship.missiles -= 1
	var shot := {"shields": kind.shields, "damage": profile.damage, "fire_chance": kind.fire_chance,
		"breach_chance": kind.breach_chance, "wounds_crew": kind.wounds_crew, "ion": kind.ion,
		"never_misses": kind.never_misses, "kind": kind.id, "interceptable": kind.uses_missile}
	_log("Fires %s at %s." % [system.name, enemy.systems[target_system_id].name], ship.side)
	for shot_index in profile.shots:
		if over:
			break
		_fire_shot(ship, enemy, card.system, target_system_id, shot, shot_index)
	if kind.chain and int(ship.chain_copies.get(card.system, 0)) < MAX_CHAIN_COPIES:
		ship.chain_copies[card.system] = int(ship.chain_copies.get(card.system, 0)) + 1
		var copy := _new_card("weapon", card.system, true)
		_insert_randomly(ship.deck, copy)
		_emit({"type": "chain_copy", "side": ship.side, "card": copy})
		_log("%s links up: a copy joins your deck." % system.name, ship.side)


## One shot: roll to hit, meet the shields, then hit the system.
func _fire_shot(ship: ShipState, enemy: ShipState, weapon_system_id: String, target_system_id: String, shot: Dictionary, shot_index: int) -> void:
	var event := {"type": "shot", "side": ship.side, "from": weapon_system_id, "target": target_system_id,
		"kind": shot.kind, "index": shot_index, "result": "hit", "damage": 0}
	if shot.get("interceptable", false):
		for guardian in enemy.suits:
			if Catalog.suit_kind(guardian.kind).action == "intercept" and guardian.ready:
				guardian.ready = false
				event.result = "intercepted"
				_emit(event)
				_log("A guardian suit shoots down the torpedo!", enemy.side)
				return
	var chance := 100 if shot.never_misses else hit_chance(ship, weapon_system_id, enemy)
	if rng.randi_range(1, 100) > chance:
		event.result = "miss"
		_emit(event)
		_log("Miss!", ship.side)
		return
	var damage: int = shot.damage
	match shot.shields:
		"pop":
			if not enemy.shield_layers.is_empty():
				event.result = "shield"
				_emit(event)
				_pop_shield(enemy)
				return
		"reduce":
			damage -= enemy.shield_layers.size()
			if damage <= 0:
				event.result = "shield"
				_emit(event)
				_log("The beam splashes off the shields.", ship.side)
				return
	event.damage = damage
	_emit(event)
	var system: Dictionary = enemy.systems[target_system_id]
	if shot.ion:
		_disable_system(enemy, target_system_id, "ionized")
		return
	_damage_system(enemy, target_system_id, damage, true, shot.kind)
	if shot.wounds_crew:
		_wound_all_in(enemy.side, target_system_id, shot.kind)
	if not system.on_fire and rng.randi_range(1, 100) <= shot.fire_chance:
		system.on_fire = true
		_emit({"type": "fire_started", "side": enemy.side, "system": target_system_id})
		_log("Fire breaks out in %s!" % system.name, ship.side)
	if not system.breached and rng.randi_range(1, 100) <= shot.breach_chance:
		system.breached = true
		_emit({"type": "breached", "side": enemy.side, "system": target_system_id})
		_log("Hull breach in %s!" % system.name, ship.side)


func _damage_system(ship: ShipState, system_id: String, amount: int, hurts_hull: bool, cause: String) -> void:
	var system: Dictionary = ship.systems[system_id]
	var before: int = system.damage
	system.damage = mini(system.level, system.damage + amount)
	if hurts_hull:
		ship.hull = maxi(0, ship.hull - amount)
	_emit({"type": "damage", "side": ship.side, "system": system_id, "amount": amount, "hull": amount if hurts_hull else 0,
		"system_damage": system.damage - before, "cause": cause})
	if hurts_hull:
		_log("%s takes %d damage (hull %d/%d)." % [system.name, amount, ship.hull, ship.hull_max], 1 - ship.side)
	elif system.damage > before:
		_log("%s is damaged by %s." % [system.name, cause], ship.side)
	_collapse_extra_shields(ship)


func _wound_all_in(ship_side: int, system_id: String, cause: String) -> void:
	for member in crew_in_system(ship_side, system_id):
		_wound(member, cause)


func _wound(member: Dictionary, cause: String) -> void:
	if member.wounds >= WOUNDS_TO_DIE:
		return
	member.wounds += 1
	if member.wounds >= WOUNDS_TO_DIE:
		_emit({"type": "crew_died", "crew": member.id, "cause": cause})
		_log("%s is killed (%s)." % [member.name, cause], member.owner)
	else:
		_emit({"type": "wounded", "crew": member.id, "cause": cause})


## A hit shield layer drops: its card goes back into the deck, its power stays spent until recharge.
func _pop_shield(ship: ShipState) -> void:
	var layer: Dictionary = ship.shield_layers.pop_back()
	_return_to_deck(ship, layer)
	for entry in ship.power_row:
		if entry.held:
			entry.held = false
			break
	_emit({"type": "shield_down", "side": ship.side, "layers": ship.shield_layers.size()})
	_log("A shield layer absorbs the hit (%d left)." % ship.shield_layers.size(), 1 - ship.side)


## Shield layers above what a damaged or disabled shield system can hold collapse.
func _collapse_extra_shields(ship: ShipState) -> void:
	while ship.shield_layers.size() > ship.shield_capacity():
		_pop_shield(ship)


func _hold_power_under_shield(ship: ShipState) -> void:
	for entry in ship.power_row:
		if entry.flipped and not entry.held:
			entry.held = true
			return


## Ion and hacks shut a system down for its captain's next turn. A reactor can't be shut down;
## instead one of its power cards is knocked loose (GDD C6).
func _disable_system(ship: ShipState, system_id: String, how: String) -> void:
	var system: Dictionary = ship.systems[system_id]
	if system.type == "reactor":
		_emit({"type": how, "side": ship.side, "system": system_id})
		_knock_power_loose(ship)
		return
	system.disabled_turns = maxi(system.disabled_turns, 1)
	_collapse_extra_shields(ship)
	_emit({"type": how, "side": ship.side, "system": system_id})
	_log("%s is %s: offline through the next turn." % [system.name, how], 1 - ship.side)


## One power card goes back into the deck.
func _knock_power_loose(ship: ShipState) -> void:
	if ship.power_row.is_empty():
		return
	var chosen: Dictionary = ship.power_row[0]
	for entry in ship.power_row:
		if not entry.held and not entry.flipped:
			chosen = entry
			break
	for entry in ship.power_row:
		if chosen.held and not entry.held:
			chosen = entry
			break
	ship.power_row.erase(chosen)
	_insert_randomly(ship.deck, chosen.card)
	_emit({"type": "power_lost", "side": ship.side})
	_log("A Power Cell is knocked loose and shuffled into the deck.", 1 - ship.side)


# ---------------------------------------------------------------- card requirements

## The system whose per-turn limit the card counts against, or "" for crew and power cards.
func _paying_system(ship: ShipState, card: Dictionary) -> String:
	match card.id:
		"weapon":
			return card.system
		"power", "repair", "extinguish", "airlock":
			return ""
	if card.system != "" and ship.systems.has(card.system):
		return card.system
	for system_id in ship.system_order:
		if Catalog.systems[ship.systems[system_id].type].card == card.id:
			return system_id
	return "missing"


func _system_name_for_card(card: Dictionary) -> String:
	for type in Catalog.systems:
		if Catalog.systems[type].card == card.id:
			return Catalog.systems[type].name
	return "system"


func _card_requirement_problem(ship: ShipState, card: Dictionary, definition: Dictionary) -> String:
	match card.id:
		"weapon":
			var kind := Catalog.weapon_kind(ship.systems[card.system].kind)
			if kind.uses_missile and ship.missiles <= 0:
				return "Out of missiles."
		"shield":
			if ship.shield_layers.size() >= ship.shield_capacity():
				return "Shields are at full strength."
		"cloak":
			if ship.cloaked:
				return "Already cloaked."
			if ship.cloak_streak >= ship.capacity_of_type("cloak"):
				return "Can't stay cloaked any longer."
		"hack":
			if ship.hacked_this_turn:
				return "Already hacked this turn."
			if ship.hack_streak >= ship.capacity_of_type("hacking"):
				return "Hacking needs a turn to cool down."
		"suit":
			if _free_crew_in(ship, card.system).is_empty():
				return "Needs a free crew member in %s." % ship.systems[card.system].name
		"airlock":
			var airlock_id := ship.first_system_of_type("airlock")
			if airlock_id == "" or ship.capacity(airlock_id) <= 0:
				return "Airlock Control isn't working."
			if _free_crew_in(ship, airlock_id).is_empty():
				return "Needs a free crew member in Airlock Control."
		"repair", "extinguish":
			if not living_crew_of(ship.side).any(func(m): return m.ship == ship.side and m.controlled_by < 0 and not m.acted):
				return "No free crew aboard."
	return ""


func _target_problem(ship: ShipState, card: Dictionary, definition: Dictionary, target: Dictionary) -> String:
	var enemy := ships[1 - ship.side]
	match definition.target:
		CardLibrary.TARGET_NONE:
			return ""
		CardLibrary.TARGET_ENEMY_SYSTEM:
			if not enemy.systems.has(target.get("system", "")):
				return "Pick an enemy system."
			return ""
		CardLibrary.TARGET_OWN_SYSTEM:
			var system_id: String = target.get("system", "")
			if not ship.systems.has(system_id) or int(target.get("ship", ship.side)) != ship.side:
				return "Pick one of your systems."
			var system: Dictionary = ship.systems[system_id]
			match card.id:
				"repair":
					if system.damage <= 0:
						return "%s isn't damaged." % system.name
					if _free_crew_in(ship, system_id).is_empty():
						return "Needs a free crew member in %s." % system.name
				"extinguish":
					if not system.on_fire:
						return "%s isn't on fire." % system.name
					if _free_crew_in(ship, system_id).is_empty():
						return "Needs a free crew member in %s." % system.name
				"restore":
					var hurt_crew := crew_in_system(ship.side, system_id).any(func(m): return m.owner == ship.side and m.wounds > 0)
					if not system.breached and not hurt_crew:
						return "Nothing to restore in %s." % system.name
				"airlock":
					if system.type == "airlock":
						return "Can't vent Airlock Control itself."
			return ""
		CardLibrary.TARGET_CREW_THEN_SYSTEM:
			if not target.has("crew"):
				return "Pick a crew member."
			var crew_problem := _crew_choice_problem(ship, card, target.crew)
			if crew_problem != "":
				return crew_problem
			var member := crew_by_id(target.crew)
			if card.id == "mindControl" and member.owner == ship.side:
				return "" if not target.has("system") else "Freeing needs no system."
			if not target.has("system"):
				return "Pick a system."
			var target_side := int(target.get("ship", -1))
			if target_side < 0 or not ships[target_side].systems.has(target.system):
				return "Pick a system."
			if card.id == "mindControl" and target_side != member.ship:
				return "Mind controlled crew stay on their own ship."
			if card.id == "teleport" and target_side == member.ship and target.system == member.system:
				return "%s is already there." % member.name
			return ""
	return ""


func _crew_choice_problem(ship: ShipState, card: Dictionary, crew_id: int) -> String:
	var member := crew_by_id(crew_id)
	if member.is_empty():
		return "Pick a crew member."
	match card.id:
		"teleport":
			if member.owner != ship.side or member.controlled_by >= 0:
				return "Teleport only your own crew."
		"mindControl":
			if member.owner == ship.side:
				if member.controlled_by < 0:
					return "%s isn't mind controlled." % member.name
			elif member.controlled_by >= 0:
				return "%s is already controlled." % member.name
			elif member.ship != member.owner:
				return "Mind control works on crew aboard their own ship."
	return ""


## A crew member of the ship's own side, in the system, not mind controlled and not yet acted this turn.
func _free_crew_in(ship: ShipState, system_id: String) -> Dictionary:
	if system_id == "":
		return {}
	var best := {}
	for member in crew_in_system(ship.side, system_id):
		if member.owner == ship.side and member.controlled_by < 0 and not member.acted:
			if best.is_empty() or member.skill > best.skill:
				best = member
	return best


# ---------------------------------------------------------------- power, decks and hands

func _pay(ship: ShipState, card: Dictionary, definition: Dictionary) -> void:
	var system_id := _paying_system(ship, card)
	if system_id != "":
		ship.spent[system_id] = int(ship.spent.get(system_id, 0)) + maxi(1, definition.cost)
	_spend_power(ship, definition.cost)


func _spend_power(ship: ShipState, amount: int) -> void:
	var from_temporary := mini(amount, ship.temporary_power)
	ship.temporary_power -= from_temporary
	var remaining := amount - from_temporary
	for i in ship.online_power_cards():
		if remaining <= 0:
			break
		if not ship.power_row[i].flipped:
			ship.power_row[i].flipped = true
			remaining -= 1


func _deal_opening_hand(ship: ShipState) -> void:
	for i in OPENING_HAND:
		_draw(ship, true)
	if not guaranteed_opening_power:
		return
	var power_in_hand := ship.hand.filter(func(card): return card.id == "power").size()
	while power_in_hand < OPENING_POWER:
		var power_index := _index_of_card(ship.deck, func(card): return card.id == "power")
		var other_index := _index_of_card(ship.hand, func(card): return card.id != "power")
		if power_index < 0 or other_index < 0:
			break
		var swapped_out: Dictionary = ship.hand[other_index]
		ship.hand[other_index] = ship.deck[power_index]
		ship.deck[power_index] = swapped_out
		power_in_hand += 1
	_shuffle(ship.deck)


func _index_of_card(cards: Array, matches: Callable) -> int:
	for i in cards.size():
		if matches.call(cards[i]):
			return i
	return -1


func _draw(ship: ShipState, quiet: bool = false) -> void:
	if ship.deck.is_empty():
		if not quiet:
			_log("No cards left to draw.", ship.side)
		return
	var card: Dictionary = ship.deck.pop_back()
	ship.hand.append(card)
	if not quiet:
		_emit({"type": "drew", "side": ship.side, "card": card})


## A card leaving play is shuffled back into its captain's deck (cards are never discarded).
func _return_to_deck(ship: ShipState, card: Dictionary) -> void:
	_insert_randomly(ship.deck, card)


func _card_in_hand(ship: ShipState, uid: int) -> Dictionary:
	for card in ship.hand:
		if card.uid == uid:
			return card
	return {}


func _new_card(card_id: String, system_id: String, temporary: bool = false) -> Dictionary:
	var card := {"uid": _next_uid, "id": card_id, "system": system_id, "temporary": temporary}
	_next_uid += 1
	return card


func _insert_randomly(cards: Array, card: Dictionary) -> void:
	cards.insert(rng.randi_range(0, cards.size()), card)


func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = cards[i]
		cards[i] = cards[j]
		cards[j] = swap


# ---------------------------------------------------------------- the end

func _check_battle_end() -> void:
	if over and outcome != "":
		if outcome == OUTCOME_ESCAPED and not _events.any(func(e): return e.type == "battle_over"):
			_emit({"type": "battle_over", "winner": -1, "outcome": outcome, "escaped": escaped_side})
		return
	for side in 2:
		var ship := ships[side]
		var lost := ""
		if ship.hull <= 0:
			lost = OUTCOME_DESTROYED
		elif living_crew_of(side).is_empty():
			lost = OUTCOME_CREW_LOST
		if lost != "":
			over = true
			outcome = lost
			winner = 1 - side
			_emit({"type": "battle_over", "winner": winner, "outcome": outcome})
			_log("%s %s. %s wins!" % [ship.name, "is destroyed" if lost == OUTCOME_DESTROYED else "has lost all hands", ships[winner].name])
			return


# ---------------------------------------------------------------- events and log

func _emit(event: Dictionary) -> void:
	_events.append(event)


## Log lines are events too, so the screen shows them in step with the animations.
func _log(text: String, side: int = -1) -> void:
	_events.append({"type": "log", "text": text, "side": side})
