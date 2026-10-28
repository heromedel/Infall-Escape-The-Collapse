## A run of battles with one ship. The ship's state carries from battle to battle exactly as it was left: hull,
## system damage, fires, breaches, wounds, crew positions, dead crew and missiles. Only Mawjig spent between battles
## repairs the hull, as repairs in the genre are bought at a stop, not done for free.
class_name RunState
extends RefCounted

var design: ShipDesign
## What the ship brings into its next battle (see Battle._init). Empty before the first battle.
var carry := {}
var mawjig := 0.0
var battles_won := 0
var battles_fought := 0
## The last battle's result, for the screen between battles: { outcome, reward, jump_cost, enemy }.
var last_result := {}


func _init(ship_design: ShipDesign) -> void:
	design = ship_design
	mawjig = float(Catalog.rule("economy", "startingMawjig", 0))


## Takes the ship's state and the reward from a finished battle the player survived.
func record_battle(battle: Battle) -> void:
	battles_fought += 1
	var enemy := battle.ships[1]
	var reward := 0.0
	if battle.winner == 0 and battle.outcome in [Battle.OUTCOME_DESTROYED, Battle.OUTCOME_CREW_LOST]:
		battles_won += 1
		reward = wreck_reward(enemy.design, battle.outcome)
	var jump_cost := float(Catalog.rule("economy", "jumpCost", 0))
	mawjig = Money.round_amount(maxf(0.0, mawjig + reward - jump_cost))
	last_result = {"outcome": battle.outcome, "reward": reward, "jump_cost": jump_cost, "enemy": enemy.name,
		"won": battle.winner == 0 and battle.outcome != Battle.OUTCOME_ESCAPED}
	carry = snapshot(battle)


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
		systems[system_id] = {"damage": system.damage, "on_fire": system.on_fire, "breached": system.breached}
	var survivors: Array = []
	for member in battle.living_crew_of(0):
		if member.ship == 0:
			survivors.append({"name": member.name, "skills": member.skills.duplicate(), "wounds": member.wounds,
				"system": member.system})
	return {"hull": ship.hull, "hull_max": ship.hull_max, "missiles": ship.missiles, "systems": systems, "crew": survivors}


# ---------------------------------------------------------------- the store between battles

func hull() -> int:
	return int(carry.get("hull", 0))


func hull_max() -> int:
	return int(carry.get("hull_max", 0))


func hull_repair_price() -> float:
	return float(Catalog.rule("economy", "hullRepair", 0))


func missile_price() -> float:
	return float(Catalog.rule("economy", "missile", 0))


func crew_price() -> float:
	return float(Catalog.rule("economy", "crew", 0))


func can_afford(price: float) -> bool:
	return mawjig + 0.0001 >= price


## Repairs up to this many hull points, as many as Mawjig allows. Returns the points repaired.
func repair_hull(points: int) -> int:
	var repaired := 0
	while repaired < points and hull() < hull_max() and can_afford(hull_repair_price()):
		carry.hull = hull() + 1
		mawjig = Money.round_amount(mawjig - hull_repair_price())
		repaired += 1
	return repaired


func buy_missile() -> bool:
	if not can_afford(missile_price()):
		return false
	carry.missiles = int(carry.get("missiles", 0)) + 1
	mawjig = Money.round_amount(mawjig - missile_price())
	return true


## Hires an untrained crew member, who starts at the ship's first system.
func hire_crew(crew_name: String) -> bool:
	if not can_afford(crew_price()) or carry.crew.size() >= 8:
		return false
	carry.crew.append({"name": crew_name, "skills": CrewSkills.empty(), "wounds": 0, "system": design.systems[0].id})
	mawjig = Money.round_amount(mawjig - crew_price())
	return true


func uses_missiles() -> bool:
	return design.systems.any(func(s): return s.type == "weapon" and Catalog.weapon_kind(s.kind).uses_missile)
