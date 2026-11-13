class_name Overlay
extends Control
## A window over the ship view: a dimmed backdrop and a framed panel. Event windows, the store, the map, the
## ship screen and the menus all build on it, so they open, look and close the same way.

signal closed

var panel := PanelContainer.new()
var body := VBoxContainer.new()
var dim := ColorRect.new()
var _scroll: ScrollContainer = null   # the scrolling area, for windows whose contents can grow tall

## A shared window (an event, a victory, a hail) shows on every machine and the Admiral answers it (GDD 4M at its
## default): its buttons send their press to the stream, and every machine presses the same button when it comes.
var shared := false
var serial := 0                       # which shared window this is, counted the same way on every machine
var page := 0                         # how many times its buttons were replaced, so a late press can't hit new ones
var _actions: Array[Callable] = []
static var press_shared: Callable     # Main: (window, page, index) -> sends the press
static var may_answer: Callable       # Main: () -> whether a player here is the Admiral


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	dim.color = Color(0.0, 0.01, 0.03, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.045, 0.075, 0.13, 0.97), UiColours.BORDER, 2, 6, 24))
	add_child(panel)
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)


## Centres the panel at a size; height 0 lets it grow with its contents.
func place_panel(width: float, height: float = 0.0) -> void:
	panel.custom_minimum_size = Vector2(width, height)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.resized.connect(_recentre)
	_recentre.call_deferred()


func _recentre() -> void:
	panel.position = (size - panel.size) * 0.5


## A part of the window that scrolls when it is taller than the screen. Windows that rebuild their contents put them
## here and empty it with clear().
func scrolling_area() -> VBoxContainer:
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var area := VBoxContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_theme_constant_override("separation", 12)
	_scroll.add_child(area)
	body.add_child(_scroll)
	return area


## Empties a box at once, not at the end of the frame, so the old and new contents are never both in the window;
## the window then shrinks back around whatever replaces them.
func clear(box: Container) -> void:
	if shared:
		page += 1
		_actions.clear()
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	refit.call_deferred()


## Fits the window to its contents again and keeps it centred, scrolling the scrolling area if it is too tall.
func refit() -> void:
	if _scroll:
		var area := _scroll.get_child(0) as Control
		_scroll.custom_minimum_size = Vector2(0, minf(area.get_combined_minimum_size().y, get_viewport_rect().size.y - 260.0))
	panel.size = Vector2.ZERO
	_recentre()


func add_title(text: String, colour: Color = UiColours.TEXT) -> Label:
	var label := UiKit.title_label(text, 30, colour)
	body.add_child(label)
	return label


func add_text(text: String, size: int = 20, colour: Color = UiColours.TEXT) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = text
	label.add_theme_font_size_override("normal_font_size", size)
	label.add_theme_font_size_override("bold_font_size", size)
	label.add_theme_color_override("default_color", colour)
	label.custom_minimum_size = Vector2(panel.custom_minimum_size.x - 48, 0)
	body.add_child(label)
	return label


func add_separator() -> void:
	var line := ColorRect.new()
	line.color = UiColours.BORDER_DIM
	line.custom_minimum_size = Vector2(0, 1)
	body.add_child(line)


func add_button(text: String, on_press: Callable, colour: Color = UiColours.TEXT, confirm_cost: int = 0) -> Button:
	var button := UiKit.button(text, Callable() if shared else on_press)
	if shared:
		var index := _actions.size()
		var my_page := page
		_actions.append(on_press)
		button.pressed.connect(func(): _ask(my_page, index, confirm_cost))
		if may_answer.is_valid() and not may_answer.call():
			button.disabled = true
			button.tooltip_text = "The Admiral chooses."
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_color_override("font_color", colour)
	button.add_theme_color_override("font_hover_color", colour.lightened(0.3))
	button.add_theme_font_size_override("font_size", 19)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(button)
	return button


## A number key presses the choice with that number, as the genre's event windows do ("1. Continue..."); in a
## window with one unnumbered button, 1 presses it.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo or not visible or is_queued_for_deletion():
		return
	var number := 0
	if event.keycode >= KEY_1 and event.keycode <= KEY_9:
		number = event.keycode - KEY_0
	elif event.keycode >= KEY_KP_1 and event.keycode <= KEY_KP_9:
		number = event.keycode - KEY_KP_0
	if number == 0 or get_parent() == null or get_parent().get_children().filter(func(w): return w is Overlay and w.visible and not w.is_queued_for_deletion()).back() != self:
		return
	var buttons: Array = body.get_children().filter(func(node): return node is Button and node.visible and not node.disabled)
	for button: Button in buttons:
		if button.text.begins_with("%d. " % number):
			get_viewport().set_input_as_handled()
			button.pressed.emit()
			return
	if number == 1 and buttons.size() == 1 and not buttons[0].text.left(2).is_valid_int():
		get_viewport().set_input_as_handled()
		buttons[0].pressed.emit()


## A press of a shared window's button, asked for here: it goes to the stream (after the low Mawjig warning).
func _ask(my_page: int, index: int, cost: int) -> void:
	if press_shared.is_valid():
		LowMawjigWarning.confirm_cost(self, cost, func(): press_shared.call(self, my_page, index))


## The press, as it comes back from the stream on every machine.
func press(at_page: int, index: int) -> void:
	if at_page == page and index >= 0 and index < _actions.size():
		_actions[index].call()


func close() -> void:
	closed.emit()
	queue_free()
