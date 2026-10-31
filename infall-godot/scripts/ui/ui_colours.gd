class_name UiColours
extends RefCounted
## The game's colours in one place (GDD 14B: muted blue boxes, white text and borders, power colours for power;
## palette.md for the decided values).

const POWER_GREEN := Color("#66ff66")
const PIRATE_ORANGE := Color("#ff8500")
const DAMAGED_RED := Color("#ff4a3d")
const ION_BLUE := Color("#7fd3ff")
const SHIELD_BLUE := Color("#5aa8ff")
const SUPERSHIELD := Color("#ff8fe0")
const HULL_GREEN := Color("#7dff7a")
const HULL_YELLOW := Color("#ffd23d")
const HULL_RED := Color("#ff4a3d")

const PANEL := Color(0.075, 0.12, 0.2, 0.86)
const PANEL_DARK := Color(0.04, 0.065, 0.11, 0.92)
const PANEL_LIGHT := Color(0.12, 0.19, 0.3, 0.9)
const BORDER := Color(0.82, 0.9, 1.0, 0.85)
const BORDER_DIM := Color(0.55, 0.66, 0.8, 0.45)
const TEXT := Color(0.95, 0.97, 1.0)
const TEXT_DIM := Color(0.66, 0.74, 0.86)
const ACCENT := Color("#8fd0ff")
const WARNING := Color("#ffb23d")
const BAR_EMPTY := Color(0.2, 0.26, 0.34, 0.9)
const ENEMY_RED := Color("#ff5a4d")
const TARGET_YELLOW := Color("#ffe14d")

const FLOOR := Color("#c9cfd8")
const FLOOR_LINE := Color("#adb5c1")
const WALL := Color("#141a26")
const DOOR := Color("#5b8de0")
const DOOR_OPEN := Color("#2c4778")
const AIRLOCK := Color("#e0a33a")
const ENEMY_FLOOR := Color("#a9b0ba")
const UNSEEN_FLOOR := Color("#2a3140")
const LOW_AIR := Color(1.0, 0.25, 0.3)


## The colour of a race's power when it is the enemy (palette.md); GATOS pirates show pirate orange.
static func enemy_power(faction: String, race: RaceDef) -> Color:
	if faction == "pirate":
		return PIRATE_ORANGE
	return race.power_colour if race else PIRATE_ORANGE


static func hull_colour(fraction: float) -> Color:
	if fraction > 0.66:
		return HULL_GREEN
	if fraction > 0.33:
		return HULL_YELLOW
	return HULL_RED
