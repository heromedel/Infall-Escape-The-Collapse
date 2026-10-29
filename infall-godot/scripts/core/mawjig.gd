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


## A reward of a size (low, medium, high) scaled by band, as events write them (events-sample.md).
static func reward_for_size(size: String, band: int) -> int:
	var base := {"tiny": 0.61, "low": 1.81, "medium": 3.62, "high": 6.03, "huge": 9.66}.get(size, 1.81) as float
	var band_scale := 1.0 + 0.1 * float(band - 1)
	return amount(base * band_scale)
