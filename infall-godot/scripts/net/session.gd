class_name Session
extends Node
## The game always runs as a server with its players as clients, also when one person plays alone (GV 4A, 4C).
## Every player action is an order. The host puts the orders and the clock's ticks into one stream, in one order,
## and every machine plays that same stream through the same simulation, so they all see the same run. A machine
## that joins later is sent where the run began and everything since, and catches up.
##
## Players are the host's keyboard and mouse, each controller on the host, and each machine that joined over LAN
## (and its own controllers). The host starts as the Admiral; squad decisions (event choices, jumps, pausing, hails)
## are the Admiral's (GDD 4H, 4M at their defaults, GV 4E); every player commands every ship for now (GV 4D).

signal players_changed
signal session_ended(reason: String)
signal note(text: String)

const PORT := 47121
const TICK_SECONDS := 0.05
const MAX_TICKS_A_FRAME := 4
const CHECK_EVERY := 100              # ticks between the host's checks that every machine still agrees
const COLOURS := ["#5fd4ff", "#ffb347", "#c58cff", "#ff6f91", "#9be564", "#ffe066", "#7af0c8", "#f08a5d"]
## Orders only the Admiral gives: the squad's decisions.
const ADMIRAL_ORDERS := ["shared", "pause", "jump", "wait", "hail_open", "rule", "hold"]

var is_host := true
var players: Array[Dictionary] = []   # {id, name, colour, device ("keys", "pad", "remote"), pad, peer, here}
var admiral: int = 1
var my_peer: int = 1                  # this machine's peer id; 1 is the host
var origin: Dictionary = {}           # where the run began: {kind: "new", seed, ship, rules} or {kind: "load", save, rules}
var stream: Array = []                # everything since the origin, for machines joining (ticks counted together)
var main: Node                        # plays the stream: apply_item(), can_tick(), checksum()
var busy := false                     # playing an item that waits (the jump's flash), so no ticks are sent meanwhile
var catching_up := false              # playing a long backlog: no animations or sounds
var remote_hold := false              # the Admiral, on another machine, has a window open
var tick_progress := 0.0              # 0 to 1 between ticks, for smooth drawing

var _queue: Array = []
var _tick_time := 0.0
var _ticks_since_check := 0
var _next_player_id := 1
var _outgoing: Array = []
var _peer: ENetMultiplayerPeer = null
var _join_name := ""


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(func(): _leave("Couldn't reach that address."))
	multiplayer.server_disconnected.connect(func(): _leave("The host left the game."))
	Settings.rule_changed = func(id: String, value: Variant): submit(first_local_id(), {"k": "rule", "id": id, "value": value})


# --- Players --------------------------------------------------------------------------------------------------

## Adds a player on this machine (the keyboard and mouse, or a controller) and returns their id.
func add_local_player(device: String, pad: int = -1) -> int:
	# A controller coming back gets its old place (GDD 4F)
	for player in players:
		if player.device == device and player.pad == pad and player.peer == my_peer:
			player.here = true
			_players_changed()
			return player.id
	var player := {"id": 0, "name": "", "colour": "", "device": device, "pad": pad, "peer": my_peer, "here": true}
	if is_host:
		_register(player)
	else:
		_ask_for_player.rpc_id(1, device, pad, _player_name(device, pad))
		return -1   # the host answers with the id
	return player.id


func remove_local_player(id: int) -> void:
	var player := player_by_id(id)
	if player.is_empty():
		return
	player.here = false
	if not is_host:
		_player_left.rpc_id(1, id)
	_players_changed()


func player_by_id(id: int) -> Dictionary:
	for player in players:
		if player.id == id:
			return player
	return {}


func local_players() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for player in players:
		if player.peer == my_peer and player.here:
			list.append(player)
	return list


func first_local_id() -> int:
	var list := local_players()
	return list[0].id if not list.is_empty() else 0


func is_admiral(id: int) -> bool:
	return id == admiral


func admiral_is_local() -> bool:
	return not player_by_id(admiral).is_empty() and player_by_id(admiral).peer == my_peer


func colour_of(id: int) -> Color:
	var player := player_by_id(id)
	return Color(player.colour) if not player.is_empty() else Color.WHITE


func name_of(id: int) -> String:
	var player := player_by_id(id)
	return player.name if not player.is_empty() else "Someone"


## A player's title (GV 4B): the host's squad leader is the Admiral, every other player a Commodore.
func title_of(id: int) -> String:
	return "Admiral" if id == admiral else "Commodore"


## "Admiral Name", as the game names a player.
func titled_name(id: int) -> String:
	return "%s %s" % [title_of(id), name_of(id)]


func here_count() -> int:
	return players.filter(func(p): return p.here).size()


## The Admiral's own windows hold the battle. On the host that is read when the clock ticks; another machine tells
## the host.
func local_hold_changed() -> void:
	if is_host or not admiral_is_local() or main == null:
		return
	var view = main.view_of(admiral)
	submit(admiral, {"k": "hold", "on": view != null and view.has_window()})


func make_admiral(id: int) -> void:
	if is_host:
		admiral = id
		_players_changed()
	else:
		_ask_admiral.rpc_id(1, id)


func _register(player: Dictionary) -> void:
	player.id = _next_player_id
	_next_player_id += 1
	player.colour = COLOURS[(player.id - 1) % COLOURS.size()]
	if player.name.is_empty():
		player.name = _player_name(player.device, player.pad)
	players.append(player)
	_players_changed()


func _player_name(device: String, pad: int) -> String:
	if device == "pad":
		return "Controller %d" % (pad + 1)
	if not _join_name.is_empty():
		return _join_name
	var name := OS.get_environment("USERNAME") if OS.has_environment("USERNAME") else OS.get_environment("USER")
	return name.capitalize() if not name.is_empty() else "Player"


func _players_changed() -> void:
	if is_host and _peer:
		_players_list.rpc(players, admiral)
	players_changed.emit()


# --- Orders and the stream ------------------------------------------------------------------------------------

## A player's order. The host puts it into the stream; another machine sends it to the host.
func submit(player_id: int, order: Dictionary) -> void:
	order["p"] = player_id
	if is_host:
		_sequence(order)
	elif multiplayer.multiplayer_peer:
		_order_from_client.rpc_id(1, order)


func _sequence(order: Dictionary) -> void:
	if String(order.k) in ADMIRAL_ORDERS and int(order.get("p", 0)) != admiral and not (order.k == "rule" and int(order.get("p", 0)) == first_local_id()):
		return
	_emit(order)


## Puts one item on the stream: for the record and for this machine to play. The host sends each item to the
## other machines as it plays it, so they get them in the order it played them.
func _emit(item: Dictionary) -> void:
	if item.k == "t" and not stream.is_empty() and stream.back().k == "t":
		stream.back().n = int(stream.back().n) + 1
	elif item.k != "check":
		stream.append(item.duplicate() if item.k != "t" else {"k": "t", "n": 1})
	_queue.append(item)


func _process(delta: float) -> void:
	if is_host and main and main.can_tick() and not busy and _queue.is_empty():
		_tick_time += delta
		var ticks := 0
		while _tick_time >= TICK_SECONDS and ticks < MAX_TICKS_A_FRAME:
			_tick_time -= TICK_SECONDS
			ticks += 1
			_emit({"k": "t"})
			_ticks_since_check += 1
			if _ticks_since_check >= CHECK_EVERY and _peer:
				_ticks_since_check = 0
				_emit({"k": "check"})
		if ticks >= MAX_TICKS_A_FRAME:
			_tick_time = 0.0
	elif is_host:
		_tick_time = 0.0
	if not busy and not _queue.is_empty():
		_play()
	_send_outgoing()
	tick_progress = clampf(_tick_time / TICK_SECONDS, 0.0, 1.0) if is_host else minf(1.0, tick_progress + delta / TICK_SECONDS)


func _send_outgoing() -> void:
	if not _outgoing.is_empty() and is_host and _peer:
		_items.rpc(_outgoing)
	_outgoing.clear()


## Plays the queue in order. An item may wait (the jump's flash); nothing after it is played until it finishes.
func _play() -> void:
	busy = true
	while not _queue.is_empty():
		catching_up = _queue.size() > 60
		var item: Dictionary = _queue.pop_front()
		match String(item.k):
			"t":
				for count in int(item.get("n", 1)):
					main.apply_tick()
				tick_progress = 0.0
				_pass_on({"k": "t", "n": int(item.get("n", 1))})
			"check":
				_pass_on({"k": "sum", "v": main.checksum()})
			"sum":
				if not is_host and int(item.v) != main.checksum():
					note.emit("This machine fell out of step with the host. Catching up again...")
					_rejoin()
					break
			_:
				_pass_on(item)
				await main.apply_order(item)
				_send_outgoing()
	catching_up = false
	busy = false


func _pass_on(item: Dictionary) -> void:
	if is_host and _peer:
		if item.k == "t" and not _outgoing.is_empty() and _outgoing.back().k == "t":
			_outgoing.back().n = int(_outgoing.back().n) + int(item.n)
		else:
			_outgoing.append(item)


# --- Starting and ending a run --------------------------------------------------------------------------------

## The host starts a run from an origin; every machine joined to it starts the same run.
func start_run(new_origin: Dictionary) -> void:
	origin = new_origin
	stream.clear()
	_queue.clear()
	_ticks_since_check = 0
	Settings.session_rules = origin.rules
	if is_host and _peer:
		_start_run.rpc(origin)
	main.begin_run(origin)


## The host ends the run (back to the title, or the run is over); machines joined to it wait for the next one.
func end_run() -> void:
	origin = {}
	stream.clear()
	_queue.clear()
	Settings.session_rules = {}
	if is_host and _peer:
		_end_run.rpc()


static func new_origin(ship_id: String, seed_number: int) -> Dictionary:
	return {"kind": "new", "seed": seed_number, "ship": ship_id, "rules": Settings.rules_snapshot()}


static func load_origin(save: Dictionary) -> Dictionary:
	return {"kind": "load", "save": save, "rules": Settings.rules_snapshot()}


# --- LAN ------------------------------------------------------------------------------------------------------

## Opens this machine to LAN players (direct IP, GDD 4A). Returns an error text, or "".
func host_lan() -> String:
	if _peer:
		return ""
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, 7)
	if error != OK:
		return "Couldn't open port %d for LAN players." % PORT
	_peer = peer
	multiplayer.multiplayer_peer = peer
	is_host = true
	my_peer = 1
	return ""


func is_open_to_lan() -> bool:
	return _peer != null


## Joins a host by its IP address. The run, if one is going, arrives once connected.
func join_lan(address: String, player_name: String) -> String:
	leave_lan()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), PORT)
	if error != OK:
		return "Couldn't start connecting to %s." % address
	_join_name = player_name.strip_edges()
	_peer = peer
	multiplayer.multiplayer_peer = peer
	is_host = false
	players.clear()
	RunState.saves_here = false
	return ""


func leave_lan() -> void:
	if _peer:
		_peer.close()
	_peer = null
	multiplayer.multiplayer_peer = null
	var was_client := not is_host
	is_host = true
	my_peer = 1
	RunState.saves_here = true
	if was_client:
		players.clear()
		Settings.session_rules = {}
		origin = {}
		_queue.clear()
		stream.clear()
		_next_player_id = 1
		admiral = 1
		_join_name = ""
		add_local_player("keys")


## This machine's addresses on the local network, for others to type in.
static func addresses() -> PackedStringArray:
	var found: PackedStringArray = []
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254"):
			found.append(address)
	return found


func _leave(reason: String) -> void:
	leave_lan()
	session_ended.emit(reason)


func _on_connected() -> void:
	my_peer = multiplayer.get_unique_id()
	_hello.rpc_id(1, _join_name)


func _on_peer_connected(_id: int) -> void:
	pass   # the joining machine says hello first


func _on_peer_disconnected(peer_id: int) -> void:
	if not is_host:
		return
	var admiral_left := false
	for player in players:
		if player.peer == peer_id and player.here:
			player.here = false
			admiral_left = admiral_left or player.id == admiral
	_players_changed()
	if admiral_left and main and main.has_method("admiral_gone"):
		main.admiral_gone()   # the game pauses and saves until the Admiral returns (GDD 4N, off)


func _rejoin() -> void:
	_queue.clear()
	_hello.rpc_id(1, _join_name)


@rpc("any_peer", "reliable")
func _hello(player_name: String) -> void:
	if not is_host:
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var player := {}
	for each in players:
		if each.peer == peer_id or (each.device == "keys" and each.name == player_name and not each.here and each.peer != 1):
			player = each
	if player.is_empty():
		player = {"id": 0, "name": player_name if not player_name.is_empty() else "Player", "colour": "", "device": "keys", "pad": -1, "peer": peer_id, "here": true}
		_register(player)
	else:
		player.peer = peer_id   # a player coming back gets their old place (GDD 4F)
		player.here = true
	_welcome.rpc_id(peer_id, players, admiral, origin, stream)
	_players_changed()
	note.emit("%s joined." % player.name)


@rpc("authority", "reliable")
func _welcome(list: Array, admiral_id: int, run_origin: Dictionary, so_far: Array) -> void:
	players.assign(list)
	admiral = admiral_id
	players_changed.emit()
	_queue.clear()
	origin = run_origin
	if origin.is_empty():
		main.wait_for_host()
		return
	Settings.session_rules = origin.rules
	main.begin_run(origin)
	_queue.append_array(so_far)


@rpc("authority", "reliable")
func _players_list(list: Array, admiral_id: int) -> void:
	players.assign(list)
	admiral = admiral_id
	players_changed.emit()


@rpc("authority", "reliable")
func _start_run(run_origin: Dictionary) -> void:
	origin = run_origin
	stream.clear()
	_queue.clear()
	Settings.session_rules = origin.rules
	main.begin_run(origin)


@rpc("authority", "reliable")
func _end_run() -> void:
	origin = {}
	_queue.clear()
	Settings.session_rules = {}
	main.wait_for_host()


@rpc("authority", "reliable")
func _items(items: Array) -> void:
	_queue.append_array(items)


@rpc("any_peer", "reliable")
func _order_from_client(order: Dictionary) -> void:
	if not is_host:
		return
	var sender := player_by_id(int(order.get("p", 0)))
	if sender.is_empty() or sender.peer != multiplayer.get_remote_sender_id():
		return   # a machine may only give its own players' orders
	if order.k == "hold":
		remote_hold = bool(order.get("on", false))
		return
	_sequence(order)


@rpc("any_peer", "reliable")
func _ask_for_player(device: String, pad: int, player_name: String) -> void:
	if not is_host:
		return
	var peer_id := multiplayer.get_remote_sender_id()
	for player in players:
		if player.peer == peer_id and player.device == device and player.pad == pad:
			player.here = true
			_players_changed()
			return
	_register({"id": 0, "name": player_name, "colour": "", "device": device, "pad": pad, "peer": peer_id, "here": true})


@rpc("any_peer", "reliable")
func _player_left(id: int) -> void:
	var player := player_by_id(id)
	if is_host and not player.is_empty() and player.peer == multiplayer.get_remote_sender_id():
		player.here = false
		_players_changed()


@rpc("any_peer", "reliable")
func _ask_admiral(id: int) -> void:
	var asker := multiplayer.get_remote_sender_id()
	if is_host and not player_by_id(admiral).is_empty() and player_by_id(admiral).peer == asker:
		admiral = id
		_players_changed()
