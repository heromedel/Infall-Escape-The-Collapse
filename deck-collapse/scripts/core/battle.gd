## The rules of a card battle between two ships. It holds the battle's state and changes it only through
## the captain actions below (play a card, move crew, burn engines, reroute power, jump, end turn).
## When the enemy is beaten, the battle goes on with only the winner's turns (the aftermath) until they jump,
## so they can repair, fight fires and heal first.
## Each action returns the events it caused, in order, so the screen can animate them; the Battle never draws.
class_name Battle
extends RefCounted

const OPENING_HAND := 7
const OPENING_POWER := 2
const CLOAK_EVASION := 40
const BURN_EVASION := 5
const EVASION_CAP := 80
const MAX_CHAIN_COPIES := 3

const OUTCOME_DESTROYED := "destroyed"
const OUTCOME_CREW_LOST := "crew_lost"
const OUTCOME_ESCAPED := "escaped"

var ships: Array[ShipState] = []
## Every crew member of both ships: { id, owner, name, race, skills, wounds, max_health, ship, system, moved, acted,
## locked, stunned, controlled_by }. "wounds" is health lost in pips; they die when it reaches max_health.
## "ship" is the side of the ship they stand on; "controlled_by" is -1 or the side mind-controlling them;
## "locked" means they repaired this turn and must stay where they are until their next turn.
var crew: Array = []
var active_side := 0
var turn_number := 1
## The battle is completely finished: someone jumped away or the player's ship was lost.
var over := false
## The losing side has been beaten (destroyed, crew lost or jumped away); the winner plays on until they jump.
var aftermath := false
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
## True while a turn's end-of-turn effects run, so a win then doesn't also start a turn (the turn change follows).
var _finishing_turn := false
var _next_uid := 1
var _next_crew_id := 1


## carry: the state side 0 brings from its last battle (see RunState.carry): hull, missiles, system damage,
## fires, breaches, and the surviving crew with their wounds and positions. Empty for a fresh ship.
func _init(design_a: ShipDesign, design_b: ShipDesign, first_side: int, seed_value: int = 0, carry: Dictionary = {}) -> void:
	rng.seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec())
	draw_per_turn = int(Settings.value("draw_per_turn"))
	guaranteed_opening_power = Settings.value("opening_power") == "2 Guaranteed"
	for side in 2:
		var design := design_a if side == 0 else design_b
		var ship := ShipState.new(side, design)
		ships.append(ship)
		for entry in CardLibrary.deck_list(design):
			ship.deck.append(_new_card(entry.id, entry.system, false, int(entry.get("slot", 0))))
		_shuffle(ship.deck)
		var members: Array = design.crew
		if side == 0 and carry.has("crew"):
			members = carry.crew
		for member in members:
			var station: String = member.get("system", member.get("station", ""))
			if not ship.systems.has(station):
				station = ship.system_order[0]
			var xp: Dictionary = member.get("xp", {}).duplicate()
			for skill in CrewSkills.NAMES:
				xp[skill] = maxf(float(xp.get(skill, 0.0)), xp_for_level(int(member.skills.get(skill, 0))))
			var race := Catalog.race(member.get("race", ""))
			crew.append({"id": _next_crew_id, "owner": side, "name": member.name, "race": race.id, "skills": member.skills.duplicate(),
				"xp": xp, "wounds": float(member.get("wounds", 0)), "max_health": max_health_for(race.id),
				"ship": side, "system": station, "moved": false,
				"acted": false, "locked": false, "stunned": false, "controlled_by": -1, "controlled_turns": 0, "leaving_to": "", "leaving_turns": 0})
			_next_crew_id += 1
		ship.mawjig = Money.round_amount(design.value() * float(Catalog.rule("economy", "enemyPursePercent", 0)) / 100.0) \
			if side == 1 else float(carry.get("mawjig", Catalog.rule("economy", "startingMawjig", 0)))
		if side == 0 and not carry.is_empty():
			_apply_carry(ship, carry)
	for ship in ships:
		_deal_opening_hand(ship)
	active_side = first_side
	_log("Battle start: %s vs %s. %s goes first." % [ships[0].name, ships[1].name, ships[first_side].name])
	_start_turn(first_side, true)
	opening_events = _events
	_events = []


func _apply_carry(ship: ShipState, carry: Dictionary) -> void:
	ship.hull = clampi(int(carry.get("hull", ship.hull)), 1, ship.hull_max)
	ship.missiles = int(carry.get("missiles", ship.missiles))
	ship.suit_parts = int(carry.get("suit_parts", ship.suit_parts))
	var systems: Dictionary = carry.get("systems", {})
	for system_id in systems:
		if ship.systems.has(system_id):
			var saved: Dictionary = systems[system_id]
			var system: Dictionary = ship.systems[system_id]
			system.damage = mini(system.level, int(saved.get("damage", 0)))
			system.on_fire = saved.get("on_fire", false)
			system.fire = int(saved.get("fire", 1 if system.on_fire else 0))
			system.breached = saved.get("breached", false)
			system.air = clampi(int(saved.get("air", ship.air_max)), 0, ship.air_max)


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
	# A repair in the aftermath may get the Engines or Piloting working again.
	_fill_jump_drive_if_clear(ship)
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
	member.moved = true
	# Boarders are held up by the enemy's Airlock Control: they need turns to break out of a system.
	var exit_turns := boarder_exit_turns(member)
	if exit_turns > 0:
		member.leaving_to = system_id
		member.leaving_turns = exit_turns
		_emit({"type": "crew_leaving", "side": side, "crew": crew_id, "to": system_id, "turns": exit_turns})
		_log("%s starts forcing the doors toward %s (%d turn%s)." % [member.name, ships[member.ship].systems[system_id].name,
			exit_turns, "" if exit_turns == 1 else "s"], side)
		return _events
	member.system = system_id
	member.leaving_to = ""
	_emit({"type": "crew_moved", "side": side, "crew": crew_id, "from": from_system, "to": system_id, "ship": member.ship})
	_log("%s moves to %s." % [member.name, ships[member.ship].systems[system_id].name], side)
	return _events


## Turns a crew member needs to leave their system: 0 at home; aboard an enemy ship, by its Airlock Control level.
func boarder_exit_turns(member: Dictionary) -> int:
	if member.ship == member.owner:
		return 0
	var host := ships[member.ship]
	var level := effective_level(host, host.first_system_of_type("airlock"))
	return int(Catalog.by_skill(Catalog.rule("airlock", "boarderExitTurns", [0]), level))


## Spends 1 power on Engines for +10% evasion until the captain's next turn. Limited by the Engines level.
func burn_engines(side: int) -> Array:
	_events = []
	var reason := why_cannot_burn(side)
	if reason != "":
		_emit({"type": "refused", "side": side, "reason": reason})
		return _events
	burn_engines_quietly(side)
	return _events


## One burn, adding its events to the current action (used by burn_engines and Auto Burn).
func burn_engines_quietly(side: int) -> void:
	var ship := ships[side]
	var engines_id := ship.first_system_of_type("engines")
	_spend_power(ship, 1)
	ship.spent[engines_id] = int(ship.spent.get(engines_id, 0)) + 1
	ship.burns += 1
	_emit({"type": "burn", "side": side, "system": engines_id})
	_log("Engines burn: evasion now %d%%." % evasion(ship), side)


## Powers the Med Bay for this turn (1 power): as the turn ends it heals everyone in it by its working level.
func treat(side: int) -> Array:
	_events = []
	var reason := why_cannot_treat(side)
	if reason != "":
		_emit({"type": "refused", "side": side, "reason": reason})
		return _events
	var ship := ships[side]
	var med_bay_id := ship.first_system_of_type("medBay")
	_spend_power(ship, 1)
	ship.spent[med_bay_id] = int(ship.spent.get(med_bay_id, 0)) + 1
	ship.treated = true
	_emit({"type": "treat", "side": side, "system": med_bay_id})
	_log("Med Bay powered: it treats everyone inside as the turn ends.", side)
	return _events


func why_cannot_treat(side: int) -> String:
	if over or side != active_side:
		return "Not your turn."
	var ship := ships[side]
	var med_bay_id := ship.first_system_of_type("medBay")
	if med_bay_id == "":
		return "No Med Bay."
	if ship.treated:
		return "The Med Bay is already running this turn."
	if ship.system_room(med_bay_id) < 1:
		return "The Med Bay isn't working." if ship.capacity(med_bay_id) < 1 else "The Med Bay can't take more power this turn."
	if ship.available_power() < 1:
		return "No power left."
	return ""


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


## Jumps away once the Jig Drive is fully charged. Mid-battle this is an escape; in the aftermath it ends the battle.
func jump(side: int) -> Array:
	_events = []
	var reason := why_cannot_jump(side)
	if reason != "":
		_emit({"type": "refused", "side": side, "reason": reason})
		return _events
	var ship := ships[side]
	_emit({"type": "jumped", "side": side})
	_log("%s jumps away!" % ship.name, side)
	if not aftermath:
		escaped_side = side
		if side != 0:
			# The enemy fled: the player is left to regroup before jumping on.
			_begin_aftermath(0, OUTCOME_ESCAPED)
			return _events
		outcome = OUTCOME_ESCAPED
		winner = -1
	over = true
	_emit({"type": "battle_over", "winner": winner, "outcome": outcome, "escaped": escaped_side})
	return _events


## Ends the side's turn: end-of-turn hazards, then the other captain's turn starts. Returns events.
func end_turn(side: int) -> Array:
	_events = []
	if over or side != active_side:
		return _events
	_finish_turn(side)
	return _events


func _finish_turn(side: int) -> void:
	if Settings.value("auto_burn") == "On":
		while why_cannot_burn(side) == "":
			burn_engines_quietly(side)
	_charge_jig_drive(ships[side])
	_emit({"type": "turn_end", "side": side})
	_finishing_turn = true
	_end_of_turn_effects(ships[side])
	_check_battle_end()
	_finishing_turn = false
	if over:
		return
	turn_number += 1
	# In the aftermath the beaten side takes no more turns.
	_start_turn(winner if aftermath else 1 - side, false)
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
	if aftermath and definition.target == CardLibrary.TARGET_ENEMY_SYSTEM:
		return "The enemy is beaten. Repair up and jump when ready."
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


## Every valid target for a card, for highlighting. For crew-then-system cards, pass the chosen crew id; for
## Teleport, from_bay lists where the crew in the bay can go.
func valid_targets(side: int, uid: int, chosen_crew_id: int = -1, from_bay: bool = false) -> Array:
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
		CardLibrary.TARGET_TELEPORT:
			var bay := ship.first_system_of_type("teleport")
			for ship_side in 2:
				for system_id in ships[ship_side].system_order:
					if from_bay:
						candidates.append({"system": bay, "ship": side, "to_system": system_id, "to_ship": ship_side})
					elif ship_side != side or system_id != bay:
						candidates.append({"system": system_id, "ship": ship_side})
			if not from_bay and not teleport_senders(side).is_empty():
				candidates.append({"system": bay, "ship": side, "to_system": "", "to_ship": 1 - side})
	return candidates.filter(func(target): return _listed_target(ship, card, definition, target, chosen_crew_id))


## Whether a candidate target is worth highlighting: valid, or a valid first pick (a crew member to move, or the
## Teleport Bay before its destination).
func _listed_target(ship: ShipState, card: Dictionary, definition: Dictionary, target: Dictionary, chosen_crew_id: int) -> bool:
	if target.get("to_system", "-") == "":
		return true
	if definition.target == CardLibrary.TARGET_CREW_THEN_SYSTEM and chosen_crew_id < 0:
		return _crew_choice_problem(ship, card, target.crew) == ""
	return _target_problem(ship, card, definition, target) == ""


func why_cannot_move(side: int, member: Dictionary, system_id: String) -> String:
	if over or side != active_side:
		return "Not your turn."
	if member.is_empty() or is_dead(member):
		return "No such crew member."
	if member.owner != side or member.controlled_by >= 0:
		return "%s isn't under your command." % member.name
	if member.system == "":
		return "%s is out in a battlesuit." % member.name
	if member.stunned:
		return "%s is stunned." % member.name
	if member.locked:
		return "%s is repairing and stays put this turn." % member.name
	if member.moved:
		return "%s has already moved this turn." % member.name
	if not ships[member.ship].systems.has(system_id):
		return "No such system on that ship."
	if member.system == system_id:
		return "%s is already there." % member.name
	if member.leaving_to != "":
		return "%s is still forcing the doors." % member.name
	var limit: int = Catalog.race(member.race).move_limit
	var order: Array = ships[member.ship].system_order
	if limit > 0 and absi(order.find(system_id) - order.find(member.system)) > limit:
		return "%s moves slowly: at most %d systems at a time." % [member.name, limit]
	return ""


func why_cannot_burn(side: int) -> String:
	if over or side != active_side:
		return "Not your turn."
	var ship := ships[side]
	var engines_id := ship.first_system_of_type("engines")
	if engines_id == "":
		return "No Engines."
	if ship.system_room(engines_id) < 1:
		return "Engines can't take more power this turn."
	if ship.available_power() < 1:
		return "No power left."
	return ""


func why_cannot_jump(side: int) -> String:
	if over or side != active_side:
		return "Not your turn."
	var ship := ships[side]
	if ship.jump_charge < jump_charges_needed():
		return "The Jig Drive needs %d/%d charges." % [ship.jump_charge, jump_charges_needed()]
	if not aftermath and Settings.value("jump_escape") == "Off":
		return "Escaping mid-battle is off in Settings."
	return _piloting_problem(ship)


func jump_charges_needed() -> int:
	return int(Catalog.rule("jump", "chargesNeeded", 24))


## As a turn ends, the Jig Drive gains a charge per working Engines level, if Engines and Piloting work and
## at least 1 power was burned in the Engines this turn.
func _charge_jig_drive(ship: ShipState) -> void:
	if ship.burns <= 0 or ship.jump_charge >= jump_charges_needed():
		return
	var engines := ship.capacity_of_type("engines")
	if engines <= 0 or ship.capacity_of_type("piloting") <= 0:
		return
	ship.jump_charge = mini(jump_charges_needed(), ship.jump_charge + engines)
	_emit({"type": "jump_charge", "side": ship.side, "charge": ship.jump_charge})
	_log("Jig Drive charging: %d/%d." % [ship.jump_charge, jump_charges_needed()], ship.side)


## Jumping needs Piloting working, and manned unless it has Auto Pilot (level 2+).
func _piloting_problem(ship: ShipState) -> String:
	var piloting_id := ship.first_system_of_type("piloting")
	if piloting_id == "" or ship.capacity(piloting_id) <= 0:
		return "Piloting isn't working."
	if ship.capacity(piloting_id) < 2 and manning_skill(ship, piloting_id) < 0:
		return "Needs a pilot in Piloting (or Auto Pilot, level 2+)."
	return ""


## A system's level for its effect: working level, plus the manned bonus (Sensors, Airlock Control).
func effective_level(ship: ShipState, system_id: String) -> int:
	if system_id == "" or not ship.systems.has(system_id):
		return 0
	var level := ship.capacity(system_id)
	if level > 0 and manning_skill(ship, system_id) >= 0:
		level += int(Catalog.systems[ship.systems[system_id].type].manned_level)
	return level


func why_cannot_reroute(side: int) -> String:
	if over or side != active_side:
		return "Not your turn."
	var ship := ships[side]
	if ship.cards_played_this_turn > 0:
		return "Only when you play no cards this turn."
	if not ship.deck.any(func(card): return card.id == "power"):
		return "No Power cards left in your deck."
	return ""


## Health pips a crew member of this race has: Crew Toughness × the race's health ÷ 100, rounded down.
static func max_health_for(race_id: String) -> float:
	return floorf(Settings.crew_toughness() * Catalog.race(race_id).hp / 100.0)


static func is_dead(member: Dictionary) -> bool:
	return member.wounds >= member.max_health


## Health left as a share of full health (0 to 1).
static func health_fraction(member: Dictionary) -> float:
	return clampf(1.0 - member.wounds / maxf(1.0, member.max_health), 0.0, 1.0)


func living_crew() -> Array:
	return crew.filter(func(member): return not is_dead(member))


func crew_by_id(crew_id: int) -> Dictionary:
	for member in crew:
		if member.id == crew_id and not is_dead(member):
			return member
	return {}


## Living crew standing in a system of a ship (any owner).
func crew_in_system(ship_side: int, system_id: String) -> Array:
	return living_crew().filter(func(member): return member.ship == ship_side and member.system == system_id)


## Boarders or mind-controlled crew stand in this system of the ship (nobody can repair it while they do).
func has_hostiles(ship_side: int, system_id: String) -> bool:
	return crew_in_system(ship_side, system_id).any(func(m): return m.owner != ship_side or m.controlled_by >= 0)


## The best level of the system's skill among the ship's own, free crew in it, or -1 if nobody mans it.
func manning_skill(ship: ShipState, system_id: String) -> int:
	var best := -1
	var type: String = ship.systems[system_id].type if ship.systems.has(system_id) else ""
	for member in crew_in_system(ship.side, system_id):
		if member.owner == ship.side and member.controlled_by < 0 and not member.stunned:
			best = maxi(best, CrewSkills.level(member.skills, type))
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
	# Classic: Engines give nothing until at least 1 power is burned in them; then the genre's evasion for that
	# many levels of power (systems.xml evasionByLevel). Extra Burn: the working level gives that evasion on its
	# own and each burn adds 5% more. Crew bonuses count once, only while the Engines are running.
	var classic := Settings.value("engine_efficiency") == "Classic"
	var engines_running := engines_id != "" and ship.capacity(engines_id) > 0 and (ship.burns > 0 or not classic)
	var base := 0.0
	if engines_running:
		var table: Array = Catalog.systems.engines.evasion_by_level
		if classic:
			base += Catalog.by_skill(table, mini(ship.burns, ship.capacity(engines_id)) - 1)
		else:
			base += Catalog.by_skill(table, ship.capacity(engines_id) - 1) + ship.burns * BURN_EVASION
		var engine_skill := manning_skill(ship, engines_id)
		if engine_skill >= 0:
			base += Catalog.by_skill(Catalog.systems.engines.manned_evasion, engine_skill)
		if pilot_skill >= 0:
			base += Catalog.by_skill(Catalog.systems.piloting.manned_evasion, pilot_skill)
	var total := int(base * factor) + (CLOAK_EVASION if ship.cloaked else 0)
	return clampi(total, 0, EVASION_CAP)


## Chance in percent that a shot from this weapon system (or dock) hits the defender. Beams never miss.
func hit_chance(attacker: ShipState, weapon_system_id: String, defender: ShipState) -> int:
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
	var level := effective_level(viewer, viewer.first_system_of_type("sensors"))
	return {"crew": level >= 1, "power": level >= 2, "weapons": level >= 3, "hand": level >= 4}


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
	ship.treated = false
	for member in crew:
		if member.owner == side:
			member.moved = member.stunned
			member.acted = member.stunned
			member.locked = false
	ships[1 - side].defenses_used = 0
	_boarders_break_out(side)
	for guardian in ships[1 - side].suits:
		guardian.ready = true
	_emit({"type": "turn_start", "side": side, "turn": turn_number})
	_log("— %s's turn —" % ship.name, side)
	_refill_air(ship)
	_fill_jump_drive_if_clear(ship)
	# 2. Recharge power.
	for entry in ship.power_row:
		if not entry.held:
			entry.flipped = false
	# 3. Draw, plus any extra cards from crew working their systems.
	if not first_turn_of_battle:
		for i in draw_per_turn:
			_draw(ship)
		_crew_bonus_draws(ship)


## Boarders who were forcing the doors count down, and step through when their time is up.
func _boarders_break_out(side: int) -> void:
	for member in living_crew():
		if member.owner != side or member.leaving_to == "":
			continue
		member.leaving_turns -= 1
		if member.leaving_turns <= 0:
			var from_system: String = member.system
			member.system = member.leaving_to
			member.leaving_to = ""
			_emit({"type": "crew_moved", "side": side, "crew": member.id, "from": from_system, "to": member.system, "ship": member.ship})
			_log("%s breaks through into %s." % [member.name, ships[member.ship].systems[member.system].name], side)


## Systems may draw an extra card of their own each turn, standing in for the genre's faster recharge:
## Shields a little on their own (unmannedDraw per working level), and Shields and weapons more when manned
## (crewDraw by skill). Crew in a damaged, breached or burning system may draw a Repair. Chances are in
## systems.xml and rules.xml.
func _crew_bonus_draws(ship: ShipState) -> void:
	for system_id in ship.system_order:
		var system: Dictionary = ship.systems[system_id]
		var definition: Dictionary = Catalog.systems[system.type]
		var chance := bonus_draw_chance(ship, system_id)
		if chance > 0.0 and rng.randf() * 100.0 < chance:
			var wanted: String = definition.card
			var manned := manning_skill(ship, system_id) >= 0
			_draw_bonus(ship, func(card): return card.id == wanted and (wanted != "weapon" or card.system == system_id),
				("Crew in %s work fast" if manned else "%s recharges fast") % system.name)
		var repairer := _free_crew_in(ship, system_id)
		if repairer.is_empty() or not needs_repair(system) or has_hostiles(ship.side, system_id):
			continue
		var repair_chance := Catalog.by_skill(Catalog.rule("crewDraw", "repair", [0]), int(repairer.skills.repair))
		if rng.randf() * 100.0 < repair_chance:
			_draw_bonus(ship, func(card): return card.id == "repair", "%s gets to work on %s" % [repairer.name, system.name])


## Chance in percent that a working system draws an extra card of its own this turn.
func bonus_draw_chance(ship: ShipState, system_id: String) -> float:
	var definition: Dictionary = Catalog.systems[ship.systems[system_id].type]
	var level := ship.capacity(system_id)
	if level <= 0 or definition.card == "":
		return 0.0
	var chance := float(definition.unmanned_draw) * level
	var skill := manning_skill(ship, system_id)
	if skill >= 0 and not definition.crew_draw.is_empty():
		chance += Catalog.by_skill(definition.crew_draw, skill)
	return chance


## A system has something for a Repair card to fix: a fire, a breach or damage.
static func needs_repair(system: Dictionary) -> bool:
	return system.on_fire or system.breached or system.spored or system.damage > 0


func _draw_bonus(ship: ShipState, matches: Callable, reason: String) -> void:
	var index := _index_of_card(ship.deck, func(card): return matches.call(card) and _drawable(ship, card))
	if index < 0:
		return
	var card: Dictionary = ship.deck[index]
	ship.deck.remove_at(index)
	ship.hand.append(card)
	_emit({"type": "drew", "side": ship.side, "card": card, "bonus": true})
	_log("%s: an extra card." % reason, ship.side)


func _end_of_turn_effects(ship: ShipState) -> void:
	var enemy := ships[1 - ship.side]
	_suits_act(ship, enemy)
	# Enemy boarding suits bore into this ship as its captain's turn ends.
	for suit in enemy.suits:
		if Catalog.suit_kind(suit.kind).action == "board" and suit.turns_left > 0 and not suit.recalling and not ship.is_broken(suit.target):
			_emit({"type": "suit_bores", "side": enemy.side, "target": suit.target})
			_log("A boarding suit tears into %s." % ship.systems[suit.target].name, enemy.side)
			_damage_system(ship, suit.target, 1, true, "boarding suit")
	# Fire and air: hazards hurt this captain's ship at the end of their turn.
	for system_id in ship.system_order:
		var system: Dictionary = ship.systems[system_id]
		if system.on_fire:
			_damage_system(ship, system_id, 1, false, "fire")
			for member in crew_in_system(ship.side, system_id):
				if not Catalog.race(member.race).fire_immune:
					_wound(member, "fire", system.fire)
		if not room_has_air(ship, system_id):
			for member in crew_in_system(ship.side, system_id):
				if Catalog.race(member.race).breathes:
					_wound(member, "breach" if system.breached else "no air", float(Catalog.rule("crewDamage", "noAir", 1)))
	_fires_burn(ship)
	_use_air(ship)
	# Boarders and mind-controlled crew sabotage the system they stand in.
	for member in living_crew().filter(func(m): return m.ship == ship.side and (m.owner != ship.side or m.controlled_by >= 0)):
		var system_id: String = member.system
		if not ship.is_broken(system_id):
			_emit({"type": "sabotage", "crew": member.id, "ship": ship.side, "system": system_id})
			_log("%s sabotages %s." % [member.name, ship.systems[system_id].name], 1 - ship.side)
			_damage_system(ship, system_id, 1, true, "sabotage")
		if member.controlled_by >= 0 and member.owner == ship.side:
			member.controlled_turns = int(member.get("controlled_turns", 1)) - 1
			if member.controlled_turns <= 0:
				member.controlled_by = -1
				_emit({"type": "mind_released", "crew": member.id})
				_log("%s shakes off the mind control." % member.name, ship.side)
	_crew_fights(ship)
	for member in crew:
		if member.owner == ship.side and member.stunned:
			member.stunned = false
	if ship.treated:
		_heal_in_med_bay(ship)
	# Ion and hacks wear off after the turn they blocked.
	for system_id in ship.system_order:
		var system: Dictionary = ship.systems[system_id]
		if system.disabled_turns > 0:
			system.disabled_turns -= 1
	ship.temporary_power = 0


## Each fire uses half its pips (rounded down) of its system's air and goes out once the air is gone or its system
## is broken; otherwise it grows a pip and may spread to a neighbouring system (less often with Airlock Control).
func _fires_burn(ship: ShipState) -> void:
	var airlock_level := effective_level(ship, ship.first_system_of_type("airlock"))
	var spread_chance := maxf(float(Catalog.rule("fire", "spreadMinimum", 5)),
		float(Catalog.rule("fire", "spreadChance", 30)) + airlock_level * float(Catalog.rule("fire", "spreadPerAirlockLevel", -10)))
	var burning := ship.system_order.filter(func(id): return ship.systems[id].on_fire)
	for system_id in burning:
		var system: Dictionary = ship.systems[system_id]
		system.air = maxi(0, system.air - system.fire / 2)
		if ship.is_broken(system_id) or ship.air_max > 0 and not room_has_air(ship, system_id):
			_put_out(system, system.fire)
			_emit({"type": "fire_out", "side": ship.side, "system": system_id})
			_log("The fire in %s %s." % [system.name, "burns out" if ship.is_broken(system_id) else "runs out of air"], ship.side)
			continue
		system.fire = mini(int(Catalog.rule("fire", "maxPips", 4)), system.fire + 1)
		if rng.randf() * 100.0 >= spread_chance:
			continue
		var index := ship.system_order.find(system_id)
		var neighbours: Array = []
		for offset in [-1, 1]:
			var neighbour_index: int = index + offset
			if neighbour_index >= 0 and neighbour_index < ship.system_order.size():
				var neighbour: String = ship.system_order[neighbour_index]
				if not ship.systems[neighbour].on_fire and not ship.is_broken(neighbour):
					neighbours.append(neighbour)
		if neighbours.is_empty():
			continue
		var caught: String = neighbours[rng.randi() % neighbours.size()]
		_ignite(ship.systems[caught])
		_emit({"type": "fire_started", "side": ship.side, "system": caught})
		_log("The fire spreads from %s to %s!" % [system.name, ship.systems[caught].name], ship.side)


## A fire starts (1 pip) in a system that isn't burning.
static func _ignite(system: Dictionary) -> void:
	if not system.on_fire:
		system.on_fire = true
		system.fire = 1


## Puts out some of a fire's pips; it is out at 0.
static func _put_out(system: Dictionary, pips: int) -> void:
	system.fire = maxi(0, system.fire - pips)
	system.on_fire = system.fire > 0


func life_support_down(ship: ShipState) -> bool:
	var life_support_id := ship.first_system_of_type("lifeSupport")
	return life_support_id != "" and ship.capacity(life_support_id) <= 0


## Whether a system has air: not breached, not vented this turn, and the ship has air left (Life Support working,
## or pips in reserve). Crew in a system without air take a wound as their captain's turn ends.
## A ship with no Life Support (a crew that doesn't breathe) has no air to lose.
func room_has_air(ship: ShipState, system_id: String) -> bool:
	if ship.air_max == 0:
		return true
	var system: Dictionary = ship.systems[system_id]
	return not system.breached and system.air > 0


## While Life Support is down, every system loses a pip of air as its captain's turn ends; a breach empties its
## system.
func _use_air(ship: ShipState) -> void:
	var down := life_support_down(ship)
	var emptied := false
	for system_id in ship.system_order:
		var system: Dictionary = ship.systems[system_id]
		var before: int = system.air
		if system.breached:
			system.air = 0
		elif down:
			system.air = maxi(0, system.air - 1)
		emptied = emptied or before > 0 and system.air == 0
	if down:
		_emit({"type": "air", "side": ship.side})
		_log("Life Support is down: the air is thinning." + (" Some systems have none left." if emptied else ""), ship.side)


## A working Life Support adds a pip of air to every unbreached system as its captain's turn starts.
func _refill_air(ship: ShipState) -> void:
	if life_support_down(ship):
		return
	var refilled := false
	for system_id in ship.system_order:
		var system: Dictionary = ship.systems[system_id]
		if not system.breached and system.air < ship.air_max:
			system.air += 1
			refilled = true
	if refilled:
		_emit({"type": "air", "side": ship.side})


## The ship's battlesuits act as its captain's turn ends. A recalled suit comes home instead. A suit out of air
## (its turns used up) stops working and its pilot takes a wound each turn until it is recalled.
func _suits_act(ship: ShipState, enemy: ShipState) -> void:
	for suit in ship.suits.duplicate():
		if over:
			break
		var kind := Catalog.suit_kind(suit.kind)
		var pilot := crew_by_id(suit.pilot)
		if suit.recalling or pilot.is_empty() or aftermath and winner == ship.side:
			_suit_comes_home(ship, suit)
			continue
		if suit.turns_left <= 0:
			_log("%s's suit is out of air." % pilot.name, ship.side)
			_wound(pilot, "suit out of air", float(Catalog.rule("crewDamage", "noAir", 1)))
			if is_dead(pilot):
				_lose_suit(ship, suit)
			continue
		suit.turns_left -= 1
		match kind.action:
			"shoot":
				_emit({"type": "suit_fires", "side": ship.side, "dock": suit.dock, "target": suit.target, "suit": kind.id})
				_log("%s fires at %s." % [kind.name, enemy.systems[suit.target].name], ship.side)
				var shot := {"shields": kind.shields, "damage": kind.damage, "fire_chance": 0, "breach_chance": 0,
					"wounds_crew": false, "ion": kind.ion, "never_misses": kind.never_misses,
					"kind": "ion" if kind.ion else ("beam" if kind.shields == "reduce" else "suit")}
				for shot_index in kind.shots:
					_fire_shot(ship, enemy, suit.dock, suit.target, shot, shot_index)
				suit.target = _drift_target(enemy)
			"intercept":
				# Guardians also shoot at enemy suits flying near their ship.
				var prey := enemy.suits.filter(func(s): return s.target != "" and not s.recalling)
				if not prey.is_empty():
					var victim: Dictionary = prey[rng.randi() % prey.size()]
					var hit := rng.randf() * 100.0 < float(Catalog.rule("suits", "guardianHit", 50))
					_emit({"type": "suit_shot", "side": ship.side, "dock": suit.dock, "target_side": enemy.side,
						"target": victim.target, "hit": hit})
					if hit:
						_suit_pilot_hit(enemy, victim, "a guardian suit")
					else:
						_log("A guardian suit fires at an enemy suit and misses.", ship.side)
			"repair":
				var worst := ""
				for system_id in ship.system_order:
					if ship.systems[system_id].damage > 0 and (worst == "" or ship.systems[system_id].damage > ship.systems[worst].damage):
						worst = system_id
				if worst != "":
					ship.systems[worst].damage -= 1
					_emit({"type": "repaired", "side": ship.side, "system": worst, "amount": 1, "crew": -1})
					_log("%s repairs %s (+1)." % [kind.name, ship.systems[worst].name], ship.side)
		if suit.turns_left == 0:
			_log("%s has used its last turn of air. Recall it!" % kind.name, ship.side)


## A random enemy system for a suit to drift beside, working ones first.
func _drift_target(enemy: ShipState) -> String:
	var working := enemy.system_order.filter(func(id): return not enemy.is_broken(id))
	var choices: Array = working if not working.is_empty() else enemy.system_order
	return choices[rng.randi() % choices.size()]


## A suit is hit (race-profiles.md, Mecha, Likely): the first hit damages it and wounds its pilot, and it can't act
## and heads home; a second hit destroys the suit and its pilot.
func _suit_pilot_hit(ship: ShipState, suit: Dictionary, cause: String) -> void:
	var pilot := crew_by_id(suit.pilot)
	if pilot.is_empty():
		return
	_emit({"type": "suit_hit", "side": ship.side, "dock": suit.dock, "target": suit.target, "crew": pilot.id, "id": suit.id})
	if suit.damaged:
		_log("%s's damaged battlesuit is hit again by %s and destroyed!" % [pilot.name, cause], 1 - ship.side)
		_wound_to_death(pilot, cause)
		_lose_suit(ship, suit)
		return
	_log("%s's battlesuit is hit by %s: damaged, it heads home." % [pilot.name, cause], 1 - ship.side)
	suit.damaged = true
	suit.recalling = true
	_wound(pilot, cause, float(Catalog.rule("crewDamage", "weaponPerDamage", 1)))
	if is_dead(pilot):
		_lose_suit(ship, suit)


func _lose_suit(ship: ShipState, suit: Dictionary) -> void:
	ship.suits.erase(suit)
	_emit({"type": "suit_lost", "side": ship.side, "dock": suit.dock})
	_log("A battlesuit is lost with its pilot.", ship.side)


## The suit docks and its pilot steps back into the EVB Dock. With EVB Refund on, unused turns pay back.
func _suit_comes_home(ship: ShipState, suit: Dictionary) -> void:
	ship.suits.erase(suit)
	var pilot := crew_by_id(suit.pilot)
	if not pilot.is_empty():
		pilot.ship = ship.side
		pilot.system = suit.dock
	var kind := Catalog.suit_kind(suit.kind)
	if Settings.value("evb_refund") == "Yes" and suit.turns_left > 0 and not suit.damaged:
		var refund := Money.round_amount(Ammo.suit_mawjig(kind.id, suit.turns_left))
		if refund > 0.0:
			ship.mawjig = Money.round_amount(ship.mawjig + refund)
			_log("Unused suit charge refunded: %s." % Money.text(refund), ship.side)
	_emit({"type": "suit_returned", "side": ship.side, "dock": suit.dock})
	_log("%s returns to its dock." % kind.name, ship.side)


## Calls a battlesuit home: it doesn't act this turn and docks as the turn ends.
func recall_suit(side: int, index: int) -> Array:
	_events = []
	var reason := why_cannot_recall(side, index)
	if reason != "":
		_emit({"type": "refused", "side": side, "reason": reason})
		return _events
	var suit: Dictionary = ships[side].suits[index]
	suit.recalling = true
	_emit({"type": "suit_recalling", "side": side, "dock": suit.dock})
	_log("%s is recalled; it docks as the turn ends." % Catalog.suit_kind(suit.kind).name, side)
	return _events


func why_cannot_recall(side: int, index: int) -> String:
	if over or side != active_side:
		return "Not your turn."
	if index < 0 or index >= ships[side].suits.size():
		return "No such battlesuit."
	if ships[side].suits[index].recalling:
		return "Already on its way back."
	return ""


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
		for member in defenders + boarders:
			_gain_xp(member, "combat", float(Catalog.rule("xp", "combat", 0)))
		# First strikers (Lykario) hit first; an enemy they kill doesn't strike back. Everyone else trades blows at once.
		var first := (defenders + boarders).filter(func(m): return Catalog.race(m.race).first_strike)
		var others := (defenders + boarders).filter(func(m): return not Catalog.race(m.race).first_strike)
		for member in first:
			_strike(member, boarders if member in defenders else defenders)
		var blows: Array = []
		for member in others:
			if not is_dead(member):
				blows.append([member, boarders if member in defenders else defenders])
		for blow in blows:
			_strike(blow[0], blow[1])


## One fighter's blows at a random living enemy in the fight: their hits × fight damage × their race's attack.
func _strike(member: Dictionary, enemies: Array) -> void:
	var targets := enemies.filter(func(m): return not is_dead(m))
	if targets.is_empty():
		return
	var damage: float = float(Catalog.rule("crewDamage", "fight", 2)) * Catalog.race(member.race).attack / 100.0
	for i in _combat_hits(member):
		_wound(targets[rng.randi() % targets.size()], "fight", damage)


## Blows one crew member lands in a fight: 1, a Veteran fighter sometimes 2, a Master always 2.
func _combat_hits(member: Dictionary) -> int:
	match int(member.skills.combat):
		2: return 2
		1: return 2 if rng.randf() < 0.5 else 1
	return 1


func _heal_in_med_bay(ship: ShipState) -> void:
	var med_bay_id := ship.first_system_of_type("medBay")
	if med_bay_id == "":
		return
	var healing := ship.capacity(med_bay_id) * float(Catalog.rule("crewDamage", "treat", 2))
	if healing <= 0:
		return
	for member in crew_in_system(ship.side, med_bay_id):
		if member.owner == ship.side and member.wounds > 0:
			var healed := minf(healing, member.wounds)
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
			_fire_weapon(ship, enemy, card, target)
		"restore":
			for system_id in ship.system_order:
				var system: Dictionary = ship.systems[system_id]
				if not system.breached and system.air < ship.air_max:
					system.air += 1
			_emit({"type": "air", "side": ship.side})
			_emit({"type": "aired", "side": ship.side, "system": ship.first_system_of_type("lifeSupport")})
			_log("Environment restored: every unbreached system gains a pip of air.", ship.side)
		"teleport":
			var bay := ship.first_system_of_type("teleport")
			var sending: bool = target.has("to_system")
			var travellers := teleport_senders(ship.side) if sending else teleport_returners(ship.side, int(target.ship), target.system)
			var to_ship := int(target.to_ship) if sending else ship.side
			var to_system: String = target.to_system if sending else bay
			for member in travellers:
				member.ship = to_ship
				member.system = to_system
				member.moved = true
				member.leaving_to = ""
				_emit({"type": "teleported", "crew": member.id, "ship": to_ship, "system": to_system})
			_log("%s teleport%s to %s on %s." % [", ".join(travellers.map(func(m): return m.name)), "s" if travellers.size() == 1 else "",
				ships[to_ship].systems[to_system].name, ships[to_ship].name], ship.side)
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
				# The Mind Control system holds a mind for its level + 1 turns.
				member.controlled_by = ship.side
				member.controlled_turns = ship.capacity_of_type("mindControl") + 1
				if target.has("system"):
					member.system = target.system
				_emit({"type": "mind_controlled", "crew": member.id, "system": member.system})
				_log("%s is mind controlled for %d turns and heads for %s." % [member.name, member.controlled_turns,
					ships[member.ship].systems[member.system].name], ship.side)
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
			pilot.moved = true
			pilot.system = ""
			var kind := Catalog.suit_kind(definition.suit)
			var aim := _drift_target(enemy) if kind.action in ["shoot", "board"] else ""
			var air := CardLibrary.suit_air(ship.systems[card.system].level)
			ship.suits.append({"id": _next_uid, "kind": kind.id, "dock": card.system, "pilot": pilot.id, "target": aim,
				"turns_left": air, "air": air, "recalling": false, "damaged": false, "ready": true})
			_next_uid += 1
			_emit({"type": "suit_launched", "side": ship.side, "dock": card.system, "target": aim, "suit": kind.id, "crew": pilot.id})
			if aim != "":
				_log("%s flies out in the %s toward %s." % [pilot.name, kind.name, enemy.systems[aim].name], ship.side)
			else:
				_log("%s flies out in the %s." % [pilot.name, kind.name], ship.side)
		"repair":
			_repair(ship, target.system)
		"airlock":
			var system: Dictionary = ship.systems[target.system]
			_put_out(system, system.fire)
			system.air = 0
			_emit({"type": "vented", "side": ship.side, "system": target.system})
			_log("Airlock Control vents %s to space: its air is gone." % system.name, ship.side)
			_wound_all_in(ship.side, target.system, "vented")
	_return_to_deck(ship, card)


## A crew member in the system fixes one thing, worst first: the fire, the breach, the spores, then 1 damage.
## They stay in the system for the rest of the turn. Repair skill only makes Repair cards come more often.
func _repair(ship: ShipState, system_id: String) -> void:
	var worker := _free_crew_in(ship, system_id)
	worker.acted = true
	worker.moved = true
	worker.locked = true
	var system: Dictionary = ship.systems[system_id]
	if system.on_fire:
		_put_out(system, int(Catalog.rule("fire", "repairPips", 2)))
		_emit({"type": "extinguished" if not system.on_fire else "fire_fought", "side": ship.side, "system": system_id, "crew": worker.id})
		_log("%s %s in %s." % [worker.name, "puts out the fire" if not system.on_fire else "beats the fire back", system.name], ship.side)
	elif system.breached:
		system.breached = false
		_emit({"type": "restored", "side": ship.side, "system": system_id, "crew": worker.id})
		_log("%s seals the breach in %s." % [worker.name, system.name], ship.side)
	elif system.spored:
		system.spored = false
		_emit({"type": "spores_cleared", "side": ship.side, "system": system_id, "crew": worker.id})
		_log("%s clears the spores from %s." % [worker.name, system.name], ship.side)
	else:
		system.damage -= 1
		_emit({"type": "repaired", "side": ship.side, "system": system_id, "amount": 1, "crew": worker.id})
		_log("%s repairs %s (+1)." % [worker.name, system.name], ship.side)
	_gain_xp(worker, "repair", float(Catalog.rule("xp", "repairPoint", 0)))


## How many bolts of a weapon card the captain may aim one by one: its shots with Multi Target Lasers On and a
## multi-target kind, else 1.
func bolts_to_aim(ship: ShipState, card: Dictionary) -> int:
	if card.id != "weapon" or Settings.value("multi_target_lasers") != "On":
		return 1
	var weapon := weapon_of(ship, card)
	return int(weapon.shots) if weapon.multi_target else 1


## The weapon a weapon card fires.
func weapon_of(ship: ShipState, card: Dictionary) -> Dictionary:
	return CardLibrary.weapon_of(card, ship.systems)


## How many systems a weapon card's beam sweeps (1 for anything but a sweeping beam).
func beam_rooms(ship: ShipState, card: Dictionary) -> int:
	if card.id != "weapon":
		return 1
	return int(weapon_of(ship, card).rooms)


## The systems a beam sweeps: the aimed one, then the next ones to the left (-1) or right (1), within the ship.
func sweep_systems(ship_side: int, system_id: String, direction: int, rooms: int) -> Array:
	var order: Array = ships[ship_side].system_order
	var start := order.find(system_id)
	var swept: Array = []
	for i in rooms:
		var index := start + i * (1 if direction >= 0 else -1)
		if index < 0 or index >= order.size():
			break
		swept.append(order[index])
	return swept


func _fire_weapon(ship: ShipState, enemy: ShipState, card: Dictionary, target: Dictionary) -> void:
	var target_system_id: String = target.system
	var weapon := weapon_of(ship, card)
	if weapon.uses_missile and Ammo.missiles_use_stock():
		ship.missiles -= 1
	var shot := {"shields": weapon.shields, "damage": weapon.damage, "fire_chance": weapon.fire,
		"breach_chance": weapon.breach, "wounds_crew": weapon.wounds_crew, "ion": weapon.ion,
		"never_misses": weapon.never_misses, "kind": Weapons.art(weapon), "interceptable": weapon.uses_missile and not weapon.bomb,
		"bomb": weapon.bomb, "crew_damage": weapon.crewDamage,
		"pierce": weapon.pierce, "spores": weapon.spores, "stun": weapon.stun, "mind": weapon.mind,
		"mind_turns": int(ship.systems[card.system].level)}
	_log("Fires %s at %s." % [weapon.name, enemy.systems[target_system_id].name], ship.side)
	_gain_xp_in(ship, card.system, "weapons", "volley")
	var aims: Array = target.get("systems", [])
	if weapon.rooms > 1:
		aims = sweep_systems(enemy.side, target_system_id, int(target.get("direction", 1)), weapon.rooms)
		if aims.size() > 1:
			_log("The beam sweeps %s." % ", ".join(aims.map(func(id): return enemy.systems[id].name)), ship.side)
	var shots: int = maxi(weapon.shots, aims.size())
	for shot_index in shots:
		if over:
			break
		var aim: String = aims[shot_index] if shot_index < aims.size() else target_system_id
		_fire_shot(ship, enemy, card.system, aim, shot, shot_index)
	var chain_key := "%s/%d" % [card.system, card.slot]
	if weapon.chain and int(ship.chain_copies.get(chain_key, 0)) < MAX_CHAIN_COPIES:
		ship.chain_copies[chain_key] = int(ship.chain_copies.get(chain_key, 0)) + 1
		var copy := _new_card("weapon", card.system, true, card.slot)
		_insert_randomly(ship.deck, copy)
		_emit({"type": "chain_copy", "side": ship.side, "card": copy})
		_log("%s links up: a copy joins your deck." % weapon.name, ship.side)


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
		if enemy.defenses_used < enemy.defensive_weapons():
			enemy.defenses_used += 1
			event.result = "intercepted"
			_emit(event)
			_log("A defense laser shoots down the torpedo!", enemy.side)
			return
	# Enemy suits drifting beside the firing weapon may be caught by its bolts.
	for suit in enemy.suits.duplicate():
		if suit.target == weapon_system_id and rng.randf() * 100.0 < float(Catalog.rule("suits", "strayHit", 15)):
			_suit_pilot_hit(enemy, suit, "a stray shot")
	var chance := 100 if shot.never_misses else hit_chance(ship, weapon_system_id, enemy)
	if rng.randi_range(1, 100) > chance:
		event.result = "miss"
		_emit(event)
		_log("Miss!", ship.side)
		# A miss may hit our own suit drifting beside the target.
		for suit in ship.suits.duplicate():
			if suit.target == target_system_id and rng.randf() * 100.0 < float(Catalog.rule("suits", "strayHit", 15)):
				_suit_pilot_hit(ship, suit, "a stray shot")
		# A dodge teaches the pilot and engineer, but not while cloaked (the cloak did the work).
		if not enemy.cloaked:
			_gain_xp_in(enemy, enemy.first_system_of_type("piloting"), "piloting", "dodge")
			_gain_xp_in(enemy, enemy.first_system_of_type("engines"), "engines", "dodge")
		return
	var damage: int = shot.damage
	var layers := maxi(0, enemy.shield_layers.size() - int(shot.get("pierce", 0)))
	match shot.shields:
		"pop":
			if layers > 0:
				event.result = "shield"
				_emit(event)
				_pop_shield(enemy)
				_gain_xp_in(enemy, enemy.first_system_of_type("shields"), "shields", "shieldPopped")
				return
		"reduce":
			# Each layer cuts 1 damage; a beam that does no damage at all is stopped by any layer.
			if layers > 0 and damage <= layers:
				event.result = "shield"
				_emit(event)
				_log("The beam splashes off the shields.", ship.side)
				return
			damage = maxi(0, damage - layers)
	event.damage = damage
	_emit(event)
	var system: Dictionary = enemy.systems[target_system_id]
	if shot.ion:
		_disable_system(enemy, target_system_id, "ionized")
		return
	_shot_effects(ship, enemy, target_system_id, shot)
	if damage > 0:
		# Bombs damage the system but not the hull (genre).
		_damage_system(enemy, target_system_id, damage, not shot.get("bomb", false), shot.kind)
	# As in the genre, every point of damage hurts everyone in the system; crewDamage (G20) hurts them on its own.
	var crew_hurt := damage * float(Catalog.rule("crewDamage", "weaponPerDamage", 1)) + float(shot.get("crew_damage", 0))
	if crew_hurt > 0.0:
		for member in crew_in_system(enemy.side, target_system_id):
			_wound(member, "bio" if damage <= 0 else "caught in the blast", crew_hurt)
	if not system.on_fire and rng.randi_range(1, 100) <= shot.fire_chance:
		_ignite(system)
		_emit({"type": "fire_started", "side": enemy.side, "system": target_system_id})
		_log("Fire breaks out in %s!" % system.name, ship.side)
	if not system.breached and rng.randi_range(1, 100) <= shot.breach_chance:
		system.breached = true
		_emit({"type": "breached", "side": enemy.side, "system": target_system_id})
		_log("Hull breach in %s!" % system.name, ship.side)


## A hit's specials: spores overgrow the system, a stun takes the crew's next turn, mind control takes one of them.
func _shot_effects(ship: ShipState, enemy: ShipState, system_id: String, shot: Dictionary) -> void:
	var system: Dictionary = enemy.systems[system_id]
	if shot.get("spores", false) and not system.spored:
		system.spored = true
		_collapse_extra_shields(enemy)
		_emit({"type": "spored", "side": enemy.side, "system": system_id})
		_log("Spores overgrow %s: it's offline until a Repair clears them." % system.name, ship.side)
	if shot.get("stun", false):
		for member in crew_in_system(enemy.side, system_id):
			member.stunned = true
			_emit({"type": "stunned", "crew": member.id})
			_log("%s is stunned." % member.name, ship.side)
	if shot.get("mind", false):
		var victims := crew_in_system(enemy.side, system_id).filter(func(m): return m.owner == enemy.side and m.controlled_by < 0)
		if not victims.is_empty():
			var victim: Dictionary = victims[rng.randi() % victims.size()]
			# A mind-control weapon holds a mind for as many turns as its weapon system's level.
			victim.controlled_by = ship.side
			victim.controlled_turns = maxi(1, int(shot.get("mind_turns", 1)))
			_emit({"type": "mind_controlled", "crew": victim.id, "system": victim.system})
			_log("%s's mind is taken over for %d turn%s." % [victim.name, victim.controlled_turns,
				"" if victim.controlled_turns == 1 else "s"], ship.side)


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


## XP needed in total to reach a skill level (GDD 7H: 100 to Veteran, 150 more to Master).
static func xp_for_level(level: int) -> float:
	var veteran := float(Catalog.rule("xp", "veteran", 100))
	match level:
		1: return veteran
		2: return veteran + float(Catalog.rule("xp", "master", 150))
	return 0.0


## The ship's own free crew manning a system each gain XP for an event (an xp rule name, e.g. "dodge").
func _gain_xp_in(ship: ShipState, system_id: String, skill: String, xp_event: String) -> void:
	if system_id == "":
		return
	for member in crew_in_system(ship.side, system_id):
		if member.owner == ship.side and member.controlled_by < 0:
			_gain_xp(member, skill, float(Catalog.rule("xp", xp_event, 0)))


func _gain_xp(member: Dictionary, skill: String, amount: float) -> void:
	if is_dead(member) or amount <= 0.0:
		return
	member.xp[skill] = float(member.xp.get(skill, 0.0)) + amount
	var level := int(member.skills.get(skill, 0))
	while level < CrewSkills.MAX_LEVEL and member.xp[skill] >= xp_for_level(level + 1):
		level += 1
		member.skills[skill] = level
		_emit({"type": "crew_level_up", "crew": member.id, "skill": skill, "level": level})
		_log("%s is now a %s in %s!" % [member.name, CrewSkills.LEVEL_NAMES[level], CrewSkills.LABELS[skill]], member.owner)


func _wound_all_in(ship_side: int, system_id: String, cause: String, amount: float = 1.0) -> void:
	for member in crew_in_system(ship_side, system_id):
		_wound(member, cause, amount)


func _wound_to_death(member: Dictionary, cause: String) -> void:
	if not member.is_empty() and not is_dead(member):
		_wound(member, cause, member.max_health - member.wounds)


## Takes health pips from a crew member; they die at max_health.
func _wound(member: Dictionary, cause: String, amount: float = 1.0) -> void:
	if is_dead(member) or amount <= 0.0:
		return
	member.wounds = minf(member.max_health, member.wounds + amount)
	if is_dead(member):
		_emit({"type": "crew_died", "crew": member.id, "cause": cause})
		_log("%s is killed (%s)." % [member.name, cause], member.owner)
	else:
		_emit({"type": "wounded", "crew": member.id, "cause": cause, "amount": amount})


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
		"power", "repair", "airlock":
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
	var mawjig := mawjig_cost(ship, card)
	if mawjig > 0.0 and ship.mawjig + 0.0001 < mawjig:
		return "Needs %s (you have %s)." % [Money.text(mawjig), Money.text(ship.mawjig)]
	match card.id:
		"weapon":
			if weapon_of(ship, card).uses_missile and Ammo.missiles_use_stock() and ship.missiles <= 0:
				return "Out of missiles."
		"shield":
			if ship.shield_layers.size() >= ship.shield_capacity():
				return "Shields are at full strength."
		"restore":
			if not ship.system_order.any(func(id): return not ship.systems[id].breached and ship.systems[id].air < ship.air_max):
				return "Every unbreached system has full air."
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
			if Ammo.suits_use_parts() and ship.suit_parts <= 0:
				return "Out of battlesuit parts."
		"airlock":
			var airlock_id := ship.first_system_of_type("airlock")
			if airlock_id == "" or ship.capacity(airlock_id) <= 0:
				return "Airlock Control isn't working."
		"repair":
			if not living_crew_of(ship.side).any(func(m): return m.ship == ship.side and m.controlled_by < 0 and not m.acted):
				return "No free crew aboard."
	return ""


func _target_problem(ship: ShipState, card: Dictionary, definition: Dictionary, target: Dictionary) -> String:
	var enemy := ships[1 - ship.side]
	match definition.target:
		CardLibrary.TARGET_NONE:
			return ""
		CardLibrary.TARGET_ENEMY_SYSTEM:
			if int(target.get("ship", enemy.side)) != enemy.side or not enemy.systems.has(target.get("system", "")):
				return "Pick an enemy system."
			var aims: Array = target.get("systems", [])
			if not aims.is_empty() and (bolts_to_aim(ship, card) <= 1 or aims.size() > bolts_to_aim(ship, card)):
				return "This weapon can't split its bolts."
			for aim in aims:
				if not enemy.systems.has(aim):
					return "Pick enemy systems."
			return ""
		CardLibrary.TARGET_OWN_SYSTEM:
			var system_id: String = target.get("system", "")
			if not ship.systems.has(system_id) or int(target.get("ship", ship.side)) != ship.side:
				return "Pick one of your systems."
			var system: Dictionary = ship.systems[system_id]
			match card.id:
				"repair":
					if not needs_repair(system):
						return "Nothing to fix in %s." % system.name
					if has_hostiles(ship.side, system_id):
						return "Can't repair %s with enemies in it." % system.name
					if _free_crew_in(ship, system_id).is_empty():
						return "Needs a free crew member in %s." % system.name
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
			return ""
		CardLibrary.TARGET_TELEPORT:
			var bay := ship.first_system_of_type("teleport")
			var from_side := int(target.get("ship", -1))
			if from_side < 0 or not ships[from_side].systems.has(target.get("system", "")):
				return "Pick a system."
			if from_side == ship.side and target.system == bay:
				if teleport_senders(ship.side).is_empty():
					return "Nobody of yours is free in the Teleport Bay."
				var to_side := int(target.get("to_ship", -1))
				if to_side < 0 or not ships[to_side].systems.has(target.get("to_system", "")):
					return "Pick where to send them."
				if to_side == ship.side and target.to_system == bay:
					return "They're already in the bay."
				return ""
			if teleport_returners(ship.side, from_side, target.system).is_empty():
				return "None of your crew there to bring back."
			return ""
	return ""


## Your free crew in your Teleport Bay, who a Teleport can send.
func teleport_senders(side: int) -> Array:
	var bay := ships[side].first_system_of_type("teleport")
	return crew_in_system(side, bay).filter(func(m): return m.owner == side and m.controlled_by < 0 and not m.stunned)


## Your crew in a system who a Teleport can bring back to the bay.
func teleport_returners(side: int, ship_side: int, system_id: String) -> Array:
	return crew_in_system(ship_side, system_id).filter(func(m): return m.owner == side and m.controlled_by < 0)


func _crew_choice_problem(ship: ShipState, card: Dictionary, crew_id: int) -> String:
	var member := crew_by_id(crew_id)
	if member.is_empty():
		return "Pick a crew member."
	if member.system == "":
		return "%s is out in a battlesuit." % member.name
	match card.id:
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
		if member.owner == ship.side and member.controlled_by < 0 and not member.acted and not member.stunned:
			if best.is_empty() or int(member.skills.repair) > int(best.skills.repair):
				best = member
	return best


# ---------------------------------------------------------------- power, decks and hands

func _pay(ship: ShipState, card: Dictionary, definition: Dictionary) -> void:
	var system_id := _paying_system(ship, card)
	if system_id != "":
		ship.spent[system_id] = int(ship.spent.get(system_id, 0)) + maxi(1, definition.cost)
	_spend_power(ship, definition.cost)
	var mawjig := mawjig_cost(ship, card)
	if mawjig > 0.0:
		ship.mawjig = Money.round_amount(ship.mawjig - mawjig)
		_emit({"type": "mawjig_spent", "side": ship.side, "amount": mawjig})
	if card.id == "suit" and Ammo.suits_use_parts():
		ship.suit_parts -= 1


## Mawjig a card costs to play under the Ammo setting: weapons per volley, battlesuits per launch.
func mawjig_cost(ship: ShipState, card: Dictionary) -> float:
	match card.id:
		"weapon":
			return Ammo.weapon_mawjig(weapon_of(ship, card))
		"suit":
			var definition := card_definition(ship, card)
			return Ammo.suit_mawjig(definition.suit, CardLibrary.suit_air(ship.systems[card.system].level))
	return 0.0


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


## Draws the top card that can be drawn: a broken system's cards are passed over and stay in the deck.
func _draw(ship: ShipState, quiet: bool = false) -> void:
	var index := ship.deck.size() - 1
	while index >= 0 and not _drawable(ship, ship.deck[index]):
		index -= 1
	if index < 0:
		if not quiet:
			_log("No cards left to draw." if ship.deck.is_empty() else "Only broken systems' cards are left to draw.", ship.side)
		return
	var card: Dictionary = ship.deck[index]
	ship.deck.remove_at(index)
	ship.hand.append(card)
	if not quiet:
		_emit({"type": "drew", "side": ship.side, "card": card})


func _drawable(ship: ShipState, card: Dictionary) -> bool:
	return card.system == "" or not ship.systems.has(card.system) or not ship.is_broken(card.system)


## A card leaving play is shuffled back into its captain's deck (cards are never discarded).
func _return_to_deck(ship: ShipState, card: Dictionary) -> void:
	_insert_randomly(ship.deck, card)


func _card_in_hand(ship: ShipState, uid: int) -> Dictionary:
	for card in ship.hand:
		if card.uid == uid:
			return card
	return {}


## A card instance. Weapon cards also name their weapon's slot in the weapon system.
func _new_card(card_id: String, system_id: String, temporary: bool = false, slot: int = 0) -> Dictionary:
	var card := {"uid": _next_uid, "id": card_id, "system": system_id, "temporary": temporary, "slot": slot}
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
	if over:
		return
	for side in 2:
		var ship := ships[side]
		var lost := ""
		if ship.hull <= 0:
			lost = OUTCOME_DESTROYED
		elif living_crew_of(side).is_empty():
			lost = OUTCOME_CREW_LOST
		if lost != "" and not (aftermath and side != winner):
			_log("%s %s." % [ship.name, "is destroyed" if lost == OUTCOME_DESTROYED else "has lost all hands"])
			if aftermath or side == 0:
				# The winner's own ship is lost after all, or the player is beaten: the battle is over.
				over = true
				if not aftermath:
					outcome = lost
					winner = 1 - side
				else:
					winner = -1
					outcome = lost
				_emit({"type": "battle_over", "winner": winner, "outcome": outcome})
				return
			_begin_aftermath(1 - side, lost)
			return


## The enemy is beaten: the winner keeps taking turns until they jump. Boarders aboard a destroyed ship die with it.
func _begin_aftermath(winning_side: int, how: String) -> void:
	aftermath = true
	winner = winning_side
	outcome = how
	var loser := 1 - winning_side
	if how == OUTCOME_DESTROYED:
		for member in living_crew():
			if member.ship == loser:
				member.wounds = member.max_health
				if member.owner == winning_side:
					_emit({"type": "crew_died", "crew": member.id, "cause": "lost with the wreck"})
					_log("%s goes down with the wreck." % member.name, winning_side)
	# Battlesuits come home: the winner's at once; the loser's pilots go down with a wreck.
	for suit in ships[winning_side].suits.duplicate():
		_suit_comes_home(ships[winning_side], suit)
	for suit in ships[loser].suits.duplicate():
		if how == OUTCOME_DESTROYED:
			_wound_to_death(crew_by_id(suit.pilot), "lost with the wreck")
		else:
			_suit_comes_home(ships[loser], suit)
	ships[loser].suits.clear()
	ships[loser].hand.clear()
	if how == OUTCOME_DESTROYED:
		# A wreck's systems are all gone.
		for system_id in ships[loser].systems:
			ships[loser].systems[system_id].damage = ships[loser].systems[system_id].level
			_put_out(ships[loser].systems[system_id], 99)
	_emit({"type": "enemy_beaten", "winner": winning_side, "outcome": how})
	_log("%s wins! Repair and regroup, then jump when ready." % ships[winning_side].name, winning_side)
	_fill_jump_drive_if_clear(ships[winning_side])
	# The beaten side's turn ends at once; mid end-of-turn, the turn change follows anyway.
	if active_side != winning_side and not _finishing_turn:
		turn_number += 1
		_start_turn(winning_side, false)


## With no enemy left, the Jig Drive charges at once, as in the genre, if Engines and Piloting work.
## (Battles in hazards would skip this; there are none yet.)
func _fill_jump_drive_if_clear(ship: ShipState) -> void:
	if not aftermath or ship.jump_charge >= jump_charges_needed():
		return
	if ship.capacity_of_type("engines") <= 0 or ship.capacity_of_type("piloting") <= 0:
		return
	ship.jump_charge = jump_charges_needed()
	_emit({"type": "jump_charge", "side": ship.side, "charge": ship.jump_charge})
	_log("No enemy left: the Jig Drive charges fully.", ship.side)


# ---------------------------------------------------------------- events and log

func _emit(event: Dictionary) -> void:
	_events.append(event)


## Log lines are events too, so the screen shows them in step with the animations.
func _log(text: String, side: int = -1) -> void:
	_events.append({"type": "log", "text": text, "side": side})
