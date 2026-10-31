class_name EffectsLayer
extends Node2D
## Draws everything that flies or flashes between the ships: laser bolts as glowing streaks, missiles with
## exhaust and smoke, flak, beams, battlesuits, explosions, sparks, smoke and floating numbers. Glows are drawn
## on an additive layer so they light up the space around them.

var encounter: Encounter
var alpha: float = 0.0
var particles: Array = []           # {position, velocity, life, max_life, size, colour, kind, glow, spin}
var texts: Array = []               # {position, text, colour, life, size}
var _glow := Node2D.new()
var _time := 0.0


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = additive
	add_child(_glow)
	_glow.draw.connect(_draw_glow)


func _process(delta: float) -> void:
	_time += delta
	for particle in particles:
		particle.life -= delta
		particle.position += particle.velocity * delta
		particle.velocity *= pow(0.25, delta) if particle.kind == "smoke" else pow(0.6, delta)
		particle.spin += delta * 3.0
	particles = particles.filter(func(p): return p.life > 0.0)
	for text in texts:
		text.life -= delta
		text.position += Vector2(0, -26) * delta
	texts = texts.filter(func(t): return t.life > 0.0)
	if encounter:
		for shot in encounter.projectiles:
			if shot.kind == "missile" and randf() < 0.7 and not encounter.in_barrier(shot.position):
				var at := shot.previous_position.lerp(shot.position, alpha)
				_add("smoke", at - shot.velocity.normalized() * 10.0, Vector2(randf_range(-8, 8), randf_range(-8, 8)), randf_range(0.6, 1.1), randf_range(3.0, 5.0), Color(0.75, 0.75, 0.8, 0.35), false)
	queue_redraw()
	_glow.queue_redraw()


func _add(kind: String, at: Vector2, velocity: Vector2, life: float, size: float, colour: Color, glow: bool) -> void:
	if particles.size() > 900:
		return
	particles.append({"position": at, "velocity": velocity, "life": life, "max_life": life, "size": size, "colour": colour, "kind": kind, "glow": glow, "spin": randf() * TAU})


func explosion(at: Vector2, scale: float = 1.0, colour: Color = Color(1.0, 0.6, 0.25)) -> void:
	_add("flash", at, Vector2.ZERO, 0.18, 34.0 * scale, Color(1.0, 0.95, 0.8), true)
	_add("ring", at, Vector2.ZERO, 0.45, 40.0 * scale, Color(colour, 0.8), true)
	for index in int(14 * scale):
		var direction := Vector2.from_angle(randf() * TAU)
		_add("spark", at, direction * randf_range(80, 260) * scale, randf_range(0.25, 0.6), randf_range(1.5, 3.0), colour.lightened(randf() * 0.4), true)
	for index in int(6 * scale):
		_add("smoke", at + Vector2(randf_range(-8, 8), randf_range(-8, 8)) * scale, Vector2.from_angle(randf() * TAU) * randf_range(10, 40), randf_range(0.8, 1.6), randf_range(6, 12) * scale, Color(0.3, 0.28, 0.3, 0.55), false)
	for index in int(4 * scale):
		_add("debris", at, Vector2.from_angle(randf() * TAU) * randf_range(40, 140) * scale, randf_range(0.8, 1.6), randf_range(2.0, 4.0), Color(0.55, 0.58, 0.64), false)


func shield_sparks(at: Vector2, colour: Color) -> void:
	_add("flash", at, Vector2.ZERO, 0.15, 22.0, Color(colour.lightened(0.5), 0.9), true)
	for index in 10:
		_add("spark", at, Vector2.from_angle(randf() * TAU) * randf_range(60, 180), randf_range(0.2, 0.45), 2.0, colour.lightened(0.3), true)


func small_burst(at: Vector2, colour: Color) -> void:
	_add("flash", at, Vector2.ZERO, 0.12, 16.0, Color(colour, 0.9), true)
	for index in 6:
		_add("spark", at, Vector2.from_angle(randf() * TAU) * randf_range(40, 120), randf_range(0.2, 0.4), 1.8, colour, true)


func sparkle(at: Vector2, colour: Color) -> void:
	for index in 12:
		_add("spark", at + Vector2(randf_range(-14, 14), randf_range(-14, 14)), Vector2(0, -randf_range(20, 60)), randf_range(0.4, 0.8), 2.0, colour, true)


func float_text(at: Vector2, text: String, colour: Color, size: int = 22) -> void:
	texts.append({"position": at, "text": text, "colour": colour, "life": 1.3, "size": size})


func _draw() -> void:
	for particle in particles:
		if particle.glow:
			continue
		var t: float = particle.life / particle.max_life
		match particle.kind:
			"smoke":
				draw_circle(particle.position, particle.size * (1.6 - t * 0.6), Color(particle.colour, particle.colour.a * t))
			"debris":
				var shard := PackedVector2Array()
				for index in 3:
					shard.append(particle.position + Vector2.from_angle(particle.spin + index * 2.1) * particle.size)
				draw_colored_polygon(shard, Color(particle.colour, t))
	if encounter:
		_draw_solid_shots()
	for text in texts:
		var t: float = clampf(text.life / 1.3, 0.0, 1.0)
		var font := UiKit.font_bold()
		var size := font.get_string_size(text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, text.size)
		var at: Vector2 = text.position - Vector2(size.x * 0.5, 0)
		draw_string_outline(font, at, text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, text.size, 5, Color(0, 0, 0, 0.8 * t))
		draw_string(font, at, text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, text.size, Color(text.colour, t))


func _draw_glow() -> void:
	for particle in particles:
		if not particle.glow:
			continue
		var t: float = particle.life / particle.max_life
		match particle.kind:
			"flash":
				_glow.draw_circle(particle.position, particle.size * (1.2 - t * 0.4), Color(particle.colour, particle.colour.a * t * 0.8))
			"ring":
				_glow.draw_arc(particle.position, particle.size * (1.0 - t) + 6.0, 0, TAU, 32, Color(particle.colour, t * 0.8), 3.0 * t + 1.0, true)
			"spark":
				var tail: Vector2 = particle.velocity * 0.03
				_glow.draw_line(particle.position - tail, particle.position, Color(particle.colour, t), particle.size, true)
	if encounter:
		_draw_glowing_shots()


func _draw_solid_shots() -> void:
	for shot in encounter.projectiles:
		var at := shot.previous_position.lerp(shot.position, alpha)
		var direction := shot.velocity.normalized()
		if _crossing(shot.kind, at):
			continue
		match shot.kind:
			"missile":
				var side := direction.orthogonal()
				var body := PackedVector2Array([at + direction * 10.0, at + side * 3.2 - direction * 2.0, at + side * 3.0 - direction * 9.0, at - side * 3.0 - direction * 9.0, at - side * 3.2 - direction * 2.0])
				draw_colored_polygon(body, Color("#d9dde4"))
				draw_line(at + direction * 4.0, at + direction * 10.0, shot.colour.darkened(0.2), 4.0)
				draw_line(at - direction * 9.0 + side * 4.5, at - direction * 5.0 + side * 1.0, Color("#8a92a0"), 2.0)
				draw_line(at - direction * 9.0 - side * 4.5, at - direction * 5.0 - side * 1.0, Color("#8a92a0"), 2.0)
			"flak", "asteroid":
				var size := 4.0 if shot.kind == "flak" else 11.0
				var rock := PackedVector2Array()
				for index in 7:
					rock.append(at + Vector2.from_angle(_time * 4.0 + index * TAU / 7.0) * size * (0.75 + 0.25 * sin(index * 2.3)))
				draw_colored_polygon(rock, Color("#8b7d6b") if shot.kind == "asteroid" else Color("#b9ab92"))
				draw_polyline(rock + PackedVector2Array([rock[0]]), Color("#3a332b"), 1.2, true)
	for suit in encounter.suits:
		if suit.gone:
			continue
		var at := suit.previous_position.lerp(suit.position, alpha)
		if encounter.in_barrier(at):
			continue
		var texture := Library.texture(suit.def.art_path) if not suit.def.art_path.is_empty() else null
		if texture:
			var size := texture.get_size() * suit.def.art_scale
			draw_texture_rect(texture, Rect2(at - size * 0.5, size), false, Color(1, 0.6, 0.6) if suit.is_damaged() else Color.WHITE)
		else:
			CrewPortraits.draw_token(self, suit.pilot.race.id, suit.pilot.name, at, 10.0, UiColours.enemy_power("", suit.pilot.race))
		var oxygen := clampf(float(suit.oxygen_ticks) / float(suit.def.suit_oxygen_ticks), 0.0, 1.0)
		draw_rect(Rect2(at + Vector2(-10, 14), Vector2(20, 3)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(at + Vector2(-10, 14), Vector2(20 * oxygen, 3)), Color("#7fd3ff"))


func _draw_glowing_shots() -> void:
	var dashes: bool = Settings.get_value("shots_crossing_barrier", "Shown") == "Shown"
	for shot in encounter.projectiles:
		var at := shot.previous_position.lerp(shot.position, alpha)
		var direction := shot.velocity.normalized()
		if _crossing(shot.kind, at):
			# Inside the barrier a shot is far away: only a tiny faint dash shows it is on its way (GDD 3R)
			if dashes:
				_glow.draw_line(at - direction * 6.0, at, Color(shot.colour.lightened(0.3), 0.35), 1.5, true)
			continue
		match shot.kind:
			"laser", "defense":
				var length := 34.0 if shot.kind == "laser" else 20.0
				var tail := at - direction * length
				var colour := shot.colour
				_glow.draw_line(tail, at, Color(colour, 0.22), 11.0, true)
				_glow.draw_line(tail.lerp(at, 0.3), at, Color(colour, 0.7), 5.0, true)
				_glow.draw_line(tail.lerp(at, 0.55), at, Color(colour.lightened(0.6), 0.95), 2.2, true)
				_glow.draw_circle(at, 3.5, Color(1, 1, 1, 0.9))
			"missile":
				var flame_at := at - direction * 11.0
				var flicker := 0.8 + 0.2 * sin(_time * 40.0 + at.x)
				_glow.draw_line(flame_at, flame_at - direction * 14.0 * flicker, Color(1.0, 0.55, 0.2, 0.7), 5.0, true)
				_glow.draw_circle(flame_at, 4.0, Color(1.0, 0.85, 0.5, 0.9))
				_glow.draw_circle(at + direction * 6.0, 6.0, Color(shot.colour, 0.15))
			"flak":
				_glow.draw_circle(at, 6.0, Color(1.0, 0.8, 0.5, 0.25))
	for beam in encounter.beams:
		if not beam.has("point"):
			continue
		var source: Ship = beam.source
		var target: Ship = beam.target
		var slot: WeaponSlot = beam.slot
		var origin := encounter.mount_world_position(source, slot)
		var hit_point := encounter.local_to_world(target, beam.point)
		var fade := clampf((beam.total + 6 - beam.ticks) / 6.0, 0.0, 1.0)
		var colour: Color = beam.weapon.colour
		var end_point := hit_point
		if beam.blocked:
			var radii := encounter.bubble_radii(target)
			var centre := encounter.local_to_world(target, encounter.bubble_centre(target))
			end_point = centre + (hit_point - centre).normalized() * minf(radii.x, radii.y) * 0.98
			end_point = origin.lerp(hit_point, 0.92) if end_point.distance_to(origin) > origin.distance_to(hit_point) else end_point
		for part in _outside_barrier(origin, end_point):
			_glow.draw_line(part[0], part[1], Color(colour, 0.25 * fade), 16.0, true)
			_glow.draw_line(part[0], part[1], Color(colour, 0.85 * fade), 5.0, true)
			_glow.draw_line(part[0], part[1], Color(1, 1, 1, 0.8 * fade), 1.8, true)
		_glow.draw_circle(end_point, 9.0 + 2.0 * sin(_time * 30.0), Color(colour.lightened(0.5), 0.8 * fade))
		if not beam.blocked:
			var start_world := encounter.local_to_world(target, beam.start)
			_glow.draw_line(start_world, hit_point, Color(1.0, 0.4, 0.2, 0.5 * fade), 4.0, true)
	for bomb in encounter.bombs:
		var target: Ship = bomb.target
		var at := encounter.local_to_world(target, target.rooms[bomb.room].centre_local(target.design))
		var t: float = 1.0 - bomb.ticks / 14.0
		_glow.draw_circle(at, 18.0 * (1.0 - t) + 4.0, Color(0.7, 0.9, 1.0, 0.5 * t))
		_glow.draw_arc(at, 22.0 * (1.0 - t) + 6.0, 0, TAU, 24, Color(0.8, 0.95, 1.0, 0.8 * t), 2.0, true)
	for suit in encounter.suits:
		if suit.gone:
			continue
		var at := suit.previous_position.lerp(suit.position, alpha)
		if encounter.in_barrier(at):
			if dashes:
				_glow.draw_circle(at, 1.6, Color(0.75, 0.4, 1.0, 0.35))
			continue
		_glow.draw_circle(at + Vector2(0, 10), 5.0 + sin(_time * 30.0), Color(0.75, 0.4, 1.0, 0.5))


## Whether something is crossing the barrier, and so far away that it isn't drawn as itself.
func _crossing(kind: String, at: Vector2) -> bool:
	return Encounter.GATOMETERS_PER_SECOND.has(kind) and encounter.in_barrier(at)


## The parts of a line outside the barrier: a beam is seen leaving its ship and arriving, not crossing.
func _outside_barrier(a: Vector2, b: Vector2) -> Array:
	var half := Encounter.BARRIER_HALF_DEPTH
	if is_equal_approx(a.y, b.y):
		return [] if encounter.in_barrier(a) else [[a, b]]
	var cuts: Array[float] = [0.0]
	for edge in [half, -half]:
		var t: float = (edge - a.y) / (b.y - a.y)
		if t > 0.0 and t < 1.0:
			cuts.append(t)
	cuts.append(1.0)
	cuts.sort()
	var parts: Array = []
	for index in cuts.size() - 1:
		var from := a.lerp(b, cuts[index])
		var to := a.lerp(b, cuts[index + 1])
		if not encounter.in_barrier(from.lerp(to, 0.5)):
			parts.append([from, to])
	return parts
