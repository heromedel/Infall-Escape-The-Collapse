## Draws one card: frame, cost, name, art, type line and rules text. Also draws card backs.
## The card is drawn at its base size and scaled with the Control's scale, so text stays sharp at any zoom.
class_name CardView
extends Control

const BASE_SIZE := Vector2(180, 252)

signal clicked(card_view: CardView)
signal hovered(card_view: CardView, is_hovered: bool)

var card := {}
var definition := {}
var face_down := false
## Playable cards glow; unplayable cards are dimmed.
var playable := false
var dimmed := false
var selected := false
var owner_color := UiKit.GOOD
## Extra line for the footer, e.g. the system name.
var footer := ""
var count_badge := 0

var _hover := false
var _glow_phase := 0.0


func _init() -> void:
	custom_minimum_size = BASE_SIZE
	size = BASE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func():
		_hover = true
		hovered.emit(self, true)
		queue_redraw())
	mouse_exited.connect(func():
		_hover = false
		hovered.emit(self, false)
		queue_redraw())


func setup(card_instance: Dictionary, card_definition: Dictionary, footer_text: String = "") -> CardView:
	card = card_instance
	definition = card_definition
	footer = footer_text
	queue_redraw()
	return self


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event()


func _process(delta: float) -> void:
	if playable or selected:
		_glow_phase += delta * 3.0
		queue_redraw()


func _draw() -> void:
	UiKit.load_fonts()
	var rect := Rect2(Vector2.ZERO, BASE_SIZE)
	# Shadow
	draw_style_box(_rounded(Color(0, 0, 0, 0.45), Color(0, 0, 0, 0), 12, 0), rect.grow(2).grow_individual(0, 0, 3, 6))
	if face_down:
		_draw_back(rect)
		return
	var group_color: Color = UiKit.GROUP_COLORS.get(definition.get("group", "power"), UiKit.ACCENT)
	if playable or selected:
		var pulse := 0.55 + 0.45 * sin(_glow_phase)
		var glow := (UiKit.ACCENT if selected else group_color)
		for i in 3:
			draw_style_box(_rounded(Color(0, 0, 0, 0), Color(glow, (0.35 - i * 0.1) * pulse), 14 + i * 2, 3), rect.grow(3 + i * 3))
	# Body
	draw_style_box(_rounded(Color("#151b2c"), group_color.darkened(0.15), 12, 3), rect)
	draw_style_box(_rounded(Color("#0d1220"), Color(0, 0, 0, 0), 9, 0), Rect2(8, 8, BASE_SIZE.x - 16, BASE_SIZE.y - 16))
	# Name bar
	var name_rect := Rect2(10, 10, BASE_SIZE.x - 20, 30)
	draw_style_box(_rounded(group_color.darkened(0.62), group_color.darkened(0.35), 6, 1), name_rect)
	var title: String = definition.get("name", "?")
	var title_size := UiKit.fit_size(UiKit.display_font, title, name_rect.size.x - 40, 16, 11)
	UiKit.draw_text_centered(self, UiKit.display_font, title, Rect2(name_rect.position + Vector2(30, 0), name_rect.size - Vector2(34, 0)), title_size, UiKit.TEXT)
	# Art window
	var art_rect := Rect2(14, 46, BASE_SIZE.x - 28, 84)
	_draw_art_background(art_rect, group_color)
	IconPainter.paint_glowing(self, definition.get("art", "power"), art_rect.get_center(), 58, group_color.lightened(0.15))
	draw_style_box(_rounded(Color(0, 0, 0, 0), group_color.darkened(0.3), 6, 1), art_rect)
	# Cost gem (drawn over the name bar's left end)
	_draw_cost_gem(Vector2(24, 25), int(definition.get("cost", 0)))
	# Type line
	var type_rect := Rect2(14, 134, BASE_SIZE.x - 28, 18)
	draw_rect(type_rect, Color(group_color, 0.14))
	var type_text := _type_line().to_upper()
	UiKit.draw_text_centered(self, UiKit.display_font, type_text, type_rect,
		UiKit.fit_size(UiKit.display_font, type_text, type_rect.size.x - 6, 11, 8), group_color.lightened(0.25))
	# Rules text
	var text: String = definition.get("text", "")
	var text_size := 12
	var text_width := BASE_SIZE.x - 30
	while text_size > 9 and UiKit.body_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, text_width, text_size).y > 78:
		text_size -= 1
	draw_multiline_string(UiKit.body_font, Vector2(15, 158 + UiKit.body_font.get_ascent(text_size)), text,
		HORIZONTAL_ALIGNMENT_LEFT, text_width, text_size, -1, Color("#d9deea"))
	# Footer
	var footer_text := footer
	if card.get("temporary", false):
		footer_text = "TEMPORARY"
	if footer_text != "":
		UiKit.draw_text_centered(self, UiKit.body_font, footer_text, Rect2(10, BASE_SIZE.y - 22, BASE_SIZE.x - 20, 14), 10, UiKit.MUTED)
	var mawjig := float(definition.get("mawjig", 0.0))
	if mawjig > 0.0:
		# Mawjig to fire it, under the Ammo setting: a small amber tag in the art window's corner.
		var tag_text := Money.text(mawjig, false)
		var tag := Rect2(BASE_SIZE.x - 66, 112, 50, 16)
		draw_style_box(UiKit.box(Color("#1a1204", 0.9), UiKit.ACCENT, 8, 1), tag)
		UiKit.draw_text_centered(self, UiKit.display_bold_font, tag_text + " M", tag, 11, UiKit.ACCENT)
	if count_badge > 1:
		var badge_center := Vector2(BASE_SIZE.x - 18, 18)
		draw_circle(badge_center, 14, Color("#0b0f1a"))
		draw_arc(badge_center, 14, 0, TAU, 24, UiKit.TEXT, 2, true)
		UiKit.draw_text_centered(self, UiKit.display_bold_font, "×%d" % count_badge, Rect2(badge_center - Vector2(14, 14), Vector2(28, 28)), 13, UiKit.TEXT)
	if dimmed:
		draw_style_box(_rounded(Color(0.02, 0.03, 0.06, 0.5), Color(0, 0, 0, 0), 12, 0), rect)


func _type_line() -> String:
	var group_name: String = CardLibrary.GROUP_NAMES.get(definition.get("group", ""), "")
	if definition.get("id", "") == "weapon":
		return "%s · %s %d" % [Catalog.weapon_kind(definition.kind).name, "Type", definition.weapon_type]
	match definition.get("target", ""):
		CardLibrary.TARGET_ENEMY_SYSTEM: return group_name + " · Target enemy"
		CardLibrary.TARGET_OWN_SYSTEM: return group_name + " · Target yours"
		CardLibrary.TARGET_CREW_THEN_SYSTEM: return group_name + " · Crew"
	return group_name


func _draw_cost_gem(center: Vector2, cost: int) -> void:
	var points := PackedVector2Array()
	for i in 6:
		points.append(center + Vector2.from_angle(i * TAU / 6.0 + PI / 6.0) * 17)
	draw_colored_polygon(points, Color("#2a1d05"))
	var inner := PackedVector2Array()
	for i in 6:
		inner.append(center + Vector2.from_angle(i * TAU / 6.0 + PI / 6.0) * 14)
	draw_colored_polygon(inner, Color("#ffc247") if cost > 0 else Color("#6b7187"))
	points.append(points[0])
	draw_polyline(points, Color("#fff0c4") if cost > 0 else Color("#9aa1b5"), 2, true)
	UiKit.draw_text_centered(self, UiKit.display_bold_font, str(cost), Rect2(center - Vector2(14, 14), Vector2(28, 28)), 19, Color("#1a1204"))


func _draw_art_background(art_rect: Rect2, group_color: Color) -> void:
	var top := group_color.darkened(0.72)
	var bottom := Color("#05070d")
	var steps := 12
	for i in steps:
		var y := art_rect.position.y + art_rect.size.y * i / steps
		draw_rect(Rect2(art_rect.position.x, y, art_rect.size.x, art_rect.size.y / steps + 1), top.lerp(bottom, float(i) / steps))
	# Stars, placed from the card id so each card looks the same every time.
	var seed_value := hash(str(definition.get("name", "")))
	for i in 14:
		seed_value = (seed_value * 1103515245 + 12345) & 0x7fffffff
		var x := art_rect.position.x + 4 + (seed_value % int(art_rect.size.x - 8))
		seed_value = (seed_value * 1103515245 + 12345) & 0x7fffffff
		var y := art_rect.position.y + 4 + (seed_value % int(art_rect.size.y - 8))
		draw_circle(Vector2(x, y), 0.6 + (seed_value % 3) * 0.4, Color(1, 1, 1, 0.25 + (seed_value % 5) * 0.08))


func _draw_back(rect: Rect2) -> void:
	draw_style_box(_rounded(Color("#10142a"), owner_color.darkened(0.25), 12, 3), rect)
	var center := rect.get_center()
	# The collapse: a dark core with a glowing accretion ring, the game's mark.
	for i in 8:
		draw_circle(center, 62 - i * 6, Color(owner_color.lerp(Color("#ffb347"), i / 8.0), 0.05 + i * 0.025))
	draw_arc(center, 40, 0, TAU, 48, Color("#ffb347", 0.9), 3, true)
	draw_arc(center, 48, -0.6, 2.4, 32, Color(owner_color, 0.7), 2, true)
	draw_arc(center, 54, 2.8, 5.2, 32, Color(owner_color, 0.45), 2, true)
	draw_circle(center, 30, Color("#04050a"))
	draw_style_box(_rounded(Color(0, 0, 0, 0), Color(owner_color, 0.35), 8, 1), rect.grow(-10))
	UiKit.draw_text_centered(self, UiKit.display_font, "INFALL", Rect2(0, rect.size.y - 46, rect.size.x, 20), 16, Color(owner_color.lightened(0.3), 0.8))


func _rounded(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	return style
