## Headless test of the human captain's path: clicks cards, aims, moves crew and ends turns through the battle
## screen's own handlers, many times over, and reports anything that goes wrong.
## Run: godot --headless --path . res://tools/ui_test.tscn
extends Node

var problems: Array[String] = []


func _ready() -> void:
	Settings.values["animation_speed"] = "Fast"
	Settings.values["first_turn"] = "You"
	var rounds := 0
	for design in Catalog.designs.filter(func(d): return d.built_in):
		var enemy: ShipDesign = Catalog.designs[(Catalog.designs.find(design) + 3) % Catalog.designs.size()]
		await _play_battle(design, enemy)
		rounds += 1
	print("UI test: %d battles driven, %d problems" % [rounds, problems.size()])
	for problem in problems:
		print("  PROBLEM: ", problem)
	get_tree().quit()


func _play_battle(player: ShipDesign, enemy: ShipDesign) -> void:
	var screen := BattleScreen.new()
	screen.size = Vector2(1600, 900)
	add_child(screen)
	var run := RunState.new(player)
	screen.start(player, enemy, {}, run)
	var turns := 0
	while not screen.battle.over and turns < 60:
		await _wait_for_player(screen)
		if screen.battle.over:
			break
		turns += 1
		await _human_turn(screen)
	print("%s vs %s: %d player turns, over=%s aftermath=%s outcome=%s%s" % [player.name, enemy.name, turns,
		screen.battle.over, screen.battle.aftermath, screen.battle.outcome,
		"" if screen.battle.over else "  (can't jump: %s)" % screen.battle.why_cannot_jump(0)])
	if screen.battle.over and screen.player_survived():
		# Carry the ship into the store and on into a second battle, as Continue Run does.
		run.record_battle(screen.battle)
		var store := RunScreen.new()
		store.run = run
		add_child(store)
		await get_tree().process_frame
		var hull_before := run.hull()
		run.repair_hull(3)
		if run.hull() < hull_before:
			problems.append("Hull repair lowered the hull.")
		store.queue_free()
		var second := BattleScreen.new()
		second.size = Vector2(1600, 900)
		add_child(second)
		second.start(run.design, enemy, run.battle_carry(), run)
		await get_tree().process_frame
		if second.battle.ships[0].hull != run.hull():
			problems.append("Carried hull %d became %d." % [run.hull(), second.battle.ships[0].hull])
		print("  carried into battle 2: hull %d, crew %d, Mawjig %s" % [second.battle.ships[0].hull,
			second.battle.living_crew_of(0).size(), Money.text(run.mawjig)])
		second.queue_free()
	screen.queue_free()
	await get_tree().process_frame


func _wait_for_player(screen: BattleScreen) -> void:
	var waited := 0
	while (screen._busy or screen.battle.active_side != 0) and not screen.battle.over and waited < 4000:
		await get_tree().process_frame
		waited += 1
	if waited >= 4000:
		problems.append("Timed out waiting for the player's turn.")


## Plays like a simple human: every playable card, aimed at the first valid target, plus one crew move.
func _human_turn(screen: BattleScreen) -> void:
	var battle := screen.battle
	var tries := 0
	while tries < 30:
		tries += 1
		var played := false
		for card in battle.ships[0].hand.duplicate():
			if battle.why_cannot_play_anywhere(0, card.uid) != "":
				continue
			var before := battle.ships[0].hand.size()
			screen._on_card_clicked(card)
			await _settle(screen)
			if screen._targeting_uid == card.uid:
				var targets := battle.valid_targets(0, card.uid)
				if targets.is_empty():
					problems.append("%s: targeting started with no targets." % card.id)
					screen._cancel_selection()
					continue
				var target: Dictionary = targets[0]
				if target.has("crew") and not target.has("system"):
					var member := battle.crew_by_id(target.crew)
					screen._on_crew_clicked(screen._tiles[member.ship][member.system], target.crew)
					await _settle(screen)
					if screen._targeting_uid == card.uid:
						var second := battle.valid_targets(0, card.uid, target.crew)
						second = second.filter(func(t): return t.has("system"))
						if second.is_empty():
							screen._cancel_selection()
							continue
						target = second[0]
				# A multi-target weapon takes a click per bolt.
				var clicks := 0
				while screen._targeting_uid == card.uid and target.has("system") and clicks < 6:
					screen._on_tile_clicked(screen._tiles[int(target.ship)][target.system])
					await _settle(screen)
					clicks += 1
			if battle.ships[0].hand.size() < before:
				played = true
				break
			elif screen._targeting_uid >= 0:
				problems.append("%s stayed selected after aiming." % card.id)
				screen._cancel_selection()
		if not played or battle.over:
			break
	# In the aftermath a sensible captain makes sure someone is flying the ship.
	var piloting := battle.ships[0].first_system_of_type("piloting")
	if battle.aftermath and battle.manning_skill(battle.ships[0], piloting) < 0:
		for member in battle.living_crew_of(0):
			if not member.moved and member.ship == 0 and member.controlled_by < 0:
				screen._on_crew_clicked(screen._tiles[0][member.system], member.id)
				screen._on_tile_clicked(screen._tiles[0][piloting])
				await _settle(screen)
				break
	# Move one crew member somewhere new, by clicking them and then a tile.
	if not battle.over and not battle.aftermath:
		for member in battle.living_crew_of(0):
			if member.moved or member.ship != 0 or member.controlled_by >= 0:
				continue
			var tile: SystemTile = screen._tiles[0][member.system]
			screen._on_crew_clicked(tile, member.id)
			for system_id in battle.ships[0].system_order:
				if system_id != member.system:
					screen._on_tile_clicked(screen._tiles[0][system_id])
					await _settle(screen)
					break
			break
	if not battle.over and battle.aftermath and battle.why_cannot_jump(0) == "":
		await screen._on_jump()
		return
	if not battle.over and battle.active_side == 0:
		if battle.why_cannot_burn(0) == "":
			screen._on_tile_clicked(screen._tiles[0][battle.ships[0].first_system_of_type("engines")])
		screen._on_end_turn()
		await _settle(screen)


func _settle(screen: BattleScreen) -> void:
	await get_tree().process_frame
	var waited := 0
	while screen._busy and waited < 3000 and screen.battle.active_side == 0:
		await get_tree().process_frame
		waited += 1
