## Mawjig amounts: rounding and display. Amounts are kept to hundredths and shown without trailing zeros.
class_name Money
extends RefCounted


static func round_amount(amount: float) -> float:
	return snappedf(amount, 0.01)


## "166.4 Mawjig", "12.11 Mawjig", "5 Mawjig".
static func text(amount: float, with_unit: bool = true) -> String:
	var shown := "%.2f" % round_amount(amount)
	shown = shown.rstrip("0").rstrip(".")
	return shown + (" Mawjig" if with_unit else "")
