class_name MenuWindows
extends RefCounted
## The small windows: the enemy's surrender offer, the pause menu, settings, choosing a starting ship, and
## the end of a run. Each builds an Overlay and reports the player's choice through a callback.


static func surrender_offer(ship: Ship, amount: int, on_answer: Callable) -> Overlay:
	var window := Overlay.new()
	window.place_panel(700)
	window.add_title("THE %s HAILS YOU" % ship.name.to_upper(), UiColours.WARNING)
	var line := "\"Enough! We give up. Take %s Mawjig and let us go.\"" % Mawjig.format(amount)
	if ship.race.id == "malphen":
		line = "The living ship jettisons a cloud of dense matter worth about %s Mawjig, and turns to flee. This is how the Malphen surrender." % Mawjig.format(amount)
	elif ship.race.id == "mecha":
		line = "\"You win this one. %s Mawjig, and you forget you saw us.\"" % Mawjig.format(amount)
	window.add_text(line, 20)
	window.add_button("1. Accept their surrender.", func(): on_answer.call(true); window.close())
	window.add_button("2. Refuse. Keep fighting.", func(): on_answer.call(false); window.close())
	return window


static func pause_menu(on_resume: Callable, on_settings: Callable, on_save_quit: Callable, on_quit: Callable, on_logs: Callable) -> Overlay:
	var window := Overlay.new()
	window.place_panel(460)
	window.add_title("PAUSED")
	window.add_button("Resume", func(): on_resume.call(); window.close())
	window.add_button("Settings", func(): on_settings.call())
	window.add_button("Open the logs folder", func(): on_logs.call())
	window.add_button("Save and quit to the title", func(): on_save_quit.call(); window.close())
	window.add_button("Save and quit the game", func(): on_quit.call())
	return window


static func settings() -> Overlay:
	var window := Overlay.new()
	window.place_panel(760)
	window.add_title("SETTINGS")
	window.add_text("[color=#a8b8cc]Each setting lists its default first. Classic options bring play closer to the genre's own rules.[/color]", 16)
	# The list scrolls, so it never runs off a small screen
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 560)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	window.body.add_child(scroll)
	for id in Settings.OPTIONS:
		var option: Array = Settings.OPTIONS[id]
		var choices: Array = option[1]
		var row := HBoxContainer.new()
		var label := UiKit.label(option[2], 18)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if choices.is_empty():
			var slider := HSlider.new()
			slider.min_value = 0.0
			slider.max_value = 1.0
			slider.step = 0.05
			slider.value = float(Settings.get_value(id, option[0]))
			slider.custom_minimum_size = Vector2(240, 24)
			slider.value_changed.connect(func(value): Settings.set_value(id, value); Sfx.apply_volumes())
			row.add_child(slider)
		else:
			var button := UiKit.button(_choice_text(Settings.get_value(id, option[0])), func(): pass, 240)
			button.pressed.connect(func():
				var index := choices.find(Settings.get_value(id, option[0]))
				var next = choices[(index + 1) % choices.size()]
				Settings.set_value(id, next)
				button.text = _choice_text(next))
			row.add_child(button)
		rows.add_child(row)
	window.add_text("[color=#a8b8cc]Terran Ship Conduits and Run Length apply to new runs.[/color]", 15)
	window.add_button("Reset HUD layout", func():
		HudLayout.new().reset()
		for hud in window.get_tree().get_nodes_in_group("battle_hud"):
			hud.layout = HudLayout.load_saved())
	window.add_button("Done", window.close)
	return window


static func _choice_text(value) -> String:
	if typeof(value) == TYPE_BOOL:
		return "On" if value else "Off"
	if typeof(value) == TYPE_FLOAT:
		return "%d" % int(value)
	return str(value)


## The starting ships: the GATOS Outrider always (GDD 7C); others unlock as the player gets farther.
static func ship_select(on_pick: Callable, on_back: Callable) -> Overlay:
	var window := Overlay.new()
	window.place_panel(980)
	window.add_title("CHOOSE YOUR SCOUT")
	window.add_text("The colony ship is waiting. Choose the ship that will ride out ahead of it.", 19)
	var starts := [
		["outrider", "Always available. A GATOS scout cruiser with good sensors, a three-shot laser and a light missile. Its power runs through a conduit wheel around an armoured core.", ""],
		["patrol-cutter", "A tidy GATOS patrol cutter: four crew, twin lasers, a missile and a medbay.", "reach_band_3"],
		["tentauri-scout", "Two Tentauri, two rooms, two defense lasers and a Supershield. It gets in, survives and gets out.", "reach_band_5"],
		["packrunner", "A Lykario raider with a teleporter and four hunters who would rather board than shoot.", "win"],
	]
	var unlocked := Profile.unlocked()
	for start in starts:
		var design := Library.ship(start[0])
		if design == null:
			continue
		var open: bool = start[2] == "" or unlocked.has(start[2])
		var hint: String = {"reach_band_3": "Reach band 3 in any run to unlock.", "reach_band_5": "Reach band 5 in any run to unlock.", "win": "Reach the rim and win to unlock."}.get(start[2], "")
		var text := "%s  ·  %s\n%s" % [design.name, design.race.capitalize() if design.race != "terran" else "GATOS", start[1] if open else hint]
		var button := window.add_button(text, func(): on_pick.call(start[0]); window.close())
		button.disabled = not open
		button.custom_minimum_size = Vector2(0, 76)
	window.add_button("Back", func(): on_back.call(); window.close())
	return window


static func end_screen(run: RunState, won: bool, on_done: Callable) -> Overlay:
	var window := Overlay.new()
	window.dim.color = Color(0, 0.0, 0.02, 0.85)
	window.place_panel(860)
	if won:
		window.add_title("THE WAY OUT", Color("#ffd46b"))
		window.add_text("The Last Fleet breaks apart behind you. Ahead there is nothing but the dark between galaxies, and a path your scouts have charted all the way to its edge.\n\nThe Colony Ship's signal comes through clear for the first time in weeks. \"We see your beacon. We're coming. Every one of us.\"\n\nBehind it, the collapse keeps growing. It will not reach you here.", 20)
	else:
		window.add_title("THE SCOUTS ARE GONE", UiColours.DAMAGED_RED)
		window.add_text("The last of your scout ships is gone. Somewhere behind you, The Colony Ship waits for a signal that will not come, and the collapse moves on.", 20)
	window.add_separator()
	var stats := run.stats
	window.add_text("Jumps made: %d\nEnemy ships destroyed: %d\nEnemy crews defeated: %d\nMawjig earned: %s\nScout ships lost: %d\nReached band %d of %d" % [stats.jumps, stats.ships_destroyed, stats.crews_killed, Mawjig.format(stats.mawjig_earned), stats.ships_lost, run.band(), run.galaxy.bands], 18, UiColours.TEXT_DIM)
	window.add_button("Return to the title", func(): on_done.call(); window.close())
	return window
