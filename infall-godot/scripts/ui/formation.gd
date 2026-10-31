class_name Formation
extends RefCounted
## Sizes ships for laying out squads: the box a ship's hull art (or drawn hull) covers, in local pixels, the
## square zone every ship sits in, and where a squad's zones go.


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


const ZONE_MARGIN_TILES := 8.0       # heromedel, 2026-10-31: the largest hull plus 8 tiles
const SQUAD_SHIFT_ZONES := 0.5       # in a fight each squad sits half a zone to its own side, so rows don't line up
static var _zone_size: float = 0.0


## The side of the square zone each ship sits centred in (GDD 3S): the largest hull in the game plus the margin,
## so a big ship just fits and a small one sits far from its neighbours and the barrier.
static func zone_size() -> float:
	if _zone_size <= 0.0:
		var largest := 0.0
		for id in Library.ships:
			var bounds := hull_bounds(Library.ship(id))
			largest = maxf(largest, maxf(bounds.size.x, bounds.size.y))
		_zone_size = ceilf(largest / ShipDesign.TILE + ZONE_MARGIN_TILES) * ShipDesign.TILE
	return _zone_size


## The centres of a squad's zones, as (sideways, back from the front line) in zones, for a formation from the
## settings (GDD 3H: a gentle curve, outer ships forward; 3I: other shapes).
static func zone_offsets(count: int, shape: String) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	for index in count:
		var across := index - (count - 1) * 0.5
		var u := across / maxf(1.0, (count - 1) * 0.5)
		var back := 0.0
		if count > 1:
			match shape:
				"Curve":
					back = 0.45 * (1.0 - u * u)
				"Inverted Curve":
					back = 0.45 * u * u
		offsets.append(Vector2(across, back))
	return offsets


## Puts every ship in the middle of its zone (GDD 3S). The player squad sits below the barrier and the enemy
## above it (GDD 3A); each zone's front edge starts at the barrier's line, so ships never crowd it or each other.
static func lay_out(encounter: Encounter, shape: String) -> void:
	var zone := zone_size()
	for side in [0, 1]:
		var squad: Array[Ship] = []
		for ship in encounter.ships:
			if ship.side == side:
				squad.append(ship)
		var offsets := zone_offsets(squad.size(), shape)
		var shift := SQUAD_SHIFT_ZONES * zone if encounter.fight_started else 0.0
		for index in squad.size():
			var ship := squad[index]
			ship.facing_down = side == 1
			var depth := Encounter.BARRIER_HALF_DEPTH + zone * (0.5 + offsets[index].y)
			var centre := Vector2(offsets[index].x * zone - shift, depth) if side == 0 else Vector2(-offsets[index].x * zone + shift, -depth)
			var hull_centre := hull_bounds(ship.design).get_center()
			# local_to_world turns an enemy ship around, so its hull centre is subtracted the other way
			ship.world_position = centre + hull_centre if ship.facing_down else centre - hull_centre
