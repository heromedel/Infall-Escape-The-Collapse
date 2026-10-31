class_name Formation
extends RefCounted
## Sizes ships for laying out squads: the box a ship's hull art (or drawn hull) covers, in local pixels.


static func hull_bounds(design: ShipDesign) -> Rect2:
	var texture := Library.texture(design.art_path)
	if texture:
		return Rect2(-design.art_centre, texture.get_size() * design.art_scale)
	var floor_rect := design.floor_rect()
	return Rect2(floor_rect.position - Vector2(30 + ShipDesign.TILE * 2.0, 20 + ShipDesign.TILE * 1.6), floor_rect.size + Vector2(60 + ShipDesign.TILE * 4.0, 70 + ShipDesign.TILE * 1.6))


static var _shields: Dictionary = {}   # design id -> {centre, radii}


## The shield bubble for a ship: the smallest ellipse, around the middle of its hull, that covers every opaque
## pixel of the hull art (or the whole drawn hull), its floor and its weapon mounts, with a little room to spare.
static func shield_shape(design: ShipDesign) -> Dictionary:
	if _shields.has(design.id):
		return _shields[design.id]
	var points := PackedVector2Array()
	var texture := Library.texture(design.art_path)
	var image: Image = texture.get_image() if texture else null
	if image:
		if image.is_compressed():
			image.decompress()
		var step := maxi(2, int(maxf(image.get_width(), image.get_height()) / 160.0))
		for y in range(0, image.get_height(), step):
			for x in range(0, image.get_width(), step):
				if image.get_pixel(x, y).a > 0.35:
					points.append(Vector2(x, y) * design.art_scale - design.art_centre)
	else:
		var bounds := hull_bounds(design)
		for corner in [bounds.position, bounds.end, Vector2(bounds.position.x, bounds.end.y), Vector2(bounds.end.x, bounds.position.y)]:
			points.append(bounds.get_center().lerp(corner, 0.85))
	var floor_rect := design.floor_rect()
	for corner in [floor_rect.position, floor_rect.end, Vector2(floor_rect.position.x, floor_rect.end.y), Vector2(floor_rect.end.x, floor_rect.position.y)]:
		points.append(corner)
	for mount in design.mounts:
		points.append(mount.position + mount.slide * 24.0)
	var box := Rect2(points[0], Vector2.ZERO)
	for point in points:
		box = box.expand(point)
	var centre := box.get_center()
	var half := box.size * 0.5 + Vector2(1, 1)
	var fit := 0.0   # how far past the box-shaped ellipse the furthest point lies
	for point in points:
		var d := (point - centre) / half
		fit = maxf(fit, d.length_squared())
	var shape := {"centre": centre, "radii": half * sqrt(maxf(fit, 1e-4)) + Vector2(22, 22)}
	_shields[design.id] = shape
	return shape
