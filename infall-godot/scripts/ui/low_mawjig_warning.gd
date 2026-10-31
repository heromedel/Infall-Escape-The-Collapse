class_name LowMawjigWarning
extends RefCounted
## GDD 14L: when a voluntary spend (a store purchase, or an event choice that gives Mawjig away) would leave the
## squad below 10 Mawjig, the player is warned first, with the exact amount that would be left. Shots and jumps
## never ask. The Mawjig counter turns yellow below 10 and red below two jumps.

const THRESHOLD := 1000                       # 10 Mawjig, in hundredths
const DANGER := Mawjig.JUMP_COST * 2          # two jumps


## Runs `action` now, or once the player agrees in a warning laid over `host`.
static func confirm(host: Node, run: RunState, cost: int, action: Callable) -> void:
	if not Settings.get_value("low_mawjig_warning", true) or cost <= 0 or run.mawjig - cost >= THRESHOLD:
		action.call()
		return
	var window := Overlay.new()
	host.add_child(window)
	window.place_panel(660)
	window.add_title("LOW MAWJIG", UiColours.WARNING)
	window.add_text("Warning: Mawjig is also used for weapon fire, battlesuits and jumps. After this you would have %s left. If you don't keep enough to fight or jump away, you could be defeated." % Mawjig.format(maxi(0, run.mawjig - cost)), 19)
	window.add_button("Spend it anyway", func():
		window.close()
		action.call(), UiColours.WARNING)
	window.add_button("Keep my Mawjig", window.close)


## The colour the Mawjig counter shows at an amount; `time` makes the red pulse.
static func counter_colour(mawjig: int, time: float) -> Color:
	if mawjig < DANGER:
		return Color(UiColours.DAMAGED_RED, 0.6 + 0.4 * sin(time * 5.0))
	if mawjig < THRESHOLD:
		return UiColours.WARNING
	return Color("#ffd46b")
