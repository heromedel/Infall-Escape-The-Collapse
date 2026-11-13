class_name PlayersWindow
extends Overlay
## Player setup (GV 4H): everyone in the game, their name, colour, title and input; what each commands (GV 4I);
## leaving (GV 4J); and LAN. On the title it sets up players and LAN; in a run the Admiral also assigns ships and
## crew, which every player can see.

var session: Session
var main: Node
var _list: VBoxContainer
var _address: LineEdit
var _join_name: LineEdit
var _status: Label


func open(owner: Session, game: Node) -> void:
	session = owner
	main = game
	place_panel(960)
	add_title("PLAYER SETUP")
	_list = scrolling_area()
	_status = UiKit.label("", 16, UiColours.TEXT_DIM, true)
	body.add_child(_status)
	add_button("Done", close)
	session.players_changed.connect(_rebuild)
	main.run_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	if not is_instance_valid(_list):
		return
	clear(_list)
	_list.add_child(_heading("PLAYERS"))
	for player in session.players:
		_list.add_child(_player_row(player))
	_list.add_child(UiKit.label("Controllers join by pressing Start during a run; the keyboard joins again with any key. On a controller: X or A select, A orders selected crew to a room, B steps back, Start opens the menu, View opens this.", 15, UiColours.TEXT_DIM, true))
	if main.run != null:
		_list.add_child(_separator())
		_list.add_child(_heading("WHO COMMANDS WHAT"))
		_list.add_child(UiKit.label("Any player may command a ship set to ANY. Ships take their crew with them; a crew member can be given to players of their own. The Admiral commands everything." if session.admiral_is_local() else "The Admiral, %s, decides who commands what." % session.titled_name(session.admiral), 15, UiColours.TEXT_DIM, true))
		# A player who left and came back: what they commanded went to the Admiral, who can hand it back (GDD 4F)
		for player in session.players:
			var theirs := Assignments.remembered_text(main.run, player.id)
			if theirs.is_empty() or not player.here:
				continue
			var back := HBoxContainer.new()
			back.add_theme_constant_override("separation", 8)
			var said := UiKit.label("%s commanded %s before leaving." % [session.titled_name(player.id), theirs], 16, UiColours.TEXT, true)
			said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			back.add_child(said)
			var returning: int = player.id
			if session.admiral_is_local():
				back.add_child(UiKit.button("RESTORE", func(): session.submit(session.admiral, {"k": "restore", "player": returning}), 120))
			_list.add_child(back)
		for index in main.run.squad.size():
			var ship: Ship = main.run.squad[index]
			if ship.is_gone():
				continue
			_list.add_child(_assign_row(ship.name, ship.assigned, true, false, func(players: Array, _own: bool): _assign({"sq": index, "players": players}), 0))
			for crew_index in ship.crew.size():
				var member: CrewMember = ship.crew[crew_index]
				if member.dead:
					continue
				var ci := crew_index
				_list.add_child(_assign_row(member.display_name(), member.assigned, false, member.own_assignment, func(players: Array, own: bool): _assign({"sq": index, "crew": ci, "players": players, "own": own}), 28))
	_list.add_child(_separator())
	_list.add_child(_heading("LAN"))
	_add_lan()


func _player_row(player: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var swatch := ColorRect.new()
	swatch.color = Color(player.colour)
	swatch.custom_minimum_size = Vector2(18, 18)
	row.add_child(swatch)
	var id: int = player.id
	var local: bool = player.peer == session.my_peer
	var input: String = "keyboard and mouse" if player.device == "keys" else ("controller %d" % (int(player.pad) + 1) if player.device == "pad" else "")
	if not local:
		input = "over LAN"
	if local and player.here:
		var name_box := LineEdit.new()
		name_box.text = player.name
		name_box.custom_minimum_size = Vector2(200, 36)
		name_box.text_submitted.connect(func(text: String): session.rename(id, text))
		name_box.focus_exited.connect(func(): session.rename(id, name_box.text))
		row.add_child(UiKit.label(session.title_of(id), 18, Color("#ffd46b") if session.is_admiral(id) else UiColours.TEXT, true))
		row.add_child(name_box)
	else:
		row.add_child(UiKit.label(session.titled_name(id), 18, UiColours.TEXT if player.here else UiColours.TEXT_DIM, true))
	var where := UiKit.label(input + ("" if player.here else " · away"), 16, UiColours.TEXT_DIM, true)
	where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(where)
	if local and player.here:
		row.add_child(UiKit.button("INPUT", func(): _next_input(player), 100))
		row.add_child(UiKit.button("LEAVE", func(): session.remove_local_player(id), 90))
	var can_hand_on: bool = session.admiral_is_local() or (session.is_host and not session.player_by_id(session.admiral).get("here", false))
	if not session.is_admiral(id) and player.here and can_hand_on:
		row.add_child(UiKit.button("MAKE ADMIRAL", func(): session.make_admiral(id), 170))
	return row


## The next input this machine has for a player: the keyboard and mouse, then each connected controller.
func _next_input(player: Dictionary) -> void:
	var inputs: Array = [["keys", -1]]
	for pad in Input.get_connected_joypads():
		inputs.append(["pad", pad])
	var at := 0
	for index in inputs.size():
		if inputs[index][0] == player.device and inputs[index][1] == player.pad:
			at = index
	var next: Array = inputs[(at + 1) % inputs.size()]
	session.set_input(player.id, next[0], next[1])


## A row of toggles: ANY (or WITH SHIP for a crew member) and one for each player in the game.
func _assign_row(label: String, assigned: Array, is_ship: bool, own: bool, give: Callable, indent: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(indent, 0)
	row.add_child(gap)
	var name_label := UiKit.label(label, 17 if is_ship else 15, UiColours.TEXT if is_ship else UiColours.TEXT_DIM, is_ship)
	name_label.custom_minimum_size = Vector2(300 - indent, 0)
	row.add_child(name_label)
	var editable := session.admiral_is_local()
	var first := UiKit.button("ANY" if is_ship else "WITH SHIP", func(): give.call([], false), 120)
	first.disabled = not editable
	_mark(first, assigned.is_empty() and (is_ship or not own))
	row.add_child(first)
	for player in session.players.filter(func(p): return p.here):
		var id: int = player.id
		var chosen: bool = assigned.has(id) and (is_ship or own)
		var toggle := UiKit.button(String(player.name).left(12), func():
			var players: Array = assigned.duplicate() if (is_ship or own) else []
			if players.has(id):
				players.erase(id)
			else:
				players.append(id)
			give.call(players, true), 0)
		toggle.disabled = not editable
		toggle.add_theme_color_override("font_color", Color(player.colour))
		toggle.add_theme_color_override("font_disabled_color", Color(player.colour, 0.6))
		_mark(toggle, chosen)
		row.add_child(toggle)
	return row


func _mark(button: Button, on: bool) -> void:
	if on:
		button.add_theme_stylebox_override("normal", UiKit.box(Color(0.12, 0.32, 0.2), UiColours.POWER_GREEN, 2, 4, 6))
		button.add_theme_stylebox_override("disabled", UiKit.box(Color(0.1, 0.24, 0.16), UiColours.POWER_GREEN, 2, 4, 6))


func _assign(fields: Dictionary) -> void:
	fields["k"] = "assign"
	session.submit(session.admiral, fields)


func _add_lan() -> void:
	if session.is_host:
		if session.is_open_to_lan():
			var addresses := Session.addresses()
			_list.add_child(UiKit.label("Open to LAN players. They join with this address: %s" % (", ".join(addresses) if not addresses.is_empty() else "(no network found)"), 17, UiColours.POWER_GREEN, true))
		else:
			_list.add_child(UiKit.button("OPEN THIS GAME TO LAN PLAYERS", func():
				_status.text = session.host_lan()
				_rebuild(), 0))
		_list.add_child(UiKit.label("Or join someone else's game:", 16, UiColours.TEXT_DIM, true))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var typed_address := _address.text if is_instance_valid(_address) else ""
		var typed_name := _join_name.text if is_instance_valid(_join_name) else ""
		_address = LineEdit.new()
		_address.text = typed_address
		_address.placeholder_text = "Host's IP address"
		_address.custom_minimum_size = Vector2(240, 40)
		row.add_child(_address)
		_join_name = LineEdit.new()
		_join_name.text = typed_name
		_join_name.placeholder_text = "Your name"
		_join_name.custom_minimum_size = Vector2(200, 40)
		row.add_child(_join_name)
		row.add_child(UiKit.button("JOIN", func():
			if _address.text.strip_edges().is_empty():
				_status.text = "Type the host's IP address first."
				return
			var why := session.join_lan(_address.text, _join_name.text)
			_status.text = why if not why.is_empty() else "Connecting to %s..." % _address.text.strip_edges()
			if why.is_empty():
				main.wait_for_host(), 100))
		_list.add_child(row)
	else:
		_list.add_child(UiKit.label("You are in %s's game." % session.titled_name(session.admiral), 17, UiColours.TEXT, true))
		_list.add_child(UiKit.button("LEAVE THE GAME", func():
			session.leave_lan()
			close()
			main.show_title(), 0))


func _heading(text: String) -> Label:
	return UiKit.label(text, 16, UiColours.ACCENT, true)


func _separator() -> Control:
	var line := ColorRect.new()
	line.color = UiColours.BORDER_DIM
	line.custom_minimum_size = Vector2(0, 1)
	return line
