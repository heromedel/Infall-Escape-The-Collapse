class_name MenuWindows
extends RefCounted
## The small windows: the enemy's surrender offer, the pause menu, settings, choosing a starting ship, and
## the end of a run. Each builds an Overlay and reports the player's choice through a callback.


static func surrender_offer(ship: Ship, amount: int, on_answer: Callable, shared: bool = false) -> Overlay:
	var window := Overlay.new()
	window.shared = shared
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


static func pause_menu(on_resume: Callable, on_settings: Callable, on_save_quit: Callable, on_quit: Callable, on_logs: Callable, leave_text: String = "Save and quit to the title") -> Overlay:
	var window := Overlay.new()
	window.place_panel(460)
	window.add_title("PAUSED")
	window.add_button("Resume", func(): on_resume.call(); window.close())
	window.add_button("Settings", func(): on_settings.call())
	window.add_button("How to play", func(): window.get_parent().add_child(how_to_play()))
	window.add_button("Open the logs folder", func(): on_logs.call())
	window.add_button(leave_text, func(): on_save_quit.call(); window.close())
	window.add_button("Save and quit the game", func(): on_quit.call())
	return window


## The settings, in tabs (GV 14G). Each setting lists its default first.
## The essentials on one page, for the title screen and the pause menu.
const HOW_TO_PLAY := [
	["The goal", "Jump from cluster to cluster toward the rim of the galaxy, ahead of the collapse, and find a way out of it. There are three: the Vector Frame's drive, the crossing and the convoy. The run is lost when every scout ship is gone."],
	["Mawjig", "Fuel, ammunition and money in one. A jump costs 1.21 and every shot costs a little. Stores take it for repairs, weapons, crew and ships. Won fights and events pay it."],
	["The collapse", "It grows from the centre of the galaxy with every jump and every wait, and swallows the clusters it reaches. Stay ahead of it."],
	["Your ship", "Hull is its health. Each shield layer stops one laser hit and then recharges. Evasion is the chance a shot misses you: it needs a pilot and powered engines. Air keeps the crew alive."],
	["Pause", "Space. Give orders while paused."],
	["Attack", "Click a weapon (or press 1 to 6), then click a room of an enemy ship. It fires when charged. V or AUTOFIRE keeps weapons firing."],
	["Power", "Click a system's bars to give it power, right click to take it away. Or use the key in its tooltip, with Shift to take away."],
	["Crew", "Click a crew member or drag a box, then right click a room to send them. They man the console, repair, put out fires and fight boarders there. TO STATIONS (Enter) sends everyone back."],
	["A system's buttons", "Small buttons above a system use it: open or close the doors, send or recall boarders, cloak, hack, mind control, the battery."],
	["Look around", "Mouse wheel zooms, middle drag or the arrow keys pan, Home shows the whole fight, Tab picks your next ship."],
	["Jump and shop", "J or JUMP opens the map: click a cluster joined to yours, then jump. U or SHIP upgrades your ships. A cluster with a store shows a STORE button."],
	["Where trouble is", "Nothing on the map says where a fight waits. It depends on whose space it is and how they are faring, on your own race, and on what you have done there. The map shows who lives in a cluster within sensor range and who is on the road: where many are passing through, expect trouble and people asking for help."],
	["Leaving a fight", "Each ship jumps clear on its own once its drive is charged (JUMP OUT), and comes back if the fight is won. When the squad is clear, the map opens and the jump to another cluster costs the usual 1.21. JUMP with only some ships clear leaves the rest behind."],
	["Refit yards", "Some stores have a yard: it moves a system from one of your ships to another for a quarter of its value, and buys ships."],
	["The Vector Frame", "The Mecha have built a ship around a drive that can leave the galaxy. It waits somewhere along the rim; the map says what you know of where. Beat it and its drive is yours: fitted to one of your ships, that ship leaves alone; fitted to The Colony Ship at a refit yard, everyone leaves."],
	["Its drive", "Destroy the Vector Frame while its drive is damaged and the drive is gone with it. Beaten down, the ship folds away on that drive unless the drive is damaged or jammed, and you meet it again nearby, partly mended. Killing its crew takes the ship whole."],
	["The crossing", "Late in a run The Colony Ship asks you to find the best technology of the other races and fit it to one ship. The map then says what that ship still lacks and which way to look."],
	["The convoy", "The Colony Ship asks you to win every people to a convoy that flies out together. Each one wants something different, and says so when you ask in its space or at its stores. With all of them pledged, they fight beside you at the rim."],
	["Which victories", "The Game settings switch the crossing and the convoy on or off, and can put the old Last Fleet at the rim in place of the Vector Frame."],
]


static func how_to_play() -> Overlay:
	var window := Overlay.new()
	window.place_panel(980)
	window.add_title("HOW TO PLAY")
	# The page is longer than a screen: it scrolls
	var page := window.scrolling_area()
	for entry in HOW_TO_PLAY:
		var line := window.add_text("[b]%s.[/b]  %s" % entry, 17)
		window.body.remove_child(line)
		page.add_child(line)
	window.refit.call_deferred()
	window.add_button("Close", window.close)
	return window


static func settings(tab: String = "Game") -> Overlay:
	var window := Overlay.new()
	window.place_panel(820)
	window.add_title("SETTINGS")
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	window.body.add_child(tabs)
	window.add_text("[color=#a8b8cc]Each setting lists its default first. Classic options bring play closer to the genre's own rules.[/color]", 16)
	var rows := window.scrolling_area()
	var show_tab := func(name: String) -> void:
		window.clear(rows)
		for button in tabs.get_children():
			button.disabled = button.text == name.to_upper()
		for id in Settings.TABS[name]:
			rows.add_child(_setting_row(id))
		if name == "HUD":
			rows.add_child(UiKit.button("Reset HUD layout", func():
				HudLayout.new().reset()
				for hud in window.get_tree().get_nodes_in_group("battle_hud"):
					hud.layout = HudLayout.load_saved(), 0))
		if name == "Battle":
			rows.add_child(_colour_row("player_power_custom", "Used when Specific Power Color is Custom."))
		if name == "Game":
			rows.add_child(UiKit.label("Terran Ship Conduits and Run Length apply to new runs. In a game with others, the host's settings for a run are used.", 15, UiColours.TEXT_DIM, true))
	for name in Settings.TABS:
		var tab_name: String = name
		tabs.add_child(UiKit.button(tab_name.to_upper(), func(): show_tab.call(tab_name), 0))
	show_tab.call(tab if Settings.TABS.has(tab) else "Game")
	window.add_button("Done", window.close)
	return window


## A setting that is a colour of the player's own choosing: a swatch that opens a colour picker.
static func _colour_row(id: String, note: String) -> Control:
	var row := HBoxContainer.new()
	var label := UiKit.label("%s  [%s]" % [Settings.OPTIONS[id][2], note], 18)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var picker := ColorPickerButton.new()
	picker.color = Color(String(Settings.get_value(id, Settings.OPTIONS[id][0])))
	picker.edit_alpha = false
	picker.custom_minimum_size = Vector2(360, 36)
	picker.color_changed.connect(func(colour: Color): Settings.set_value(id, "#" + colour.to_html(false)))
	row.add_child(picker)
	return row


static func _setting_row(id: String) -> Control:
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
		var button := UiKit.button(_choice_text(Settings.get_value(id, option[0])), func(): pass, 360)
		button.pressed.connect(func():
			var index := choices.find(Settings.get_value(id, option[0]))
			var next = choices[(index + 1) % choices.size()]
			Settings.set_value(id, next)
			button.text = _choice_text(next))
		row.add_child(button)
	return row


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


## The Alliance victory's end screen (Infall: Lori, Ai-Generated-Proposal 2026-11-14).
const ALLIANCE_WON_TITLE := "THE CONVOY"

## The Alliance end screen for the convoy of all seven (Infall: Lori, Ai-Generated-Proposal 2026-11-14).
const CONVOY_WON_TEXT := "The way out is clear. The convoy leaves the galaxy the long way, flying as one: The Colony Ship and every people that pledged, each guarding the next.\n\nThe crossing will take longer than anyone aboard will live. Their children will see the middle of it. Their grandchildren's grandchildren may see the end.\n\nThe GATOS cores keep it powered. The Azurethea keep its air. The Tentauri shield it. The Mecha keep it flying, for a price. The Senti remember the way. The Lykario hunt whatever comes for it. Behind it all, a Malphen growth feeds on what the convoy leaves, and grows it back.\n\nNobody makes the crossing alone. That was the point."

## The Vector Drive victory's end screens (Infall: Lori, Ai-Generated-Proposal 2026-11-14): fitted to one of the
## squad's ships, and fitted to The Colony Ship.
const VECTOR_WON_TITLE := "THE VECTOR"
const VECTOR_WON_TEXT := "The Mawjig Vector Drive folds space around one ship, and the galaxy is gone.\n\nAboard are the crew it could carry. Nobody else. Behind you, The Colony Ship is still flying toward a rim it will never cross.\n\nThe Mecha built that drive to save themselves. You took it. Wherever you arrive, you arrive as the ones who did."
const FOLD_WON_TITLE := "THE FOLD"
const FOLD_WON_TEXT := "Your scouts dock one by one, and their crews go aboard The Colony Ship. Then the Mawjig Vector Drive folds space around it, every passenger and every crew member, and the galaxy is gone.\n\nBehind you, the collapse reaches the rim. Nobody you saved will ever see it.\n\nThe Mecha built that drive to save themselves. You took it. Wherever The Colony Ship arrives, it arrives as the ones who did."

## The Tech victory's end screen (Infall: Lori, Ai-Generated-Proposal 2026-11-14).
const TECH_WON_TITLE := "THE CROSSING"
const TECH_WON_TEXT := "The best technology of other peoples, fitted into one ship that was never meant to exist. It flies into the dark between galaxies, and the dark lets it through.\n\nBehind you, The Colony Ship follows your signal as far as it can.\n\nBehind it, the collapse reaches the rim. It will never reach where you are going."

static func end_screen(run: RunState, won: bool, on_done: Callable) -> Overlay:
	var window := Overlay.new()
	window.dim.color = Color(0, 0.0, 0.02, 0.85)
	window.place_panel(860)
	if won and run.victory == "alliance":
		window.add_title(ALLIANCE_WON_TITLE, Color("#ffd46b"))
		window.add_text(CONVOY_WON_TEXT, 20)
	elif won and run.victory == "vector":
		window.add_title(VECTOR_WON_TITLE, Color("#ffd46b"))
		window.add_text(VECTOR_WON_TEXT, 20)
	elif won and run.victory == "fold":
		window.add_title(FOLD_WON_TITLE, Color("#ffd46b"))
		window.add_text(FOLD_WON_TEXT, 20)
	elif won and run.victory == "tech":
		window.add_title(TECH_WON_TITLE, Color("#ffd46b"))
		window.add_text(TECH_WON_TEXT, 20)
	elif won:
		window.add_title("THE WAY OUT", Color("#ffd46b"))
		window.add_text("The Last Fleet breaks apart behind you. Ahead there is nothing but the dark between galaxies, and a path your scouts have charted all the way across it.\n\nThe Colony Ship's signal comes through clear for the first time in weeks. \"We see your beacon. We're coming. Every one of us.\"\n\nBehind it, the collapse keeps growing. It will never reach you now.", 20)
	else:
		window.add_title("NO WAY ACROSS" if run.vector_drive == "lost" and not run.living_ships().is_empty() else "THE SCOUTS ARE GONE", UiColours.DAMAGED_RED)
		if run.vector_drive == "lost" and not run.living_ships().is_empty():
			window.add_text("The Mawjig Vector Drive is gone, and with it the only way across that you found. Your squad holds the rim for as long as it can.\n\nThe collapse reaches the edge of the galaxy. Then there is no edge at all.", 20)      # Infall: Lori
		elif run.cluster().kind == "final" and not VectorHunt.allowed():
			window.add_text("The last of your scout ships is gone. The Last Fleet takes the path out alone, and behind it the way closes. Somewhere back in the dark, The Colony Ship waits for a signal that will never come.", 20)
		else:
			window.add_text("The last of your scout ships is gone. Somewhere behind you, The Colony Ship waits for a signal that will never come, and the collapse moves on.", 20)
	window.add_separator()
	var stats := run.stats
	window.add_text("Jumps made: %d\nEnemy ships destroyed: %d\nEnemy crews defeated: %d\nMawjig earned: %s\nScout ships lost: %d\nReached band %d of %d" % [stats.jumps, stats.ships_destroyed, stats.crews_killed, Mawjig.format(stats.mawjig_earned), stats.ships_lost, run.band(), run.galaxy.bands], 18, UiColours.TEXT_DIM)
	window.add_button("Return to the title", func(): on_done.call(); window.close())
	return window
