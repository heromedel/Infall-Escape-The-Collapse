class_name UiKit
extends RefCounted
## Fonts, the game's theme and a few drawing helpers shared by every screen, so panels and buttons look the
## same everywhere (GDD 14B: muted blue boxes, white text and borders).

static var _regular: Font
static var _bold: Font
static var _title: Font
static var _theme: Theme


static func font_regular() -> Font:
	if _regular == null:
		_regular = load("res://fonts/Barlow-SemiBold.ttf")
	return _regular


static func font_bold() -> Font:
	if _bold == null:
		_bold = load("res://fonts/Barlow-Bold.ttf")
	return _bold


static func font_title() -> Font:
	if _title == null:
		var variation := FontVariation.new()
		variation.base_font = load("res://fonts/Oxanium.ttf")
		variation.variation_opentype = {"wght": 700}
		_title = variation
	return _title


static func box(fill: Color, border: Color, border_width: int = 1, radius: int = 3, padding: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	style.anti_aliasing = true
	return style


static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.default_font = font_regular()
	_theme.default_font_size = 18
	_theme.set_color("font_color", "Label", UiColours.TEXT)
	_theme.set_stylebox("panel", "PanelContainer", box(UiColours.PANEL, UiColours.BORDER_DIM, 1, 4, 10))
	_theme.set_stylebox("panel", "Panel", box(UiColours.PANEL, UiColours.BORDER_DIM, 1, 4, 10))
	_theme.set_stylebox("normal", "Button", box(UiColours.PANEL_LIGHT, UiColours.BORDER_DIM, 1, 3, 8))
	_theme.set_stylebox("hover", "Button", box(UiColours.PANEL_LIGHT.lightened(0.15), UiColours.BORDER, 1, 3, 8))
	_theme.set_stylebox("pressed", "Button", box(UiColours.PANEL_LIGHT.lightened(0.28), UiColours.BORDER, 2, 3, 8))
	_theme.set_stylebox("disabled", "Button", box(UiColours.PANEL_DARK, Color(UiColours.BORDER_DIM, 0.25), 1, 3, 8))
	_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	_theme.set_color("font_color", "Button", UiColours.TEXT)
	_theme.set_color("font_hover_color", "Button", Color.WHITE)
	_theme.set_color("font_pressed_color", "Button", Color.WHITE)
	_theme.set_color("font_disabled_color", "Button", Color(UiColours.TEXT_DIM, 0.45))
	_theme.set_font("font", "Button", font_bold())
	_theme.set_font_size("font_size", "Button", 18)
	_theme.set_stylebox("panel", "TooltipPanel", box(Color(0.03, 0.05, 0.09, 0.96), UiColours.BORDER, 1, 3, 10))
	_theme.set_color("font_color", "TooltipLabel", UiColours.TEXT)
	_theme.set_font_size("font_size", "TooltipLabel", 17)
	_theme.set_stylebox("normal", "LineEdit", box(UiColours.PANEL_DARK, UiColours.BORDER_DIM, 1, 3, 6))
	_theme.set_stylebox("grabber_area", "HSlider", box(UiColours.ACCENT, UiColours.ACCENT, 0, 2, 3))
	_theme.set_stylebox("slider", "HSlider", box(UiColours.BAR_EMPTY, UiColours.BAR_EMPTY, 0, 2, 3))
	_theme.set_stylebox("panel", "PopupMenu", box(UiColours.PANEL_DARK, UiColours.BORDER_DIM, 1, 3, 6))
	_theme.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	_theme.set_color("default_color", "RichTextLabel", UiColours.TEXT)
	_theme.set_font("normal_font", "RichTextLabel", font_regular())
	_theme.set_font("bold_font", "RichTextLabel", font_bold())
	_theme.set_font_size("normal_font_size", "RichTextLabel", 20)
	_theme.set_font_size("bold_font_size", "RichTextLabel", 20)
	_theme.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.2), Color(0, 0, 0, 0), 0, 3, 2))
	_theme.set_stylebox("grabber", "VScrollBar", box(UiColours.BORDER_DIM, UiColours.BORDER_DIM, 0, 3, 2))
	return _theme


## A panel with cut corners, the frame every HUD box uses.
static func draw_frame(canvas: CanvasItem, rect: Rect2, fill: Color = UiColours.PANEL, border: Color = UiColours.BORDER_DIM, cut: float = 10.0, width: float = 1.5) -> void:
	var points := PackedVector2Array([
		rect.position + Vector2(cut, 0), Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.end.y - cut),
		rect.end - Vector2(cut, 0), Vector2(rect.position.x, rect.end.y), rect.position + Vector2(0, cut),
	])
	canvas.draw_colored_polygon(points, fill)
	points.append(points[0])
	canvas.draw_polyline(points, border, width, true)


## Draws text at a baseline point. With no width, right alignment ends the text at `at` and centre alignment
## centres it on `at`.
static func draw_text(canvas: CanvasItem, at: Vector2, text: String, size: int = 18, colour: Color = UiColours.TEXT, font: Font = null, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1) -> void:
	var used_font := font if font else font_regular()
	if width <= 0.0 and align != HORIZONTAL_ALIGNMENT_LEFT:
		var text_width := used_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		at.x -= text_width if align == HORIZONTAL_ALIGNMENT_RIGHT else text_width * 0.5
		canvas.draw_string(used_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
		return
	canvas.draw_string(used_font, at, text, align, width, size, colour)


static func label(text: String, size: int = 18, colour: Color = UiColours.TEXT, bold: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", colour)
	if bold:
		node.add_theme_font_override("font", font_bold())
	return node


static func title_label(text: String, size: int = 30, colour: Color = UiColours.TEXT) -> Label:
	var node := label(text, size, colour)
	node.add_theme_font_override("font", font_title())
	return node


static func button(text: String, on_press: Callable, min_width: float = 0.0) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(min_width, 40)
	node.focus_mode = Control.FOCUS_NONE   # Space and Enter are hotkeys; a button must not take them
	node.pressed.connect(on_press)
	node.pressed.connect(func(): Sfx.play("click"))
	return node
