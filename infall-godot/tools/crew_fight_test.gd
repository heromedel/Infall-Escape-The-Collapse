extends Node
## Checks the rules of a crew fight (GV 7G) on the Outrider's bridge, with no captain giving orders.
## Run: godot --headless --path . tools/crew_fight_test.tscn

var failed := 0
var encounter := Encounter.new()
var player: Ship
var enemy: Ship


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	player = Ship.from_design(Library.ship("outrider"), 0, rng)
	enemy = Ship.from_design(Library.ship("pirate-hijacker.cutpurse"), 1, rng)
	encounter.wallet = RunState.new()
	encounter.setup([player], [enemy], 3)
	var bridge := 0
	var pilot: CrewMember = player.crew[0]
	var walker: CrewMember = player.crew.back()
	var boarder: CrewMember = enemy.crew[0]

	encounter._land(boarder, player, bridge)
	check("a boarder lands on a tile with none of ours on it", player.standing_on(boarder.cell, 0) == null)
	run(Encounter.TELEPORT_TICKS + 100)
	check("a fighter with nobody on their tile shoots", boarder.melee_with == null and pilot.melee_with == null and boarder.aim_at != null)
	check("shots hurt both sides", boarder.health < boarder.max_health and pilot.health + player.crew[1].health < pilot.max_health + player.crew[1].max_health)
	var before := pilot.health + player.crew[1].health
	run(200)
	var lost := before - (pilot.health + player.crew[1].health)
	var each := CrewBrain.HIT_DAMAGE * boarder.race.melee
	check("one shooter lands a hit a second (%.1f health in 10 s, a hit is %.1f)" % [lost, each], absf(lost - 10.0 * each) <= each + 0.01)

	boarder.health = boarder.max_health * 50.0     # so the fight outlasts the checks
	for member in player.crew:
		member.health = member.max_health * 50.0
	CrewBrain.order_to_room(walker, bridge)
	check("whoever walks in heads for a foe's tile", walker.destination == boarder.cell)
	run(200)
	check("the two on a tile punch each other", walker.cell == boarder.cell and walker.melee_with == boarder and boarder.melee_with == walker)

	var spare := free_tile(bridge)
	CrewBrain.walk_to(walker, spare, true)
	run(120)
	check("the enemy follows a player's crew member moved to another tile", walker.cell == spare and boarder.cell == spare and boarder.melee_with == walker)

	var elsewhere := free_tile(bridge)
	CrewBrain.walk_to(boarder, elsewhere)
	run(120)
	check("a player's crew member does not follow, and shoots", walker.cell == spare and boarder.cell == elsewhere and walker.melee_with == null)

	CrewBrain.order_to_room(walker, bridge, true)
	run(120)
	check("sent back into the room, they pair again", walker.cell == boarder.cell)
	CrewBrain.order_to_room(walker, player.rooms.size() - 1, true)
	run(200)
	check("the enemy does not follow out of the room", player.room_at(boarder.cell) == bridge and player.room_at(walker.cell) != bridge)

	# Two boarders on the bridge, shooting it out with the two at their stations
	var second: CrewMember = enemy.crew[1]
	second.health = second.max_health * 50.0
	CrewBrain.order_to_room(boarder, bridge)
	encounter._land(second, player, bridge)
	run(Encounter.TELEPORT_TICKS + 200)
	var gunner: CrewMember = player.crew[1]
	var held := [pilot.aim_at, gunner.aim_at, boarder.aim_at, second.aim_at]
	var changes := 0
	for tick in 300:
		run(1)
		if [pilot.aim_at, gunner.aim_at, boarder.aim_at, second.aim_at] != held:
			changes += 1
			held = [pilot.aim_at, gunner.aim_at, boarder.aim_at, second.aim_at]
	check("a shooter stays on one foe (%d changes of target in 15 s)" % changes, changes == 0 and pilot.aim_at != null)
	pilot.aim_at = boarder
	boarder.aim_at = gunner
	CrewBrain._hit(second, pilot, encounter)
	check("hit by another foe while their own is busy elsewhere, they turn on the one who hit them", pilot.aim_at == second)
	pilot.aim_at = boarder
	boarder.aim_at = pilot
	CrewBrain._hit(second, pilot, encounter)
	check("hit by another foe while their own is shooting at them, they stay on their own", pilot.aim_at == boarder)

	print("crew fight rules: %s" % ("all hold" if failed == 0 else "%d FAILED" % failed))
	get_tree().quit(failed)


func run(ticks: int) -> void:
	for tick in ticks:
		for member in player.crew_present():
			CrewBrain.tick(member, encounter)


## A bridge tile nobody stands on or is heading for.
func free_tile(room_index: int) -> Vector2i:
	for cell in player.rooms[room_index].cells:
		if not player.cell_is_claimed(cell, 0) and not player.cell_is_claimed(cell, 1):
			return cell
	return Ship.NO_CELL


func check(what: String, holds: bool) -> void:
	print("%s  %s" % ["ok  " if holds else "FAIL", what])
	if not holds:
		failed += 1
