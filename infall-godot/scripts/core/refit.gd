class_name Refit
extends RefCounted
## The squad's refits as orders (GV 4C): buying and selling at a store, upgrades, fitting weapons and moving crew.
## The store and the ship screen give these orders; every machine plays them here, so the run stays the same
## everywhere. Ships are named by their place in the squad, crew by their place in their ship's crew.

const INSTALLABLE := ["medbay", "doors", "sensors", "crew-teleporter", "cloaking", "supershield", "evb-dock", "shields", "life-support", "hacking", "mind-control", "backup-battery", "eva-dock"]
const RACE_OWN := {"senti": {"hacking": "intrusion-array", "shields": "shield-projector", "medbay": "aaa"}, "azurethea": {"mind-control": "pheromone-gland"}}   # a race's own make of a system


static func apply(run: RunState, order: Dictionary) -> void:
	var ship: Ship = run.squad[int(order.sq)] if order.has("sq") and int(order.sq) >= 0 and int(order.sq) < run.squad.size() else null
	match String(order.op):
		"repair":
			var per_point := repair_price(run)
			for count in int(order.points):
				var target: Ship = null
				for each in run.living_ships():
					if each.hull < each.max_hull and (target == null or float(each.hull) / each.max_hull < float(target.hull) / target.max_hull):
						target = each
				if target == null or not run.spend(per_point):
					break
				target.repair_hull(1)
		"buy_weapon":
			var def := Library.weapon(order.id)
			if def and ship and run.spend(int(order.price)):
				ensure_stock(run)
				run.cluster().store_stock.sold.append("weapon:" + def.id)
				if not ShipOutfitter.fit_weapon(ship, def):
					run.cargo.append(def.id)
				run.log_book.write("bought", {"weapon": def.id, "price": order.price}, "Bought %s for %s." % [def.display_name(), Mawjig.format(int(order.price))])
		"buy_crew":
			var race := Library.race(order.race)
			var target: Ship = null
			for each in ([ship] if ship else []) + run.living_ships():
				if race and can_host(each, race):
					target = each
					break
			ensure_stock(run)
			var member := crew_for_sale(run, int(order.index))
			if race and member and target and run.spend(int(order.price)):
				run.cluster().store_stock.sold.append("crew:%d" % int(order.index))
				target.add_crew(member)
				target.assign_stations()
				run.log_book.write("hired", {"race": race.id, "name": member.name}, "%s joined the %s." % [member.name, target.name])
		"buy_system":
			var def := Library.system(order.id)
			if def and ship and ShipOutfitter.install_refusal(ship, def, int(order.room)).is_empty() and run.spend(int(order.price)):
				ensure_stock(run)
				var installed := ShipOutfitter.install_system(ship, def, int(order.room))
				installed.make = run.cluster().race if run.cluster().race != "" else "terran"     # the store's own make
				run.cluster().store_stock.sold.append("system:" + def.id)
				run.log_book.write("installed", {"system": def.id, "room": order.room}, "Installed %s on the %s." % [def.name, ship.name])
		"buy_ship":
			var design := Library.ship(order.id)
			if design and run.living_ships().size() < EventRunner.MAX_SQUAD and run.spend(int(order.price)):
				ensure_stock(run)
				var bought := Ship.from_design(design, 0, run.rng, Settings.get_value("terran_conduits", false))
				run.squad.append(bought)
				run.cluster().store_stock.sold.append("ship")
				run.log_book.write("bought_ship", {"design": design.id, "price": order.price}, "The %s joined the squad." % bought.name)
		"buy_tech":
			var race := RimTech.sold_at(run.cluster())
			if run.tech_goal and race != "" and race == String(order.race) and not run.has_tech(race) and run.spend(RimTech.price(race, run.band())):
				run.give_tech(race, "bought")
		"move_system":
			var to: Ship = run.squad[int(order.to)] if int(order.to) >= 0 and int(order.to) < run.squad.size() else null
			var index := int(order.sys)
			var system: ShipSystem = ship.systems[index] if ship and index >= 0 and index < ship.systems.size() else null
			if system and to and has_yard(run.cluster()) and move_refusal(run, ship, system, to, int(order.room)).is_empty() and run.spend(move_price(ship, system)):
				move_system(ship, system, to, int(order.room))
				run.log_book.write("refit", {"system": system.def.id, "from": ship.design.id, "to": to.design.id}, "The %s was moved from the %s to the %s." % [system.def.name, ship.name, to.name])
		"sell_ship":
			if ship and has_yard(run.cluster()) and sell_ship_refusal(run, ship).is_empty():
				var price := sell_ship_price(run, ship)
				for member in ship.crew.duplicate():
					if member.dead:
						continue
					for other in run.own_ships():
						if other != ship and can_host(other, member.race):
							ship.crew.erase(member)
							other.add_crew(member)
							member.station_room = -1
							other.assign_stations()
							break
				run.squad.erase(ship)
				run.earn(price)
				run.log_book.write("sold_ship", {"design": ship.design.id, "price": price}, "The %s was sold for %s." % [ship.name, Mawjig.format(price)])
		"sell":
			var index := int(order.index)
			if index >= 0 and index < run.cargo.size() and run.cargo[index] == order.id:
				run.cargo.remove_at(index)
				run.earn(int(order.price))
		"upgrade_system":
			var index := int(order.sys)
			if ship and index >= 0 and index < ship.systems.size():
				ShipOutfitter.upgrade_system(run, ship, ship.systems[index])
		"upgrade_reactor":
			if ship:
				ShipOutfitter.upgrade_reactor(run, ship)
		"unfit":
			var index := int(order.w)
			if ship and index >= 0 and index < ship.weapons.size():
				var slot := ship.weapons[index]
				ShipOutfitter.unfit_weapon(ship, slot)
				run.cargo.append(slot.def.id)
		"fit":
			var index := int(order.index)
			if ship and index >= 0 and index < run.cargo.size():
				var def := Library.weapon(run.cargo[index])
				if def and ShipOutfitter.fit_weapon(ship, def):
					run.cargo.remove_at(index)
		"crew_to":
			var to: Ship = run.squad[int(order.to)] if int(order.to) >= 0 and int(order.to) < run.squad.size() else null
			var member := _member(ship, order)
			if member and to and to != ship and to.living_crew_count() < EventRunner.MAX_CREW_PER_SHIP and ship.living_crew_count() > 1:
				ship.crew.erase(member)
				to.add_crew(member)
				member.station_room = -1
				to.assign_stations()
				ship.assign_stations()
		"promote":
			var member := _member(ship, order)
			if member and member.rank_due() >= 0:
				member.rank = member.rank_due()
				run.log_book.write("promoted", {"name": member.name, "rank": member.rank}, "%s was promoted to %s." % [member.name, CrewMember.RANK_TITLE[member.rank]])
		"dismiss":
			var member := _member(ship, order)
			if member and ship.living_crew_count() > 1:
				ship.crew.erase(member)


static func _member(ship: Ship, order: Dictionary) -> CrewMember:
	var index := int(order.get("crew", -1))
	return ship.crew[index] if ship and index >= 0 and index < ship.crew.size() else null


# --- The refit yard (GV 5E; heromedel, 2026-11-14) --------------------------------------------------------------
# Some stores can move a system from one of the squad's ships to another, for a quarter of its value, and buy a ship.

const MOVE_SHARE := 0.25
const SHIP_SALE_SHARE := 0.5      # of what a store asks for the design (Infall: Eco)

## Whether this cluster's store has a refit yard: wherever a shipyard has a ship for sale, and half the other stores.
static func has_yard(cluster: Dictionary) -> bool:
	if not cluster.get("store", false) and cluster.kind != "store":
		return false
	var stock: Dictionary = cluster.get("store_stock", {})
	return String(stock.get("ship", "")) != "" or int(cluster.seed) % 2 == 0


## What a system is worth at its level, in cents: its price and the upgrades paid for; a core by its level's steps.
static func system_value(ship: Ship, system: ShipSystem) -> int:
	var total := 0
	if system.behaviour == "power_core":
		for step in mini(ship.reactor_level, ShipOutfitter.AZC_STEP_PRICES.size()):
			total += ShipOutfitter.AZC_STEP_PRICES[step]
		return total
	total = system.def.buy_price
	for level in range(1, system.level):
		total += maxi(0, system.def.upgrade_price(level))
	return total


static func move_price(ship: Ship, system: ShipSystem) -> int:
	return Mawjig.no_trailing_zero(int(round(system_value(ship, system) * MOVE_SHARE)))


## Why a system can't go from one ship to another at all, or "" when some room of the other ship may take it.
static func move_refusal_between(run: RunState, from: Ship, system: ShipSystem, to: Ship) -> String:
	if from == to:
		return "It is already on that ship."
	if from.is_mercenary() or to.is_mercenary():
		return "A mercenary's ship isn't yours to refit."
	if system.behaviour in ["weapons", "weapon_pod"] and not from.weapons_on(system).is_empty():
		return "Move its weapons to the hold first."
	if system.behaviour == "power_core":
		if to.reactor_type != "core" or to.system_by("power_core") != null:
			return "The %s has its own reactor." % to.name
	elif to.system_by(system.behaviour) != null:
		return "The %s already has its own %s." % [to.name, to.system_by(system.behaviour).def.name]
	if ShipOutfitter.room_for_new_system(to, system.def) < 0:
		return "The %s has no room that can take it." % to.name
	if run.mawjig < move_price(from, system):
		return "Not enough Mawjig."
	return ""


static func move_refusal(run: RunState, from: Ship, system: ShipSystem, to: Ship, room: int) -> String:
	var why := move_refusal_between(run, from, system, to)
	return why if not why.is_empty() else ShipOutfitter.install_refusal(to, system.def, room)


## What the squad is warned of before a system that a ship can't do without is moved off it, or "".
static func move_warning(from: Ship, system: ShipSystem) -> String:
	match system.behaviour:      # Infall: Lori's wording
		"power_core":
			return "The %s will be left without a power core. None of its systems will have power." % from.name
		"oxygen":
			return "The %s will have no Life Support. Its air will run out, and its crew may suffocate." % from.name
		"piloting":
			return "The %s will have no Piloting, so it won't be able to jump." % from.name
		"engines":
			return "The %s will have no Engines. It can't charge its Jigawatt Drive, so it won't be able to jump." % from.name
	return ""


static func move_system(from: Ship, system: ShipSystem, to: Ship, room: int) -> void:
	ShipOutfitter.remove_system(from, system)
	ShipOutfitter.place_system(to, system, room)
	if system.behaviour == "power_core":
		to.reactor_level = from.reactor_level
		from.reactor_level = 0
	for each in [from, to]:
		each.settle_power()
		each.assign_stations()


## What a yard pays for a ship (Infall: Eco, finding F17): half of what a store asks for its design, less 1.21 for
## each missing hull point, each broken system bar (2.42 for Piloting, Engines and Life Support) and each breach;
## 15 points come off the half for each core system it lacks, never below 5%. Never below nothing.
const CORE_SYSTEMS := ["piloting", "engines", "oxygen"]

static func sell_ship_price(run: RunState, ship: Ship) -> int:
	var share := SHIP_SALE_SHARE
	for behaviour in CORE_SYSTEMS:
		if ship.system_by(behaviour) == null:
			share -= 0.15
	var price := ship_price(run, ship.design, 1.0) * maxf(0.05, share)
	price -= 121.0 * (ship.max_hull - ship.hull)
	for system in ship.systems:
		price -= (242.0 if system.behaviour in CORE_SYSTEMS else 121.0) * system.damage
	for room in ship.rooms:
		price -= 121.0 * room.breaches.size()
	return Mawjig.no_trailing_zero(maxi(0, int(round(price))))


static func sell_ship_refusal(run: RunState, ship: Ship) -> String:
	if ship.is_mercenary():
		return "A mercenary's ship isn't yours to sell."
	if run.own_ships().size() <= 1:
		return "The squad can't sell its last ship."
	return ""


## Per hull point by band: 0.48 in bands 1-3, 0.73 in 4-6, 0.97 in 7-8 (mawjig-cost-table.md).
## Whether a ship can take on a crew member of a race: a bunk free, and for a Senti, room in its Armoured Avatar
## Array (race profiles, Senti 9: a ship needs an array to host even one).
static func can_host(ship: Ship, race: RaceDef) -> bool:
	return ship.living_crew_count() < EventRunner.MAX_CREW_PER_SHIP and (not race.broadcast or ship.avatar_room() > 0)


## What a store asks for a ship: a share of its value by difficulty (Infall: Eco, 2026-11-14: Easy 50%, Normal 75%,
## Hard 100%), times the cluster's price scale.
const SHIP_PRICE_SHARE := {"Easy": 0.5, "Normal": 0.75, "Hard": 1.0}

static func ship_price(run: RunState, design: ShipDesign, scale: float) -> int:
	return Mawjig.amount(design.value * SHIP_PRICE_SHARE.get(run.difficulty, 0.75) * scale / 100.0)


static func repair_price(run: RunState) -> int:
	var band := run.band()
	return 48 if band <= 3 else (73 if band <= 6 else 97)


## The crew member in one of the store's slots, as they will be when bought: their name and their subtype (GV 7F),
## neither already in the squad nor given to anyone for sale in a slot before theirs. Worked out with the cluster's
## own numbers, so the store's picture, the crew member bought and every machine agree. Null for a slot that isn't
## there.
static func crew_for_sale(run: RunState, slot: int) -> CrewMember:
	var stock: Dictionary = run.cluster().store_stock
	var names: Array = []
	for ship in run.squad:
		names.append_array(ship.crew.map(func(aboard): return aboard.name))
	var worn := {}              # race id -> subtypes
	var member: CrewMember = null
	for index in mini(slot + 1, stock.crew.size()):
		if index < slot and stock.sold.has("crew:%d" % index):
			continue
		var race := Library.race(stock.crew[index])
		if not worn.has(race.id):
			worn[race.id] = CrewSkins.worn(run.squad, race)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(run.cluster().seed) + 78 + index
		member = CrewMember.create(race, race.random_name(rng, names))
		member.subtype = CrewSkins.pick(race, worn[race.id], rng)
		names.append(member.name)
		worn[race.id].append(member.subtype)
	return member if slot < stock.crew.size() else null


## What the cluster's store sells, worked out once from the cluster's seed. Stock depends on the cluster's race and
## state (GDD 2R: doomed and refugee stores run short).
static func ensure_stock(run: RunState) -> void:
	var cluster := run.cluster()
	if not cluster.store_stock.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cluster.seed) + 77
	var race: String = cluster.race if cluster.race != "" else "terran"
	var short: bool = cluster.states.has("Doomed") or cluster.states.has("Refugee") or cluster.states.has("Occupied")
	var stock := {"weapons": [], "systems": [], "crew": [], "ship": "", "sold": []}
	var weapon_pool: Array = []
	for def in Library.weapons.values():
		if def.type == "suit" or def.id.ends_with("-stolen"):
			continue
		var weight := 3 if def.race == race else 1
		if def.price > 1200 + run.band() * 280:
			continue
		for copy in weight:
			weapon_pool.append(def.id)
	for count in (2 if short else 3):
		if weapon_pool.is_empty():
			break
		var pick: String = weapon_pool[rng.randi_range(0, weapon_pool.size() - 1)]
		weapon_pool = weapon_pool.filter(func(id): return id != pick)
		stock.weapons.append(pick)
	var systems := INSTALLABLE.duplicate()
	if race != "tentauri":
		systems.erase("supershield")
	if race != "mecha":
		systems.erase("evb-dock")
	if race != "lykario":
		systems.erase("cloaking")
	for index in range(systems.size() - 1, 0, -1):   # shuffled with the cluster's own numbers, the same on every machine
		var other := rng.randi_range(0, index)
		var swap = systems[index]
		systems[index] = systems[other]
		systems[other] = swap
	for index in mini(2 if short else 3, systems.size()):
		stock.systems.append(RACE_OWN.get(race, {}).get(systems[index], systems[index]))
	var crew_races := [race, "terran"] if race != "malphen" else ["terran"]
	for count in (1 if short else 2):
		stock.crew.append(crew_races[rng.randi_range(0, crew_races.size() - 1)])
	var late: bool = int(cluster.band) >= 4 and rng.randf() < 0.35      # from band 4 on, more stores have a ship to sell (Infall: Eco, 2026-11-14)
	if (cluster.race == "terran" and cluster.rank != "border" and rng.randf() < 0.45) or (cluster.states.has("Refugee") and rng.randf() < 0.5) or late:
		var ships := {"terran": ["patrol-cutter", "outrider"], "tentauri": ["tentauri-scout"], "azurethea": ["moth-skiff"], "lykario": ["packrunner"], "senti": ["relay-picket"], "mecha": ["light-attack-frame"]}.get(race, ["patrol-cutter"]) as Array
		stock.ship = ships[rng.randi_range(0, ships.size() - 1)]
	cluster.store_stock = stock
