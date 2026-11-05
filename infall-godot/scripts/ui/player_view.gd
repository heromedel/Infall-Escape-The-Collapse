class_name PlayerView
extends Node
## One player's look at the battle (GV 4F): their camera, their cards, what they have selected and what they are
## aiming, and the windows they open for themselves (map, store, ship screen, menu). Players sharing a screen each
## get one, side by side; over LAN each machine has its own. The battle world is shared: this view only looks at it.
##
## Clicks and keys reach the view through its own viewport (InputRouter pushes them there, a controller's as
## well as the mouse's), and become orders for the stream (Session), never changes made here.

signal jump_pressed(view: PlayerView)
signal ship_screen_pressed(view: PlayerView)
signal hail_pressed(view: PlayerView)
signal store_pressed(view: PlayerView)
signal menu_pressed(view: PlayerView)
signal players_pressed(view: PlayerView)

var player_id: int = 1
var colour := Color.WHITE
var battle: BattleScreen
var session: Session
var uses_keys := true               # this player has the keyboard and mouse (the arrow keys pan their camera)

var viewport := SubViewport.new()
var display := TextureRect.new()    # where the view shows on the screen
var view_scale := 1.0               # screen pixels per view pixel
var camera := BattleCamera.new()
var background := SpaceBackground.new()
var hazard_layer := HazardAmbience.new()
var divider := SquadDivider.new()
var hud: BattleHud
var overlays := CanvasLayer.new()   # this player's own windows
var pointer := Vector2(960, 540)    # where this player's cursor is, in view pixels
var show_cursor := false            # a controller player's drawn cursor

var selected_ship: Ship
var ship_deselected := false        # the player stepped back past their ship: none is selected until they pick one
var selected_crew: Array[CrewMember] = []
var aim_mode: String = ""            # weapon, beam, teleport, suit
var aim_slot: WeaponSlot
var aim_ship: Ship                  # the ship whose weapon is being aimed
var autofire_default: bool = false
var hover_ship: Ship
var hover_room: int = -1
var hover_cell := Vector2i(999, 999)
var hover_crew: CrewMember
var hover_door: ShipDoor

var _marks := Node2D.new()
var _cursor := Node2D.new()
var _flash := ColorRect.new()
var _drag_start := Vector2.ZERO
var _box_selecting := false
var _beam_start_local := Vector2.ZERO
var _beam_target: Ship
var _shake := 0.0


func setup(owner: BattleScreen, id: int, player_colour: Color, keys: bool) -> void:
	battle = owner
	session = owner.session
	player_id = id
	colour = player_colour
	uses_keys = keys
	show_cursor = not keys


func _ready() -> void:
	viewport.world_2d = battle.world_host.world_2d
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = true
	viewport.size = Vector2i(1920, 1080)
	add_child(viewport)
	# Shown through a TextureRect, the viewport never hears the mouse come in by itself; without this its windows
	# would get clicks but not mouse moves (the map's hover)
	viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	display.texture = viewport.get_texture()
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	viewport.add_child(background)
	viewport.add_child(hazard_layer)
	var divider_layer := CanvasLayer.new()
	divider_layer.layer = -1
	divider_layer.follow_viewport_enabled = true
	viewport.add_child(divider_layer)
	divider_layer.add_child(divider)
	viewport.add_child(camera)
	camera.make_current()
	var marks_layer := CanvasLayer.new()
	marks_layer.layer = 1
	marks_layer.follow_viewport_enabled = true
	viewport.add_child(marks_layer)
	marks_layer.add_child(_marks)
	_marks.draw.connect(_draw_marks)
	hud = BattleHud.new()
	hud.screen = self
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	viewport.add_child(hud_layer)
	hud_layer.add_child(hud)
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 15
	viewport.add_child(flash_layer)
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash)
	overlays.layer = 20
	viewport.add_child(overlays)
	var cursor_layer := CanvasLayer.new()
	cursor_layer.layer = 40
	viewport.add_child(cursor_layer)
	cursor_layer.add_child(_cursor)
	_cursor.draw.connect(_draw_cursor)
	var input := _ViewInput.new()
	input.view = self
	viewport.add_child(input)
	if battle.encounter:
		encounter_changed()


## Places the view on the screen: `rect` in screen pixels. The view is drawn `logical_height` pixels tall, as wide
## as the rect's shape allows, and scaled to fit, so cards and windows keep their size and shape in a smaller view.
func place(rect: Rect2, logical_height: float) -> void:
	view_scale = rect.size.y / logical_height
	viewport.size = Vector2i(roundi(rect.size.x / view_scale), roundi(logical_height))
	display.position = rect.position
	display.size = rect.size


# --- What the HUD reads -----------------------------------------------------------------------------------

var encounter: Encounter:
	get: return battle.encounter if battle else null
var run: RunState:
	get: return battle.run if battle else null
var paused: bool:
	get: return battle.paused
var store_here: bool:
	get: return battle.store_here
var views: Dictionary:
	get: return battle.views
## Input is held while a shared window is open, or one of this player's own.
var hold_pause: bool:
	get: return battle.hold_pause or has_window()


func has_window() -> bool:
	return overlays.get_children().any(func(w): return not w.is_queued_for_deletion())


func is_admiral() -> bool:
	return session == null or session.is_admiral(player_id)


# --- A new encounter ----------------------------------------------------------------------------------------

## A new encounter (a jump, a fight, a refit): the old selection goes, and the camera frames it unless the cluster is
## the same and the player is looking somewhere.
func encounter_changed(reframe: bool = true) -> void:
	selected_crew = selected_crew.filter(func(m): return encounter.ships.has(m.home) and not m.dead)
	cancel_aim()
	divider.encounter = encounter
	divider.visible = encounter.fight_started
	_keep_a_ship_selected()
	background.set_cluster_look(battle.look_seed, battle.collapse_near, encounter.hazard)
	hazard_layer.set_hazard(encounter.hazard, battle.look_seed)
	if reframe:
		frame_everything(true)


func _process(delta: float) -> void:
	if encounter == null:
		return
	_keep_a_ship_selected()
	background.follow_camera(camera.position, camera.zoom.x)
	divider.zoom = camera.zoom.x
	divider.camera_x = camera.position.x
	divider.visible = encounter.fight_started and encounter.outcome == ""
	camera.keys_free = uses_keys and not hold_pause and not viewport.gui_get_focus_owner() is LineEdit
	if _shake > 0.1:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake / camera.zoom.x * 0.5
		_shake *= pow(0.02, delta)
	else:
		camera.offset = Vector2.ZERO
	_marks.queue_redraw()
	_cursor.queue_redraw()


## When the selected ship is destroyed or loses its crew, the next living ship of the squad is selected. A player who
## stepped back past their ship has none selected until they pick one (GV 14F).
func _keep_a_ship_selected() -> void:
	if selected_ship != null and (not encounter.ships.has(selected_ship) or selected_ship.is_gone()):
		selected_ship = null
		ship_deselected = false
	if selected_ship == null and not ship_deselected:
		selected_ship = encounter.living(0)[0] if not encounter.living(0).is_empty() else null


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func flash_white(seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(_flash, "color", Color(1, 1, 1, 0.9), seconds).set_delay(0.2)


func flash_clear() -> void:
	var tween := create_tween()
	tween.tween_property(_flash, "color", Color(1, 1, 1, 0.0), 0.7)


## Opens one of this player's own windows in their view.
func open_window(window: Control) -> void:
	overlays.add_child(window)
	window.tree_exited.connect(func(): if is_inside_tree(): window_count_changed())
	window_count_changed()


## The Admiral's own windows hold the battle, as one player's do alone (GDD 4H: only the Admiral pauses).
func window_count_changed() -> void:
	if session and is_admiral():
		session.local_hold_changed()


# --- The camera -----------------------------------------------------------------------------------------------

func view_size() -> Vector2:
	return Vector2(viewport.size)


func screen_to_world(point: Vector2) -> Vector2:
	return viewport.get_canvas_transform().affine_inverse() * point


func world_to_screen(point: Vector2) -> Vector2:
	return viewport.get_canvas_transform() * point


## Flies the camera to one ship, close enough to work its rooms; Home frames everything again.
func focus_ship(ship: Ship) -> void:
	var bounds := Formation.hull_bounds(ship.design)
	var size := view_size()
	var fit := minf((size.y - 104.0 - 150.0) / bounds.size.y, (size.x - 700.0) / bounds.size.x)
	camera.target_zoom = clampf(fit, BattleCamera.MIN_ZOOM, BattleCamera.MAX_ZOOM)
	camera.target_position = encounter.local_to_world(ship, bounds.get_center()) + Vector2(0, (150.0 - 104.0) * 0.5) / camera.target_zoom
	camera.user_moved = true


## Frames the whole encounter, or just the player's squad when there is no one to fight.
func frame_everything(instant: bool = false) -> void:
	var rect := Rect2()
	var first := true
	for ship in encounter.ships:
		if ship.side == 1 and not encounter.fight_started:
			continue
		if ship.escaped or (ship.destroyed and ship.explosion_ticks > 60):
			continue
		var bounds := Formation.hull_bounds(ship.design)
		var floor_rect := ship.design.floor_rect()
		var trimmed := Rect2(Vector2(floor_rect.position.x - 50.0, bounds.position.y), Vector2(floor_rect.size.x + 100.0, floor_rect.end.y + 30.0 - bounds.position.y))
		for corner in [trimmed.position, trimmed.end, Vector2(trimmed.position.x, trimmed.end.y), Vector2(trimmed.end.x, trimmed.position.y)]:
			var world_point := encounter.local_to_world(ship, corner)
			if first:
				rect = Rect2(world_point, Vector2.ZERO)
				first = false
			else:
				rect = rect.expand(world_point)
	camera.frame(rect.grow(20.0), view_size(), 104.0, 150.0)
	if instant:
		camera.zoom = Vector2.ONE * camera.target_zoom
		camera.position = camera.target_position


# --- Input ----------------------------------------------------------------------------------------------------

## Sits inside the view's viewport, so it gets the clicks and keys pushed into it after the cards and windows.
class _ViewInput extends Node:
	var view: PlayerView

	func _input(event: InputEvent) -> void:
		if event is InputEventMouse:
			view.pointer = event.position

	func _unhandled_input(event: InputEvent) -> void:
		view.handle_input(event)


func handle_input(event: InputEvent) -> void:
	if encounter == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		step_back(true)   # Esc works with a window open too: it is how the menu closes
		return
	if hold_pause:
		return
	if camera.handle_drag(event):
		return
	if event is InputEventMouseMotion:
		_update_hover()
		if _box_selecting:
			hud.box_rect = Rect2(_drag_start, event.position - _drag_start).abs()
	elif event is InputEventMouseButton:
		_mouse_button(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_key(event)


func _mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		camera.zoom_at(event.position, 1.12, view_size())
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		camera.zoom_at(event.position, 1.0 / 1.12, view_size())
		return
	_update_hover()
	var left_orders := _left_orders()
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if left_orders:
			step_back()   # Mouse Control's second choice: right click steps back (GV 14E)
		elif aim_mode != "":
			if aim_slot and aim_ship:
				_give({"k": "untarget", "s": _index(aim_ship), "w": aim_ship.weapons.find(aim_slot)})
			cancel_aim()
		elif not selected_crew.is_empty():
			_order_selected_to_hover()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if aim_mode != "":
			_click_while_aiming()
			return
		if event.double_click and selected_crew.is_empty():
			var ship := encounter.ship_under(screen_to_world(event.position))
			if ship:
				focus_ship(ship)
				return
		if hover_crew and hover_crew.side == 0:
			_select_crew([hover_crew], event.shift_pressed)
			return
		if hover_door and hover_ship and hover_ship.side == 0:
			toggle_door(hover_ship, hover_door)
			return
		if left_orders and not selected_crew.is_empty() and hover_room >= 0:
			_order_selected_to_hover()
			return
		_drag_start = event.position
		_box_selecting = true
		hud.box_rect = Rect2(event.position, Vector2.ZERO)
	else:
		if aim_mode == "beam" and _beam_target != null:
			_finish_beam()
			return
		if _box_selecting:
			_box_selecting = false
			var box: Rect2 = hud.box_rect
			hud.box_rect = Rect2()
			if box.size.length() > 8.0:
				_box_select(box)
			elif hover_ship and hover_ship.side == 0 and (hover_ship != selected_ship or left_orders):
				select_ship(hover_ship)
			elif not left_orders:
				step_back()   # a click on nothing (or on the selected ship's floor) steps back one level (GV 14F)


func _click_while_aiming() -> void:
	if hover_ship == null or hover_ship.side != 1 or hover_ship.is_gone():
		var suit := _suit_under_pointer()
		if aim_mode == "weapon" and suit:
			_give({"k": "aim_suit", "s": _index(aim_ship), "w": aim_ship.weapons.find(aim_slot), "suit": encounter.suits.find(suit), "auto": _aim_is_autofire()})
			Sfx.play("target")
			cancel_aim()
		return
	match aim_mode:
		"weapon":
			if hover_room < 0:
				return
			_give({"k": "aim", "s": _index(aim_ship), "w": aim_ship.weapons.find(aim_slot), "ts": _index(hover_ship), "cell": hover_cell, "auto": _aim_is_autofire()})
			Sfx.play("target")
			cancel_aim()
		"beam":
			if hover_room < 0:
				return
			_beam_target = hover_ship
			_beam_start_local = encounter.world_to_local(hover_ship, screen_to_world(pointer))
		"teleport":
			if hover_room >= 0:
				_give({"k": "board", "s": _index(selected_ship), "ts": _index(hover_ship), "room": hover_room})
				cancel_aim()
		"suit":
			_give({"k": "suit", "s": _index(selected_ship), "ts": _index(hover_ship)})
			cancel_aim()


func _finish_beam() -> void:
	var end_local := encounter.world_to_local(_beam_target, screen_to_world(pointer))
	var direction := end_local - _beam_start_local
	if direction.length() < 4.0:
		direction = Vector2.RIGHT
	var start_cell := Vector2i(floor((_beam_start_local - _beam_target.design.cell_offset) / ShipDesign.TILE))
	if _beam_target.room_at(start_cell) < 0:
		start_cell = _beam_target.rooms[0].cells[0]
	_give({"k": "aim_beam", "s": _index(aim_ship), "w": aim_ship.weapons.find(aim_slot), "ts": _index(_beam_target), "cell": start_cell,
			"a": _beam_start_local, "b": _beam_start_local + direction.normalized() * aim_slot.def.beam_length, "auto": _aim_is_autofire()})
	_beam_target = null
	Sfx.play("target")
	cancel_aim()


func _aim_is_autofire() -> bool:
	return autofire_default != (uses_keys and Input.is_key_pressed(KEY_CTRL))


func _key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_SPACE:
			toggle_pause()
		KEY_V:
			toggle_autofire()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			var index: int = event.keycode - KEY_1
			if selected_ship and index < selected_ship.weapons.size():
				arm_weapon(selected_ship.weapons[index])
		KEY_TAB:
			cycle_ship()
		KEY_HOME:
			frame_everything()
		KEY_F:
			if selected_ship:
				focus_ship(selected_ship)
		KEY_J:
			jump_pressed.emit(self)
		KEY_U:
			ship_screen_pressed.emit(self)
		KEY_T:
			start_teleport()
		KEY_E:
			start_suit_launch()
		KEY_C:
			if selected_ship:
				cloak(selected_ship)
		KEY_Z:
			return_to_stations()
		KEY_P:
			players_pressed.emit(self)


## Steps back one level at a time (GV 14F): a window closes (Esc), aiming stops, the crew are let go, then the
## ship, and Esc's last step opens the menu.
func step_back(esc: bool = false) -> void:
	var windows := overlays.get_children().filter(func(w): return not w.is_queued_for_deletion())
	if not windows.is_empty():
		if esc:
			var top: Control = windows.back()
			if top.has_method("close"):
				top.close()
		return
	if battle.hold_pause:
		return
	if aim_mode != "":
		cancel_aim()
	elif not selected_crew.is_empty():
		selected_crew.clear()
	elif selected_ship != null:
		selected_ship = null
		ship_deselected = true
	elif esc:
		menu_pressed.emit(self)


## Mouse Control (GV 14E): the genre's way by default; the second choice gives orders with the left button.
func _left_orders() -> bool:
	return Settings.get_value("mouse_control", "Left Selects, Right Orders") != "Left Selects, Right Orders"


func _update_hover() -> void:
	var world_point := screen_to_world(pointer)
	hover_ship = null
	hover_room = -1
	hover_cell = Vector2i(999, 999)
	hover_crew = null
	hover_door = null
	for ship in encounter.ships:
		if ship.is_gone():
			continue
		var local := encounter.world_to_local(ship, world_point)
		for member in ship.crew + ship.visitors:
			if member.ship == ship and member.is_active() and member.position.distance_to(local) <= ShipView.TOKEN_RADIUS + 2.0:
				if member.side == 0 or views[ship].interior_visible:
					hover_crew = member
		var cell := Vector2i(floor((local - ship.design.cell_offset) / ShipDesign.TILE))
		var room := ship.room_at(cell)
		for door in ship.doors:
			var middle := ship.design.cell_centre(door.cell_a) + Vector2(door.direction) * ShipDesign.TILE * 0.5
			if middle.distance_to(local) < 8.0:
				hover_door = door
				hover_ship = ship
		if room >= 0:
			hover_ship = ship
			hover_room = room
			hover_cell = cell
			return


## Whether a controller's A here gives an order (crew are selected and it points at a room, not at a card) rather than
## selecting or pressing.
func would_order_here() -> bool:
	if has_window() or selected_crew.is_empty() or aim_mode != "":
		return false
	if not hud._region_at(hud.get_local_mouse_position()).is_empty():
		return false
	_update_hover()
	return hover_room >= 0 and hover_crew == null


func _suit_under_pointer() -> Battlesuit:
	var world_point := screen_to_world(pointer)
	for suit in encounter.suits:
		if not suit.gone and suit.side == 1 and suit.position.distance_to(world_point) < 24.0:
			return suit
	return null


# --- Orders: what the clicks become ---------------------------------------------------------------------------

func _index(ship: Ship) -> int:
	return BattleOrders.ship_index(encounter, ship)


func _give(order: Dictionary) -> void:
	session.submit(player_id, order)


func toggle_pause() -> void:
	if not is_admiral():
		hud.flash_message("Only the Admiral pauses (%s)." % session.titled_name(session.admiral))
		return
	_give({"k": "pause", "on": not battle.paused})


func toggle_autofire() -> void:
	autofire_default = not autofire_default
	_give({"k": "autofire", "on": autofire_default})


func arm_weapon(slot: WeaponSlot) -> void:
	if slot.def.type == "suit" or selected_ship == null:
		return
	if not slot.powered:
		if not selected_ship.can_power_weapon(slot):
			if selected_ship.reactor_type == "pool" and selected_ship.reactor_free() < slot.def.power:
				hud.flash_message("Not enough reactor power.")
			else:
				hud.flash_message("The Weapons system can't hold more power.")
			Sfx.play("deny")
			return
		_give({"k": "wpower", "s": _index(selected_ship), "w": selected_ship.weapons.find(slot), "on": true})
		Sfx.play("power_up")
	aim_slot = slot
	aim_ship = selected_ship
	aim_mode = "beam" if slot.def.type == "beam" else "weapon"
	Sfx.play("arm")


func weapon_power(ship: Ship, slot: WeaponSlot) -> void:
	if not slot.powered and not ship.can_power_weapon(slot):
		Sfx.play("deny")
		hud.flash_message("Not enough weapon power.")
		return
	_give({"k": "wpower", "s": _index(ship), "w": ship.weapons.find(slot), "on": not slot.powered})
	Sfx.play("power_down" if slot.powered else "power_up")


func system_power(ship: Ship, system: ShipSystem, up: bool) -> void:
	if up and not (ship.reactor_type == "core" and system.enabled) and not ship.can_add_power(system):
		Sfx.play("deny")
		if ship.reactor_type == "core":
			hud.flash_message("The AZC is running all the systems it can. Switch another off first.")
		elif system.power >= system.usable_bars():
			hud.flash_message("%s can't hold more power." % system.def.name)
		else:
			hud.flash_message("No free reactor power.")
		return
	_give({"k": "power", "s": _index(ship), "sys": ship.systems.find(system), "up": up})
	Sfx.play("power_up" if up and not (ship.reactor_type == "core" and system.enabled) else "power_down")


func cancel_aim() -> void:
	aim_mode = ""
	aim_slot = null
	aim_ship = null
	_beam_target = null


func start_teleport() -> void:
	if selected_ship and encounter.can_teleport(selected_ship) and encounter.in_fight():
		aim_mode = "teleport"
	else:
		hud.flash_message("The teleporter isn't ready.")


func recall_boarders() -> void:
	if selected_ship:
		_give({"k": "recall", "s": _index(selected_ship)})


func start_suit_launch() -> void:
	if selected_ship and selected_ship.system_by("evb_dock") and encounter.in_fight():
		aim_mode = "suit"


func cloak(ship: Ship) -> void:
	_give({"k": "cloak", "s": _index(ship)})


func cycle_ship() -> void:
	var ships := encounter.living(0)
	if ships.is_empty():
		return
	var index := ships.find(selected_ship)
	select_ship(ships[(index + 1) % ships.size()])


func select_ship(ship: Ship) -> void:
	selected_ship = ship
	ship_deselected = false
	_select_crew([], false)


func _select_crew(members: Array, add: bool) -> void:
	if not add:
		selected_crew.clear()
	for member in members:
		if not selected_crew.has(member):
			selected_crew.append(member)
			if member.home.side == 0:
				selected_ship = member.home
				ship_deselected = false
	if not members.is_empty():
		Sfx.play("select")


func select_crew_member(member: CrewMember, add: bool) -> void:
	_select_crew([member], add)


func _box_select(box: Rect2) -> void:
	var picked: Array = []
	for ship in encounter.ships:
		for member in ship.crew:
			if member.side != 0 or not member.is_active():
				continue
			if box.has_point(world_to_screen(encounter.local_to_world(member.ship, member.position))):
				picked.append(member)
	_select_crew(picked, uses_keys and Input.is_key_pressed(KEY_SHIFT))


func _order_selected_to_hover() -> void:
	if hover_ship == null or hover_room < 0:
		return
	var refs: Array = []
	for member in selected_crew:
		if member.ship == hover_ship and member.is_active():
			refs.append(BattleOrders.crew_ref(encounter, member))
	if refs.is_empty():
		return
	_give({"k": "move", "crew": refs, "ts": _index(hover_ship), "cell": hover_cell})
	Sfx.play("order")


func toggle_door(ship: Ship, door: ShipDoor) -> void:
	if not ship.doors_controllable():
		hud.flash_message("The Doors system isn't working.")
		Sfx.play("deny")
		return
	_give({"k": "door", "s": _index(ship), "d": ship.doors.find(door)})
	Sfx.play("door")


func set_all_doors(ship: Ship, open: bool, airlocks: bool) -> void:
	if not ship.doors_controllable():
		hud.flash_message("The Doors system isn't working.")
		return
	_give({"k": "doors", "s": _index(ship), "open": open, "airlocks": airlocks})
	Sfx.play("door")


func return_to_stations() -> void:
	if selected_ship:
		_give({"k": "stations", "s": _index(selected_ship)})


func save_stations() -> void:
	if selected_ship:
		_give({"k": "save_posts", "s": _index(selected_ship)})
		hud.flash_message("Stations saved.")


# --- Drawing what only this player sees -----------------------------------------------------------------------

## The tile and room under this player's cursor while they aim or move crew, and the beam they are dragging.
func _draw_marks() -> void:
	if encounter == null or hover_ship == null or hover_room < 0 or not views.has(hover_ship):
		return
	var canvas := _marks
	var view: ShipView = views[hover_ship]
	canvas.draw_set_transform_matrix(view.get_global_transform())
	var design := hover_ship.design
	var room := hover_ship.rooms[hover_room]
	var room_rect := Rect2(design.cell_top_left(room.rect.position), Vector2(room.rect.size) * ShipDesign.TILE)
	var tile_rect := Rect2(design.cell_top_left(hover_cell), Vector2.ONE * ShipDesign.TILE).grow(-2.5)
	var mark := Color.TRANSPARENT
	if aim_mode in ["weapon", "beam"] and hover_ship.side == 1:
		mark = UiColours.TARGET_YELLOW if not _aim_is_autofire() else UiColours.ENEMY_RED
		canvas.draw_rect(room_rect.grow(-1.5), Color(mark, 0.35), false, 3.0)
	elif aim_mode != "" and hover_ship.side == 1:
		canvas.draw_rect(room_rect.grow(-1.5), UiColours.TARGET_YELLOW, false, 3.0)
	elif not selected_crew.is_empty() and selected_crew[0].ship == hover_ship:
		mark = colour if battle.player_views.size() > 1 else UiColours.POWER_GREEN
		canvas.draw_rect(room_rect.grow(-1.5), Color(mark, 0.4), false, 3.0)
	if mark.a > 0.0:
		canvas.draw_rect(tile_rect, Color(mark, 0.18))
		canvas.draw_rect(tile_rect, mark, false, 2.5)
	if aim_mode == "beam" and _beam_target != null and views.has(_beam_target):
		canvas.draw_set_transform_matrix(views[_beam_target].get_global_transform())
		var pointer_local := encounter.world_to_local(_beam_target, screen_to_world(pointer))
		var direction := pointer_local - _beam_start_local
		if direction.length() > 1.0:
			var end := _beam_start_local + direction.normalized() * aim_slot.def.beam_length
			canvas.draw_line(_beam_start_local, end, Color(UiColours.TARGET_YELLOW, 0.85), 3.0, true)
			canvas.draw_circle(_beam_start_local, 5.0, UiColours.TARGET_YELLOW)


## A controller player's cursor: an arrow in their colour.
func _draw_cursor() -> void:
	if not show_cursor:
		return
	var at := pointer
	var arrow := PackedVector2Array([at, at + Vector2(0, 26), at + Vector2(7, 19), at + Vector2(13, 31), at + Vector2(18, 28), at + Vector2(12, 17), at + Vector2(21, 17)])
	_cursor.draw_colored_polygon(arrow, colour)
	var outline := arrow.duplicate()
	outline.append(at)
	_cursor.draw_polyline(outline, Color(0.05, 0.05, 0.1), 2.0, true)
