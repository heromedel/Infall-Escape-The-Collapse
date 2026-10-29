## Battle effects drawn over the screen: shots in flight, beams, impacts, sparks and floating numbers.
## Each effect method returns when the effect reaches its key moment (a shot landing), so callers can await it.
class_name FxLayer
extends Control

## Things being drawn: { kind, from, to, age, life, color, ... }.
var _effects: Array = []
var _particles: Array = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	for effect in _effects:
		effect.age += delta
	_effects = _effects.filter(func(e): return e.age < e.life)
	for particle in _particles:
		particle.age += delta
		particle.position += particle.velocity * delta
		particle.velocity *= 1.0 - minf(1.0, delta * particle.drag)
	_particles = _particles.filter(func(p): return p.age < p.life)
	queue_redraw()


## A projectile from one point to another. Returns when it arrives (or passes, for a miss).
func shoot(from: Vector2, to: Vector2, kind: String, color: Color, missed: bool) -> void:
	var speed := Settings.animation_scale()
	var life := 0.42 * speed
	match kind:
		"missile", "spore": life = 0.75 * speed
		"heavy", "flak": life = 0.5 * speed
		"ion", "mind": life = 0.55 * speed
	var target := to
	if missed:
		var away := (to - from).normalized()
		target = to + away.orthogonal() * (60.0 if _rng.randf() < 0.5 else -60.0) + away * 160.0
	_effects.append({"kind": "shot_" + kind, "from": from, "to": target, "age": 0.0, "life": life, "color": color,
		"arc": _rng.randf_range(-0.25, 0.25)})
	await get_tree().create_timer(life * (0.72 if missed else 1.0)).timeout


## A beam sweeping across a target point.
func beam(from: Vector2, to: Vector2, color: Color) -> void:
	var life := 0.6 * Settings.animation_scale()
	_effects.append({"kind": "beam", "from": from, "to": to, "age": 0.0, "life": life, "color": color})
	await get_tree().create_timer(life * 0.5).timeout


func explosion(at: Vector2, color: Color, strength: float = 1.0) -> void:
	_effects.append({"kind": "flash", "from": at, "to": at, "age": 0.0, "life": 0.35, "color": color, "size": 34.0 * strength})
	for i in int(18 * strength):
		var angle = _rng.randf() * TAU
		var speed := _rng.randf_range(60.0, 260.0) * strength
		_particles.append({"position": at, "velocity": Vector2.from_angle(angle) * speed, "age": 0.0,
			"life": _rng.randf_range(0.3, 0.75), "color": color.lerp(Color("#fff3c0"), _rng.randf() * 0.6),
			"size": _rng.randf_range(1.5, 3.5), "drag": 3.0})


func shield_ripple(at: Vector2, color: Color = UiKit.SHIELD) -> void:
	_effects.append({"kind": "ripple", "from": at, "to": at, "age": 0.0, "life": 0.5, "color": color})
	for i in 10:
		var angle = _rng.randf() * TAU
		_particles.append({"position": at + Vector2.from_angle(angle) * 20.0, "velocity": Vector2.from_angle(angle) * 120.0,
			"age": 0.0, "life": 0.4, "color": color.lightened(0.4), "size": 2.0, "drag": 4.0})


func sparkle(at: Vector2, color: Color, count: int = 14) -> void:
	for i in count:
		var angle = _rng.randf() * TAU
		_particles.append({"position": at + Vector2.from_angle(angle) * _rng.randf_range(0, 30), "velocity": Vector2(0, -_rng.randf_range(30, 90)),
			"age": 0.0, "life": _rng.randf_range(0.5, 1.0), "color": color, "size": _rng.randf_range(1.5, 3.0), "drag": 1.0})


## Text that rises and fades, e.g. "-2" or "MISS".
func float_text(at: Vector2, text: String, color: Color, size: int = 26) -> void:
	var label := UiKit.label(text, size, color, UiKit.display_bold_font)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_child(label)
	label.position = at - Vector2(label.get_minimum_size().x / 2.0, 20)
	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 56, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tween.chain().tween_callback(label.queue_free)


## A big banner across the middle of the screen ("YOUR TURN").
func banner(text: String, color: Color) -> void:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	holder.size = size
	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.55)
	strip.size = Vector2(size.x, 90)
	strip.position = Vector2(0, size.y * 0.5 - 45)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(strip)
	var label := UiKit.label(text, 46, color, UiKit.display_bold_font)
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(size.x, 60)
	label.position = Vector2(0, size.y * 0.5 - 32)
	holder.add_child(label)
	holder.modulate.a = 0.0
	var duration := 0.9 * Settings.animation_scale()
	var tween := create_tween()
	tween.tween_property(holder, "modulate:a", 1.0, 0.15)
	tween.tween_interval(duration)
	tween.tween_property(holder, "modulate:a", 0.0, 0.25)
	tween.tween_callback(holder.queue_free)
	await get_tree().create_timer(duration * 0.6).timeout


func _draw() -> void:
	for particle in _particles:
		var fade: float = 1.0 - particle.age / particle.life
		draw_circle(particle.position, particle.size * (0.5 + fade * 0.5), Color(particle.color, fade))
	for effect in _effects:
		var t: float = effect.age / effect.life
		var color: Color = effect.color
		match effect.kind:
			"flash":
				draw_circle(effect.from, effect.size * (0.4 + t), Color(color, (1.0 - t) * 0.6))
				draw_circle(effect.from, effect.size * 0.5 * (1.0 - t), Color(Color("#fff6d8"), 1.0 - t))
			"ripple":
				draw_arc(effect.from, 18 + t * 46, 0, TAU, 40, Color(color, 1.0 - t), 3.0, true)
				draw_arc(effect.from, 10 + t * 30, 0, TAU, 40, Color(color.lightened(0.5), (1.0 - t) * 0.7), 2.0, true)
			"beam":
				var sweep = (effect.to - effect.from).normalized().orthogonal() * 40.0
				var end: Vector2 = effect.to + sweep * (t * 2.0 - 1.0)
				var alpha = sin(t * PI)
				draw_line(effect.from, end, Color(color, alpha * 0.35), 14.0)
				draw_line(effect.from, end, Color(color, alpha), 5.0)
				draw_line(effect.from, end, Color(Color.WHITE, alpha), 2.0)
				draw_circle(end, 9.0, Color(Color.WHITE, alpha))
			_:
				_draw_projectile(effect, t)


func _draw_projectile(effect: Dictionary, t: float) -> void:
	var from: Vector2 = effect.from
	var to: Vector2 = effect.to
	var bend = (to - from).orthogonal() * effect.arc
	var eased = t
	var position = from.lerp(to, eased) + bend * sin(eased * PI)
	var previous = from.lerp(to, maxf(0.0, eased - 0.08)) + bend * sin(maxf(0.0, eased - 0.08) * PI)
	var color: Color = effect.color
	match effect.kind:
		"shot_laser", "shot_chain", "shot_suit":
			draw_line(previous, position, Color(color, 0.4), 9.0)
			draw_line(previous, position, color, 4.0)
			draw_line(previous.lerp(position, 0.4), position, Color.WHITE, 2.0)
		"shot_heavy":
			draw_line(previous, position, Color(color, 0.35), 16.0)
			draw_line(previous, position, color, 8.0)
			draw_line(previous.lerp(position, 0.3), position, Color.WHITE, 3.0)
		"shot_ion":
			draw_circle(position, 11.0, Color(UiKit.ION, 0.3))
			draw_circle(position, 6.0, UiKit.ION)
			draw_circle(position, 3.0, Color.WHITE)
			for i in 3:
				var angle = effect.age * 20.0 + i * TAU / 3.0
				draw_line(position, position + Vector2.from_angle(angle) * 14.0, Color(UiKit.ION, 0.8), 1.5)
		"shot_missile":
			var direction = (position - previous).normalized()
			for i in 6:
				var trail = position - direction * (8.0 + i * 9.0)
				draw_circle(trail, 4.0 + i * 1.3, Color(0.7, 0.7, 0.75, 0.35 - i * 0.05))
			draw_circle(position - direction * 6.0, 5.0, UiKit.FIRE)
			var body = PackedVector2Array([position + direction * 9.0, position + direction.orthogonal() * 4.0 - direction * 6.0,
				position - direction.orthogonal() * 4.0 - direction * 6.0])
			draw_colored_polygon(body, Color("#e8ecf6"))
		"shot_spore":
			# A drifting green cloud with seeds trailing behind it.
			var wobble := Vector2(sin(effect.age * 18.0), cos(effect.age * 14.0)) * 3.0
			for i in 5:
				var behind: Vector2 = position.lerp(from, 0.04 * i) + Vector2.from_angle(i * 1.7 + effect.age * 6.0) * 5.0
				draw_circle(behind + wobble, 7.0 - i, Color("#7dffb0", 0.35 - i * 0.05))
			draw_circle(position + wobble, 8.0, Color("#3fcf7a", 0.75))
			draw_circle(position + wobble, 4.0, Color("#d6ffe4"))
		"shot_mind":
			# Expanding purple rings travelling with the pulse.
			for i in 3:
				var ring := fmod(effect.age * 3.0 + i / 3.0, 1.0)
				draw_arc(position, 4.0 + ring * 14.0, 0, TAU, 20, Color(UiKit.MIND, 1.0 - ring), 2.0, true)
			draw_circle(position, 4.0, Color("#f0dcff"))
		"shot_flak":
			# A spread of debris chunks.
			var direction = (position - previous).normalized()
			for i in 5:
				var spread: Vector2 = direction.orthogonal() * (i - 2) * 6.0 * (0.3 + t)
				var chunk: Vector2 = position + spread - direction * (i % 2) * 6.0
				draw_rect(Rect2(chunk - Vector2(2.5, 2.5), Vector2(5, 5)), Color("#c9b79a"))
				draw_rect(Rect2(chunk - Vector2(1, 1), Vector2(2, 2)), Color.WHITE)
		_:
			draw_circle(position, 5.0, color)
