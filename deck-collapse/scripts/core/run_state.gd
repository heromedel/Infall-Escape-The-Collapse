## A run of battles with one ship. The ship's state carries from battle to battle exactly as it was left: hull,
## system damage, fires, breaches, wounds, crew positions, dead crew and missiles. Between battles is a stop; some
## stops have a station (a store) that sells hull repair, missiles, suit parts and a random stock. Upgrades and the
## cargo hold change the run's own copy of the design, never the saved ship.
class_name RunState
extends RefCounted

## The run's own copy of the ship design: upgrades, new systems and weapons change it.
var design: ShipDesign
## What the ship brings into its next battle (see Battle._init). Empty before the first battle.
var carry := {}
var mawjig := 0.0
var battles_won := 0
var battles_fought := 0
## The last battle's result, for the screen between battles: { outcome, reward, jump_cost, enemy }.
var last_result := {}
## Weapons and battlesuit types kept out of the deck: { kind: "weapon", weapon (see Weapons), name } or
## { kind: "suit", suit, name }.
var cargo: Array = []
## The station at this stop, or null when the stop has none.
var station: Station = null
## What waits at this beacon: { kind: "start" | "hostile" (enemy) | "event" (event) | "quiet" }.
var beacon := {"kind": "start"}
var rng := RandomNumberGenerator.new()

var _stops_to_station := 0
## Stops reached so far in the run; the difficulty band rises every stopsPerBand of them.
var stops := 0
## Upgrades bought at this stop, newest last, so they can be undone until the ship leaves: { system_id, price }.
var _upgrades: Array = []


func _init(ship_design: ShipDesign) -> void:
	design = ship_design.duplicate_design()
	mawjig = float(Catalog.rule("economy", "startingMawjig", 0))
	rng.randomize()
	_stops_to_station = _station_gap()


## Takes the ship's state and the reward from a finished battle the player survived.
func record_battle(battle: Battle) -> void:
	battles_fought += 1
	var enemy := battle.ships[1]
	var reward := 0.0
	if battle.winner == 0 and battle.outcome in [Battle.OUTCOME_DESTROYED, Battle.OUTCOME_CREW_LOST]:
		battles_won += 1
		reward = wreck_reward(enemy.design, battle.outcome, band())
	var jump_cost := float(Catalog.rule("economy", "jumpCost", 0))
	var spent_in_battle := mawjig - battle.ships[0].mawjig
	mawjig = Money.round_amount(maxf(0.0, battle.ships[0].mawjig + reward - jump_cost))
	last_result = {"outcome": battle.outcome, "reward": reward, "jump_cost": jump_cost, "enemy": enemy.name,
		"spent": spent_in_battle,
		"won": battle.winner == 0 and battle.outcome != Battle.OUTCOME_ESCAPED}
	carry = snapshot(battle)
	last_result.stop = stops + 1
	_arrive()


## Jumps on from a beacon (the battle's own jump paid for the jump out of a fight).
func jump() -> void:
	mawjig = Money.round_amount(maxf(0.0, mawjig - float(Catalog.rule("economy", "jumpCost", 0))))
	_arrive()


## Reaches the next beacon: it may have a station (1 in 5–10), and holds an event or a hostile ship.
func _arrive() -> void:
	_upgrades.clear()
	stops += 1
	_stops_to_station -= 1
	station = null
	if Settings.value("station_frequency") == "Every Stop" or _stops_to_station <= 0:
		station = Station.new(design, rng, band())
		_stops_to_station = _station_gap()
	if not Catalog.events.is_empty() and rng.randf() * 100.0 < float(Catalog.rule("beacons", "eventChance", 50)):
		var choices := Catalog.events.filter(func(e): return e.id != beacon.get("event", {}).get("id", ""))
		beacon = {"kind": "event", "event": choices[rng.randi() % choices.size()]}
	else:
		beacon = {"kind": "hostile", "enemy": random_enemy()}


## A random built-in enemy allowed in the band (any, if none is).
func random_enemy() -> ShipDesign:
	var choices := Catalog.designs.filter(func(d): return d.built_in and d.name != design.name and d.in_band(band()))
	if choices.is_empty():
		choices = Catalog.designs.filter(func(d): return d.built_in and d.name != design.name)
	return choices[rng.randi() % choices.size()]


# ---------------------------------------------------------------- events

## The choices a player sees: blue ones only when the ship meets them. [{ choice, crew }] where crew is the name a
## race choice found ("" otherwise).
func event_choices(choices: Array) -> Array:
	var shown: Array = []
	for choice in choices:
		var requirement: String = choice.requires
		if requirement == "":
			shown.append({"choice": choice, "crew": ""})
			continue
		var crew_name = _meets(requirement)
		if crew_name != null:
			shown.append({"choice": choice, "crew": crew_name})
	return shown


## "" or a crew member's name when the ship meets a requirement (race:X, system:type, sensors:N), else null.
func _meets(requirement: String):
	var parts := requirement.split(":")
	match parts[0]:
		"race":
			for member in carry.get("crew", design.crew):
				if Catalog.race(member.get("race", "")).id == Catalog.race(parts[1]).id:
					return member.name
			return null
		"system":
			return "" if design.has_system(parts[1]) else null
		"sensors":
			var sensors := design.systems.filter(func(s): return s.type == "sensors")
			return "" if not sensors.is_empty() and sensors[0].level >= int(parts[1]) else null
	return null


## The bracketed label of a blue choice: "(Mecha Crew)", "(Teleport Bay)", "(Sensors level 2+)".
static func requirement_label(requirement: String) -> String:
	var parts := requirement.split(":")
	match parts[0]:
		"race": return "(%s Crew)" % Catalog.race(parts[1]).name
		"system": return "(%s)" % Catalog.systems.get(parts[1], {"name": parts[1]}).name
		"sensors": return "(Sensors level %s+)" % parts[1]
	return ""


## Picks one of a choice's outcomes by weight, applies it, and returns { outcome, text, summary, battle }.
func resolve_event_choice(choice: Dictionary, crew_name: String) -> Dictionary:
	var total := 0.0
	for outcome in choice.outcomes:
		total += outcome.weight
	var roll := rng.randf() * total
	var picked: Dictionary = choice.outcomes[0]
	for outcome in choice.outcomes:
		roll -= outcome.weight
		if roll <= 0.0:
			picked = outcome
			break
	if crew_name == "" and not carry.get("crew", []).is_empty():
		crew_name = carry.crew[rng.randi() % carry.crew.size()].name
	var summary := _apply_event_effects(picked.effects, crew_name)
	var battle: bool = picked.effects.get("battle", "") != ""
	if battle:
		beacon = {"kind": "hostile", "enemy": random_enemy()}
	else:
		beacon = {"kind": "quiet"}
	return {"outcome": picked, "text": String(picked.text).replace("{crew}", crew_name), "summary": summary, "battle": battle}


func _apply_event_effects(effects: Dictionary, crew_name: String) -> Array[String]:
	var summary: Array[String] = []
	if effects.has("mawjig"):
		var amount := _event_size(effects.mawjig, "mawjig")
		mawjig = Money.round_amount(maxf(0.0, mawjig + amount))
		summary.append("Mawjig %s%s" % ["+" if amount >= 0 else "−", Money.text(absf(amount))])
	if effects.has("hull"):
		var points := int(_event_size(effects.hull, "hull"))
		carry.hull = clampi(hull() + points, 1, hull_max())
		summary.append("Hull %s%d" % ["+" if points >= 0 else "−", absi(points)])
	if effects.has("missiles"):
		var count := int(_event_size(effects.missiles, "missiles"))
		carry.missiles = maxi(0, int(carry.get("missiles", 0)) + count)
		summary.append("Missiles %s%d" % ["+" if count >= 0 else "−", absi(count)])
	if effects.get("wound", "") != "":
		for member in carry.get("crew", []):
			if member.name == crew_name:
				var full := Battle.max_health_for(member.get("race", ""))
				member.wounds = minf(full, float(member.get("wounds", 0)) + float(Catalog.rule("beacons", "wound", 3)))
				if member.wounds >= full:
					carry.crew.erase(member)
					summary.append("%s is gone" % crew_name)
				else:
					summary.append("%s wounded" % crew_name)
				break
	if effects.get("join", "") != "" and carry.get("crew", []).size() < 8:
		var race := Catalog.race(effects.join)
		var list := "gatos/cats" if Settings.value("crew_portraits") == "Cat Faces" else "gatos/human"
		var member_name := Catalog.random_name(list, rng)
		carry.crew.append({"name": member_name, "race": race.id, "skills": CrewSkills.empty(), "wounds": 0,
			"system": design.systems[0].id})
		summary.append("%s (%s) joins your crew" % [member_name, race.name])
	if effects.get("repair", "") != "":
		var worst := ""
		for system_id in carry.get("systems", {}):
			var saved: Dictionary = carry.systems[system_id]
			if int(saved.damage) > 0 and (worst == "" or int(saved.damage) > int(carry.systems[worst].damage)):
				worst = system_id
		if worst != "":
			carry.systems[worst].merge({"damage": 0, "on_fire": false, "fire": 0, "breached": false}, true)
			var system := design.system_by_id(worst)
			summary.append("%s repaired" % (system.get("name", Catalog.systems[system.type].name) if not system.is_empty() else worst))
	return summary


## An event size such as "+low" or "-medium" as a number, from rules.xml beacons.
func _event_size(text: String, what: String) -> float:
	var sign := -1.0 if text.begins_with("-") else 1.0
	var size := text.trim_prefix("+").trim_prefix("-")
	return sign * float(Catalog.rule("beacons", "%s%s" % [what, size.capitalize()], 0))


func _station_gap() -> int:
	return rng.randi_range(int(Catalog.rule("station", "gapMin", 5)), int(Catalog.rule("station", "gapMax", 10)))


## The run's difficulty band: 1, rising every stopsPerBand stops (rules.xml), up to 8.
func band() -> int:
	return clampi(1 + stops / maxi(1, int(Catalog.rule("bands", "stopsPerBand", 10))), 1, Weapons.MAX_BAND)


func stops_to_next_station() -> int:
	return 1 if Settings.value("station_frequency") == "Every Stop" else _stops_to_station


## A beaten enemy's Mawjig: a share of its ship's value times the band's adjustment, more if its crew was killed and
## the ship left whole.
static func wreck_reward(enemy_design: ShipDesign, outcome: String, at_band: int = 1) -> float:
	var reward := enemy_design.value() * float(Catalog.rule("economy", "rewardPercent", 0)) / 100.0 * band_adjustment(at_band)
	if outcome == Battle.OUTCOME_CREW_LOST:
		reward *= 1.0 + float(Catalog.rule("economy", "crewKillBonus", 0)) / 100.0
	return Money.round_amount(reward)


## Rewards rise each band (mawjig-cost-table.md, Fight rewards): x1.0 in band 1, then bandStep % more per band.
static func band_adjustment(at_band: int) -> float:
	return 1.0 + float(Catalog.rule("economy", "bandStep", 0)) / 100.0 * (at_band - 1)


## The player's ship as the battle left it. Crew aboard the enemy ship when you jump are left behind.
static func snapshot(battle: Battle) -> Dictionary:
	var ship := battle.ships[0]
	var systems := {}
	for system_id in ship.systems:
		var system: Dictionary = ship.systems[system_id]
		systems[system_id] = {"damage": system.damage, "on_fire": system.on_fire, "fire": system.fire,
			"breached": system.breached, "air": system.air}
	var survivors: Array = []
	# Senti stored in a working Avatar Array come back after the battle, the dead ones whole.
	var array_id := ship.first_system_of_type("aaa")
	var stored := battle.crew.filter(func(m): return m.owner == 0 and m.get("stored", false)) \
		if array_id != "" and not ship.is_broken(array_id) else []
	for member in battle.living_crew_of(0) + stored:
		if member.ship == 0 or member.get("stored", false):
			survivors.append({"name": member.name, "race": member.race, "skills": member.skills.duplicate(), "xp": member.xp.duplicate(),
				"wounds": 0.0 if Battle.is_dead(member) else member.wounds,
				"system": array_id if member.get("stored", false) else member.system})
	return {"hull": ship.hull, "hull_max": ship.hull_max, "missiles": ship.missiles, "suit_parts": ship.suit_parts,
		"systems": systems, "crew": survivors}


# ---------------------------------------------------------------- the stop between battles

func hull() -> int:
	return int(carry.get("hull", 0))


func hull_max() -> int:
	return int(carry.get("hull_max", 0))


func can_afford(price: float) -> bool:
	return mawjig + 0.0001 >= price


func _pay(price: float) -> void:
	mawjig = Money.round_amount(mawjig - price)


## The battle's starting state: the carried ship plus the Mawjig purse it fires with.
func battle_carry() -> Dictionary:
	var state := carry.duplicate(true)
	state.mawjig = mawjig
	return state


func uses_missiles() -> bool:
	return Ammo.missiles_use_stock() and design.uses_missile_weapons()


func uses_suit_parts() -> bool:
	return Ammo.suits_use_parts() and design.has_system("evb")


# ---------------------------------------------------------------- the station's goods

## Hull repair by band (mawjig-cost-table.md: 0.48 in bands 1–3, 0.73 in 4–6, 0.97 in 7–8).
func hull_repair_price() -> float:
	return Catalog.by_skill(Catalog.rule("bands", "hullRepair", [0.48]), band() - 1)


func missile_price() -> float:
	return float(Catalog.rule("economy", "missile", 0))


func suit_part_price() -> float:
	return float(Catalog.rule("economy", "suitPart", 0))


## Repairs up to this many hull points, as many as Mawjig allows. Returns the points repaired.
func repair_hull(points: int) -> int:
	var repaired := 0
	while repaired < points and hull() < hull_max() and can_afford(hull_repair_price()):
		carry.hull = hull() + 1
		_pay(hull_repair_price())
		repaired += 1
	return repaired


func buy_missile() -> void:
	if can_afford(missile_price()):
		carry.missiles = int(carry.get("missiles", 0)) + 1
		_pay(missile_price())


func buy_suit_part() -> void:
	if can_afford(suit_part_price()):
		carry.suit_parts = int(carry.get("suit_parts", 0)) + 1
		_pay(suit_part_price())


## Store System Repair: each damage point, fire and breach the station can fix, and the price of each.
func system_repair_count() -> int:
	var count := 0
	for system_id in carry.get("systems", {}):
		var saved: Dictionary = carry.systems[system_id]
		count += int(saved.damage) + (1 if saved.on_fire else 0) + (1 if saved.breached else 0)
	return count


func system_repair_price() -> float:
	return float(Catalog.rule("station", "systemRepair", 0))


func repair_all_systems() -> void:
	var price := system_repair_price() * system_repair_count()
	if not can_afford(price):
		return
	for system_id in carry.get("systems", {}):
		carry.systems[system_id].merge({"damage": 0, "on_fire": false, "fire": 0, "breached": false}, true)
	_pay(price)


## Why an item in the station's stock can't be bought, or "".
func why_cannot_buy(item: Dictionary) -> String:
	if item.sold:
		return "Sold."
	if not can_afford(item.price):
		return "Not enough Mawjig."
	match item.kind:
		"crew":
			if carry.get("crew", []).size() >= 8:
				return "At most 8 crew."
		"weapon":
			if free_weapon_system() == "" and cargo_full():
				return "No room: every weapon slot and the cargo hold are full."
		"suit":
			if free_dock() == "" and cargo_full():
				return "No room: every EVB Dock slot and the cargo hold are full."
		"system":
			if design.has_system(item.type):
				return "Already installed."
	return ""


## Buys an item: a system is installed at level 1 (an EVB Dock empty), a weapon goes into a free weapon slot and a
## battlesuit type into a free dock slot (or cargo when there is none), crew join at the first system.
func buy(item: Dictionary) -> void:
	if why_cannot_buy(item) != "":
		return
	match item.kind:
		"system":
			var system := {"id": design.unused_system_id(item.type), "type": item.type, "level": 1}
			if item.type == "evb":
				system.suits = []
			elif item.type == "weapon":
				system.name = "Weapons"
				system.weapons = []
			design.systems.append(system)
		"weapon":
			var system_id := free_weapon_system()
			if system_id != "":
				design.system_by_id(system_id).weapons.append(item.weapon.duplicate())
			else:
				cargo.append({"kind": "weapon", "weapon": item.weapon.duplicate(), "name": item.name})
		"suit":
			var dock_id := free_dock()
			if dock_id != "":
				design.system_by_id(dock_id).suits.append(item.suit)
			else:
				cargo.append({"kind": "suit", "suit": item.suit, "name": item.name})
		"crew":
			var member: Dictionary = item.member
			carry.crew.append({"name": member.name, "race": member.get("race", "Terran"), "skills": member.skills.duplicate(), "wounds": 0,
				"system": design.systems[0].id})
	item.sold = true
	_pay(item.price)


## What an item sells back for (genre: half its price).
static func sell_price(item: Dictionary) -> float:
	var price := 0.0
	match item.kind:
		"weapon": price = float(item.weapon.price)
		"suit": price = float(Catalog.suit_kind(item.suit).price)
	return Money.round_amount(price * float(Catalog.rule("station", "sellPercent", 50)) / 100.0)


func sell_cargo(index: int) -> void:
	mawjig = Money.round_amount(mawjig + sell_price(cargo[index]))
	cargo.remove_at(index)


## Sells a fitted weapon from its slot. The ship must keep something to fight with.
func sell_weapon(system_id: String, slot: int) -> void:
	if why_cannot_remove_weapon() != "":
		return
	var weapon: Dictionary = design.system_by_id(system_id).weapons.pop_at(slot)
	mawjig = Money.round_amount(mawjig + sell_price({"kind": "weapon", "weapon": weapon}))


# ---------------------------------------------------------------- cargo

func cargo_slots() -> int:
	return int(Catalog.rule("station", "cargoSlots", 4))


func cargo_full() -> bool:
	return cargo.size() >= cargo_slots()


func weapon_systems() -> Array:
	return design.systems.filter(func(s): return s.type == "weapon")


## The first EVB Dock with a free slot, or "".
func free_dock() -> String:
	for system in design.systems:
		if system.type == "evb" and system.suits.size() < Weapons.SLOTS_PER_SYSTEM:
			return system.id
	return ""


## Moves a suit type out of a dock into the cargo hold.
func store_suit(dock_id: String, slot: int) -> void:
	if cargo_full():
		return
	var suit_id: String = design.system_by_id(dock_id).suits.pop_at(slot)
	cargo.append({"kind": "suit", "suit": suit_id, "name": Catalog.suit_kind(suit_id).name})


## The first weapon system with a free slot, or "".
func free_weapon_system() -> String:
	for system in weapon_systems():
		if system.weapons.size() < system.get("max_slots", Weapons.SLOTS_PER_SYSTEM):
			return system.id
	return ""


## A weapon can leave the ship only if another weapon or an EVB Dock remains to fight with.
func why_cannot_remove_weapon() -> String:
	var fitted := 0
	for system in weapon_systems():
		fitted += system.weapons.size()
	if fitted <= 1 and not design.systems.any(func(s): return s.type == "evb" and not s.suits.is_empty()):
		return "Keep at least one weapon or a battlesuit."
	return ""


## Moves a fitted weapon into the cargo hold.
func store_weapon(system_id: String, slot: int) -> void:
	if cargo_full() or why_cannot_remove_weapon() != "":
		return
	var weapon: Dictionary = design.system_by_id(system_id).weapons.pop_at(slot)
	cargo.append({"kind": "weapon", "weapon": weapon, "name": weapon.name})


## Where a cargo item can go, as [{ target, label }]: a weapon system or EVB Dock id (a free slot), or
## "system id/slot" (swap with what is in that slot).
func cargo_targets(index: int) -> Array:
	var item: Dictionary = cargo[index]
	var targets: Array = []
	if item.kind == "weapon":
		for system in weapon_systems():
			if system.weapons.size() < system.get("max_slots", Weapons.SLOTS_PER_SYSTEM):
				targets.append({"target": system.id, "label": "Fit in %s" % system.name})
			for slot in system.weapons.size():
				targets.append({"target": "%s/%d" % [system.id, slot], "label": "Swap for %s" % system.weapons[slot].name})
	else:
		for system in design.systems:
			if system.type != "evb":
				continue
			if system.suits.size() < Weapons.SLOTS_PER_SYSTEM:
				targets.append({"target": system.id, "label": "Load in EVB Dock"})
			for slot in system.suits.size():
				targets.append({"target": "%s/%d" % [system.id, slot], "label": "Swap for %s" % Catalog.suit_kind(system.suits[slot]).name})
	return targets


## Takes a cargo item out of the hold: into a free weapon slot, or swapped with what a slot or dock holds now.
func use_cargo(index: int, target: String) -> void:
	var item: Dictionary = cargo[index]
	cargo.remove_at(index)
	var parts := target.split("/")
	var system := design.system_by_id(parts[0])
	if item.kind == "suit" and parts.size() == 1:
		system.suits.append(item.suit)
	elif item.kind == "suit":
		var suit_slot := int(parts[1])
		var old_suit: String = system.suits[suit_slot]
		system.suits[suit_slot] = item.suit
		cargo.insert(index, {"kind": "suit", "suit": old_suit, "name": Catalog.suit_kind(old_suit).name})
	elif parts.size() == 1:
		system.weapons.append(item.weapon)
	else:
		var slot := int(parts[1])
		var old: Dictionary = system.weapons[slot]
		system.weapons[slot] = item.weapon
		cargo.insert(index, {"kind": "weapon", "weapon": old, "name": old.name})


# ---------------------------------------------------------------- upgrades

## Why upgrades can't be bought at this stop, or "".
func why_cannot_upgrade_here() -> String:
	if station == null and Settings.value("upgrade_stations_only") == "On":
		return "Upgrades only at stations (Settings: Upgrade at Stations Only)."
	return ""


## The price of a system's next level, or -1 at its top level.
static func upgrade_price(system: Dictionary) -> float:
	var definition: Dictionary = Catalog.systems[system.type]
	if system.level >= definition.max_level or system.level >= definition.prices.size():
		return -1.0
	return float(definition.prices[system.level])


func upgrade(system_id: String) -> void:
	var system := design.system_by_id(system_id)
	var price := upgrade_price(system)
	if why_cannot_upgrade_here() != "" or price < 0.0 or not can_afford(price):
		return
	system.level += 1
	_pay(price)
	_upgrades.append({"system_id": system_id, "price": price})


func can_undo_upgrade() -> bool:
	return not _upgrades.is_empty()


func undo_upgrade() -> void:
	if _upgrades.is_empty():
		return
	var last: Dictionary = _upgrades.pop_back()
	var system := design.system_by_id(last.system_id)
	if not system.is_empty():
		system.level -= 1
	mawjig = Money.round_amount(mawjig + float(last.price))
