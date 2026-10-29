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
var rng := RandomNumberGenerator.new()

var _stops_to_station := 0
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
		reward = wreck_reward(enemy.design, battle.outcome)
	var jump_cost := float(Catalog.rule("economy", "jumpCost", 0))
	var spent_in_battle := mawjig - battle.ships[0].mawjig
	mawjig = Money.round_amount(maxf(0.0, battle.ships[0].mawjig + reward - jump_cost))
	last_result = {"outcome": battle.outcome, "reward": reward, "jump_cost": jump_cost, "enemy": enemy.name,
		"spent": spent_in_battle,
		"won": battle.winner == 0 and battle.outcome != Battle.OUTCOME_ESCAPED}
	carry = snapshot(battle)
	_arrive_at_stop()


func _arrive_at_stop() -> void:
	_upgrades.clear()
	_stops_to_station -= 1
	station = null
	if Settings.value("station_frequency") == "Every Stop" or _stops_to_station <= 0:
		station = Station.new(design, rng)
		_stops_to_station = _station_gap()


func _station_gap() -> int:
	return rng.randi_range(int(Catalog.rule("station", "gapMin", 5)), int(Catalog.rule("station", "gapMax", 10)))


func stops_to_next_station() -> int:
	return 1 if Settings.value("station_frequency") == "Every Stop" else _stops_to_station


## A beaten enemy's Mawjig: a share of its ship's value, more if its crew was killed and the ship left whole.
static func wreck_reward(enemy_design: ShipDesign, outcome: String) -> float:
	var reward := enemy_design.value() * float(Catalog.rule("economy", "rewardPercent", 0)) / 100.0
	if outcome == Battle.OUTCOME_CREW_LOST:
		reward *= 1.0 + float(Catalog.rule("economy", "crewKillBonus", 0)) / 100.0
	return Money.round_amount(reward)


## The player's ship as the battle left it. Crew aboard the enemy ship when you jump are left behind.
static func snapshot(battle: Battle) -> Dictionary:
	var ship := battle.ships[0]
	var systems := {}
	for system_id in ship.systems:
		var system: Dictionary = ship.systems[system_id]
		systems[system_id] = {"damage": system.damage, "on_fire": system.on_fire, "breached": system.breached,
			"air": system.air}
	var survivors: Array = []
	for member in battle.living_crew_of(0):
		if member.ship == 0:
			survivors.append({"name": member.name, "skills": member.skills.duplicate(), "xp": member.xp.duplicate(),
				"wounds": member.wounds, "system": member.system})
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

func hull_repair_price() -> float:
	return float(Catalog.rule("economy", "hullRepair", 0))


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
		carry.systems[system_id].merge({"damage": 0, "on_fire": false, "breached": false}, true)
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
			if cargo_full():
				return "The cargo hold is full."
		"system":
			if design.has_system(item.type):
				return "Already installed."
	return ""


## Buys an item: a system is installed at level 1, a weapon goes into a free weapon slot (or cargo when there is
## none), a battlesuit type goes to cargo, crew join at the first system.
func buy(item: Dictionary) -> void:
	if why_cannot_buy(item) != "":
		return
	match item.kind:
		"system":
			var system := {"id": design.unused_system_id(item.type), "type": item.type, "level": 1}
			if item.type == "evb":
				system.suit = _cheapest_suit()
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
			cargo.append({"kind": "suit", "suit": item.suit, "name": item.name})
		"crew":
			var member: Dictionary = item.member
			carry.crew.append({"name": member.name, "skills": member.skills.duplicate(), "wounds": 0,
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
	if fitted <= 1 and not design.has_system("evb"):
		return "Keep at least one weapon or an EVB Dock."
	return ""


## Moves a fitted weapon into the cargo hold.
func store_weapon(system_id: String, slot: int) -> void:
	if cargo_full() or why_cannot_remove_weapon() != "":
		return
	var weapon: Dictionary = design.system_by_id(system_id).weapons.pop_at(slot)
	cargo.append({"kind": "weapon", "weapon": weapon, "name": weapon.name})


## Where a cargo item can go, as [{ target, label }]. A weapon's target is a weapon system id (a free slot) or
## "system id/slot" (swap with the weapon there); a battlesuit's is an EVB Dock id it would swap into.
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
			if system.type == "evb" and system.level >= Catalog.suit_kind(item.suit).cost and system.suit != item.suit:
				targets.append({"target": system.id, "label": "Use in %s Dock" % Catalog.suit_kind(system.suit).name})
	return targets


## Takes a cargo item out of the hold: into a free weapon slot, or swapped with what a slot or dock holds now.
func use_cargo(index: int, target: String) -> void:
	var item: Dictionary = cargo[index]
	cargo.remove_at(index)
	var parts := target.split("/")
	var system := design.system_by_id(parts[0])
	if item.kind == "suit":
		cargo.insert(index, {"kind": "suit", "suit": system.suit, "name": Catalog.suit_kind(system.suit).name})
		system.suit = item.suit
	elif parts.size() == 1:
		system.weapons.append(item.weapon)
	else:
		var slot := int(parts[1])
		var old: Dictionary = system.weapons[slot]
		system.weapons[slot] = item.weapon
		cargo.insert(index, {"kind": "weapon", "weapon": old, "name": old.name})


static func _cheapest_suit() -> String:
	var best := ""
	for suit_id in Catalog.suit_kinds:
		if best == "" or Catalog.suit_kind(suit_id).cost < Catalog.suit_kind(best).cost:
			best = suit_id
	return best


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
