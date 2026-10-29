## The game's flow: which screen is showing, and what each screen leads to.
## Read top to bottom, this is the table of contents of the program.
##
## Test options (after "--" on the command line):
##   start=battle|setup|designer|rules|settings   open that screen first
##   player=<ship name>  enemy=<ship name>        ships for start=battle
##   autoplay                                     the AI plays your side too
##   screenshot=<file>:<seconds>                   save a screenshot after a delay, then quit
extends Control

var player_design: ShipDesign
var enemy_design: ShipDesign
## The current run: starts with each battle picked on the setup screen, continues through "Continue Run".
var run: RunState
var _screen: Control
var _options := {}


func _ready() -> void:
	theme = UiKit.theme()
	_read_options()
	player_design = _design_named(_options.get("player", "Wayfarer"))
	enemy_design = _design_named(_options.get("enemy", "Patrol Scout"))
	match _options.get("start", "menu"):
		"battle": show_battle()
		"setup": show_setup()
		"designer": show_designer(player_design.duplicate_design())
		"rules": show_rules()
		"settings": show_settings()
		"station": _preview_station()
		_: show_menu()
	if _options.has("screenshot"):
		_take_screenshot_later(_options.screenshot)


## For testing (start=station): a run stopped at a station after an unfought battle.
func _preview_station() -> void:
	run = RunState.new(player_design)
	run.record_battle(Battle.new(run.design, enemy_design, 0))
	if run.station == null:
		run.station = Station.new(run.design, run.rng)
	show_run()


func show_menu() -> void:
	var menu := MenuScreen.new()
	menu.chosen.connect(_on_menu_choice)
	_swap(menu)


func _on_menu_choice(choice: String) -> void:
	match choice:
		"battle": show_setup()
		"designer": show_designer(player_design.duplicate_design())
		"rules": show_rules()
		"settings": show_settings()
		"quit": get_tree().quit()


func show_setup() -> void:
	var setup := SetupScreen.new()
	setup.player_design = player_design
	setup.enemy_design = enemy_design
	setup.fight.connect(func(player: ShipDesign, enemy: ShipDesign):
		player_design = player
		enemy_design = enemy
		run = RunState.new(player_design)
		show_battle())
	setup.customize.connect(func(design: ShipDesign): show_designer(design.duplicate_design()))
	setup.back.connect(show_menu)
	_swap(setup)


func show_battle() -> void:
	if run == null:
		run = RunState.new(player_design)
	var battle_screen := BattleScreen.new()
	battle_screen.autoplay = _options.has("autoplay")
	battle_screen.finished.connect(func(choice: String): _on_battle_finished(choice, battle_screen.battle))
	_swap(battle_screen)
	battle_screen.start(run.design, enemy_design, run.battle_carry(), run)


func _on_battle_finished(choice: String, battle: Battle) -> void:
	match choice:
		"continue":
			run.record_battle(battle)
			show_run()
		"rematch": show_battle()
		"setup": show_setup()
		_: show_menu()


func show_run() -> void:
	var run_screen := RunScreen.new()
	run_screen.run = run
	run_screen.next_battle.connect(func():
		enemy_design = _random_enemy()
		show_battle())
	run_screen.end_run.connect(show_menu)
	_swap(run_screen)


func show_designer(design: ShipDesign) -> void:
	var designer := DesignerScreen.new()
	designer.design = design
	designer.fly.connect(func(flown: ShipDesign):
		player_design = flown
		show_setup())
	designer.back.connect(show_menu)
	_swap(designer)


func show_rules() -> void:
	var rules := RulesScreen.new()
	rules.back.connect(show_menu)
	_swap(rules)


func show_settings() -> void:
	var settings_screen := SettingsScreen.new()
	settings_screen.back.connect(show_menu)
	_swap(settings_screen)


# ---------------------------------------------------------------- helpers

func _swap(next_screen: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = next_screen
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_screen)
	_screen.modulate.a = 0.0
	create_tween().tween_property(_screen, "modulate:a", 1.0, 0.25)


func _random_enemy() -> ShipDesign:
	var choices := Catalog.designs.filter(func(d): return d.built_in and d.name != player_design.name)
	return choices[randi() % choices.size()]


func _design_named(ship_name: String) -> ShipDesign:
	for design in Catalog.designs:
		if design.name.to_lower() == ship_name.to_lower():
			return design
	return Catalog.designs[0]


func _read_options() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.contains("="):
			_options[argument.get_slice("=", 0)] = argument.substr(argument.find("=") + 1)
		else:
			_options[argument] = true


func _take_screenshot_later(spec: String) -> void:
	var path := spec.get_slice(":", 0)
	var seconds := float(spec.get_slice(":", 1)) if spec.contains(":") else 2.0
	await get_tree().create_timer(seconds).timeout
	get_viewport().get_texture().get_image().save_png(path)
	print("Screenshot saved: ", path)
	get_tree().quit()
