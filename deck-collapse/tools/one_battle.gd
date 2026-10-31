## Headless test: one AI vs AI battle with the full log printed. Args: -- a=0 b=1 seed=5
extends Node


func _ready() -> void:
	var a := 0
	var b := 1
	var seed_value := 5
	for argument in OS.get_cmdline_user_args():
		var value := int(argument.get_slice("=", 1))
		match argument.get_slice("=", 0):
			"a": a = value
			"b": b = value
			"seed": seed_value = value
	var designs := Catalog.designs
	var battle := Battle.new(designs[a], designs[b], 0, seed_value)
	var captains := [BattleAI.new("Normal", seed_value + 1), BattleAI.new("Normal", seed_value + 2)]
	print_events(battle.opening_events)
	var actions := 0
	var started := Time.get_ticks_msec()
	while not battle.over and actions < 3000:
		if battle.aftermath and battle.active_side == 1:
			break
		var side := battle.active_side
		var action: Dictionary = captains[side].next_action(battle, side)
		var events: Array = load("res://tools/simulate.gd").perform(battle, side, action)
		if action.kind != "end":
			print("    > ", action.kind, " ", action.get("target", action.get("system", "")))
		print_events(events)
		actions += 1
	print("actions %d, turns %d, ms %d, outcome %s winner %d" % [actions, battle.turn_number, Time.get_ticks_msec() - started, battle.outcome, battle.winner])
	get_tree().quit()


func print_events(events: Array) -> void:
	for event in events:
		if event.type == "log":
			print("[%d] %s" % [event.side, event.text])
		elif event.type == "refused":
			print("REFUSED: ", event.reason)
