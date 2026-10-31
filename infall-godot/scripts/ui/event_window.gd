class_name EventWindow
extends Overlay
## An event box in the form of events-sample.md: the opening text, numbered choices (blue choices first say
## what they need), then the outcome and a summary of what was gained or lost.

signal resolved(result: Dictionary)

const BLUE := Color("#7cc8ff")

var runner: EventRunner
var def: EventDef
var header := ""


func show_event(event_def: EventDef, event_runner: EventRunner, heading: String = "") -> void:
	def = event_def
	runner = event_runner
	header = heading
	place_panel(820)
	_show_opening()


func _show_opening() -> void:
	_clear()
	if not header.is_empty():
		body.add_child(UiKit.label(header, 15, UiColours.TEXT_DIM, true))
	if not def.title.is_empty():
		add_title(def.title)
	add_text(runner.fill_text(def.text), 21)
	add_separator()
	var number := 1
	for choice in def.choices:
		if not runner.can_take(choice):
			continue
		var blue := runner.is_blue(choice)
		var crew_name := runner.crew_for_choice(choice)
		var label := "%d. %s%s" % [number, (runner.requirement_label(choice) + " ") if blue or String(choice.requires).begins_with("mawjig") else "", runner.fill_text(choice.text, crew_name)]
		add_button(label, func(): _choose(choice, crew_name), BLUE if blue else UiColours.TEXT)
		number += 1


func _choose(choice: Dictionary, crew_name: String) -> void:
	var result := runner.resolve(choice, crew_name)
	if String(result.text).is_empty() and result.lines.is_empty():
		_finish(result)
		return
	_clear()
	if not def.title.is_empty():
		add_title(def.title)
	if not String(result.text).is_empty():
		add_text(result.text, 21)
	if not result.lines.is_empty():
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", UiKit.box(Color(0.02, 0.04, 0.08, 0.9), UiColours.BORDER_DIM, 1, 4, 12))
		var lines := VBoxContainer.new()
		box.add_child(lines)
		for line in result.lines:
			var colour := UiColours.POWER_GREEN if (line.contains("+") or line.begins_with("Weapon") or line.contains("joins")) else (UiColours.DAMAGED_RED if (line.contains("-") or line.contains("lost") or line.contains("injured") or line.contains("damaged")) else UiColours.TEXT)
			lines.add_child(UiKit.label(line, 18, colour, true))
		body.add_child(box)
	add_separator()
	var next_label := "Continue..."
	if result.fight_given:
		next_label = "Prepare for battle..."
	add_button(next_label, func(): _finish(result))


func _finish(result: Dictionary) -> void:
	resolved.emit(result)
	close()


func _clear() -> void:
	for child in body.get_children():
		child.queue_free()
