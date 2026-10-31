class_name Formation
extends RefCounted
## Sizes ships for laying out squads: the box a ship's hull art (or drawn hull) covers, in local pixels.


static func hull_bounds(design: ShipDesign) -> Rect2:
	var texture := Library.texture(design.art_path)
	if texture:
		return Rect2(-design.art_centre, texture.get_size() * design.art_scale)
	var floor_rect := design.floor_rect()
	return Rect2(floor_rect.position - Vector2(30 + ShipDesign.TILE * 2.0, 20 + ShipDesign.TILE * 1.6), floor_rect.size + Vector2(60 + ShipDesign.TILE * 4.0, 70 + ShipDesign.TILE * 1.6))
