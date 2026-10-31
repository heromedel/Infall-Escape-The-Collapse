class_name WeaponArt
extends RefCounted
## Draws a weapon at its mount, pointing up: its own art when its folder has some, otherwise a weapon drawn
## from its type and its race's style (a laser turret with a barrel per shot, a missile pod, a beam emitter...),
## so a weapon without art still looks like a weapon (GDD 8J). A glow at the muzzle shows its charge.

const STYLES := {
	"terran": [Color("#e6eaf0"), Color("#8f99a8"), Color("#3b6fd8")],
	"gatos": [Color("#e6eaf0"), Color("#8f99a8"), Color("#3b6fd8")],
	"pirate": [Color("#646a74"), Color("#3a3f47"), Color("#c0532b")],
	"mecha": [Color("#2a2c35"), Color("#14151a"), Color("#aa28eb")],
	"tentauri": [Color("#eef2f3"), Color("#7fe0dc"), Color("#ff5eca")],
	"azurethea": [Color("#4f9be8"), Color("#2547b8"), Color("#9fe3ff")],
	"senti": [Color("#f2f4f7"), Color("#a9b4c0"), Color("#4ff0ff")],
	"lykario": [Color("#8d8a82"), Color("#55534e"), Color("#f2f2ee")],
	"malphen": [Color("#d98a8a"), Color("#9c4f62"), Color("#f6e7d6")],
}


static func draw(canvas: CanvasItem, def: WeaponDef, at: Vector2, style: String, charge: float, flash: bool, powered: bool) -> void:
	var texture := Library.texture(def.art_path) if not def.art_path.is_empty() else null
	var muzzle := at + Vector2(0, -20)
	if texture:
		var size := texture.get_size() * def.art_scale
		var rect := Rect2(at - def.art_anchor * def.art_scale, size)
		canvas.draw_texture_rect(texture, rect, false, Color.WHITE if powered else Color(0.65, 0.65, 0.7))
		muzzle = Vector2(at.x, rect.position.y + 4.0)
	else:
		var colours: Array = STYLES.get(def.race if STYLES.has(def.race) else style, STYLES["terran"])
		muzzle = _draw_shape(canvas, def, at, colours, powered)
	if powered and charge > 0.02:
		var glow := def.colour
		var ready := charge >= 0.999
		var radius := 2.0 + 3.0 * charge + (1.2 * sin(Time.get_ticks_msec() / 90.0) if ready else 0.0)
		canvas.draw_circle(muzzle, radius + 3.0, Color(glow, 0.18 * charge))
		canvas.draw_circle(muzzle, radius, Color(glow.lightened(0.4), 0.55 * charge + (0.3 if ready else 0.0)))
	if flash:
		canvas.draw_circle(muzzle, 9.0, Color(1, 1, 0.9, 0.85))
		canvas.draw_circle(muzzle, 14.0, Color(def.colour, 0.4))


static func _draw_shape(canvas: CanvasItem, def: WeaponDef, at: Vector2, colours: Array, powered: bool) -> Vector2:
	var body: Color = colours[0]
	var shade: Color = colours[1]
	var trim: Color = colours[2]
	if not powered:
		body = body.darkened(0.25)
		trim = trim.darkened(0.4)
	var outline := Color("#0d1018")
	match def.type:
		"missile":
			var tubes := clampi(def.shots + def.damage - 1, 1, 3)
			var width := 8.0 + tubes * 6.0
			var pod := Rect2(at + Vector2(-width * 0.5, -22), Vector2(width, 28))
			canvas.draw_rect(pod.grow(1.5), outline)
			canvas.draw_rect(pod, body)
			canvas.draw_rect(Rect2(pod.position, Vector2(width * 0.35, pod.size.y)), shade)
			for index in tubes:
				var x := pod.position.x + 7.0 + index * 6.0
				canvas.draw_circle(Vector2(x, pod.position.y + 4.0), 2.6, outline)
				canvas.draw_circle(Vector2(x, pod.position.y + 4.0), 1.8, trim)
			canvas.draw_line(Vector2(pod.position.x, pod.end.y - 6.0), Vector2(pod.end.x, pod.end.y - 6.0), trim, 2.0)
			return Vector2(at.x, pod.position.y + 4.0)
		"beam":
			var base := Rect2(at + Vector2(-9, -8), Vector2(18, 14))
			canvas.draw_rect(base.grow(1.5), outline)
			canvas.draw_rect(base, body)
			var stalk := Rect2(at + Vector2(-3, -30), Vector2(6, 24))
			canvas.draw_rect(stalk.grow(1.5), outline)
			canvas.draw_rect(stalk, shade)
			canvas.draw_circle(at + Vector2(0, -31), 5.5, outline)
			canvas.draw_circle(at + Vector2(0, -31), 4.2, trim)
			return at + Vector2(0, -31)
		"bomb":
			canvas.draw_circle(at + Vector2(0, -8), 10.0, outline)
			canvas.draw_circle(at + Vector2(0, -8), 8.5, body)
			canvas.draw_circle(at + Vector2(-2, -10), 4.0, shade.lightened(0.2))
			canvas.draw_arc(at + Vector2(0, -8), 5.5, 0, TAU, 16, trim, 2.0, true)
			return at + Vector2(0, -8)
		"flak":
			var base := Rect2(at + Vector2(-12, -10), Vector2(24, 16))
			canvas.draw_rect(base.grow(1.5), outline)
			canvas.draw_rect(base, body)
			var barrel := Rect2(at + Vector2(-6, -26), Vector2(12, 18))
			canvas.draw_rect(barrel.grow(1.5), outline)
			canvas.draw_rect(barrel, shade)
			canvas.draw_line(Vector2(barrel.position.x, barrel.position.y + 3.0), Vector2(barrel.end.x, barrel.position.y + 3.0), trim, 2.0)
			return Vector2(at.x, barrel.position.y)
		_:
			var barrels := clampi(def.shots, 1, 3)
			var spread := 5.0
			var base := Rect2(at + Vector2(-9 - barrels * 1.5, -8), Vector2(18 + barrels * 3.0, 15))
			var length := 16.0 + def.damage * 4.0
			for index in barrels:
				var x := at.x + (index - (barrels - 1) * 0.5) * spread
				var barrel := Rect2(Vector2(x - 2.0, at.y - 8.0 - length), Vector2(4.0, length + 2.0))
				canvas.draw_rect(barrel.grow(1.2), outline)
				canvas.draw_rect(barrel, shade.lightened(0.15))
				canvas.draw_rect(Rect2(barrel.position, Vector2(barrel.size.x, 3.0)), trim)
			canvas.draw_rect(base.grow(1.5), outline)
			canvas.draw_rect(base, body)
			canvas.draw_rect(Rect2(base.position + Vector2(0, base.size.y - 4.0), Vector2(base.size.x, 4.0)), shade)
			canvas.draw_circle(at + Vector2(0, -1), 2.5, trim)
			return Vector2(at.x, at.y - 9.0 - length)
