## Shared look for every screen: colours, fonts, the theme, and small builders for common widgets.
class_name UiKit
extends RefCounted

const BACKGROUND := Color("#070a12")
const PANEL := Color("#121827")
const PANEL_LIGHT := Color("#1a2236")
const PANEL_HOVER := Color("#232d47")
const LINE := Color("#2c3654")
const TEXT := Color("#e9edf7")
const MUTED := Color("#8e98b5")
const FAINT := Color("#55607d")
const ACCENT := Color("#ffb347")
const GOOD := Color("#66ff66")
const DANGER := Color("#ff4d5e")
const ION := Color("#62d0ff")
const SHIELD := Color("#4fb8ff")
const FIRE := Color("#ff7a2a")
const HELD := Color("#7fa8ff")
const MIND := Color("#c77dff")

## Card group colours (frame and art tint).
const GROUP_COLORS := {
	"power": Color("#ffc247"),
	"weapon": Color("#ff5a5f"),
	"defense": Color("#47b8ff"),
	"crew": Color("#5ee38a"),
	"tactic": Color("#b57bff"),
}

static var display_font: Font
static var display_bold_font: Font
static var body_font: Font
static var body_bold_font: Font
static var _theme: Theme


static func load_fonts() -> void:
	if body_font:
		return
	display_font = load("res://fonts/ChakraPetch-SemiBold.ttf")
	display_bold_font = load("res://fonts/ChakraPetch-Bold.ttf")
	var plex: FontFile = load("res://fonts/IBMPlexSans.ttf")
	var regular := FontVariation.new()
	regular.base_font = plex
	regular.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 420}
	body_font = regular
	var bold := FontVariation.new()
	bold.base_font = plex
	bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 620}
	body_bold_font = bold


static func theme() -> Theme:
	if _theme:
		return _theme
	load_fonts()
	var t := Theme.new()
	t.default_font = body_font
	t.default_font_size = 16
	t.set_color("font_color", "Label", TEXT)

	var normal := box(PANEL_LIGHT, LINE, 6, 1)
	var hover := box(PANEL_HOVER, ACCENT.darkened(0.2), 6, 1)
	var pressed := box(PANEL, ACCENT, 6, 2)
	var disabled := box(PANEL, LINE.darkened(0.3), 6, 1)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style: StyleBox = {"normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled, "focus": hover}[state]
		if state == "focus":
			style = StyleBoxEmpty.new()
		t.set_stylebox(state, "Button", style)
		t.set_stylebox(state, "OptionButton", style if state != "focus" else StyleBoxEmpty.new())
	t.set_font("font", "Button", display_font)
	t.set_font_size("font_size", "Button", 17)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", FAINT)
	t.set_font("font", "OptionButton", body_font)
	t.set_font_size("font_size", "OptionButton", 15)
	t.set_color("font_color", "OptionButton", TEXT)

	t.set_stylebox("normal", "LineEdit", box(Color("#0c111d"), LINE, 5, 1))
	t.set_stylebox("focus", "LineEdit", box(Color("#0c111d"), ACCENT, 5, 1))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", ACCENT)
	t.set_font_size("font_size", "LineEdit", 15)
	t.set_stylebox("normal", "TextEdit", box(Color("#0c111d"), LINE, 5, 1))
	t.set_stylebox("focus", "TextEdit", box(Color("#0c111d"), ACCENT, 5, 1))
	t.set_color("font_color", "TextEdit", TEXT)
	t.set_font("font", "TextEdit", body_font)
	t.set_font_size("font_size", "TextEdit", 13)

	t.set_stylebox("panel", "PanelContainer", box(PANEL, LINE, 10, 1))
	t.set_stylebox("panel", "PopupMenu", box(PANEL_LIGHT, LINE, 6, 1))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_stylebox("hover", "PopupMenu", box(PANEL_HOVER, PANEL_HOVER, 4, 0))
	t.set_stylebox("panel", "TooltipPanel", box(Color("#0d1220"), ACCENT.darkened(0.3), 6, 1))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font_size("font_size", "TooltipLabel", 14)

	t.set_font("normal_font", "RichTextLabel", body_font)
	t.set_font("bold_font", "RichTextLabel", body_bold_font)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 15)
	t.set_font_size("bold_font_size", "RichTextLabel", 15)

	var scroll_grabber := box(LINE, LINE, 4, 0)
	t.set_stylebox("grabber", "VScrollBar", scroll_grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", box(ACCENT.darkened(0.3), ACCENT.darkened(0.3), 4, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(ACCENT, ACCENT, 4, 0))
	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.2), Color(0, 0, 0, 0), 4, 0))
	_theme = t
	return t


static func box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.anti_aliasing = true
	return style


static func label(text: String, size: int = 16, color: Color = TEXT, font: Font = null) -> Label:
	load_fonts()
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_font_override("font", font if font else body_font)
	return node


static func heading(text: String, size: int = 28, color: Color = TEXT) -> Label:
	load_fonts()
	return label(text, size, color, display_font)


static func button(text: String, on_press: Callable, size: int = 17, min_width: int = 0) -> Button:
	var node := Button.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.custom_minimum_size = Vector2(min_width, 0)
	node.pressed.connect(func():
		Sounds.play("click")
		on_press.call())
	node.mouse_entered.connect(func(): if not node.disabled: Sounds.play("hover", -8.0))
	return node


## A big call-to-action button in the accent colour.
static func primary_button(text: String, on_press: Callable, size: int = 20, min_width: int = 0) -> Button:
	var node := button(text, on_press, size, min_width)
	node.add_theme_stylebox_override("normal", box(ACCENT.darkened(0.55), ACCENT, 8, 2))
	node.add_theme_stylebox_override("hover", box(ACCENT.darkened(0.4), ACCENT.lightened(0.2), 8, 2))
	node.add_theme_stylebox_override("pressed", box(ACCENT.darkened(0.65), ACCENT, 8, 2))
	node.add_theme_stylebox_override("disabled", box(PANEL, LINE, 8, 1))
	node.add_theme_color_override("font_color", Color("#fff3df"))
	return node


static func panel(fill: Color = PANEL, border: Color = LINE, radius: int = 10) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", box(fill, border, radius, 1))
	return node


static func margin(child: Control, amount: int) -> MarginContainer:
	var node := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		node.add_theme_constant_override("margin_" + side, amount)
	node.add_child(child)
	return node


static func vbox(spacing: int = 8) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", spacing)
	return node


static func hbox(spacing: int = 8) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", spacing)
	return node


## Draws text centred in a rectangle on any CanvasItem.
static func draw_text_centered(canvas: CanvasItem, font: Font, text: String, rect: Rect2, size: int, color: Color) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var baseline := rect.position.y + (rect.size.y - text_size.y) / 2.0 + font.get_ascent(size)
	canvas.draw_string(font, Vector2(rect.position.x, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color)


## The largest font size (down to a floor) at which the text fits in the width.
static func fit_size(font: Font, text: String, width: float, size: int, smallest: int = 9) -> int:
	while size > smallest and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		size -= 1
	return size
