class_name ShipView
extends Node2D
## Draws one ship in the battle world: hull art (or a drawn hull when the ship has none, GDD 5K), weapons
## sliding out from their mounts, the floor with rooms, doors, consoles, conduits, air, fire and breaches, the
## crew as portrait tokens, and the shield bubble. It only reads the Ship; the battle screen owns input.

const TOKEN_RADIUS := 12.5

var ship: Ship
var encounter: Encounter
var alpha: float = 0.0             # how far between the last tick and the next, for smooth movement
var selected: bool = false         # the player's selected ship: conduits glow
var interior_visible: bool = true  # sensors decide whether the player sees inside enemy ships
var hover_room: int = -1
var highlight_rooms: Dictionary = {}   # room -> Color (aiming, moving crew)
var highlight_tiles: Dictionary = {}   # tile -> Color (the tile a shot or an order would go to)
var target_marks: Array = []       # {cell, label, colour}
var beam_marks: Array = []         # {start, end, colour} in local pixels
var power_colour := UiColours.POWER_GREEN
var time: float = 0.0

var _weapons_layer := Node2D.new()
var _hull_layer: Node2D
var _floor_layer := Node2D.new()
var _crew_layer := Node2D.new()
var _shield_layer := Node2D.new()
var _shield_rect := ColorRect.new()
var _shield_material: ShaderMaterial
var _super_rect := ColorRect.new()
var _super_material: ShaderMaterial
var _hits: Array = []              # shield bubble hits: {position (local), age}
var _super_hits: Array = []        # Supershield hits


func setup(view_ship: Ship, owner: Encounter) -> void:
	ship = view_ship
	encounter = owner
	power_colour = UiColours.POWER_GREEN if ship.side == 0 else UiColours.enemy_power(ship.faction, ship.race)
	add_child(_weapons_layer)
	_weapons_layer.draw.connect(_draw_weapons)
	var texture := Library.texture(ship.design.art_path)
	if texture:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2.ONE * ship.design.art_scale
		sprite.position = -ship.design.art_centre
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if ship.design.art_nearest:
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		_hull_layer = sprite
	else:
		var painter := HullPainter.new()
		painter.design = ship.design
		_hull_layer = painter
	add_child(_hull_layer)
	add_child(_floor_layer)
	_floor_layer.draw.connect(_draw_floor)
	add_child(_crew_layer)
	_crew_layer.draw.connect(_draw_crew)
	add_child(_shield_layer)
	_setup_bubbles()


func _setup_bubbles() -> void:
	var centre := encounter.bubble_centre(ship)
	var radii := encounter.bubble_radii(ship)
	var shader := load("res://shaders/shield.gdshader") as Shader
	_shield_material = ShaderMaterial.new()
	_shield_material.shader = shader
	_shield_material.set_shader_parameter("tint", UiColours.SHIELD_BLUE)
	_shield_rect.material = _shield_material
	_shield_rect.position = centre - radii * 1.08
	_shield_rect.size = radii * 2.16
	_shield_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield_layer.add_child(_shield_rect)
	_super_material = ShaderMaterial.new()
	_super_material.shader = shader
	_super_material.set_shader_parameter("tint", UiColours.SUPERSHIELD)
	_super_rect.material = _super_material
	_super_rect.position = centre - radii * 1.2
	_super_rect.size = radii * 2.4
	_super_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield_layer.add_child(_super_rect)


## Called by the battle screen when a shot hits this ship's shields, at a world point.
func shield_hit(world_point: Vector2, supershield: bool = false) -> void:
	var list := _super_hits if supershield else _hits
	list.append({"position": encounter.world_to_local(ship, world_point), "age": 0.0})
	if list.size() > 4:
		list.pop_front()


func _process(delta: float) -> void:
	time += delta
	position = ship.world_position
	rotation = PI if ship.facing_down else 0.0
	for hit in _hits + _super_hits:
		hit.age += delta
	_hits = _hits.filter(func(hit): return hit.age < 1.2)
	_super_hits = _super_hits.filter(func(hit): return hit.age < 1.2)
	_update_bubble(_shield_material, _shield_rect, ship.shield_layers, _hits)
	_update_bubble(_super_material, _super_rect, ship.supershield, _super_hits)
	var fade := 1.0
	if ship.destroyed:
		fade = clampf(1.0 - ship.explosion_ticks / 50.0, 0.0, 1.0)
	elif ship.escaped:
		fade = 0.0
	modulate.a = fade
	if ship.is_cloaked():
		modulate.a = 0.45
	visible = fade > 0.0
	_weapons_layer.queue_redraw()
	_floor_layer.queue_redraw()
	_crew_layer.queue_redraw()
	if ship.hit_flash > 0:
		_hull_layer.modulate = Color(1.6, 1.4, 1.3)
	else:
		_hull_layer.modulate = Color.WHITE


func _update_bubble(material: ShaderMaterial, rect: ColorRect, layers: int, hits: Array) -> void:
	rect.visible = layers > 0 or not hits.is_empty()
	material.set_shader_parameter("strength", clampf(0.35 + 0.22 * layers, 0.0, 1.0) if layers > 0 else 0.0)
	material.set_shader_parameter("time", time)
	var hit_points := PackedVector2Array()
	var hit_ages := PackedFloat32Array()
	for index in 4:
		if index < hits.size():
			var local: Vector2 = hits[index].position
			hit_points.append((local - rect.position) / rect.size)
			hit_ages.append(hits[index].age)
		else:
			hit_points.append(Vector2(-10, -10))
			hit_ages.append(9.0)
	material.set_shader_parameter("hit_points", hit_points)
	material.set_shader_parameter("hit_ages", hit_ages)


# --- Weapons -------------------------------------------------------------------------------------------------

func _draw_weapons() -> void:
	for slot in ship.weapons:
		var mount := ship.design.mount_by_id(slot.mount_id)
		if mount.is_empty():
			continue
		var at: Vector2 = mount.position + mount.slide * (slot.slide * 12.0 - 2.0)
		WeaponArt.draw(_weapons_layer, slot.def, at, ship.design.style, slot.charge / maxf(1.0, slot.charge_needed(ship.tech)), slot.fired_flash > 0, slot.powered)


# --- Floor ---------------------------------------------------------------------------------------------------

func _draw_floor() -> void:
	var canvas := _floor_layer
	var design := ship.design
	var tile := ShipDesign.TILE
	var seen := interior_visible
	for room in ship.rooms:
		var rect := Rect2(design.cell_top_left(room.rect.position), Vector2(room.rect.size) * tile)
		var floor_colour := UiColours.FLOOR if ship.side == 0 else UiColours.ENEMY_FLOOR
		if not seen:
			floor_colour = UiColours.UNSEEN_FLOOR
		canvas.draw_rect(rect, floor_colour)
		# tile seams
		for x in range(1, room.rect.size.x):
			canvas.draw_line(rect.position + Vector2(x * tile, 2), rect.position + Vector2(x * tile, rect.size.y - 2), UiColours.FLOOR_LINE if seen else floor_colour.lightened(0.06), 1.0)
		for y in range(1, room.rect.size.y):
			canvas.draw_line(rect.position + Vector2(2, y * tile), rect.position + Vector2(rect.size.x - 2, y * tile), UiColours.FLOOR_LINE if seen else floor_colour.lightened(0.06), 1.0)
		if seen:
			for cell in room.scorch:
				if not room.fires.has(cell):
					_draw_scorch(canvas, design.cell_centre(cell), cell)
		if seen and room.oxygen < 0.95:
			canvas.draw_rect(rect, Color(UiColours.LOW_AIR, (1.0 - room.oxygen) * 0.5))
		if seen and room.infection > 0.0:
			_draw_infection(canvas, room, rect)
		if seen and _medbay_working(room):
			canvas.draw_rect(rect, Color(0.35, 1.0, 0.5, 0.13 + 0.07 * sin(time * 2.2)))
	_draw_conduits(canvas)
	for room in ship.rooms:
		var rect := Rect2(design.cell_top_left(room.rect.position), Vector2(room.rect.size) * tile)
		canvas.draw_rect(rect.grow(1.0), UiColours.WALL, false, 3.5)
	_draw_doors(canvas)
	for system in ship.systems:
		_draw_console(canvas, system)
	if seen:
		for room in ship.rooms:
			for cell in room.breaches:
				_draw_breach(canvas, design.cell_centre(cell), cell)
			for cell in room.fires:
				_draw_fire(canvas, design.cell_centre(cell), room.fires[cell], cell)
	for room_index in highlight_rooms:
		if room_index >= 0 and room_index < ship.rooms.size():
			var room := ship.rooms[room_index]
			var rect := Rect2(design.cell_top_left(room.rect.position), Vector2(room.rect.size) * tile)
			canvas.draw_rect(rect.grow(-1.5), highlight_rooms[room_index], false, 3.0)
	for cell in highlight_tiles:
		var tile_rect := Rect2(design.cell_top_left(cell), Vector2(tile, tile)).grow(-2.5)
		canvas.draw_rect(tile_rect, Color(highlight_tiles[cell], 0.18))
		canvas.draw_rect(tile_rect, highlight_tiles[cell], false, 2.5)
	_draw_destinations(canvas)
	for mark in target_marks:
		_draw_target_mark(canvas, mark)
	for mark in beam_marks:
		canvas.draw_line(mark.start, mark.end, Color(mark.colour, 0.85), 3.0, true)
		canvas.draw_circle(mark.start, 5.0, mark.colour)


func _medbay_working(room: ShipRoom) -> bool:
	for system in room.systems:
		if system.behaviour == "medbay" and ship.system_power(system) > 0:
			return true
	return false


func _draw_infection(canvas: CanvasItem, room: ShipRoom, rect: Rect2) -> void:
	var amount := room.infection / 100.0
	var seed := room.index * 13
	for index in int(3 + amount * 6):
		var spot := rect.position + Vector2(fmod(seed * 37.0 + index * 53.0, rect.size.x), fmod(seed * 17.0 + index * 29.0, rect.size.y))
		canvas.draw_circle(spot, 4.0 + amount * 7.0 + sin(time * 2.0 + index) * 1.2, Color(0.85, 0.35, 0.45, 0.45 * amount + 0.15))


func _draw_conduits(canvas: CanvasItem) -> void:
	if ship.reactor_type != "core" or ship.conduits.is_empty():
		return
	var design := ship.design
	var steps := {1: Vector2i(0, -1), 2: Vector2i(1, 0), 4: Vector2i(0, 1), 8: Vector2i(-1, 0)}
	var flash := 0.5 + 0.5 * sin(time * 9.0)
	for cell in ship.conduits:
		var mask: int = ship.conduits[cell]
		var from := design.cell_centre(cell)
		var broken := ship.broken_conduits.has(cell)
		var powered := ship.powered_conduits.has(cell)
		var colour: Color
		var width := 2.0
		if broken:
			colour = Color(UiColours.DAMAGED_RED, 0.5 + 0.5 * flash)
			width = 3.0
		elif selected and interior_visible:
			colour = Color(power_colour, 0.75) if powered else Color(0.5, 0.55, 0.62, 0.7)
		else:
			colour = Color(0.45, 0.5, 0.58, 0.32) if interior_visible else Color(0.3, 0.34, 0.4, 0.3)
		for bit in steps:
			if mask & bit:
				var to := from + Vector2(steps[bit]) * ShipDesign.TILE * 0.5
				canvas.draw_line(from, to, colour, width, true)
		if broken:
			canvas.draw_circle(from, 4.0 + flash * 3.0, Color(UiColours.DAMAGED_RED, 0.6))


func _draw_doors(canvas: CanvasItem) -> void:
	var design := ship.design
	for door in ship.doors:
		var a := design.cell_centre(door.cell_a)
		var middle := a + Vector2(door.direction) * ShipDesign.TILE * 0.5
		var along := Vector2(door.direction).orthogonal()
		var half := 9.0
		var colour := UiColours.AIRLOCK if door.to_space else UiColours.DOOR
		if not interior_visible:
			colour = colour.darkened(0.45)
		var thick := 6.0
		if door.is_open():
			var gap := 7.0
			canvas.draw_line(middle - along * half, middle - along * gap, colour.darkened(0.3), thick)
			canvas.draw_line(middle + along * gap, middle + along * half, colour.darkened(0.3), thick)
			canvas.draw_line(middle - along * gap, middle + along * gap, UiColours.FLOOR.darkened(0.15) if interior_visible else UiColours.UNSEEN_FLOOR, thick - 2.0)
		else:
			canvas.draw_line(middle - along * half, middle + along * half, colour, thick)
			canvas.draw_line(middle - along * half * 0.9, middle + along * half * 0.9, colour.darkened(0.45), 1.5)
			if door.health < ship.door_max_health() * 0.99 and door.health > 0.0:
				canvas.draw_line(middle - along * half, middle + along * half, Color(UiColours.DAMAGED_RED, 0.8), 2.0)


## A system's console: a desk against its wall with the symbol lit in the ship's power colour, red when damaged.
func _draw_console(canvas: CanvasItem, system: ShipSystem) -> void:
	var design := ship.design
	var centre := design.cell_centre(system.cell)
	var tile := ShipDesign.TILE
	var colour := _system_colour(system)
	if system.behaviour == "power_core":
		var glow := 0.6 + 0.4 * sin(time * 2.4)
		canvas.draw_circle(centre, 13.0, Color("#262c38"))
		canvas.draw_circle(centre, 10.0, Color("#3a4252"))
		canvas.draw_arc(centre, 8.0, 0, TAU, 24, Color(colour, glow), 2.5, true)
		canvas.draw_circle(centre, 4.5, Color(colour, 0.6 + 0.4 * glow))
		return
	var wall_dir: Vector2 = {"north": Vector2.UP, "south": Vector2.DOWN, "east": Vector2.RIGHT, "west": Vector2.LEFT}.get(system.wall, Vector2.ZERO)
	var icon_at := centre
	if wall_dir != Vector2.ZERO:
		var desk_centre := centre + wall_dir * (tile * 0.5 - 6.0)
		var desk_size := Vector2(tile * 0.78, 9.0) if wall_dir.y != 0 else Vector2(9.0, tile * 0.78)
		var desk := Rect2(desk_centre - desk_size * 0.5, desk_size)
		canvas.draw_rect(desk, Color("#e4e8ee") if interior_visible else Color("#4a5262"))
		canvas.draw_rect(desk, Color("#59616f"), false, 1.0)
		var screen_size := desk_size - Vector2(6, 4) if wall_dir.y != 0 else desk_size - Vector2(4, 6)
		canvas.draw_rect(Rect2(desk_centre - screen_size * 0.5, screen_size), Color("#1d2635"))
		icon_at = centre + wall_dir * 2.0
	var icon_size := 17.0
	_draw_upright(canvas, icon_at, func(at: Vector2):
		canvas.draw_circle(at, icon_size * 0.62, Color(0.06, 0.08, 0.12, 0.55))
		SystemIcons.draw(canvas, system.def.icon, at, icon_size, colour))
	if system.manned_by and interior_visible:
		canvas.draw_arc(icon_at, icon_size * 0.72, 0, TAU, 20, Color(colour, 0.5), 1.2, true)


func _system_colour(system: ShipSystem) -> Color:
	if system.is_broken() or system.spored:
		return UiColours.DAMAGED_RED
	if system.ion > 0:
		return UiColours.ION_BLUE
	if system.damage > 0:
		return Color("#ff9a3d")
	if ship.system_power(system) > 0 or system.behaviour == "power_core":
		return power_colour
	return Color("#8b93a3")


## Draws something that stays upright on enemy ships, which fly turned around.
func _draw_upright(canvas: CanvasItem, at: Vector2, painter: Callable) -> void:
	if ship.facing_down:
		canvas.draw_set_transform(at, PI, Vector2.ONE)
		painter.call(Vector2.ZERO)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		painter.call(at)


func _draw_fire(canvas: CanvasItem, centre: Vector2, strength: float, cell: Vector2i) -> void:
	var size := 0.85 + strength / 220.0
	var seed := float(cell.x * 7 + cell.y * 13)
	var up := Vector2.DOWN if ship.facing_down else Vector2.UP   # flames rise toward the top of the screen
	var across := Vector2(-up.y, up.x)
	var flicker := 0.85 + 0.15 * sin(time * 17.0 + seed) * sin(time * 11.0 + seed * 0.3)
	# glow on the floor and walls around the tile
	for ring in 3:
		canvas.draw_circle(centre, (26.0 - ring * 7.0) * size, Color(1.0, 0.45, 0.1, (0.07 + ring * 0.05) * flicker))
	var base := centre - up * 12.0
	canvas.draw_circle(base + up * 2.0, 9.0 * size, Color(1.0, 0.5, 0.1, 0.45 * flicker))
	# outer tongues: deep orange to red, fading at the tips
	for index in 6:
		var x := (index - 2.5) * 3.4 * size + sin(seed + index * 3.1) * 1.5
		var phase := time * (6.0 + index * 0.9) + seed + index * 2.3
		var height := (22.0 + 7.0 * sin(phase) + 4.0 * sin(phase * 2.7)) * size * flicker
		var width := (6.8 - absf(index - 2.5) * 0.6) * size
		_draw_flame(canvas, base + across * x, up, across, height, width, sin(phase * 1.4) * 4.0 * size,
			Color(1.0, 0.55, 0.08, 1.0), Color(0.9, 0.12, 0.03, 0.0))
	# inner core: yellow-white, shorter
	for index in 3:
		var phase := time * (8.0 + index) + seed * 1.3 + index
		var height := (13.0 + 4.0 * sin(phase)) * size * flicker
		_draw_flame(canvas, base + across * (index - 1) * 4.0 * size, up, across, height, 4.2 * size,
			sin(phase * 1.7) * 2.5 * size, Color(1.0, 0.97, 0.75, 0.95), Color(1.0, 0.7, 0.15, 0.0))
	# embers rising and fading
	for index in 5:
		var t := fposmod(time * (0.55 + index * 0.08) + seed * 0.37 + index * 0.21, 1.0)
		var drift := across * (sin(seed + index * 5.3 + time * 2.0) * 7.0 * size)
		var at := base + drift + up * (6.0 + t * 30.0 * size)
		canvas.draw_circle(at, 1.3 * (1.0 - t * 0.5), Color(1.0, 0.75 - t * 0.4, 0.25, 1.0 - t))
	# smoke above the flames
	for index in 3:
		var t := fposmod(time * 0.35 + index / 3.0 + seed * 0.11, 1.0)
		var at := base + across * (sin(seed + index * 1.9 + t * 3.0) * 6.0) + up * (20.0 + t * 26.0) * size
		canvas.draw_circle(at, (4.0 + t * 7.0) * size, Color(0.16, 0.15, 0.15, 0.2 * (1.0 - t) * minf(1.0, t * 4.0)))


## One flame tongue as a strip of quads, coloured from its base to its fading tip and bending as it rises.
func _draw_flame(canvas: CanvasItem, base: Vector2, up: Vector2, across: Vector2, height: float, width: float, sway: float, root: Color, tip: Color) -> void:
	const STEPS := 6
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var colours: Array[Color] = []
	for step in STEPS + 1:
		var s := step / float(STEPS)
		var half := width * pow(1.0 - s, 0.8) * (0.75 + 0.5 * sin(PI * minf(1.0, s * 1.6 + 0.2)))
		var mid := base + up * height * s + across * sway * s * s
		left.append(mid - across * half)
		right.append(mid + across * half)
		colours.append(root.lerp(tip, pow(s, 1.3)))
	for step in STEPS:
		var quad := PackedVector2Array([left[step], right[step], right[step + 1], left[step + 1]])
		if quad[2].distance_squared_to(quad[3]) < 0.01:
			quad = PackedVector2Array([left[step], right[step], right[step + 1]])
			canvas.draw_polygon(quad, PackedColorArray([colours[step], colours[step], colours[step + 1]]))
		else:
			canvas.draw_polygon(quad, PackedColorArray([colours[step], colours[step], colours[step + 1], colours[step + 1]]))


func _draw_scorch(canvas: CanvasItem, centre: Vector2, cell: Vector2i) -> void:
	var seed := float(cell.x * 19 + cell.y * 23)
	var points := PackedVector2Array()
	for index in 10:
		var radius := 11.0 + 3.0 * sin(seed + index * 2.7)
		points.append(centre + Vector2.from_angle(index * TAU / 10.0) * radius)
	canvas.draw_colored_polygon(points, Color(0.2, 0.12, 0.06, 0.22))
	var inner := PackedVector2Array()
	for point in points:
		inner.append(centre + (point - centre) * 0.6)
	canvas.draw_colored_polygon(inner, Color(0.08, 0.05, 0.03, 0.35))


func _draw_breach(canvas: CanvasItem, centre: Vector2, cell: Vector2i) -> void:
	var seed := float(cell.x * 31 + cell.y * 17)
	var points := PackedVector2Array()
	for index in 9:
		var angle := index * TAU / 9.0
		var radius := 9.0 + 4.0 * sin(seed + index * 2.3)
		points.append(centre + Vector2.from_angle(angle) * radius)
	canvas.draw_colored_polygon(points, Color("#05070d"))
	points.append(points[0])
	canvas.draw_polyline(points, Color("#9fb4cc"), 1.5, true)
	var twinkle := 0.5 + 0.5 * sin(time * 6.0 + seed)
	canvas.draw_circle(centre + Vector2(2, -2), 1.2 + twinkle, Color(1, 1, 1, 0.8))


## A target reticle on the tile a weapon is aimed at, with the weapon's number.
func _draw_target_mark(canvas: CanvasItem, mark: Dictionary) -> void:
	var cell: Vector2i = mark.cell
	if ship.room_at(cell) < 0:
		return
	var at := ship.design.cell_centre(cell)
	var colour: Color = mark.colour
	var pulse := 1.0 + 0.08 * sin(time * 6.0)
	canvas.draw_arc(at, 11.0 * pulse, 0, TAU, 28, colour, 2.5, true)
	for step in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		canvas.draw_line(at + step * 6.0, at + step * 16.0 * pulse, colour, 2.2, true)
	_draw_upright(canvas, at + Vector2(13, 13) * (-1.0 if ship.facing_down else 1.0), func(p: Vector2):
		canvas.draw_circle(p, 7.5, Color(0, 0, 0, 0.65))
		canvas.draw_string(UiKit.font_bold(), p + Vector2(-4, 5), str(mark.label), HORIZONTAL_ALIGNMENT_CENTER, -1, 13, colour))


## Where each selected crew member is walking to: a small marker on their destination tile.
func _draw_destinations(canvas: CanvasItem) -> void:
	for member in ship.crew + ship.visitors:
		if member.ship != ship or not member.selected or member.path.is_empty() or member.dead:
			continue
		var at := ship.design.cell_centre(member.destination)
		var pulse := 0.5 + 0.5 * sin(time * 5.0)
		canvas.draw_arc(at, 9.0 + pulse * 2.0, 0, TAU, 20, Color(UiColours.POWER_GREEN, 0.8), 2.0, true)
		canvas.draw_circle(at, 2.5, UiColours.POWER_GREEN)


# --- Crew ----------------------------------------------------------------------------------------------------

func _draw_crew() -> void:
	if not interior_visible:
		return
	var canvas := _crew_layer
	for member in ship.crew + ship.visitors:
		if member.dead or member.in_suit or member.ship != ship:
			continue
		var at := member.previous_position.lerp(member.position, alpha)
		var ring := UiColours.POWER_GREEN if member.side == 0 else UiColours.enemy_power(member.home.faction, member.home.race)
		if member.teleporting_ticks > 0:
			var t := member.teleporting_ticks / float(Encounter.TELEPORT_TICKS)
			canvas.draw_circle(at, TOKEN_RADIUS * (1.0 + t), Color(0.6, 0.9, 1.0, 0.35 * t))
			for index in 6:
				var spark := at + Vector2.from_angle(index * TAU / 6.0 + time * 4.0) * TOKEN_RADIUS * (0.6 + t)
				canvas.draw_circle(spark, 1.6, Color(0.85, 0.95, 1.0, t))
			if t > 0.5:
				continue
		_draw_upright(canvas, at, func(p: Vector2): _draw_member(canvas, member, p, ring))
		if member.healing:
			_draw_heal_sparks(canvas, at, member.name.hash())


## Small green crosses drifting up off a crew member a medbay is healing.
func _draw_heal_sparks(canvas: CanvasItem, at: Vector2, seed: int) -> void:
	var up := Vector2.DOWN if ship.facing_down else Vector2.UP
	for index in 4:
		var t := fposmod(time * 0.7 + index / 4.0 + (seed % 97) / 97.0, 1.0)
		var side := Vector2(up.y, -up.x) * (sin(seed + index * 2.1) * 11.0)
		var p := at + side + up * (4.0 + t * 26.0)
		var arm := 4.5 * (1.0 - t * 0.4)
		var colour := Color(0.45, 1.0, 0.55, minf(1.0, (1.0 - t) * 1.6))
		canvas.draw_line(p - Vector2(arm + 1.0, 0), p + Vector2(arm + 1.0, 0), Color(0, 0.15, 0.05, colour.a * 0.6), 4.5)
		canvas.draw_line(p - Vector2(0, arm + 1.0), p + Vector2(0, arm + 1.0), Color(0, 0.15, 0.05, colour.a * 0.6), 4.5)
		canvas.draw_line(p - Vector2(arm, 0), p + Vector2(arm, 0), colour, 2.5)
		canvas.draw_line(p - Vector2(0, arm), p + Vector2(0, arm), colour, 2.5)


func _draw_member(canvas: CanvasItem, member: CrewMember, at: Vector2, ring: Color) -> void:
	if member.selected:
		canvas.draw_arc(at, TOKEN_RADIUS + 4.0, 0, TAU, 28, Color(UiColours.POWER_GREEN, 0.9), 2.0, true)
	CrewPortraits.draw_token(canvas, member.race.id, member.name, at, TOKEN_RADIUS, ring, 2.2 if member.side == 0 else 2.6)
	var fraction := member.health_fraction()
	if fraction < 0.999 or member.selected:
		var bar := Rect2(at + Vector2(-12, TOKEN_RADIUS + 3), Vector2(24, 4))
		canvas.draw_rect(bar, Color(0, 0, 0, 0.75))
		canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), UiColours.hull_colour(fraction))
	var badge := ""
	match member.task:
		"repairing", "patching":
			badge = "repair"
		"extinguishing":
			badge = "fire"
		"fighting", "breaking", "sabotaging":
			badge = "fight"
		"stunned":
			badge = "stun"
	if member.suffocating:
		badge = "air"
	if not badge.is_empty():
		_draw_badge(canvas, at + Vector2(TOKEN_RADIUS * 0.8, -TOKEN_RADIUS * 0.8), badge)


func _draw_badge(canvas: CanvasItem, at: Vector2, badge: String) -> void:
	canvas.draw_circle(at, 6.5, Color(0.05, 0.07, 0.1, 0.9))
	match badge:
		"repair":
			canvas.draw_line(at + Vector2(-3, 3), at + Vector2(3, -3), Color("#ffd23d"), 2.0, true)
			canvas.draw_circle(at + Vector2(3, -3), 2.0, Color("#ffd23d"))
		"fire":
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-3, 3), at + Vector2(0, -4), at + Vector2(3, 3)]), Color("#ff7a2a"))
		"fight":
			canvas.draw_line(at + Vector2(-3, -3), at + Vector2(3, 3), Color("#ff5a4d"), 2.0, true)
			canvas.draw_line(at + Vector2(3, -3), at + Vector2(-3, 3), Color("#ff5a4d"), 2.0, true)
		"stun":
			canvas.draw_arc(at, 3.5, time * 6.0, time * 6.0 + 4.5, 8, Color("#9fd0ff"), 1.6, true)
		"air":
			canvas.draw_arc(at, 3.5, 0, TAU, 10, Color("#ff6a8a"), 1.6, true)
