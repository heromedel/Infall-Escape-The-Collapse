class_name PlayersWindow
extends Overlay
## The Players menu (GV 4C): everyone in the game, their colour, who is the Admiral, and how others join. The
## host opens the game to LAN players and the Admiral can hand the role on; anyone can join a host by its IP
## address or leave. Controllers on this machine join by pressing Start.

var session: Session
var main: Node
var _list: VBoxContainer
var _address: LineEdit
var _name: LineEdit
var _status: Label


func open(owner: Session, game: Node) -> void:
	session = owner
	main = game
	place_panel(760)
	add_title("PLAYERS")
	_list = scrolling_area()
	_status = UiKit.label("", 16, UiColours.TEXT_DIM, true)
	body.add_child(_status)
	add_button("Done", close)
	session.players_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	if not is_instance_valid(_list):
		return
	clear(_list)
	for player in session.players:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var swatch := ColorRect.new()
		swatch.color = Color(player.colour)
		swatch.custom_minimum_size = Vector2(18, 18)
		row.add_child(swatch)
		var where: String = {"keys": "keyboard and mouse", "pad": "controller", "remote": "LAN"}.get(player.device, "")
		if player.peer != session.my_peer:
			where = "over LAN"
		var text := "%s · %s%s%s" % [player.name, where, " · ADMIRAL" if session.is_admiral(player.id) else "", "" if player.here else " · away"]
		var label := UiKit.label(text, 18, UiColours.TEXT if player.here else UiColours.TEXT_DIM, true)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var can_hand_on: bool = session.admiral_is_local() or (session.is_host and not session.player_by_id(session.admiral).get("here", false))
		if not session.is_admiral(player.id) and player.here and can_hand_on:
			var id: int = player.id
			row.add_child(UiKit.button("MAKE ADMIRAL", func(): session.make_admiral(id), 170))
		if player.device == "pad" and player.peer == session.my_peer and player.here:
			var id: int = player.id
			row.add_child(UiKit.button("LEAVE", func(): session.remove_local_player(id), 100))
		_list.add_child(row)
	_list.add_child(UiKit.label("Controllers on this machine join by pressing Start, during a run.", 15, UiColours.TEXT_DIM, true))
	_list.add_child(_separator())
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
		var typed_name := _name.text if is_instance_valid(_name) else ""
		_address = LineEdit.new()
		_address.text = typed_address
		_name = LineEdit.new()
		_name.text = typed_name
		_address.placeholder_text = "Host's IP address"
		_address.custom_minimum_size = Vector2(240, 40)
		row.add_child(_address)
		_name.placeholder_text = "Your name"
		_name.custom_minimum_size = Vector2(200, 40)
		row.add_child(_name)
		row.add_child(UiKit.button("JOIN", func():
			if _address.text.strip_edges().is_empty():
				_status.text = "Type the host's IP address first."
				return
			var why := session.join_lan(_address.text, _name.text)
			_status.text = why if not why.is_empty() else "Connecting to %s..." % _address.text.strip_edges()
			if why.is_empty():
				main.wait_for_host(), 100))
		_list.add_child(row)
	else:
		_list.add_child(UiKit.label("You are in %s's game." % session.name_of(session.admiral), 17, UiColours.TEXT, true))
		_list.add_child(UiKit.button("LEAVE THE GAME", func():
			session.leave_lan()
			close()
			main.show_title(), 0))


func _separator() -> Control:
	var line := ColorRect.new()
	line.color = UiColours.BORDER_DIM
	line.custom_minimum_size = Vector2(0, 1)
	return line
