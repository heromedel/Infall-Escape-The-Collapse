class_name ShipSystem
extends RefCounted
## One installed system on one ship: its level (bars), damage, ion, and the power it was given.
## How much power it actually has depends on the ship's power model, so Ship.system_power() answers that.

const ION_TICKS := 100            # one ion bar wears off every 5 s

var def: SystemDef
var behaviour: String
var label: String = ""
var level: int = 1
var damage: int = 0                # broken bars
var repair_progress: float = 0.0   # toward the next bar repaired, 0 to 100
var ion: int = 0
var ion_ticks: int = 0
var spored: bool = false           # Sporewing hit: off until cleared like a repair
var spore_progress: float = 0.0
var power: int = 0                 # bars given (reactor pool ships)
var power_lost: int = 0            # bars damage or ion took, given back once they work again
var enabled: bool = true           # switched on (core ships)
var own_power: int = 0             # bars it carries itself (Mecha ships)
var integration_bar: bool = false  # a Mecha crew member is integrated with it
var room: int = -1
var cell: Vector2i
var wall: String = "north"
var manned_by: CrewMember = null
var manned_count: int = 0


## How many bars make one level: two for shields under Shield Levels: By Layer, the shield test (GDD 8H), where a
## level is a whole layer that costs two power and takes two damage, or two ion, to lose. One for everything else.
func bars_per_level() -> int:
	return 2 if behaviour == "shields" and Settings.get_value("shield_levels", "By Bar") == "By Layer" else 1


## The level as the player reads it.
func shown_level() -> int:
	return level / bars_per_level()


## The bars damage has left working.
func usable_bars() -> int:
	return maxi(0, level - _whole_levels(damage))


## The bars that can hold power right now: those damage has left, less those ion holds down.
func working_bars() -> int:
	return maxi(0, usable_bars() - _whole_levels(ion))


func _whole_levels(bars: int) -> int:
	var step := bars_per_level()
	return bars / step * step


func is_broken() -> bool:
	return damage >= level


func is_damaged() -> bool:
	return damage > 0 or spored


func skill_name() -> String:
	match behaviour:
		"piloting", "engines", "shields", "weapons":
			return behaviour
		"sensors", "doors":
			return "repair"
	return ""


func tick_ion() -> void:
	if ion <= 0:
		return
	ion_ticks -= 1
	if ion_ticks <= 0:
		ion -= 1
		ion_ticks = ION_TICKS if ion > 0 else 0


func add_ion(amount: int) -> void:
	ion = mini(level, ion + amount)
	ion_ticks = ION_TICKS


func display_name() -> String:
	return def.name if label.is_empty() else "%s %s" % [def.name, label]
