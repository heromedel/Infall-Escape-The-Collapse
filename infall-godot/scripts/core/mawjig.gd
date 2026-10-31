class_name Mawjig
extends RefCounted
## Mawjig is fuel, ammunition and currency at once (GDD 8C). It is kept as whole hundredths ("cents") so
## sums never drift, and shown to two decimals. Amounts never end in a zero: an amount that lands on x.x0
## moves by one hundredth (GDD 8C).

const JUMP_COST := 121          # 1.21 for the whole squad (GDD 6C)
const WAIT_GAIN := 25           # 0.25 for the whole squad (GDD 6B)


## Turns a decimal amount from a content file into hundredths, applying the no-trailing-zero rule.
static func amount(value: float) -> int:
	var cents := int(round(value * 100.0))
	return no_trailing_zero(cents)


static func no_trailing_zero(cents: int, round_up: bool = true) -> int:
	if cents != 0 and cents % 10 == 0:
		return cents + (1 if round_up else -1)
	return cents


static func format(cents: int) -> String:
	var sign := "-" if cents < 0 else ""
	var whole := absi(cents) / 100
	var part := absi(cents) % 100
	return "%s%d.%02d" % [sign, whole, part]


# Event rewards by band (low, medium, high), the genre's curve on Normal, from Infall: Eco's review (2026-10-31).
# Unlike wreck rewards (GDD 8I), events have no ship value behind them, so they follow the full curve.
const EVENT_REWARDS := [
	[2.06, 3.75, 5.08], [2.91, 5.21, 7.14], [3.75, 6.78, 9.21], [4.72, 8.23, 11.25],
	[5.57, 9.81, 13.31], [6.41, 11.37, 15.37], [7.26, 12.83, 17.54], [8.11, 14.41, 19.61],
]


## An event's reward of a size (events-sample.md) at a band: tiny is a third of low, huge one and a half times high.
static func reward_for_size(size: String, band: int) -> int:
	var row: Array = EVENT_REWARDS[clampi(band, 1, EVENT_REWARDS.size()) - 1]
	match size:
		"tiny":
			return amount(row[0] / 3.0)
		"low":
			return amount(row[0])
		"medium":
			return amount(row[1])
		"high":
			return amount(row[2])
		"huge":
			return amount(row[2] * 1.5)
	return amount(row[0])
